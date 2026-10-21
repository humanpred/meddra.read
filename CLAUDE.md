# meddra.read — Claude project guide

This file orients Claude (and human contributors) to the package. Read it
before grepping. It complements `~/.claude/CLAUDE.md` (which covers global
R-package and R-on-Windows conventions) — only project-specific content lives
here.

## Purpose

Load 'MedDRA' (Medical Dictionary for Regulatory Activities) ASCII
distribution files into R and flatten the hierarchy into a tidy data.frame.
Two exported functions, no UI, no fetching — input is a local directory the
user already has under a MedDRA license.

## Architecture / data flow

```
  <dir>/MedAscii/*.asc          <dir>/SeqAscii/*.seq  (or MedSeq/*.seq)
        |                              |
        +-------- read_meddra() -------+
                       |
                       v
        named list of data.frames
        (one per file, keyed by lowercase filename;
         legacy "+" cols and "null_field" cols already dropped)
                       |
                       v
                  join_meddra()
                       |
                       v
        flat tidy data.frame, one row per LLT,
        full SOC -> HLGT -> HLT -> PT -> LLT hierarchy on each row
```

`read_meddra()` only parses; `join_meddra()` only joins. The two are
deliberately separable so callers can work with the raw list (e.g. SMQs,
release metadata, history) without paying for the join.

## Source map

- `R/read_meddra.R:10` — `read_meddra(directory)` exported entry point.
  Resolves `MedAscii/` and `SeqAscii/`-or-`MedSeq/` subdirs, dispatches to
  `read_meddra_dir()` twice, `append()`s the two named lists.
- `R/read_meddra.R:24` — `read_meddra_dir(directory, extension)` internal.
  Lists files by extension, names them by lowercase basename, sorts, and
  `lapply`s `read_meddra_file()`.
- `R/read_meddra.R:34` — `colnames_meddra_files` constant. The spec for every
  supported file (both `.asc` and `.seq`). Each entry references the relevant
  table in `dist_file_format_25_1_English.pdf` (or older spec PDFs for legacy
  files). **This is where new file support is added.**
- `R/read_meddra.R:99` — `meddra_data_in_last_column` constant. Files whose
  last column legitimately carries data (`meddra_history_english.asc`,
  `meddra_history.asc`).
- `R/read_meddra.R:105` — `meddra_data_in_last_column_maybe` constant.
  `SMQ_List.asc` — warn instead of error if last column has data.
- `R/read_meddra.R:107` — `read_meddra_file(filename)` internal. Parses one
  file: handles empty files, missing trailing newlines, last-column quirks,
  legacy `+` columns, and `null_field` placeholders.
- `R/join_meddra.R:12` — `join_meddra(data)` exported. Eight chained
  `dplyr::left_join`s through `soc → soc_hlgt → hlgt → hlgt_hlt → hlt →
  hlt_pt → pt → llt`, then a final join against a 4-column subset of
  `mdhier.asc` keyed on `(pt_code, soc_code, pt_soc_code)` to attach
  `primary_soc_fg`.
- `R/join_smq.R` — `join_smq(data)` exported. Expands every SMQ into one row
  per LLT with the full hierarchy. Reuses `join_meddra()` for the hierarchy,
  then `inner_join`s SMQ members onto it: PT members (`term_level == 4`) by
  `pt_code` (→ all LLTs of the PT), LLT members (`term_level == 5`) by
  `llt_code`. `inner_join` (not `left_join`) so orphan terms with no hierarchy
  match are dropped rather than emitting all-NA rows.
- `R/join_smq.R` — `flatten_smq_content()` / `flatten_smq_one()` internal.
  Recursively resolve sub-SMQ references (`term_level == 0`, where `term_code`
  is a child `smq_code`) to PT/LLT-only rows via an iterative, cycle-safe
  worklist; relabel kept rows to the top-level `smq_code`. **This is where the
  SMQ expansion logic lives.**

## MedDRA domain crib sheet

Hierarchy, top-to-bottom — every level has a numeric `*_code` and a text
`*_name`:

