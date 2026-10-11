# Caste composition and rural electrification in India

I examine whether rural electrification eligibility produced different local effects in villages with different baseline Scheduled Caste and Scheduled Tribe population shares. I use real public village data and the population-threshold design of Burlig and Preonas (2024).

Author: [nakshatra0904](https://github.com/nakshatra0904).

## Start here

- [Formal LaTeX report](report/report.tex) - authoritative report source, with embedded tables, the estimating equation, three summary figures and all eighteen repository graphs in Appendix B.
- [Compiled formal PDF report](report/report.pdf) - 26 pages, compiled directly from the accompanying LaTeX source and visually checked.
- [HTML report and 18-figure gallery](report/report.html) - open locally after extracting the ZIP.
- [Detailed text report](report/report.md)
- [Analysis plan and transparent amendment](docs/analysis_plan.md)
- [Data dictionary](docs/data_dictionary.csv)

## Main result

I analysed 12,533 real villages near the eligibility cutoff, covering 1,342 administrative blocks and 129 districts across 12 states. After adjusting for four primary comparisons, I found no clear evidence that RGGVY eligibility effects on domestic village availability or household electric lighting differed with baseline SC/ST composition. This is not evidence that benefits are equal.

For household electric lighting, I estimated a -0.76-percentage-point difference in the eligibility effect for a 10-percentage-point larger baseline SC share (95% interval -1.56 to +0.04; raw p=0.064; Holm p=0.257). The corresponding ST estimate is -0.39 pp (95% interval -1.09 to +0.31; Holm p=0.823).

Village caste composition is not individual household caste. These are local eligibility effects, not effects of caste identity, actual electricity receipt, discrimination, or national average impacts. The commercial-electricity extension is explicitly exploratory. The broader caste/electricity topic is not new.

## Repository contents

```text
data/          Real source extract and cleaned analysis data (.dta and .csv)
stata/         Master plus cleaning, descriptives, RDD, robustness and graph .do files
tables/        Executed descriptive, regression and diagnostic CSV outputs
figures/       18 figures in PNG and SVG formats
report/        Formal LaTeX source and compiled PDF, 18 vector PDF graph assets, Markdown and HTML gallery
docs/          Analysis plan, variable dictionary, source/figure manifests, references
verification/  Executed model summaries, execution status and Python verification code
```

## Compile the formal LaTeX report

`report/report.tex` uses LuaLaTeX, with `pgfplots` for the three main-text summaries and `report/assets/` for the eighteen vector graphs in Appendix B. Keep the supplied assets folder beside the source. The bibliography is included in the source. Compile twice from the report folder to resolve references:

```text
cd report
lualatex report.tex
lualatex report.tex
```

I compiled `report/report.pdf` from `report/report.tex` using LuaLaTeX (TeX Live 2026) through TeXLive.net. I checked all 26 pages visually; the final compiler log records no errors, overfull boxes or unresolved references. Appendix B occupies pages 9-26, with one graph per landscape page. Source/PDF hashes, graph coverage and the compiler log are retained in `verification/`. I kept the village datasets local during PDF compilation.

## Find the regressions and RDD results

- Report Section 4: equation, assignment cutoff and identification assumptions.
- Report Section 5.1 / Table 2: pooled bias-corrected RDD effects and confidence intervals.
- Report Section 5.2 / Table 3: primary SC/ST interaction results.
- Report Appendix A / Table 5: main regression coefficients and standard errors.
- Report Appendix B / Figures 4-21: all eighteen repository graphs, including RDD plots, balance checks and sensitivity analyses.
- `stata/03_rdd.do`: Stata estimation; `stata/04_robustness.do`: diagnostic and sensitivity specifications.
- `tables/full_model_*.csv`: complete coefficient tables for all eight outcomes; `verification/model_*.txt`: readable executed summaries.
- `tables/pooled_rdrobust.csv`: all pooled estimates, bandwidths, sample counts and properly distinguished cluster counts.

## Audit and corrections

I re-extracted all 55,320 candidate villages and verified that they matched the supplied source extract exactly. I independently checked all eight main coefficient vectors and cluster covariance matrices. I corrected double-precision transformations, pooled RDD cluster-count labels, Stata exports of complete coefficient tables and percentile conventions. I refreshed all eighteen graphs with clearer labels, consistent colours, wrapped captions and improved spacing. The main findings are unchanged. See `docs/corrections.md` and `verification/project_audit.json`.

## Run the Stata analysis

Requires Stata 16 or newer. Start Stata and change to the extracted repository root:

```stata
cd "C:/path/to/caste_electrification_study"
do "stata/00_master.do"
```

The shipped `data/source_extract.dta` is the input. The master recreates cleaned data, estimates, diagnostics and 18 graphs under `stata_generated/`; original delivered outputs remain available. Core estimation uses built-in Stata commands. Pooled robust-bias-corrected benchmarks use `rdrobust`; the master attempts installation if missing and logs a clear skip if unavailable.

I provide Stata code as the primary implementation. **I have not executed the Stata pipeline because a working Stata installation was unavailable during this analysis.** I produced the numerical outputs and figures with matching Python statistical methods. I therefore distinguish the verified numerical results from Stata runtime verification, which remains outstanding. See `verification/execution_status.json` and `docs/reproduction_notes.md`.

## Data and source checks

- Source DOI: [10.7910/DVN/APWICK](https://doi.org/10.7910/DVN/APWICK).
- Original archive: 580,643 records, 943 variables; 2,294,890,843 bytes.
- Source size and MD5 were verified; extract identifiers and ranges were audited.
- Candidate extract: 55,320 villages; preferred local sample: 12,533 villages.
- Data are real; no synthetic observations were substituted.
- Source data license: CC0 1.0; original code here: MIT. See `DATA_LICENSE.md`.
- The full multi-gigabyte source is linked, not bundled. `stata/optional_rebuild_extract.do` rebuilds the compact source extract if the original file is supplied under `raw/`.

## Design

Population is measured in the 2001 Census. Eligibility begins at 300 people, represented by a 299.5 cutoff for integer population. The sample uses single-habitation villages and the original first-wave/geography/matching rules. Main local-linear regressions have a 100-person bandwidth, triangular weights, state effects and block-clustered t inference. Baseline SC and ST shares enter separately with full side-specific slope interactions. Four primary interaction tests use Holm correction; twelve secondary interaction tests form a separate exploratory family. Sensitivities and diagnostics are retained, including state-specific discontinuities, alternative bandwidths, baseline balance, placebo cutoffs and pre-policy night lights.

Primary and sensitivity results are intent-to-treat. No domestic-electricity fuzzy-RDD LATE is claimed. Main heterogeneity intervals are conventional, with smoothing-bias limits; pooled rdrobust benchmarks use robust bias-corrected intervals and discrete-mass-point adjustment.

## Repository and download

I maintain the complete study in [caste-electrification-rdd](https://github.com/nakshatra0904/caste-electrification-rdd). It contains the compact real data, all seven Stata files, executed results, eighteen graphs in PNG/SVG, eighteen vector report assets and the formal PDF with its LaTeX source. Every bundled file is below 100 MB. The full raw archive is linked separately and excluded by `.gitignore`. You can inspect the outputs locally after downloading and extracting the repository.

## Citation

Fiona Burlig and Louis Preonas (2024), *Out of the Darkness and into the Light? Development Effects of Rural Electrification*, Journal of Political Economy 132(9), 2937-2971. [Paper](https://doi.org/10.1086/730204); [data](https://doi.org/10.7910/DVN/APWICK).

Prior caste/electricity research is discussed in the report and `docs/references.md`. I describe my contribution as a transparent replication-based extension. I credit the original data and design, and I do not claim to be the first to study caste and electrification.
