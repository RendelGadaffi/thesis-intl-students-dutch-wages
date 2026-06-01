# Data Speaks. Can You Hear It? — Participant Guide

> **Tidy → Group → Predict** · ~40 minutes · Honours Workshop — Statistical Inference with Python
>
> Utrecht University · (Y) (R)

---

## [Setup] Setup (Before We Start)

### Step 1: Install the packages

```bash
pip install pandas numpy matplotlib seaborn statsmodels scikit-learn
```

### Step 2: Download the files

You need two data files from the workshop repository:

- `salary_messy.csv` — 504 rows of broken salary data
- `customer_segments.csv` — 400 customers with known segments

Place both in your working directory alongside this guide.

### Step 3: Quick sanity check

```python
import pandas as pd
print(pd.__version__)          # ≥ 2.0
```

**Expected output:**

```
2.x.x
```

> **Q: Raise your hand when you see a version number. Don't move on until everyone has it.**

---

# [Tidy] PART 1: TIDYING

> *10 minutes — "The data is broken. Fix it."*

### 1.1 Load the Mess

```python
import pandas as pd
import numpy as np

df = pd.read_csv("salary_messy.csv")
print(df.info())
```

**What you should see:**

```
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 504 entries, 0 to 503
Data columns (total 8 columns):
 #   Column               Non-Null Count  Dtype
---  ------               --------------  -----
 0   Annual Salary ($)    479 non-null    float64
 1   Years Experience     504 non-null    float64
 2   Education Level      504 non-null    object
 3   Manager? (1=Yes)     504 non-null    int64
 4   Hours/Week           504 non-null    float64
 5   Department           504 non-null    object
 6   Department_Code      504 non-null    object
 7   Education_Numeric    504 non-null    int64
dtypes: float64(3), int64(2), object(3)
```

Problems spotted at a glance:
| Column | Non-Null | Problem? |
|:---|:---|:---|
| `Annual Salary ($)` | 479 / 504 | (R) **25 missing** |
| `Manager? (1=Yes)` | 504 | (R) Ugly name (special chars) |
| `Department_Code` | 504 | (R) `FIN:::NCE` junk format |
| `Education_Numeric` | 504 | (R) Redundant with Education Level |

> **Q: 504 rows when there should be 500. What's going on?**

---

### 1.2 Fix 1: Rename Columns

```python
df = df.rename(columns={
    'Annual Salary ($)':  'salary',
    'Years Experience':   'experience',
    'Education Level':    'education',
    'Manager? (1=Yes)':   'is_manager',
    'Hours/Week':         'hours',
    'Department':         'department',
    'Department_Code':    'dept_code',
    'Education_Numeric':  'edu_code',
})
```

**Why rename?** No spaces → `df.salary` works. No special chars → formulas don't break. Lowercase → no SHIFT-key accidents. Every analyst does this within **30 seconds** of opening a stranger's file.

---

### 1.3 Fix 2 & 3: Missing Values + Duplicates

```python
# 25 missing salaries
print(f"Missing: {df['salary'].isna().sum()}")
df = df.dropna(subset=['salary'])       # → 479 rows

# 3 duplicate rows
print(f"Duplicates: {df.duplicated().sum()}")
df = df.drop_duplicates()               # → 476 rows
```

**Progress tracker:**

| Step | Rows | What happened |
|:--|:--|:--|
| Original | 504 | Messy file |
| `dropna()` | **479** | −25 rows with blank salary |
| `drop_duplicates()` | **476** | −3 copied rows |

> **Q: How do duplicates happen?** *(Export errors, merge bugs, human copy-paste.)*

---

### 1.4 Fix 4: The Outlier

```python
import matplotlib.pyplot as plt
plt.boxplot(df['salary'], vert=False)
plt.show()
```

One point at **$856,580** — everything else below ~$156K.

```python
q99 = df['salary'].quantile(0.99)        # $151,381
df = df[df['salary'] <= q99 * 3]         # → 475 rows
```

> **5.7× the 99th percentile.** Data entry error (extra zero) or the CEO's salary. **Context matters** — always verify outliers against domain knowledge.

---

### 1.5 Fix 5: Split & Save

