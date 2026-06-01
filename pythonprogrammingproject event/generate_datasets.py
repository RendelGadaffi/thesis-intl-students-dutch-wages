"""
Generate two synthetic datasets for the Statistical Inference workshop.
Both have known true DGPs so t-statistics, cluster assignments, and
predictions are all verifiable.

Dataset 1: salary_data.csv (N=500) — Prediction / Regression
  - Properly specified DGP with normal homoskedastic errors
  - True coefficients known → t-statistics follow correct distributions
  - Variables: salary, experience, education, manager, hours, department

Dataset 2: customer_segments.csv (N=400) — Grouping / Clustering
  - 3 Gaussian clusters with known centroids
  - Well-separated for clean k-means
  - Segment labels for supervised classification comparison
"""
import numpy as np
import pandas as pd

rng = np.random.default_rng(2025)  # fixed seed for reproducibility

# ================================================================
# DATASET 1: Salary Prediction  (N=500)
# ================================================================
# True DGP:
#   salary = 35_000
#          + 2_200 * years_experience
#          + 6_500 * has_bachelor
#          + 14_000 * has_master
#          + 18_000 * is_manager
#          + 250 * hours_per_week
#          + department_effect
#          + ε,  ε ~ N(0, 8500²)
#
# All predictors have ~zero correlation with each other (good for teaching:
# coefficients don't change when you add variables, and t-stats are clean).

N = 500
sigma = 7000  # residual SD — realistic noise, all true effects remain significant

# Generate uncorrelated predictors
years_experience = rng.uniform(0, 35, N)

# Education (mutually exclusive categories)
edu_rand = rng.uniform(0, 1, N)
has_highschool = (edu_rand < 0.30).astype(int)
has_bachelor   = ((edu_rand >= 0.30) & (edu_rand < 0.70)).astype(int)
has_master     = (edu_rand >= 0.70).astype(int)

# Manager (independent of experience and education)
is_manager = (rng.uniform(0, 1, N) < 0.22).astype(int)

# Hours per week
hours_per_week = rng.normal(38, 6, N)
hours_per_week = np.clip(hours_per_week, 20, 60)

# Department (4 departments, roughly balanced)
dept_idx = rng.integers(0, 4, N)
departments = np.array(["Engineering", "Marketing", "Finance", "Operations"])
department = departments[dept_idx]
# Department base salary effects
dept_effect = np.array([5000, -2000, 8000, 0])  # Finance premium, Marketing penalty
dept_adj = dept_effect[dept_idx]

# Construct salary from DGP
salary = (35000
          + 2200 * years_experience
          + 6500 * has_bachelor
          + 14000 * has_master
          + 18000 * is_manager
          + 250 * hours_per_week
          + dept_adj
          + rng.normal(0, sigma, N))

# Build education string label
def edu_label(hs, ba, ma):
    if ma: return "Master"
    if ba: return "Bachelor"
    return "High School"

education = [edu_label(hs, ba, ma) for hs, ba, ma in zip(has_highschool, has_bachelor, has_master)]

df_salary = pd.DataFrame({
    "salary":             np.round(salary, 0).astype(int),
    "years_experience":   np.round(years_experience, 1),
    "education":          education,
    "is_manager":         is_manager,
    "hours_per_week":     np.round(hours_per_week, 1),
    "department":         department,
})

# Shuffle rows so clusters aren't obvious
df_salary = df_salary.sample(frac=1, random_state=42).reset_index(drop=True)

# ================================================================
# DATASET 1B: salary_messy.csv — for the TIDYING section
# ================================================================
# Same data but with deliberate mess:
#   - Missing values in salary (5%)
#   - Duplicate rows (3)
#   - Bad column names (spaces, caps)
#   - A column that should be split (department_code with weird separator)
#   - An outlier salary (data entry error: extra zero)
#   - A categorical column stored as numeric codes

df_messy = df_salary.copy()
# Rename columns to be messy
df_messy.columns = ["Annual Salary ($)", "Years Experience", "Education Level",
                     "Manager? (1=Yes)", "Hours/Week", "Department"]

