-- ============================================================
--  BANKING ANALYTICS SYSTEM — SEED DATA
--  Realistic data for portfolio demonstration
-- ============================================================

-- ─── Reference Data ─────────────────────────────────────────

INSERT INTO countries VALUES
    ('US', 'United States',    'USD', 'Americas'),
    ('GB', 'United Kingdom',   'GBP', 'Europe'),
    ('DE', 'Germany',          'EUR', 'Europe'),
    ('SG', 'Singapore',        'SGD', 'Asia Pacific'),
    ('IN', 'India',            'INR', 'Asia Pacific'),
    ('CA', 'Canada',           'CAD', 'Americas'),
    ('AU', 'Australia',        'AUD', 'Asia Pacific'),
    ('JP', 'Japan',            'JPY', 'Asia Pacific');

INSERT INTO currencies VALUES
    ('USD', 'US Dollar',          '$',  2),
    ('GBP', 'British Pound',      '£',  2),
    ('EUR', 'Euro',               '€',  2),
    ('SGD', 'Singapore Dollar',   'S$', 2),
    ('INR', 'Indian Rupee',       '₹',  2),
    ('CAD', 'Canadian Dollar',    'C$', 2),
    ('AUD', 'Australian Dollar',  'A$', 2),
    ('JPY', 'Japanese Yen',       '¥',  0);

INSERT INTO risk_categories VALUES
    (1, 'LOW',      0,   39, 365),
    (2, 'MEDIUM',  40,   69,  90),
    (3, 'HIGH',    70,   89,  30),
    (4, 'CRITICAL',90,  100,   7);

-- ─── Account Types ──────────────────────────────────────────

INSERT INTO account_types (type_code, type_name, interest_rate, overdraft_limit, monthly_fee, min_balance) VALUES
    ('CHK_BASIC',   'Basic Checking',        0.0010, 500.00,   0.00,    0.00),
    ('CHK_PREMIUM', 'Premium Checking',      0.0050, 2000.00, 15.00, 1000.00),
    ('SAV_STANDARD','Standard Savings',      0.0200, 0.00,     0.00,  100.00),
    ('SAV_HIGH',    'High-Yield Savings',    0.0480, 0.00,     0.00, 5000.00),
    ('MONEY_MKT',   'Money Market',          0.0420, 0.00,    10.00, 2500.00),
    ('CD_12M',      '12-Month CD',           0.0520, 0.00,     0.00, 1000.00),
    ('BIZ_CHK',     'Business Checking',     0.0015, 5000.00, 25.00,    0.00),
    ('BIZ_SAV',     'Business Savings',      0.0180, 0.00,    10.00,  500.00);

-- ─── Branches ───────────────────────────────────────────────

INSERT INTO branches (branch_code, branch_name, country_code, city, opened_date) VALUES
    ('NYC-001', 'New York Flagship',     'US', 'New York',      '2005-03-15'),
    ('NYC-002', 'Brooklyn Heights',      'US', 'New York',      '2008-06-01'),
    ('LAX-001', 'Los Angeles Downtown',  'US', 'Los Angeles',   '2007-09-20'),
    ('CHI-001', 'Chicago Loop',          'US', 'Chicago',       '2006-11-10'),
    ('LON-001', 'London City',           'GB', 'London',        '2010-04-05'),
    ('LON-002', 'Canary Wharf',          'GB', 'London',        '2012-08-15'),
    ('SGP-001', 'Singapore Central',     'SG', 'Singapore',     '2015-01-20'),
    ('TOR-001', 'Toronto Financial',     'CA', 'Toronto',       '2013-07-08');

-- ─── Employees (with hierarchy) ─────────────────────────────

