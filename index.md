# meddra.read

The goal of meddra.read is to read in the MedDRA source distribution
files into a data.frame usable in R.

## Installation

You can install the development version of meddra.read like so:

``` r
remotes::install_github("humanpred/meddra.read")
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
