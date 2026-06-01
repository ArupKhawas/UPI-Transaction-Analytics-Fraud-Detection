-- ================================================================= --
       -- UPI Transaction Analytics & Fraud Detection project --
-- ================================================================= --

USE master;
GO
-- Drop database if already exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'upi_analysis_db')
    DROP DATABASE upi_analysis_db;
GO
-- Create new database
CREATE DATABASE upi_analysis_db;
GO
-- Switch to database
USE upi_analysis_db;
GO

-- Customer details table
CREATE TABLE customer_master (
    customer_id VARCHAR(100), 
    full_name VARCHAR(100), 
    age VARCHAR(50), 
    gender VARCHAR(50), 
    region VARCHAR(100), 
    date_joined VARCHAR(100), 
    is_business_user VARCHAR(50), 
    risk_score VARCHAR(50), 
    mobile_number VARCHAR(100)
);

-- Merchant information table
CREATE TABLE merchant_info (
    merchant_id VARCHAR(100), 
    merchant_name VARCHAR(200), 
    merchant_type VARCHAR(100), 
    region VARCHAR(100), 
    onboard_date VARCHAR(100), 
    risk_score VARCHAR(50)
);

-- Device details used for transactions
CREATE TABLE device_info (
    device_id VARCHAR(100), 
    customer_id VARCHAR(100), 
    device_type VARCHAR(100), 
    app_version VARCHAR(100), 
    is_rooted VARCHAR(50), 
    last_active VARCHAR(100)
);

-- Customer UPI account details
CREATE TABLE upi_account_details (
    upi_id VARCHAR(100), 
    customer_id VARCHAR(100), 
    bank_name VARCHAR(100), 
    account_type VARCHAR(100), 
    date_added VARCHAR(100), 
    status VARCHAR(100)
);

-- Main UPI transaction table
CREATE TABLE upi_transaction_history (
    transaction_id VARCHAR(100), 
    upi_id VARCHAR(100), 
    customer_id VARCHAR(100), 
    timestamp VARCHAR(100), 
    amount VARCHAR(100), 
    transaction_type VARCHAR(100), 
    merchant_id VARCHAR(100), 
    counterparty_upi VARCHAR(100), 
    status VARCHAR(100), 
    device_id VARCHAR(100), 
    device_type VARCHAR(100), 
    channel VARCHAR(100), 
    fraud_flag VARCHAR(50), 
    reversal_flag VARCHAR(50), 
    failure_reason VARCHAR(200)
);

-- Fraud alert records
CREATE TABLE fraud_alert_history (
    alert_id VARCHAR(100), 
    transaction_id VARCHAR(100), 
    alert_type VARCHAR(100), 
    alert_date VARCHAR(100), 
    resolved VARCHAR(50), 
    resolution_date VARCHAR(100), 
    remarks VARCHAR(200)
);

-- Customer feedback and issue tracking
CREATE TABLE customer_feedback (
    feedback_id VARCHAR(100), 
    customer_id VARCHAR(100), 
    date_submitted VARCHAR(100), 
    feedback_text VARCHAR(200), 
    satisfaction_score VARCHAR(50), 
    issue_type VARCHAR(100), 
    resolved VARCHAR(50)
);

-- View raw data from all staging tables
SELECT * FROM customer_feedback
SELECT * FROM customer_master
SELECT * FROM device_info
SELECT * FROM fraud_alert_history
SELECT * FROM merchant_info
SELECT * FROM upi_account_details
SELECT * FROM upi_transaction_history


-- Rename tables with '_stg' suffix to indicate staging layer
EXEC sp_rename 'customer_master', 'customer_master_stg';
EXEC sp_rename 'merchant_info', 'merchant_info_stg';
EXEC sp_rename 'device_info', 'device_info_stg';
EXEC sp_rename 'upi_account_details', 'upi_account_details_stg';
EXEC sp_rename 'upi_transaction_history', 'upi_transaction_history_stg';
EXEC sp_rename 'fraud_alert_history', 'fraud_alert_history_stg';
EXEC sp_rename 'customer_feedback', 'customer_feedback_stg';


-- Customer master table with validation constraints
CREATE TABLE customer_master (
    customer_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100),
    age INT CHECK(age >= 0),
    gender VARCHAR(10),
    region VARCHAR(30),
    date_joined DATE,
    is_business_user BIT DEFAULT 0,
    risk_score DECIMAL(5,2),
    mobile_number VARCHAR(15) UNIQUE
);