INSERT INTO employees (branch_id, manager_id, first_name, last_name, job_title, hire_date, base_salary, department) VALUES
    -- NYC HQ leadership
    (1, NULL,  'Margaret', 'Chen',     'Chief Banking Officer',   '2005-03-15', 285000, 'Executive'),
    (1, 1,     'Robert',   'Haines',   'VP Retail Banking',       '2006-01-10', 195000, 'Retail'),
    (1, 1,     'Priya',    'Nair',     'VP Risk & Compliance',    '2007-05-20', 205000, 'Risk'),
    -- Branch Managers
    (1, 2,     'James',    'Whitfield','Branch Manager NYC-001',  '2008-03-01', 125000, 'Retail'),
    (2, 2,     'Sofia',    'Reyes',    'Branch Manager NYC-002',  '2010-07-15', 115000, 'Retail'),
    (3, 2,     'David',    'Park',     'Branch Manager LAX-001',  '2009-11-01', 118000, 'Retail'),
    (4, 2,     'Amara',    'Okafor',   'Branch Manager CHI-001',  '2011-02-14', 112000, 'Retail'),
    (5, 2,     'Oliver',   'Thompson', 'Branch Manager LON-001',  '2010-04-05', 130000, 'Retail'),
    (7, 2,     'Mei',      'Tanaka',   'Branch Manager SGP-001',  '2015-01-20', 145000, 'Retail'),
    -- Loan Officers
    (1, 4,     'Carlos',   'Mendez',   'Senior Loan Officer',     '2012-06-01',  92000, 'Lending'),
    (1, 4,     'Hannah',   'Fischer',  'Loan Officer',            '2018-03-15',  72000, 'Lending'),
    (3, 6,     'Kenji',    'Watanabe', 'Loan Officer',            '2019-09-01',  71000, 'Lending'),
    -- Compliance
    (1, 3,     'Fatima',   'Al-Hassan','Senior Compliance Analyst','2013-08-20', 98000, 'Compliance'),
    (1, 3,     'Brandon',  'Scott',    'Fraud Analyst',           '2020-01-06',  68000, 'Compliance');

-- ─── Customers ──────────────────────────────────────────────

