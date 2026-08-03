DROP DATABASE IF EXISTS healthcare_revenue_cycle;

CREATE DATABASE healthcare_revenue_cycle;

USE healthcare_revenue_cycle;


CREATE TABLE claims
(
  claim_id              INT           NOT NULL,
  patient_id            INT           NOT NULL,
  provider_id           INT           NOT NULL,
  insurance_plan_id     INT           NOT NULL,
  service_date          DATE          NOT NULL,
  claim_submission_date DATE          NOT NULL,
  procedure_code        VARCHAR(10)   NOT NULL,
  diagnosis_code        VARCHAR(10)   NOT NULL,
  billed_amount         DECIMAL(10,2) NOT NULL,
  allowed_amount        DECIMAL(10,2) NOT NULL,
  claim_status          VARCHAR(30)   NOT NULL,
  denial_reason         VARCHAR(150)  NULL    ,
  PRIMARY KEY (claim_id)
);

CREATE TABLE insurance_plans
(
  insurance_plan_id INT          NOT NULL AUTO_INCREMENT,
  payer_name        VARCHAR(100) NOT NULL,
  plan_name         VARCHAR(100) NOT NULL,
  plan_type         VARCHAR(30)  NOT NULL,
  active_status     VARCHAR(20)  NOT NULL,
  PRIMARY KEY (insurance_plan_id)
);

CREATE TABLE patients
(
  patient_id        INT         NOT NULL AUTO_INCREMENT,
  first_name        VARCHAR(50) NOT NULL,
  last_name         VARCHAR(50) NOT NULL,
  date_of_birth     DATE        NOT NULL,
  gender            VARCHAR(20) NULL    ,
  state             CHAR(2)     NULL    ,
  insurance_plan_id INT         NULL    ,
  PRIMARY KEY (patient_id)
);

CREATE TABLE payments
(
  payment_id             INT           NOT NULL AUTO_INCREMENT,
  claim_id               INT           NOT NULL,
  payment_date           DATE          NOT NULL,
  payer_payment          DECIMAL(10,2) NOT NULL DEFAULT 0,
  patient_responsibility DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_status         VARCHAR(30)   NOT NULL,
  adjustment_amount      DECIMAL(10,2) NULL     DEFAULT 0,
  PRIMARY KEY (payment_id)
);

CREATE TABLE providers
(
  provider_id   INT          NOT NULL AUTO_INCREMENT,
  provider_name VARCHAR(100) NOT NULL,
  specialty     VARCHAR(100) NOT NULL,
  npi_number    VARCHAR(10)  NOT NULL,
  facility_name VARCHAR(100) NULL    ,
  state         CHAR(2)      NULL    ,
  PRIMARY KEY (provider_id)
);

ALTER TABLE providers
  ADD CONSTRAINT UQ_npi_number UNIQUE (npi_number);

ALTER TABLE patients
  ADD CONSTRAINT FK_insurance_plans_TO_patients
    FOREIGN KEY (insurance_plan_id)
    REFERENCES insurance_plans (insurance_plan_id);

ALTER TABLE claims
  ADD CONSTRAINT FK_insurance_plans_TO_claims
    FOREIGN KEY (insurance_plan_id)
    REFERENCES insurance_plans (insurance_plan_id);

ALTER TABLE payments
  ADD CONSTRAINT FK_claims_TO_payments
    FOREIGN KEY (claim_id)
    REFERENCES claims (claim_id);

ALTER TABLE claims
  ADD CONSTRAINT FK_patients_TO_claims
    FOREIGN KEY (patient_id)
    REFERENCES patients (patient_id);

ALTER TABLE claims
  ADD CONSTRAINT FK_providers_TO_claims
    FOREIGN KEY (provider_id)
    REFERENCES providers (provider_id);
    
/* Insert data into tables and show each table */

INSERT INTO insurance_plans (
    insurance_plan_id,
    payer_name,
    plan_name,
    plan_type,
    active_status
)
VALUES
    (1, 'Horizon Blue Cross', 'Horizon Advantage', 'PPO', 'Active'),
    (2, 'UnitedHealthcare', 'Choice Plus', 'PPO', 'Active'),
    (3, 'Medicare', 'Medicare Part B', 'Medicare', 'Active');

