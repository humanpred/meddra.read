# Combine together all of the MedDRA terms into a single data.frame

Combine together all of the MedDRA terms into a single data.frame

## Usage

``` r
join_meddra(data)
```

## Arguments

- data:

  MedDRA source data from
  [`read_meddra()`](https://humanpred.github.io/meddra.read/reference/read_meddra.md)

## Value

A data.frame with the "soc_code", "soc_name", "soc_abbrev", "hlgt_code",
"hlgt_name", "hlt_code", "hlt_name", "pt_code", "pt_name",
"pt_soc_code", "llt_code", "llt_name", and "llt_currency"

## Examples

``` r
example_dir <- system.file("example_meddra", package = "meddra.read")
meddra_raw <- read_meddra(example_dir)
meddra_df <- join_meddra(meddra_raw)
```