INSERT INTO customers (customer_id, first_name, last_name, date_of_birth, email, phone, country_code, risk_id, kyc_verified, kyc_verified_at) VALUES
    ('a1000000-0000-0000-0000-000000000001','Alice','Morgan',       '1982-04-12','alice.morgan@email.com',       '+12125550101','US',1,TRUE,'2019-01-15 09:00:00+00'),
    ('a1000000-0000-0000-0000-000000000002','Benjamin','Torres',    '1975-11-28','ben.torres@email.com',         '+12125550102','US',1,TRUE,'2018-06-20 10:30:00+00'),
    ('a1000000-0000-0000-0000-000000000003','Catherine','Wu',       '1990-07-03','cat.wu@email.com',             '+12125550103','US',2,TRUE,'2020-03-10 14:00:00+00'),
    ('a1000000-0000-0000-0000-000000000004','Daniel','Osei',        '1988-02-19','d.osei@email.com',             '+12125550104','US',1,TRUE,'2017-11-05 11:00:00+00'),
    ('a1000000-0000-0000-0000-000000000005','Elena','Kovacs',       '1995-09-30','elena.kovacs@email.com',       '+14155550105','US',2,TRUE,'2021-07-22 09:30:00+00'),
    ('a1000000-0000-0000-0000-000000000006','Felix','Hoffmann',     '1970-06-14','felix.h@biz.de',               '+493055550106','DE',1,TRUE,'2016-04-18 08:00:00+00'),
    ('a1000000-0000-0000-0000-000000000007','Grace','Patel',        '1985-12-25','grace.patel@email.com',        '+14425550107','GB',2,TRUE,'2019-09-30 15:00:00+00'),
    ('a1000000-0000-0000-0000-000000000008','Henry','Nakamura',     '1992-03-08','h.nakamura@corp.jp',           '+81355550108','JP',1,TRUE,'2020-12-01 07:00:00+00'),
    ('a1000000-0000-0000-0000-000000000009','Isabella','Costa',     '1998-08-17','isa.costa@email.com',          '+12125550109','US',3,TRUE,'2022-02-14 13:00:00+00'),
    ('a1000000-0000-0000-0000-000000000010','James','Blackwood',    '1968-01-31','jblackwood@wealth.com',        '+12125550110','US',1,TRUE,'2015-08-10 09:00:00+00'),
    ('a1000000-0000-0000-0000-000000000011','Kavya','Sharma',       '1994-05-20','kavya.s@email.in',             '+919855550111','IN',2,TRUE,'2021-11-15 12:00:00+00'),
    ('a1000000-0000-0000-0000-000000000012','Lucas','Dubois',       '1987-10-07','l.dubois@email.fr',            '+33155550112','DE',1,TRUE,'2018-03-25 10:00:00+00'),
    ('a1000000-0000-0000-0000-000000000013','Maria','Santos',       '1979-04-22','maria.santos@email.com',       '+12125550113','US',1,TRUE,'2017-07-14 11:30:00+00'),
    ('a1000000-0000-0000-0000-000000000014','Nathan','Griffiths',   '1991-06-11','n.griffiths@corp.co.uk',       '+44205550114','GB',2,TRUE,'2020-05-18 14:30:00+00'),
    ('a1000000-0000-0000-0000-000000000015','Olivia','Fernandez',   '2000-02-29','o.fernandez@email.com',        '+13105550115','US',2,TRUE,'2022-06-01 10:00:00+00'),
    ('a1000000-0000-0000-0000-000000000016','Patrick','O''Brien',   '1973-08-04','pat.obrien@email.ie',          '+35315550116','GB',1,TRUE,'2016-10-20 09:30:00+00'),
    ('a1000000-0000-0000-0000-000000000017','Rachel','Kim',         '1989-11-16','r.kim@corp.sg',                '+6591550117','SG',1,TRUE,'2019-04-08 08:30:00+00'),
    ('a1000000-0000-0000-0000-000000000018','Samuel','Mbeki',       '1983-07-29','s.mbeki@email.com',            '+12125550118','US',3,TRUE,'2021-01-20 13:30:00+00'),
    ('a1000000-0000-0000-0000-000000000019','Tina','Johansson',     '1996-03-14','tina.j@email.se',              '+46855550119','DE',2,TRUE,'2022-09-05 11:00:00+00'),
    ('a1000000-0000-0000-0000-000000000020','Umar','Farouk',        '1977-12-03','umar.f@bizsg.com',             '+6581550120','SG',1,TRUE,'2018-12-12 10:00:00+00');

-- ─── Accounts ───────────────────────────────────────────────

