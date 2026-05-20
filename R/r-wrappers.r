#' Decode DAG-CBOR encoded data to an R object
#'
#' This function decodes a raw vector containing DAG-CBOR encoded data into an R
#' object. DAG-CBOR is a deterministic subset of the CBOR format, used by IPFS
#' and AtProto (Bluesky) for data representation.
#'
#' @param data A raw vector containing DAG-CBOR encoded data
#' @return An R object representing the decoded data
#' @export
#'
#' @examples
#' # Decode a simple DAG-CBOR map {"a": "Hello", "b": "World!"}
#' cbor_data <- as.raw(c(
#'   0xa2, 0x61, 0x61, 0x65, 0x48, 0x65, 0x6c, 0x6c, 0x6f,
#'   0x61, 0x62, 0x66, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21
#' ))
#' decode_dag_cbor(cbor_data)
decode_dag_cbor <- function(data) {
  if (!is.raw(data)) {
    stop("Input must be a raw vector")
  }
  result <- .Call(wrap__decode_dag_cbor, data)
  if (inherits(result, "error")) {
    stop(result$message)
  }
  return(result)
}


#' Decode multiple DAG-CBOR objects from a byte stream
#'
#' This function decodes multiple consecutive DAG-CBOR objects from a single raw
#' vector. The returned list includes a 'bytes_consumed' attribute indicating
#' how many bytes from the beginning of the input were successfully processed.
#' This is useful for streaming applications where you need to know where to
#' continue reading.
#'
#' @param data A raw vector containing multiple DAG-CBOR encoded objects
#' @return A list of R objects, each representing a decoded DAG-CBOR object
#' @export
#'
#' @examples
#' # Decode two consecutive DAG-CBOR objects from a single byte stream
#' cbor_data <- as.raw(c(
#'   0xa2, 0x61, 0x61, 0x65, 0x48, 0x65, 0x6c, 0x6c, 0x6f,
#'   0x61, 0x62, 0x66, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21,
#'   0xa1, 0x61, 0x63, 0x01
#' ))
#' results <- decode_dag_cbor_multi(cbor_data)
#' attr(results, "bytes_consumed")
decode_dag_cbor_multi <- function(data) {
  if (!is.raw(data)) {
    stop("Input must be a raw vector")
  }
  .Call(wrap__decode_dag_cbor_multi, data)
}


#' Decode a Content IDentifier (CID) string
#'
#' This function decodes a CID string into its components (version, codec, and hash).
#'
#' @param cid_str A string containing a valid CID
#'
#' @return A list with CID components
#'
#' @export
#'
#' @examples
#' # Decode a CID:
#' cid_info <- decode_cid("bafyreib775pirw4o3rz4iwdjwi3rz7q4z5t4xjyfrwnk2yukhzo2wyr4ye")
decode_cid <- function(cid_str) {
  if (!is.character(cid_str) || length(cid_str) != 1) {
    stop("Input must be a single character string")
  }
  result <- .Call(wrap__decode_cid, cid_str)
  if (inherits(result, "error")) {
    stop(result$message)
  }
  return(result)
}


#' Decode a Content Addressable aRchive (CAR) file
#'
#' This function decodes a CAR file from a raw vector, extracting the header and blocks.
#'
#' @param data A raw vector containing a CAR file
#' @return A list with header information and decoded blocks
#' @export
#'
#' @examples
#' car_file <- system.file("extdata", "sample.car", package = "libipldr")
#' car_data <- readBin(car_file, what = "raw", n = file.size(car_file))
#' decode_car(car_data)
decode_car <- function(data) {
  if (!is.raw(data)) {
    stop("Input must be a raw vector")
  }
  result <- .Call(wrap__decode_car, data)
  if (inherits(result, "error")) {
    stop(result$message)
  }
  return(result)
}
