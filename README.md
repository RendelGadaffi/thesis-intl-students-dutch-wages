# Thesis: International Student Presence and Dutch Graduate Labor Market Outcomes
## Redon Ismailaga (9770879) — Utrecht University School of Economics

---

## File Overview

| File | Description |
|------|-------------|
| `thesis.Rmd` | Complete thesis document (R Markdown). Renders to PDF/HTML with embedded code, tables, and figures. |
| `data_preparation.R` | Data pipeline: reads raw data, tidies in memory, writes pre-processed CSVs to `data_tidy/`. |
| `references.bib` | BibTeX bibliography with all citations (shift-share instruments, international students, stay rates). |
| `data_tidy/` | Output directory for pre-processed datasets (created by `data_preparation.R`). |

---

## How to Run

### Step 1: Prepare Data

In Positron or RStudio, set your working directory to this folder and run:

```r
source("data_preparation.R")
prepare_all_data("C:/Users/redon/Desktop/Thesis work/DATA", "data_tidy")
```

This reads raw data from your thesis DATA folder and writes tidied CSVs to `data_tidy/`.

### Step 2: Render Thesis

```r
rmarkdown::render("thesis.Rmd", output_format = "pdf_document")
```

Or click "Knit" in RStudio/Positron.

---

## Data Sources

| Source | Raw Location | Tidied Output |
|--------|-------------|---------------|
| LISS Work & Schooling | `DATA/LISS Work and Schooling/Extracted/` | `data_tidy/liss_work_tidy.csv` |
| LISS Income | `DATA/LISS Economic Situation, Income/Extracted/` | `data_tidy/liss_income_tidy.csv` |
| DUO Graduates | `DATA/DUO Graduates by Gender, Institution, Field of Study/` | `data_tidy/duo_graduates_tidy.csv` |
| IND Visa Acceptance | `DATA/IND Short-Term Schengen Visa Acceptance Rates/` | `data_tidy/ind_visa_consulates_tidy.csv` |
| CBS Nationality Shares | Nuffic/CBS | `data_tidy/cbs_85124NED_2024_top15.csv` |

---

## Methodology Summary

- **DV:** Log personal gross monthly income (LISS panel, 2020-2024)
- **Endogenous:** Field-level international student intensity (DUO program classification)
- **Instrument:** Shift-share (Bartik) using IND visa acceptance rates as exogenous shift
- **Estimation:** 2SLS with field and year fixed effects
- **Heterogeneity:** STEM vs. non-STEM fields

### Instrument Construction

```
Z_{f,t} = Σ_j ω_{j,t-1} × (1 - VisaRejectionRate_{j,t})
```

where ω_{j,t-1} is the lagged share of international students from country j, and VisaRejectionRate is from IND consular data.

### Identification

Visa acceptance rates are determined by Dutch consular policy and diplomatic relations — plausibly exogenous to field-specific Dutch labor market conditions.

---

## Key References

- Bartik (1991), Card (2001) — shift-share instruments
- Goldsmith-Pinkham, Sorkin, Swift (2020) — Bartik guide
- Borusyak, Hull, Jaravel (2022) — quasi-experimental shift-share
- Adão, Kolesár, Morales (2019) — shift-share inference
- ROA (2024) — stay rates of international graduates in NL
- Costas-Fernández et al. (2023) — foreign peer effects in England
- Wang et al. (2021) — international program wage premium in NL

---

## Notes

- All data processing happens in memory — raw files are never modified.
- The `data_tidy/` folder is in `.gitignore` (generated outputs).
- For questions: r.ismailaga@students.uu.nl
