#' Decode DAG-CBOR encoded data to an R object
#'
#' This function decodes a raw vector containing DAG-CBOR encoded data into an R object.
#' DAG-CBOR is a deterministic subset of the CBOR format, used by IPFS and AtProto
#' (Bluesky) for data representation.
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
#' This function decodes multiple consecutive DAG-CBOR objects from a single raw vector.
#'
#' @param data A raw vector containing multiple DAG-CBOR encoded objects
#' @return A list of R objects, each representing a decoded DAG-CBOR object
#' @export
#'
#' @examples
#' \dontrun{
#' # When you have multiple DAG-CBOR objects in one stream:
#' results <- decode_dag_cbor_multi(raw_data)
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
#' @return A list with CID components
#' @export
#'
#' @examples
#' \dontrun{
#' # Decode a CID:
#' cid_info <- decode_cid("bafyreib775pirw4o3rz4iwdjwi3rz7q4z5t4xjyfrwnk2yukhzo2wyr4ye")
#' }
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

#' Print method for CAR file objects
#'
#' @param x A CAR file object from decode_car()
#' @param ... Additional arguments passed to print
#' @export
print.car_file <- function(x, ...) {
  cat("CAR file (Content Addressable aRchive)\n")
  cat("Version:", x$header$version, "\n")
  cat("Root CIDs:", paste(x$header$roots, collapse=", "), "\n")
  cat("Number of blocks:", length(x$blocks), "\n")
}

#' Print method for CID objects
#'
#' @param x A CID object from decode_cid()
#' @param ... Additional arguments passed to print
#' @export
print.cid <- function(x, ...) {
  cat("Content Identifier (CID)\n")
  cat("Version:", x$version, "\n")
  cat("Codec:", x$codec, "\n")
  cat("Hash code:", x$hash$code, "\n")
  cat("Hash size:", x$hash$size, "\n")
}
