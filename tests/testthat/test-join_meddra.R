test_that("join_meddra", {
  structured_data <-
    list(
      soc.asc = data.frame(soc_code = 1L, soc_name = "universe", soc_abbrev = "Univ"),
      soc_hlgt.asc = data.frame(soc_code = 1L, hlgt_code = 2L),
      hlgt.asc = data.frame(hlgt_code = 2L, hlgt_name = "galaxy"),
      hlgt_hlt.asc = data.frame(hlgt_code = 2L, hlt_code = 3L),
      hlt.asc = data.frame(hlt_code = 3L, hlt_name = "solar system"),
      hlt_pt.asc = data.frame(hlt_code = 3L, pt_code = 4L),
      pt.asc = data.frame(pt_code = 4L, pt_name = "earth", pt_soc_code = 1L),
      llt.asc = data.frame(llt_code = 5L, llt_name = "earth's core", pt_code = 4L, llt_currency = "Y")
    )
  expect_s3_class(
    join_meddra(structured_data),
    "data.frame"
  )
})
