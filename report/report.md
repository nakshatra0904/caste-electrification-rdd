# Caste composition and rural electrification in India

**Exploratory regression-discontinuity extension | nakshatra0904 | 11 October 2026**

## Main finding

I analysed 12,533 real villages, covering 1,342 administrative blocks and 129 districts across 12 states. I found no clear primary evidence that RGGVY eligibility effects on domestic village availability or household electric lighting differ with baseline SC/ST composition after adjustment for four primary comparisons. This is not evidence that benefits are equal.

For household electric lighting, a 10-percentage-point larger baseline SC share is associated with an estimated -0.76-percentage-point difference in the eligibility effect (95% interval -1.56 to +0.04; raw p=0.064; Holm p=0.257). The corresponding ST estimate is -0.39 pp (95% interval -1.09 to +0.31; Holm p=0.823).

## Question and contribution

I ask whether policy eligibility at a population threshold delivers comparable access and adoption gains in villages with different pre-policy Scheduled Caste and Scheduled Tribe shares. I examine SC and ST separately.

I conduct an analytical extension using public replication data and an existing policy experiment. Caste and electricity have already been studied. The specific contribution is heterogeneity in the eligibility-induced discontinuity at the 300-person boundary, separating village availability from household lighting adoption. Publication-level novelty is not established.

Burlig and Preonas provide the underlying RGGVY design. Sedai and coauthors study marginalized household welfare with IHDS panel data and instrumental variables. Azam studies tribal concentration and later satellite-based reliability. Dugoua and coauthors study geographic and socioeconomic barriers. My village-level local policy comparisons address a narrower question and do not measure individual caste-specific treatment effects.

## Data and audit

The source archive contains 580,643 records and 943 variables. I checked its 2,294,890,843-byte Stata file against the archive MD5. The shipped extract retains 55,320 candidate villages with documented columns. All identifiers in this extract are unique; shares and binary outcomes passed range checks.

I retained first-wave programme districts, valid geography, night-light matches, habitation matches, single-habitation villages and positive 2001 population. Kerala is removed, following the original code. The compact extract retains population 1-999. The preferred sample also excludes >20% Census/habitation population mismatches and projected night-light changes >=20. See the sample-flow table and source manifest for exact counts.

The main window is population 200-399, with 12,533 villages. A 200-person bandwidth covers 100-499, avoiding the separate 500-person road-policy threshold. States: ANDHRA PRADESH, BIHAR, CHHATTISGARH, GUJARAT, HARYANA, JHARKHAND, KARNATAKA, MADHYA PRADESH, MAHARASHTRA, ORISSA, RAJASTHAN, WEST BENGAL.

Village domestic availability is a binary Census indicator. Household electric lighting is the village share of households reporting electricity as their main source of light. Neither is kWh or a measure of continuous, reliable supply. Caste shares come from 2001, before RGGVY. All outcomes are village aggregates.

## Design and estimand

Eligibility is Census 2001 population >=300; integer population is centered at 299.5. Estimates are local intent-to-treat effects of eligibility, not the causal effect of actual electricity receipt. Only single-habitation villages are used because the eligibility rule applied to habitations. Later 100-person rules are not pooled into this design.

The primary interacted regression includes eligibility, population centered at the cutoff, their interaction, baseline SC and ST shares, and separate interactions of each share with eligibility and both population slopes. State fixed effects are included. Shares are scaled so each caste coefficient represents a +10-percentage-point change in baseline composition.

I use triangular weights and a prespecified 100-person bandwidth; block-clustered CR1 standard errors and t-based intervals use cluster degrees of freedom. Bandwidths of 50, 150 and 200 are sensitivities. Pooled rdrobust benchmarks use state covariates, data-driven or fixed bandwidths, mass-point adjustment and robust bias-corrected intervals. Fixed-bandwidth caste-interaction intervals are conventional and exploratory; they are not bias-corrected heterogeneity intervals.

## Pooled regression-discontinuity results

The compiled formal report contains these results in Section 5.1, Table 2. Effects and robust bias-corrected intervals are in percentage points. These benchmarks are descriptive; the prespecified primary family consists of four caste-interaction tests.

- Domestic availability, mserd: bias-corrected effect -0.72 pp; robust 95% interval [-3.76, +2.33]; p=0.645; N_h=7,533; blocks in h=1,173.

