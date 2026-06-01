# USE Honours Event — Slide-by-Slide Draft for Kimi Slides
### One 40-minute walkthrough: Tidying → Grouping → Prediction
### Format: one slide = one `###` block.

---

---

# PART 0: INTRO — "Data Speaks. Can You Hear It?"  (Slides 1–5, ~5 min)

---

### Slide 1 — Title Slide
**On screen:** USE logo (top-left). Large centred text: "Data Speaks. Can You Hear It?" Subtitle: "Honours Workshop — Statistical Inference with Python". Bottom: date, presenter name.

**Presenter says:** "Welcome. Today you're not going to listen to me talk about data. You're going to talk TO data. And data is going to talk back. In 40 minutes, you'll learn three skills that every analyst uses every single day: tidying messy data, finding hidden groups, and making predictions you can defend."

---

### Slide 2 — The Three Skills
**On screen:** Three large icons in a horizontal row, connected by arrows:

| Icon | Label | One-liner |
|------|-------|-----------|
| [Tidy] Broom | **TIDY** | "Real data is messy. You fix it." |
| [Group] Magnifying glass | **GROUP** | "Patterns hide in plain sight. You find them." |
| [Predict] Crystal ball | **PREDICT** | "The past knows the future. You extract it." |

**Presenter says:** "These are the three skills. Tidying: because no one hands you clean data. Grouping: because categories and clusters reveal structure. Prediction: because once you understand the structure, you can forecast what comes next. We'll spend about 10 minutes on tidying, 15 on grouping, and 15 on prediction. Every step — you follow along on your laptop."

---

### Slide 3 — The Datasets
**On screen:** Two dataset cards side by side.

LEFT CARD (blue): "[Salary] Salary Data" — 500 employees. Variables: salary, experience, education, manager status, hours, department. **Used for:** Tidying + Prediction.

RIGHT CARD (green): "[Customers] Customer Segments" — 400 shoppers. Variables: annual spend, visit frequency, basket size, loyalty years, segment. **Used for:** Grouping.

**Presenter says:** "Two datasets. Both synthetic but built to behave like real data — the coefficients, t-statistics, and cluster separations all match what you'd see in the wild. You'll have both CSV files on your laptop."

---

### Slide 4 — "You Will Need"
**On screen:** Three items with checkmarks:
1. Python 3.9+ installed
2. One terminal command: `pip install pandas numpy matplotlib seaborn statsmodels scikit-learn`
3. The datasets on your laptop (QR code on screen)

Large QR code at bottom-right.

**Presenter says:** "If you haven't installed the packages yet, run that command now. It takes 30 seconds."

---

### Slide 5 — "How This Works"
**On screen:** A timeline bar:

| Block | Label | Duration |
|-------|-------|----------|
| TIDY | Clean messy salary data | ~10 min |
| GROUP | Cluster + classify customers | ~15 min |
| PREDICT | Regress salary, interpret output | ~15 min |

Below: "I talk for ~12 minutes. You work for ~28."

**Presenter says:** "Open your terminal. We start with tidying."

---

---

# PART 1: TIDYING — "The Data Is Broken. Fix It."  (Slides T1–T6, ~10 min)

---

### Slide T1 — "Here Is Your Data"
**On screen:** A screenshot of `salary_messy.csv` opened in a text editor. Visible problems highlighted in red:

| Line | Problem | Highlight |
|------|---------|-----------|
| Header | Column names: `"Annual Salary ($)"`, `"Manager? (1=Yes)"` — spaces, caps, special chars | (R) |
| Row 47 | `Annual Salary ($)` is blank — missing value | (R) |
| Row 502 | Duplicate of row 2 | (R) |
| Row 504 | Salary = 650,000 (data entry error — extra zero) | (R) |
| Col H | `Department_Code` with `"ENG:::EER"` — should be two columns | (R) |

**Presenter says:** "This is what real data looks like. Someone exported it from Excel, someone else hand-edited it, a third person merged two files badly. Your first job as an analyst: fix it so the computer can read it. Open `salary_messy.csv`."

---

### Slide T2 — "Load It. See What's Wrong."
**On screen:** Code block, large font:

```python
import pandas as pd

df = pd.read_csv("salary_messy.csv")
print(df.head())
print(df.info())
```

Below: the actual output — column names with spaces and special chars, `Annual Salary ($)` shows `NaN` for rows 47-51, 504 rows when there should be 500.