```python
# 'FIN:::NCE' → two columns
df[['dept_abbr', 'dept_suffix']] = (
    df['dept_code'].str.split(':::', expand=True)
)

# Drop originals + redundant columns
df = df.drop(columns=['dept_code', 'dept_suffix', 'edu_code'])

df.to_csv('salary_clean.csv', index=False)
```

**Before vs After:**

| | Before | After |
|:--|:--|:--|
| **Rows** | 504 | **475** |
| **Columns** | 8 (messy) | **7** (clean) |
| Missing | 25 | **0** |
| Duplicates | 3 | **0** |
| Outliers | 1 ($857K) | **0** |

> #### [OK] Tidying — Your Turn
>
> Load `salary_clean.csv` and verify it's clean:
> ```python
> clean = pd.read_csv("salary_clean.csv")
> print(clean.info())
> print(f"Rows: {len(clean)}, Cols: {len(clean.columns)}")
> ```

---

### [Tidy] Key Takeaways — Tidy Principles

1. **Rename immediately** — lowercase, no spaces, no special chars
2. **Drop missing** — `df.dropna(subset=['key_column'])`
3. **Drop duplicates** — `df.drop_duplicates()`
4. **Handle outliers** — boxplot + quantile threshold or domain knowledge
5. **Split junk columns** — `str.split()` on delimiter patterns
6. **Save clean version** — never overwrite the original

> **Q: What if you skip tidying?**
> - Run regression with the **$857K outlier** → experience coefficient inflates by ~$300/year
> - Don't remove **duplicates** → p-values look more significant than they are
> - Leave **bad column names** → 5-minute debugging session on a KeyError typo
>
> **Tidying is not busywork. Tidying is the difference between a finding and a mistake.**

---

# [Group] PART 2: GROUPING

> *15 minutes — "Patterns hide in plain sight. You find them."*

### 2.1 Load Customer Data

```python
df = pd.read_csv("customer_segments.csv")
print(f"{len(df)} customers")
print(df.head(3))
```

**Sample rows:**

| annual_spend | visits/mo | basket | loyalty | segment_label |
|--:|--:|--:|--:|---|
| $11,926 | 4.0 | 179.7 | 4.0 yr | Whale |
| $5,728 | 14.2 | 71.0 | 5.0 yr | Premium Loyalist |
| $1,389 | 9.9 | 22.1 | 1.1 yr | Budget Shopper |

**400 customers. 4 features. 3 segments.** *But in reality, you don't have the `segment_label` column — you discover the groups yourself.*

---

### 2.2 Supervised: `groupby()` — When You Have Labels

```python
df.groupby('segment_label')[
    ['annual_spend', 'visit_frequency_month',
     'avg_basket_size', 'loyalty_years']
].mean().round(1)
```

**Expected output:**

| Segment | Spend/yr | Visits/mo | Basket | Loyalty |
|:---|---:|---:|---:|---:|
| Budget Shopper | **$1,239** | 14.2 | 21.9 | 2.7 yr |
| Premium Loyalist | **$4,454** | 9.8 | 53.5 | 7.3 yr |
| Whale | **$9,377** | 6.0 | 117.1 | 5.1 yr |

> **Q: Discuss with your neighbour (30 sec):** If you had ONE billboard ad, which segment do you target and **why**? Defend your answer with a number from this table.

---

### 2.3 Unsupervised: K-Means — When You Don't

> **Q: Before we run it — guess how many groups exist in this data.**

```python
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

X = df[['annual_spend', 'visit_frequency_month',
        'avg_basket_size', 'loyalty_years']]

X_scaled = StandardScaler().fit_transform(X)   # SCALE is critical!

kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['cluster'] = kmeans.fit_predict(X_scaled)

print(pd.crosstab(df['segment_label'], df['cluster']))
```

**Confusion matrix (true segments vs discovered clusters):**

| True Segment | Cluster 0 | Cluster 1 | Cluster 2 |
|:---|---:|---:|---:|
| Budget Shopper | 0 | **159** [2713] | 1 |
| Premium Loyalist | 1 | 7 | **132** [2713] |
| Whale | **92** [2713] | 0 | 8 |

