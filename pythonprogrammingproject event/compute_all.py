import pandas as pd, numpy as np, json, warnings
import statsmodels.formula.api as smf
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
warnings.filterwarnings('ignore')

out = {}

# ==================== TIDYING ====================
df_messy = pd.read_csv("/workspace/pythonprogrammingproject event/salary_messy.csv")
out['messy_rows'] = len(df_messy)
out['messy_colnames'] = list(df_messy.columns)
out['messy_head_str'] = df_messy.head(5).to_string()
out['messy_info_str'] = str(df_messy.dtypes)

n_missing = int(df_messy['Annual Salary ($)'].isna().sum())
out['n_missing'] = n_missing

# Manual rename (clean, readable names — as shown in slides)
df = df_messy.copy()
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
out['clean_colnames'] = list(df.columns)

# Drop missing
df = df.dropna(subset=['salary'])
out['after_dropna'] = len(df)

# Drop duplicates
before = len(df)
df = df.drop_duplicates()
out['dupes_removed'] = before - len(df)
out['after_dedup'] = len(df)

# Outlier
q99 = float(df['salary'].quantile(0.99))
mask = df['salary'] > q99 * 3
out['n_outliers'] = int(mask.sum())
out['outlier_salary'] = float(df.loc[mask, 'salary'].iloc[0])
out['q99_salary'] = q99
df = df[~mask]

# Split dept_code
df[['dept_abbr', 'dept_rest']] = df['dept_code'].str.split(':::', expand=True)
df = df.drop(columns=['dept_code', 'dept_rest', 'edu_code'])
out['final_rows'] = len(df)
out['final_cols'] = len(df.columns)

df.to_csv("/workspace/pythonprogrammingproject event/salary_clean.csv", index=False)

out['salary_mean'] = round(float(df['salary'].mean()), 0)
out['salary_std'] = round(float(df['salary'].std()), 0)
out['salary_min'] = round(float(df['salary'].min()), 0)
out['salary_max'] = round(float(df['salary'].max()), 0)
out['exp_mean'] = round(float(df['experience'].mean()), 1)
out['hours_mean'] = round(float(df['hours'].mean()), 1)
out['mgr_pct'] = round(float(df['is_manager'].mean() * 100), 1)
out['edu_counts'] = {str(k): int(v) for k, v in df['education'].value_counts().items()}

# ==================== GROUPING ====================
df_seg = pd.read_csv("/workspace/pythonprogrammingproject event/customer_segments.csv")
out['seg_rows'] = len(df_seg)

gb = df_seg.groupby('segment_label')[['annual_spend','visit_frequency_month','avg_basket_size','loyalty_years']].mean().round(1)
out['gb_spend'] = {str(k): float(v) for k, v in gb['annual_spend'].items()}
out['gb_visits'] = {str(k): float(v) for k, v in gb['visit_frequency_month'].items()}
out['gb_basket'] = {str(k): float(v) for k, v in gb['avg_basket_size'].items()}
out['gb_loyalty'] = {str(k): float(v) for k, v in gb['loyalty_years'].items()}

X = df_seg[['annual_spend','visit_frequency_month','avg_basket_size','loyalty_years']]
X_scaled = StandardScaler().fit_transform(X)
km = KMeans(n_clusters=3, random_state=42, n_init=10)
clusters = km.fit_predict(X_scaled)
ct = pd.crosstab(df_seg['segment_label'], clusters)
out['ct_budget'] = [int(x) for x in ct.loc['Budget Shopper']]
out['ct_premium'] = [int(x) for x in ct.loc['Premium Loyalist']]
out['ct_whale'] = [int(x) for x in ct.loc['Whale']]

inertias = [round(float(KMeans(n_clusters=k, random_state=42, n_init=10).fit(X_scaled).inertia_), 0) for k in range(1, 9)]
out['inertias'] = inertias

X_tr, X_te, y_tr, y_te = train_test_split(X_scaled, df_seg['segment'], test_size=0.3, random_state=42)
clf = LogisticRegression(max_iter=1000).fit(X_tr, y_tr)
out['logreg_acc'] = round(float(clf.score(X_te, y_te)) * 100, 1)

# ==================== PREDICTION ====================
df_sal = pd.read_csv("/workspace/pythonprogrammingproject event/salary_clean.csv")
out['corr_exp'] = round(float(df_sal['experience'].corr(df_sal['salary'])), 3)

m1 = smf.ols('salary ~ experience', data=df_sal).fit()
out['m1_r2'] = round(float(m1.rsquared), 3)
out['m1_coef_exp'] = round(float(m1.params['experience']), 0)
out['m1_se_exp'] = round(float(m1.bse['experience']), 1)
out['m1_t_exp'] = round(float(m1.tvalues['experience']), 1)
out['m1_p_exp'] = float(m1.pvalues['experience'])
out['m1_ci_low'] = round(float(m1.conf_int().loc['experience', 0]), 0)
out['m1_ci_high'] = round(float(m1.conf_int().loc['experience', 1]), 0)

m2 = smf.ols('salary ~ experience + education + is_manager + hours', data=df_sal).fit()
out['m2_r2'] = round(float(m2.rsquared), 3)
out['m2_terms'] = {}
for var in m2.params.index:
    out['m2_terms'][var] = {'coef': round(float(m2.params[var]), 0), 't': round(float(m2.tvalues[var]), 1), 'p': float(m2.pvalues[var])}

m3 = smf.ols('salary ~ experience + education + is_manager + hours + C(department)', data=df_sal).fit()
out['m3_r2'] = round(float(m3.rsquared), 3)
out['m3_terms'] = {}
for var in m3.params.index:
    out['m3_terms'][var] = {'coef': round(float(m3.params[var]), 0), 't': round(float(m3.tvalues[var]), 1), 'p': float(m3.pvalues[var])}

with open("/workspace/pythonprogrammingproject event/computed_values.json", "w") as f:
    json.dump(out, f, indent=2, default=str)

print("Done computing all values.")
