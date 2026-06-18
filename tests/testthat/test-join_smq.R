# Build a small MedDRA universe with two SOC -> ... -> PT -> LLT branches plus
# SMQ list/content. Tests override `smq_content.asc` to exercise each path.
make_smq_fixture <- function() {
  list(
    soc.asc = data.frame(
      soc_code = c(1L, 2L),
      soc_name = c("universe", "void"),
      soc_abbrev = c("Univ", "Void")
    ),
    soc_hlgt.asc = data.frame(soc_code = c(1L, 2L), hlgt_code = c(20L, 21L)),
    hlgt.asc = data.frame(hlgt_code = c(20L, 21L), hlgt_name = c("galaxy", "nebula")),
    hlgt_hlt.asc = data.frame(hlgt_code = c(20L, 21L), hlt_code = c(30L, 31L)),
    hlt.asc = data.frame(hlt_code = c(30L, 31L), hlt_name = c("solar system", "cluster")),
    hlt_pt.asc = data.frame(hlt_code = c(30L, 31L), pt_code = c(40L, 41L)),
    pt.asc = data.frame(
      pt_code = c(40L, 41L),
      pt_name = c("earth", "mars"),
      pt_soc_code = c(1L, 2L)
    ),
    llt.asc = data.frame(
      llt_code = c(50L, 51L, 52L),
      llt_name = c("earth's core", "earth's crust", "mars dust"),
      pt_code = c(40L, 40L, 41L),
      llt_currency = c("Y", "N", "Y")
    ),
    mdhier.asc = data.frame(
      soc_code = c(1L, 2L),
      pt_soc_code = c(1L, 2L),
      pt_code = c(40L, 41L),
      primary_soc_fg = c("Y", "Y")
    ),
    smq_list.asc = data.frame(
      smq_code = c(20000001L, 20000002L),
      smq_name = c("Top SMQ", "Child SMQ"),
      smq_level = c(1L, 2L),
      smq_description = c("", ""),
      smq_source = c("", ""),
      smq_note = c("", ""),
      MedDRA_version = c(0, 0),
      status = c("A", "A"),
      smq_algorithm = c("N", "N")
    ),
    smq_content.asc = data.frame(
      smq_code = integer(0),
      term_code = integer(0),
      term_level = integer(0),
      term_scope = integer(0),
      term_category = character(0),
      term_weight = numeric(0),
      term_status = character(0),
      term_addition_version = numeric(0),
      term_last_modified_version = numeric(0)
    )
  )
}

test_that("join_smq expands a PT-level term to all of the PT's LLTs", {
  d <- make_smq_fixture()
  d$smq_content.asc <- data.frame(
    smq_code = 20000001L, term_code = 40L, term_level = 4L,
    term_scope = 1L, term_category = "A", term_weight = 0,
    term_status = "A", term_addition_version = 0, term_last_modified_version = 0
  )
  res <- join_smq(d)
  expect_s3_class(res, "data.frame")
  # PT 40 (earth) has LLTs 50 (current) and 51 (non-current); both appear.
  expect_setequal(res$llt_code, c(50L, 51L))
  expect_true(all(res$pt_code == 40L))
  expect_true(all(res$term_scope == 1L)) # scope flows to every LLT
  expect_true(all(res$smq_code == 20000001L))
  expect_equal(unique(res$smq_name), "Top SMQ")
  expect_true(all(c("soc_name", "primary_soc_fg") %in% names(res)))
})

test_that("join_smq attaches an LLT-level term to a single LLT", {
  d <- make_smq_fixture()
  d$smq_content.asc <- data.frame(
    smq_code = 20000001L, term_code = 50L, term_level = 5L,
    term_scope = 2L, term_category = NA_character_, term_weight = 0,
    term_status = "A", term_addition_version = 0, term_last_modified_version = 0
  )
  res <- join_smq(d)
  expect_equal(nrow(res), 1L)
  expect_equal(res$llt_code, 50L)
  expect_equal(res$term_scope, 2L)
})

test_that("join_smq recursively flattens a sub-SMQ reference", {
  d <- make_smq_fixture()
  d$smq_content.asc <- data.frame(
    smq_code = c(20000001L, 20000002L),
    term_code = c(20000002L, 41L), # parent -> child SMQ; child -> PT mars
    term_level = c(0L, 4L), # 0 = sub-SMQ link, 4 = PT
    term_scope = c(NA_integer_, 1L),
    term_category = c(NA_character_, "B"),
    term_weight = c(0, 0),
    term_status = c(NA_character_, "A"),
    term_addition_version = c(0, 0),
    term_last_modified_version = c(0, 0)
  )
  res <- join_smq(d)
  # The top SMQ resolves through the child SMQ down to mars (PT 41) -> LLT 52,
  # labelled with the top-level SMQ identity and retaining the child's scope.
  top <- res[res$smq_code == 20000001L, ]
  expect_setequal(top$llt_code, 52L)
  expect_true(all(top$term_scope == 1L))
  expect_equal(unique(top$smq_name), "Top SMQ")
  # The subordinate SMQ is also expanded on its own.
  expect_true(20000002L %in% res$smq_code)
})

test_that("join_smq errors when SMQ files are absent", {
  d <- make_smq_fixture()
  d$smq_content.asc <- NULL
  expect_error(join_smq(d), regexp = "smq_content.asc")
})

test_that("join_smq returns a typed zero-row frame for empty content", {
  d <- make_smq_fixture() # smq_content.asc is already zero-row
  res <- join_smq(d)
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0L)
  expect_true(all(c("smq_code", "llt_code", "primary_soc_fg") %in% names(res)))
})

test_that("join_smq is cycle-safe when a sub-SMQ is reached by two paths", {
  d <- make_smq_fixture()
  # Diamond: 20000001 -> {20000003, 20000004}; both -> 20000005 -> PT mars (41).
  # 20000005 is therefore reached twice while expanding 20000001.
  d$smq_content.asc <- data.frame(
    smq_code = c(20000001L, 20000001L, 20000003L, 20000004L, 20000005L),
    term_code = c(20000003L, 20000004L, 20000005L, 20000005L, 41L),
    term_level = c(0L, 0L, 0L, 0L, 4L),
    term_scope = c(NA_integer_, NA_integer_, NA_integer_, NA_integer_, 1L),
    term_category = c(NA, NA, NA, NA, "A"),
    term_weight = c(0, 0, 0, 0, 0),
    term_status = c(NA, NA, NA, NA, "A"),
    term_addition_version = c(0, 0, 0, 0, 0),
    term_last_modified_version = c(0, 0, 0, 0, 0)
  )
  res <- join_smq(d)
  top <- res[res$smq_code == 20000001L, ]
  # The shared grandchild PT (mars -> LLT 52) is included exactly once.
  expect_equal(nrow(top), 1L)
  expect_setequal(top$llt_code, 52L)
})

test_that("join_smq returns zero rows when smq_list is empty", {
  d <- make_smq_fixture()
  d$smq_list.asc <- d$smq_list.asc[0, , drop = FALSE]
  res <- join_smq(d)
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0L)
})