SELECT * FROM insurance_plans;

INSERT INTO patients (
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    state,
    insurance_plan_id
)
VALUES
    (1, 'Maria', 'Lopez', '1982-04-17', 'Female', 'NJ', 1),
    (2, 'James', 'Carter', '1975-09-02', 'Male', 'NY', 2),
    (3, 'Aisha', 'Patel', '1990-12-11', 'Female', 'PA', 1),
    (4, 'Robert', 'Green', '1968-06-25', 'Male', 'NJ', 3),
    (5, 'Emily', 'Chen', '1988-03-14', 'Female', 'NY', 2);

SELECT * FROM patients;

INSERT INTO providers (
    provider_id,
    provider_name,
    specialty,
    npi_number,
    facility_name,
    state
)
VALUES
    (
        1,
        'Dr. Susan Miller',
        'Cardiology',
        '1234567890',
        'Northside Medical Center',
        'NJ'
    ),
    (
        2,
        'Dr. Daniel Kim',
        'Primary Care',
        '2345678901',
        'Metro Health Clinic',
        'NY'
    ),
    (
        3,
        'Dr. Rachel Evans',
        'Orthopedics',
        '3456789012',
        'Valley Specialty Group',
        'PA'
    );
    
SELECT * FROM providers;

INSERT INTO claims (
    claim_id,
    patient_id,
    provider_id,
    insurance_plan_id,
    service_date,
    claim_submission_date,
    procedure_code,
    diagnosis_code,
    billed_amount,
    allowed_amount,
    claim_status,
    denial_reason
)
VALUES
    (
        1001,
        1,
        1,
        1,
        '2026-06-01',
        '2026-06-03',
        '99214',
        'I10',
        300.00,
        220.00,
        'Paid',
        NULL
    ),
    (
        1002,
        2,
        2,
        2,
        '2026-06-05',
        '2026-06-06',
        '99213',
        'E11.9',
        180.00,
        135.00,
        'Paid',
        NULL
    ),
    (
        1003,
        3,
        3,
        1,
        '2026-06-08',
        '2026-06-10',
        '73560',
        'M25.561',
        450.00,
        320.00,
        'Denied',
        'Missing authorization'
    ),
    (
        1004,
        4,
        1,
        3,
        '2026-06-12',
        '2026-06-13',
        '93000',
        'I48.91',
        225.00,
        160.00,
        'Pending',
        NULL
    ),
    (
        1005,
        5,
        2,
        2,
        '2026-06-15',
        '2026-06-18',
        '99214',
        'J06.9',
        275.00,
        200.00,
        'Denied',
        'Invalid diagnosis code'
    ),
    (
        1006,
        1,
        1,
        1,
        '2026-06-20',
        '2026-06-21',
        '93306',
        'I10',
        800.00,
        600.00,
        'Paid',
        NULL
    );
SELECT * FROM claims;

INSERT INTO payments (
    payment_id,
    claim_id,
    payment_date,
    payer_payment,
    patient_responsibility,
    payment_status,
    adjustment_amount
)
VALUES
    (
        5001,
        1001,
        '2026-06-20',
        180.00,
        40.00,
        'Paid',
        80.00
    ),
    (
        5002,
        1002,
        '2026-06-22',
        110.00,
        25.00,
        'Paid',
        45.00
    ),
    (
        5003,
        1006,
        '2026-07-05',
        500.00,
        100.00,
        'Paid',
        200.00
    );

SELECT * FROM payments;

SHOW TABLES;

/*3. View the complete claims dataset using joins. First major relational query. */

SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    pr.provider_name,
    pr.specialty,
    ip.payer_name,
    ip.plan_name,
    c.service_date,
    c.procedure_code,
    c.diagnosis_code,
    c.billed_amount,
    c.allowed_amount,
    c.claim_status,
    c.denial_reason
FROM claims AS c
INNER JOIN patients AS p
    ON c.patient_id = p.patient_id
INNER JOIN providers AS pr
    ON c.provider_id = pr.provider_id
INNER JOIN insurance_plans AS ip
    ON c.insurance_plan_id = ip.insurance_plan_id
ORDER BY c.claim_id;