> **The algorithm found the same groups WITHOUT seeing the labels.** 159/160 Budget Shoppers correctly grouped. 132/140 Premium Loyalists. 92/100 Whales.

---

### 2.4 How Many Clusters? The Elbow Method

```python
inertias = []
for k in range(1, 9):
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    km.fit(X_scaled)
    inertias.append(km.inertia_)

print(inertias)
```

| K | 1 | 2 | **3** | 4 | 5 | 6 | 7 | 8 |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Inertia | 1,600 | 832 | **498** | 402 | 354 | 312 | 289 | 267 |

**1,600 → 832 = −768 | 832 → 498 = −334 | 498 → 402 = −96**

The elbow is at **K = 3** — diminishing returns after that.

> #### [OK] Grouping — Your Turn
>
> Re-run K-Means with `n_clusters=4`. How does the crosstab change? Does the 4th cluster split an existing group or create a new one?

---

### 2.5 Classification: Predict a New Customer's Segment

```python
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, df['segment_label'], test_size=0.3, random_state=42
)

clf = LogisticRegression(max_iter=1000)
clf.fit(X_train, y_train)

print(f"Accuracy: {clf.score(X_test, y_test):.1%}")
```

**Result:**

```
Accuracy: 95.8%
```

Baseline (random guess with 3 equal classes): **33%**. The model is 3× better than random.

> #### [OK] Classification — Your Turn
>
> A new customer arrives: spends $2,000/year, visits 12×/month, basket $30, loyalty 3 years. Which segment are they? Run `clf.predict()` on their scaled features.

---

### [Group] Key Takeaways — Grouping Principles

| Approach | Type | Question Answered |
|:--|:--|:--|
| `df.groupby().mean()` | Supervised summary | *What do my known groups look like?* |
| `KMeans(n_clusters=3)` | Unsupervised clustering | *What groups EXIST in my data?* |
| Elbow method | Model selection | *How many groups are there?* |
| `LogisticRegression()` | Supervised classification | *Which group is this NEW customer?* |

1. **If you have labels** → `groupby().mean()` for fast insight
2. **If you don't have labels** → K-Means + elbow plot
3. **Scale before clustering** — StandardScaler() or features with big numbers dominate
4. **Logistic Regression for classification** — fast, interpretable, surprisingly good

> **Q: FINAL GROUPING QUESTION:** You're the marketing director. Budget covers ONE email campaign. Which segment — and defend with a number from the groupby table.

---

# [Predict] PART 3: PREDICTION

> *15 minutes — "The past knows the future. You extract it."*

### 3.1 Explore: Experience vs Salary

```python
df = pd.read_csv("salary_clean.csv")
print(df.describe())
```

**Descriptive statistics:**

| | salary | experience | is_manager | hours |
|:---|---:|---:|---:|---:|
| **mean** | $97,077 | 18.1 yr | 19% | 38.0 hr |
| **std** | $25,355 | 10.1 yr | 39% | 6.0 hr |
| **min** | $32,897 | 0.2 yr | 0 | 20 hr |
| **max** | $156,352 | 34.8 yr | 1 | 60 hr |

**Education breakdown:** 201 Bachelor's · 144 High School · 130 Master's

```python
corr = df['experience'].corr(df['salary'])
print(f"Correlation: {corr:.3f}")    # → 0.888
```

> **Q: Correlation is 0.888. Is that "good"? What does it actually MEAN?**

---

### 3.2 Simple Regression — Salary ~ Experience

```python
import statsmodels.formula.api as smf

model1 = smf.ols('salary ~ experience', data=df).fit()
print(model1.summary())
```

**Key output:**

```
                            OLS Regression Results
==============================================================================
                        coef    std err          t      P>|t|
------------------------------------------------------------------------------
Intercept          5.74e+04   1218.327     47.146      0.000
experience          2227.98     53.050     **42.000**      **0.000**
------------------------------------------------------------------------------
R-squared:           **0.789**
```

> **Q: `salary ~ experience` — what does the `~` mean in plain English?**

#### How to Read This Table — Only Four Numbers Matter