**Presenter says:** "Run these two lines. `df.info()` is your diagnostic tool. Look at: (1) column names — spaces and symbols will break your code later. (2) Non-null counts — 475 for salary means 29 missing values. (3) Row count — 504 when you expect 500. Four duplicates somewhere. Find them."

---

### Slide T3 — "Fix 1: Clean Column Names"
**On screen:**

```python
# Before: 'Annual Salary ($)', 'Manager? (1=Yes)', 'Hours/Week'
# After:  'annual_salary',    'is_manager',       'hours_per_week'

df.columns = (df.columns
    .str.lower()
    .str.replace("[^a-z0-9_]", "_", regex=True)
    .str.replace("_+", "_", regex=True)
    .str.strip("_"))

print(df.columns.tolist())
```

Output: `['annual_salary', 'years_experience', 'education_level', 'is_manager', 'hours_per_week', 'department', 'department_code', 'education_numeric']`

**Presenter says:** "First rule of tidying: make column names machine-friendly. Lowercase, underscores, no spaces, no special characters. Run this block. Now you can type `df['annual_salary']` without quotes around a mess."

---

### Slide T4 — "Fix 2: Missing Values & Duplicates"
**On screen:**

```python
# How many missing?
print(df['annual_salary'].isna().sum())  # → 29

# Drop rows where salary is missing
df = df.dropna(subset=['annual_salary'])

# Remove duplicate rows
before = len(df)
df = df.drop_duplicates()
print(f"Removed {before - len(df)} duplicates. Now {len(df)} rows.")
```

**Presenter says:** "Missing salary means we can't use that row for prediction — drop it. Duplicates mean the same person appears twice — drop one copy. How many rows do you have now? Should be close to 500."

---

### Slide T5 — "Fix 3: The Outlier"
**On screen:** A boxplot of `annual_salary`.

```python
import matplotlib.pyplot as plt
plt.boxplot(df['annual_salary'])
plt.show()
```

One dot at $650,000, far above the rest (mean ~$97K, max otherwise ~$140K).

```python
# Find and remove the outlier
q99 = df['annual_salary'].quantile(0.99)
outlier_mask = df['annual_salary'] > q99 * 3  # 3x the 99th percentile
print(f"Outlier rows: {outlier_mask.sum()}")
df = df[~outlier_mask]
```

**Presenter says:** "One salary is 10× what it should be — someone typed an extra zero. Boxplots catch this instantly. We remove it. In a real job, you'd email whoever sent you the file. Today, we drop it."

---

### Slide T6 — "Fix 4: Split & Clean Up"
**On screen:**

```python
# Split 'ENG:::EER' into department_code + suffix
df[['dept_code', 'dept_suffix']] = df['department_code'].str.split(':::', expand=True)
df = df.drop(columns=['department_code', 'dept_suffix', 'education_numeric'])

# Final check
print(f"Clean! {len(df)} rows, {len(df.columns)} columns")
print(df.describe())
```

**Presenter says:** "That column with the triple colons? Someone concatenated two fields. We split them apart, then drop what we don't need. Now save this clean version — you'll use it in the Prediction section. Type: `df.to_csv('salary_clean.csv', index=False)`."

---

### Slide T6.5 — "You Just Tidied Data"
**On screen:** Before/after comparison:

| Before | After |
|--------|-------|
| `"Annual Salary ($)"` | `annual_salary` |
| 29 missing salaries | 0 missing |
| 4 duplicate rows | 0 duplicates |
| 1 outlier ($650K) | Removed |
| Concatenated column | Split into two, cleaned |
| 504 rows, 8 messy columns | ~498 rows, 6 clean columns |

**Presenter says:** "This is what data analysts spend 60% of their time doing. You just did it in 8 minutes. The dataset is now clean, predictable, and ready for analysis. On to grouping."

---

---

# PART 2: GROUPING — "Who Are Your Customers?"  (Slides G1–G8, ~15 min)

---

### Slide G1 — "A New Dataset: Customer Segments"
**On screen:** `customer_segments.csv` — first 5 rows visible. Columns: annual_spend, visit_frequency_month, avg_basket_size, loyalty_years, segment, segment_label.

**Presenter says:** "New dataset. 400 customers of an online store. You have their spending, how often they visit, how big their basket is, and how long they've been loyal. The `segment` column is hidden from you — your job is to DISCOVER the segments. First: supervised grouping. Then: unsupervised clustering."

---

### Slide G2 — "Supervised Grouping: `groupby()`"
**On screen:** Code:

```python
df = pd.read_csv("customer_segments.csv")

# Group by segment_label and compute means
print(df.groupby('segment_label')[['annual_spend', 'visit_frequency_month',
      'avg_basket_size', 'loyalty_years']].mean().round(1))
```

