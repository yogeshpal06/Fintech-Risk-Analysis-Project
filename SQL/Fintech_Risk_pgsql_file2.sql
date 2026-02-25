CREATE DATABSE Fintech_Risk_Analysis_Data;

Create TABLE Fintech_Application (
	sk_id_curr        INT PRIMARY KEY,
    target            INT,
    name_contract_type VARCHAR(50),
    code_gender        VARCHAR(10),
    cnt_children       INT,
    amt_income_total   NUMERIC(15,2),
    amt_credit         NUMERIC(15,2),
    amt_annuity        NUMERIC(15,2)
);

SELECT * FROM Fintech_Application;

COPY fintech_application
FROM 'file path :-application_train_clean.csv'
DELIMITER ','
CSV HEADER;


CREATE TABLE fintech_feature_base AS
SELECT
    sk_id_curr,
    target,
    name_contract_type,
    code_gender,
    cnt_children,
    amt_income_total,
    amt_credit,
    amt_annuity,

    -- Business feature: loan to income ratio
    CASE 
        WHEN amt_income_total = 0 THEN NULL
        ELSE amt_credit / amt_income_total
    END AS loan_to_income_ratio

FROM fintech_application;

SELECT loan_to_income_ratio
FROM fintech_feature_base;

ALTER TABLE fintech_feature_base
ALTER COLUMN loan_to_income_ratio
TYPE NUMERIC(10,2);


CREATE TABLE fintech_segment_base AS
SELECT *,

		CASE
			WHEN cnt_children = 0 THEN 'Low'
			WHEN cnt_children <= 2 THEN 'Medium'
			ELSE 'High'
		END AS dependency_segment,

		CASE 
			WHEN amt_income_total < 100000 THEN 'Low Income'
			WHEN amt_income_total < 300000 THEn 'Mid Income'
			ELSE 'High Income'
		END AS income_segment

FROM fintech_feature_base;

SELECT COUNT(*) FROM fintech_segment_base;

SELECT cnt_children, dependency_segment, amt_income_total, income_segment
FROM fintech_segment_base;


-- Finding which income segment has highest default risk

SELECT income_segment,COUNT(*) AS total_customers,AVG(target) AS default_rate
FROM fintech_segment_base
GROUP BY income_segment
ORDER BY default_rate DESC;

-- finding the dependency risk

SELECT dependency_segment,COUNT(*) AS customers,AVG(target) AS default_rate
FROM fintech_segment_base
GROUP BY dependency_segment
ORDER BY default_rate DESC;

-- combining income and dependency risk

SELECT income_segment,dependency_segment,
	COUNT (*) AS customers,AVG(target) AS default_rate
FROM fintech_segment_base
GROUP BY income_segment,dependency_segment
ORDER BY default_rate DESC;

-- now loading other 2 csv files
-- loading previous application into a temp. table

CREATE TABLE temp_previous_application (
    sk_id_prev INT,
    sk_id_curr INT,
    name_contract_type TEXT,
    amt_annuity NUMERIC,
    amt_application NUMERIC,
    amt_credit NUMERIC,
    amt_down_payment NUMERIC,
    amt_goods_price NUMERIC,
    weekday_appr_process_start TEXT,
    hour_appr_process_start INT,
    flag_last_appl_per_contract TEXT,
    nflag_last_appl_in_day INT,
    rate_down_payment NUMERIC,
    rate_interest_primary NUMERIC,
    rate_interest_privileged NUMERIC,
    name_cash_loan_purpose TEXT,
    name_contract_status TEXT,
    days_decision INT,
    name_payment_type TEXT,
    code_reject_reason TEXT,
    name_type_suite TEXT,
    name_client_type TEXT,
    name_goods_category TEXT,
    name_portfolio TEXT,
    name_product_type TEXT,
    channel_type TEXT,
    sellerplace_area INT,
    name_seller_industry TEXT,
    cnt_payment NUMERIC,
    name_yield_group TEXT,
    product_combination TEXT,
    days_first_drawing NUMERIC,
    days_first_due NUMERIC,
    days_last_due_1st_version NUMERIC,
    days_last_due NUMERIC,
    days_termination NUMERIC,
    nflag_insured_on_approval NUMERIC
);

