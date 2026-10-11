# Reproduction and validation

## Executed and unexecuted work

I extracted and transformed the data, executed the numerical analysis, produced eighteen graphs and generated the report. The main interacted weighted regressions use statsmodels WLS with CR1 cluster covariance and cluster-based t inference. I independently checked their coefficients and covariance with direct weighted normal equations and summed cluster scores. Pooled benchmarks use the official Python rdrobust package. Numerical diagnostics are retained as CSVs.

I reviewed the corresponding Stata .do pipeline statically but have not run it because Stata was unavailable during this analysis. Stata and Python graphs have the same metrics and designs but are not expected to be pixel-identical. Output formatting may differ. The data-driven rdrobust results can also differ across package releases; record the Stata rdrobust version printed to the master log before comparing.

## Comparing the Stata run

1. Run `stata/00_master.do` from the repository root.
2. Compare `stata_generated/analysis.csv` with `data/analysis.csv` by `pca01_id`.
3. Compare the main heterogeneity coefficients, standard errors and p-values against `tables/heterogeneity_results.csv` by outcome, term and bandwidth.
4. Review the master log for warnings, dropped variables or package-install failures. A missing rdrobust package does not invalidate the built-in Stata regressions, but its benchmark outputs are then unavailable.

The source extract uses the exact authors' first-wave/geography/matching restrictions and population 1-999. The extension differs from the published preferred specifications: it focuses on caste interactions, uses conventional fixed-bandwidth cluster inference and state effects, and does not claim exact replication of all paper tables. The pooled benchmark is restricted to population 100-499 and excludes neither SC nor ST villages.

## Optional Python verification

Install `verification/requirements.txt` in a separate environment and run `verification/run_analysis.py` from the repository. This is supplementary verification code; Stata remains the primary implementation. The script uses the shipped `data/analysis.dta` and writes to the repository output folders. It does not need a network connection once dependencies are installed.

The source-verification and extraction scripts are included for provenance. They require the large public source file and archive metadata; the compact delivered source extract is sufficient for the Stata master. The 2.3 GB source and package installations are intentionally excluded from this ZIP.

## Formal report

`report/report.tex` is the authoritative formal source; `report/report.pdf` is its successfully compiled 26-page PDF. It includes the equation, pooled RDD table, primary and secondary tests, three inline vector summaries, a regression-coefficient appendix, and all eighteen repository graphs in landscape Appendix B (pages 9-26). Compile twice with `lualatex report.tex` from `report/`, keeping `report/assets/` intact. The eighteen vector PDF assets preserve the plotted results and make the appendix sharp at any zoom. No external bibliography file is needed. I compiled the source and graph inputs with LuaLaTeX through TeXLive.net. The full log, source/PDF hashes and visual review status are in `verification/latex_compile_status.json`; per-graph coverage and hashes are in `verification/report_graph_coverage.json`. I removed the earlier separately generated reading copy and retain the PDF compiled from the authoritative LaTeX source.

## Audit corrections (9 October 2026)

Derived caste shares and light differences now use double precision, matching Stata's explicit double transformations. Descriptive quartiles use the averaged inverse empirical distribution, corresponding to Stata's default percentile convention. In pooled_rdrobust.csv, clusters counts unique blocks in the estimation bandwidth h; clusters_bias counts blocks in b; clusters_input counts blocks in the supplied 100-499-person sample; clusters_package records the package's returned count, whose support may include the bias bandwidth. These different counts must not be treated as interchangeable. Stata now explicitly exports every full coefficient table. Stata state dummy labels (e.g. 2.st_code) and Python labels (e.g. state_2) are equivalent; Stata's omitted reference level is not an estimated coefficient.

The single village with both SC and ST shares exactly 50% is assigned to the ST group consistently in both languages. The group labels use >=50%, so they include ties rather than strict majorities. Figure dots use actual mean population within each bin in both languages. Display fits are unadjusted and are identified as such; formal estimates use state controls and clustered inference.
