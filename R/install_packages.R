# Install only the three required packages into a repository-local library.
arg <- grep("^--file=", commandArgs(), value = TRUE)
root <- if (length(arg)) dirname(dirname(normalizePath(sub("^--file=", "", arg[1])))) else normalizePath(getwd())
lib <- Sys.getenv("STUDY_R_LIBRARY", file.path(root, "r_library"))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
install.packages(c("haven", "jsonlite", "rdrobust"), lib = lib, repos = "https://cloud.r-project.org")
