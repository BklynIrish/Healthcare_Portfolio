/*
Project:
Healthcare Data-Quality Checks

Purpose:
Create a small healthcare encounter dataset and test completeness,
uniqueness, validity, and operational totals.
*/

CREATE DATABASE IF NOT EXISTS healthcare_data_quality;

USE healthcare_data_quality;

DROP TABLE IF EXISTS patient_encounters;

CREATE TABLE patient_encounters (
    encounter_id INT,
    patient_id VARCHAR(20),
    encounter_date VARCHAR(20),
    status VARCHAR(20),
    charge_amount DECIMAL(10, 2)
);

INSERT INTO patient_encounters (
    encounter_id,
    patient_id,
    encounter_date,
    status,
    charge_amount
)
VALUES
    (1, 'P1001', '2026-07-01', 'Completed', 250.00),
    (2, 'P1002', '2026-07-02', 'Completed', 180.00),
    (3, NULL,    '2026-07-03', 'Completed', 325.00),
    (4, 'P1004', 'INVALID_DATE', 'Completed', 210.00),
    (5, 'P1002', '2026-07-02', 'Completed', 180.00),
    (6, 'P1006', '2026-07-05', 'Cancelled', -50.00);
 
/* View Table patient_encounters */

SELECT * FROM patient_encounters;

/*
Validation Rule 1:
Patient ID must not be missing.
*/

SELECT *
FROM patient_encounters
WHERE patient_id IS NULL
   OR TRIM(patient_id) = '';
 
/*
Validation Rule 2:
Patient and encounter-date combinations should not be duplicated.
*/ 
 
SELECT
    patient_id,
    encounter_date,
    COUNT(*) AS record_count
FROM patient_encounters
GROUP BY
    patient_id,
    encounter_date
HAVING COUNT(*) > 1;

SELECT * FROM patient_encounters;

/*
Validation Rule 3: Shows full rows of duplicated encounter_dates and charge_amounts
*/

SELECT pe.*
FROM patient_encounters AS pe
INNER JOIN (
    SELECT
        patient_id,
        encounter_date
    FROM patient_encounters
    WHERE patient_id IS NOT NULL
    GROUP BY
        patient_id,
        encounter_date
    HAVING COUNT(*) > 1
) AS duplicates
    ON pe.patient_id = duplicates.patient_id
   AND pe.encounter_date = duplicates.encounter_date
ORDER BY
    pe.patient_id,
    pe.encounter_date,
    pe.encounter_id;

/*
Validation Rule 4:
Completed encounters should not have valid negative charges. This shows Negative or Zero Charges.
*/
    
SELECT *
FROM patient_encounters
WHERE charge_amount <= 0;

/*
Validation Rule 5:
Completed encounters should not have valid negative charges this shows Completed Negative or Zero Charges.
*/

SELECT *
FROM patient_encounters
WHERE status = 'Completed'
  AND (
      charge_amount IS NULL
      OR charge_amount <= 0
  );

/*
Validation Rule 4:
Encounter dates must use an accepted YYYY-MM-DD date format. Any missing or misformatted date is Identified
*/
  
  SELECT *
FROM patient_encounters
WHERE encounter_date IS NULL
   OR STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NULL;
   
SELECT *
FROM patient_encounters
WHERE encounter_date IS NULL
   OR STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NULL
   OR DATE_FORMAT(
          STR_TO_DATE(encounter_date, '%Y-%m-%d'),
          '%Y-%m-%d'
      ) <> encounter_date;
      
/*
shows status, encounter_ids, and total charge amounts
*/
	
SELECT
    status,
    COUNT(*) AS encounter_count,
    SUM(charge_amount) AS total_charges
FROM patient_encounters
GROUP BY status
ORDER BY status;

/*
Shows status, enounter_ids, total, and average_charges
*/ 

SELECT
    status,
    COUNT(*) AS encounter_count,
    SUM(charge_amount) AS total_charges,
    ROUND(AVG(charge_amount), 2) AS average_charge
FROM patient_encounters
GROUP BY status
ORDER BY status;

/*
This is an optional but valuable improvement. It consolidates multiple data-quality rules into a single result set. It shows status, 
charge amounts, encounter_ids for those entries where there was a missing patient_id, negative charge amount, or invalid date formats
*/

SELECT
    encounter_id,
    patient_id,
    encounter_date,
    status,
    charge_amount,
    CASE
        WHEN patient_id IS NULL OR TRIM(patient_id) = ''
            THEN 'Missing patient identifier'

        WHEN STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NULL
            THEN 'Invalid encounter date'

        WHEN charge_amount <= 0
            THEN 'Invalid or suspicious charge'

        ELSE 'No exception detected'
    END AS validation_result
FROM patient_encounters
WHERE patient_id IS NULL
   OR TRIM(patient_id) = ''
   OR STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NULL
   OR charge_amount <= 0
ORDER BY encounter_id;

/*
This preserves every individual row while showing which rows belong to duplicate groups.
*/

SELECT
    encounter_id,
    patient_id,
    encounter_date,
    status,
    charge_amount,
    COUNT(*) OVER (
        PARTITION BY patient_id, encounter_date
    ) AS patient_date_record_count,
    CASE
        WHEN COUNT(*) OVER (
            PARTITION BY patient_id, encounter_date
        ) > 1
        THEN 'Duplicate patient/date combination'
        ELSE 'Unique'
    END AS duplicate_status
FROM patient_encounters;
 
/* Assign each record an exception count */

SELECT
	encounter_id,
    patient_id,
    encounter_date,
    status,
    charge_amount,
    (
		CASE
			WHEN patient_id IS NULL OR TRIM(patient_id) = ''
			THEN 1 ELSE 0
		END
        +
        CASE
			WHEN STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NULL
            THEN 1 ELSE 0
		END
        +
        CASE
			WHEN charge_amount <= 0
            THEN 1 ELSE 0
		END
	) AS exception_count
FROM patient_encounters
ORDER BY encounter_id;

/* Overall Valid Record Rate*/

SELECT
	COUNT(*) AS total_records,
    SUM(
		CASE
			WHEN patient_id IS NOT NULL
            AND TRIM(patient_id) <> ''
            AND STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NOT NULL
            AND charge_amount > 0
			THEN 1 
            ELSE 0
		END
	) AS valid_records,
    ROUND(
		100.0 * SUM(
			CASE
				WHEN patient_id IS NOT NULL
				AND TRIM(patient_id) <> ''
				AND STR_TO_DATE(encounter_date, '%Y-%m-%d') IS NOT NULL
				AND charge_amount > 0
				THEN 1 
				ELSE 0
			END
		) / COUNT(*),
        1
	) AS valid_record_percentage
FROM patient_encounters;
