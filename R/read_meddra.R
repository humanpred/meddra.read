#' Read MedDRA datasets from the source MedDRA datasets
#'
#' @param directory the directory containing the MedAscii and SeqAscii
#'   directories
#' @return A list of data.frames for each file in the MedDRA source distribution
#' @export
read_meddra <- function(directory) {
  dirs_available <- list.dirs(path = directory, full.names = FALSE)
  medascii_dir <- intersect("MedAscii", dirs_available)
  seqascii_dir <- intersect(c("SeqAscii", "MedSeq"), dirs_available)
  if (length(medascii_dir) != 1) {
    stop("MedAscii directory was not found in ", directory)
  } else if (length(seqascii_dir) != 1) {
    stop("SeqAscii (or MedSeq) directory was not found in ", directory)
  }
  medascii_data <- read_meddra_dir(file.path(directory, medascii_dir), extension = "asc")
  seqascii_data <- read_meddra_dir(file.path(directory, seqascii_dir), extension = "seq")
  append(medascii_data, seqascii_data)
}

read_meddra_dir <- function(directory, extension) {
  files <- list.files(directory, full.names = TRUE, pattern = sprintf("\\.%s$", extension))
  stopifnot(length(files) > 0)
  files <- setNames(files, basename(files))
  lapply(X = files, FUN = read_meddra_file)
}

# column names ending in "+" should have no data in them because they were used
# prior to MedDRA 15.0 but now contain no data (according to footnotes under
# each of the section 3 tables in dist_file_format_25_1_English.pdf).
colnames_meddra_files <-
  list(
    # Table 2-2 in dist_file_format_25_1_English.pdf
    meddra_history_english.asc = c("term_code", "term_name", "term_addition_version", "term_type", "llt_currency", "action"),
    # Table 2-2 in ASCII_seq_datafiles_15_0_English.pdf (same as more recent _english version)
    meddra_history.asc = c("term_code", "term_name", "term_addition_version", "term_type", "llt_currency", "action"),
    # Table 2-3 in dist_file_format_25_1_English.pdf
    meddra_release.asc = c("version", "language", "null_field", "null_field", "null_field"),

    # Table 3-1 in dist_file_format_25_1_English.pdf
    llt.asc = c("llt_code", "llt_name", "pt_code", "llt_whoart_code+", "llt_harts_code+", "llt_costart_sym+", "llt_icd9_code+", "llt_icd9cm_code+", "llt_icd10_code+", "llt_currency", "llt_jart_code+"),
    # Table 3-2 in dist_file_format_25_1_English.pdf
    pt.asc = c("pt_code", "pt_name", "null_field", "pt_soc_code", "pt_whoart_code+", "pt_harts_code+", "pt_costart_sym+", "pt_icd9_code+", "pt_icd9cm_code+", "pt_icd10_code+", "pt_jart_code+"),
    # Table 3-3 in dist_file_format_25_1_English.pdf
    hlt.asc = c("hlt_code", "hlt_name", "hlt_whoart_code+", "hlt_harts_code+", "hlt_costart_sym+", "hlt_icd9_code+", "hlt_icd9cm_code+", "hlt_icd10_code+", "hlt_jart_code+"),
    # Table 3-5 in dist_file_format_25_1_English.pdf
    hlgt.asc = c("hlgt_code", "hlgt_name", "hlgt_whoart_code+", "hlgt_harts_code+", "hlgt_costart_sym+", "hlgt_icd9_code+", "hlgt_icd9cm_code+", "hlgt_icd10_code+", "hlgt_jart_code+"),
    # Table 3-7 in dist_file_format_25_1_English.pdf
    soc.asc = c("soc_code", "soc_name", "soc_abbrev", "soc_whoart_code+", "soc_harts_code+", "soc_costart_sym+", "soc_icd9_code+", "soc_icd9cm_code+", "soc_icd10_code+", "soc_jart_code+"),

    # Table 3-4 in dist_file_format_25_1_English.pdf
    hlt_pt.asc = c("hlt_code", "pt_code"),
    # Table 3-6 in dist_file_format_25_1_English.pdf
    hlgt_hlt.asc = c("hlgt_code", "hlt_code"),
    # Table 3-8 in dist_file_format_25_1_English.pdf
    soc_hlgt.asc = c("soc_code", "hlgt_code"),
    # Table 3-9 in dist_file_format_25_1_English.pdf
    mdhier.asc = c("pt_code", "hlt_code", "hlgt_code", "soc_code", "pt_name", "hlt_name", "hlgt_name", "soc_name", "soc_abbrev", "null_field", "pt_soc_code", "primary_soc_fg"),
    # Table 3-10 in dist_file_format_25_1_English.pdf
    intl_ord.asc = c("intl_ord_code", "soc_code"),
    # Table 3-11 in dist_file_format_25_1_English.pdf
    smq_list.asc = c("smq_code", "smq_name", "smq_level", "smq_description", "smq_source", "smq_note", "MedDRA_version", "status", "smq_algorithm"),
    # Table 3-12 in dist_file_format_25_1_English.pdf
    smq_content.asc = c("smq_code", "term_code", "term_level", "term_scope", "term_category", "term_weight", "term_status", "term_addition_version", "term_last_modified_version"),
    # Table 3-10 in asciidoc.pdf from version 9.1
    spec.asc = c("spec_code", "spec_name", "spec_abbrev"),
    # Table 3-11 in asciidoc.pdf from version 9.1
    spec_pt.asc = c("spec_code", "pt_code"),

    # Table 8-1 in dist_file_format_25_1_English.pdf
    llt.seq = c("llt_version_date", "llt_action_code", "llt_mod_fld_num", "llt_code", "llt_name", "pt_code", "llt_whoart_code", "llt_harts_code", "llt_costart_sym", "llt_icd9_code", "llt_icd9cm_code", "llt_icd10_code", "llt_currency", "llt_jart_code"),
    # Table 8-2 in dist_file_format_25_1_English.pdf
    pt.seq = c("pt_version_date", "pt_action_code", "pt_mod_fld_num", "pt_code", "pt_name", "null_field", "pt_soc_code", "pt_whoart_code", "pt_harts_code", "pt_costart_sym", "pt_icd9_code", "pt_icd9cm_code", "pt_icd10_code", "pt_jart_code"),
    # Table 8-3 in dist_file_format_25_1_English.pdf
    hlt.seq = c("hlt_version_date", "hlt_action_code", "hlt_mod_fld_num", "hlt_code", "hlt_name", "hlt_whoart_code", "hlt_harts_code", "hlt_costart_sym", "hlt_icd9_code", "hlt_icd9cm_code", "hlt_icd10_code", "hlt_jart_code"),
    # Table 8-4 in dist_file_format_25_1_English.pdf
    hlt_pt.seq = c("h_p_version_date", "h_p_action_code", "h_p_mod_fld_num", "hlt_code", "pt_code"),
    # Table 8-5 in dist_file_format_25_1_English.pdf
    hlgt.seq = c("hlgt_version_date", "hlgt_action_code", "hlgt_mod_fld_num", "hlgt_code", "hlgt_name", "hlgt_whoart_code", "hlgt_harts_code", "hlgt_costart_sym", "hlgt_icd9_code", "hlgt_icd9cm_code", "hlgt_icd10_code", "hlgt_jart_code"),
    # Table 8-6 in dist_file_format_25_1_English.pdf (Hlgt_code was converted to lower case as it appeared to be a typo in the table)
    hlgt_hlt.seq = c("h_h_version_date", "h_h_action_code", "h_h_mod_fld_num", "hlgt_code", "hlt_code"),
    # Table 8-7 in dist_file_format_25_1_English.pdf
    soc.seq = c("soc_version_date", "soc_action_code", "soc_mod_fld_num", "soc_code", "soc_name", "soc_abbrev", "soc_whoart_code", "soc_harts_code", "soc_costart_sym", "soc_icd9_code", "soc_icd9cm_code", "soc_icd10_code", "soc_jart_code"),
    # Table 8-8 in dist_file_format_25_1_English.pdf
    soc_hlgt.seq = c("s_h_version_date", "s_h_action_code", "s_h_mod_fld_num", "soc_code", "hlgt_code"),
    # Table 8-9 in dist_file_format_25_1_English.pdf
    mdhier.seq = c("md_version_date", "md_action_code", "md_mod_fld_num", "pt_code", "hlt_code", "hlgt_code", "soc_code", "pt_name", "hlt_name", "hlgt_name", "soc_name", "soc_abbrev", "null_field", "pt_soc_code", "primary_soc_fg"),
    # Table 8-10 in dist_file_format_25_1_English.pdf
    intl_ord.seq = c("Intl_ord_version_date", "Intl_ord_action_code", "Intl_ord_mod_fld_num", "Intl_ord_code", "soc_code"),
    # Table 3-10 in conseq.pdf from version 9.1
    spec.seq = c("spec_version_date", "spec_action_code", "spec_mod_fld_num", "spec_code", "spec_name", "spec_abbrev"),
    # Table 3-11 in conseq.pdf from version 9.1
    spec_pt.seq = c("sp_p_version_date", "sp_p_action_code", "sp_p_mod_fld_num", "spec_code", "pt_code")
  )