/* 4) Find denied claims*/
SELECT
    claim_id,
    patient_id,
    provider_id,
    billed_amount,
    allowed_amount,
    denial_reason
FROM claims
WHERE claim_status = 'Denied';

/* 5) Count claims via status */
SELECT
    claim_status,
    COUNT(*) AS claim_count
FROM claims
GROUP BY claim_status
ORDER BY claim_status;

/* 6) Calculate total billed and allowed amounts */
SELECT
	SUM(billed_amount) AS total_billed_amount,
	SUM(allowed_amount) AS total_allowed_amount
FROM claims;

/* 7) Calculate billed and allowed amounts by claim status */ 
SELECT
	claim_status,
	COUNT(*) AS claim_count,
	SUM(billed_amount) AS total_billed,
	SUM(allowed_amount) AS total_allowed,
	ROUND(AVG(billed_amount),2) AS average_billed
FROM claims
GROUP BY claim_status
ORDER BY claim_status;

/* 8) Calculate the denial rate percentage */
SELECT
	COUNT(*) AS total_claims,
	SUM(
		CASE
			WHEN claim_status = 'Denied' THEN 1 ELSE 0
		END
	) AS denied_claims,
	ROUND(
		100 * SUM(
			CASE
				WHEN claim_status = 'Denied' THEN 1 ELSE 0
			END
		) / COUNT(*),
		1 
		) AS denial_rate_percentage
	FROM claims;

/* 9) Compare billed and allowed amounts and the percentage of allowed amount is of billed amount  */
SELECT 
	claim_id,
	billed_amount,
	allowed_amount, 
	billed_amount - allowed_amount AS contractual_difference,
	ROUND(
		100.0 * allowed_amount / billed_amount,
		1
	) AS allowed_percentage
FROM claims
ORDER BY claim_id;

/* 10) Summarize claimis by payer name and total amount allowed */
SELECT
	ip.payer_name,
	COUNT(c.claim_id) AS claim_count,
	SUM(c.billed_amount) AS total_billed,
	SUM(c.allowed_amount) AS total_allowed,
	ROUND(AVG(c.allowed_amount),2) AS average_allowed
FROM claims AS c
INNER JOIN insurance_plans AS ip
	ON c.insurance_plan_id = ip.insurance_plan_id
GROUP BY ip.payer_name
ORDER BY total_allowed DESC;

/* 11) Summarize Claims by provider and total billed*/
SELECT
    pr.provider_name,
    pr.specialty,
    COUNT(c.claim_id) AS claim_count,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.allowed_amount) AS total_allowed
FROM claims AS c
INNER JOIN providers AS pr
    ON c.provider_id = pr.provider_id
GROUP BY
    pr.provider_id,
    pr.provider_name,
    pr.specialty
ORDER BY total_billed DESC;

/* 12) Confirm that each paid claim is financially balanced. The payer payment plus patient responsibility
should equal the allowed amount, while the adjustment should equal the difference between billed and allowed 
amounts.*/
SELECT
    c.claim_id,
    c.billed_amount,
    c.allowed_amount,
    pay.payer_payment,
    pay.patient_responsibility,
    pay.adjustment_amount,

    pay.payer_payment + pay.patient_responsibility
        AS total_reimbursement,

    c.allowed_amount
        - (pay.payer_payment + pay.patient_responsibility)
        AS allowed_balance,

    c.billed_amount - c.allowed_amount
        AS expected_adjustment,

    (c.billed_amount - c.allowed_amount)
        - pay.adjustment_amount
        AS adjustment_variance,

    CASE
        WHEN c.allowed_amount =
             pay.payer_payment + pay.patient_responsibility
         AND c.billed_amount - c.allowed_amount =
             pay.adjustment_amount
            THEN 'Fully reconciled'
        ELSE 'Reconciliation exception'
    END AS reconciliation_status

FROM claims AS c
INNER JOIN payments AS pay
    ON c.claim_id = pay.claim_id
WHERE c.claim_status = 'Paid'
ORDER BY c.claim_id; 

/* 13) Identify claims marked Paid that do not have a corresponding record in the payments table.*/
SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    c.allowed_amount,
    c.claim_status
FROM claims AS c
INNER JOIN patients AS p
    ON c.patient_id = p.patient_id