- Domestic availability, fixed_100: bias-corrected effect -0.54 pp; robust 95% interval [-2.93, +1.85]; p=0.657; N_h=12,529; blocks in h=1,342.

- Household lighting, mserd: bias-corrected effect +1.09 pp; robust 95% interval [-2.23, +4.41]; p=0.521; N_h=10,682; blocks in h=1,288.

- Household lighting, fixed_100: bias-corrected effect +1.10 pp; robust 95% interval [-1.94, +4.14]; p=0.479; N_h=12,533; blocks in h=1,342.

- Commercial availability, mserd: bias-corrected effect +3.59 pp; robust 95% interval [-1.74, +8.91]; p=0.187; N_h=8,666; blocks in h=1,222.

- Commercial availability, fixed_100: bias-corrected effect +3.67 pp; robust 95% interval [-0.82, +8.16]; p=0.110; N_h=12,529; blocks in h=1,342.

- All-sector availability, mserd: bias-corrected effect +2.86 pp; robust 95% interval [-2.61, +8.33]; p=0.306; N_h=8,267; blocks in h=1,205.

- All-sector availability, fixed_100: bias-corrected effect +2.94 pp; robust 95% interval [-1.60, +7.49]; p=0.204; N_h=12,529; blocks in h=1,342.

## Primary results

- Domestic availability / SC: +0.14 [-0.54, +0.81] pp per +10 pp share; raw p=0.691, Holm p=1.000, N=12,529.

- Domestic availability / ST: -0.08 [-0.62, +0.47] pp per +10 pp share; raw p=0.784, Holm p=1.000, N=12,529.

- Household lighting / SC: -0.76 [-1.56, +0.04] pp per +10 pp share; raw p=0.064, Holm p=0.257, N=12,533.

- Household lighting / ST: -0.39 [-1.09, +0.31] pp per +10 pp share; raw p=0.274, Holm p=0.823, N=12,533.

All four primary Holm-adjusted p-values exceed 0.05. The weak domestic-availability jump is consistent with the published study, which finds its clearer first-stage gains in commercial and all-sector access. It should not be interpreted as evidence that RGGVY did nothing nationally.

## Exploratory productive-electricity and employment results

I added commercial and all-sector availability after inspecting the first domestic/adoption benchmark and the published paper. They remain explicitly exploratory and join employment outcomes in a 12-comparison Holm-adjusted family. Original primary tests are unchanged.

- All work / SC: +0.13 [-0.24, +0.50] pp per +10 pp share; raw p=0.480, Holm p=1.000.

- All work / ST: +0.06 [-0.22, +0.35] pp per +10 pp share; raw p=0.674, Holm p=1.000.

- Female work / SC: +0.09 [-0.52, +0.70] pp per +10 pp share; raw p=0.771, Holm p=1.000.

- Female work / ST: -0.04 [-0.50, +0.42] pp per +10 pp share; raw p=0.862, Holm p=1.000.

- Other work / SC: +0.06 [-0.23, +0.36] pp per +10 pp share; raw p=0.669, Holm p=1.000.

- Other work / ST: +0.02 [-0.18, +0.22] pp per +10 pp share; raw p=0.852, Holm p=1.000.

- Female other work / SC: +0.06 [-0.22, +0.35] pp per +10 pp share; raw p=0.664, Holm p=1.000.

- Female other work / ST: +0.08 [-0.12, +0.28] pp per +10 pp share; raw p=0.447, Holm p=1.000.

- Commercial availability / SC: -1.31 [-2.67, +0.06] pp per +10 pp share; raw p=0.060, Holm p=0.660.

- Commercial availability / ST: -0.07 [-1.08, +0.94] pp per +10 pp share; raw p=0.889, Holm p=1.000.

- All-sector availability / SC: -1.37 [-2.71, -0.04] pp per +10 pp share; raw p=0.044, Holm p=0.524.

- All-sector availability / ST: -0.25 [-1.24, +0.73] pp per +10 pp share; raw p=0.617, Holm p=1.000.

## Diagnostics and robustness

Baseline SC/ST shares, domestic access, household lighting, literacy and 2001 night lights show no significant discontinuity after the six-check Holm adjustment. This supports, but cannot prove, the continuity assumption. Integer-population frequencies are plotted; no continuous-density test is presented as proof of no sorting.

