

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
#> # A tibble: 1,115 × 3
#>    action cid                                                         path      
#>    <chr>  <chr>                                                       <chr>     
#>  1 create bafyreibcf7jradap3cvp6f6mettrgir6rragejycmqnathupnuokb3asyi app.bsky.…
#>  2 create bafyreicnprlyrt6msfnihw7jibih3mp5ruratvmss3ul7a7hd7hfba5gjy app.bsky.…
#>  3 create bafyreiaw3dpsbrbegwgphxurlarq24qyi6g76smw7ggvcdtxmahc5yjmri app.bsky.…
#>  4 create bafyreiawwsisedoucznomazyva3zhomvhzdloimtdectt7w3wzv3f6oose app.bsky.…
#>  5 create bafyreibxg7boxn3ekbeyqtl3cjni2ipurld6ri6jeoex56t5iij7z2obgi app.bsky.…
#>  6 create bafyreic3qe3ag3sbone6aijh6no5bwq2jclfa5gejtcdhcxvlbu7ah3mty app.bsky.…
#>  7 create bafyreicrfdsrimqc4enhvba55jeuymwu4o24f6z2hynis4qxaujklpi7ai app.bsky.…
#>  8 create bafyreiawaesfaubvp5s757lpx4tw7rmtzwanco5zwmpg2ffjo2njmd45zm app.bsky.…
#>  9 create bafyreicc46yccpdsmy3ompsiorbu26fqnhe5no4ryrhxhppc6gklmyrb2e app.bsky.…
#> 10 create bafyreib7yliu74q37fokcipjjyz3penpeax5i7vyr2kfu76f4rcq3d5nmq app.bsky.…
#> # ℹ 1,105 more rows
```