INSERT INTO accounts (account_id, account_number, customer_id, branch_id, type_id, currency_code, balance, available_balance, opened_date, status) VALUES
    -- Alice Morgan - multiple accounts
    ('b1000000-0000-0000-0000-000000000001','ACC-0000001','a1000000-0000-0000-0000-000000000001',1,1,'USD',  12450.00,  12450.00,'2019-01-15','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000002','ACC-0000002','a1000000-0000-0000-0000-000000000001',1,3,'USD',  87200.00,  87200.00,'2019-01-15','ACTIVE'),
    -- Benjamin Torres
    ('b1000000-0000-0000-0000-000000000003','ACC-0000003','a1000000-0000-0000-0000-000000000002',1,2,'USD',  34800.00,  34800.00,'2018-06-20','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000004','ACC-0000004','a1000000-0000-0000-0000-000000000002',1,4,'USD', 250000.00, 250000.00,'2020-01-10','ACTIVE'),
    -- Catherine Wu
    ('b1000000-0000-0000-0000-000000000005','ACC-0000005','a1000000-0000-0000-0000-000000000003',1,1,'USD',   2100.00,   1600.00,'2020-03-10','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000006','ACC-0000006','a1000000-0000-0000-0000-000000000003',1,3,'USD',  15300.00,  15300.00,'2020-03-10','ACTIVE'),
    -- Daniel Osei
    ('b1000000-0000-0000-0000-000000000007','ACC-0000007','a1000000-0000-0000-0000-000000000004',1,1,'USD',  48200.00,  48200.00,'2017-11-05','ACTIVE'),
    -- Elena Kovacs
    ('b1000000-0000-0000-0000-000000000008','ACC-0000008','a1000000-0000-0000-0000-000000000005',2,1,'USD',   3400.00,   3400.00,'2021-07-22','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000009','ACC-0000009','a1000000-0000-0000-0000-000000000005',2,3,'USD',  22500.00,  22500.00,'2021-07-22','ACTIVE'),
    -- Felix Hoffmann (business)
    ('b1000000-0000-0000-0000-000000000010','ACC-0000010','a1000000-0000-0000-0000-000000000006',5,7,'EUR', 185000.00, 180000.00,'2016-04-18','ACTIVE'),
    -- Grace Patel
    ('b1000000-0000-0000-0000-000000000011','ACC-0000011','a1000000-0000-0000-0000-000000000007',5,1,'GBP',  19700.00,  19700.00,'2019-09-30','ACTIVE'),
    -- Henry Nakamura
    ('b1000000-0000-0000-0000-000000000012','ACC-0000012','a1000000-0000-0000-0000-000000000008',7,2,'SGD',  92400.00,  92400.00,'2020-12-01','ACTIVE'),
    -- Isabella Costa - high risk
    ('b1000000-0000-0000-0000-000000000013','ACC-0000013','a1000000-0000-0000-0000-000000000009',1,1,'USD',    450.00,    450.00,'2022-02-14','ACTIVE'),
    -- James Blackwood - HNW
    ('b1000000-0000-0000-0000-000000000014','ACC-0000014','a1000000-0000-0000-0000-000000000010',1,2,'USD', 520000.00, 520000.00,'2015-08-10','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000015','ACC-0000015','a1000000-0000-0000-0000-000000000010',1,4,'USD',1850000.00,1850000.00,'2015-08-10','ACTIVE'),
    ('b1000000-0000-0000-0000-000000000016','ACC-0000016','a1000000-0000-0000-0000-000000000010',1,6,'USD', 300000.00, 300000.00,'2018-03-01','ACTIVE'),
    -- Kavya Sharma
    ('b1000000-0000-0000-0000-000000000017','ACC-0000017','a1000000-0000-0000-0000-000000000011',7,1,'SGD',   8900.00,   8900.00,'2021-11-15','ACTIVE'),
    -- Lucas Dubois
    ('b1000000-0000-0000-0000-000000000018','ACC-0000018','a1000000-0000-0000-0000-000000000012',5,1,'EUR',  27300.00,  27300.00,'2018-03-25','ACTIVE'),
    -- Maria Santos
    ('b1000000-0000-0000-0000-000000000019','ACC-0000019','a1000000-0000-0000-0000-000000000013',1,3,'USD',  64100.00,  64100.00,'2017-07-14','ACTIVE'),
    -- Nathan Griffiths
    ('b1000000-0000-0000-0000-000000000020','ACC-0000020','a1000000-0000-0000-0000-000000000014',5,2,'GBP',  41200.00,  41200.00,'2020-05-18','ACTIVE'),
    -- Samuel Mbeki - high risk
    ('b1000000-0000-0000-0000-000000000021','ACC-0000021','a1000000-0000-0000-0000-000000000018',4,1,'USD',   1200.00,   1200.00,'2021-01-20','FROZEN'),
    -- Rachel Kim (business)
    ('b1000000-0000-0000-0000-000000000022','ACC-0000022','a1000000-0000-0000-0000-000000000017',7,7,'SGD', 345000.00, 340000.00,'2019-04-08','ACTIVE');

-- ─── Loan Products ──────────────────────────────────────────

