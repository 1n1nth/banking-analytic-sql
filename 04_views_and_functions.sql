-- ============================================================
--  BANKING ANALYTICS SYSTEM — VIEWS & FUNCTIONS
-- ============================================================


-- ─── View: Active Account Overview ──────────────────────────
CREATE OR REPLACE VIEW vw_active_accounts AS
SELECT
    a.account_id,
    a.account_number,
    c.full_name                                     AS customer_name,
    c.email,
    at2.type_name                                   AS account_type,
    a.currency_code,
    a.balance,
    a.available_balance,
    a.opened_date,
    b.branch_name,
    co.country_name,
    rc.risk_name                                    AS customer_risk,
    a.status
FROM accounts      a
JOIN customers     c   ON c.customer_id  = a.customer_id
JOIN account_types at2 ON at2.type_id    = a.type_id
JOIN branches      b   ON b.branch_id    = a.branch_id
JOIN countries     co  ON co.country_code = b.country_code
JOIN risk_categories rc ON rc.risk_id    = c.risk_id
WHERE a.status = 'ACTIVE';


-- ─── View: Loan Portfolio Health ────────────────────────────
CREATE OR REPLACE VIEW vw_loan_portfolio AS
SELECT
    l.loan_id,
    c.full_name                                     AS borrower,
    lp.loan_type,
    lp.product_name,
    b.branch_name,
    l.principal,
    l.outstanding_balance,
    ROUND((l.outstanding_balance / l.principal * 100), 1)
                                                    AS outstanding_pct,
    l.interest_rate * 100                           AS rate_pct,
    l.disbursement_date,
    l.maturity_date,
    l.term_months,
    -- Months elapsed vs remaining
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, l.disbursement_date))::INT
                                                    AS months_elapsed,
    EXTRACT(MONTH FROM AGE(l.maturity_date, CURRENT_DATE))::INT
                                                    AS months_remaining,
    l.status,
    -- Days past maturity for overdue loans
    CASE WHEN CURRENT_DATE > l.maturity_date AND l.status = 'ACTIVE'
         THEN (CURRENT_DATE - l.maturity_date) ELSE 0 END
                                                    AS days_past_maturity
FROM loans l
JOIN customers     c   ON c.customer_id  = l.customer_id
JOIN loan_products lp  ON lp.product_id  = l.product_id
JOIN branches      b   ON b.branch_id    = l.branch_id;


-- ─── View: Fraud Watchlist ───────────────────────────────────
CREATE OR REPLACE VIEW vw_fraud_watchlist AS
SELECT
    fa.alert_id,
    c.full_name                                     AS customer_name,
    c.email,
    a.account_number,
    rc.risk_name                                    AS risk_tier,
    fr.rule_name                                    AS triggered_rule,
    fr.severity,
    fa.alert_score,
    fa.status                                       AS alert_status,
    fa.created_at                                   AS flagged_at,
    NOW() - fa.created_at                           AS age_of_alert,
    fa.notes,
    -- Escalation recommendation
    CASE
        WHEN fa.alert_score >= 90 THEN 'ESCALATE_IMMEDIATELY'
        WHEN fa.alert_score >= 70 THEN 'SENIOR_REVIEW_24H'
        WHEN fa.alert_score >= 50 THEN 'ANALYST_REVIEW_72H'
        ELSE 'MONITOR'
    END                                             AS recommended_action
FROM fraud_alerts  fa
JOIN accounts      a   ON a.account_id   = fa.account_id
JOIN customers     c   ON c.customer_id  = a.customer_id
JOIN fraud_rules   fr  ON fr.rule_id     = fa.rule_id
JOIN risk_categories rc ON rc.risk_id   = c.risk_id
WHERE fa.status IN ('OPEN','INVESTIGATING')
ORDER BY fa.alert_score DESC;