| Level | Abbreviation | Meaning |
|-------|--------------|---------|
| 1 | **SOC** | System Organ Class (also has `soc_abbrev`) |
| 2 | **HLGT** | High Level Group Term |
| 3 | **HLT** | High Level Term |
| 4 | **PT** | Preferred Term |
| 5 | **LLT** | Lowest Level Term (also has `llt_currency`) |

Other concepts:

- A **PT can belong to multiple SOCs**. `primary_soc_fg = "Y"` marks the
  primary SOC for that PT. `pt_soc_code` carries the primary SOC of the PT
  (so a PT row appears once per SOC it links to, but `pt_soc_code` is
  constant for the PT).
- `llt_currency = "Y"/"N"` — whether an LLT is currently in use. Most
  downstream analyses filter to `"Y"`.
- **SMQ** = Standardised MedDRA Query — curated term groupings for safety
  analysis. Lives in `smq_list.asc` (definitions) and `smq_content.asc`
  (term membership). Not joined into `join_meddra()` output; use `join_smq()`
  to expand them into per-LLT rows. In `smq_content.asc`: `term_level` is
  **4 = PT**, **5 = LLT**, **0 = sub-SMQ** (then `term_code` is a child
  `smq_code`, resolved recursively); `term_scope` is **1 = broad**,
  **2 = narrow**. SMQs are defined at the PT level, so PT members expand down
  to all their LLTs for merging against LLT-coded adverse events.
- **Specialties** (`spec.asc`, `spec_pt.asc`) — alternate cross-cuts of PTs.
  Not joined into `join_meddra()` output.

File-set roles:

- **Concept definitions:** `soc.asc`, `hlgt.asc`, `hlt.asc`, `pt.asc`,
  `llt.asc`.
- **Hierarchy links:** `soc_hlgt.asc`, `hlgt_hlt.asc`, `hlt_pt.asc`.
- **Flattened hierarchy:** `mdhier.asc` (the only place `primary_soc_fg`
  lives).
- **Specialties:** `spec.asc`, `spec_pt.asc`.
- **SMQs:** `smq_list.asc`, `smq_content.asc`.
- **Metadata:** `meddra_release.asc` (version/language),
  `meddra_history_english.asc` (change log), `intl_ord.asc` (SOC ordering).
- **`SeqAscii/*.seq` files** mirror the `.asc` files but prepend three
  change-tracking columns: `*_version_date`, `*_action_code`, `*_mod_fld_num`.

## File-format quirks the code already handles

Don't re-discover these — they're encoded in `R/read_meddra.R`:

- **Legacy cross-coding columns** ending in `+` (WHO-ART, HARTS, COSTART,
  ICD-9/9CM/10, JART) — empty since MedDRA 15.0; stripped on read
  (`R/read_meddra.R:156-159`).
- **`null_field` columns** — placeholders in the spec; stripped on read
  (same location).
- **Seq directory naming:** accepts either `SeqAscii/` (current) or `MedSeq/`
  (v23.1+ variant) — `R/read_meddra.R:13`.
- **Empty `.asc` files** — valid since MedDRA 28.0; produce zero-row
  data.frames with correct schema (`R/read_meddra.R:116`).
- **Missing trailing newlines** — read via `readLines` + `read.delim(text=)`
  to suppress the warning (`R/read_meddra.R:115`).
- **Filename case insensitivity** — files are keyed by `tolower(basename())`
  so v9.1-style mixed-case names work (`R/read_meddra.R:27`).
- **Last-column-has-data files** — `meddra_history*.asc` keep it,
  `SMQ_List.asc` warns, everything else errors if the last column isn't NA
  (`R/read_meddra.R:141-149`).

## `join_meddra()` output columns

Order matches the source:

`soc_code, soc_name, soc_abbrev, hlgt_code, hlgt_name, hlt_code, hlt_name,
pt_code, pt_name, pt_soc_code, llt_code, llt_name, llt_currency,
primary_soc_fg`.

If you add a column here, update the `@return` block in `R/join_meddra.R`,
the column-list section in `vignettes/meddra-read.Rmd`, and `NEWS.md`.

