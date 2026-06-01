---
marp: true
theme: "uu-theme"
class: lead
size: '16:9'
math: mathjax
paginate: true
output: pdf_document
---

<!-- _class: lead -->

# Data Speaks.
# Can You Hear It?

#### Honours Workshop — Statistical Inference with Python

*Tidy → Group → Predict &nbsp;·&nbsp; ~40 minutes*

<!-- speaker_note: Welcome everyone. Today is about turning messy data into actionable inference — all in Python, all live-coded. You'll type every line yourself. If you get stuck, raise your hand and we fix it together before moving on. Timing: we have about 40 minutes total, broken into 4 blocks. Let's start. -->

---

<!-- _class: lead -->

## &nbsp; &nbsp; 

|**TIDY** | **GROUP** | **PREDICT** |
|:--:|:--:|:--:|
|Real data is broken | Patterns hide in plain sight | The past knows the future |
|*You fix it* | *You find them* | *You extract it* |

<br>

> **Q:** You're handed a CSV. Column names have spaces and dollar signs. Some cells are blank. Three rows look identical. One salary says **$856,580** when the max should be ~$150K. What do you do **first**?

> **Discuss with your neighbour (30 sec).** Then share one word with the room.

<!-- speaker_note: This is a warm-up question to get them thinking about data quality before any analysis. Let them discuss for exactly 30 seconds, then call on 2-3 people. Expect answers like 'look at it', 'describe', 'plot'. Nod and say "yes, that's exactly right — the first step is always to LOAD and LOOK." -->

---

<!-- _class: lead -->

## Your Datasets

|| `salary_messy.csv` | `customer_segments.csv` |
|:--|:--|:--|
|**Rows** | 504 *(messy)* | 400 |
|**Cols** | 8 *(2 are junk)* | 6 |
|**Used for** | Tidying + Prediction | Grouping |
|**Question** | *What drives salary?* | *Who are your customers?* |

<br>

<small>Both synthetic, built with known true DGPs. Every t-statistic is verifiable.</small>

<!-- speaker_note: Frame the workshop roadmap. 'salary_messy.csv' has deliberate problems we'll fix. 'customer_segments.csv' has hidden groups we'll discover. Both are synthetic so we can check our answers against ground truth. Timing: 1 min. -->

---

## Quick Setup

```bash
pip install pandas numpy matplotlib seaborn statsmodels scikit-learn
```

Check it works:

```python
import pandas as pd
print(pd.__version__) # ≥ 2.0
```

> **Q:** Raise your hand when you see a version number. Don't move on until everyone has it.

<!-- speaker_note: Common pitfalls: someone may not have pip or may be in the wrong environment. Walk around and check. If someone's install is slow, have them start the install first, then explain the overview while it runs. Timing: 2-3 min, don't rush this. -->

---

<!-- _class: lead -->

# PART 1
# TIDYING

 10 min · 6 slides

*"The data is broken. Fix it."*

<!-- speaker_note: Part 1 is about pragmatic data cleaning. We'll go from 504 messy rows to 475 clean ones. Emphasise: this isn't glamorous, but it's what separates real analysis from garbage-in-garbage-out. -->

---

## Load the Mess

```python
import pandas as pd
import numpy as np

df = pd.read_csv("salary_messy.csv")
print(df.info())
```

|Column | Non-Null | Problem? |
|:---|:---|:---|
|`Annual Salary ($)` | 479 / 504 | **25 missing** |
|`Manager? (1=Yes)` | 504 | **Ugly name** |
|`Department_Code` | 504 | **`FIN:::NCE`** |
|`Education_Numeric` | 504 | **Redundant** |

<br>

> **Q:** 504 rows when there should be 500. What's going on?
> **Discuss: Think for 10 seconds, then pair-share.**

<!-- speaker_note: Let them notice the discrepancy. The answer: 3 duplicates + 1 outlier row inserted on purpose. This slide establishes why cleaning is needed. The 'FIN:::NCE' value is a split column indicator — a great teachable moment about non-standard delimiters. -->

---

## Fix 1: Rename Columns

```python
df = df.rename(columns={
 'Annual Salary ($)': 'salary',
 'Years Experience': 'experience',
 'Education Level': 'education',
 'Manager? (1=Yes)': 'is_manager',
 'Hours/Week': 'hours',
 'Department': 'department',
 'Department_Code': 'dept_code',
 'Education_Numeric': 'edu_code',
})
```

