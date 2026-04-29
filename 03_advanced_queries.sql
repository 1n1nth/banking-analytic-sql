-- ============================================================
--  BANKING ANALYTICS SYSTEM — ADVANCED QUERY SHOWCASE
--  Each section demonstrates a distinct advanced SQL concept
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- §1  WINDOW FUNCTIONS — Running Totals & Moving Averages
--     Shows: SUM/AVG OVER, PARTITION BY, ORDER BY, frame spec
-- ════════════════════════════════════════════════════════════

-- 1a. Running balance reconstruction with 30-day moving average
-- Verifies that stored balance matches computed running total
WITH ordered_txns AS (
    SELECT
        t.transaction_id,
        t.account_id,
        a.account_number,
        t.created_at::DATE                          AS txn_date,
        t.transaction_type,
        t.amount,
        t.balance_after                             AS stored_balance,

        -- Cumulative running sum from first transaction
        SUM(CASE
                WHEN t.transaction_type IN ('DEPOSIT','TRANSFER_IN','INTEREST') THEN  t.amount
                ELSE -t.amount
            END)
            OVER (PARTITION BY t.account_id ORDER BY t.created_at
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                    AS computed_running_balance,

        -- 30-day moving average transaction amount
        AVG(t.amount)
            OVER (PARTITION BY t.account_id ORDER BY t.created_at
                  RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW)
                                                    AS moving_avg_30d,

        -- Percentage of monthly account volume
        t.amount * 100.0 /
            NULLIF(SUM(t.amount)
                   OVER (PARTITION BY t.account_id,
                                      DATE_TRUNC('month', t.created_at)),0)
                                                    AS pct_of_month_volume

    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.status = 'POSTED'
)
SELECT
    account_number,
    txn_date,
    transaction_type,
    amount,
    stored_balance,
    computed_running_balance,
    ROUND(moving_avg_30d, 2)                        AS moving_avg_30d,
    ROUND(pct_of_month_volume, 2)                   AS pct_of_month_volume,
    -- Data quality flag
    CASE WHEN ABS(stored_balance - computed_running_balance) > 0.01
         THEN 'MISMATCH' ELSE 'OK' END              AS balance_integrity
FROM ordered_txns
ORDER BY account_number, txn_date;


-- 1b. Customer transaction velocity — detect unusual spikes
--     Uses LAG to compare current month vs prior month
WITH monthly_stats AS (
    SELECT
        c.customer_id,
        c.full_name,
        DATE_TRUNC('month', t.created_at)           AS month,
        COUNT(*)                                    AS txn_count,
        SUM(t.amount)                               AS total_volume,
        AVG(t.amount)                               AS avg_amount,
        MAX(t.amount)                               AS max_amount
    FROM transactions t
    JOIN accounts a  ON a.account_id  = t.account_id
    JOIN customers c ON c.customer_id = a.customer_id
    WHERE t.status = 'POSTED'
    GROUP BY 1,2,3
),
with_lag AS (
    SELECT *,
        LAG(txn_count,  1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_txn_count,
        LAG(total_volume,1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_volume,
        -- 3-month rolling average for baseline
        AVG(total_volume)
            OVER (PARTITION BY customer_id ORDER BY month
                  ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)                AS baseline_3m_avg
    FROM monthly_stats
)
SELECT
    full_name,
    TO_CHAR(month,'YYYY-MM')                        AS month,
    txn_count,
    prev_txn_count,
    ROUND(total_volume,2)                           AS volume,
    ROUND(prev_volume,2)                            AS prev_volume,
    ROUND(baseline_3m_avg,2)                        AS baseline_3m_avg,
    ROUND((total_volume / NULLIF(baseline_3m_avg,0) - 1)*100, 1)
                                                    AS pct_vs_baseline,
    CASE WHEN total_volume > baseline_3m_avg * 3
         THEN '⚠ SPIKE DETECTED' ELSE 'Normal' END  AS velocity_flag
FROM with_lag
WHERE month >= '2023-01-01'
ORDER BY pct_vs_baseline DESC NULLS LAST;


-- ════════════════════════════════════════════════════════════
-- §2  RECURSIVE CTE — Org Chart & Loan Amortization Schedule
-- ════════════════════════════════════════════════════════════

-- 2a. Employee management hierarchy (recursive tree walk)
WITH RECURSIVE org_tree AS (
    -- Anchor: top-level employees (no manager)
    SELECT
        employee_id,
        first_name || ' ' || last_name              AS employee_name,
        job_title,
        manager_id,
        base_salary,
        0                                           AS depth,
        ARRAY[employee_id]                          AS path,
        first_name || ' ' || last_name              AS breadcrumb
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.job_title,
        e.manager_id,
        e.base_salary,
        ot.depth + 1,
        ot.path || e.employee_id,
        ot.breadcrumb || ' → ' || e.first_name || ' ' || e.last_name
    FROM employees e
    JOIN org_tree ot ON ot.employee_id = e.manager_id
)
SELECT
    REPEAT('    ', depth) || employee_name          AS org_chart,
    job_title,
    depth                                           AS level,
    base_salary,
    -- Total salary burden for each manager's subtree
    SUM(base_salary) OVER (
        PARTITION BY path[1]                        -- group by root ancestor
        ORDER BY path
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                               AS cumulative_subtree_salary,
    breadcrumb
FROM org_tree
ORDER BY path;


-- 2b. Generate full loan amortization schedule (recursive)
WITH RECURSIVE amortization AS (
    -- Anchor: loan details at origination
    SELECT
        l.loan_id,
        l.principal                                 AS remaining_balance,
        l.interest_rate / 12                        AS monthly_rate,
        l.term_months,
        1                                           AS payment_num,
        l.disbursement_date + INTERVAL '1 month'    AS payment_date,
        -- Monthly payment (PMT formula)
        ROUND(
            l.principal *
            (l.interest_rate/12) /
            (1 - POWER(1 + l.interest_rate/12, -l.term_months))
        , 2)                                        AS monthly_payment
    FROM loans l
    WHERE l.loan_id = 'c1000000-0000-0000-0000-000000000002'   -- Ben Torres personal loan

    UNION ALL

    SELECT
        a.loan_id,
        ROUND(a.remaining_balance
              - (a.monthly_payment - ROUND(a.remaining_balance * a.monthly_rate, 2))
             ,2),
        a.monthly_rate,
        a.term_months,
        a.payment_num + 1,
        a.payment_date + INTERVAL '1 month',
        a.monthly_payment
    FROM amortization a
    WHERE a.payment_num < a.term_months
      AND a.remaining_balance > 0
)
SELECT
    payment_num,
    payment_date::DATE,
    monthly_payment,
    ROUND(remaining_balance * monthly_rate, 2)      AS interest_portion,
    ROUND(monthly_payment
          - (remaining_balance * monthly_rate), 2)  AS principal_portion,
    remaining_balance                               AS balance_before,
    ROUND(remaining_balance
          - (monthly_payment - remaining_balance * monthly_rate)
         ,2)                                        AS balance_after,
    -- Cumulative interest paid so far
    SUM(ROUND(remaining_balance * monthly_rate, 2))
        OVER (ORDER BY payment_num
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                    AS cumulative_interest_paid,
    payment_num * 100.0 / term_months              AS pct_complete
FROM amortization
ORDER BY payment_num;


-- ════════════════════════════════════════════════════════════
-- §3  ANALYTICAL / REPORTING CTEs — Customer 360 & Scoring
-- ════════════════════════════════════════════════════════════

-- 3a. Full Customer 360 View
--     Aggregates accounts, loans, transactions, alerts into one row
WITH account_summary AS (
    SELECT
        a.customer_id,
        COUNT(*)                                    AS num_accounts,
        SUM(a.balance)                              AS total_balance,
        MAX(a.balance)                              AS max_single_balance,
        STRING_AGG(DISTINCT at2.type_code, ', '
                   ORDER BY at2.type_code)          AS product_mix,
        BOOL_OR(a.status = 'FROZEN')                AS has_frozen_account
    FROM accounts a
    JOIN account_types at2 ON at2.type_id = a.type_id
    GROUP BY a.customer_id
),
loan_summary AS (
    SELECT
        l.customer_id,
        COUNT(*) FILTER (WHERE l.status = 'ACTIVE')         AS active_loans,
        COUNT(*) FILTER (WHERE l.status = 'DEFAULTED')      AS defaulted_loans,
        SUM(l.outstanding_balance) FILTER (WHERE l.status='ACTIVE')
                                                            AS total_debt,
        SUM(l.principal)                                    AS total_borrowed_lifetime
    FROM loans l
    GROUP BY l.customer_id
),
payment_behaviour AS (
    SELECT
        l.customer_id,
        COUNT(*)                                            AS total_payments_due,
        COUNT(*) FILTER (WHERE lp.status = 'PAID'
                         AND lp.days_late IS NULL)          AS on_time_payments,
        COUNT(*) FILTER (WHERE lp.days_late > 0)            AS late_payments,
        MAX(lp.days_late)                                   AS worst_delay_days,
        AVG(lp.days_late)                                   AS avg_delay_days
    FROM loan_payments lp
    JOIN loans l ON l.loan_id = lp.loan_id
    GROUP BY l.customer_id
),
fraud_summary AS (
    SELECT
        a.customer_id,
        COUNT(fa.alert_id)                                  AS total_fraud_alerts,
        COUNT(fa.alert_id) FILTER (WHERE fa.status='OPEN')  AS open_alerts,
        MAX(fa.alert_score)                                 AS max_alert_score
    FROM fraud_alerts fa
    JOIN accounts a ON a.account_id = fa.account_id
    GROUP BY a.customer_id
),
txn_recency AS (
    SELECT DISTINCT ON (a.customer_id)
        a.customer_id,
        t.created_at                                        AS last_txn_at,
        NOW() - t.created_at                                AS days_since_last_txn
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.status = 'POSTED'
    ORDER BY a.customer_id, t.created_at DESC
)
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    rc.risk_name                                    AS risk_tier,
    co.country_name,
    EXTRACT(YEAR FROM AGE(c.date_of_birth))         AS age,
    c.kyc_verified,

    -- Account portfolio
    COALESCE(acs.num_accounts, 0)                   AS num_accounts,
    COALESCE(acs.total_balance, 0)                  AS total_deposits,
    acs.product_mix,
    acs.has_frozen_account,

    -- Loan exposure
    COALESCE(ls.active_loans, 0)                    AS active_loans,
    COALESCE(ls.defaulted_loans, 0)                 AS defaulted_loans,
    COALESCE(ls.total_debt, 0)                      AS total_outstanding_debt,

    -- Debt-to-deposit ratio
    CASE WHEN acs.total_balance > 0
         THEN ROUND(ls.total_debt / acs.total_balance, 3) END
                                                    AS debt_to_deposit_ratio,

    -- Payment behaviour
    COALESCE(pb.on_time_payments, 0)                AS on_time_payments,
    COALESCE(pb.late_payments, 0)                   AS late_payments,
    pb.worst_delay_days,

    -- Fraud signals
    COALESCE(fs.total_fraud_alerts, 0)              AS fraud_alerts,
    COALESCE(fs.open_alerts, 0)                     AS open_alerts,
    fs.max_alert_score,

    -- Recency
    tr.last_txn_at::DATE                            AS last_transaction_date,

    -- Composite health score (0-100)
    GREATEST(0, LEAST(100,
        50                                          -- base score
        + CASE WHEN c.kyc_verified THEN 10 ELSE -20 END
        + CASE rc.risk_name
            WHEN 'LOW'      THEN 15
            WHEN 'MEDIUM'   THEN  5
            WHEN 'HIGH'     THEN -10
            ELSE                 -25 END
        - COALESCE(pb.late_payments, 0) * 3
        - COALESCE(ls.defaulted_loans, 0) * 20
        - COALESCE(fs.open_alerts, 0) * 8
        + CASE WHEN acs.total_balance > 50000 THEN 10
               WHEN acs.total_balance > 10000 THEN  5 ELSE 0 END
    ))                                              AS health_score

FROM customers c
JOIN countries         co  ON co.country_code  = c.country_code
JOIN risk_categories   rc  ON rc.risk_id       = c.risk_id
LEFT JOIN account_summary   acs ON acs.customer_id = c.customer_id
LEFT JOIN loan_summary       ls ON  ls.customer_id = c.customer_id
LEFT JOIN payment_behaviour  pb ON  pb.customer_id = c.customer_id
LEFT JOIN fraud_summary      fs ON  fs.customer_id = c.customer_id
LEFT JOIN txn_recency        tr ON  tr.customer_id = c.customer_id
ORDER BY health_score DESC;


-- ════════════════════════════════════════════════════════════
-- §4  FRAUD DETECTION — Pattern Matching with Window Functions
-- ════════════════════════════════════════════════════════════

-- 4a. Structuring detection: 3+ cash deposits under $2k within 24hrs
--     (Classic structuring / smurfing pattern)
WITH cash_deposits AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.amount,
        t.created_at,
        -- Count deposits in preceding 24-hour window
        COUNT(*) OVER (
            PARTITION BY t.account_id
            ORDER BY t.created_at
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        )                                           AS deposits_in_24h,
        SUM(t.amount) OVER (
            PARTITION BY t.account_id
            ORDER BY t.created_at
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        )                                           AS volume_in_24h,
        MIN(t.created_at) OVER (
            PARTITION BY t.account_id
            ORDER BY t.created_at
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        )                                           AS window_start
    FROM transactions t
    WHERE t.transaction_type = 'DEPOSIT'
      AND t.amount < 2000
      AND t.channel = 'ATM'
      AND t.status  = 'POSTED'
),
flagged AS (
    SELECT DISTINCT account_id, window_start, deposits_in_24h, volume_in_24h
    FROM cash_deposits
    WHERE deposits_in_24h >= 3
)
SELECT
    c.full_name,
    a.account_number,
    rc.risk_name,
    f.window_start::TIMESTAMP,
    f.deposits_in_24h,
    ROUND(f.volume_in_24h, 2)                       AS total_deposited_24h,
    'STRUCTURING_PATTERN'                           AS alert_type,
    CASE WHEN f.volume_in_24h > 9000 THEN 'CTR_REQUIRED' ELSE 'SAR_REVIEW' END
                                                    AS compliance_action
FROM flagged f
JOIN accounts    a  ON a.account_id  = f.account_id
JOIN customers   c  ON c.customer_id = a.customer_id
JOIN risk_categories rc ON rc.risk_id = c.risk_id
ORDER BY f.volume_in_24h DESC;


-- 4b. Layering detection: quick large deposit followed by near-full withdrawal
WITH deposit_withdrawal_pairs AS (
    SELECT
        t.account_id,
        t.transaction_id,
        t.amount,
        t.transaction_type,
        t.created_at,
        LEAD(t.transaction_type) OVER (
            PARTITION BY t.account_id ORDER BY t.created_at
        )                                           AS next_type,
        LEAD(t.amount) OVER (
            PARTITION BY t.account_id ORDER BY t.created_at
        )                                           AS next_amount,
        LEAD(t.created_at) OVER (
            PARTITION BY t.account_id ORDER BY t.created_at
        )                                           AS next_txn_time
    FROM transactions t
    WHERE t.status = 'POSTED'
)
SELECT
    c.full_name,
    a.account_number,
    dwp.amount                                      AS deposit_amount,
    dwp.next_amount                                 AS withdrawal_amount,
    ROUND(dwp.next_amount / dwp.amount * 100, 1)    AS withdrawal_pct_of_deposit,
    dwp.created_at                                  AS deposit_time,
    dwp.next_txn_time                               AS withdrawal_time,
    EXTRACT(EPOCH FROM (dwp.next_txn_time - dwp.created_at))/60
                                                    AS minutes_between,
    'LAYERING_PATTERN'                              AS alert_type
FROM deposit_withdrawal_pairs dwp
JOIN accounts    a ON a.account_id  = dwp.account_id
JOIN customers   c ON c.customer_id = a.customer_id
WHERE dwp.transaction_type = 'DEPOSIT'
  AND dwp.next_type        = 'WITHDRAWAL'
  AND dwp.amount           > 5000
  AND dwp.next_amount      >= dwp.amount * 0.85     -- ≥85% withdrawn
  AND dwp.next_txn_time - dwp.created_at <= INTERVAL '2 hours'
ORDER BY dwp.amount DESC;


-- ════════════════════════════════════════════════════════════
-- §5  PIVOTING / CROSSTAB — Monthly P&L by Branch & Currency
-- ════════════════════════════════════════════════════════════

-- 5a. Conditional aggregation pivot: monthly revenue by channel
SELECT
    DATE_TRUNC('month', t.created_at)::DATE         AS month,
    b.branch_name,

    -- Deposits by channel (revenue proxy)
    SUM(t.amount) FILTER (WHERE t.transaction_type='DEPOSIT'
                             AND t.channel='ONLINE')    AS online_deposits,
    SUM(t.amount) FILTER (WHERE t.transaction_type='DEPOSIT'
                             AND t.channel='MOBILE')    AS mobile_deposits,
    SUM(t.amount) FILTER (WHERE t.transaction_type='DEPOSIT'
                             AND t.channel='ATM')       AS atm_deposits,
    SUM(t.amount) FILTER (WHERE t.transaction_type='DEPOSIT'
                             AND t.channel='BRANCH')    AS branch_deposits,

    -- Fee income
    SUM(t.amount) FILTER (WHERE t.transaction_type='FEE') AS fee_income,

    -- Outflows
    SUM(t.amount) FILTER (WHERE t.transaction_type IN
                              ('WITHDRAWAL','TRANSFER_OUT'))  AS total_outflows,

    -- Net position
    SUM(CASE WHEN t.transaction_type IN ('DEPOSIT','TRANSFER_IN','INTEREST','FEE')
             THEN t.amount ELSE -t.amount END)           AS net_flow,

    COUNT(DISTINCT a.customer_id)                       AS active_customers,
    COUNT(*)                                            AS total_transactions

FROM transactions t
JOIN accounts a  ON a.account_id = t.account_id
JOIN branches b  ON b.branch_id  = a.branch_id
WHERE t.status = 'POSTED'
GROUP BY 1, 2
ORDER BY 1, 2;


-- ════════════════════════════════════════════════════════════
-- §6  MATERIALIZED VIEW + REFRESH STRATEGY
--     Demonstrates performance-oriented design
-- ════════════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW mv_customer_monthly_summary AS
WITH base AS (
    SELECT
        a.customer_id,
        DATE_TRUNC('month', t.created_at)           AS month,
        COUNT(*)                                    AS txn_count,
        SUM(CASE WHEN t.transaction_type IN ('DEPOSIT','TRANSFER_IN','INTEREST')
                 THEN t.amount ELSE 0 END)          AS total_credits,
        SUM(CASE WHEN t.transaction_type NOT IN ('DEPOSIT','TRANSFER_IN','INTEREST')
                 THEN t.amount ELSE 0 END)          AS total_debits,
        COUNT(DISTINCT t.channel)                   AS channels_used,
        MAX(t.amount)                               AS largest_txn,
        AVG(t.amount)                               AS avg_txn_amount
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.status = 'POSTED'
    GROUP BY 1, 2
)
SELECT
    b.*,
    b.total_credits - b.total_debits               AS net_flow,
    -- Month-over-month growth
    LAG(b.total_credits) OVER (
        PARTITION BY b.customer_id ORDER BY b.month)
                                                    AS prev_month_credits,
    ROUND(
        (b.total_credits /
         NULLIF(LAG(b.total_credits) OVER (
             PARTITION BY b.customer_id ORDER BY b.month), 0) - 1) * 100
    , 2)                                            AS mom_credit_growth_pct
FROM base b;

CREATE UNIQUE INDEX ON mv_customer_monthly_summary (customer_id, month);
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_monthly_summary;


-- ════════════════════════════════════════════════════════════
-- §7  GAP ANALYSIS — Detecting Missing Loan Payments
--     Uses GENERATE_SERIES to find gaps in expected schedule
-- ════════════════════════════════════════════════════════════

WITH expected_payments AS (
    -- Generate every expected payment month for each active loan
    SELECT
        l.loan_id,
        l.customer_id,
        gs.payment_month::DATE
    FROM loans l
    CROSS JOIN LATERAL GENERATE_SERIES(
        l.disbursement_date + INTERVAL '1 month',
        LEAST(l.maturity_date, CURRENT_DATE),
        INTERVAL '1 month'
    ) AS gs(payment_month)
    WHERE l.status = 'ACTIVE'
),
actual_payments AS (
    SELECT
        loan_id,
        DATE_TRUNC('month', due_date)::DATE         AS payment_month
    FROM loan_payments
    WHERE status IN ('PAID','PARTIAL')
)
SELECT
    c.full_name,
    l.loan_id,
    lp2.product_name,
    ep.payment_month,
    CASE WHEN ap.payment_month IS NULL THEN 'MISSING' ELSE 'RECEIVED' END
                                                    AS payment_status,
    CURRENT_DATE - ep.payment_month                 AS days_outstanding
FROM expected_payments ep
JOIN loans       l   ON l.loan_id   = ep.loan_id
JOIN customers   c   ON c.customer_id = l.customer_id
JOIN loan_products lp2 ON lp2.product_id = l.product_id
LEFT JOIN actual_payments ap
       ON ap.loan_id       = ep.loan_id
      AND ap.payment_month = ep.payment_month
WHERE ap.payment_month IS NULL                      -- Only show gaps
ORDER BY days_outstanding DESC, l.loan_id, ep.payment_month;


-- ════════════════════════════════════════════════════════════
-- §8  STORED PROCEDURE — Atomic Fund Transfer with Validation
-- ════════════════════════════════════════════════════════════

CREATE OR REPLACE PROCEDURE sp_transfer_funds(
    p_from_account_id   UUID,
    p_to_account_id     UUID,
    p_amount            NUMERIC(15,2),
    p_description       VARCHAR(255),
    p_initiated_by      INT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_from_balance      NUMERIC(15,2);
    v_to_balance        NUMERIC(15,2);
    v_from_currency     CHAR(3);
    v_to_currency       CHAR(3);
    v_from_status       VARCHAR(15);
    v_to_status         VARCHAR(15);
    v_overdraft_limit   NUMERIC(12,2);
    v_ref_id            UUID := uuid_generate_v4();
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be positive. Got: %', p_amount;
    END IF;

    -- Lock both rows in consistent order (lower UUID first) to prevent deadlock
    SELECT a.balance, a.available_balance, a.currency_code, a.status,
           at2.overdraft_limit
    INTO   v_from_balance, v_from_balance, v_from_currency, v_from_status,
           v_overdraft_limit
    FROM accounts a
    JOIN account_types at2 ON at2.type_id = a.type_id
    WHERE a.account_id = LEAST(p_from_account_id, p_to_account_id)
    FOR UPDATE;

    SELECT a.balance, a.currency_code, a.status
    INTO   v_to_balance, v_to_currency, v_to_status
    FROM accounts a
    WHERE a.account_id = GREATEST(p_from_account_id, p_to_account_id)
    FOR UPDATE;

    -- Validate account states
    IF v_from_status != 'ACTIVE' THEN
        RAISE EXCEPTION 'Source account is not active: %', v_from_status;
    END IF;
    IF v_to_status != 'ACTIVE' THEN
        RAISE EXCEPTION 'Destination account is not active: %', v_to_status;
    END IF;

    -- Re-fetch sender balance specifically
    SELECT balance, available_balance INTO v_from_balance, v_from_balance
    FROM accounts WHERE account_id = p_from_account_id FOR UPDATE;

    -- Sufficient funds check (respecting overdraft)
    IF v_from_balance - p_amount < -v_overdraft_limit THEN
        RAISE EXCEPTION 'Insufficient funds. Balance: %, Overdraft limit: %, Requested: %',
            v_from_balance, v_overdraft_limit, p_amount;
    END IF;

    -- Currency match
    IF v_from_currency != v_to_currency THEN
        RAISE EXCEPTION 'Currency mismatch: % vs %', v_from_currency, v_to_currency;
    END IF;

    -- Execute the debit
    UPDATE accounts
    SET    balance           = balance - p_amount,
           available_balance = available_balance - p_amount
    WHERE  account_id = p_from_account_id;

    -- Execute the credit
    UPDATE accounts
    SET    balance           = balance + p_amount,
           available_balance = available_balance + p_amount
    WHERE  account_id = p_to_account_id;

    -- Record TRANSFER_OUT leg
    INSERT INTO transactions
        (account_id, transaction_type, amount, currency_code, balance_after,
         description, reference_id, channel, initiated_by)
    VALUES
        (p_from_account_id, 'TRANSFER_OUT', p_amount, v_from_currency,
         v_from_balance - p_amount, p_description, v_ref_id, 'ONLINE', p_initiated_by);

    -- Record TRANSFER_IN leg
    INSERT INTO transactions
        (account_id, transaction_type, amount, currency_code, balance_after,
         description, reference_id, channel, initiated_by)
    VALUES
        (p_to_account_id, 'TRANSFER_IN', p_amount, v_to_currency,
         v_to_balance + p_amount, p_description, v_ref_id, 'ONLINE', p_initiated_by);

    COMMIT;
END;
$$;


-- ════════════════════════════════════════════════════════════
-- §9  PORTFOLIO RISK REPORT — Multi-level Rollup with GROUPING SETS
-- ════════════════════════════════════════════════════════════

-- Uses GROUPING SETS to produce branch → country → global subtotals
-- in a single pass — avoids multiple UNION ALL queries
SELECT
    COALESCE(co.country_name, '── GLOBAL TOTAL ──')    AS country,
    COALESCE(b.branch_name,
             CASE WHEN co.country_name IS NOT NULL
                  THEN '  ─ ' || co.country_name || ' SUBTOTAL'
                  ELSE NULL END)                        AS branch,
    COUNT(DISTINCT l.loan_id)                           AS loan_count,
    COUNT(DISTINCT l.customer_id)                       AS borrower_count,
    ROUND(SUM(l.principal), 0)                          AS total_originated,
    ROUND(SUM(l.outstanding_balance), 0)                AS total_outstanding,
    ROUND(SUM(l.outstanding_balance) / NULLIF(SUM(l.principal),0) * 100, 1)
                                                        AS utilisation_pct,
    COUNT(*) FILTER (WHERE l.status = 'DEFAULTED')      AS defaulted_count,
    ROUND(SUM(l.outstanding_balance)
          FILTER (WHERE l.status = 'DEFAULTED') / 
          NULLIF(SUM(l.outstanding_balance),0) * 100, 2)
                                                        AS default_rate_pct,
    ROUND(AVG(l.interest_rate)*100, 3)                  AS avg_interest_rate_pct,
    GROUPING(b.branch_id, co.country_code)              AS grouping_level
FROM loans l
JOIN branches      b  ON b.branch_id    = l.branch_id
JOIN countries     co ON co.country_code = b.country_code
GROUP BY GROUPING SETS (
    (co.country_name, co.country_code, b.branch_name, b.branch_id),  -- branch level
    (co.country_name, co.country_code),                               -- country level
    ()                                                                -- grand total
)
ORDER BY
    COALESCE(co.country_name,'ZZZZ'),
    grouping_level,
    b.branch_name NULLS LAST;


-- ════════════════════════════════════════════════════════════
-- §10 TEMPORAL / SCD — Slowly Changing Dimension for Rate History
-- ════════════════════════════════════════════════════════════

-- 10a. Point-in-time account balance reconstruction
--      "What was Alice's balance on 2023-03-15?"
WITH balance_at_date AS (
    SELECT
        t.account_id,
        t.balance_after,
        t.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY t.account_id
            ORDER BY t.created_at DESC
        )                                           AS rn
    FROM transactions t
    WHERE t.created_at <= '2023-03-15 23:59:59+00'
      AND t.account_id  = 'b1000000-0000-0000-0000-000000000001'
      AND t.status      = 'POSTED'
)
SELECT
    a.account_number,
    c.full_name,
    '2023-03-15'::DATE                              AS balance_as_of,
    bad.balance_after                               AS reconstructed_balance,
    bad.created_at                                  AS last_txn_before_date
FROM balance_at_date bad
JOIN accounts  a ON a.account_id  = bad.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE rn = 1;


-- 10b. Interest rate sensitivity analysis
--      How much more/less would customers pay at ±1% rate shift?
SELECT
    c.full_name,
    lp.loan_type,
    lp.product_name,
    l.principal,
    l.term_months,
    ROUND(l.interest_rate * 100, 3)                 AS current_rate_pct,
    -- Current monthly payment
    ROUND(
        l.principal * (l.interest_rate/12) /
        (1 - POWER(1 + l.interest_rate/12, -l.term_months))
    ,2)                                             AS current_monthly_payment,
    -- Payment at rate +1%
    ROUND(
        l.principal * ((l.interest_rate+0.01)/12) /
        (1 - POWER(1 + (l.interest_rate+0.01)/12, -l.term_months))
    ,2)                                             AS payment_rate_plus_1pct,
    -- Payment at rate -1%
    ROUND(
        l.principal * ((l.interest_rate-0.01)/12) /
        (1 - POWER(1 + (l.interest_rate-0.01)/12, -l.term_months))
    ,2)                                             AS payment_rate_minus_1pct,
    -- Impact
    ROUND(
        l.principal * ((l.interest_rate+0.01)/12) /
        (1 - POWER(1 + (l.interest_rate+0.01)/12, -l.term_months))
      - l.principal * (l.interest_rate/12) /
        (1 - POWER(1 + l.interest_rate/12, -l.term_months))
    ,2)                                             AS monthly_impact_plus_1pct,
    -- Total interest lifetime comparison
    ROUND(
        l.term_months *
        l.principal * (l.interest_rate/12) /
        (1 - POWER(1 + l.interest_rate/12, -l.term_months))
      - l.principal
    ,2)                                             AS total_interest_current,
    ROUND(
        l.term_months *
        l.principal * ((l.interest_rate+0.01)/12) /
        (1 - POWER(1 + (l.interest_rate+0.01)/12, -l.term_months))
      - l.principal
    ,2)                                             AS total_interest_plus_1pct
FROM loans l
JOIN customers    c   ON c.customer_id = l.customer_id
JOIN loan_products lp ON lp.product_id = l.product_id
WHERE l.status = 'ACTIVE'
ORDER BY l.principal DESC;
