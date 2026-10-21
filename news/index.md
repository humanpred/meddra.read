# Changelog

## meddra.read 0.0.1.9000

- Add
  [`join_smq()`](https://humanpred.github.io/meddra.read/reference/join_smq.md)
  to expand SMQ lists into one row per Lowest Level Term with the full
  MedDRA hierarchy attached, resolving sub-SMQ references and expanding
  Preferred Terms down to their LLTs (fix \#14).
- Add `primary_soc_fg` column to merged data from `join_meddra` (fix
  \#5)
- Improved function examples in
  [`read_meddra()`](https://humanpred.github.io/meddra.read/reference/read_meddra.md)
  and
  [`join_meddra()`](https://humanpred.github.io/meddra.read/reference/join_meddra.md)
  to illustrate input and output using the bundled example dataset.

## meddra.read 0.0.1

CRAN release: 2025-03-26

- Initial CRAN submission.
