

<!-- README.md is generated from README.qmd. Please edit that file -->

# libipldr

<!-- badges: start -->

<!-- badges: end -->

The goal of libipldr is to make it possible to translate DAG-CBOR
encoded data in R. This is mostly useful for the

## Installation

You can install the development version of libipldr from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("JBGruber/libipldr")
```

## Example

Decode CID:

``` r
library(libipldr)
decode_cid("bafyreig7jbijxpn4lfhvnvyuwf5u5jyhd7begxwyiqe7ingwxycjdqjjoa")
#> Content Identifier (CID)
#> Version: 1 
#> Codec: 113 
#> Hash code: 18 
#> Hash size: 32
```

Decode DAG-CBOR:

``` r
cbor_data <- as.raw(c(
  0xa2, 0x61, 0x61, 0x65, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x61, 0x62,  0x66, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21
))
decode_dag_cbor(cbor_data)
#> $a
#> [1] "Hello"
#> 
#> $b
#> [1] "World!"
```