LEFT JOIN payments AS pay
    ON c.claim_id = pay.claim_id
WHERE c.claim_status = 'Paid'
  AND pay.payment_id IS NULL;
  
  /* 14) Find payments associated with nonpaid claims */
  SELECT
    pay.payment_id,
    pay.claim_id,
    c.claim_status,
    pay.payer_payment,
    pay.patient_responsibility,
    pay.adjustment_amount
FROM payments AS pay
INNER JOIN claims AS c
    ON pay.claim_id = c.claim_id
WHERE c.claim_status <> 'Paid';

/* 15) Identify denied claims that do not have a documented denial reason. */
SELECT
    claim_id,
    patient_id,
    provider_id,
    claim_status,
    denial_reason
FROM claims
WHERE claim_status = 'Denied'
  AND (
        denial_reason IS NULL
        OR TRIM(denial_reason) = ''
      );
      
  /* 16) Determine the number and financial value of claims associated with each denial reason */
SELECT
	denial_reason,
    COUNT(*) AS denied_claim_count,
    SUM(billed_amount) AS denied_billed_amount,
    SUM(allowed_amount) AS denied_allowed_amount
FROM claims
WHERE claim_status = 'Denied'
GROUP BY denial_reason
ORDER BY denied_billed_amount DESC;

/* 17) Measure the percentage of total billed charges associated with denied claims */
SELECT
    SUM(billed_amount) AS total_billed_amount,

    SUM(
        CASE
            WHEN claim_status = 'Denied'
                THEN billed_amount
            ELSE 0
        END
    ) AS denied_billed_amount,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN claim_status = 'Denied'
                    THEN billed_amount
                ELSE 0
            END
        ) / SUM(billed_amount),
        1
    ) AS denied_dollar_rate_percentage

FROM claims;

/* 18) Analyze claim-submission lag. Calculate the number of days between the service date and claim-submission date. */
SELECT
    claim_id,
    service_date,
    claim_submission_date,

    DATEDIFF(
        claim_submission_date,
        service_date
    ) AS submission_lag_days,

    CASE
        WHEN DATEDIFF(
            claim_submission_date,
            service_date
        ) > 2
            THEN 'Submission follow-up'
        ELSE 'Submitted within 2 days'
    END AS submission_status

FROM claims
ORDER BY submission_lag_days DESC, claim_id;

/* 19) Calculate the average and maximum claim-submission lag and count claims exceeding the project’s two-day threshold. */
SELECT
    COUNT(*) AS total_claims,

    ROUND(
        AVG(
            DATEDIFF(
                claim_submission_date,
                service_date
            )
        ),
        2
    ) AS average_submission_lag_days,

    MAX(
        DATEDIFF(
            claim_submission_date,
            service_date
        )
    ) AS maximum_submission_lag_days,

    SUM(
        CASE
            WHEN DATEDIFF(
                claim_submission_date,
                service_date
            ) > 2
                THEN 1
            ELSE 0
        END
    ) AS claims_over_two_days

FROM claims;

/* 20) Identify patients with repeated utilization and summarize their billed and allowed amounts. */
SELECT
    pt.patient_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    COUNT(c.claim_id) AS claim_count,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.allowed_amount) AS total_allowed
FROM patients AS pt
INNER JOIN claims AS c
    ON pt.patient_id = c.patient_id
GROUP BY 
    pt.patient_id,
    pt.first_name,
    pt.last_name
HAVING COUNT(c.claim_id) > 1
ORDER BY claim_count DESC, total_billed;

/* 21) Compare claim volume, billed amounts, allowed amounts, and denial performance across procedures. */
SELECT
    procedure_code,
    COUNT(*) AS claim_count,
    SUM(billed_amount) AS total_billed,
    SUM(allowed_amount) AS total_allowed,
    
    SUM(
        CASE
            WHEN claim_status = 'Denied' THEN 1 ELSE 0
        END
    ) AS denied_claims,

    ROUND(
        100 * SUM(
            CASE
                WHEN claim_status = 'Denied' THEN 1 ELSE 0
            END
        ) / COUNT(*),
        1
    ) AS denial_rate_percentage
FROM claims
GROUP BY procedure_code
ORDER BY total_billed;