-- Merchant details table
CREATE TABLE merchant_info (
    merchant_id VARCHAR(20) PRIMARY KEY,
    merchant_name VARCHAR(100),
    merchant_type VARCHAR(50),
    region VARCHAR(30),
    onboard_date DATE,
    risk_score DECIMAL(5,2)
);

-- Device information linked to customers
CREATE TABLE device_info (
    device_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    device_type VARCHAR(30),
    app_version VARCHAR(20),
    is_rooted BIT DEFAULT 0,
    last_active DATETIME2,                  
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- UPI account details table
CREATE TABLE upi_account_details (
    upi_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    bank_name VARCHAR(50),
    account_type VARCHAR(30),
    date_added DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- Main transaction history table
CREATE TABLE upi_transaction_history (
    transaction_id VARCHAR(20) PRIMARY KEY,
    upi_id VARCHAR(50),
    customer_id VARCHAR(20),
    timestamp DATETIME2,                    
    amount DECIMAL(12,2) CHECK(amount > 0),
    transaction_type VARCHAR(30),
    merchant_id VARCHAR(20),
    counterparty_upi VARCHAR(50),
    status VARCHAR(20),
    device_id VARCHAR(20),
    device_type VARCHAR(20),
    channel VARCHAR(20),
    fraud_flag BIT DEFAULT 0,
    reversal_flag BIT DEFAULT 0,
    failure_reason VARCHAR(100),

    -- Foreign key relationships
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id),
    FOREIGN KEY (merchant_id) REFERENCES merchant_info(merchant_id),
    FOREIGN KEY (device_id) REFERENCES device_info(device_id),
    FOREIGN KEY (upi_id) REFERENCES upi_account_details(upi_id)
);

-- Fraud alerts generated for suspicious transactions
CREATE TABLE fraud_alert_history (
    alert_id VARCHAR(20) PRIMARY KEY,
    transaction_id VARCHAR(20) NOT NULL,
    alert_type VARCHAR(50),
    alert_date DATETIME2,                   
    resolved BIT DEFAULT 0,
    resolution_date DATETIME2,              
    remarks VARCHAR(100),
    FOREIGN KEY (transaction_id) REFERENCES upi_transaction_history(transaction_id)
);

-- Customer feedback and issue records
CREATE TABLE customer_feedback (
    feedback_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    date_submitted DATE,
    feedback_text VARCHAR(100),
    satisfaction_score INT CHECK(satisfaction_score BETWEEN 1 AND 5),
    issue_type VARCHAR(20),
    resolved BIT DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);


-- 1. customer_master
INSERT INTO dbo.customer_master
SELECT
    customer_id,
    full_name,
    TRY_CAST(age AS INT),
    gender,
    region,
    TRY_CAST(date_joined AS DATE),
    CASE WHEN LOWER(is_business_user) IN ('1','true','yes') THEN 1 ELSE 0 END,
    TRY_CAST(risk_score AS DECIMAL(5,2)),
    mobile_number
FROM dbo.customer_master_stg
WHERE customer_id IS NOT NULL;
SELECT 'customer_master' AS table_name, COUNT(*) AS rows FROM dbo.customer_master;


-- 2. merchant_info
INSERT INTO dbo.merchant_info
SELECT
    merchant_id,
    merchant_name,
    merchant_type,
    region,
    TRY_CAST(onboard_date AS DATE),
    TRY_CAST(risk_score AS DECIMAL(5,2))
FROM dbo.merchant_info_stg
WHERE merchant_id IS NOT NULL;
SELECT 'merchant_info' AS table_name, COUNT(*) AS rows FROM dbo.merchant_info;


  -- 3. device_info
INSERT INTO dbo.device_info
SELECT
    device_id,
    customer_id,
    device_type,
    app_version,
    CASE WHEN LOWER(is_rooted) IN ('1','true','yes') THEN 1 ELSE 0 END,
    TRY_CAST(last_active AS DATETIME2)
FROM dbo.device_info_stg
WHERE device_id IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM dbo.customer_master);
SELECT 'device_info' AS table_name, COUNT(*) AS rows FROM dbo.device_info;


-- 4. upi_account_details
INSERT INTO dbo.upi_account_details
SELECT
    upi_id,
    customer_id,
    bank_name,
    account_type,
    TRY_CAST(date_added AS DATE),
    status
