

<!-- README.md is generated from README.qmd. Please edit that file -->

# libipldr

<!-- badges: start -->

[![R-CMD-check](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml)
[![extendr](https://img.shields.io/badge/extendr-%5E0.8.1-276DC2)](https://extendr.rs/extendr/extendr_api/)
[![CRAN_Download_Badge](https://cranlogs.r-pkg.org/badges/grand-total/libipldr)](https://cran.r-project.org/package=libipldr)
<!-- badges: end -->

The goal of libipldr is to make it possible to translate DAG-CBOR
encoded data in R. This is mostly useful for the
[`atrrr`](https://jbgruber.github.io/atrrr/articles/Networks.html)
package that can stream from the Bluesky firehose.

## Installation

You can install from CRAN with:

``` r
install.packages("libipldr")
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
#> $version
#> [1] 1
#> 
#> $codec
#> [1] 113
#> 
#> $hash
#> $hash$code
#> [1] 18
#> 
#> $hash$size
#> [1] 32
#> 
#> $hash$digest
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
#> # A tibble: 983 × 4
#>    action cid                                                        path  prev 
#>    <chr>  <chr>                                                      <chr> <chr>
#>  1 create bafyreif2jqr4mgs3ab4d7vh64stmt54q2b5p3ay6vglmmmh4fg6qtuah… app.… <NA> 
#>  2 create bafyreiai3qhecipgihgmk3jyvbssso6z7czbxp5frozga2vaypgkhvnq… app.… <NA> 
#>  3 create bafyreiconv43mllioqujwkqsdacjudcleaq7tmzf5x4m6rbkbr3p4w2b… app.… <NA> 
#>  4 create bafyreibklcbwtxmxtwunjfzjnckeerpx2kau5lteyf66sev5pczthkpd… app.… <NA> 
#>  5 create bafyreih2wlvbvqww6udd2oattdriydxprqzhed637qton6te2vrvs4d2… app.… <NA> 
#>  6 create bafyreiczfxgz6qs3y4etx3p2petwlgfvwdsvlfw7dlk4v7otdqbiradd… app.… <NA> 
#>  7 create bafyreigdqhozfzfzeuhn3y2545mugchoadrmw74c2twldoxyywh63wrl… app.… <NA> 
#>  8 delete <NA>                                                       app.… bafy…
#>  9 create bafyreic4h64ytwy6rwjplc6oljawp3zvfdenuh2macinb2kl7g3b6za3… app.… <NA> 
#> 10 create bafyreigk257ywvssiir26ooqlco35suhnzmxwgpwbio23ejfxgfvhy6e… app.… <NA> 
#> # ℹ 973 more rows
```
