test_that("decode_cid works with valid CID", {
  cid_str <- "bafyreig7jbijxpn4lfhvnvyuwf5u5jyhd7begxwyiqe7ingwxycjdqjjoa"
  result <- decode_cid(cid_str)

  expect_type(result, "list")
  expect_true("version" %in% names(result))
  expect_true("codec" %in% names(result))
})

test_that("decode_dag_cbor works with valid data", {
  cbor_data <- as.raw(c(
    0xa2,
    0x61,
    0x61,
    0x65,
    0x48,
    0x65,
    0x6c,
    0x6c,
    0x6f,
    0x61,
    0x62,
    0x66,
    0x57,
    0x6f,
    0x72,
    0x6c,
    0x64,
    0x21
  ))
  result <- decode_dag_cbor(cbor_data)

  expect_type(result, "list")
  expect_equal(result$a, "Hello")
  expect_equal(result$b, "World!")
})

test_that("decode_cid fails with invalid input", {
  expect_error(decode_cid(123), "Input must be a single character string")
  expect_error(
    decode_cid(c("a", "b")),
    "Input must be a single character string"
  )
})

test_that("decode_dag_cbor fails with invalid input", {
  expect_error(decode_dag_cbor("not raw"), "Input must be a raw vector")
  expect_error(decode_dag_cbor(123), "Input must be a raw vector")
})

test_that("decode_dag_cbor_multi works with valid data", {
  cbor_data <- as.raw(c(
    0xa2,
    0x61,
    0x61,
    0x65,
    0x48,
    0x65,
    0x6c,
    0x6c,
    0x6f,
    0x61,
    0x62,
    0x66,
    0x57,
    0x6f,
    0x72,
    0x6c,
    0x64,
    0x21
  ))
  result <- decode_dag_cbor_multi(cbor_data)

  expect_type(result, "list")
  expect_true(length(result) >= 1)
})

test_that("decode_car fails with invalid input", {
  expect_error(decode_car("not raw"), "Input must be a raw vector")
  expect_error(decode_car(123), "Input must be a raw vector")
})

test_that("decode_dag_cbor decodes scalar values correctly", {
  dec <- function(...) decode_dag_cbor(as.raw(c(...)))
  expect_identical(dec(0x17), 23L)
  expect_identical(dec(0x18, 0x64), 100L)
  expect_identical(dec(0x20), -1L)
  expect_identical(dec(0x38, 0x63), -100L)
  expect_identical(dec(0x1b, 0, 0, 0, 1, 0, 0, 0, 0), 2^32)
  expect_identical(dec(0x3b, 0, 0, 0, 1, 0, 0, 0, 0), -(2^32) - 1)
  expect_identical(dec(0xf5), TRUE)
  expect_identical(dec(0xf4), FALSE)
  expect_null(dec(0xf6))
  expect_identical(dec(0xfb, 0x3f, 0xf1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9a), 1.1)
  expect_identical(dec(0x78, 0x18, rep(0x61, 24)), strrep("a", 24))
  expect_identical(dec(0x43, 0x01, 0x02, 0x03), as.raw(1:3))
})

test_that("decode_dag_cbor decodes nested structures", {
  # {"a": [1, {"b": true}]}
  res <- decode_dag_cbor(as.raw(c(
    0xa1, 0x61, 0x61, 0x82, 0x01, 0xa1, 0x61, 0x62, 0xf5
  )))
  expect_identical(res, list(a = list(1L, list(b = TRUE))))
})

test_that("decode_dag_cbor decodes CID links to strings", {
  cid <- "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua"
  digest <- decode_cid(cid)$hash$digest
  # tag 42, byte string of length 37: 0x00 prefix + CIDv1 dag-cbor sha2-256
  bytes <- as.raw(c(0xd8, 0x2a, 0x58, 0x25, 0x00, 0x01, 0x71, 0x12, 0x20))
  expect_identical(decode_dag_cbor(c(bytes, digest)), cid)
})

test_that("decode_dag_cbor errors on invalid data", {
  expect_error(decode_dag_cbor(as.raw(c(0xd8, 0x63, 0x01))), "Failed to decode")
  expect_error(decode_dag_cbor(as.raw(c(0x01, 0x02))), "Failed to decode")
  expect_error(decode_dag_cbor(as.raw(c(0x78, 0x18, 0x61))), "Failed to decode")
})

test_that("decode_dag_cbor_multi reports bytes consumed", {
  first <- as.raw(c(0xa1, 0x61, 0x63, 0x01)) # {"c": 1}
  second <- as.raw(c(0x18, 0x64)) # 100
  truncated <- as.raw(c(0x78, 0x18, 0x61)) # incomplete string
  res <- decode_dag_cbor_multi(c(first, second, truncated))
  expect_length(res, 2)
  expect_identical(res[[1]], list(c = 1L))
  expect_identical(res[[2]], 100L)
  expect_equal(attr(res, "bytes_consumed"), length(first) + length(second))
})

test_that("decode_car decodes the sample file", {
  car_file <- system.file("extdata", "sample.car", package = "libipldr")
  car_data <- readBin(car_file, what = "raw", n = file.size(car_file))
  res <- decode_car(car_data)
  root <- "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua"
  expect_identical(res$header$version, 1L)
  expect_identical(res$header$roots, root)
  expect_named(res$blocks, root)
  expect_length(res$blocks[[1]], 0)
})

test_that("decode_car errors on truncated data", {
  car_file <- system.file("extdata", "sample.car", package = "libipldr")
  car_data <- readBin(car_file, what = "raw", n = file.size(car_file))
  expect_error(decode_car(car_data[1:30]), "Failed to decode CAR")
})
