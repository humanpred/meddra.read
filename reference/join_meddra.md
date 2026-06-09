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
# The package bundles a small fictional MedDRA dataset for illustration.
# For real work, replace this with the path to your licensed MedDRA release.
example_dir <- system.file("example_meddra", package = "meddra.read")
meddra_raw <- read_meddra(example_dir)

# Flatten the SOC -> HLGT -> HLT -> PT -> LLT hierarchy into one data.frame,
# one row per LLT, with all parent hierarchy levels on each row.
meddra_df <- join_meddra(meddra_raw)
meddra_df
#>   soc_code                         soc_name soc_abbrev hlgt_code
#> 1 10000100 Example Nervous System Disorders       ExNS  10001100
#> 2 10000100 Example Nervous System Disorders       ExNS  10001100
#> 3 10000200        Example Cardiac Disorders       ExCD  10002100
#>                              hlgt_name hlt_code                     hlt_name
#> 1       Example Neurological Disorders 10001110   Example Headache Disorders
#> 2       Example Neurological Disorders 10001110   Example Headache Disorders
#> 3 Example Cardiac Structural Disorders 10002110 Example Arrhythmia Disorders
#>    pt_code              pt_name pt_soc_code llt_code             llt_name
#> 1 10001111     Example Headache    10000100 10001111     Example Headache
#> 2 10001111     Example Headache    10000100 10001112    Example Head Pain
#> 3 10002111 Example Palpitations    10000200 10002111 Example Palpitations
#>   llt_currency primary_soc_fg
#> 1            Y              Y
#> 2            N              Y
#> 3            Y              Y

# Typical follow-on: drop non-current LLT synonyms.
subset(meddra_df, llt_currency == "Y")
#>   soc_code                         soc_name soc_abbrev hlgt_code
#> 1 10000100 Example Nervous System Disorders       ExNS  10001100
#> 3 10000200        Example Cardiac Disorders       ExCD  10002100
#>                              hlgt_name hlt_code                     hlt_name
#> 1       Example Neurological Disorders 10001110   Example Headache Disorders
#> 3 Example Cardiac Structural Disorders 10002110 Example Arrhythmia Disorders
#>    pt_code              pt_name pt_soc_code llt_code             llt_name
#> 1 10001111     Example Headache    10000100 10001111     Example Headache
#> 3 10002111 Example Palpitations    10000200 10002111 Example Palpitations
#>   llt_currency primary_soc_fg
#> 1            Y              Y
#> 3            Y              Y
```