## Tests and fixtures

`tests/testthat/test-read_meddra.R` carries the real coverage — every quirk
above has a fixture under `tests/testthat/data/`:

| Fixture directory | What it exercises |
|---|---|
| `empty_file/` | empty `.asc` / `.seq` files (MedDRA 28.0+) |
| `capitalization_9.1/` | mixed-case filenames (MedDRA 9.1) |
| `last_column/` | trailing NA column (standard case) |
| `last_column_10.0/` | trailing column legitimately has data |
| `unique_medseq_23.1/` | `MedSeq/` directory variant |
| `missing_asc/` | missing `MedAscii/` directory (error path) |
| `missing_seq/` | missing seq directory (error path) |

`tests/testthat/test-join_meddra.R` is minimal — it only asserts the return
class. Real join logic isn't covered yet; that's a known follow-up.

No `helper-*.R` files. Tests build fixtures inline or load via
`test_path("data/...")`.

`inst/example_meddra/` (full `MedAscii/` + `SeqAscii/` synthetic data) is for
vignettes and examples — accessed via
`system.file("example_meddra", package = "meddra.read")`. **It is not used
by tests** — keep the two separate.

## Docs, CI, release

- `man/*.Rd` and `NAMESPACE` are roxygen2-generated — never hand-edit. Run
  `devtools::document()` after changing roxygen comments or exports.
- `vignettes/meddra-read.Rmd` — keep in sync if user-facing API changes. If
  a new vignette is added, list it in `_pkgdown.yml`.
- `_pkgdown.yml` builds the site at https://humanpred.github.io/meddra.read/
  via `.github/workflows/pkgdown.yaml`.
- `inst/WORDLIST` — add MedDRA acronyms / domain terms here when the
  `spelling` check flags them.
- `cran-comments.md` records the licensing constraint: real MedDRA data
  can't be bundled or fetched remotely, so all examples must run off
  `inst/example_meddra/`.
- CI workflows (`.github/workflows/`):
  - `R-CMD-check.yaml` — macOS / Windows / Ubuntu × {release, devel,
    oldrel-1}.
  - `test-coverage.yaml` — Codecov upload.
  - `pkgdown.yaml` — deploys to gh-pages.

## Best practices for common modifications

- **Add support for a new MedDRA file type** — add an entry to
  `colnames_meddra_files` in `R/read_meddra.R` (keyed by lowercase
  filename), with a comment pointing at the relevant
  `dist_file_format_*_English.pdf` table. Add a fixture under
  `tests/testthat/data/` and a `test_that()` case. If the file's last
  column legitimately holds data, also extend `meddra_data_in_last_column`
  or `meddra_data_in_last_column_maybe`.
- **Extend `join_meddra()` output** — add the `left_join` step; update the
  `@return` roxygen block in `R/join_meddra.R`; update the output-column
  section in `vignettes/meddra-read.Rmd`; add to `NEWS.md`.
- **Change `join_smq()` output** — keep the `col_order`/`member_cols` vectors,
  the `@return` roxygen block in `R/join_smq.R`, the vignette "Expanding an SMQ
  into dictionary terms" section (incl. the SAS/ADaM rename table), and
  `NEWS.md` in sync. Tests live in `tests/testthat/test-join_smq.R` (inline
  fixtures, not the `data/` directory).
- **Support a new MedDRA version** — diff the new format-doc PDF against
  `colnames_meddra_files`; update column lists and the spec-section
  comments; add a versioned fixture (`tests/testthat/data/<feature>_<ver>/`)
  if parsing behavior diverges.
- **Pre-commit checklist** — if roxygen comments or function signatures
  changed: `devtools::document()` and stage updated `NAMESPACE` / `man/`.
  If exports / deps / docs changed: `devtools::check()`. Update `NEWS.md`
  for user-facing changes (once version > 0.0.1).

## Cross-references

- Global R-on-Windows quirks and R-package workflow checklist:
  `~/.claude/CLAUDE.md`.
- Persistent project context (lifecycle, licensing, external URLs):
  `~/.claude/projects/C--git-meddra-read/memory/`.
