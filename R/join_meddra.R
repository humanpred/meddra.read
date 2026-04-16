#' Combine together all of the MedDRA terms into a single data.frame
#'
#' @param data MedDRA source data from `read_meddra()`
#' @return A data.frame with the "soc_code", "soc_name", "soc_abbrev",
#'   "hlgt_code", "hlgt_name", "hlt_code", "hlt_name", "pt_code", "pt_name",
#'   "pt_soc_code", "llt_code", "llt_name", and "llt_currency"
#' @examples
#' example_dir <- system.file("example_meddra", package = "meddra.read")
#' meddra_raw <- read_meddra(example_dir)
#' meddra_df <- join_meddra(meddra_raw)
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
