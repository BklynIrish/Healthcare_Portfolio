USE healthcare_prior_authorization;

-- ============================================================
-- 1. RECORD COUNTS
-- ============================================================

SELECT 'patients' AS table_name, COUNT(*) AS records FROM patients
UNION ALL
SELECT 'providers', COUNT(*) FROM providers
UNION ALL
SELECT 'payers', COUNT(*) FROM payers
UNION ALL
SELECT 'coverages', COUNT(*) FROM coverages
UNION ALL
SELECT 'procedures', COUNT(*) FROM procedures
UNION ALL
SELECT 'diagnoses', COUNT(*) FROM diagnoses
UNION ALL
SELECT 'authorization_requests', COUNT(*) FROM authorization_requests
UNION ALL
SELECT 'status_history', COUNT(*) FROM status_history;


-- ============================================================
-- 2. DUPLICATE PRIMARY KEYS
-- Expected result: zero rows from every query
-- ============================================================

SELECT patient_id, COUNT(*) AS occurrences
FROM patients
GROUP BY patient_id
HAVING COUNT(*) > 1;

SELECT authorization_id, COUNT(*) AS occurrences
FROM authorization_requests
GROUP BY authorization_id
HAVING COUNT(*) > 1;

SELECT status_event_id, COUNT(*) AS occurrences
FROM status_history
GROUP BY status_event_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. PATIENT-COVERAGE CONSISTENCY
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS patient_coverage_mismatches
FROM authorization_requests AS ar
JOIN coverages AS c
    ON ar.coverage_id = c.coverage_id
WHERE ar.patient_id <> c.patient_id;


-- ============================================================
-- 4. DATE-SEQUENCE VALIDATION
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS invalid_date_sequences
FROM authorization_requests
WHERE
    (submitted_at IS NOT NULL AND submitted_at < created_at)
    OR
    (decision_at IS NOT NULL AND submitted_at IS NULL)
    OR
    (decision_at IS NOT NULL AND decision_at < submitted_at);


-- ============================================================
-- 5. FINAL-DECISION VALIDATION
-- Expected results: all zero
-- ============================================================

SELECT COUNT(*) AS final_requests_without_decision_date
FROM authorization_requests
WHERE current_status IN ('Approved', 'Denied')
  AND decision_at IS NULL;

SELECT COUNT(*) AS approved_requests_without_number
FROM authorization_requests
WHERE current_status = 'Approved'
  AND authorization_number IS NULL;

SELECT COUNT(*) AS denied_requests_without_reason
FROM authorization_requests
WHERE current_status = 'Denied'
  AND denial_reason IS NULL;


-- ============================================================
-- 6. EMPTY-STRING VALIDATION
-- Expected results: all zero
-- ============================================================

SELECT COUNT(*) AS empty_authorization_numbers
FROM authorization_requests
WHERE authorization_number = '';

SELECT COUNT(*) AS empty_denial_reasons
FROM authorization_requests
WHERE denial_reason = '';


-- ============================================================
-- 7. COVERAGE VALIDATION
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS invalid_coverage_at_submission
FROM authorization_requests AS ar
JOIN coverages AS c
    ON ar.coverage_id = c.coverage_id
WHERE ar.submitted_at IS NOT NULL
  AND (
      c.coverage_status <> 'active'
      OR DATE(ar.submitted_at) < c.coverage_start_date
      OR (
          c.coverage_end_date IS NOT NULL
          AND DATE(ar.submitted_at) > c.coverage_end_date
      )
  );


-- ============================================================
-- 8. STATUS-HISTORY COVERAGE
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS requests_without_history
FROM authorization_requests AS ar
LEFT JOIN status_history AS sh
    ON ar.authorization_id = sh.authorization_id
WHERE sh.authorization_id IS NULL;


-- ============================================================
-- 9. LATEST-STATUS CONSISTENCY
-- Expected result: 0
-- ============================================================

WITH ranked_statuses AS (
    SELECT
        authorization_id,
        status,
        status_at,
        ROW_NUMBER() OVER (
            PARTITION BY authorization_id
            ORDER BY status_at DESC, status_event_id DESC
        ) AS status_rank
    FROM status_history
)
SELECT COUNT(*) AS latest_status_mismatches
FROM authorization_requests AS ar
JOIN ranked_statuses AS rs
    ON ar.authorization_id = rs.authorization_id
   AND rs.status_rank = 1
WHERE ar.current_status <> rs.status;


-- ============================================================
-- 10. FINAL VALIDATION SUMMARY
-- Every failure_count should equal 0
-- ============================================================

SELECT
    'Patient-coverage mismatch' AS validation_check,
    COUNT(*) AS failure_count
FROM authorization_requests AS ar
JOIN coverages AS c
    ON ar.coverage_id = c.coverage_id
WHERE ar.patient_id <> c.patient_id

UNION ALL

SELECT
    'Invalid date sequence',
    COUNT(*)
FROM authorization_requests
WHERE
    (submitted_at IS NOT NULL AND submitted_at < created_at)
    OR
    (decision_at IS NOT NULL AND submitted_at IS NULL)
    OR
    (decision_at IS NOT NULL AND decision_at < submitted_at)

UNION ALL

SELECT
    'Final request missing decision date',
    COUNT(*)
FROM authorization_requests
WHERE current_status IN ('Approved', 'Denied')
  AND decision_at IS NULL

UNION ALL

SELECT
    'Approved request missing authorization number',
    COUNT(*)
FROM authorization_requests
WHERE current_status = 'Approved'
  AND authorization_number IS NULL

UNION ALL

SELECT
    'Denied request missing denial reason',
    COUNT(*)
FROM authorization_requests
WHERE current_status = 'Denied'
  AND denial_reason IS NULL

UNION ALL

SELECT
    'Request missing status history',
    COUNT(*)
FROM authorization_requests AS ar
LEFT JOIN status_history AS sh
    ON ar.authorization_id = sh.authorization_id
WHERE sh.authorization_id IS NULL;