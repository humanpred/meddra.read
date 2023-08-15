devtools::load_all()
foo <- read_meddra("C:/git/gitlab/customers/pfizer/projects/pfe-2023-001 placebo meta-analysis refresh/Data/Raw/Reference Files/MedDRA/MedDRA 25.1 English")
fooj <- join_meddra(foo)
