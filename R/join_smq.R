#' Expand Standardised MedDRA Queries (SMQs) into per-LLT membership rows
#'
#' Flattens each SMQ in `smq_list.asc` against `smq_content.asc` and attaches the
#' full MedDRA hierarchy, producing the dictionary term list needed to flag
#' adverse events (which are coded at the Lowest Level Term level) and to build
#' SMQ\* or CQ\* variables. Specifically it:
#'
#' * resolves sub-SMQ references (term level 0) recursively, so a hierarchical
#'   SMQ is expanded through all of its subordinate SMQs;
#' * expands Preferred Term members (term level 4) down to every Lowest Level
#'   Term beneath the Preferred Term; and
#' * attaches Lowest Level Term members (term level 5) directly.
#'
#' The hierarchy on each row comes from [join_meddra()], so a Preferred Term that
#' maps to more than one System Organ Class contributes one row per SOC path
#' (filter on `primary_soc_fg == "Y"` for a single SOC per PT). Every SMQ in
#' `smq_list.asc` is expanded, so a subordinate SMQ can also be selected on its
#' own via its `smq_code`.
#'
#' @param data MedDRA source data from [read_meddra()]. Must include the
#'   `smq_list.asc` and `smq_content.asc` elements, as well as the hierarchy
#'   files required by [join_meddra()].
#' @return A data.frame with one row per (SMQ x expanded LLT x SOC path) and the
#'   columns `smq_code`, `smq_name`, `smq_level`, `term_scope`, `term_category`,
#'   `term_weight`, `term_status`, `soc_code`, `soc_name`, `soc_abbrev`,
#'   `hlgt_code`, `hlgt_name`, `hlt_code`, `hlt_name`, `pt_code`, `pt_name`,
#'   `pt_soc_code`, `llt_code`, `llt_name`, `llt_currency`, and `primary_soc_fg`.
#'   `term_scope` is `1` (broad) or `2` (narrow); for Preferred Term members the
#'   scope is inherited by all of the Preferred Term's Lowest Level Terms.
#' @seealso [join_meddra()] for the underlying hierarchy flattening.
#' @examples
#' # The package bundles a small fictional MedDRA dataset for illustration.
#' # For real work, replace this with the path to your licensed MedDRA release.
#' example_dir <- system.file("example_meddra", package = "meddra.read")
#' meddra_raw <- read_meddra(example_dir)
#'
#' # Expand every SMQ into one row per Lowest Level Term, with the full
#' # SOC -> HLGT -> HLT -> PT -> LLT hierarchy attached to each row.
#' smq_df <- join_smq(meddra_raw)
#' smq_df
#'
#' # Typical follow-on: keep only broad-scope, current LLTs for merging.
#' subset(smq_df, term_scope == 1 & llt_currency == "Y")
#' @export
join_smq <- function(data) {
  required <- c("smq_list.asc", "smq_content.asc")
  missing <- required[!required %in% names(data)]
  if (length(missing) > 0) {
    stop(
      "`data` is missing required SMQ element(s): ",
      paste(missing, collapse = ", "),
      ". Re-run read_meddra() on a release that includes the SMQ files."
    )
  }

  # Flatten sub-SMQs to PT/LLT-only rows, then attach the SMQ name and level.
  flattened <- flatten_smq_content(data)
  flattened <-
    dplyr::left_join(
      flattened,
      data$smq_list.asc[, c("smq_code", "smq_name", "smq_level")],
      by = "smq_code"
    )
  member_cols <-
    c(
      "smq_code", "smq_name", "smq_level",
      "term_scope", "term_category", "term_weight", "term_status"
    )

  # Per-LLT hierarchy from the existing joiner.
  hier <- join_meddra(data)

  # PT members (term_level 4): term_code is a pt_code -> expand to all its LLTs.
  is_pt <- flattened$term_level %in% 4L
  pt_terms <- flattened[is_pt, member_cols, drop = FALSE]
  pt_terms$pt_code <- flattened$term_code[is_pt]
  pt_expanded <- dplyr::inner_join(pt_terms, hier, by = "pt_code")

  # LLT members (term_level 5): term_code is an llt_code -> attach that LLT.
  is_llt <- flattened$term_level %in% 5L
  llt_terms <- flattened[is_llt, member_cols, drop = FALSE]
  llt_terms$llt_code <- flattened$term_code[is_llt]
  llt_expanded <- dplyr::inner_join(llt_terms, hier, by = "llt_code")

  # Combine, de-duplicate defensively, and apply the stable column order.
  ret <- dplyr::distinct(dplyr::bind_rows(pt_expanded, llt_expanded))
  col_order <-
    c(
      "smq_code", "smq_name", "smq_level",
      "term_scope", "term_category", "term_weight", "term_status",
      "soc_code", "soc_name", "soc_abbrev",
      "hlgt_code", "hlgt_name", "hlt_code", "hlt_name",
      "pt_code", "pt_name", "pt_soc_code",
      "llt_code", "llt_name", "llt_currency", "primary_soc_fg"
    )
  ret <- ret[, col_order, drop = FALSE]
  rownames(ret) <- NULL
  ret
}

# Flatten the sub-SMQ (term_level 0) rows of a single SMQ into their constituent
# PT (term_level 4) and LLT (term_level 5) rows.
#
# A term_level 0 row is a sub-SMQ link: its term_code is the smq_code of a
# subordinate SMQ whose rows must replace it (recursively). PT/LLT rows are kept
# and relabelled to `top_smq` (the SMQ being expanded) while retaining their own
# scope/category. An iterative worklist with a `visited` set keeps this cycle
# safe and guarantees termination.
flatten_smq_one <- function(content, top_smq) {
  pending <- top_smq
  visited <- character(0)
  collected <- content[0, , drop = FALSE]
  while (length(pending) > 0) {
    cur <- pending[[1]]
    pending <- pending[-1]
    cur_chr <- as.character(cur)
    if (cur_chr %in% visited) {
      next
    }
    visited <- c(visited, cur_chr)
    rows <- content[as.character(content$smq_code) == cur_chr, , drop = FALSE]
    if (nrow(rows) == 0) {
      # An SMQ with no content (or an absent sub-SMQ) contributes nothing.
      next
    }
    is_sub <- rows$term_level %in% 0L
    keep <- rows[!is_sub, , drop = FALSE]
    if (nrow(keep) > 0) {
      keep$smq_code <- top_smq
      collected <- rbind(collected, keep)
    }
    if (any(is_sub)) {
      pending <- c(pending, rows$term_code[is_sub])
    }
  }
  collected
}

# Flatten every SMQ in smq_list.asc against smq_content.asc, returning a
# data.frame with one row per (SMQ x member term) where every row is at
# term_level 4 (PT) or 5 (LLT) and smq_code is the expanded SMQ.
flatten_smq_content <- function(data) {
  content <- data$smq_content.asc
  parts <-
    lapply(
      unique(data$smq_list.asc$smq_code),
      function(code) flatten_smq_one(content, code)
    )
  ret <- do.call(rbind, parts)
  if (is.null(ret)) {
    ret <- content[0, , drop = FALSE]
  }
  rownames(ret) <- NULL
  ret
}
