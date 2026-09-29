# Global Sales Analytics

SQL + SQLite + Excel dashboard for global sales performance analysis. This is a portfolio project built with generated, realistic-looking data for demonstration and practice.

## What is included

- `global_superstore_data.csv` — sales dataset
- `global_superstore.db` — ready-to-query SQLite database
- `analises_sql.sql` — analytical queries
- `Global_Sales_Dashboard.xlsx` — Excel dashboard

## Skills demonstrated

Window functions, CTEs, moving averages, Pareto analysis, year-over-year growth and quarterly aggregation.

## Quick start

1. Open `Global_Sales_Dashboard.xlsx` in Excel.
2. Open `global_superstore.db` in DB Browser for SQLite.
3. Run the examples in `analises_sql.sql`.

> Portfolio note: the dataset is generated for analytics demonstrations; it is not a live commercial data source.

## Verificação

```bash
python checks/check_artifacts.py            # confere os artefatos contra o baseline
python checks/check_artifacts.py --update   # regrava o baseline após mudar os dados
```

O baseline em `checks/expected.json` é versionado: se um CSV esvaziar, um banco perder tabela ou uma aba do dashboard desaparecer, a checagem falha. Roda no CI a cada push.
