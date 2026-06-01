# USE Honours Event — Statistical Inference Workshop
### "Tidy. Group. Predict." — Three skills in 40 minutes

---

## Design Principle

> This is an **inference** workshop. The goal isn't the fanciest model — it's understanding *why* patterns exist, *how* to discover them, and *what* confidence we have in our conclusions. Every participant leaves having tidied messy data, run a clustering algorithm, and interpreted a regression table.

**Pedagogy: "I Do → We Do → You Do"**

The workshop follows a live-coding format — presenter types each step, audience executes simultaneously on their own laptops.

| Phase | Skill | Duration |
|-------|-------|----------|
| **Intro** | Hook + setup | 5 min |
| **Tidying** | Clean messy salary data | 10 min |
| **Grouping** | Cluster customers (supervised + unsupervised) | 15 min |
| **Prediction** | OLS regression on salary + bleeding edge mention | 15 min |

**Total: ~40 minutes.** Presenter talks ~12 min, audience works ~28 min.

---

## Datasets

Two synthetic datasets, both generated with known true Data Generating Processes so results are verifiable:

| Dataset | Rows | Purpose |
|---------|------|---------|
| `salary_messy.csv` | ~504 (messy) | Tidying: dirty columns, missing values, duplicates, outlier |
| `salary_data.csv` | 500 (clean) | Prediction: OLS regression with proper t-distributions |
| `customer_segments.csv` | 400 | Grouping: 3 Gaussian clusters + classification |

### Salary DGP (known true coefficients)
```
salary = 35,000 + 2,200*years_exp + 6,500*has_bachelor + 14,000*has_master
         + 18,000*is_manager + 250*hours_per_week + dept_effect + ε
where ε ~ N(0, 7000²)
```
All predictors are independent → coefficients stay stable when variables are added, and t-statistics follow correct distributions under the null.

### Customer Segments DGP
Three Gaussian clusters with known centroids — well-separated for clean k-means recovery (~95%+ classification accuracy).

---

## Timeline (40 min)

### Part 0: Intro (5 min)

| Min | Who | What |
|-----|-----|------|
| 0–2 | Presenter | **Hook.** "Data Speaks. Can You Hear It?" Show the three skills: Tidy, Group, Predict. |
| 2–5 | Presenter | **Setup check.** Verify everyone has Python + packages + datasets. QR code on screen. |

---

### Part 1: Tidying (10 min)
*Audience follows along — presenter types each line, audience executes.*

| Min | Who | What |
|-----|-----|------|
| 5–7 | Together | **Load messy data.** `pd.read_csv("salary_messy.csv")`. `df.info()` reveals: bad column names, missing values (29), extra rows (504 vs 500). |
| 7–9 | Together | **Clean columns + drop bad rows.** Lowercase/underscore column names. `dropna()` for missing salary. `drop_duplicates()`. |
| 9–12 | Together | **Boxplot → find outlier.** One salary at $650K (10× too high). Remove it. |
| 12–15 | Together | **Split concatenated column.** `"ENG:::EER"` → two columns. Drop noise. Save clean CSV. |

---

### Part 2: Grouping (15 min)

| Min | Who | What |
|-----|-----|------|
| 15–17 | Together | **Supervised: groupby.** Load `customer_segments.csv`. `df.groupby('segment_label').mean()` — three customer types emerge immediately. |
| 17–19 | Presenter | **Unsupervised concept.** K-means explained visually (3 blobs, centroids). "The algorithm discovers groups without labels." |
| 19–23 | Together | **Run K-means.** Scale features, `KMeans(n_clusters=3)`, cross-tab with true segments. "Did it find the same groups?" |
| 23–25 | Together | **Elbow method.** Try K=1..8, plot inertia. Elbow at K=3 confirms the choice. |
| 25–28 | Together | **Supervised classification.** `LogisticRegression` to predict segment from features. ~95% accuracy. "Now new customers can be classified automatically." |
| 28–30 | Presenter | **Debrief.** Three grouping approaches: `groupby()` (known groups), K-means (discover groups), Logistic Regression (assign new obs). |

---

### Part 3: Prediction (15 min)

| Min | Who | What |
|-----|-----|------|
| 30–32 | Together | **Explore.** Load `salary_clean.csv`. `sns.regplot(x='years_experience', y='annual_salary')`. Correlation = 0.71. "One variable, clear pattern." |
| 32–35 | Together | **First regression.** `smf.ols('annual_salary ~ years_experience', data=df).fit().summary()`. Presenter highlights: coef ($2,168/year), p-value (0.000), t-stat (65.8), R² (0.50). |
| 35–38 | Together | **Multiple regression.** Add education, is_manager, hours_per_week. R² jumps to 0.92. Every variable significant. "The t-statistic = coef/SE. t > 2 → significant." |
| 38–40 | Together | **Categorical variable.** Add `C(department)`. Finance premium, Marketing penalty. "Even with same experience and education, department matters." |
| 40–43 | Presenter | **Bleeding edge.** OLS vs Random Forest vs XGBoost comparison table. "These are what you graduate to. But they don't give you p-values — you still need OLS for inference." |
| 43–45 | Presenter | **Wrap-up.** The 8-line toolkit. QR code to code + data. "Go find your own dataset. The code is the same." |

---

## Learning Objectives

By the end, participants can:
1. **Tidy** — Clean column names, handle missing values, detect/remove duplicates and outliers, split concatenated fields
2. **Group** — Use `groupby()` for summary statistics, run K-means clustering, interpret the elbow plot, train a logistic regression classifier
3. **Predict** — Run OLS regression, interpret coefficients/p-values/t-statistics/R², include categorical variables, understand the OLS vs ML tradeoff
4. **Think critically** — Distinguish correlation from causation, understand statistical significance (t > 2, p < 0.05), know when to use inference vs prediction tools

---

## What the presenter brings
- USB stick with datasets + `generate_datasets.py`
- QR code to the same files
- Projector for live-coding
- Pre-event pip command: `pip install pandas numpy matplotlib seaborn statsmodels scikit-learn`

---

## Risk Mitigations

| Risk | Mitigation |
|------|------------|
| Packages not installed | QR code on slide 4 with the pip command. 30-second install. |
| Participants never used pandas | Every code block is copy-paste ready. Presenter types EVERY line live. |
| Overwhelmed by regression output | Only 4 numbers highlighted: coef, p-value, t-stat, R². Everything else greyed out. |
| K-means gives wrong clusters | `random_state=42` and `n_init=10` ensure reproducibility. Presenter pre-runs and screenshots expected output. |
| Time overrun | Tidying section is the buffer — the messy file has exactly 4 fixable problems. If running long, skip the "split column" step. |

---

## Comparison to earlier two-workshop design

| | Old (Movie + Football) | New (Tidy → Group → Predict) |
|---|---|---|
| Number of workshops | 2 × 45 min | 1 × 40 min |
| Focus | OLS regression only | Full data pipeline |
| Skills taught | Load, plot, regress | Tidy, group (supervised + unsupervised), predict |
| ML mention | None | OLS vs RF vs XGBoost comparison |
| User's job match | No | Yes (tidying, grouping supervised/unsupervised, prediction) |