Output table:

| segment_label | annual_spend | visit_freq | basket_size | loyalty_yrs |
|---------------|-------------|------------|-------------|-------------|
| Budget Shopper | $1,172 | 14.1/mo | 22.2 | 2.5 yr |
| Premium Loyalist | $4,509 | 10.0/mo | 55.1 | 7.0 yr |
| Whale | $9,408 | 6.1/mo | 119.0 | 5.1 yr |

**Presenter says:** "Three customer types jump out immediately. Budget shoppers visit often but spend little. Whales visit rarely but drop huge baskets. Premium loyalists are in the middle — steady and long-term. But what if you DIDN'T have the segment labels? Can you discover these groups automatically?"

---

### Slide G3 — "Unsupervised Grouping: K-Means Clustering"
**On screen:** Simple visual — 3 blobs of coloured dots on a 2D plane (spend vs frequency). Centroids marked with X.

```
         spend →
freq  ↑   (B)(B)      (G)(G)(G)
          (B)(B)(B)
                    (G)(G)
                (Y)
            (Y)(Y)(Y)(Y)
                (Y)(Y)
```

**Presenter says:** "K-means clustering: give the algorithm a number K, and it finds K groups. How? It picks K random centroids, assigns every point to the nearest centroid, recomputes centroids, repeats until stable. You don't tell it what the groups ARE — it discovers them from the data alone."

---

### Slide G4 — "Run K-Means: 3 Clusters"
**On screen:**

```python
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# Select features for clustering
X = df[['annual_spend', 'visit_frequency_month',
        'avg_basket_size', 'loyalty_years']]

# Scale (important! spend is in thousands, frequency is in tens)
X_scaled = StandardScaler().fit_transform(X)

# Cluster
kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['cluster'] = kmeans.fit_predict(X_scaled)

# Compare to true segments
print(pd.crosstab(df['segment_label'], df['cluster']))
```

**Presenter says:** "Run this. The crosstab shows how well the algorithm recovered the true segments. If it worked, you'll see one big number per row — the algorithm found the same groups you saw in the `groupby()` table. But it did it WITHOUT labels."

---

### Slide G5 — "Visualise the Clusters"
**On screen:** A scatter plot — `annual_spend` vs `visit_frequency_month`, points coloured by discovered cluster.

```python
import seaborn as sns
sns.scatterplot(data=df, x='annual_spend', y='visit_frequency_month',
                hue='cluster', palette='Set1', alpha=0.7)
plt.title("Customer Segments Discovered by K-Means")
plt.show()
```

Three distinct coloured clouds: blue (bottom-left, high frequency, low spend), green (middle, medium everything), red (upper-left, huge spend, low frequency).

**Presenter says:** "Look at your plot. Three groups. No labels needed. The algorithm found structure that was ALREADY in the data. That's unsupervised learning — the data organizes itself."

---

### Slide G6 — "What About 4 Clusters? 5?"
**On screen:** Elbow plot — K on x-axis (1–8), inertia on y-axis. A clear elbow at K=3.

```python
inertias = []
for k in range(1, 9):
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    km.fit(X_scaled)
    inertias.append(km.inertia_)

plt.plot(range(1, 9), inertias, 'bo-')
plt.xlabel('Number of Clusters (K)')
plt.ylabel('Inertia')
plt.title('Elbow Method: Optimal K = 3')
plt.show()
```

**Presenter says:** "How do you know K=3 is right? Elbow method: try K=1, 2, 3... 8. The inertia drops fast at first, then levels off. The 'elbow' — where adding more clusters stops helping much — is K=3. That's your answer."

---

### Slide G7 — "Supervised Classification: Predict the Segment"
**On screen:** Code:

```python
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, df['segment'], test_size=0.3, random_state=42
)

# Train
clf = LogisticRegression(max_iter=1000)
clf.fit(X_train, y_train)

# Evaluate
y_pred = clf.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, y_pred):.2%}")
```

**Presenter says:** "Now flip it: can we PREDICT which segment a NEW customer belongs to? That's supervised classification. Logistic regression learns the boundaries between groups. On this data, accuracy should be 95%+ — the segments are well-separated."

---

### Slide G8 — "Grouping: What We Learned"
**On screen:**

| Approach | Type | Question Answered |
|----------|------|-------------------|
| `df.groupby()` | Supervised summary | "What do my known groups look like?" |
| K-Means | Unsupervised clustering | "What groups EXIST in my data?" |
| Logistic Regression | Supervised classification | "Which group does this NEW customer belong to?" |

