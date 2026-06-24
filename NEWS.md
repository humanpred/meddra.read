# meddra.read 0.0.1.9000

* Add `join_smq()` to expand SMQ lists into one row per Lowest Level Term with
  the full MedDRA hierarchy attached, resolving sub-SMQ references and expanding
  Preferred Terms down to their LLTs (fix #14).
* Add `primary_soc_fg` column to merged data from `join_meddra` (fix #5)
* Improved function examples in `read_meddra()` and `join_meddra()` to
  illustrate input and output using the bundled example dataset.

# meddra.read 0.0.1

* Initial CRAN submission.