INSERT INTO loan_products (product_code, product_name, loan_type, min_amount, max_amount, min_term_months, max_term_months, base_rate) VALUES
    ('PL-STD',  'Standard Personal Loan',     'PERSONAL',   1000,    50000,  12,  60, 0.0899),
    ('PL-PREM', 'Premium Personal Loan',      'PERSONAL',   5000,   100000,  12,  84, 0.0699),
    ('MORT-FX', 'Fixed Rate Mortgage',        'MORTGAGE',  50000, 2000000, 120, 360, 0.0625),
    ('MORT-VR', 'Variable Rate Mortgage',     'MORTGAGE',  50000, 2000000, 120, 360, 0.0575),
    ('AUTO-NEW','New Auto Loan',              'AUTO',       5000,    80000,  24,  72, 0.0549),
    ('AUTO-USD','Used Auto Loan',             'AUTO',       3000,    40000,  24,  60, 0.0699),
    ('BIZ-LOC', 'Business Line of Credit',   'CREDIT_LINE',10000,  500000,  12, 120, 0.0750),
    ('BIZ-TERM','Business Term Loan',         'BUSINESS',  25000,  1000000, 24, 120, 0.0680);

-- ─── Loans ──────────────────────────────────────────────────

INSERT INTO loans (loan_id, customer_id, product_id, branch_id, officer_id, principal, interest_rate, term_months, disbursement_date, status, outstanding_balance) VALUES
    ('c1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001',3,1,10, 420000.00,0.0610,360,'2019-06-01','ACTIVE',  398200.00),
    ('c1000000-0000-0000-0000-000000000002','a1000000-0000-0000-0000-000000000002',1,1,10,  18000.00,0.0899, 48,'2022-03-15','ACTIVE',   10400.00),
    ('c1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000004',5,1,10,  28000.00,0.0549, 60,'2021-09-01','ACTIVE',   18300.00),
    ('c1000000-0000-0000-0000-000000000004','a1000000-0000-0000-0000-000000000006',8,5,11, 150000.00,0.0680, 84,'2020-07-01','ACTIVE',  112000.00),
    ('c1000000-0000-0000-0000-000000000005','a1000000-0000-0000-0000-000000000010',3,1,10,1200000.00,0.0590,360,'2018-05-01','ACTIVE', 1148000.00),
    ('c1000000-0000-0000-0000-000000000006','a1000000-0000-0000-0000-000000000013',1,1,11,   8000.00,0.0999, 36,'2022-03-01','ACTIVE',    5600.00),
    ('c1000000-0000-0000-0000-000000000007','a1000000-0000-0000-0000-000000000018',1,4,10,  12000.00,0.1099, 36,'2022-06-01','DEFAULTED',11800.00),
    ('c1000000-0000-0000-0000-000000000008','a1000000-0000-0000-0000-000000000017',7,7,12,  75000.00,0.0750, 60,'2021-04-01','ACTIVE',   52000.00),
    ('c1000000-0000-0000-0000-000000000009','a1000000-0000-0000-0000-000000000005',2,2,11,  25000.00,0.0749, 60,'2023-01-15','ACTIVE',   22100.00),
    ('c1000000-0000-0000-0000-000000000010','a1000000-0000-0000-0000-000000000003',5,1,12,  22000.00,0.0599, 48,'2023-08-01','ACTIVE',   19500.00);

-- ─── Loan Payments (sample amortization schedule) ────────────

