# Read MedDRA datasets from the source MedDRA datasets

Read MedDRA datasets from the source MedDRA datasets

## Usage

``` r
read_meddra(directory)
```

## Arguments

- directory:

  the directory containing the MedAscii and SeqAscii directories

## Value

A list of data.frames for each file in the MedDRA source distribution

## Examples

``` r
# The package bundles a small fictional MedDRA dataset for illustration.
# For real work, replace this with the path to your licensed MedDRA release.
example_dir <- system.file("example_meddra", package = "meddra.read")

meddra_raw <- read_meddra(example_dir)

# The result is a named list of data.frames, one per MedDRA source file
names(meddra_raw)
#>  [1] "hlgt.asc"                   "hlgt_hlt.asc"              
#>  [3] "hlt.asc"                    "hlt_pt.asc"                
#>  [5] "intl_ord.asc"               "llt.asc"                   
#>  [7] "mdhier.asc"                 "meddra_history_english.asc"
#>  [9] "meddra_release.asc"         "pt.asc"                    
#> [11] "smq_content.asc"            "smq_list.asc"              
#> [13] "soc.asc"                    "soc_hlgt.asc"              
#> [15] "spec.asc"                   "spec_pt.asc"               
#> [17] "hlgt.seq"                   "hlgt_hlt.seq"              
#> [19] "hlt.seq"                    "hlt_pt.seq"                
#> [21] "intl_ord.seq"               "llt.seq"                   
#> [23] "mdhier.seq"                 "pt.seq"                    
#> [25] "soc.seq"                    "soc_hlgt.seq"              
#> [27] "spec.seq"                   "spec_pt.seq"               

# Each component mirrors the schema of its MedDRA source file
meddra_raw$soc.asc
#>   soc_code                         soc_name soc_abbrev
#> 1 10000100 Example Nervous System Disorders       ExNS
#> 2 10000200        Example Cardiac Disorders       ExCD
meddra_raw$pt.asc
#>    pt_code              pt_name pt_soc_code
#> 1 10001111     Example Headache    10000100
#> 2 10002111 Example Palpitations    10000200
meddra_raw$llt.asc
#>   llt_code             llt_name  pt_code llt_currency
#> 1 10001111     Example Headache 10001111            Y
#> 2 10001112    Example Head Pain 10001111            N
#> 3 10002111 Example Palpitations 10002111            Y
```
