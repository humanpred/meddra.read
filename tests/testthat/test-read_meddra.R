test_that("read_meddra", {
  empty_example <-
    list(
      hlgt.asc = data.frame(hlgt_code = logical(0), hlgt_name = logical(0)),
      hlgt.seq =
        data.frame(
          hlgt_version_date = logical(0),
          hlgt_action_code = logical(0), hlgt_mod_fld_num = logical(0),
          hlgt_code = logical(0), hlgt_name = logical(0), hlgt_whoart_code = logical(0),
          hlgt_harts_code = logical(0), hlgt_costart_sym = logical(0),
          hlgt_icd9_code = logical(0), hlgt_icd9cm_code = logical(0),
          hlgt_icd10_code = logical(0), hlgt_jart_code = logical(0)
        )
    )

  # Loading empty files (like from version 28.0) works
  expect_silent(
    read_meddra(test_path("data/empty_file"))
  )
  expect_equal(
    read_meddra(test_path("data/empty_file")),
    empty_example
  )
  # Loading MedSeq directory from version 23.1 works
  expect_silent(
    read_meddra(test_path("data/unique_medseq_23.1"))
  )
  expect_equal(
    read_meddra(test_path("data/unique_medseq_23.1")),
    empty_example
  )
  # Loading file with last column filled works
  filled_example <-
    list(
      hlgt.asc = data.frame(hlgt_code = logical(0), hlgt_name = logical(0)),
      smq_list.asc =
        data.frame(
          smq_code = 1L, smq_name = "foo", smq_level = "foo",
          smq_description = "example foo", smq_source = "foo",
          smq_note = "notable foo", MedDRA_version = 10, status = "Y",
          smq_algorithm = "N"
        ),
      hlgt.seq =
        data.frame(
          hlgt_version_date = logical(0),
          hlgt_action_code = logical(0), hlgt_mod_fld_num = logical(0),
          hlgt_code = logical(0), hlgt_name = logical(0), hlgt_whoart_code = logical(0),
          hlgt_harts_code = logical(0), hlgt_costart_sym = logical(0),
          hlgt_icd9_code = logical(0), hlgt_icd9cm_code = logical(0),
          hlgt_icd10_code = logical(0), hlgt_jart_code = logical(0)
        )
    )
  expect_warning(
    read_meddra(test_path("data/last_column_10.0")),
    regexp = "The last column is not NA in file: .*last_column_10.0/MedAscii/SMQ_List.asc"
  )
  expect_equal(
    suppressWarnings(read_meddra(test_path("data/last_column_10.0"))),
    filled_example
  )
  # Loading mixed case filenames from version 9.1 works
  expect_silent(
    read_meddra(test_path("data/capitalization_9.1"))
  )
  expect_equal(
    read_meddra(test_path("data/capitalization_9.1")),
    empty_example
  )
  # Verify that directories are found
  expect_error(
    read_meddra(test_path("data/missing_asc")),
    regexp = "MedAscii directory was not found"
  )
  expect_error(
    read_meddra(test_path("data/missing_seq")),
    regexp = "SeqAscii \\(or MedSeq\\) directory was not found"
  )
})