INSERT INTO loan_payments (loan_id, due_date, paid_date, scheduled_amount, principal_portion, interest_portion, penalty_amount, status) VALUES
    -- Loan 002 - mostly on time, one late
    ('c1000000-0000-0000-0000-000000000002','2022-04-15','2022-04-14', 451.24, 316.24, 135.00, 0.00,'PAID'),
    ('c1000000-0000-0000-0000-000000000002','2022-05-15','2022-05-15', 451.24, 318.62, 132.62, 0.00,'PAID'),
    ('c1000000-0000-0000-0000-000000000002','2022-06-15','2022-06-22', 451.24, 320.00, 131.24,25.00,'PAID'),  -- 7 days late
    ('c1000000-0000-0000-0000-000000000002','2022-07-15','2022-07-15', 451.24, 322.00, 129.24, 0.00,'PAID'),
    ('c1000000-0000-0000-0000-000000000002','2022-08-15','2022-08-14', 451.24, 324.00, 127.24, 0.00,'PAID'),
    -- Loan 006 (high risk - Isabella) - mixed payments
    ('c1000000-0000-0000-0000-000000000006','2022-04-01','2022-04-05', 257.85, 191.52,  66.33, 0.00,'PAID'),
    ('c1000000-0000-0000-0000-000000000006','2022-05-01','2022-05-18', 257.85, 193.11,  64.74,25.00,'PAID'),  -- 17 days late
    ('c1000000-0000-0000-0000-000000000006','2022-06-01','2022-06-30', 257.85, 194.72,  63.13,25.00,'PAID'),  -- 29 days late
    ('c1000000-0000-0000-0000-000000000006','2022-07-01',NULL,         257.85,   0.00,   0.00, 0.00,'OVERDUE'),
    -- Loan 007 (Samuel - defaulted)
    ('c1000000-0000-0000-0000-000000000007','2022-07-01','2022-07-03', 391.47, 282.47, 109.00, 0.00,'PAID'),
    ('c1000000-0000-0000-0000-000000000007','2022-08-01','2022-09-15', 391.47, 284.06, 107.41,50.00,'PAID'),  -- 45 days late
    ('c1000000-0000-0000-0000-000000000007','2022-09-01',NULL,         391.47,   0.00,   0.00, 0.00,'OVERDUE'),
    ('c1000000-0000-0000-0000-000000000007','2022-10-01',NULL,         391.47,   0.00,   0.00, 0.00,'OVERDUE');

-- ─── Fraud Rules ────────────────────────────────────────────

INSERT INTO fraud_rules (rule_name, rule_type, threshold_amount, threshold_count, time_window_mins, severity) VALUES
    ('Large Single Transaction',     'AMOUNT_THRESHOLD',  10000.00, NULL,  NULL, 'HIGH'),
    ('Rapid Successive Withdrawals', 'VELOCITY',           NULL,    5,     60,   'HIGH'),
    ('Unusual Foreign Transaction',  'GEO_ANOMALY',        500.00,  NULL,  NULL, 'MEDIUM'),
    ('Round Amount Pattern',         'PATTERN',            1000.00, 3,    1440,  'LOW'),
    ('New Account Large Transfer',   'NEW_ACCOUNT',        5000.00, NULL,  NULL, 'CRITICAL'),
    ('Late Night High Value',        'TIME_ANOMALY',       2000.00, NULL,  NULL, 'MEDIUM');

-- ─── Transactions (2022-2025 rich dataset) ──────────────────

-- Alice Morgan - regular activity
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5000.00,'USD', 17450.00,'Payroll deposit',           'SYSTEM','2023-01-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',  1200.00,'USD', 16250.00,'Rent payment',              'ONLINE','2023-02-01 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',   450.00,'USD', 15800.00,'Grocery store',             'MOBILE','2023-02-05 14:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5000.00,'USD', 20800.00,'Payroll deposit',           'SYSTEM','2023-02-28 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',  1200.00,'USD', 19600.00,'Rent payment',              'ONLINE','2023-03-01 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5000.00,'USD', 24600.00,'Payroll deposit',           'SYSTEM','2023-03-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','TRANSFER_OUT',8000.00,'USD', 16600.00,'Transfer to savings',       'ONLINE','2023-04-03 11:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000002','TRANSFER_IN', 8000.00,'USD', 95200.00,'Transfer from checking',    'ONLINE','2023-04-03 11:00:01+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5000.00,'USD', 21600.00,'Payroll deposit',           'SYSTEM','2023-04-28 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',   320.00,'USD', 21280.00,'Utilities',                 'ONLINE','2023-05-02 08:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5000.00,'USD', 26280.00,'Payroll deposit',           'SYSTEM','2023-05-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',  2500.00,'USD', 23780.00,'Vacation expenses',         'ATM',   '2023-06-15 15:00:00+00','POSTED');