FROM dbo.upi_account_details_stg
WHERE upi_id IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM dbo.customer_master);
SELECT 'upi_account_details' AS table_name, COUNT(*) AS rows FROM dbo.upi_account_details;


-- 5. upi_transaction_history
INSERT INTO dbo.upi_transaction_history
SELECT
    t.transaction_id,
    t.upi_id,
    t.customer_id,
    TRY_CAST(t.timestamp AS DATETIME2),
    TRY_CAST(t.amount AS DECIMAL(12,2)),
    t.transaction_type,
    CASE WHEN t.merchant_id IN (SELECT merchant_id FROM dbo.merchant_info)
         THEN t.merchant_id ELSE NULL END,
    t.counterparty_upi,
    t.status,
    CASE WHEN t.device_id IN (SELECT device_id FROM dbo.device_info)
         THEN t.device_id ELSE NULL END,
    t.device_type,
    t.channel,
    CASE WHEN LOWER(t.fraud_flag) IN ('1','true','yes') THEN 1 ELSE 0 END,
    CASE WHEN LOWER(t.reversal_flag) IN ('1','true','yes') THEN 1 ELSE 0 END,
    t.failure_reason
FROM dbo.upi_transaction_history_stg t
WHERE t.transaction_id IS NOT NULL
  AND t.transaction_id NOT IN (SELECT transaction_id FROM dbo.upi_transaction_history);
SELECT 'upi_transaction_history' AS table_name, COUNT(*) AS rows FROM dbo.upi_transaction_history;


-- 6. fraud_alert_history
INSERT INTO dbo.fraud_alert_history
SELECT
    alert_id,
    transaction_id,
    alert_type,
    TRY_CAST(alert_date AS DATETIME2),
    CASE WHEN LOWER(resolved) IN ('1','true','yes') THEN 1 ELSE 0 END,
    TRY_CAST(resolution_date AS DATETIME2),
    remarks
FROM dbo.fraud_alert_history_stg
WHERE alert_id IS NOT NULL
  AND transaction_id IN (SELECT transaction_id FROM dbo.upi_transaction_history);
SELECT 'fraud_alert_history' AS table_name, COUNT(*) AS rows FROM dbo.fraud_alert_history;


-- 7. customer_feedback
INSERT INTO dbo.customer_feedback
SELECT
    feedback_id,
    customer_id,
    TRY_CAST(date_submitted AS DATE),
    feedback_text,
    TRY_CAST(satisfaction_score AS INT),
    issue_type,
    CASE WHEN LOWER(resolved) IN ('1','true','yes') THEN 1 ELSE 0 END
FROM dbo.customer_feedback_stg
WHERE feedback_id IS NOT NULL
  AND customer_id IN (SELECT customer_id FROM dbo.customer_master);
SELECT 'customer_feedback' AS table_name, COUNT(*) AS rows FROM dbo.customer_feedback;


-- View data from all main tables
SELECT * FROM customer_feedback     
SELECT * FROM customer_master       
SELECT * FROM device_info
SELECT * FROM fraud_alert_history
SELECT * FROM merchant_info         
SELECT * FROM upi_account_details   
SELECT * FROM upi_transaction_history


-- Find minimum and maximum customer age
SELECT 
    MIN(age) AS min_age, 
    MAX(age) AS max_age 
FROM customer_master;


-- Find minimum and maximum transaction amount
SELECT 
    MIN(amount) AS min_amount, 
    MAX(amount) AS max_amount
FROM upi_transaction_history;


-- Find merchant risk score range
SELECT 
    MIN(risk_score) AS min_risk_score, 
    MAX(risk_score) AS max_risk_score
FROM merchant_info;


-- Find customer risk score range
SELECT 
    MIN(risk_score) AS min_risk_score, 
    MAX(risk_score) AS max_risk_score
FROM customer_master;


-- Remove old age constraint if exists
ALTER TABLE dbo.customer_master
DROP CONSTRAINT IF EXISTS CK__customer__age;


-- Add age validation constraint
ALTER TABLE dbo.customer_master
ADD CONSTRAINT chk_customer_age 
CHECK(age >= 18);


-- Add customer risk score validation
ALTER TABLE dbo.customer_master
ADD CONSTRAINT chk_customer_risk 
CHECK(risk_score BETWEEN 0 AND 1);


