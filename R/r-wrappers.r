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
#' \dontrun{
#' # When you have DAG-CBOR encoded data:
#' result <- decode_dag_cbor(raw_data)
#' }
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
#' \dontrun{
#' # When you have multiple DAG-CBOR objects in one stream:
#' results <- decode_dag_cbor_multi(raw_data)
#' bytes_consumed <- attr(results, "bytes_consumed")
#'
#' # Remove processed bytes from buffer for streaming
#' remaining_buffer <- raw_data[(bytes_consumed + 1):length(raw_data)]
#' }
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
#' @export decoded character string
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
#' \dontrun{
#' # When you have a CAR file as raw data:
#' car_data <- decode_car(raw_car_data)
#' }
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
