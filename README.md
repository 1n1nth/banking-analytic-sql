# 🏦 Banking Analytics System — Advanced SQL Portfolio Project

A production-grade relational database for a multi-branch, multi-currency retail & commercial bank.  
Designed to demonstrate **advanced SQL engineering** across schema design, complex analytics, fraud detection, and performance optimisation.

---

## 📁 Project Structure

```
banking_sql/
├── schema/
│   └── 01_schema.sql          # Full DDL — tables, constraints, indexes, triggers
├── data/
│   └── 02_seed_data.sql       # Realistic seed data (20 customers, accounts, loans, transactions)
├── queries/
│   ├── 03_advanced_queries.sql # 10 query showcases (window functions, recursion, pivots…)
│   └── 04_views_and_functions.sql # Views, stored procedures, PL/pgSQL functions
└── README.md
```

---

## 🗄️ Schema Overview

### Entity Relationship Summary

```
countries ──< customers >──── customer_addresses
                │
                ├──< accounts >──── transactions (partitioned)
                │        │               │
                │         └──── interest_accruals
                │
                ├──< loans >──── loan_payments
                │        └── loan_products
                │
employees >── branches
    │
    └── [manager_id → self-referential hierarchy]

fraud_alerts ──── fraud_rules
audit_log   ──── (trigger-populated from accounts, loans)
```

### Key Design Decisions

| Feature | Implementation | Skill Demonstrated |
|---|---|---|
| **Partitioned table** | `transactions` partitioned by year (RANGE) | Performance-oriented DDL |
| **Generated columns** | `full_name`, `maturity_date`, `days_late`, `is_active` | Computed/virtual columns |
| **Self-referential FK** | `employees.manager_id → employees.employee_id` | Hierarchical data modelling |
| **Check constraints** | Age ≥18, balance ≥ -overdraft, score ranges | Data integrity enforcement |
| **Audit trigger** | PL/pgSQL function auto-logs all DML to `audit_log` | Trigger-based auditing |
| **UUID primary keys** | All core entities use UUID | Distributed-system readiness |
| **Temporal validity** | `valid_from/valid_to` on addresses | SCD Type 2 pattern |

---

## 🚀 Getting Started

### Prerequisites

- **PostgreSQL 14+** (uses generated columns, RANGE partitioning, `uuid-ossp`)
- `psql` CLI or any PostgreSQL client (DBeaver, DataGrip, pgAdmin)

### Setup

```bash
# 1. Create a fresh database
createdb banking_analytics

# 2. Run in order
psql -d banking_analytics -f schema/01_schema.sql
psql -d banking_analytics -f data/02_seed_data.sql
psql -d banking_analytics -f queries/03_advanced_queries.sql
psql -d banking_analytics -f queries/04_views_and_functions.sql
```

---

## 🧠 SQL Techniques Showcased

### §1 — Window Functions (Running Totals & Velocity Detection)
**File:** `03_advanced_queries.sql` → Lines 18–90

```sql
-- Running balance with 30-day moving average
SUM(amount) OVER (PARTITION BY account_id ORDER BY created_at
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- Month-over-month velocity with LAG()
LAG(total_volume, 1) OVER (PARTITION BY customer_id ORDER BY month)
```
**Concepts:** `SUM/AVG OVER`, `LAG`, `PARTITION BY`, `ROWS` vs `RANGE` frames, data quality assertions

---

### §2 — Recursive CTEs
**File:** `03_advanced_queries.sql` → Lines 95–175

```sql
-- Full org chart traversal with depth tracking
WITH RECURSIVE org_tree AS (
    SELECT ..., 0 AS depth, ARRAY[employee_id] AS path
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.*, ot.depth + 1, ot.path || e.employee_id
    FROM employees e JOIN org_tree ot ON ot.employee_id = e.manager_id
)
```
**Also:** Full loan amortization schedule generated recursively using the PMT formula.  
**Concepts:** Anchor + recursive member, cycle prevention via `path` arrays, depth limiting

---

### §3 — Customer 360 Analytical CTE
**File:** `03_advanced_queries.sql` → Lines 180–280

Aggregates 6 independent CTEs (accounts, loans, payments, fraud, recency) with a composite health score computed inline.  
**Concepts:** CTE chaining, `COALESCE` for null-safe aggregation, computed composite scores, `BOOL_OR`, `STRING_AGG`

---

### §4 — Fraud Pattern Detection
**File:** `03_advanced_queries.sql` → Lines 285–360

```sql
-- Structuring (smurfing): 3+ sub-$2k ATM deposits in 24 hours
COUNT(*) OVER (PARTITION BY account_id ORDER BY created_at
               RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW)

-- Layering: large deposit immediately followed by ~full withdrawal
LEAD(transaction_type) OVER (PARTITION BY account_id ORDER BY created_at)
```
**Concepts:** `RANGE BETWEEN INTERVAL` frames, `LEAD`, time-based pattern matching, compliance output (`CTR_REQUIRED` / `SAR_REVIEW`)