-- Add merchant risk score validation
ALTER TABLE dbo.merchant_info
ADD CONSTRAINT chk_merchant_risk 
CHECK(risk_score BETWEEN 0 AND 1);


-- Drop system-generated age constraint
ALTER TABLE dbo.customer_master
DROP CONSTRAINT CK__customer_ma__age__5DCAEF64;


-- View all check constraints in database
SELECT 
    t.name AS table_name,
    cc.name AS constraint_name,
    cc.definition
FROM sys.check_constraints cc
JOIN sys.tables t 
    ON cc.parent_object_id = t.object_id
ORDER BY t.name;


-- Find customers with invalid mobile number length
SELECT * 
FROM customer_master
WHERE LEN(mobile_number) < 10 
ORDER BY LEN(mobile_number);


-- Create index for faster customer transaction searches
CREATE INDEX idx_customer_time
ON dbo.upi_transaction_history(customer_id, timestamp);

-- Create index for merchant-based transaction analysis
CREATE INDEX idx_merchant_time
ON dbo.upi_transaction_history(merchant_id, timestamp);

-- Create index for fraud-related queries
CREATE INDEX idx_fraud_time
ON dbo.upi_transaction_history(fraud_flag, timestamp);

-- Create index for fraud alert transaction lookup
CREATE INDEX idx_alert_transaction
ON dbo.fraud_alert_history(transaction_id);

-- Create index for customer feedback lookup
CREATE INDEX idx_feedback_customer
ON dbo.customer_feedback(customer_id);


-- View all non-primary indexes and indexed columns
SELECT
    t.name AS table_name,
    i.name AS index_name,
    STRING_AGG(c.name, ', ') AS columns
FROM sys.indexes i
JOIN sys.tables t 
    ON i.object_id = t.object_id
JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
JOIN sys.columns c 
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE i.is_primary_key = 0
  AND t.name IN (
    'upi_transaction_history',
    'fraud_alert_history',
    'customer_feedback'
  )
GROUP BY t.name, i.name
ORDER BY t.name, i.name;


-- Check all tables have correct row counts
SELECT 'customer_master'          AS table_name, COUNT(*) AS rows FROM dbo.customer_master
UNION ALL
SELECT 'merchant_info',            COUNT(*) FROM dbo.merchant_info
UNION ALL
SELECT 'device_info',              COUNT(*) FROM dbo.device_info
UNION ALL
SELECT 'upi_account_details',      COUNT(*) FROM dbo.upi_account_details
UNION ALL
SELECT 'upi_transaction_history',  COUNT(*) FROM dbo.upi_transaction_history
UNION ALL
SELECT 'fraud_alert_history',      COUNT(*) FROM dbo.fraud_alert_history
UNION ALL
SELECT 'customer_feedback',        COUNT(*) FROM dbo.customer_feedback;


-- Check sample data
SELECT TOP 5 * FROM dbo.fraud_alert_history;


-- Check date range
SELECT 
    MIN(alert_date) AS earliest_alert,
    MAX(alert_date) AS latest_alert,
    COUNT(*) AS total_rows
FROM dbo.fraud_alert_history;


-- Check no duplicates
SELECT alert_id, COUNT(*) AS cnt
FROM dbo.fraud_alert_history
GROUP BY alert_id
HAVING COUNT(*) > 1;


-- Set resolution_date as NULL for unresolved fraud alerts
UPDATE dbo.fraud_alert_history
SET resolution_date = NULL
WHERE resolved = 0
  AND resolution_date IS NOT NULL;


-- Verify unresolved alerts after update
SELECT TOP 5 
    resolved, 
    resolution_date 
FROM dbo.fraud_alert_history
WHERE resolved = 0;


-- See the invalid mobile numbers
SELECT customer_id, mobile_number, LEN(mobile_number) AS length
FROM dbo.customer_master
WHERE LEN(mobile_number) < 10
ORDER BY LEN(mobile_number);


-- Count breakdown by length
SELECT LEN(mobile_number) AS length, COUNT(*) AS count
FROM dbo.customer_master
WHERE LEN(mobile_number) < 10
GROUP BY LEN(mobile_number)
ORDER BY length;


-- Create view with mobile validation only
GO
CREATE VIEW vw_clean_customer AS
SELECT
    customer_id,
    full_name,
    age,
    gender,
    region,
    date_joined,
    is_business_user,
    risk_score,
    mobile_number,
    CASE WHEN LEN(mobile_number) = 10 THEN 'Valid'
         ELSE 'Invalid' END AS mobile_status