meddra_data_in_last_column <-
  c(
    "meddra_history_english.asc",
    "meddra_history.asc"
  )

read_meddra_file <- function(filename) {
  # Assign names based on the column names from
  # dist_file_format_25_1_English.pdf
  current_colnames <- colnames_meddra_files[[tolower(basename(filename))]]
  if (is.null(current_colnames)) {
    stop("Could not find column names for ", filename) # nocov
  }

  file_text <- readLines(filename, warn = FALSE)
  if (length(file_text) == 0) {
    # Some files (at least hlgt.seq in version 28.0) may be empty, create a
    # zero-row data.frame for those.
    ret <-
      data.frame(matrix(
        data = vector(),
        nrow = 0, ncol = length(current_colnames),
        dimnames = list(c(), current_colnames)
      ))
  } else {
    ret <-
      read.delim(
        # Some files (at least meddra_release.asc in version 28.0) are missing
        # newlines at the end, this suppresses a warning about that.
        text = file_text,
        header = FALSE,
        sep = "$"
      )
  }

  # According to the MedDRA standard (dist_file_format_25_1_English.pdf, section
  # 2), all of the last columns in the files should be blank.  Confirm that then
  # remove the last column from each file.

  # Except, it's not true for a few files.
  if (basename(filename) %in% meddra_data_in_last_column) {
    # do nothing
  } else if (nrow(ret) > 0 && all(is.na(ret[[ncol(ret)]]))) {
    ret[[ncol(ret)]] <- NULL
  } else if (nrow(ret) > 0) {
    stop("The last column should be NA in file: ", filename) # nocov
  }
  if (ncol(ret) != length(current_colnames)) {
    stop("Column names do not match for file: ", filename) # nocov
  }
  names(ret) <- current_colnames

  # Drop extra columns that are unused
  mask_remove <-
    grepl(x = current_colnames, pattern = "\\+$") |
    current_colnames == "null_field"
  ret[, !mask_remove]
}