> **Why rename?** No spaces → `df.salary` works. No special chars → formulas don't break. Lowercase → no SHIFT key accidents. Every analyst does this within **30 seconds** of opening a stranger's file.

<!-- speaker_note: Type this out line by line. Pause after each to let them catch up. Point out the naming convention: snake_case, descriptive, no spaces. This is a 30-second habit that saves hours of debugging. Pitfall: someone will type 'Years_Experience' instead of 'Years Experience' from the CSV — show them how to check with df.columns. -->

---

## Fix 2 & 3: Missing + Duplicates

```python
# 25 missing salaries
print(f"Missing: {df['salary'].isna().sum()}")
df = df.dropna(subset=['salary']) # 479 rows

# 3 duplicate rows
print(f"Duplicates: {df.duplicated().sum()}")
df = df.drop_duplicates() # 476 rows
```

|Step | Rows | What happened |
|:--|:--|:--|
|Original | 504 | Messy file |
|`dropna()` | 479 | −25 rows with blank salary |
|`drop_duplicates()` | **476** | −3 copied rows |

> **Q:** How do duplicates happen? *(Export errors, merge bugs, human copy-paste.)*
> **Discuss: Take 15 sec, then call out your best guess.**

<!-- speaker_note: Emphasise that dropna and drop_duplicates are the two most-used cleaning commands in pandas. The duplicate issue: in real life, look for exact row copies (easier) or near-copies on key columns (harder). Pitfall: dropna by default drops ANY row with ANY NaN — show them the `subset=` parameter. -->

---

## Fix 4: The Outlier

```python
import matplotlib.pyplot as plt
plt.boxplot(df['salary'], vert=False)
plt.show()
```

One point at **$856,580** — everything else below ~$156K.

```python
q99 = df['salary'].quantile(0.99) # $151,381
df = df[df['salary'] <= q99 * 3] # → 475 rows
```

<br>

> **5.7× the 99th percentile.** Data entry error (extra zero) or the CEO's salary. **Context matters** — always verify outliers against domain knowledge.

<!-- speaker_note: The boxplot reveals the outlier visually — let the audience react. The 3×IQR or 3×99th percentile rule is a heuristic, not a theorem. Ask: "Would we remove it differently if it were a CEO's legitimate salary?" This opens the conversation about domain-aware cleaning. Pitfall: someone will ask why we don't use IQR — explain both work, 99th percentile is simpler to teach. -->

---

## Fix 5: Split & Save

```python
# 'FIN:::NCE' → two columns
df[['dept_abbr', 'dept_suffix']] = (
 df['dept_code'].str.split(':::', expand=True)
)

# Drop originals + redundant columns
df = df.drop(columns=['dept_code', 'dept_suffix', 'edu_code'])

df.to_csv('salary_clean.csv', index=False)
```

|| Before | After |
|:--|:--|:--|
|**Rows** | 504 | **475** |
|**Columns** | 8 (messy) | **7** (clean) |
|**Missing** | 25 | **0** |
|**Duplicates** | 3 | **0** |
|**Outliers** | 1 ($857K) | **0** |

<!-- speaker_note: The split trick with ':::' is a real-world pattern — data is often stored in concatenated columns with weird separators. We drop 'edu_code' because education is already stored as a readable string. Save early, save often. Everyone should now have 'salary_clean.csv' on disk. -->

---

## Tidying: Why It Matters

> **Q: What if you skip tidying?**
>
> - Run regression with the **$857K outlier** → experience coef inflates by ~$300/year
> - Don't remove **duplicates** → p-values look more significant than they are
> - Leave **bad column names** → 5-minute debugging session on a KeyError typo
>
> **Tidying is not busywork. Tidying is the difference between a finding and a mistake.**
>
> **Discuss: Any questions before we move on?**

<!-- speaker_note: This slide is the 'why' moment. Emphasise: cleaning isn't optional, it's the foundation. If anyone looks confused, now is the time to clarify. Transition: "We've fixed the data. Now let's discover what's hiding inside it." -->

---

<!-- _class: lead -->

## End of Part 1 Recap

### What We Just Did

|Problem | Solution | Rows affected |
|:--|:--|--:|
|Ugly column names | `df.rename()` | All 8 columns |
|25 missing salaries | `df.dropna()` | −25 |
|3 duplicate rows | `df.drop_duplicates()` | −3 |
|1 extreme outlier | Quantile filter | −1 |
|Concatenated codes | `str.split(':::')` | Split into 2 cols |
|Redundant columns | `df.drop()` | −2 columns |

### Clean result: **475 rows · 7 columns · 0 problems**