FROM dbo.customer_master;
GO

-- Verify
SELECT mobile_status, COUNT(*) AS count
FROM vw_clean_customer
GROUP BY mobile_status;


-- Use only valid mobile customers in analysis
SELECT *
FROM vw_clean_customer
WHERE mobile_status = 'Valid';


-- Check how many have quotes
SELECT COUNT(*) AS quoted_names
FROM dbo.merchant_info
WHERE merchant_name LIKE '"%"';


-- Preview before fixing
SELECT merchant_id,
       merchant_name,
       REPLACE(merchant_name, '"', '') AS cleaned_name
FROM dbo.merchant_info
WHERE merchant_name LIKE '"%"';


-- Fix by removing quotes
UPDATE dbo.merchant_info
SET merchant_name = REPLACE(merchant_name, '"', '')
WHERE merchant_name LIKE '"%"';


--Verify fix
SELECT merchant_name FROM dbo.merchant_info
ORDER BY merchant_name;


-- Find duplicate merchant names
SELECT merchant_name, COUNT(*) AS count
FROM dbo.merchant_info
GROUP BY merchant_name
HAVING COUNT(*) > 1
ORDER BY count DESC;

SELECT * FROM dbo.merchant_info
WHERE merchant_name IN ('Brown Inc', 'Jackson Group', 
                        'Johnson Inc', 'Ortiz and Sons',
                        'Williams Group')
ORDER BY merchant_name;


-- Confirm no true duplicates exist
SELECT merchant_name, merchant_type, region, COUNT(*) AS count
FROM dbo.merchant_info
GROUP BY merchant_name, merchant_type, region
HAVING COUNT(*) > 1;




-- =========================================================
               --SQL Analysis starts here
-- =========================================================

--1️. Data Validation

-- Row counts
SELECT 'vw_clean_customer'        AS table_name, COUNT(*) AS rows FROM vw_clean_customer
UNION ALL
SELECT 'merchant_info',            COUNT(*) FROM dbo.merchant_info
UNION ALL
SELECT 'device_info',              COUNT(*) FROM dbo.device_info
UNION ALL
SELECT 'upi_account_details',      COUNT(*) FROM dbo.upi_account_details
UNION ALL
SELECT 'upi_transaction_history',  COUNT(*) FROM dbo.upi_transaction_history
UNION ALL
SELECT 'fraud_alert_history',      COUNT(*) FROM dbo.fraud_alert_history
UNION ALL
SELECT 'customer_feedback',        COUNT(*) FROM dbo.customer_feedback;


-- NULL check
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)         AS null_amount,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END)         AS null_status,
    SUM(CASE WHEN fraud_flag IS NULL THEN 1 ELSE 0 END)     AS null_fraud_flag,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)    AS null_customer_id,
    SUM(CASE WHEN merchant_id IS NULL THEN 1 ELSE 0 END)    AS null_merchant_id
FROM dbo.upi_transaction_history;


--2️. EDA

-- Status distribution with percentage
SELECT
    status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount
FROM dbo.upi_transaction_history
GROUP BY status
ORDER BY count DESC;


-- Transaction type
SELECT
    transaction_type,
    COUNT(*) AS count,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM dbo.upi_transaction_history
GROUP BY transaction_type
ORDER BY count DESC;


-- Monthly trend
SELECT
    YEAR(timestamp) AS year,
    MONTH(timestamp) AS month,
    COUNT(*) AS total_txn,
    ROUND(SUM(amount), 2) AS total_amount,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_count
FROM dbo.upi_transaction_history
GROUP BY YEAR(timestamp), MONTH(timestamp)
ORDER BY year, month;


-- Channel and device
SELECT
    channel,
    device_type,
    COUNT(*) AS txn_count,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history
GROUP BY channel, device_type
ORDER BY txn_count DESC;


--3️. Core KPIs

-- KPI Summary
SELECT
    COUNT(*) AS total_txn,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS failure_rate_pct,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN reversal_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS reversal_rate_pct
FROM dbo.upi_transaction_history;


-- Top 10 customers by spending
SELECT TOP 10
    c.customer_id,
    c.full_name,
    c.region,
    COUNT(t.transaction_id) AS total_txn,
    ROUND(SUM(t.amount), 2) AS total_spent,
    ROUND(AVG(t.amount), 2) AS avg_amount,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM vw_clean_customer c