| [Color] | What | Value | Meaning |
|:--|:--|:--|:--|
| (Y) | **coef** | **+$2,228** | Each year of experience → +$2,228 |
| (G) | **P>\|t\|** | **< 0.001** | Virtually certain this is real |
| (P) | **t-statistic** | **42.0** | 42 standard errors from zero — enormous |
| (B) | **R²** | **0.789** | Experience explains 78.9% of salary |

**95% Confidence Interval:** The true effect is between **$2,124** and **$2,333** per year of experience.

#### The t-statistic Explained

**t = coefficient ÷ standard error = $2,228 ÷ $53 = 42.0**

```
           "Not significant"     "Significant"         "Very significant"
           (p > 0.05)            (p < 0.05)            (p < 0.001)
                │                     │                       │
  ──────────────┼─────────────────────┼───────────────────────┼────→ t
  −2    −1      0      1      2                            42
  <── noise ──>│                  <────── signal ─────────────────>
```

| t | p ≈ | Verdict |
|--:|:--|:--|
| 0.5 | 0.62 | [Not sig] Not significant |
| 1.5 | 0.13 | [Unsure] Might be real, can't be sure |
| **2.0** | **0.05** | [OK] **Significant** |
| **42.0** | **6.8×10⁻¹⁶²** | [Strong] **Overwhelming** |

---

### 3.3 Multiple Regression — Add More Variables

```python
model2 = smf.ols(
    'salary ~ experience + education + is_manager + hours',
    data=df
).fit()
print(model2.summary())
```

| Variable | Coef | t | p | Interpretation |
|:---|---:|---:|---:|:--|
| `experience` | **+$2,183** | 57.2 | <0.001 | Each year → +$2,183 |
| `education[T.High School]` | **−$5,123** | −5.6 | <0.001 | HS grads earn −$5,123 vs Bachelor's |
| `education[T.Master]` | **+$7,071** | 7.5 | <0.001 | Master's earns +$7,071 vs Bachelor's |
| `is_manager` | **+$16,267** | 16.5 | <0.001 | Managers earn +$16,267 |
| `hours` | **+$287** | 4.7 | <0.001 | Each extra hour/week → +$287 |
| **R²** | **0.892** | — | — | **89.2% of salary explained** |

> **Q: The experience coefficient was $2,228 in Model 1. Now it's $2,183. Why did it change?**
>
> *Answer: Omitted variable bias. Experience correlates with education and manager status. Model 1 bundled their effects into the experience coefficient. Model 2 separates them.*

---

### 3.4 Add Categories — Department Effects

```python
model3 = smf.ols(
    'salary ~ experience + education + is_manager + hours + C(department)',
    data=df
).fit()
print(model3.summary())
```

| Variable | Coef | t | p |
|:---|---:|---:|---:|
| `experience` | +$2,167 | 63.2 | <0.001 |
| `education[T.High School]` | −$5,088 | −6.3 | <0.001 |
| `education[T.Master]` | +$7,482 | 8.9 | <0.001 |
| `is_manager` | **+$17,022** | 19.2 | <0.001 |
| `hours` | +$284 | 5.3 | <0.001 |
| `department[T.Finance]` | **+$3,931** | 4.1 | <0.001 |
| `department[T.Marketing]` | **−$5,956** | −6.0 | <0.001 |
| `department[T.Operations]` | **−$3,957** | −4.0 | <0.001 |
| **R²** | **0.915** | — | — |

Department effects are relative to **Engineering** (the reference category). Finance commands a premium. Marketing and Operations have a penalty — both survive controls for experience, education, and management.

> #### [OK] Prediction — Your Turn
>
> Predict the salary for these two hypothetical employees:
> - **Person A:** 15 years experience, Master's, manager, 40 hrs/wk, Engineering
> - **Person B:** 5 years experience, High School, not manager, 35 hrs/wk, Marketing
>
> Use `model3.predict()` with a small DataFrame of new data.

---

### [Predict] Key Takeaways — Prediction Principles

1. **Start simple** — one predictor, one regression
2. **Read four numbers** — coefficient, p-value, t-stat, R²
3. **Add variables** — watch for coefficient changes (omitted variable bias)
4. **Use `C()` for categories** — statsmodels handles dummy encoding automatically
5. **R² = fraction explained** — 0.915 means the model accounts for 91.5% of salary variation

