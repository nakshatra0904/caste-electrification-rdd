# Project audit and corrections - 9 October 2026

The original numerical conclusion is unchanged. I made the following corrections to improve numerical consistency, output interpretation and reproducibility.

1. **Double precision:** derived SC/ST share units and night-light differences now use float64, matching Stata's generate double. Original archive variables are preserved exactly. Effects change only at numerical rounding precision.
2. **Pooled RDD cluster counts:** the earlier clusters field copied the package count, which includes the bias bandwidth. It now counts unique blocks within h. Separate fields report blocks in b, the input sample and the package return. For fixed h=100, blocks in h=1,342 and in b=1,454. Estimates, standard errors and p-values were already computed correctly and remain unchanged.
3. **Stata output exports:** the estimation file now explicitly exports complete coefficient tables for all eight outcomes, alongside model files and the log.
4. **Descriptive percentiles:** Python uses the averaged inverse empirical distribution corresponding to Stata's default percentile rule. Continuous source shares remain in their original precision.
5. **Figures:** I refreshed eighteen PNG/SVG figures with consistent blue/orange/green colours, larger readable labels, grid guides, wrapped captions, confidence-interval annotations and sample-count labels. Bin dots now use mean population, consistently in both languages. Display fits are clearly labelled unadjusted and extended to the cutoff.
6. **Formal report:** I added a pooled bias-corrected RDD table and main regression-coefficient appendix. The PDF is now compiled from its exact LaTeX source. I fixed a long-path margin overflow; final compiler log has no errors, overfull boxes or unresolved references. I visually reviewed all eight pages at that stage.
7. **Repository navigation:** README and HTML now link directly to RDD results, complete regressions and the compiled report. The old separately generated PDF reading copy was removed.

Validation: I re-extracted all 55,320 candidate villages and their source columns exactly from the full public file and verified the original size and MD5 again. All eight main coefficient vectors and CR1 cluster covariance matrices passed direct matrix calculations. I independently checked transformations, flags, CSV/.dta agreement, counts, Holm adjustments, confidence intervals and local links. The ZIP is integrity-tested and contains file checksums.

Execution limit: I reviewed the Stata code statically but have not executed it because Stata was unavailable. I produced the numerical outputs with the corresponding Python statistical methods; Stata runtime verification remains outstanding. This remains an exploratory extension with the identification and smoothing-bias limits described in the report.

## Complete graphical appendix (9 October 2026)

I added all eighteen repository graphs to the formal LaTeX PDF as Figures 4-21 in Appendix B, one per landscape page. The three summary figures and the analytical text remain in the main report. Vector PDF graph inputs are included in report/assets/; the original PNG/SVG figures remain available. I corrected a character-encoding artifact in the appendix sensitivity-plot label during visual review. I compiled the exact source and graph inputs with LuaLaTeX through TeXLive.net. I visually checked all 26 pages and the compiler log contains no errors, overfull boxes or unresolved references. Numerical estimates and datasets are unchanged.

## Repository publication (11 October 2026)

I revised the research narrative into first person, added my GitHub username as author, and prepared the complete repository for GitHub. I retained the original authors' data and literature citations, the exploratory interpretation and the outstanding Stata runtime check. I did not alter the data, regression estimates or graph results.

## Executed R conversion and public repository (12 October 2026)

I made the repository public and replaced the supplied Stata/Python analysis scripts with an executed R pipeline. The R code reconstructs the data, exports complete models, runs the diagnostics and sensitivities, uses R rdrobust and generates all eighteen graph designs. The rebuilt data and 21 numerical comparisons passed; all eight main coefficients and CR1 covariances passed an additional independent matrix check. The optional R extraction also reproduces all 55,320 source rows from the checksum-verified full archive. The conclusions and published graph designs are unchanged. I retained the original publication tables and images as independently verified reference outputs and documented R styling and package-metadata differences. Earlier execution-limit statements above describe the historical Stata version.