/* 22) Analyze claims by diagnosis code. Compare claim volume and financial performance across diagnosis codes. */
SELECT
    diagnosis_code,
    COUNT(*) AS claim_count,
    SUM(billed_amount) AS total_billed,
    SUM(allowed_amount) AS total_allowed,

    SUM(
        CASE
            WHEN claim_status = 'Denied' THEN 1
            ELSE 0
        END
    ) AS denied_claims

FROM claims
GROUP BY diagnosis_code
ORDER BY total_billed DESC;

/* 23) Calculate payment turnaround time. Measure how many days elapsed between claim submission and payment. */
SELECT
    c.claim_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    c.claim_submission_date,
    p.payment_date,

    DATEDIFF(
        p.payment_date,
        c.claim_submission_date
    ) AS days_from_submission_to_payment

FROM claims AS c
INNER JOIN patients AS pt
    ON c.patient_id = pt.patient_id
INNER JOIN payments AS p
    ON c.claim_id = p.claim_id
WHERE c.claim_status = 'Paid'
ORDER BY days_from_submission_to_payment DESC;

/* 24) Summarize payment components. Calculate total payer payments, patient responsibility, contractual adjustments, and total reimbursement. */
SELECT
    COUNT(*) AS payment_record_count,
    SUM(payer_payment) AS total_payer_payments,
    SUM(patient_responsibility) AS total_patient_responsibility,
    SUM(adjustment_amount) AS total_adjustments,

    SUM(
        payer_payment + patient_responsibility
    ) AS total_reimbursement,

    SUM(payer_payment
        + patient_responsibility
        + adjustment_amount
    ) AS total_accounted_amount

FROM payments;

/* 25) Denial rate by payer. Compare denial volume and denied dollars across the three payers. */
SELECT
    ip.payer_name,
    COUNT(c.claim_id) AS claim_count,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.allowed_amount) AS total_allowed,

    SUM(
        CASE
            WHEN c.claim_status = 'Denied' THEN 1
            ELSE 0
        END
    ) AS denied_claims,

    SUM(
        CASE
            WHEN c.claim_status = 'Denied'
                THEN c.billed_amount
            ELSE 0
        END
    ) AS denied_billed_amount,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN c.claim_status = 'Denied' THEN 1
                ELSE 0
            END
        ) / COUNT(c.claim_id),
        1
    ) AS denial_rate_percentage

FROM claims AS c
INNER JOIN insurance_plans AS ip
    ON c.insurance_plan_id = ip.insurance_plan_id
GROUP BY
    ip.insurance_plan_id,
    ip.payer_name
ORDER BY denial_rate_percentage DESC;

/* 26.) Denial rate by provider. Compare denial frequency across providers and specialties. */
SELECT
    pr.provider_name,
    pr.specialty,
    COUNT(c.claim_id) AS claim_count,
    SUM(c.billed_amount) AS total_billed,
    SUM(c.allowed_amount) AS total_allowed,

    SUM(
        CASE
            WHEN c.claim_status = 'Denied' THEN 1 
            ELSE 0
        END
    ) AS denied_claims,

    ROUND(
        100.0 * SUM(
            CASE
				WHEN c.claim_status = 'Denied' THEN 1 
                ELSE 0
            END
        ) / COUNT(c.claim_id),
        1
    ) AS denial_rate_percentage
FROM claims AS c
INNER JOIN providers AS pr
    ON c.provider_id = pr.provider_id
GROUP BY
    pr.provider_id,
    pr.provider_name,
    pr.specialty
ORDER BY denial_rate_percentage DESC;

/* 27) Create a revenue-cycle follow-up queue. Produce an operational worklist containing denied and pending claims. */
SELECT
    c.claim_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    ip.payer_name,
    pr.provider_name,
    c.procedure_code,
    c.diagnosis_code,
    c.claim_status,
    c.billed_amount,
    c.allowed_amount,
    c.denial_reason,

    CASE
        WHEN c.claim_status = 'Denied'
            THEN 'Denial follow-up'
        WHEN c.claim_status = 'Pending'
            THEN 'Pending claim follow-up'
        ELSE 'No immediate follow-up'
    END AS follow_up_category