JOIN dbo.upi_transaction_history t ON c.customer_id = t.customer_id
WHERE c.mobile_status = 'Valid'
GROUP BY c.customer_id, c.full_name, c.region
ORDER BY total_spent DESC;


--4️. Fraud Analysis

-- Fraud by region with rate
SELECT
    c.region,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_txn,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history t
JOIN vw_clean_customer c ON t.customer_id = c.customer_id
GROUP BY c.region
ORDER BY fraud_rate_pct DESC;


-- Fraud by channel
SELECT
    channel,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_txn,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history
GROUP BY channel
ORDER BY fraud_rate_pct DESC;


-- Fraud by device type
SELECT
    d.device_type,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_txn,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history t
JOIN dbo.device_info d ON t.device_id = d.device_id
GROUP BY d.device_type
ORDER BY fraud_rate_pct DESC;


-- Rooted device fraud
SELECT
    d.is_rooted,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_txn,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct,
    ROUND(AVG(t.amount), 2) AS avg_amount
FROM dbo.device_info d
JOIN dbo.upi_transaction_history t ON d.device_id = t.device_id
GROUP BY d.is_rooted;


-- High risk customers
SELECT
    c.customer_id,
    c.full_name,
    c.region,
    c.risk_score,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM dbo.upi_transaction_history t
JOIN vw_clean_customer c ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.region, c.risk_score
HAVING SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) > 1
ORDER BY fraud_count DESC;