COPY temp_previous_application
FROM 'file path :- previous_application (Original file).csv'
DELIMITER ','
CSV HEADER;


SELECT COUNT(*) FROM temp_previous_application;

-- loading file installation payment into tem file.

CREATE TABLE temp_installments_payments (
	sk_id_prev INT,
    sk_id_curr INT,
    num_instalment_version NUMERIC,
    num_instalment_number NUMERIC,
    days_instalment NUMERIC,
    days_entry_payment NUMERIC,
    amt_instalment NUMERIC,
    amt_payment NUMERIC
);

COPY temp_installments_payments
FROM 'file path :-installments_payments (Original file).csv'
DELIMITER ','
CSV HEADER;

SELECT COUNT(*) FROM temp_installments_payments;

-- Now creating base table of these 2 files
-- Base table for file 1 previous application

CREATE TABLE previous_application_base AS
SELECT sk_id_curr,
		COUNT(*) AS total_previous_loans,
		AVG(amt_credit) AS avg_previous_credit,
		SUM(
			CASE 
				WHEN name_contract_status = 'Approved' THEN 1
				ELSE 0
			END
		) AS approved_previous_loans

FROM temp_previous_application
GROUP BY sk_id_curr;

SELECT COUNT(*) FROM previous_application_base;


-- base table for file 2 installment payments

CREATE TABLE installments_payments_base AS
SELECT sk_id_curr,
		COUNT(*) AS total_installments,
		AVG(amt_payment/NULLIF(amt_instalment,0)) AS avg_payment_ratio,
		AVG(days_entry_payment - days_instalment) AS avg_delay_days

FROM temp_installments_payments
GROUP BY sk_id_curr;

SELECT COUNT(*) FROM installments_payments_base;

-- Now joining all three base table into 1 master table

CREATE TABLE fintech_underwriting_master AS
SELECT f.*,
		p.total_previous_loans,
		p.avg_previous_credit,
		p.approved_previous_loans,

		i.total_installments,
		i.avg_payment_ratio,
		i.avg_delay_days

FROM fintech_segment_base f

LEFT JOIN previous_application_base p
ON f.sk_id_curr = p.sk_id_curr

LEFT JOIN installments_payments_base i
ON f.sk_id_curr = i.sk_id_curr;


SELECT count(*) from fintech_underwriting_master;

-- Now creating FINTECH KPI's to asses behavioural risk
-- 1st KPI Payment Delay VS Default Risk

SELECT
	CASE
		WHEN avg_delay_days IS NULL THEN 'No History'
		WHEN avg_delay_days <= 0 THEN 'On Time'
		WHEN avg_delay_days <= 10 THEN 'Slight Delay'
		ELSE 'High Delay'
	END AS delay_group,

	COUNT(*) AS customers,
	AVG(target) AS default_rate

FROM fintech_underwriting_master
GROUP BY delay_group
ORDER BY default_rate DESC;


--2nd KPI Previous Loan VS Risk

SELECT
	CASE
		WHEN total_previous_loans IS NULL THEN 'No Previous Loan'
		WHEN total_previous_loans <= 2 THEN 'Few Loans'
		ELSE 'Many Loans'
	END AS loan_history_group,

	Count(*) AS customers,
	AVG(target) AS default_rate

FROM fintech_underwriting_master
GROUP BY loan_history_group
ORDER BY default_rate DESC;

-- Now adding delay group and loan history group finding into a column in master table

ALTER TABLE fintech_underwriting_master
ADD COLUMN delay_group TEXT,
ADD COLUMN loan_history_group TEXT;

-- now adding data in above created new columns

UPDATE fintech_underwriting_master
SET delay_group =
				CASE
					WHEN avg_delay_days IS NULL THEN 'No History'
					WHEN avg_delay_days <= 0 THEN 'On Time'
					WHEN avg_delay_days <= 10 THEN 'Slight Delay'
					ELSE 'High Delay'
				END,
	loan_history_group = 
				CASE
					WHEN total_previous_loans IS NULL THEN 'No Previous Loans'
					WHEN total_previous_loans <= 2 THEN 'Few Loans'
					ELSE 'Many Loans'
				END;

