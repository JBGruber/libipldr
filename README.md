

<!-- README.md is generated from README.qmd. Please edit that file -->

# libipldr

<!-- badges: start -->

[![R-CMD-check](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JBGruber/libipldr/actions/workflows/R-CMD-check.yaml)
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
#> # A tibble: 991 × 3
#>    action cid                                                         path      
#>    <chr>  <chr>                                                       <chr>     
#>  1 create bafyreibt4woefbrzxnhclqyjuwo4lsbnjjktxvpep43se5u5l45ruy3wwa app.bsky.…
#>  2 create bafyreiaygudmqw67c4wmrqf22luqlwe7mj55bjli6uwguelzocgzfa3oc4 app.bsky.…
#>  3 create bafyreieqkkrimkxq7u5udp6giyxfs42jokclya52tk76t5j5uftpjtwzri app.bsky.…
#>  4 create bafyreiccmp44o76eps44jrptbhv5bbcxnr4sggtzqb4h37fbl46eoxkzhi app.bsky.…
#>  5 create bafyreiaxqb6eaulgyeam36h3wjf3lw665w7nq7i74c3sk7j67pa6ocaaem app.bsky.…
#>  6 create bafyreihnljosz6g6xjukslees5iooir6yudxuolpc5jpzrqqc4fxdpsco4 app.bsky.…
#>  7 create bafyreibkwsgtnd7fgdy5vlot3fz47hefe34awsyt6qdkg63bnflbew72na app.bsky.…
#>  8 create bafyreiefub5vlhghurhz4c6pdyg2ef4dmwo4fxbb76jmpl32jovxuz3tbm app.bsky.…
#>  9 create bafyreiefdafsouqavlzd6jonyotnbvbyicguibupv7t7enwfwelpo7bqt4 app.bsky.…
#> 10 create bafyreidnzlksyvttfcxzeqzyszyxsepnscnmgzzuompqotlchgbyrcl3qi app.bsky.…
#> # ℹ 981 more rows
```