**Presenter says:** "Three ways to group. `groupby()` is your daily driver. K-means discovers structure you didn't know existed. Logistic regression puts new observations into the groups you found. These three tools cover 90% of grouping tasks. On to prediction."

---

---

# PART 3: PREDICTION — "What Drives Salary?"  (Slides P1–P10, ~15 min)

---

### Slide P1 — "Back to Salary Data"
**On screen:** The clean salary dataset — `df.head()` showing 5 rows of salary, years_experience, education, is_manager, hours_per_week, department.

**Presenter says:** "Load your clean salary data. The question: what determines someone's salary? Experience? Education? Being a manager? Hours worked? Department? We're going to answer that with OLS regression — the workhorse of statistical inference."

---

### Slide P2 — "First: Explore One Relationship"
**On screen:**

```python
df = pd.read_csv("salary_clean.csv")  # your tidied file

# Plot: experience vs salary
sns.regplot(x='years_experience', y='annual_salary', data=df,
            scatter_kws={'alpha': 0.4}, line_kws={'color': 'red'})
plt.title("Experience vs Salary")
plt.show()

corr = df['years_experience'].corr(df['annual_salary'])
print(f"Correlation: {corr:.3f}")
```

A scatter plot with clear upward slope.

**Presenter says:** "Run this. Every dot is an employee. The red line is the trend. One year of experience correlates with higher salary. But by HOW MUCH? And is it just experience, or are managers with experience driving the pattern? One variable at a time can't answer that."

---

### Slide P3 — "OLS Regression: The One-Liner"
**On screen:** Large code block:

```python
import statsmodels.formula.api as smf

model1 = smf.ols('annual_salary ~ years_experience', data=df).fit()
print(model1.summary())
```

The `summary()` output builds on screen from top to bottom.

**Presenter says:** "This is an OLS regression. `annual_salary ~ years_experience` means 'explain salary using experience.' One line of Python. The output looks intimidating — we only care about FOUR numbers."

---

### Slide P4 — "How to Read a Regression Table"
**On screen:** The `model1.summary()` output, only four things highlighted:

| What | Highlight | Plain English |
|------|-----------|---------------|
| `years_experience  coef = 2168` | (Y) YELLOW | "+1 year experience → +$2,168 salary" |
| `P>\|t\| = 0.000` | (G) GREEN | "We are VERY sure this is real (not noise)" |
| `t = 65.8` | (P) PURPLE | "The effect is 65.8 standard errors from zero — massive" |
| `R-squared = 0.503` | (B) BLUE | "Experience alone explains 50% of salary variation" |

Everything else is greyed out.

**Presenter says:** "Four numbers. Coef: how big the effect is. P-value: are we sure it's real? t-statistic: how many standard errors the coefficient is from zero — bigger = more confident. R²: what fraction of the story does this variable tell? Experience explains 50% of salary. What explains the other 50%?"

---

### Slide P5 — "The t-statistic: Why It Matters"
**On screen:** A normal-ish distribution (t-distribution with many df). The t-statistic of 65.8 is marked far in the tail, in the "p < 0.001" zone. Below it, a smaller t of 1.2 in the middle (grey zone, "p = 0.23 — not significant").

**Presenter says:** "The t-statistic is `coef / SE` — the signal divided by the noise. When t > 2 (roughly), p < 0.05 and we say the effect is 'statistically significant.' Our t of 65 means experience is DEFINITELY not zero. The data was BUILT with a known true effect of $2,200/year. The model recovered $2,168. That's statistical inference: the data tells you what the world actually looks like."

---

### Slide P6 — "Add More Variables: Multiple Regression"
**On screen:**

```python
model2 = smf.ols(
    'annual_salary ~ years_experience + education + is_manager + hours_per_week',
    data=df
).fit()
print(model2.summary())
```

**Presenter says:** "Now add education, manager status, and hours. The model now says: 'holding everything else constant, what's the pure effect of each variable?' This is where inference gets powerful. When you add education, the experience coefficient might CHANGE — because more experienced people tend to have more education. Multiple regression untangles these confounded effects."

---

### Slide P7 — "Read the Rich Model"
**On screen:** The `model2.summary()` output, key rows highlighted:

