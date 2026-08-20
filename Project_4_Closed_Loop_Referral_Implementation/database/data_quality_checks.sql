-- ============================================================================
-- Project 4: Closed-Loop Specialty Referral Management
-- File: data_quality_checks.sql
-- Purpose: Validate the 28,543 loaded processed rows against DQ-001–DQ-020.
-- Expected result: every failure_count equals 0.
-- Platform: MySQL 8.0+
-- ============================================================================

USE healthcare_referral_management;

DROP TEMPORARY TABLE IF EXISTS dq_results;

CREATE TEMPORARY TABLE dq_results (
    rule_id       VARCHAR(10)  NOT NULL,
    rule_name     VARCHAR(150) NOT NULL,
    failure_count INT          NOT NULL,
    expected_count INT         NOT NULL DEFAULT 0,
    test_status   VARCHAR(10)  NULL,
    PRIMARY KEY (rule_id)
);

-- DQ-001: Referral coverage belongs to the referral patient.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-001',
    'Referral coverage belongs to the same patient',
    COUNT(*)
FROM referrals r
JOIN coverages c ON c.coverage_id = r.coverage_id
WHERE c.patient_id <> r.patient_id;

-- DQ-002: Referring location belongs to the referring organization.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-002',
    'Referring location belongs to referring organization',
    COUNT(*)
FROM referrals r
JOIN locations l ON l.location_id = r.referring_location_id
WHERE l.organization_id <> r.referring_organization_id;

-- DQ-003: Destination practitioner aligns with destination organization.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-003',
    'Destination practitioner aligns with destination organization',
    COUNT(*)
FROM referrals r
JOIN practitioners p
  ON p.practitioner_id = r.destination_practitioner_id
WHERE r.destination_organization_id IS NOT NULL
  AND p.organization_id <> r.destination_organization_id;

-- DQ-004: Status-history transition uses an approved transition.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-004',
    'Status transitions follow approved workflow',
    COUNT(*)
FROM referral_status_history h
WHERE NOT (
       (h.previous_status IS NULL AND h.new_status = 'Received')
    OR (h.previous_status = 'Received'
        AND h.new_status IN ('Needs Information', 'Ready for Outreach', 'Cancelled'))
    OR (h.previous_status = 'Needs Information'
        AND h.new_status IN ('Ready for Outreach', 'Closed—Not Completed', 'Cancelled'))
    OR (h.previous_status = 'Ready for Outreach'
        AND h.new_status IN ('Outreach in Progress', 'Scheduled',
                             'Closed—Not Completed', 'Cancelled'))
    OR (h.previous_status = 'Outreach in Progress'
        AND h.new_status IN ('Scheduled', 'Closed—Not Completed', 'Cancelled'))
    OR (h.previous_status = 'Scheduled'
        AND h.new_status IN ('Outreach in Progress', 'Completed—Report Pending',
                             'Closed—Not Completed', 'Cancelled'))
    OR (h.previous_status = 'Completed—Report Pending'
        AND h.new_status IN ('Closed—Completed', 'Closed—Not Completed'))
);

-- DQ-005: Current referral status equals the latest status-history event.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-005',
    'Current status equals latest status-history event',
    COUNT(*)
FROM referrals r
JOIN (
    SELECT referral_id, new_status
    FROM (
        SELECT
            referral_id,
            new_status,
            ROW_NUMBER() OVER (
                PARTITION BY referral_id
                ORDER BY status_changed_at DESC, status_history_id DESC
            ) AS row_num
        FROM referral_status_history
    ) ranked_history
    WHERE row_num = 1
) latest ON latest.referral_id = r.referral_id
WHERE latest.new_status <> r.current_status;

-- DQ-006: Stored referral milestones reconcile with source event tables.
-- For scheduling, historical Rescheduled rows are excluded because the stored
-- milestone represents the first current/qualifying appointment scheduling.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-006',
    'Referral milestone timestamps reconcile with lifecycle events',
    COUNT(*)
FROM referrals r
LEFT JOIN (
    SELECT referral_id, MIN(attempt_at) AS first_outreach_at
    FROM outreach_attempts
    GROUP BY referral_id
) o ON o.referral_id = r.referral_id
LEFT JOIN (
    SELECT
        referral_id,
        MIN(CASE WHEN appointment_status <> 'Rescheduled'
                 THEN scheduled_at END) AS first_scheduled_at,
        MIN(CASE WHEN appointment_status = 'Completed'
                 THEN appointment_start_at END) AS first_completed_at
    FROM appointments
    GROUP BY referral_id
) a ON a.referral_id = r.referral_id
LEFT JOIN (
    SELECT referral_id, MIN(received_at) AS first_report_at
    FROM consult_reports
    WHERE match_status = 'Matched'
    GROUP BY referral_id
) cr ON cr.referral_id = r.referral_id
WHERE NOT (r.first_outreach_at <=> o.first_outreach_at)
   OR NOT (r.first_scheduled_at <=> a.first_scheduled_at)
   OR NOT (r.first_completed_appointment_at <=> a.first_completed_at)
   OR NOT (r.first_report_received_at <=> cr.first_report_at);

