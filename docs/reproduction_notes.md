# Reproduction and validation

## Executed R implementation

I executed the complete pipeline in `R/00_master.R` with R 4.5.1, haven 2.5.5, jsonlite 2.0.0 and rdrobust 4.1.1. I reconstructed the analysis data from the real source extract, fitted all eight main models and their sensitivities, computed descriptives and diagnostics, and generated all eighteen graph designs in PNG, SVG and vector PDF. I also executed `R/optional_rebuild_extract.R` against the full source archive: the byte size, MD5 and all 55,320 extracted rows match.

Install the required packages with `Rscript R/install_packages.R`, then run `Rscript R/00_master.R` from the repository root. Packages are installed in `r_library/`; generated outputs go to `r_generated/`. A custom output directory is accepted as the master's first argument. The compact shipped source extract is sufficient for the full analysis. The optional archive rebuild requires the original 2.3 GB file, which is linked rather than bundled.

## Numerical checks

`R/06_validate.R` compares the rebuilt data by identifier and column, then compares 21 numerical tables by their natural keys. Main coefficients, standard errors, p-values, intervals, Holm adjustments, sensitivities, placebo checks, subgroup estimates, balance checks and descriptives passed. All eight main coefficient vectors and CR1 covariance matrices were additionally checked using direct weighted normal equations and explicit cluster score sums, independently of the QR estimation implementation.

The table tolerance is 1e-7 for the main numerical comparisons, zero for counts, and 1e-5 for pooled rdrobust output (including selected bandwidths). Actual differences are recorded by column in `verification/R_validation.json`; main coefficients agree to about 1e-14 and pooled bandwidths to about 1e-8. Package warnings about mass points are retained in `verification/rdrobust_warnings.json`: population is discrete and the benchmark uses mass-point adjustment. A failed comparison stops the pipeline. Future package revisions may change data-driven bandwidths and should be checked rather than silently accepted.

I retained the published reference tables and figures, originally produced with Python, because R independently reproduces their numerical content. The supplied current implementation is entirely R. Published images and native R graphs need not be pixel-identical. I include the executed R model summaries, run log, session information, package versions and validation records; the master generates all new outputs when rerun. `data/analysis.rds` is the R-native analysis dataset.

## Estimation and metadata

The weighted local-linear models use state effects, triangular weights, full SC/ST side-specific slope interactions, block-clustered CR1 covariance and t inference with G-1 degrees of freedom. Descriptive quartiles use R quantile type 2, matching the averaged inverse empirical distribution used in the reference outputs. Original archive columns retain their source precision; derived transformations use double precision. A village with both SC and ST shares exactly 50% is assigned to the ST group consistently.

In pooled outputs, `clusters` counts distinct blocks within h, `clusters_bias` within b and `clusters_input` within the input sample. The historical published table's `clusters_package` is the aggregate returned by the original Python package. R rdrobust returns two side-specific counts, recorded as `clusters_package_left` and `clusters_package_right` in `verification/R_pooled_rdrobust.csv` and newly generated R tables. They cannot be added to obtain a distinct-block union because a block may occur on both sides. Validation compares shared numerical fields and recomputed h/b/input union counts; it does not equate unlike package metadata.

The extract follows the original first-wave/geography/matching restrictions and population 1-999. This extension differs from the published preferred specifications: it focuses on caste interactions, fixed-bandwidth cluster inference and state effects. I do not claim exact replication of every paper table. The pooled benchmark uses population 100-499 without excluding SC/ST villages.

## Formal report

`report/report.tex` is the authoritative source, edited in place for this R conversion. Its compiled PDF includes the equation, pooled RDD table, primary and secondary tests, three inline summaries, a coefficient appendix and all eighteen publication graphs. Compile twice with `lualatex report.tex` from `report/`, keeping `report/assets/` intact. No external bibliography file is needed. Compilation status, exact hashes and the log are retained in `verification/latex_compile_status.json`; graph coverage is in `verification/report_graph_coverage.json`.