FROM claims AS c
INNER JOIN patients AS pt
    ON c.patient_id = pt.patient_id
INNER JOIN insurance_plans AS ip
    ON c.insurance_plan_id = ip.insurance_plan_id
INNER JOIN providers AS pr
    ON c.provider_id = pr.provider_id
WHERE c.claim_status IN ('Denied', 'Pending')
ORDER BY 
	CASE
        WHEN c.claim_status = 'Denied' THEN 1
        WHEN c.claim_status = 'Pending' THEN 2
        ELSE 3
    END,
	c.billed_amount DESC;
    
/* 28) Executive KPI summary. Objective: Return the principal project metrics in one dashboard-ready row.*/
SELECT
    COUNT(*) AS total_claims,
    SUM(billed_amount) AS total_billed,
    SUM(allowed_amount) AS total_allowed,

    SUM(
        CASE WHEN claim_status = 'Paid' THEN 1 ELSE 0 END
    ) AS paid_claims,

    SUM(
        CASE WHEN claim_status = 'Denied' THEN 1 ELSE 0 END
    ) AS denied_claims,

    SUM(
        CASE WHEN claim_status = 'Pending' THEN 1 ELSE 0 END
    ) AS pending_claims,

    ROUND(
        100.0 * SUM(
            CASE WHEN claim_status = 'Denied' THEN 1 ELSE 0 END
        ) / COUNT(*),
        1
    ) AS denial_rate_percentage,

    ROUND(
        100.0 * SUM(allowed_amount) / SUM(billed_amount),
        1
    ) AS overall_allowed_rate_percentage

FROM claims;

/* 29. Create a Reusable Claim Revenue Summary View. Then display the view.Objective:** Create a reusable 
claim-level reporting dataset that combines patient, provider, insurance-plan, claim, and aggregated payment 
information. The view supports recurring analysis and dashboard development without requiring the underlying 
joins to be rewritten. */

CREATE OR REPLACE VIEW claim_revenue_summary AS

SELECT
    c.claim_id,

    c.patient_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    pt.date_of_birth,
    pt.gender,
    pt.state AS patient_state,

    c.provider_id,
    pr.provider_name,
    pr.specialty,
    pr.npi_number,
    pr.facility_name,
    pr.state AS provider_state,

    c.insurance_plan_id,
    ip.payer_name,
    ip.plan_name,
    ip.plan_type,

    c.service_date,
    c.claim_submission_date,

    DATEDIFF(
        c.claim_submission_date,
        c.service_date
    ) AS submission_lag_days,

    c.procedure_code,
    c.diagnosis_code,
    c.claim_status,
    c.denial_reason,

    c.billed_amount,
    c.allowed_amount,

    c.billed_amount - c.allowed_amount
        AS contractual_difference,

    ROUND(
        100.0 * c.allowed_amount / c.billed_amount,
        1
    ) AS allowed_percentage,

    pay.payment_date,

    COALESCE(pay.payer_payment, 0)
        AS payer_payment,

    COALESCE(pay.patient_responsibility, 0)
        AS patient_responsibility,

    COALESCE(pay.adjustment_amount, 0)
        AS adjustment_amount,

    COALESCE(pay.payer_payment, 0)
        + COALESCE(pay.patient_responsibility, 0)
        AS total_reimbursement,

    c.allowed_amount
        - (
            COALESCE(pay.payer_payment, 0)
            + COALESCE(pay.patient_responsibility, 0)
          ) AS allowed_balance

FROM claims AS c

INNER JOIN patients AS pt
    ON c.patient_id = pt.patient_id

INNER JOIN providers AS pr
    ON c.provider_id = pr.provider_id

INNER JOIN insurance_plans AS ip
    ON c.insurance_plan_id = ip.insurance_plan_id

LEFT JOIN (
    SELECT
        claim_id,
        MAX(payment_date) AS payment_date,
        SUM(payer_payment) AS payer_payment,
        SUM(patient_responsibility)
            AS patient_responsibility,
        SUM(adjustment_amount)
            AS adjustment_amount
    FROM payments
    GROUP BY claim_id
) AS pay
    ON c.claim_id = pay.claim_id;

SELECT *
FROM claim_revenue_summary
ORDER BY claim_id;