-- James Blackwood - HNW client
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000015','DEPOSIT',    50000.00,'USD',1900000.00,'Dividend income',          'ONLINE','2023-01-15 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','DEPOSIT',    75000.00,'USD',1975000.00,'Investment proceeds',      'BRANCH','2023-02-10 14:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','TRANSFER_OUT',100000.00,'USD',1875000.00,'Real estate payment',    'BRANCH','2023-03-05 11:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','DEPOSIT',   200000.00,'USD',2075000.00,'Property sale proceeds',  'BRANCH','2023-04-20 09:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','WITHDRAWAL', 15000.00,'USD',2060000.00,'Tax payment',             'ONLINE','2023-06-30 16:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000014','DEPOSIT',    25000.00,'USD', 545000.00,'Bonus payment',           'ONLINE','2023-03-15 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000014','WITHDRAWAL', 12000.00,'USD', 533000.00,'Overseas wire transfer',  'ONLINE','2023-05-01 09:00:00+00','POSTED');

-- Isabella Costa - suspicious activity
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 1450.00,'Cash deposit',              'ATM',   '2023-03-01 02:15:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 2450.00,'Cash deposit',              'ATM',   '2023-03-01 02:45:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 3450.00,'Cash deposit',              'ATM',   '2023-03-01 03:10:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','WITHDRAWAL', 2900.00,'USD',  550.00,'Cash withdrawal',           'ATM',   '2023-03-01 03:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    5000.00,'USD', 5550.00,'Wire transfer in',          'ONLINE','2023-04-15 11:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','WITHDRAWAL', 4800.00,'USD',  750.00,'International wire',        'ONLINE','2023-04-15 11:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 1750.00,'Cash deposit',              'ATM',   '2023-05-10 23:55:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 2750.00,'Cash deposit',              'ATM',   '2023-05-11 00:10:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    1000.00,'USD', 3750.00,'Cash deposit',              'ATM',   '2023-05-11 00:25:00+00','POSTED');

-- Felix Hoffmann - business transactions
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000010','DEPOSIT',   45000.00,'EUR',230000.00,'Client payment - Invoice 4401','API', '2023-02-15 08:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','WITHDRAWAL',12000.00,'EUR',218000.00,'Supplier payment',             'API', '2023-02-20 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','DEPOSIT',   62000.00,'EUR',280000.00,'Client payment - Invoice 4450','API', '2023-03-15 08:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','WITHDRAWAL',25000.00,'EUR',255000.00,'Payroll disbursement',         'API', '2023-03-31 17:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','FEE',          25.00,'EUR',254975.00,'Monthly account fee',          'SYSTEM','2023-03-31 23:59:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','DEPOSIT',   38000.00,'EUR',292975.00,'Client payment - Invoice 4501','API', '2023-04-18 08:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000010','TRANSFER_OUT',80000.00,'EUR',212975.00,'Tax reserve transfer',       'ONLINE','2023-04-30 16:00:00+00','POSTED');

-- Rachel Kim - business SGD
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000022','DEPOSIT',   120000.00,'SGD',465000.00,'Client retainer Q1',        'API', '2023-01-02 08:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000022','WITHDRAWAL', 35000.00,'SGD',430000.00,'Office rental',             'ONLINE','2023-01-05 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000022','DEPOSIT',    85000.00,'SGD',515000.00,'Project milestone payment', 'API', '2023-02-15 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000022','WITHDRAWAL', 48000.00,'SGD',467000.00,'Contractor payments',       'API', '2023-02-28 17:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000022','DEPOSIT',    95000.00,'SGD',562000.00,'Q2 retainer',               'API', '2023-04-01 08:00:00+00','POSTED');

