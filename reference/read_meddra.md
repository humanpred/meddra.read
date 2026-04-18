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
example_dir <- system.file("example_meddra", package = "meddra.read")
meddra_raw <- read_meddra(example_dir)
```