# Insert 5% missing salaries
missing_idx = rng.choice(N, size=int(N * 0.05), replace=False)
df_messy.loc[missing_idx, "Annual Salary ($)"] = np.nan

# Add 3 duplicate rows
dupes = df_messy.iloc[:3].copy()
df_messy = pd.concat([df_messy, dupes], ignore_index=True)

# Add an outlier (extra zero on salary)
outlier_row = df_messy.iloc[10:11].copy()
outlier_row["Annual Salary ($)"] = outlier_row["Annual Salary ($)"] * 10
df_messy = pd.concat([df_messy, outlier_row], ignore_index=True)

# Create a "Department_Code" column with weird separator
df_messy["Department_Code"] = df_messy["Department"].str[:3].str.upper() + ":::" + df_messy["Department"].str[-3:].str.upper()

# Add an Education_Numeric column (codebook: 1=HS, 2=BA, 3=MA)
edu_map = {"High School": 1, "Bachelor": 2, "Master": 3}
df_messy["Education_Numeric"] = df_messy["Education Level"].map(edu_map)

# ================================================================
# DATASET 2: Customer Segments  (N=400, 3 clusters)
# ================================================================
# Three customer types with known centroids:
#   Segment 0 "Budget Shoppers":    low spend, frequent, small basket, short loyalty
#   Segment 1 "Premium Loyalists":  high spend, frequent, large basket, long loyalty
#   Segment 2 "Whales":             very high spend, moderate freq, huge basket, medium loyalty

N2 = 400
cluster_sizes = [160, 140, 100]  # roughly balanced but not equal

# Cluster centroids: [annual_spend, visit_frequency_monthly, avg_basket_size, loyalty_years]
centroids = {
    0: [1200, 14, 22, 2.5],    # Budget
    1: [4500, 10, 55, 7.0],    # Premium
    2: [9500, 6, 120, 5.0],    # Whales
}

# Cluster covariance matrices (diagonal, different spreads)
covs = {
    0: np.diag([300**2, 4**2, 8**2, 1.5**2]),
    1: np.diag([800**2, 3**2, 15**2, 2.5**2]),
    2: np.diag([2000**2, 2**2, 35**2, 2.0**2]),
}

segments_list = []
for seg_id, size in enumerate(cluster_sizes):
    points = rng.multivariate_normal(centroids[seg_id], covs[seg_id], size)
    for p in points:
        segments_list.append({
            "annual_spend":          max(100, round(p[0], 0)),
            "visit_frequency_month": max(0.5, round(p[1], 1)),
            "avg_basket_size":       max(5, round(p[2], 1)),
            "loyalty_years":         max(0.1, round(p[3], 1)),
            "segment":               seg_id,
        })

df_segments = pd.DataFrame(segments_list)
df_segments = df_segments.sample(frac=1, random_state=42).reset_index(drop=True)

# Add segment labels for interpretability
seg_labels = {0: "Budget Shopper", 1: "Premium Loyalist", 2: "Whale"}
df_segments["segment_label"] = df_segments["segment"].map(seg_labels)

# ================================================================
# SAVE
# ================================================================
import os
outdir = "/workspace/pythonprogrammingproject event"
os.makedirs(outdir, exist_ok=True)

df_salary.to_csv(f"{outdir}/salary_data.csv", index=False)
df_messy.to_csv(f"{outdir}/salary_messy.csv", index=False)
df_segments.to_csv(f"{outdir}/customer_segments.csv", index=False)

print(f"salary_data.csv:      {len(df_salary)} rows, {len(df_salary.columns)} cols")
print(f"salary_messy.csv:      {len(df_messy)} rows, {len(df_messy.columns)} cols (with mess)")
print(f"customer_segments.csv: {len(df_segments)} rows, {len(df_segments.columns)} cols")
print(f"\nTrue DGP verification:")
print(f"  Salary mean: ${df_salary['salary'].mean():,.0f}")
print(f"  Salary SD:   ${df_salary['salary'].std():,.0f}")
print(f"  Segment counts: {df_segments['segment'].value_counts().to_dict()}")
