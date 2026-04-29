-- ============================================================
--  BANKING ANALYTICS SYSTEM — SCHEMA
--  Demonstrates: normalization, constraints, FK relationships,
--  check constraints, generated columns, partitioning
-- ============================================================

-- ─── Extensions ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Lookup / Reference Tables ──────────────────────────────

CREATE TABLE countries (
    country_code    CHAR(2)         PRIMARY KEY,
    country_name    VARCHAR(100)    NOT NULL,
    currency_code   CHAR(3)         NOT NULL,
    region          VARCHAR(50)
);

CREATE TABLE currencies (
    currency_code   CHAR(3)         PRIMARY KEY,
    currency_name   VARCHAR(50)     NOT NULL,
    symbol          VARCHAR(5)      NOT NULL,
    decimal_places  SMALLINT        NOT NULL DEFAULT 2
);

CREATE TABLE risk_categories (
    risk_id         SERIAL          PRIMARY KEY,
    risk_name       VARCHAR(30)     NOT NULL UNIQUE,   -- LOW / MEDIUM / HIGH / CRITICAL
    min_score       SMALLINT        NOT NULL,
    max_score       SMALLINT        NOT NULL,
    review_days     SMALLINT        NOT NULL,           -- how often account is reviewed
    CONSTRAINT chk_score_range CHECK (min_score < max_score)
);

-- ─── Customers ──────────────────────────────────────────────

CREATE TABLE customers (
    customer_id     UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name      VARCHAR(60)     NOT NULL,
    last_name       VARCHAR(60)     NOT NULL,
    full_name       VARCHAR(122)    GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    date_of_birth   DATE            NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    phone           VARCHAR(20),
    country_code    CHAR(2)         NOT NULL REFERENCES countries(country_code),
    risk_id         INT             REFERENCES risk_categories(risk_id),
    kyc_verified    BOOLEAN         NOT NULL DEFAULT FALSE,
    kyc_verified_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_adult CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years')
);

CREATE TABLE customer_addresses (
    address_id      SERIAL          PRIMARY KEY,
    customer_id     UUID            NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    address_type    VARCHAR(10)     NOT NULL CHECK (address_type IN ('HOME','WORK','MAILING')),
    street_line1    VARCHAR(200)    NOT NULL,
    street_line2    VARCHAR(200),
    city            VARCHAR(100)    NOT NULL,
    state_province  VARCHAR(100),
    postal_code     VARCHAR(20),
    country_code    CHAR(2)         NOT NULL REFERENCES countries(country_code),
    is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,
    valid_from      DATE            NOT NULL DEFAULT CURRENT_DATE,
    valid_to        DATE,
    CONSTRAINT chk_valid_dates CHECK (valid_to IS NULL OR valid_to > valid_from)
);

-- ─── Branches & Staff ───────────────────────────────────────

CREATE TABLE branches (
    branch_id       SERIAL          PRIMARY KEY,
    branch_code     VARCHAR(10)     NOT NULL UNIQUE,
    branch_name     VARCHAR(100)    NOT NULL,
    country_code    CHAR(2)         NOT NULL REFERENCES countries(country_code),
    city            VARCHAR(100)    NOT NULL,
    opened_date     DATE            NOT NULL,
    closed_date     DATE,
    is_active       BOOLEAN         GENERATED ALWAYS AS (closed_date IS NULL) STORED
);

CREATE TABLE employees (
    employee_id     SERIAL          PRIMARY KEY,
    branch_id       INT             NOT NULL REFERENCES branches(branch_id),
    manager_id      INT             REFERENCES employees(employee_id),   -- self-referential
    first_name      VARCHAR(60)     NOT NULL,
    last_name       VARCHAR(60)     NOT NULL,
    job_title       VARCHAR(80)     NOT NULL,
    hire_date       DATE            NOT NULL,
    termination_date DATE,
    base_salary     NUMERIC(12,2)   NOT NULL CHECK (base_salary > 0),
    department      VARCHAR(50)     NOT NULL
);

-- ─── Account Types & Products ───────────────────────────────

CREATE TABLE account_types (
    type_id         SERIAL          PRIMARY KEY,
    type_code       VARCHAR(20)     NOT NULL UNIQUE,
    type_name       VARCHAR(60)     NOT NULL,
    interest_rate   NUMERIC(6,4)    NOT NULL DEFAULT 0,     -- annual %
    overdraft_limit NUMERIC(12,2)   NOT NULL DEFAULT 0,
    monthly_fee     NUMERIC(8,2)    NOT NULL DEFAULT 0,
    min_balance     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    description     TEXT
);

