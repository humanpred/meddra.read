
<!-- README.md is generated from README.Rmd. Please edit that file -->

# meddra.read

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/meddra.read)](https://CRAN.R-project.org/package=meddra.read)
[![R-CMD-check](https://github.com/billdenney/meddra.read/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/billdenney/meddra.read/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of meddra.read is to read in the MedDRA source distribution
files into a data.frame usable in R.

## Installation

You can install the development version of meddra.read like so:

``` r
remotes::install_github("billdenney/meddra.read")
```

## Example

Here is how to load MedDRA data. You must have a directory with the
MedAscii and SeqAscii distribution files, they are not allowed to be
publicly distributed.

``` r
library(meddra.read)
meddra_raw <- read_meddra("/path/to/meddra_dist")
meddra_data <- join_meddra(meddra_raw)
```
