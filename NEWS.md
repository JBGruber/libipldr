# libipldr (development version)

* The Rust backend now uses `ipld-core` and `serde_ipld_dagcbor` instead of
  the deprecated `libipld` crate. The R functions are unchanged. This also
  solved some decoding issues with edge cases.
* The minimum supported Rust version is now 1.81.

* Added a `NEWS.md` file to track changes to the package.
