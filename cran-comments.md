## Resubmission

This is a resubmission. I thank Benjamin Altmann for checking the original 
submission and for his comments, which I address below:

* Software and API names are now quoted in Title and Description ('Rust', 'IPLD',
  'IPFS', 'AtProto').
* All acronyms are expanded on first use: DAG-CBOR (Directed Acyclic Graph
  Concise Binary Object Representation), IPLD (InterPlanetary Linked Data),
  IPFS (InterPlanetary File System).
* Added upstream library reference URL to Description.
* Replaced `\dontrun{}` with a runnable example in `decode_car()` that loads a
  small sample CAR file from `inst/extdata/` via `system.file()`.

## Test environments

* Local: EndeavourOS (Arch Linux), R 4.6.0
* GitHub Actions (via R-CMD-check):
  - Windows (latest), R-release
  - macOS (latest), R-release
  - Ubuntu (latest), R-devel, R-release, R-oldrel
* win-builder

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
