

<!-- README.md is generated from README.qmd. Please edit that file -->

# libipldr

<!-- badges: start -->

[![R-CMD-check](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml)
[![extendr](https://img.shields.io/badge/extendr-%5E0.8.1-276DC2)](https://extendr.github.io/extendr/extendr_api/)
<!-- badges: end -->

The goal of libipldr is to make it possible to translate DAG-CBOR
encoded data in R. This is mostly useful for the
[`atrrr`](https://jbgruber.github.io/atrrr/articles/Networks.html)
package that can stream from the Bluesky firehose.

## Installation

You can install the development version of libipldr with:

``` r
install.packages("libipldr)
```

Or install the development version from [GitHub](https://github.com/)
with:

``` r
# install.packages("pak")
pak::pak("JBGruber/libipldr")
```

## Example

Decode CID:

``` r
library(libipldr)
decode_cid("bafyreig7jbijxpn4lfhvnvyuwf5u5jyhd7begxwyiqe7ingwxycjdqjjoa")
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 113
#> 
#> [[3]]
#> [[3]][[1]]
#> [1] 18
#> 
#> [[3]][[2]]
#> [1] 32
#> 
#> [[3]][[3]]
#>  [1] df 48 50 9b bd bc 59 4f 56 d7 14 b1 7b 4e a7 07 1f c2 43 5e d8 44 09 f4 34
#> [26] d6 be 04 91 c1 29 70
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

# What is this good for?

Mainly I wanted to have this to decode the firehose stream from Bluesky:

``` r
library(httr2)
# open connection to firehose
firehose <- request("wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos") |>
  req_perform_connection()

# stream 5 Mb
results_raw <- firehose |>
  resp_stream_raw(kb = 5000)

close(firehose)

# decode the stream
results <- decode_dag_cbor_multi(results_raw)

# extract operations
library(purrr)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
events_df <- map(results, function(res) {
  pluck(res, "ops", 1)
}) |>
  bind_rows()
events_df
#> # A tibble: 999 × 3
#>    action cid                                                         path      
#>    <chr>  <chr>                                                       <chr>     
#>  1 create bafyreibqrbhfp5rtjuoa7do347nafwbnzbtka4jbwcvvtdlim6du2sbsjm app.bsky.…
#>  2 create bafyreidbopgyh5y2zdacoru5n4wm5t4xu7vnun7cerem3mbcvc4ifkl3y4 app.bsky.…
#>  3 create bafyreibjwxhmiobpu5merpc5kxtcdprr4kbvquw6jx3o4vnorfle3tfjqm app.bsky.…
#>  4 delete <NA>                                                        app.bsky.…
#>  5 create bafyreiciwsrykshbmjkvhzhtnqh3xvvcbyq3fdza3v6aod4iboq4swjcue app.bsky.…
#>  6 create bafyreibnabt6s7qo2ranc26xvjgudl3437ugp3qqzrxdkx3fhytwjkgn6q app.bsky.…
#>  7 create bafyreifc53e3oshbwb7anysozesfe4wqalcrtx2omnwgdswf5brwifltgm app.bsky.…
#>  8 create bafyreiank2n2rd3y2rdnutvyd3i4xe62ggmuc4cqy7tkyr3kpd73fnit7i app.bsky.…
#>  9 create bafyreih4hu3vggz2ifhjohrpjaw35ohdhz4thf7rzfa2nbbodrnorc3qse app.bsky.…
#> 10 create bafyreidku42p2l7etdhfizbr42i5ksliixvcvbtjuvleig4mt5vuss2bdi app.bsky.…
#> # ℹ 989 more rows
```