-- DQ-007: Only one active assignment exists per referral.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-007',
    'No referral has multiple active assignments',
    COUNT(*)
FROM (
    SELECT referral_id
    FROM referral_assignments
    WHERE active_assignment_flag = 1
    GROUP BY referral_id
    HAVING COUNT(*) > 1
) duplicate_active_assignments;

-- DQ-008: Every active referral has an accountable user or queue.
-- This rule replaces a CHECK removed because of MySQL Error 3823.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-008',
    'Every active referral has an owner or accountable queue',
    COUNT(*)
FROM referrals r
WHERE r.current_status NOT IN ('Closed—Completed', 'Closed—Not Completed', 'Cancelled')
  AND r.current_owner_user_id IS NULL
  AND r.current_queue IS NULL;

-- DQ-009: Terminal referrals have no active assignment.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-009',
    'Terminal referrals have no active assignment',
    COUNT(*)
FROM referrals r
JOIN referral_assignments ra
  ON ra.referral_id = r.referral_id
 AND ra.active_assignment_flag = 1
WHERE r.current_status IN ('Closed—Completed', 'Closed—Not Completed', 'Cancelled');

-- DQ-010: Closed-completed referrals satisfy completed closure requirements.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-010',
    'Closed-completed referrals have completed visit and reviewed report',
    COUNT(*)
FROM referrals r
WHERE r.current_status = 'Closed—Completed'
  AND (
      r.closed_at IS NULL
      OR r.closure_category <> 'Completed'
      OR NOT EXISTS (
          SELECT 1
          FROM appointments a
          WHERE a.referral_id = r.referral_id
            AND a.appointment_status = 'Completed'
      )
      OR NOT EXISTS (
          SELECT 1
          FROM consult_reports cr
          WHERE cr.referral_id = r.referral_id
            AND cr.match_status = 'Matched'
            AND cr.report_status = 'Reviewed'
            AND cr.routed_at IS NOT NULL
            AND cr.reviewed_at IS NOT NULL
      )
  );

-- DQ-011: Closed-not-completed referrals use an approved closure reason.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-011',
    'Closed-not-completed referrals have approved reason',
    COUNT(*)
FROM referrals r
WHERE r.current_status = 'Closed—Not Completed'
  AND (
      r.closure_category <> 'Not Completed'
      OR r.closure_reason IS NULL
      OR r.closure_reason NOT IN (
          'Patient Declined', 'Unable to Contact After Protocol',
          'No Longer Clinically Indicated', 'Transferred Care',
          'Patient Moved', 'Duplicate Referral',
          'Insurance or Access Barrier',
          'Patient Chose Another Provider', 'Other Authorized Reason'
      )
  );

-- DQ-012: Final appointment outcomes include outcome timestamps.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-012',
    'Final appointment outcomes include outcome timestamps',
    COUNT(*)
FROM appointments
WHERE appointment_status IN ('Completed', 'Cancelled', 'No-show', 'Rescheduled')
  AND outcome_recorded_at IS NULL;

-- DQ-013: Rescheduled appointments reference an existing successor.
-- This rule replaces a CHECK removed because of MySQL Error 3823.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-013',
    'Rescheduled appointments reference an existing successor',
    COUNT(*)
FROM appointments old_appointment
LEFT JOIN appointments successor
  ON successor.appointment_id = old_appointment.superseded_by_appointment_id
WHERE old_appointment.appointment_status = 'Rescheduled'
  AND (
      old_appointment.superseded_by_appointment_id IS NULL
      OR successor.appointment_id IS NULL
      OR successor.referral_id <> old_appointment.referral_id
  );

-- DQ-014: Matched consultation reports reference a referral.
-- This rule replaces a CHECK removed because of MySQL Error 3823.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-014',
    'Matched reports reference an existing referral',
    COUNT(*)
FROM consult_reports cr
LEFT JOIN referrals r ON r.referral_id = cr.referral_id
WHERE cr.match_status = 'Matched'
  AND (cr.referral_id IS NULL OR r.referral_id IS NULL);

-- DQ-015: Reviewed reports have reviewer, routing, and logical timestamps.
-- This rule replaces a CHECK removed because of MySQL Error 3823.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-015',
    'Reviewed reports have reviewer and ordered routing timestamps',
    COUNT(*)