---

### §5 — Conditional Aggregation Pivot
**File:** `03_advanced_queries.sql` → Lines 365–405

```sql
SUM(amount) FILTER (WHERE channel = 'ONLINE')  AS online_deposits,
SUM(amount) FILTER (WHERE channel = 'MOBILE')  AS mobile_deposits,
```
**Concepts:** `FILTER` clause (cleaner than `CASE WHEN`), multi-dimension pivoting without `crosstab` extension

---

### §6 — Materialized View with Refresh Strategy
**File:** `03_advanced_queries.sql` → Lines 410–450

Pre-aggregated monthly customer summary with month-over-month growth, designed for concurrent refresh.  
**Concepts:** `CREATE MATERIALIZED VIEW`, `CREATE UNIQUE INDEX` for `CONCURRENTLY`, refresh strategy

---

### §7 — Gap Analysis with GENERATE_SERIES
**File:** `03_advanced_queries.sql` → Lines 455–500

```sql
-- Generate every expected payment month, then LEFT JOIN to find gaps
CROSS JOIN LATERAL GENERATE_SERIES(
    disbursement_date + INTERVAL '1 month',
    LEAST(maturity_date, CURRENT_DATE),
    INTERVAL '1 month'
) AS gs(payment_month)
```
**Concepts:** `GENERATE_SERIES`, `LATERAL` joins, gap detection via anti-join pattern

---

### §8 — Stored Procedure: Atomic Fund Transfer
**File:** `03_advanced_queries.sql` → Lines 505–590

Full ACID transfer with deadlock prevention, overdraft validation, currency matching, paired ledger entries.
```sql
-- Lock in consistent UUID order to prevent deadlock
FOR UPDATE WHERE account_id = LEAST(p_from, p_to)
```
**Concepts:** `LANGUAGE plpgsql`, `FOR UPDATE` locking, `RAISE EXCEPTION`, atomicity, `COMMIT`

---

### §9 — GROUPING SETS Portfolio Rollup
**File:** `03_advanced_queries.sql` → Lines 595–640

```sql
GROUP BY GROUPING SETS (
    (country, branch),   -- branch-level rows
    (country),           -- country subtotals
    ()                   -- grand total
)
```
**Concepts:** `GROUPING SETS`, `ROLLUP`, single-pass multi-level aggregation, `GROUPING()` function

---

### §10 — Temporal Queries & Rate Sensitivity
**File:** `03_advanced_queries.sql` → Lines 645–710

Point-in-time balance reconstruction + interest rate stress testing (±1% rate shift impact on monthly payments and lifetime interest).  
**Concepts:** Point-in-time queries, financial mathematics in SQL, scenario analysis

---

## 📊 Views Reference

| View | Purpose |
|---|---|
| `vw_active_accounts` | Denormalised account + customer + branch info |
| `vw_loan_portfolio` | Loan health with elapsed/remaining months |
| `vw_fraud_watchlist` | Open/investigating alerts with escalation recommendations |
| `mv_customer_monthly_summary` | Materialised monthly stats with MoM growth |

## ⚙️ Functions Reference

| Function / Procedure | Returns | Purpose |
|---|---|---|
| `fn_credit_score(customer_id)` | TABLE | Weighted credit score 300–850 with explanations |
| `fn_account_statement(account_id, from, to)` | TABLE | Bank statement with debit/credit columns |
| `fn_accrue_daily_interest(date)` | INT | Inserts daily accruals for all eligible accounts |
| `sp_transfer_funds(from, to, amount, ...)` | VOID | Atomic double-entry fund transfer |
| `fn_audit_trigger()` | TRIGGER | Auto-logs all DML to `audit_log` as JSONB |

---

## 💡 Interview Talking Points

- **Partitioning strategy:** Transactions table is range-partitioned by year. Queries against recent data (most common) hit only one partition — explain `EXPLAIN ANALYZE` partition pruning.
- **Deadlock prevention:** Transfer procedure always acquires locks in `LEAST(uuid_a, uuid_b)` order, ensuring a consistent global lock ordering regardless of call direction.
- **Structuring detection:** The `RANGE BETWEEN INTERVAL` frame is more semantically correct than `ROWS` for time-based fraud windows — it handles ties naturally.
- **GROUPING SETS vs UNION ALL:** A single `GROUPING SETS` pass is typically 3–5× faster than three separate `UNION ALL` queries on large tables because it scans the base table only once.
- **Materialised view refresh:** The `UNIQUE INDEX` on `(customer_id, month)` is required for `REFRESH MATERIALIZED VIEW CONCURRENTLY`, which avoids locking the view during refresh in production.

---

## 📝 License

MIT — free to use, adapt, or extend for portfolio or production purposes.
