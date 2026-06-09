#' Combine together all of the MedDRA terms into a single data.frame
#'
#' @param data MedDRA source data from `read_meddra()`
#' @return A data.frame with the "soc_code", "soc_name", "soc_abbrev",
#'   "hlgt_code", "hlgt_name", "hlt_code", "hlt_name", "pt_code", "pt_name",
#'   "pt_soc_code", "llt_code", "llt_name", and "llt_currency"
#' @examples
#' # The package bundles a small fictional MedDRA dataset for illustration.
#' # For real work, replace this with the path to your licensed MedDRA release.
#' example_dir <- system.file("example_meddra", package = "meddra.read")
#' meddra_raw <- read_meddra(example_dir)
#'
#' # Flatten the SOC -> HLGT -> HLT -> PT -> LLT hierarchy into one data.frame,
#' # one row per LLT, with all parent hierarchy levels on each row.
#' meddra_df <- join_meddra(meddra_raw)
#' meddra_df
#'
#' # Typical follow-on: drop non-current LLT synonyms.
#' subset(meddra_df, llt_currency == "Y")
#' @export
join_meddra <- function(data) {
  ret <- dplyr::left_join(data$soc.asc, data$soc_hlgt.asc, by = "soc_code")
  ret <- dplyr::left_join(ret, data$hlgt.asc, by = "hlgt_code")
  ret <- dplyr::left_join(ret, data$hlgt_hlt.asc, by = "hlgt_code")
  ret <- dplyr::left_join(ret, data$hlt.asc, by = "hlt_code")
  ret <- dplyr::left_join(ret, data$hlt_pt.asc, by = "hlt_code")
  ret <- dplyr::left_join(ret, data$pt.asc, by = "pt_code")
  ret <- dplyr::left_join(ret, data$llt.asc, by = "pt_code")
  md_heir_prep <- data$mdhier.asc[, c("soc_code", "pt_soc_code", "pt_code", "primary_soc_fg")]
  ret <- dplyr::left_join(ret, md_heir_prep, by = c("pt_code", "soc_code", "pt_soc_code"))
  ret
}