FROM consult_reports
WHERE report_status = 'Reviewed'
  AND (
      reviewed_by_practitioner_id IS NULL
      OR routed_at IS NULL
      OR reviewed_at IS NULL
      OR routed_at < received_at
      OR reviewed_at < routed_at
  );

-- DQ-016: Resolved or accepted issues include resolution evidence.
-- This rule replaces a CHECK removed because of MySQL Error 3823.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-016',
    'Resolved validation issues include resolver and resolution timestamp',
    COUNT(*)
FROM referral_validation_issues
WHERE resolution_status IN ('Resolved', 'Accepted Exception')
  AND (
      resolved_by_user_id IS NULL
      OR resolved_at IS NULL
      OR resolved_at < detected_at
      OR (resolution_status = 'Accepted Exception' AND resolution_note IS NULL)
  );

-- DQ-017: Outreach events do not precede referral receipt.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-017',
    'Outreach events do not precede referral receipt',
    COUNT(*)
FROM outreach_attempts o
JOIN referrals r ON r.referral_id = o.referral_id
WHERE o.attempt_at < r.referral_received_at;

-- DQ-018: Closure does not precede referral receipt.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-018',
    'Closure timestamp does not precede referral receipt',
    COUNT(*)
FROM referrals
WHERE closed_at IS NOT NULL
  AND closed_at < referral_received_at;

-- DQ-019: Coverage termination does not precede effective date.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-019',
    'Coverage termination does not precede effective date',
    COUNT(*)
FROM coverages
WHERE termination_date IS NOT NULL
  AND termination_date < effective_date;

-- DQ-020: Source identifiers expected to be unique contain no duplicates.
INSERT INTO dq_results (rule_id, rule_name, failure_count)
SELECT
    'DQ-020',
    'Expected unique source identifiers contain no duplicates',
    SUM(duplicate_groups)
FROM (
    SELECT COUNT(*) AS duplicate_groups
    FROM (
        SELECT source_patient_id
        FROM patients
        GROUP BY source_patient_id
        HAVING COUNT(*) > 1
    ) patient_duplicates
    UNION ALL
    SELECT COUNT(*)
    FROM (
        SELECT source_referral_id
        FROM referrals
        GROUP BY source_referral_id
        HAVING COUNT(*) > 1
    ) referral_duplicates
    UNION ALL
    SELECT COUNT(*)
    FROM (
        SELECT source_coverage_id
        FROM coverages
        WHERE source_coverage_id IS NOT NULL
        GROUP BY source_coverage_id
        HAVING COUNT(*) > 1
    ) coverage_duplicates
) all_duplicate_groups;

-- Assign PASS or FAIL.
UPDATE dq_results
SET test_status = CASE
    WHEN failure_count = expected_count THEN 'PASS'
    ELSE 'FAIL'
END
WHERE rule_id BETWEEN 'DQ-001' AND 'DQ-020';

-- ============================================================================
-- SUMMARY RESULTS
-- Expected: 20 PASS, 0 FAIL, 0 total failures.
-- ============================================================================

SELECT
    rule_id,
    rule_name,
    failure_count,
    expected_count,
    test_status
FROM dq_results
ORDER BY rule_id;

SELECT
    COUNT(*) AS rules_tested,
    SUM(test_status = 'PASS') AS rules_passed,
    SUM(test_status = 'FAIL') AS rules_failed,
    SUM(failure_count) AS total_failures
FROM dq_results;

-- Return only failing rules for rapid troubleshooting.
-- Expected result: zero rows.
SELECT
    rule_id,
    rule_name,
    failure_count
FROM dq_results
WHERE test_status = 'FAIL'
ORDER BY rule_id;

-- ============================================================================
-- OPTIONAL DATABASE ROW-COUNT RECONCILIATION
-- Expected total: 28,543 rows.
-- ============================================================================

SELECT
    (SELECT COUNT(*) FROM patients)
  + (SELECT COUNT(*) FROM organizations)
  + (SELECT COUNT(*) FROM locations)
  + (SELECT COUNT(*) FROM specialties)
  + (SELECT COUNT(*) FROM practitioners)
  + (SELECT COUNT(*) FROM payers)
  + (SELECT COUNT(*) FROM coverages)
  + (SELECT COUNT(*) FROM users)
  + (SELECT COUNT(*) FROM referrals)
  + (SELECT COUNT(*) FROM referral_status_history)
  + (SELECT COUNT(*) FROM outreach_attempts)
  + (SELECT COUNT(*) FROM appointments)
  + (SELECT COUNT(*) FROM consult_reports)
  + (SELECT COUNT(*) FROM referral_validation_issues)
  + (SELECT COUNT(*) FROM referral_assignments)
    AS total_database_rows,
    28543 AS expected_database_rows;

-- End of data_quality_checks.sql
