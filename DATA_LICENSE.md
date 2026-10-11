# Data provenance and license

The real village records in `data/` come from the public replication archive
for Fiona Burlig and Louis Preonas (2024), *Out of the Darkness and into the
Light? Development Effects of Rural Electrification*, Journal of Political
Economy 132(9), 2937-2971. Paper DOI: https://doi.org/10.1086/730204.

Data DOI: https://doi.org/10.7910/DVN/APWICK. Source file ID: 7887967,
`panel_dataset_full.dta`. The archive metadata declares **CC0 1.0**:
https://creativecommons.org/publicdomain/zero/1.0/.

`source_extract.dta` and its CSV counterpart retain only the documented
analysis-relevant columns and candidate villages. `analysis.dta` and its CSV
counterpart add the transformations defined in `stata/01_prepare.do`.
There are no synthetic observations. Source size and MD5 checksum were
verified; see `docs/source_manifest.json`.

The full multi-gigabyte archive and published articles are not bundled.
This repository does not redistribute confidential household microdata or
proprietary shapefiles. Village-level caste composition describes settlements,
not the caste of individual electricity users.
