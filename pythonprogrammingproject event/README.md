# Data Speaks. Can You Hear It?

## Python Econometrics Workshop — USE Honours Programme

> **Tidy → Group → Predict** — Three skills in ~40 minutes.

A hands-on, live-coding workshop where participants clean a broken CSV, discover
customer segments through clustering, and run regression analysis to understand
what drives salary — all in Python. Designed for the Utrecht University School of
Economics (USE) Honours programme.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Workshop Flow](#workshop-flow)
- [Datasets](#datasets)
  - [Salary Data (Tidying + Prediction)](#salary-data-tidying--prediction)
  - [Customer Segments (Grouping)](#customer-segments-grouping)
- [Building Slides](#building-slides)
- [Theme](#theme)
- [File Reference](#file-reference)
- [License & Attribution](#license--attribution)

---

## Overview

| Item | Detail |
|:-----|:-------|
| **Audience** | USE Honours students (1st/2nd year) |
| **Duration** | ~40 minutes (5 + 10 + 15 + 15 min) |
| **Pedagogy** | Live coding — "I Do → We Do → You Do" |
| **Tools** | Python 3, pandas, numpy, matplotlib, seaborn, statsmodels, scikit-learn |
| **Slides** | Marp (Markdown → HTML presentation) |
| **Theme** | Utrecht University branding (yellow/red) |

### Learning Objectives

By the end of the workshop, participants can:

1. **Tidy** — Clean column names, handle missing values, detect/remove duplicates
   and outliers, split concatenated fields
2. **Group** — Use `groupby()` for summary statistics, run K-means clustering,
   interpret the elbow plot, train a logistic regression classifier
3. **Predict** — Run OLS regression, interpret coefficients, p-values,
   t-statistics, and R², include categorical variables
4. **Think critically** — Distinguish inference from prediction, understand
   statistical significance (t > 2, p < 0.05)

---

## Prerequisites

- **Python 3.9+** and `pip`
- **Node.js 18+** (for Marp slides — optional; the Markdown works without it)

Verify your setup:

```bash
python3 --version          # ≥ 3.9
pip3 --version             # should return normally
node --version             # ≥ 18 (optional, for slides)
```

---

## Quick Start

```bash
git clone <repo-url> pythonprogrammingproject-event
cd pythonprogrammingproject-event
chmod +x setup.sh
./setup.sh
```

The script will:

1. Check Python 3 and pip
2. Install required packages (`pandas`, `numpy`, `matplotlib`, `seaborn`,
   `statsmodels`, `scikit-learn`)
3. Generate synthetic datasets (if not already present)
4. Run all computations (cleaning, grouping, regression)
5. Install Marp CLI and build the slides HTML
6. Print a final status summary

To open the slides:

```bash
open /workspace/slides/SLIDES.html     # macOS
xdg-open /workspace/slides/SLIDES.html  # Linux
start /workspace/slides/SLIDES.html     # Windows (WSL)
```

---

## Project Structure

```
pythonprogrammingproject event/
├── setup.sh                          # One-command build script (this)
├── README.md                         # This documentation
├── SLIDES.md                         # Marp presentation source (markdown)
├── uu-theme.css                      # Utrecht University theme for Marp
├── generate_datasets.py              # Synthetic data generator (known DGPs)
├── compute_all.py                    # Runs all computations, writes JSON
├── salary_messy.csv                  # Raw messy dataset (504 rows, 8 cols)
├── salary_data.csv                   # Clean, un-messed version (500 rows)
├── salary_clean.csv                  # After tidying pipeline (output)
├── customer_segments.csv             # Customer segments (400 rows, 3 clusters)
├── computed_values.json              # Pre-computed results for slide values
├── statistical_inference_workshops.md # Workshop design document
├── kimi_slides_draft.md              # Earlier draft / alternative content
├── MY JOB.txt                        # Scratch notes
└── slides/
    └── SLIDES.html                   # Built HTML presentation (output)
```

---

## Workshop Flow

### Part 0: Intro (5 min)

| Time | Who | What |
|:----|:----|:-----|
| 0–2 | Presenter | **Hook.** "Data Speaks. Can You Hear It?" Show the three skills |
| 2–5 | Presenter | **Setup check.** Verify Python + packages + datasets on every laptop |

### Part 1: [Tidy] Tidying (10 min)

| Time | Who | What |
|:----|:----|:-----|
| 5–7 | Together | **Load messy data.** `pd.read_csv()`. Discover problems via `df.info()` |
| 7–9 | Together | **Clean columns + drop bad rows.** Rename, `dropna()`, `drop_duplicates()` |
| 9–12 | Together | **Boxplot → find outlier.** $856K salary, remove it |
| 12–15 | Together | **Split concatenated column.** `"FIN:::NCE"` → clean department codes |

**Pipeline:** 504 rows → 479 (dropna) → 476 (drop dupes) → 475 (remove outlier) → 7 clean columns

### Part 2: [Group] Grouping (15 min)

| Time | Who | What |
|:----|:----|:-----|
| 15–17 | Together | **Supervised: groupby.** `df.groupby('segment_label').mean()` |
| 17–19 | Presenter | **Unsupervised concept.** K-means visual explanation |
| 19–23 | Together | **Run K-means.** Scale features, cluster, cross-tab with true segments |
| 23–25 | Together | **Elbow method.** K=1..8, plot inertia, elbow at K=3 |
| 25–28 | Together | **Supervised classification.** LogisticRegression → 95.8% accuracy |
| 28–30 | Presenter | **Debrief.** Three grouping approaches summarised |

### Part 3: [Predict] Prediction (15 min)

| Time | Who | What |
|:----|:----|:-----|
| 30–32 | Together | **Explore.** `sns.regplot()`, correlation = 0.888 |
| 32–35 | Together | **First regression.** `salary ~ experience`. R² = 0.789, t = 42.0 |
| 35–38 | Together | **Multiple regression.** Add education, manager, hours → R² = 0.892 |
| 38–40 | Together | **Categorical variable.** Add `C(department)` → R² = 0.915 |
| 40–43 | Presenter | **Bleeding edge.** OLS vs Random Forest vs XGBoost comparison |
| 43–45 | Presenter | **Wrap-up.** The 8-line toolkit. "Go find your own dataset." |

---

## Datasets

Both datasets are **synthetic** with known true Data Generating Processes (DGPs).
Every t-statistic, cluster assignment, and prediction is verifiable.

### Salary Data (Tidying + Prediction)

**Files:** `salary_messy.csv` (raw), `salary_data.csv` (clean seed), `salary_clean.csv` (after pipeline)

**True DGP:**

```text
salary = 35,000
       + 2,200 × experience
       + 6,500 × has_bachelor
       + 14,000 × has_master
       + 18,000 × is_manager
       + 250 × hours_per_week
       + department_effect
       + ε,  ε ~ N(0, 7,000²)
```

All predictors are designed to be **approximately uncorrelated**, so coefficients
remain stable as variables are added — ideal for teaching.

**Problems baked into `salary_messy.csv` for the tidying exercise:**

| Problem | Count | How to fix |
|:--------|:------|:-----------|
| Bad column names | 8 columns | `df.rename()` |
| Missing salary values | 25 rows | `.dropna(subset=['salary'])` |
| Duplicate rows | 3 rows | `.drop_duplicates()` |
| Outlier ($856,580) | 1 row | Quantile-based filter |
| Concatenated codes (`FIN:::NCE`) | 1 column | `.str.split(':::')` |

### Customer Segments (Grouping)

**File:** `customer_segments.csv`

- 400 customers, 6 columns (4 features + `segment_label` + `segment` code)
- 3 well-separated Gaussian clusters
- Features: `annual_spend`, `visit_frequency_month`, `avg_basket_size`,
  `loyalty_years`
- True segments: **Budget Shopper**, **Premium Loyalist**, **Whale**
- K-means recovers labels with ~95% accuracy without seeing them

---

## Building Slides

To rebuild the slides after editing `SLIDES.md`:

```bash
# Using setup.sh (full rebuild)
./setup.sh

# Or manually (faster if only editing slides):
npx @marp-team/marp-cli SLIDES.md --output /workspace/slides/SLIDES.html \
    --html --allow-local-files

# Watch mode (auto-rebuild on save):
npx @marp-team/marp-cli SLIDES.md --output /workspace/slides/SLIDES.html \
    --html --allow-local-files --watch
```

---

## Theme

The workshop uses **Utrecht University branding**:

- **Yellow slides** (`#FFCD00`): Section headers and lead slides
- **Red accent** (`#C00A35`): Highlighting key numbers and code
- **Fonts:** Open Sans (body), Merriweather (headings), Fira Code (code)
- Theme file: `uu-theme.css` — a Marp custom theme

The theme is automatically copied alongside the slides during `setup.sh`.

---

## File Reference

| File | Description |
|:-----|:------------|
| `setup.sh` | One-command build script — installs deps, generates data, runs computations, builds slides |
| `README.md` | This documentation file |
| `SLIDES.md` | Marp presentation source — all workshop content in Markdown |
| `uu-theme.css` | Utrecht University custom Marp theme (yellow/red branding) |
| `generate_datasets.py` | Generates both synthetic datasets with known true DGPs (seed=2025) |
| `compute_all.py` | Runs the full tidying → grouping → prediction pipeline; writes `computed_values.json` |
| `salary_messy.csv` | Raw messy salary data (504 rows, 8 columns) for the tidying exercise |
| `salary_data.csv` | Clean salary seed data (500 rows) before messing |
| `salary_clean.csv` | Output of the tidying pipeline (475 rows, 7 columns) |
| `customer_segments.csv` | Customer segmentation data (400 rows, 3 Gaussian clusters) |
| `computed_values.json` | Pre-computed results used to populate slide tables and figures |
| `statistical_inference_workshops.md` | Workshop design document — pedagogy, timeline, risk mitigations |
| `kimi_slides_draft.md` | Earlier draft of slide content (reference / alternative) |

---

## License & Attribution

This workshop was created for the **Utrecht University School of Economics (USE)
Honours programme**.

- **Author:** Honours workshop team, Utrecht University
- **Data:** Both datasets are synthetic — generated by `generate_datasets.py`
- **Presentation framework:** [Marp](https://marp.app/) (MIT License)
- **Theme:** Utrecht University brand colours — use in accordance with UU brand guidelines

---

*"Data Speaks. Can You Hear It?" — Tidy → Group → Predict*