-- 2024 transactions for trend analysis
INSERT INTO transactions (account_id, transaction_type, amount, currency_code, balance_after, description, channel, created_at, status) VALUES
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5200.00,'USD', 17452.00,'Payroll deposit',           'SYSTEM','2024-01-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','WITHDRAWAL',  1200.00,'USD', 16252.00,'Rent payment',              'ONLINE','2024-02-01 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5200.00,'USD', 21452.00,'Payroll deposit',           'SYSTEM','2024-02-29 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000001','DEPOSIT',     5200.00,'USD', 26652.00,'Payroll deposit',           'SYSTEM','2024-03-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000003','DEPOSIT',     8500.00,'USD', 43300.00,'Payroll deposit',           'SYSTEM','2024-01-31 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000003','WITHDRAWAL',  3200.00,'USD', 40100.00,'Mortgage payment',          'ONLINE','2024-02-05 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000003','DEPOSIT',     8500.00,'USD', 48600.00,'Payroll deposit',           'SYSTEM','2024-02-28 09:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','DEPOSIT',   100000.00,'USD',1960000.00,'Annual bonus',             'BRANCH','2024-01-10 10:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','TRANSFER_OUT',250000.00,'USD',1710000.00,'Investment fund wire',   'BRANCH','2024-02-15 14:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000015','DEPOSIT',   180000.00,'USD',1890000.00,'Dividend reinvestment',    'ONLINE','2024-03-31 16:00:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','DEPOSIT',    10500.00,'USD', 11250.00,'Unexplained large deposit', 'ATM',   '2024-02-10 01:30:00+00','POSTED'),
    ('b1000000-0000-0000-0000-000000000013','WITHDRAWAL', 10000.00,'USD',  1250.00,'Immediate full withdrawal', 'ATM',   '2024-02-10 01:45:00+00','POSTED');

-- ─── Interest Accruals (sample) ─────────────────────────────

INSERT INTO interest_accruals (account_id, accrual_date, daily_rate, balance_used, interest_amount, posted) VALUES
    ('b1000000-0000-0000-0000-000000000002','2023-01-31',0.00005479,87200.00,4.778,TRUE),
    ('b1000000-0000-0000-0000-000000000002','2023-02-28',0.00005479,87200.00,4.778,TRUE),
    ('b1000000-0000-0000-0000-000000000002','2023-03-31',0.00005479,87200.00,4.778,TRUE),
    ('b1000000-0000-0000-0000-000000000004','2023-01-31',0.00013151,250000.00,32.877,TRUE),
    ('b1000000-0000-0000-0000-000000000004','2023-02-28',0.00013151,250000.00,32.877,TRUE),
    ('b1000000-0000-0000-0000-000000000004','2023-03-31',0.00013151,250000.00,32.877,TRUE),
    ('b1000000-0000-0000-0000-000000000015','2023-01-31',0.00014247,1900000.00,270.694,TRUE),
    ('b1000000-0000-0000-0000-000000000015','2023-02-28',0.00014247,1975000.00,281.378,TRUE),
    ('b1000000-0000-0000-0000-000000000015','2023-03-31',0.00014247,1875000.00,267.131,TRUE);

-- ─── Fraud Alerts ────────────────────────────────────────────

INSERT INTO fraud_alerts (account_id, transaction_id, rule_id, alert_score, status, created_at) VALUES
    ('b1000000-0000-0000-0000-000000000013',
     (SELECT transaction_id FROM transactions WHERE account_id='b1000000-0000-0000-0000-000000000013' AND amount=1000.00 ORDER BY created_at LIMIT 1),
     4, 72.50,'INVESTIGATING','2023-03-01 04:00:00+00'),
    ('b1000000-0000-0000-0000-000000000013',
     (SELECT transaction_id FROM transactions WHERE account_id='b1000000-0000-0000-0000-000000000013' AND amount=4800.00 LIMIT 1),
     3, 68.00,'OPEN','2023-04-15 12:00:00+00'),
    ('b1000000-0000-0000-0000-000000000013',
     (SELECT transaction_id FROM transactions WHERE account_id='b1000000-0000-0000-0000-000000000013' AND amount=10500.00 LIMIT 1),
     5, 91.00,'OPEN','2024-02-10 02:00:00+00');