-- ─── Function: Calculate Credit Score ───────────────────────
CREATE OR REPLACE FUNCTION fn_credit_score(p_customer_id UUID)
RETURNS TABLE (
    customer_id         UUID,
    credit_score        INT,
    score_band          VARCHAR(20),
    key_positives       TEXT,
    key_negatives       TEXT,
    calculated_at       TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
DECLARE
    v_score             INT := 650;  -- base score
    v_positives         TEXT[];
    v_negatives         TEXT[];

    v_account_age_years NUMERIC;
    v_on_time_rate      NUMERIC;
    v_default_count     INT;
    v_total_balance     NUMERIC;
    v_open_alerts       INT;
    v_late_count        INT;
    v_kyc               BOOLEAN;
    v_debt_ratio        NUMERIC;
BEGIN
    -- ── Gather raw metrics ─────────────────────────────────
    SELECT
        EXTRACT(YEAR FROM AGE(MIN(a.opened_date))),
        SUM(a.balance),
        c.kyc_verified
    INTO v_account_age_years, v_total_balance, v_kyc
    FROM accounts a
    JOIN customers c ON c.customer_id = a.customer_id
    WHERE a.customer_id = p_customer_id
    GROUP BY c.kyc_verified;

    SELECT
        COUNT(*) FILTER (WHERE lp.status = 'PAID' AND lp.days_late IS NULL)::NUMERIC
        / NULLIF(COUNT(*),0),
        COUNT(*) FILTER (WHERE lp.days_late > 0),
        COUNT(*) FILTER (WHERE l.status = 'DEFAULTED')
    INTO v_on_time_rate, v_late_count, v_default_count
    FROM loan_payments lp
    JOIN loans l ON l.loan_id = lp.loan_id
    WHERE l.customer_id = p_customer_id;

    SELECT COALESCE(
        SUM(l.outstanding_balance) FILTER (WHERE l.status='ACTIVE')
        / NULLIF(v_total_balance, 0), 0)
    INTO v_debt_ratio
    FROM loans l
    WHERE l.customer_id = p_customer_id;

    SELECT COUNT(*)
    INTO v_open_alerts
    FROM fraud_alerts fa
    JOIN accounts a ON a.account_id = fa.account_id
    WHERE a.customer_id = p_customer_id AND fa.status IN ('OPEN','INVESTIGATING');

    -- ── Apply scoring rules ────────────────────────────────

    -- KYC
    IF v_kyc THEN
        v_score := v_score + 30;
        v_positives := v_positives || 'KYC verified (+30)';
    ELSE
        v_score := v_score - 50;
        v_negatives := v_negatives || 'KYC not verified (-50)';
    END IF;

    -- Account age
    IF v_account_age_years >= 5 THEN
        v_score := v_score + 40;
        v_positives := v_positives || 'Long account history (+40)';
    ELSIF v_account_age_years >= 2 THEN
        v_score := v_score + 20;
        v_positives := v_positives || 'Established history (+20)';
    ELSIF v_account_age_years < 1 THEN
        v_score := v_score - 20;
        v_negatives := v_negatives || 'New customer (-20)';
    END IF;

    -- Balance health
    IF v_total_balance > 100000 THEN
        v_score := v_score + 50;
        v_positives := v_positives || 'Strong deposits (+50)';
    ELSIF v_total_balance > 10000 THEN
        v_score := v_score + 25;
        v_positives := v_positives || 'Healthy deposits (+25)';
    ELSIF v_total_balance < 500 THEN
        v_score := v_score - 30;
        v_negatives := v_negatives || 'Low deposit balance (-30)';
    END IF;

    -- Payment history
    IF v_on_time_rate >= 0.98 THEN
        v_score := v_score + 60;
        v_positives := v_positives || 'Excellent payment history (+60)';
    ELSIF v_on_time_rate >= 0.90 THEN
        v_score := v_score + 30;
        v_positives := v_positives || 'Good payment history (+30)';
    ELSIF v_late_count > 0 THEN
        v_score := v_score - (v_late_count * 15);
        v_negatives := v_negatives || 'Late payments (-' || (v_late_count*15) || ')';
    END IF;

    -- Defaults
    IF v_default_count > 0 THEN
        v_score := v_score - (v_default_count * 100);
        v_negatives := v_negatives || 'Loan defaults (-' || (v_default_count*100) || ')';
    END IF;

    -- Debt ratio
    IF v_debt_ratio > 0.8 THEN
        v_score := v_score - 40;
        v_negatives := v_negatives || 'High debt-to-deposit ratio (-40)';
    ELSIF v_debt_ratio < 0.3 AND v_debt_ratio > 0 THEN
        v_score := v_score + 15;
        v_positives := v_positives || 'Low debt ratio (+15)';
    END IF;

    -- Fraud alerts
    IF v_open_alerts > 0 THEN
        v_score := v_score - (v_open_alerts * 25);
        v_negatives := v_negatives || 'Open fraud alerts (-' || (v_open_alerts*25) || ')';
    END IF;

    -- Clamp to 300-850 range
    v_score := GREATEST(300, LEAST(850, v_score));

    RETURN QUERY SELECT
        p_customer_id,
        v_score,
        CASE
            WHEN v_score >= 750 THEN 'EXCELLENT'
            WHEN v_score >= 670 THEN 'GOOD'
            WHEN v_score >= 580 THEN 'FAIR'
            WHEN v_score >= 500 THEN 'POOR'
            ELSE 'VERY_POOR'
        END,
        ARRAY_TO_STRING(v_positives, '; '),
        ARRAY_TO_STRING(v_negatives, '; '),
        NOW();
END;
$$;


-- ─── Function: Account Statement Generator ──────────────────
CREATE OR REPLACE FUNCTION fn_account_statement(
    p_account_id    UUID,
    p_from_date     DATE,
    p_to_date       DATE
)
RETURNS TABLE (
    seq             INT,
    txn_date        DATE,
    description     VARCHAR,
    txn_type        VARCHAR,
    debit           NUMERIC,
    credit          NUMERIC,
    balance         NUMERIC,
    channel         VARCHAR
)
LANGUAGE SQL AS $$
    SELECT
        ROW_NUMBER() OVER (ORDER BY t.created_at)::INT,
        t.created_at::DATE,
        t.description,
        t.transaction_type,
        CASE WHEN t.transaction_type NOT IN ('DEPOSIT','TRANSFER_IN','INTEREST')
             THEN t.amount END,
        CASE WHEN t.transaction_type IN ('DEPOSIT','TRANSFER_IN','INTEREST')
             THEN t.amount END,
        t.balance_after,
        t.channel
    FROM transactions t
    WHERE t.account_id  = p_account_id
      AND t.created_at::DATE BETWEEN p_from_date AND p_to_date
      AND t.status      = 'POSTED'
    ORDER BY t.created_at;
$$;


-- ─── Function: Daily Interest Accrual ───────────────────────
CREATE OR REPLACE FUNCTION fn_accrue_daily_interest(p_date DATE DEFAULT CURRENT_DATE)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    v_count INT := 0;
BEGIN
    INSERT INTO interest_accruals
        (account_id, accrual_date, daily_rate, balance_used, interest_amount, posted)
    SELECT
        a.account_id,
        p_date,
        at2.interest_rate / 365.0,
        a.balance,
        ROUND(a.balance * (at2.interest_rate / 365.0), 6),
        FALSE
    FROM accounts a
    JOIN account_types at2 ON at2.type_id = a.type_id
    WHERE a.status    = 'ACTIVE'
      AND a.balance   > 0
      AND at2.interest_rate > 0
    ON CONFLICT (account_id, accrual_date) DO NOTHING;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


-- ─── Credit Scoring for all customers ───────────────────────
-- Example: run the credit scoring function for every customer
SELECT
    cs.*,
    c.full_name,
    c.email
FROM customers c
CROSS JOIN LATERAL fn_credit_score(c.customer_id) cs
ORDER BY cs.credit_score DESC;


-- ─── Generate account statement example ─────────────────────
SELECT * FROM fn_account_statement(
    'b1000000-0000-0000-0000-000000000001',
    '2023-01-01',
    '2023-12-31'
);
