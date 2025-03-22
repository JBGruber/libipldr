library(libipldr)

# CID examples
# ------------------------------

# Decode a CID string to its components
cid_example <- decode_cid("bafyreig7jbijxpn4lfhvnvyuwf5u5jyhd7begxwyiqe7ingwxycjdqjjoa")
print(cid_example)

cbor_data <- as.raw(c(0xa2, 0x61, 0x61, 0x0c, 0x61, 0x62, 0x66, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x21))
decoded_cbor <- decode_dag_cbor(cbor_data)


library(httr)
library(jsonlite)

# Function to connect to Bluesky Firehose and process events
bluesky_firehose <- function(callback, max_events = 10) {
  # Connect to the BGS firehose
  url <- "https://bsky.network/xrpc/com.atproto.sync.subscribeRepos"

  count <- 0

  # Set up a connection with a streaming callback
  httr::GET(
    url = url,
    httr::write_function(function(data) {
      # Process each chunk of data as it arrives
      if (length(data) > 0) {
        # Decode the CBOR data
        decoded <- decode_dag_cbor(data)

        # Process the decoded data with user callback
        callback(decoded)

        count <<- count + 1
        if (count >= max_events) {
          return(FALSE)  # Stop the connection after max_events
        }
      }
      return(TRUE)  # Continue getting data
    })
  )
}


# Example callback function to process events
process_event <- function(event) {
  # Extract and print key information
  if (!is.null(event$op) && event$op == "create") {
    print(paste0(
      "New post from: ", event$repo,
      ", Path: ", event$path,
      ", CID: ", event$cid
    ))

    # You could further decode the record here
    if (!is.null(event$record)) {
      print(jsonlite::toJSON(event$record, auto_unbox = TRUE, pretty = TRUE))
    }
  }
}

# Connect to firehose and process 5 events
bluesky_firehose(process_event, max_events = 5)

library(websocket)

ws <- WebSocket$new("ws://echo.websocket.org/", autoConnect = FALSE)
ws$onOpen(function(event) {
  cat("Connection opened\n")
})
ws$onMessage(function(event) {
  cat("Client got msg: ", event$data, "\n")
})
ws$onClose(function(event) {
  cat("Client disconnected with code ", event$code,
      " and reason ", event$reason, "\n", sep = "")
})
ws$onError(function(event) {
  cat("Client failed to connect: ", event$message, "\n")
})
ws$connect()
ws$close()

library(websocket)

the <- new.env()
the$stream <- NULL
test_firehose_stream <- function(secs = 1) {
  ws <- websocket::WebSocket$new("wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos", autoConnect = FALSE)
  # ws$onOpen(function(event) {
  #   cat("Connection opened\n")
  # })
  ws$onMessage(function(event) {
    event <<- event
    # write(event$data, file="myfile.txt", append=TRUE)
    dat <<- libipldr::decode_dag_cbor_multi(event$data)[[2]]
    # cat("Client got msg: ", dat[["time"]], "\n")
    # saveRDS(dat, paste0(dat$commit, ".rds"))
    the$stream[[dat$commit]] <- dat
  })
  # ws$onClose(function(event) {
  #   cat("Client disconnected with code ", event$code,
  #       " and reason ", event$reason, "\n", sep = "")
  # })
  ws$onError(function(event) {
    # cat("Client failed to connect: ", event$message, "\n")
  })
  ws$connect()
  Sys.sleep(secs)
  ws$close()
}
test_firehose_stream(10)
commits <- the$stream
commits2 <- lapply(commits, function(dat) {
  dat$blocks <- libipldr::decode_dag_cbor_multi(dat$blocks)
  dat
})

x <- readChar("myfile.txt", nchars = file.size("myfile.txt"), useBytes = TRUE)
x |>
  gsub(pattern = "\n", replacement = "", x = _) |>
  charToRaw() |>
  libipldr::decode_dag_cbor()

y <- lapply(list.files(pattern = "rds"), readRDS)

z <- libipldr::decode_dag_cbor_multi(y[[1]]$data)
libipldr::decode_dag_cbor_multi(z[[2]][["blocks"]])
