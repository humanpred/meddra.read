# Getting Started with meddra.read

``` r
library(meddra.read)
```

## What is MedDRA?

MedDRA (Medical Dictionary for Regulatory Activities) is a standardized
medical terminology used in clinical trials and regulatory submissions
to classify adverse events. It is organized as a five-level hierarchy:

| Level             | Abbreviation | Description           |
|-------------------|--------------|-----------------------|
| 1 (broadest)      | SOC          | System Organ Class    |
| 2                 | HLGT         | High Level Group Term |
| 3                 | HLT          | High Level Term       |
| 4                 | PT           | Preferred Term        |
| 5 (most specific) | LLT          | Lowest Level Term     |

MedDRA data is proprietary and requires a license from the [MedDRA
MSSO](https://www.meddra.org/). This package helps you load and work
with your licensed MedDRA data. The examples below use a small, clearly
fictional dataset bundled with the package for illustration purposes.

## MedDRA Distribution File Structure

When you download a licensed MedDRA release, it contains two
subdirectories:

    my_meddra_release/
    ├── MedAscii/          # Main MedDRA data files (.asc)
    │   ├── soc.asc        # System Organ Classes
    │   ├── hlgt.asc       # High Level Group Terms
    │   ├── hlt.asc        # High Level Terms
    │   ├── pt.asc         # Preferred Terms
    │   ├── llt.asc        # Lowest Level Terms
    │   ├── hlt_pt.asc     # HLT to PT linking table
    │   ├── hlgt_hlt.asc   # HLGT to HLT linking table
    │   ├── soc_hlgt.asc   # SOC to HLGT linking table
    │   ├── mdhier.asc     # Denormalized hierarchy
    │   ├── meddra_release.asc  # Version information
    │   └── ...            # Additional files (SMQ, specialties, etc.)
    └── SeqAscii/          # Sequential update files (.seq)
        ├── soc.seq
        ├── pt.seq
        └── ...

All files use the `$` character as a field separator.

## Reading MedDRA Data

Use
[`read_meddra()`](https://humanpred.github.io/meddra.read/reference/read_meddra.md)
pointing to the parent directory that contains `MedAscii` and `SeqAscii`
(or `MedSeq`) subdirectories. It returns a named list of data.frames,
one per file.

``` r
# For your licensed data, replace this path with your actual MedDRA directory:
# example_dir <- "/path/to/your/meddra/release"

# The package includes a small fictional dataset for illustration:
example_dir <- system.file("example_meddra", package = "meddra.read")

meddra_raw <- read_meddra(example_dir)
```

The result is a named list with one data.frame per MedDRA file:

``` r
names(meddra_raw)
#>  [1] "hlgt_hlt.asc"               "hlgt.asc"                  
#>  [3] "hlt_pt.asc"                 "hlt.asc"                   
#>  [5] "intl_ord.asc"               "llt.asc"                   
#>  [7] "mdhier.asc"                 "meddra_history_english.asc"
#>  [9] "meddra_release.asc"         "pt.asc"                    
#> [11] "smq_content.asc"            "smq_list.asc"              
#> [13] "soc_hlgt.asc"               "soc.asc"                   
#> [15] "spec_pt.asc"                "spec.asc"                  
#> [17] "hlgt_hlt.seq"               "hlgt.seq"                  
#> [19] "hlt_pt.seq"                 "hlt.seq"                   
#> [21] "intl_ord.seq"               "llt.seq"                   
#> [23] "mdhier.seq"                 "pt.seq"                    
#> [25] "soc_hlgt.seq"               "soc.seq"                   
#> [27] "spec_pt.seq"                "spec.seq"
```

Each data.frame corresponds to one of the MedDRA source files. For
example, the System Organ Class data:

``` r
meddra_raw$soc.asc
#>   soc_code                         soc_name soc_abbrev
#> 1 10000100 Example Nervous System Disorders       ExNS
#> 2 10000200        Example Cardiac Disorders       ExCD
```

The Preferred Terms:

``` r
meddra_raw$pt.asc
#>    pt_code              pt_name pt_soc_code
#> 1 10001111     Example Headache    10000100
#> 2 10002111 Example Palpitations    10000200
```

The Lowest Level Terms (note: `llt_currency = "Y"` means the term is
current; `"N"` means it is a non-current synonym):

``` r
meddra_raw$llt.asc
#>   llt_code             llt_name  pt_code llt_currency
#> 1 10001111     Example Headache 10001111            Y
#> 2 10001112    Example Head Pain 10001111            N
#> 3 10002111 Example Palpitations 10002111            Y
```

## Joining into a Single Data Frame

[`join_meddra()`](https://humanpred.github.io/meddra.read/reference/join_meddra.md)
merges all the hierarchy tables into a single flat data.frame, making it
easy to look up or filter by any level of the hierarchy:

``` r
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
```

The resulting data.frame has one row per LLT (Lowest Level Term) and
includes all parent hierarchy levels. The columns are:

| Column                                 | Description                                                 |
|----------------------------------------|-------------------------------------------------------------|
| `soc_code`, `soc_name`, `soc_abbrev`   | System Organ Class                                          |
| `hlgt_code`, `hlgt_name`               | High Level Group Term                                       |
| `hlt_code`, `hlt_name`                 | High Level Term                                             |
| `pt_code`, `pt_name`, `pt_soc_code`    | Preferred Term                                              |
| `llt_code`, `llt_name`, `llt_currency` | Lowest Level Term                                           |
| `primary_soc_fg`                       | `"Y"` if this SOC is the primary (preferred) SOC for the PT |

## Common Use Cases

### Filter by System Organ Class

To work with terms from a specific SOC:

``` r
subset(meddra_df, soc_name == "Example Nervous System Disorders")
#>   soc_code                         soc_name soc_abbrev hlgt_code
#> 1 10000100 Example Nervous System Disorders       ExNS  10001100
#> 2 10000100 Example Nervous System Disorders       ExNS  10001100
#>                        hlgt_name hlt_code                   hlt_name  pt_code
#> 1 Example Neurological Disorders 10001110 Example Headache Disorders 10001111
#> 2 Example Neurological Disorders 10001110 Example Headache Disorders 10001111
#>            pt_name pt_soc_code llt_code          llt_name llt_currency
#> 1 Example Headache    10000100 10001111  Example Headache            Y
#> 2 Example Headache    10000100 10001112 Example Head Pain            N
#>   primary_soc_fg
#> 1              Y
#> 2              Y
```

### Find all LLTs for a Preferred Term

To find all Lowest Level Terms (including non-current synonyms) for a
given PT:

``` r
subset(meddra_df, pt_name == "Example Headache", select = c(llt_code, llt_name, llt_currency))
#>   llt_code          llt_name llt_currency
#> 1 10001111  Example Headache            Y
#> 2 10001112 Example Head Pain            N
```

### Keep only current LLTs

Non-current LLTs (`llt_currency = "N"`) are historical synonyms. In most
analyses you will want to keep only current terms:

``` r
current <- subset(meddra_df, llt_currency == "Y")
current[, c("llt_name", "pt_name", "soc_abbrev")]
#>               llt_name              pt_name soc_abbrev
#> 1     Example Headache     Example Headache       ExNS
#> 3 Example Palpitations Example Palpitations       ExCD
```

### Check the MedDRA version

``` r
meddra_raw$meddra_release.asc
#>   version language
#> 1       0  English
```

## Working with SMQ Data

Standardized MedDRA Queries (SMQs) are pre-defined sets of terms used to
search for adverse events. The SMQ data is available in `smq_list.asc`
and `smq_content.asc`:

``` r
meddra_raw$smq_list.asc
#>   smq_code             smq_name smq_level
#> 1 10000001 Example Headache SMQ         2
#>                          smq_description     smq_source     smq_note
#> 1 Example SMQ for headache-related terms Example source Example note
#>   MedDRA_version status smq_algorithm
#> 1              0      A             N
meddra_raw$smq_content.asc
#>   smq_code term_code term_level term_scope term_category term_weight
#> 1 10000001  10001111          4          1             A           0
#>   term_status term_addition_version term_last_modified_version
#> 1           A                     0                          0
```