<!-- speaker_note: Quick verbal summary — 30 seconds. Ask "How many rows did we lose total?" (504 → 475 = 29 lost). Then transition: "Next up: what if you DON'T know the groups in your data? That's clustering." -->

---

<!-- _class: lead -->

# PART 2
# GROUPING

 15 min · 8 slides

*"Patterns hide in plain sight. You find them."*

<!-- speaker_note: Part 2 is the longest section. We switch datasets to customer_segments.csv. The key insight: K-Means finds groups without any labels — a different kind of learning. Timing check: we should be about 12-13 minutes in. -->

---

## Customer Segments

```python
df = pd.read_csv("customer_segments.csv")
print(f"{len(df)} customers")
```

|annual_spend | visits/mo | basket | loyalty | segment_label |
|--:|--:|--:|--:|---|
|$11,926 | 4.0 | 179.7 | 4.0 yr | Whale |
|$5,728 | 14.2 | 71.0 | 5.0 yr | Premium Loyalist |
|$1,389 | 9.9 | 22.1 | 1.1 yr | Budget Shopper |

**400 customers. 4 features. 3 segments.** *But in reality, you don't have the `segment_label` column — you discover the groups yourself.*

<!-- speaker_note: Switch datasets. Load customer_segments.csv. Point out: in this dataset we DO have labels (for teaching), but in real life you wouldn't. The labels are for verifying our clustering results. Ask: "Looking at these three rows, can you already see the groups?" -->

---

## `groupby()` — When You Have Labels

```python
df.groupby('segment_label')[
 ['annual_spend','visit_frequency_month',
 'avg_basket_size','loyalty_years']
].mean().round(1)
```

|Segment | Spend/yr | Visits/mo | Basket | Loyalty |
|:---|---:|---:|---:|---:|
|Budget Shopper | **$1,239** | 14.2 | 21.9 | 2.7 yr |
|Premium Loyalist | **$4,454** | 9.8 | 53.5 | 7.3 yr |
|Whale | **$9,377** | 6.0 | 117.1 | 5.1 yr |

<br>

> **Q: Discuss with your neighbour (30 sec):** If you had ONE billboard ad, which segment do you target and **why**? Defend your answer with a number from this table.

<!-- speaker_note: Let them discuss for 30 seconds. Expect varied answers: Budget (volume), Premium (basket size + loyalty), Whales (high spend). No wrong answer — the point is using data to defend a decision. This models how groupby feeds into business reasoning. -->

---

## Q: What If You DON'T Have Labels?

### Three Hidden Groups in the Feature Space

|Feature | Budget Shopper | Premium Loyalist | Whale |
|:---|---:|---:|---:|
|**Annual spend** | Low ($1,200) | Medium ($4,500) | High ($9,500) |
|**Visit frequency** | High (14/mo) | Medium (10/mo) | Low (6/mo) |
|**Basket size** | Small ($22) | Medium ($55) | Large ($120) |
|**Loyalty** | Short (2.5 yr) | Long (7.0 yr) | Medium (5.0 yr) |
|**Strategy** | Volume-driven | Relationship-driven | Premium-driven |

> **Q:** Before we run clustering — guess how many groups exist in this data just from this table.
> **Discuss: Write your answer on your hand. Show me on 3.**

<!-- speaker_note: Replace the ASCII scatterplot with a clear conceptual table. This is more readable in Marp and conveys the same information: three distinct patterns. The feature-space description lets students reason about clusters before seeing the algorithm output. Ask them to guess K before revealing it. -->

---

## Run K-Means (K=3)

```python
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

X = df[['annual_spend','visit_frequency_month',
 'avg_basket_size','loyalty_years']]

X_scaled = StandardScaler().fit_transform(X) # SCALE is critical!

kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['cluster'] = kmeans.fit_predict(X_scaled)

print(pd.crosstab(df['segment_label'], df['cluster']))
```

|True Segment | Cluster 0 | Cluster 1 | Cluster 2 |
|:---|---:|---:|---:|
|Budget Shopper | 0 | **159**  | 1 |
|Premium Loyalist | 1 | 7 | **132**  |
|Whale | **92**  | 0 | 8 |

> **The algorithm found the same groups WITHOUT seeing the labels.**

<!-- speaker_note: Emphasise why scaling matters — without it, 'annual_spend' (thousands) would dominate 'visit_frequency' (single digits). The crosstab shows 383/400 correct assignments (95.75% accuracy). Ask: "Which segment had the most misclassifications?" (Premium, with 8 mistakes.) Pitfall: StandardScaler must be fit on X, not on the whole df. -->

