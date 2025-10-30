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