Allowing state-specific eligibility jumps and population slopes changes the household-lighting interactions to SC -0.76 [-1.55, +0.03] and ST -0.51 [-1.25, +0.24] pp per +10 pp share. All sensitivity estimates, including omissions of the post-policy light-change filter, district clustering, a +/-5-person donut and baseline adjustment, are retained in specification_sensitivity.csv.

Subgroup regressions compare >=50% SC villages, >=50% ST villages and other villages separately. They require at least 50 observations and 20 blocks on each side. These comparisons remain exploratory and do not replace the continuous-share specification.

Placebo cutoffs at 149.5 and 449.5 use 50-person windows excluding the real 299.5 boundary. Seven annual pre-policy night-light tests (1998-2004) are reported. Placebo or balance non-rejection is not proof of design validity.

## Limits and policy interpretation

The data cannot establish discrimination, individual SC/ST household impacts, reliable electricity consumption, or present-day conditions. Caste composition is correlated with geography, remoteness and institutions. State-specific discontinuity checks help assess geographic treatment heterogeneity, but do not identify a causal effect of caste composition itself.

No fuzzy-RDD LATE is claimed for domestic electricity: the primary domestic-access first stage is weak, and electricity availability, adoption and reliability are different treatment margins. Multiple-testing correction and bandwidth sensitivity discourage selecting a favorable isolated estimate.

The policy-relevant conclusion is a measurement and identification distinction: existing descriptive access gaps do not automatically establish unequal causal gains from this eligibility rule. Better village and individual-level reliability data, and a larger or later-period design, would be needed to make stronger distributional claims.

## Reproduction and execution status

I produced all numerical outputs and eighteen figures using Python statistical libraries and provide a matching Stata pipeline as the primary code implementation. I have not executed the Stata pipeline because Stata was unavailable; its runtime verification remains outstanding. I independently checked the main clustered WLS coefficients and covariance matrices using direct matrix formulas, and audited the source and transformed data; see verification/execution_status.json.

Run stata/00_master.do from the repository root. It uses the shipped source extract, recreates cleaned data, regressions, diagnostics and 18 graphs, and writes to stata_generated/ so delivered outputs are preserved. It installs rdrobust if absent; without that package the built-in Stata analysis still runs and explicitly skips pooled robust-bias-corrected benchmarks.

## References

- [Burlig, F. and Preonas, L. (2024). Out of the Darkness and into the Light? Development Effects of Rural Electrification. Journal of Political Economy 132(9), 2937-2971.](https://doi.org/10.1086/730204)

- [Burlig and Preonas replication archive, Harvard Dataverse.](https://doi.org/10.7910/DVN/APWICK)

- [Sedai, A. K., Jamasb, T., Nepal, R. and Miller, R. (2021). Electrification and welfare for the marginalized: Evidence from India. Energy Economics 102.](https://www.sciencedirect.com/science/article/abs/pii/S0140988321003595)

- [Azam, M. (2026). The Enclave Penalty: Tribes, Caste, and Electricity Reliability in India. IZA Discussion Paper 18493.](https://docs.iza.org/dp18493.pdf)

- [Dugoua, E., Liu, R. and Urpelainen, J. (2017). Geographic and socio-economic barriers to rural electrification: New evidence from Indian villages. Energy Policy 106, 278-287.](https://www.sciencedirect.com/science/article/abs/pii/S0301421517301921)

- [Calonico, Cattaneo, Farrell and Titiunik: rdrobust software and references.](https://github.com/rdpackages/rdrobust)

## Reviewed formal report and audit

I compiled the 26-page formal PDF from report.tex using LuaLaTeX (TeX Live 2026) through TeXLive.net. All eighteen repository graphs are reproduced with captions on landscape pages 9-26 in Appendix B, alongside the three main-text summaries. The supplied report/assets/ folder is required when recompiling locally. I independently audited the full source data, transforms, sample counts, multiple-testing adjustments, confidence intervals and output links, and checked all eight main coefficient vectors and cluster covariance matrices with direct matrix calculations. The main conclusion is unchanged. Details are recorded in docs/corrections.md; complete regression coefficients are in Table 5 of the formal PDF and tables/full_model_*.csv.