---

## How Many Clusters? The Elbow

```python
inertias = []
for k in range(1, 9):
 km = KMeans(n_clusters=k, random_state=42, n_init=10)
 km.fit(X_scaled)
 inertias.append(km.inertia_)
```

|K | 1 | 2 | **3** | 4 | 5 | 6 | 7 | 8 |
|--:|--:|--:|--:|--:|--:|--:|--:|--:|
|Inertia | 1,600 | 832 | **498** | 402 | 354 | 312 | 289 | 267 |

<div style="text-align: center;">

**1,600 → 832 = −768 &nbsp;|&nbsp; 832 → 498 = −334 &nbsp;|&nbsp; 498 → 402 = −96**

<small>The elbow is at **K = 3** </small>

</div>

<!-- speaker_note: The elbow method is heuristic — look for the 'knee' where the drop flattens. Here it's clearly K=3. Pitfall: students often pick K where inertia is lowest (K=8). Explain that we trade complexity for parsimony. The diminishing returns after K=3 are clear from the delta values. -->

---

## Classify New Customers

```python
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
 X_scaled, df['segment'], test_size=0.3, random_state=42
)
clf = LogisticRegression(max_iter=1000)
clf.fit(X_train, y_train)

print(f"Accuracy: {clf.score(X_test, y_test):.1%}")
```

<div style="text-align: center; padding: 0.5em;">

### 95.8% accuracy

<small>Baseline (random guess with 3 equal classes): **33%**</small>

</div>

<!-- speaker_note: We use logistic regression on the clustered data to classify NEW customers. This bridges unsupervised (discovering groups) with supervised (predicting group membership). The 95.8% is good but not perfect — we expect some misclassification at cluster boundaries. Pitfall: make sure 'segment' (numeric) is the target, not 'segment_label' (string). -->

---

## Grouping: Your Toolkit

|Approach | Type | Question Answered |
|:--|:--|:--|
|`df.groupby().mean()` | Supervised summary | *What do my known groups look like?* |
|`KMeans(n_clusters=3)` | Unsupervised clustering | *What groups EXIST in my data?* |
|Elbow method | Model selection | *How many groups are there?* |
|`LogisticRegression()` | Supervised classification | *Which group is this NEW customer?* |

<br>

> **Q: FINAL GROUPING QUESTION:** You're the marketing director. Budget covers ONE email campaign. Which segment — and defend with a number from the groupby table.
> **Discuss: 30 seconds to decide. Then we compare answers across the room.**

<!-- speaker_note: This is a cumulative question — they should use the groupby results to defend their choice. Listen for answers that cite specific numbers. If someone says "Whales because they spend $9,377/yr", that's a strong answer. If someone says "Budget shoppers because there are more of them (159)", that's also valid. -->

---

<!-- _class: lead -->

## End of Part 2 Recap

### What We Just Did

|Concept | Code / Method | Outcome |
|:--|:--|:--|
|Labeled groups | `df.groupby().mean()` | Segment profiles |
|No labels → K-Means | `KMeans(n_clusters=3)` | Found 3 true segments |
|Choosing K | Elbow method | K=3 confirmed |
|Classify new customers | `LogisticRegression()` | 95.8% accuracy |

### Three segments: **Budget Shopper** · **Premium Loyalist** · **Whale**

<!-- speaker_note: Quick summary — 30 seconds. Ask "What's the difference between supervised and unsupervised learning?" Answer: labels vs no labels. Transition: "Now for the last piece: predicting salary from experience." -->

---

<!-- _class: lead -->

# PART 3
# PREDICTION

 15 min · 9 slides

*"The past knows the future. You extract it."*

<!-- speaker_note: Part 3 is the most 'statistical' section — we introduce OLS regression. The key message: regression turns a research question into a testable model. Timing check: we should be about 25-27 minutes in. -->

---

## Explore: Experience vs Salary

```python
df = pd.read_csv("salary_clean.csv")
print(df.describe())
```

|| salary | experience | is_manager | hours |
|:---|---:|---:|---:|---:|
|**mean** | $97,077 | 18.1 yr | 19% | 38.0 hr |
|**std** | $25,355 | 10.1 yr | 39% | 6.0 hr |
|**range** | $33K–$156K | 0.2–34.8 yr | 0–1 | 20–60 hr |

**Education:** 201 Bachelor's · 144 High School · 130 Master's