| Variable | Coef | P-value | t-stat | Interpretation |
|----------|------|---------|--------|----------------|
| `years_experience` | +$2,168 | 0.000 | 65.8 | Each year → +$2,168 |
| `education[T.High School]` | −$5,003 | 0.000 | −6.4 | HS grads earn $5K less than Bachelors |
| `education[T.Master]` | +$7,460 | 0.000 | 9.3 | Master's earns $7.5K more than Bachelor's |
| `is_manager` | +$17,035 | 0.000 | 20.6 | Managers earn $17K more |
| `hours_per_week` | +$276 | 0.000 | 5.3 | Each extra hour → +$276 |
| **R²** | **0.916** | — | — | **92% of salary explained!** |

**Presenter says:** "Every variable is significant. R² jumped from 50% to 92% — we're explaining almost all the variation. The biggest effect is being a manager: +$17,000. But ask yourself: does being a manager CAUSE higher salary? Or do higher-paid people get promoted to manager? Regression tells you the correlation. Causality is a harder question."

---

### Slide P8 — "What About Department?"
**On screen:**

```python
model3 = smf.ols(
    'annual_salary ~ years_experience + education + is_manager + hours_per_week + C(department)',
    data=df
).fit()
print(model3.summary())
```

Department coefficients highlighted:

| Department | Coef vs Engineering | Interpretation |
|------------|---------------------|----------------|
| Finance | +$3,770*** | Finance pays $3.8K more than Engineering |
| Marketing | −$6,097*** | Marketing pays $6.1K less |
| Operations | −$4,172*** | Operations pays $4.2K less |

**Presenter says:** "Add `C(department)` to include department as a categorical variable. Finance pays a premium. Marketing pays less. Both effects survive controlling for experience, education, and manager status. The data says: even with the SAME experience and education, department matters."

---

### Slide P9 — "The Bleeding Edge: Beyond OLS"
**On screen:** A visual comparison — three model cards:

| | OLS Regression | Random Forest | XGBoost |
|---|---------------|---------------|---------|
| **Interpretability** | [5/5] | [2/5] | [2/5] |
| **Predictive power** | [3/5] | [4/5] | [5/5] |
| **Assumptions** | Linearity, normality, homoskedasticity | None | None |
| **Output** | Coefficients, p-values, t-stats, R² | Feature importance | Feature importance |
| **When to use** | "Why does this happen?" | "What will happen?" | "What will happen, accurately?" |
| **Python** | `statsmodels` | `sklearn.ensemble` | `xgboost` |

**Presenter says:** "OLS is the inferential workhorse — it tells you WHY, with statistical confidence. But when prediction accuracy is all that matters, modern machine learning takes over. Random forests handle non-linear relationships automatically. XGBoost is what wins Kaggle competitions. These are the tools you graduate to. But they don't give you p-values or t-statistics — they give you predictions, not explanations. For a thesis, a policy paper, or a business case — you still need OLS."

---

### Slide P10 — "What We Did in 40 Minutes"
**On screen:** A pipeline diagram:

```
[Tidy] TIDY           [Group] GROUP              [Predict] PREDICT
───────           ─────────            ──────────
Clean names    →  groupby() mean   →   sns.regplot()
Drop missing   →  K-Means (K=3)   →   smf.ols()
Remove dupes   →  Elbow method    →   Coefficients
Fix outlier    →  Log. Regression →   p-values
Split column   →  95% accuracy    →   t-statistics
                                    →   R² = 0.92
                                    →   Bleeding edge
```

One line at the bottom: **"8 lines of Python. Infinite applications."**

```python
df = pd.read_csv("data.csv")
df.groupby('category').mean()
KMeans(n_clusters=3).fit_predict(X)
LogisticRegression().fit(X, y)
smf.ols('y ~ x1 + x2', data=df).fit().summary()
```

**Presenter says:** "You tidied broken data. You found hidden customer segments with unsupervised learning. You predicted salaries with OLS regression and read the output like a statistician. You know what a t-statistic means. You know the difference between correlation and causation. And you know what tools exist beyond OLS. Screenshot this slide. These 8 lines are your new toolkit."

---

### Slide P11 — "Take It With You"
**On screen:** Three challenge cards for later:

1. [Data] **Your own data** — Load ANY CSV. Run `.describe()`, `.corr()`, and a regression. What do you find?
2. [ML] **Try Random Forest** — `from sklearn.ensemble import RandomForestRegressor`. Compare R² to OLS. Why is it higher? What did you lose?
3. [Online] **Real datasets** — Kaggle, CBS StatLine, Eurostat. Go find a dataset that matters to YOUR field. The code is the same.

---

### Slide P12 — Thank You
**On screen:** USE logo. "Data Speaks. Now You Do Too." Presenter contact info. QR code to the code + datasets.
