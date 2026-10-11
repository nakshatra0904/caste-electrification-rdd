# Run from any directory: Rscript R/00_master.R [output_directory]
# I rebuild the analysis from the verified real source extract.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
PROJECT <- if (length(script_arg)) dirname(dirname(normalizePath(sub("^--file=", "", script_arg[1])))) else normalizePath(getwd())
OUT <- if (length(args)) normalizePath(args[1], mustWork = FALSE) else file.path(PROJECT, "r_generated")
local_library <- Sys.getenv("STUDY_R_LIBRARY", file.path(PROJECT, "r_library"))
if (dir.exists(local_library)) .libPaths(c(local_library, .libPaths()))
required <- c("haven", "jsonlite", "rdrobust")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Run R/install_packages.R first. Missing packages: ", paste(missing, collapse = ", "))
options(stringsAsFactors = FALSE, scipen = 999, warn = 1)
for (folder in c("data", "tables", "figures", "report/assets", "verification")) dir.create(file.path(OUT, folder), recursive = TRUE, showWarnings = FALSE)
T <- file.path(OUT, "tables"); F <- file.path(OUT, "figures"); V <- file.path(OUT, "verification")
log_file <- file.path(V, "R_execution.log")
log_connection <- file(log_file, "wt")
sink(log_connection, split = TRUE)
tryCatch({
  source(file.path(PROJECT, "R/helpers.R"))
  for (name in c("01_prepare.R", "02_descriptives.R", "03_rdd.R", "04_robustness.R", "05_graphs.R", "06_validate.R")) {
    cat("Running", name, "\n")
    source(file.path(PROJECT, "R", name))
  }
  writeLines(capture.output(sessionInfo()), file.path(V, "R_sessionInfo.txt"))
  cat("Completed: real-data preparation, regressions, diagnostics, 18 graphs and validation.\n")
}, finally = {sink(); close(log_connection)})