```python
corr = df['experience'].corr(df['salary'])
print(f"Correlation: {corr:.3f}") # → 0.888
```

<br>

> **Q:** Correlation is 0.888. Is that "good"? What does it actually **MEAN**?
> **Discuss: Think for 10 seconds. Then write your answer in one sentence.**

<!-- speaker_note: The loaded dataset is 'salary_clean.csv' — the cleaned version from Part 1. 0.888 means strong positive linear relationship: more experience → higher salary. But correlation ≠ causation. Ask: "Could there be a third factor driving both?" (Education, industry, etc.) -->

---

## Your First Regression

```python
import statsmodels.formula.api as smf

model1 = smf.ols('salary ~ experience', data=df).fit()
print(model1.summary())
```

```
 OLS Regression Results
==============================================================================
 coef std err t P>|t|
------------------------------------------------------------------------------
Intercept 5.74e+04 1218.327 47.146 0.000
experience 2227.98 53.050 **42.000** **0.000**
------------------------------------------------------------------------------
R-squared: **0.789**
```

<br>

> **Q:** `salary ~ experience` — what does the `~` mean in plain English?
> **Discuss: "Salary is predicted BY experience" or "Salary depends ON experience."**

<!-- speaker_note: The tilde reads as 'is modelled by' or 'depends on'. Y ~ X means Y is the outcome, X is the predictor. Type this line by line. The summary output is intimidating at first — tell them we only care about 4 numbers. Pitfall: statsmodels output shows 'P>|t|' as scientific notation — demystify it. -->

---

## How to Read a Regression Table

**Only four numbers matter.** Everything else: greyed out.

|| What | Value | Meaning |
|:--|:--|:--|:--|
|| **coef** | **+$2,228** | Each year of experience → +$2,228 |
|| **P>\\|t\\|** | **< 0.001** | Virtually certain this is real |
|| **t-statistic** | **42.0** | 42 standard errors from zero — enormous |
|| **R²** | **0.789** | Experience explains 78.9% of salary |

<br>

<small>95% CI: true effect between **$2,124** and **$2,333** per year of experience.</small>

<!-- speaker_note: Four numbers, four colours. The story: experience has a large, precisely estimated, highly significant effect on salary, accounting for 79% of variation. The 95% CI says we're confident the true per-year increase is between $2,124 and $2,333. Pitfall: students confuse p-value with effect size — remind them p < 0.001 doesn't mean 'big', it means 'precise'. -->

---

## The t-statistic

<div style="text-align: center; font-size: 1.1em;">

**t = coefficient ÷ standard error = $2,228 ÷ $53 = 42.0**

</div>

### What t-values Mean

|t-value | p ≈ | Interpretation | Verdict |
|--:|:--|:--|:--|
|0.5 | 0.62 | Coefficient is ~half its SE | Not significant — noise |
|1.5 | 0.13 | Coefficient is 1.5× its SE | Might be real, can't be sure |
|**2.0** | **0.05** | Coefficient is 2× its SE | **Significant** (conventional) |
|3.0 | 0.003 | Coefficient is 3× its SE | **Highly significant** |
|**42.0** | **6.8×10⁻¹⁶²** | Coefficient is 42× its SE | **Overwhelming** |

<br>

<small>Rule of thumb: |t| > 2 → significant at the 5% level (for large samples). Our t=42 is off the charts.</small>

<!-- speaker_note: Replace the ASCII distribution with a clean table. The t-statistic is a signal-to-noise ratio. t=2 is the conventional threshold (roughly p=0.05). Our t=42 is enormous — 42 standard errors from zero. Emphasise: a large t means the signal is loud relative to the noise. Pitfall: students may confuse t-stat with coefficient size — a small effect with tiny SE can have large t. -->

---

## Add More Variables

<!-- _class: compact -->

```python
model2 = smf.ols(
 'salary ~ experience + education + is_manager + hours',
 data=df
).fit()
```

|Variable | Coef | t | p | Interpretation |
|:---|---:|---:|---:|:--|
|`experience` | **+$2,183** | 57.2 | <0.001 | Each year → +$2,183 |
|`education[T.High School]` | **−$5,123** | −5.6 | <0.001 | HS grads: −$5,123 vs Bachelor's |
|`education[T.Master]` | **+$7,071** | 7.5 | <0.001 | Master's: +$7,071 vs Bachelor's |
|`is_manager` | **+$16,267** | 16.5 | <0.001 | Managers: +$16,267 |
|`hours` | **+$287** | 4.7 | <0.001 | Each extra hour → +$287 |
|**R²** | **0.892** | — | — | **89.2% explained** |

