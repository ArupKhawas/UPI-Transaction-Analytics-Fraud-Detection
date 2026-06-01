# Data Dictionary

## customer_master

| Column | Description |
|----------|----------|
| customer_id | Unique customer identifier |
| customer_name | Customer full name |
| gender | Customer gender |
| age | Customer age |
| region | Customer region |
| risk_score | Customer risk score |
| join_date | Customer registration date |

---

## merchant_info

| Column | Description |
|----------|----------|
| merchant_id | Unique merchant identifier |
| merchant_name | Merchant name |
| merchant_category | Merchant category |
| region | Merchant region |
| risk_score | Merchant risk score |

---

## device_info

| Column | Description |
|----------|----------|
| device_id | Unique device identifier |
| device_type | Android / iOS |
| is_rooted | Rooted device flag |
| app_version | App version |

---

## upi_transaction_history

| Column | Description |
|----------|----------|
| transaction_id | Unique transaction ID |
| customer_id | Customer reference |
| merchant_id | Merchant reference |
| amount | Transaction amount |
| transaction_type | Send / Receive / Merchant |
| channel | QR / UPI ID / Mobile |
| status | Success / Failed |
| fraud_flag | Fraud indicator |
| timestamp | Transaction timestamp |

---

## fraud_alert_history

| Column | Description |
|----------|----------|
| alert_id | Fraud alert ID |
| transaction_id | Linked transaction |
| alert_type | Fraud category |
| resolution_status | Alert resolution status |

---

## customer_feedback

| Column | Description |
|----------|----------|
| feedback_id | Feedback identifier |
| customer_id | Customer reference |
| satisfaction_score | Rating 1-5 |
| issue_type | Complaint category |
| resolution_status | Resolution status |