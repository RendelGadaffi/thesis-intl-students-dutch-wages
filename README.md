# Thesis: International Student Presence and Dutch Graduate Labor Market Outcomes

**Redon Ismailaga (9770879)** — Utrecht University School of Economics

Field-level shift-share instrumental variables analysis: does studying in internationalized programs affect Dutch graduates' wages? Instruments international student intensity with visa acceptance rates from IND consular data.

---

## Quick Start (Positron/RStudio)

1. Open `thesis_complete.Rmd` in Positron
2. Click **Knit** (or `Ctrl+Shift+K`)

That's it. The thesis auto-detects your data and runs everything. If processed data is missing, it sources `data_preparation.R` automatically.

## Manual Data Preparation (optional)

```r
source("data_preparation.R")
prepare_all_data()
```

This reads raw data from your thesis folder and writes processed CSVs to `data_tidy/`.

## Instrument Construction (optional)

The instrument is pre-built in `instrument_values.csv`. To rebuild:

```bash
python build_instrument.py
```

This reads CBS InternationalStudents, EthnicalMakeup, and IND Excel files to compute Z_{f,t} = Σ ω_{j,f} × VisaRate_{j,t}.

## Push to GitHub

Double-click `push_to_github.bat` — or manually:

```bash
git remote add origin https://github.com/YOUR_USERNAME/thesis-intl-students-dutch-wages.git
git push -u origin master
```

---

## File Map

| File | Purpose |
|------|---------|
| `thesis_complete.Rmd` | **Main thesis** — 937 lines, all code executable |
| `data_preparation.R` | Data pipeline (LISS + DUO WO/HBO + IND + CBS → tidy CSVs) |
| `build_instrument.py` | IV construction from raw data |
| `instrument_values.csv` | 55 field×year instrument values (11 fields × 5 years) |
| `cbs_field_shares.csv` | ω_{j,f} matrix — baseline herkomst shares by field |
| `herkomst_visa_rates.csv` | Group-level visa acceptance rates (6 groups × 5 years) |
| `country_crosswalk.csv` | IND→CBS→herkomst group mapping (171 countries) |
| `references.bib` | BibTeX citations |
| `apa.csl` | APA 7 citation style |

## Methodology

- **DV:** Log personal gross annual income (LISS panel, 2020–2024)
- **Endogenous:** Field-level international student intensity (DUO program language classification)
- **Instrument:** Z_{f,t} = Σ_j ω_{j,f} × VisaAcceptanceRate_{j,t}
  - ω_{j,f}: Predetermined (2011–2019) herkomst shares across 11 ISCED-F fields (CBS)
  - VisaAcceptanceRate_{j,t}: 1 − not_issued_rate, permit-share-weighted (IND + CBS EthnicalMakeup)
- **Estimation:** 2SLS with field + year FE, clustered SEs at field level
- **Diagnostics:** Kleibergen-Paap F, Stock-Yogo, Anderson-Rubin, Wu-Hausman
- **Heterogeneity:** STEM vs. non-STEM fields

## ISCED-F → DUO Crosswalk Design

- **Field 04** (Recht/administratie/handel): duplicated → both `economie` and `recht`
- **Field 06** (Informatica): mapped → `techniek` (CS programs in engineering faculties)
- **Unknown field**: excluded (unrepresentative 50/50 split)