> **Q:** The experience coef was **$2,228** in Model 1. Now it's **$2,183**. Why did it change?
> **Discuss: Take 20 seconds — chat with your neighbour. Use the word 'omitted variable bias'.**

<!-- speaker_note: Used compact class to fit all 7 rows. The coefficient dropped because Model 1 suffered from omitted variable bias — experience was proxying for education and management status. Now with controls, we see experience's 'pure' effect. This is THE key insight for causal inference: coefficients change when you add variables. Pitfall: someone may ask why we don't add ALL variables — introduce overfitting briefly. -->

---

## What About Department?

<!-- _class: compact -->

```python
model3 = smf.ols(
 'salary ~ experience + education + is_manager + hours + C(department)',
 data=df
).fit()
```

|Variable | Coef | t | p | Interpretation |
|:---|---:|---:|---:|:--|
|`experience` | **+$2,167** | 63.2 | <0.001 | Each year → +$2,167 |
|`education[T.High School]` | **−$5,088** | −6.3 | <0.001 | vs Bachelor's |
|`education[T.Master]` | **+$7,482** | 8.9 | <0.001 | vs Bachelor's |
|`is_manager` | **+$17,022** | 19.2 | <0.001 | +$17K for managers |
|`hours` | **+$284** | 5.3 | <0.001 | Per extra hour |
|`department[T.Finance]` | **+$3,931** | 4.1 | <0.001 | vs Engineering |
|`department[T.Marketing]` | **−$5,956** | −6.0 | <0.001 | vs Engineering |
|`department[T.Operations]` | **−$3,957** | −4.0 | <0.001 | vs Engineering |
|**R²** | **0.915** | — | — | **91.5% explained** |

<br>

<small>Department effects relative to **Engineering** (reference). Finance premium, Marketing penalty — both survive controls.</small>

<!-- speaker_note: Used compact class for 8 variable rows. Adding department bumps R² from 0.892 to 0.915. The department effects are interpretable: Finance pays $3,931 more than Engineering; Marketing pays $5,956 less. Point out: experience coefficient barely changed ($2,183 → $2,167), suggesting experience isn't confounded by department choice. -->

---

## The Bleeding Edge: Beyond OLS

|| OLS | Random Forest | XGBoost |
|:--|:--|:--|:--|
|**Interpretability** | | | |
|**Predictive power** | | | |
|**Assumptions** | Linearity, normality | **None** | **None** |
|**Output** | coef, p, t, R², CI | Feature importance | Feature importance |
|**Question** | ***Why?*** | ***What?*** | ***What, accurately?*** |

<br>

> **Q:** If XGBoost predicts better, why ever use OLS?
>
> *"Salary goes up by $2,167/year and we're 99.999% confident" — you can defend that statement to a boss, a journal, or a court. "The black box says so" — you can't.*
>
> **Discuss: Any thoughts on when you'd prefer interpretability over accuracy?**

<!-- speaker_note: This slide broadens the perspective. The trade-off: accuracy vs interpretability. For regulated industries (banking, healthcare, hiring), interpretability is legally required. For competition rankings (Kaggle), accuracy wins. Let the audience discuss. Pitfall: someone might think OLS is 'better' — it's not, it's different. -->

---

## Your 8-Line Toolkit

<!-- _class: compact -->

```python
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
print(model.summary()) # coef, p, t, R² — your 4 numbers
```

<br>

<small>Screenshot this. Works on **ANY** dataset with a numeric target.</small>

<!-- speaker_note: This is the cheat sheet slide — encourage them to screenshot it. Every line here was typed during the workshop. This slide is the "take-home" — apply these 8 lines to any CSV and you have a complete analysis pipeline. Timing: we have about 2-3 minutes remaining. -->

---

<!-- _class: lead -->

# Data Speaks.
# Now You Do Too.

### Find a CSV — Kaggle, CBS StatLine, Eurostat
### Try `RandomForestRegressor` — compare to OLS
### Add an instrument — you have IV for your thesis

<br>

<small>Files: `salary_clean.csv` · `customer_segments.csv` · `generate_datasets.py` · This deck</small>

<!-- speaker_note: Closing remarks (1 min). Congratulate them on completing the full pipeline: tidy → group → predict. Point them to next steps: Kaggle datasets for practice, trying RandomForest for comparison, and using IV methods from their econometrics courses. The files are all in the workshop directory — they can re-run everything. Thank them and open for final questions. -->
