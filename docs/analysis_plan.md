# Caste composition and the local benefits of rural electrification

I recorded this analysis plan on 8 October 2026, before examining regression outcomes.

## Question and contribution

Does RGGVY eligibility generate comparable improvements in electricity access and household electric lighting in villages with higher baseline Scheduled Caste (SC) and Scheduled Tribe (ST) population shares?

This is an original analytical extension of public replication data, not an original policy experiment or a claim to be the first caste-and-electricity study. Burlig and Preonas (2024) provide the underlying RGGVY design. Sedai and coauthors (2021) study electrification and marginalized households using IHDS. Azam (2026) studies caste/tribal concentration and satellite-based electricity reliability. I focus the extension on heterogeneity in the policy-induced jump at the 300-person eligibility boundary. I will examine SC and ST separately because they are distinct groups.

## Identification

I will use 2001 Census village population, eligible at population >=300, represented by an RDD cutoff of 299.5 for integer population. I will restrict the sample to single-habitation villages, first-wave programme districts, and the authors' geography and merge-quality sample. The main estimates are intent-to-treat effects of eligibility. They are not effects of belonging to a caste or tribe, and they are not national average treatment effects.

## Outcomes and specifications

Primary outcomes: 2011 village electricity availability (if the verified data include the relevant measure), and the share of households using electricity as their main source of lighting. Baseline 2001 lighting provides a predetermined balance/placebo outcome and an optional precision control. Pre-policy SC and ST population shares are moderators, never their 2011 shares.

Primary heterogeneity specification: local linear weighted regressions with triangular weights, separate population slopes on each side, separate SC/ST terms and their interactions with eligibility and both population slopes. Include state fixed effects. The interaction coefficients express changes in the eligibility effect associated with a 10-percentage-point difference in baseline SC/ST share. Cluster inference by administrative block as in the published RGGVY analysis; also assess district clustering. Report confidence intervals and joint tests, not only significance stars.

I will use an a priori main bandwidth of 100 people either side and sensitivity bandwidths of 50, 150 and 200. Also report pooled local-linear rdrobust estimates with data-driven bandwidths and robust bias-corrected intervals, acknowledging integer mass points. Treat heterogeneity estimates from fixed bandwidths as exploratory and sensitive to smoothing bias. Binary majority-SC and majority-ST subgroup comparisons (>=50%) are secondary and only estimated with adequate observations and clusters on both sides. SC and ST will not be combined for the primary heterogeneity test.

Secondary outcomes: total/female work participation and non-agricultural work, if verified; these form an exploratory family with multiple-testing adjustment. No results-driven outcome or subgroup selection.

## Diagnostics and interpretation

I will audit unique village identifiers, units, missingness, source flags and sample exclusions. Report observations and clusters by side, state and caste-composition group. Check SC/ST composition, baseline lighting, literacy and pre-policy night lights at the eligibility boundary; inspect integer-population frequencies and heaping; estimate placebo cutoffs where the main cutoff is outside the estimation window. Do not interpret continuous-density diagnostics as automatically valid for discrete Census population.

The authors exclude Census/habitation population mismatches and extreme changes in night lights. Report both their preferred sample and a sensitivity sample retaining observations excluded for post-policy night-light changes, because selection on a post-treatment quantity can matter.

Night lights are not kWh. Village caste composition cannot establish individual SC/ST household treatment effects or discrimination. A statistically insignificant difference does not establish equal benefits. Weak subgroup first stages and wide intervals must be reported. All data are real public archive observations; no synthetic records will be substituted.

## Deliverables

Clean, documented .dta and .csv analysis data; original commented Stata .do files; descriptive tables and plots; regression and diagnostic outputs; a short report distinguishing the replication benchmark, extension, findings and limitations. Stata execution will be claimed only if a working Stata installation is actually used.

## Transparent amendment after first benchmark results (9 October 2026)

The original primary tests remain unchanged. Inspection of the published paper's Table 2 confirms that the programme expanded commercial and all-sector electricity access, while domestic village access was already widespread. I therefore added commercial and all-sector availability as **exploratory** outcomes, without retrospectively designating them primary outcomes. Their four caste interaction tests join the eight employment interaction tests in a 12-test Holm-adjusted secondary family. The state-specific-discontinuity sensitivity is also included to assess confounding by geographic treatment heterogeneity. This is an analysis plan, not a formally registered preregistration.

## References

- Burlig and Preonas (2024): https://doi.org/10.1086/730204
- Public replication data: https://doi.org/10.7910/DVN/APWICK
- Sedai et al. (2021): https://www.sciencedirect.com/science/article/abs/pii/S0140988321003595
- Azam (2026): https://www.iza.org/publications/dp/18493/the-enclave-penalty-tribes-caste-and-electricity-reliability-in-india

## Implementation update (12 October 2026)

I replaced the planned Stata implementation with R and executed the complete analysis. I preserved the original dated plan above as a record of the intended deliverables. The outcomes, estimands, bandwidths, multiplicity families and exploratory amendment are unchanged. The delivered code is now in R/; validation and package versions are retained in verification/.