-- ─── Accounts ───────────────────────────────────────────────

CREATE TABLE accounts (
    account_id      UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_number  VARCHAR(20)     NOT NULL UNIQUE,
    customer_id     UUID            NOT NULL REFERENCES customers(customer_id),
    branch_id       INT             NOT NULL REFERENCES branches(branch_id),
    type_id         INT             NOT NULL REFERENCES account_types(type_id),
    currency_code   CHAR(3)         NOT NULL REFERENCES currencies(currency_code),
    balance         NUMERIC(15,2)   NOT NULL DEFAULT 0,
    available_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    opened_date     DATE            NOT NULL DEFAULT CURRENT_DATE,
    closed_date     DATE,
    status          VARCHAR(15)     NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE','FROZEN','CLOSED','DORMANT')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_balance_gte_overdraft
        CHECK (balance >= -(SELECT overdraft_limit FROM account_types WHERE type_id = accounts.type_id))
);

-- ─── Transactions ────────────────────────────────────────────
-- Partitioned by year for performance demonstration

CREATE TABLE transactions (
    transaction_id  UUID            NOT NULL DEFAULT uuid_generate_v4(),
    account_id      UUID            NOT NULL REFERENCES accounts(account_id),
    transaction_type VARCHAR(20)    NOT NULL
                        CHECK (transaction_type IN
                            ('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT',
                             'FEE','INTEREST','REVERSAL','ADJUSTMENT')),
    amount          NUMERIC(15,2)   NOT NULL,
    currency_code   CHAR(3)         NOT NULL REFERENCES currencies(currency_code),
    balance_after   NUMERIC(15,2)   NOT NULL,
    description     VARCHAR(255),
    reference_id    UUID,           -- links paired TRANSFER_IN / TRANSFER_OUT
    channel         VARCHAR(20)     NOT NULL
                        CHECK (channel IN ('ATM','BRANCH','ONLINE','MOBILE','API','SYSTEM')),
    initiated_by    INT             REFERENCES employees(employee_id),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    posted_at       TIMESTAMPTZ,
    status          VARCHAR(15)     NOT NULL DEFAULT 'POSTED'
                        CHECK (status IN ('PENDING','POSTED','FAILED','REVERSED')),
    PRIMARY KEY (transaction_id, created_at)
) PARTITION BY RANGE (created_at);

-- Create yearly partitions
CREATE TABLE transactions_2022 PARTITION OF transactions
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE transactions_2023 PARTITION OF transactions
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE transactions_2024 PARTITION OF transactions
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE transactions_2025 PARTITION OF transactions
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- ─── Loans ──────────────────────────────────────────────────

CREATE TABLE loan_products (
    product_id      SERIAL          PRIMARY KEY,
    product_code    VARCHAR(20)     NOT NULL UNIQUE,
    product_name    VARCHAR(80)     NOT NULL,
    loan_type       VARCHAR(20)     NOT NULL
                        CHECK (loan_type IN ('PERSONAL','MORTGAGE','AUTO','BUSINESS','CREDIT_LINE')),
    min_amount      NUMERIC(15,2)   NOT NULL,
    max_amount      NUMERIC(15,2)   NOT NULL,
    min_term_months SMALLINT        NOT NULL,
    max_term_months SMALLINT        NOT NULL,
    base_rate       NUMERIC(6,4)    NOT NULL,
    CONSTRAINT chk_loan_amounts CHECK (min_amount < max_amount)
);

CREATE TABLE loans (
    loan_id         UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id     UUID            NOT NULL REFERENCES customers(customer_id),
    product_id      INT             NOT NULL REFERENCES loan_products(product_id),
    branch_id       INT             NOT NULL REFERENCES branches(branch_id),
    officer_id      INT             REFERENCES employees(employee_id),
    principal       NUMERIC(15,2)   NOT NULL CHECK (principal > 0),
    interest_rate   NUMERIC(6,4)    NOT NULL,
    term_months     SMALLINT        NOT NULL,
    disbursement_date DATE          NOT NULL,
    maturity_date   DATE            NOT NULL GENERATED ALWAYS AS
                        (disbursement_date + (term_months || ' months')::INTERVAL) STORED,
    status          VARCHAR(15)     NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('PENDING','ACTIVE','PAID_OFF','DEFAULTED','WRITTEN_OFF')),
    outstanding_balance NUMERIC(15,2) NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE loan_payments (
    payment_id      UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    loan_id         UUID            NOT NULL REFERENCES loans(loan_id),
    due_date        DATE            NOT NULL,
    paid_date       DATE,
    scheduled_amount NUMERIC(12,2)  NOT NULL,
    principal_portion NUMERIC(12,2) NOT NULL DEFAULT 0,
    interest_portion  NUMERIC(12,2) NOT NULL DEFAULT 0,
    penalty_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    status          VARCHAR(15)     NOT NULL DEFAULT 'SCHEDULED'
                        CHECK (status IN ('SCHEDULED','PAID','PARTIAL','OVERDUE','WAIVED')),
    days_late       SMALLINT        GENERATED ALWAYS AS
                        (CASE WHEN paid_date IS NOT NULL AND paid_date > due_date
                              THEN (paid_date - due_date)::SMALLINT
                              ELSE NULL END) STORED
);

