import pandas as pd
import sqlite3
from lifelines import KaplanMeierFitter
import matplotlib.pyplot as plt

# Load data dari SQLite
conn = sqlite3.connect(r'd:\kuli p\aokaok\port\port 4\bank_churn.db')  # sesuaikan path kamu
df = pd.read_sql_query('SELECT * FROM "Customer-Churn-Records"', conn)
conn.close()

# KM Overall
kmf = KaplanMeierFitter()
kmf.fit(durations=df['Tenure'], event_observed=df['Exited'], label='Overall')

plt.figure(figsize=(10, 6))
kmf.plot_survival_function()
plt.title('Kaplan-Meier Survival Curve — Overall')
plt.xlabel('Tenure (years)')
plt.ylabel('Survival Probability')
plt.grid(True, alpha=0.3)
plt.savefig('km_overall.png', dpi=150, bbox_inches='tight')
plt.show()

# KM by Geography
kmf_geo = KaplanMeierFitter()
plt.figure(figsize=(10, 6))
ax = plt.subplot(111)

for country in df['Geography'].unique():
    mask = df['Geography'] == country
    kmf_geo.fit(
        durations=df.loc[mask, 'Tenure'],
        event_observed=df.loc[mask, 'Exited'],
        label=country
    )
    kmf_geo.plot_survival_function(ax=ax)

plt.title('Kaplan-Meier Survival Curve by Geography')
plt.xlabel('Tenure (years)')
plt.ylabel('Survival Probability')
plt.grid(True, alpha=0.3)
plt.savefig('km_by_geography.png', dpi=150, bbox_inches='tight')
plt.show()

kmf_prod = KaplanMeierFitter()
plt.figure(figsize=(10, 6))
ax = plt.subplot(111)

for n in sorted(df['NumOfProducts'].unique()):
    mask = df['NumOfProducts'] == n
    kmf_prod.fit(
        durations=df.loc[mask, 'Tenure'],
        event_observed=df.loc[mask, 'Exited'],
        label=f'{n} product(s)'
    )
    kmf_prod.plot_survival_function(ax=ax)

plt.title('Kaplan-Meier Survival Curve by NumOfProducts')
plt.xlabel('Tenure (years)')
plt.ylabel('Survival Probability')
plt.grid(True, alpha=0.3)
plt.savefig('km_by_numproducts.png', dpi=150, bbox_inches='tight')
plt.show()

from lifelines import CoxPHFitter

# Siapkan data — pilih kolom relevan, buang yang leakage/identifier
cox_df = df[['Tenure', 'Exited', 'CreditScore', 'Geography', 'Gender', 
             'Age', 'Balance', 'NumOfProducts', 'HasCrCard', 
             'IsActiveMember', 'EstimatedSalary']].copy()

# One-hot encoding untuk kategorikal
cox_df = pd.get_dummies(cox_df, columns=['Geography', 'Gender', 'NumOfProducts'], 
                         drop_first=True, dtype=int)

# Fit Cox model
cph = CoxPHFitter()
cph.fit(cox_df, duration_col='Tenure', event_col='Exited')

cph.print_summary()

plt.figure(figsize=(9, 6))
cph.plot()
plt.title('Cox Proportional Hazards — Hazard Ratios')
plt.tight_layout()
plt.savefig('cox_forest_plot.png', dpi=150, bbox_inches='tight')
plt.show()