-- Fraud alert resolution
SELECT
    alert_type,
    COUNT(*) AS total_alerts,
    SUM(CASE WHEN resolved = 1 THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN resolved = 0 THEN 1 ELSE 0 END) AS unresolved,
    ROUND(SUM(CASE WHEN resolved = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS resolution_rate_pct,
    ROUND(AVG(CASE WHEN resolved = 1
              THEN DATEDIFF(HOUR, alert_date, resolution_date)
              END), 1) AS avg_resolution_hours
FROM dbo.fraud_alert_history
GROUP BY alert_type
ORDER BY total_alerts DESC;


--5️. Failure Analysis

-- Failure reasons
SELECT
    failure_reason,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM dbo.upi_transaction_history
WHERE status = 'Failed'
GROUP BY failure_reason
ORDER BY count DESC;


-- Failure by channel
SELECT
    channel,
    COUNT(*) AS total,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed,
    ROUND(SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS failure_rate_pct
FROM dbo.upi_transaction_history
GROUP BY channel
ORDER BY failure_rate_pct DESC;


-- Failure by device
SELECT
    device_type,
    COUNT(*) as total,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed,
    ROUND(SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / 
          COUNT(*),2) as failure_rate_pct
FROM dbo.upi_transaction_history
GROUP BY device_type
ORDER BY failure_rate_pct DESC;


--6️. Business Insights

-- Top 10 merchants by revenue
SELECT TOP 10
    m.merchant_name,
    m.merchant_type,
    m.region,
    COUNT(t.transaction_id) AS total_txn,
    ROUND(SUM(t.amount), 2) AS revenue,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history t
JOIN dbo.merchant_info m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name, m.merchant_type, m.region
ORDER BY revenue DESC;


-- Merchant performance by type
SELECT
    m.merchant_type,
    COUNT(DISTINCT m.merchant_id) AS merchant_count,
    COUNT(t.transaction_id) AS total_txn,
    ROUND(SUM(t.amount), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN t.status = 'Failed' THEN 1 ELSE 0 END) * 100.0 /
          NULLIF(COUNT(t.transaction_id), 0), 2) AS failure_rate_pct,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          NULLIF(COUNT(t.transaction_id), 0), 2) AS fraud_rate_pct
FROM dbo.merchant_info m
LEFT JOIN dbo.upi_transaction_history t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_type
ORDER BY total_revenue DESC;


-- Customer risk segmentation
SELECT
    CASE
        WHEN risk_score < 0.3 THEN 'Low Risk'
        WHEN risk_score < 0.7 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_category,
    COUNT(*) AS customers,
    ROUND(AVG(risk_score), 4) AS avg_risk_score,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM vw_clean_customer
GROUP BY
    CASE
        WHEN risk_score < 0.3 THEN 'Low Risk'
        WHEN risk_score < 0.7 THEN 'Medium Risk'
        ELSE 'High Risk'
    END
ORDER BY avg_risk_score;


-- Customer 360 view
SELECT TOP 20
    c.customer_id,
    c.full_name,
    c.region,
    c.risk_score,
    COUNT(DISTINCT d.device_id)          AS total_devices,
    COUNT(DISTINCT u.upi_id)             AS total_upi_accounts,
    COUNT(DISTINCT t.transaction_id)     AS total_transactions,
    ROUND(SUM(t.amount), 2)              AS total_spent,
    SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(AVG(CAST(f.satisfaction_score AS FLOAT)), 2) AS avg_satisfaction
FROM vw_clean_customer c
LEFT JOIN dbo.device_info d              ON c.customer_id = d.customer_id
LEFT JOIN dbo.upi_account_details u      ON c.customer_id = u.customer_id
LEFT JOIN dbo.upi_transaction_history t  ON c.customer_id = t.customer_id
LEFT JOIN dbo.customer_feedback f        ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.full_name, c.region, c.risk_score
ORDER BY total_spent DESC;


--7. Advanced SQL

-- CTE + LAG (Month over month growth)
WITH monthly AS (
    SELECT
        YEAR(timestamp) AS yr,
        MONTH(timestamp) AS mn,
        COUNT(*) AS txn_count,
        ROUND(SUM(amount), 2) AS total_amount
    FROM dbo.upi_transaction_history
    GROUP BY YEAR(timestamp), MONTH(timestamp)
)
SELECT
    yr, mn,
    txn_count,
    total_amount,
    LAG(total_amount) OVER (ORDER BY yr, mn) AS prev_month,
    ROUND((total_amount - LAG(total_amount) OVER (ORDER BY yr, mn)) * 100.0 /
          NULLIF(LAG(total_amount) OVER (ORDER BY yr, mn), 0), 2) AS growth_pct
FROM monthly
ORDER BY yr, mn;


-- Window function (Rank customers)
SELECT
    customer_id,
    ROUND(SUM(amount), 2) AS total_spent,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS spending_rank
FROM dbo.upi_transaction_history
GROUP BY customer_id;


-- Subquery (above average transactions)
SELECT
    transaction_id,
    customer_id,
    ROUND(amount, 2) AS amount,
    status,
    fraud_flag
FROM dbo.upi_transaction_history
WHERE amount > (SELECT AVG(amount) FROM dbo.upi_transaction_history)
ORDER BY amount DESC;


-- Transaction categorization
SELECT
    CASE
        WHEN amount < 100 THEN 'Low (< 100)'
        WHEN amount BETWEEN 100 AND 500 THEN 'Medium (100-500)'
        ELSE 'High (> 500)'
    END AS value_category,
    COUNT(*) AS txn_count,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.upi_transaction_history
GROUP BY
    CASE
        WHEN amount < 100 THEN 'Low (< 100)'
        WHEN amount BETWEEN 100 AND 500 THEN 'Medium (100-500)'
        ELSE 'High (> 500)'
    END
ORDER BY avg_amount;


--8. Interview Bonus

-- Customers with no transactions
SELECT
    c.customer_id,
    c.full_name,
    c.region
FROM vw_clean_customer c
LEFT JOIN dbo.upi_transaction_history t ON c.customer_id = t.customer_id
WHERE t.transaction_id IS NULL;


-- Merchants with fraud rate above average
SELECT
    m.merchant_name,
    m.merchant_type,
    COUNT(*) AS total_txn,
    ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
          COUNT(*), 2) AS fraud_rate_pct
FROM dbo.merchant_info m
JOIN dbo.upi_transaction_history t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_name, m.merchant_type
HAVING ROUND(SUM(CASE WHEN t.fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
             COUNT(*), 2) >
       (SELECT ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
                     COUNT(*), 2)
        FROM dbo.upi_transaction_history)
ORDER BY fraud_rate_pct DESC;


-- Recent fraud customers last 3 months
SELECT DISTINCT
    c.customer_id,
    c.full_name,
    c.region,
    c.risk_score
FROM vw_clean_customer c
JOIN dbo.upi_transaction_history t ON c.customer_id = t.customer_id
WHERE t.fraud_flag = 1
  AND t.timestamp >= DATEADD(MONTH, -12, GETDATE())
ORDER BY c.risk_score DESC;