-- ─── Fraud & Compliance ─────────────────────────────────────

CREATE TABLE fraud_rules (
    rule_id         SERIAL          PRIMARY KEY,
    rule_name       VARCHAR(100)    NOT NULL,
    rule_type       VARCHAR(30)     NOT NULL,
    threshold_amount NUMERIC(15,2),
    threshold_count  SMALLINT,
    time_window_mins SMALLINT,
    severity        VARCHAR(10)     NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE
);

CREATE TABLE fraud_alerts (
    alert_id        UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id  UUID            NOT NULL,
    account_id      UUID            NOT NULL REFERENCES accounts(account_id),
    rule_id         INT             NOT NULL REFERENCES fraud_rules(rule_id),
    alert_score     NUMERIC(5,2)    NOT NULL,
    status          VARCHAR(15)     NOT NULL DEFAULT 'OPEN'
                        CHECK (status IN ('OPEN','INVESTIGATING','RESOLVED','FALSE_POSITIVE')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    resolved_at     TIMESTAMPTZ,
    resolved_by     INT             REFERENCES employees(employee_id),
    notes           TEXT
);

-- ─── Interest Accruals ──────────────────────────────────────

CREATE TABLE interest_accruals (
    accrual_id      SERIAL          PRIMARY KEY,
    account_id      UUID            NOT NULL REFERENCES accounts(account_id),
    accrual_date    DATE            NOT NULL,
    daily_rate      NUMERIC(10,8)   NOT NULL,
    balance_used    NUMERIC(15,2)   NOT NULL,
    interest_amount NUMERIC(12,6)   NOT NULL,
    posted          BOOLEAN         NOT NULL DEFAULT FALSE,
    UNIQUE (account_id, accrual_date)
);

-- ─── Audit Log ──────────────────────────────────────────────

CREATE TABLE audit_log (
    log_id          BIGSERIAL       PRIMARY KEY,
    table_name      VARCHAR(50)     NOT NULL,
    record_id       TEXT            NOT NULL,
    operation       CHAR(1)         NOT NULL CHECK (operation IN ('I','U','D')),
    changed_by      VARCHAR(100)    NOT NULL DEFAULT current_user,
    changed_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    old_values      JSONB,
    new_values      JSONB
);

-- ─── Indexes ────────────────────────────────────────────────

CREATE INDEX idx_customers_country   ON customers(country_code);
CREATE INDEX idx_customers_risk      ON customers(risk_id);
CREATE INDEX idx_accounts_customer   ON accounts(customer_id);
CREATE INDEX idx_accounts_status     ON accounts(status);
CREATE INDEX idx_txn_account         ON transactions(account_id, created_at DESC);
CREATE INDEX idx_txn_type            ON transactions(transaction_type, created_at DESC);
CREATE INDEX idx_txn_reference       ON transactions(reference_id) WHERE reference_id IS NOT NULL;
CREATE INDEX idx_loans_customer      ON loans(customer_id);
CREATE INDEX idx_loans_status        ON loans(status);
CREATE INDEX idx_loan_payments_loan  ON loan_payments(loan_id, due_date);
CREATE INDEX idx_fraud_alerts_acct   ON fraud_alerts(account_id, created_at DESC);
CREATE INDEX idx_audit_table         ON audit_log(table_name, changed_at DESC);

-- ─── Audit Trigger ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO audit_log(table_name, record_id, operation, old_values, new_values)
    VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW::TEXT, OLD::TEXT),
        CASE TG_OP WHEN 'INSERT' THEN 'I' WHEN 'UPDATE' THEN 'U' ELSE 'D' END,
        CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) END
    );
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_audit_accounts
    AFTER INSERT OR UPDATE OR DELETE ON accounts
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_loans
    AFTER INSERT OR UPDATE OR DELETE ON loans
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();