#### The Bleeding Edge: Beyond OLS

| | OLS | Random Forest | XGBoost |
|:--|:--|:--|:--|
| **Interpretability** | [5/5] | [2/5] | [1/5] |
| **Predictive power** | [3/5] | [4/5] | [5/5] |
| **Assumptions** | Linearity, normality | **None** | **None** |
| **Output** | coef, p, t, R², CI | Feature importance | Feature importance |
| **Question** | ***Why?*** | ***What?*** | ***What, accurately?*** |

> **Q: If XGBoost predicts better, why ever use OLS?**
>
> *"Salary goes up by $2,167/year and we're 99.999% confident" — you can defend that statement to a boss, a journal, or a court. "The black box says so" — you can't.*

---

# [Toolkit] Your 8-Line Toolkit

Copy this into any Python script. Works on **any** dataset with a numeric target.

```python
import pandas as pd
import statsmodels.formula.api as smf

# TIDY
df = pd.read_csv("data.csv")
df = df.rename(columns={'Bad Name': 'good_name'})
df = df.dropna().drop_duplicates()

# GROUP
df.groupby('category').mean()
KMeans(n_clusters=3).fit_predict(X_scaled)
LogisticRegression().fit(X_train, y_train)

# PREDICT
sns.regplot(x='x', y='y', data=df)
model = smf.ols('y ~ x1 + x2 + C(category)', data=df).fit()
print(model.summary())      # coef, p, t, R² — your 4 numbers
```

---

# [Advanced] Going Further

### Where to Find Datasets

| Source | URL | Notes |
|:--|:--|:--|
| Kaggle | kaggle.com/datasets | Everything from housing to NLP |
| CBS StatLine | opendata.cbs.nl | Dutch official statistics |
| Eurostat | ec.europa.eu/eurostat | European economic data |
| UCI ML Repository | archive.ics.uci.edu/ml | Classic benchmark datasets |
| Our World in Data | ourworldindata.org | Global development data |

### What to Learn Next

1. **Random Forest** — `from sklearn.ensemble import RandomForestRegressor`
   - No assumptions, captures non-linear patterns
   - Compare R² to OLS on the same salary data

2. **XGBoost** — `pip install xgboost`
   - State-of-the-art for tabular data
   - Usually beats Random Forest by 2-5%

3. **Instrumental Variables (IV)** — `from linearmodels import IV2SLS`
   - When predictors correlate with the error term (endogeneity)
   - Crucial for causal claims in econometrics

4. **Cross-Validation** — `from sklearn.model_selection import cross_val_score`
   - Stop overfitting — estimate out-of-sample performance

### Challenge: Back to Your Own Data

```python
# Copy your data into this template
df = pd.read_csv("your_data.csv")
df = df.dropna().drop_duplicates()           # tidy
print(df.groupby('your_category').mean())    # group
model = smf.ols('y ~ x1 + x2', data=df).fit()  # predict
print(model.summary())
```

---

# [Notes] My Notes

> Use this space to jot down questions, things you want to Google later, and ideas for your own data.




---

### Quick Reference: All Q: Questions from the Workshop

1. You're handed a CSV. Column names have spaces and dollar signs. Some cells are blank. Three rows look identical. One salary says $856,580. What do you do **first**?
2. 504 rows when there should be 500. What's going on?
3. How do duplicates happen?
4. What if you skip tidying?
5. Before we run K-Means — guess how many groups exist in this data.
6. Discuss with your neighbour (30 sec): If you had ONE billboard ad, which segment do you target and why?
7. You're the marketing director. Budget covers ONE email campaign. Which segment — and defend with a number.
8. Correlation is 0.888. Is that "good"? What does it actually MEAN?
9. `salary ~ experience` — what does the `~` mean in plain English?
10. The experience coefficient was $2,228 in Model 1. Now it's $2,183. Why did it change?
11. If XGBoost predicts better, why ever use OLS?

---

*This guide accompanies the "Data Speaks. Can You Hear It?" workshop.*
*Files: `salary_messy.csv` · `salary_clean.csv` · `customer_segments.csv` · `generate_datasets.py`*
*Built with synthetic data — every t-statistic is verifiable against known true DGPs.*
