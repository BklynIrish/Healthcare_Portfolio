-- ============================================================================
-- Project 4: Closed-Loop Specialty Referral Management
-- File: operational_views.sql
-- Purpose: Create reusable operational and analytical views.
-- Platform: MySQL 8.0+
-- Prerequisite: 15 tables loaded and data_quality_checks.sql passed.
-- ============================================================================

USE healthcare_referral_management;

-- Re-running this script replaces the views without changing source data.
DROP VIEW IF EXISTS v_data_exception_queue;
DROP VIEW IF EXISTS v_site_specialty_performance;
DROP VIEW IF EXISTS v_referral_funnel;
DROP VIEW IF EXISTS v_operational_work_queue;
DROP VIEW IF EXISTS v_referral_lifecycle;

-- ============================================================================
-- 1. REFERRAL LIFECYCLE
-- Grain: one row per referral.
-- Purpose: authoritative dashboard-ready lifecycle dataset.
-- ============================================================================

CREATE VIEW v_referral_lifecycle AS
SELECT
    r.referral_id,
    r.source_referral_id,
    r.patient_id,
    r.referring_practitioner_id,
    CONCAT(rp.first_name, ' ', rp.last_name) AS referring_practitioner_name,
    r.referring_organization_id,
    ro.organization_name AS referring_organization_name,
    r.referring_location_id,
    rl.location_name AS referring_location_name,
    r.specialty_id,
    s.specialty_code,
    s.specialty_name,
    r.destination_practitioner_id,
    CASE
        WHEN dp.practitioner_id IS NULL THEN NULL
        ELSE CONCAT(dp.first_name, ' ', dp.last_name)
    END AS destination_practitioner_name,
    r.destination_organization_id,
    destination_org.organization_name AS destination_organization_name,
    c.payer_id,
    p.payer_name,
    p.payer_category,
    r.priority,
    r.current_status,
    r.current_queue,
    r.current_owner_user_id,
    u.display_name AS current_owner_name,
    r.source_ordered_at,
    r.referral_received_at,
    r.current_stage_started_at,
    r.service_level_due_at,
    r.initial_validation_completed_at,
    r.first_outreach_at,
    r.first_scheduled_at,
    r.first_completed_appointment_at,
    r.first_report_received_at,
    r.closed_at,
    r.closure_category,
    r.closure_reason,
    TIMESTAMPDIFF(
        DAY,
        r.referral_received_at,
        COALESCE(r.closed_at, CURRENT_TIMESTAMP)
    ) AS referral_age_days,
    TIMESTAMPDIFF(
        HOUR,
        r.current_stage_started_at,
        COALESCE(r.closed_at, CURRENT_TIMESTAMP)
    ) AS current_stage_age_hours,
    CASE
        WHEN r.current_status NOT IN
            ('Closed—Completed', 'Closed—Not Completed', 'Cancelled')
         AND r.service_level_due_at IS NOT NULL
         AND r.service_level_due_at < CURRENT_TIMESTAMP
        THEN 1 ELSE 0
    END AS overdue_flag,
    CASE
        WHEN r.initial_validation_completed_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR, r.referral_received_at, r.initial_validation_completed_at
        ) / 24.0
        ELSE NULL
    END AS days_to_validation,
    CASE
        WHEN r.first_outreach_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR, r.referral_received_at, r.first_outreach_at
        ) / 24.0
        ELSE NULL
    END AS days_to_first_outreach,
    CASE
        WHEN r.first_scheduled_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR, r.referral_received_at, r.first_scheduled_at
        ) / 24.0
        ELSE NULL
    END AS days_to_schedule,
    CASE
        WHEN r.first_completed_appointment_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            r.referral_received_at,
            r.first_completed_appointment_at
        ) / 24.0
        ELSE NULL
    END AS days_to_completion,
    CASE
        WHEN r.first_completed_appointment_at IS NOT NULL
         AND r.first_report_received_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            r.first_completed_appointment_at,
            r.first_report_received_at
        ) / 24.0
        ELSE NULL
    END AS report_turnaround_days,
    COALESCE(outreach_summary.outreach_attempt_count, 0)
        AS outreach_attempt_count,
    outreach_summary.last_outreach_at,
    outreach_summary.next_outreach_action_at,
    appointment_summary.appointment_count,
    appointment_summary.latest_appointment_start_at,
    appointment_summary.latest_appointment_status,
    report_summary.report_count,
    report_summary.latest_report_status,
    CASE
        WHEN r.current_status = 'Closed—Completed'
         AND r.first_completed_appointment_at IS NOT NULL
         AND r.first_report_received_at IS NOT NULL
         AND report_summary.reviewed_report_count > 0
        THEN 1 ELSE 0
    END AS closed_loop_flag,
    CASE
        WHEN r.current_status = 'Closed—Not Completed'
         AND r.first_outreach_at IS NOT NULL
         AND r.first_completed_appointment_at IS NULL
        THEN 1 ELSE 0
    END AS referral_leakage_flag,
    DATE_FORMAT(r.referral_received_at, '%Y-%m-01') AS referral_month
FROM referrals r
JOIN practitioners rp
  ON rp.practitioner_id = r.referring_practitioner_id
JOIN organizations ro
  ON ro.organization_id = r.referring_organization_id
JOIN locations rl
  ON rl.location_id = r.referring_location_id
JOIN specialties s
  ON s.specialty_id = r.specialty_id
LEFT JOIN practitioners dp
  ON dp.practitioner_id = r.destination_practitioner_id
LEFT JOIN organizations destination_org
  ON destination_org.organization_id = r.destination_organization_id
LEFT JOIN coverages c
  ON c.coverage_id = r.coverage_id
LEFT JOIN payers p
  ON p.payer_id = c.payer_id
LEFT JOIN users u
  ON u.user_id = r.current_owner_user_id
LEFT JOIN (
    SELECT
        referral_id,
        COUNT(*) AS outreach_attempt_count,
        MAX(attempt_at) AS last_outreach_at,
        MIN(CASE
            WHEN next_action_at >= CURRENT_TIMESTAMP THEN next_action_at
            ELSE NULL
        END) AS next_outreach_action_at
    FROM outreach_attempts
    GROUP BY referral_id
) outreach_summary
  ON outreach_summary.referral_id = r.referral_id
LEFT JOIN (
    SELECT
        referral_id,
        COUNT(*) AS appointment_count,
        MAX(appointment_start_at) AS latest_appointment_start_at,
        SUBSTRING_INDEX(
            GROUP_CONCAT(
                appointment_status
                ORDER BY appointment_start_at DESC, appointment_id DESC
                SEPARATOR '|'
            ),
            '|',
            1
        ) AS latest_appointment_status
    FROM appointments
    GROUP BY referral_id
) appointment_summary
  ON appointment_summary.referral_id = r.referral_id
LEFT JOIN (
    SELECT
        referral_id,
        COUNT(*) AS report_count,
        SUM(report_status = 'Reviewed') AS reviewed_report_count,
        SUBSTRING_INDEX(
            GROUP_CONCAT(
                report_status
                ORDER BY received_at DESC, consult_report_id DESC
                SEPARATOR '|'
            ),
            '|',
            1
        ) AS latest_report_status
    FROM consult_reports
    WHERE referral_id IS NOT NULL
    GROUP BY referral_id
) report_summary
  ON report_summary.referral_id = r.referral_id;

-- ============================================================================
-- 2. OPERATIONAL WORK QUEUE
-- Grain: one row per active referral requiring operational visibility.
-- Purpose: daily referral-coordinator and manager work queue.
-- ============================================================================

CREATE VIEW v_operational_work_queue AS
SELECT
    lifecycle.referral_id,
    lifecycle.patient_id,
    lifecycle.priority,
    lifecycle.current_status,
    lifecycle.current_queue,
    lifecycle.current_owner_user_id,
    lifecycle.current_owner_name,
    lifecycle.referring_location_name,
    lifecycle.specialty_name,
    lifecycle.payer_name,
    lifecycle.destination_organization_name,
    lifecycle.referral_received_at,
    lifecycle.current_stage_started_at,
    lifecycle.service_level_due_at,
    lifecycle.referral_age_days,
    lifecycle.current_stage_age_hours,
    lifecycle.overdue_flag,
    lifecycle.outreach_attempt_count,
    lifecycle.last_outreach_at,
    lifecycle.next_outreach_action_at,
    lifecycle.latest_appointment_start_at,
    lifecycle.latest_appointment_status,
    lifecycle.latest_report_status,
    CASE
        WHEN lifecycle.priority = 'Urgent' AND lifecycle.overdue_flag = 1
            THEN 'Critical—Urgent Overdue'
        WHEN lifecycle.priority = 'Urgent'
            THEN 'High—Urgent'
        WHEN lifecycle.overdue_flag = 1
            THEN 'High—Overdue'
        WHEN lifecycle.current_owner_user_id IS NULL
         AND lifecycle.current_queue IS NULL
            THEN 'High—Unassigned'
        WHEN lifecycle.current_status = 'Completed—Report Pending'
            THEN 'Medium—Report Follow-Up'
        WHEN lifecycle.current_status = 'Needs Information'
            THEN 'Medium—Missing Information'
        ELSE 'Routine'
    END AS work_priority,
    CASE
        WHEN lifecycle.current_owner_user_id IS NULL
         AND lifecycle.current_queue IS NULL
            THEN 'Assign owner or accountable queue'
        WHEN lifecycle.current_status = 'Received'
            THEN 'Complete intake validation'
        WHEN lifecycle.current_status = 'Needs Information'
            THEN 'Resolve missing or invalid information'
        WHEN lifecycle.current_status = 'Ready for Outreach'
            THEN 'Initiate patient outreach'
        WHEN lifecycle.current_status = 'Outreach in Progress'
            THEN 'Complete next outreach action'
        WHEN lifecycle.current_status = 'Scheduled'
         AND lifecycle.latest_appointment_start_at < CURRENT_TIMESTAMP
            THEN 'Verify elapsed appointment outcome'
        WHEN lifecycle.current_status = 'Scheduled'
            THEN 'Monitor scheduled appointment'
        WHEN lifecycle.current_status = 'Completed—Report Pending'
            THEN 'Obtain and route consultation report'
        ELSE 'Review referral'
    END AS recommended_next_action,
    CASE
        WHEN lifecycle.priority = 'Urgent' THEN 1
        ELSE 2
    END AS priority_sort,
    CASE
        WHEN lifecycle.overdue_flag = 1 THEN 1
        ELSE 2
    END AS overdue_sort
FROM v_referral_lifecycle lifecycle
WHERE lifecycle.current_status NOT IN
    ('Closed—Completed', 'Closed—Not Completed', 'Cancelled');

-- ============================================================================
-- 3. REFERRAL FUNNEL
-- Grain: one row per funnel stage.
-- Purpose: mutually nonexclusive reached-stage counts and rates.
-- ============================================================================

CREATE VIEW v_referral_funnel AS
SELECT
    1 AS stage_order,
    'Received' AS funnel_stage,
    COUNT(*) AS referral_count,
    ROUND(COUNT(*) / NULLIF((SELECT COUNT(*) FROM referrals), 0), 4)
        AS percent_of_received
FROM referrals
UNION ALL
SELECT
    2,
    'Validated',
    SUM(initial_validation_completed_at IS NOT NULL),
    ROUND(
        SUM(initial_validation_completed_at IS NOT NULL)
        / NULLIF(COUNT(*), 0),
        4
    )
FROM referrals
UNION ALL
SELECT
    3,
    'Outreach Initiated',
    SUM(first_outreach_at IS NOT NULL),
    ROUND(SUM(first_outreach_at IS NOT NULL) / NULLIF(COUNT(*), 0), 4)
FROM referrals
UNION ALL
SELECT
    4,
    'Scheduled',
    SUM(first_scheduled_at IS NOT NULL),
    ROUND(SUM(first_scheduled_at IS NOT NULL) / NULLIF(COUNT(*), 0), 4)
FROM referrals
UNION ALL
SELECT
    5,
    'Appointment Completed',
    SUM(first_completed_appointment_at IS NOT NULL),
    ROUND(
        SUM(first_completed_appointment_at IS NOT NULL)
        / NULLIF(COUNT(*), 0),
        4
    )
FROM referrals
UNION ALL
SELECT
    6,
    'Report Received',
    SUM(first_report_received_at IS NOT NULL),
    ROUND(SUM(first_report_received_at IS NOT NULL) / NULLIF(COUNT(*), 0), 4)
FROM referrals
UNION ALL
SELECT
    7,
    'Closed Loop',
    SUM(current_status = 'Closed—Completed'),
    ROUND(SUM(current_status = 'Closed—Completed') / NULLIF(COUNT(*), 0), 4)
FROM referrals;

-- ============================================================================
-- 4. SITE AND SPECIALTY PERFORMANCE
-- Grain: one row per referring location and specialty.
-- Purpose: comparative operational performance for Tableau.
-- ============================================================================

CREATE VIEW v_site_specialty_performance AS
SELECT
    referring_location_id,
    referring_location_name,
    specialty_id,
    specialty_name,
    COUNT(*) AS referral_count,
    SUM(priority = 'Urgent') AS urgent_referral_count,
    SUM(initial_validation_completed_at IS NOT NULL) AS validated_referral_count,
    SUM(first_scheduled_at IS NOT NULL) AS scheduled_referral_count,
    SUM(first_completed_appointment_at IS NOT NULL) AS completed_referral_count,
    SUM(closed_loop_flag) AS closed_loop_referral_count,
    SUM(referral_leakage_flag) AS leaked_referral_count,
    SUM(overdue_flag) AS overdue_open_referral_count,
    ROUND(
        SUM(initial_validation_completed_at IS NOT NULL)
        / NULLIF(COUNT(*), 0),
        4
    ) AS intake_completeness_rate,
    ROUND(
        SUM(first_scheduled_at IS NOT NULL)
        / NULLIF(SUM(first_outreach_at IS NOT NULL), 0),
        4
    ) AS scheduling_conversion_rate,
    ROUND(
        SUM(first_completed_appointment_at IS NOT NULL)
        / NULLIF(SUM(first_scheduled_at IS NOT NULL), 0),
        4
    ) AS appointment_completion_rate,
    ROUND(SUM(closed_loop_flag) / NULLIF(COUNT(*), 0), 4)
        AS closed_loop_rate,
    ROUND(
        SUM(referral_leakage_flag)
        / NULLIF(SUM(first_outreach_at IS NOT NULL), 0),
        4
    ) AS referral_leakage_rate,
    ROUND(AVG(days_to_schedule), 2) AS average_days_to_schedule,
    ROUND(AVG(days_to_completion), 2) AS average_days_to_completion,
    ROUND(AVG(report_turnaround_days), 2) AS average_report_turnaround_days
FROM v_referral_lifecycle
GROUP BY
    referring_location_id,
    referring_location_name,
    specialty_id,
    specialty_name;

-- ============================================================================
-- 5. DATA EXCEPTION QUEUE
-- Grain: one row per unresolved validation issue.
-- Purpose: actionable data-quality and implementation exception management.
-- ============================================================================

CREATE VIEW v_data_exception_queue AS
SELECT
    issue.validation_issue_id,
    issue.referral_id,
    issue.source_record_id,
    issue.issue_source,
    issue.rule_code,
    issue.field_name,
    issue.severity,
    issue.issue_description,
    issue.detected_at,
    issue.resolution_status,
    issue.resolved_by_user_id,
    issue.resolved_at,
    issue.resolution_note,
    r.priority AS referral_priority,
    r.current_status AS referral_status,
    r.current_queue,
    r.current_owner_user_id,
    s.specialty_name,
    l.location_name AS referring_location_name,
    TIMESTAMPDIFF(HOUR, issue.detected_at, CURRENT_TIMESTAMP)
        AS issue_age_hours,
    CASE
        WHEN issue.severity = 'Critical' THEN 1
        WHEN issue.severity = 'Blocking' THEN 2
        ELSE 3
    END AS severity_sort
FROM referral_validation_issues issue
LEFT JOIN referrals r
  ON r.referral_id = issue.referral_id
LEFT JOIN specialties s
  ON s.specialty_id = r.specialty_id
LEFT JOIN locations l
  ON l.location_id = r.referring_location_id
WHERE issue.resolution_status IN ('Open', 'In Progress');

-- ============================================================================
-- VIEW VERIFICATION
-- Expected: 5 views and v_referral_lifecycle = 2,500 rows.
-- ============================================================================

SELECT
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'healthcare_referral_management'
ORDER BY table_name;

SELECT 'v_referral_lifecycle' AS view_name, COUNT(*) AS row_count
FROM v_referral_lifecycle
UNION ALL
SELECT 'v_operational_work_queue', COUNT(*)
FROM v_operational_work_queue
UNION ALL
SELECT 'v_referral_funnel', COUNT(*)
FROM v_referral_funnel
UNION ALL
SELECT 'v_site_specialty_performance', COUNT(*)
FROM v_site_specialty_performance
UNION ALL
SELECT 'v_data_exception_queue', COUNT(*)
FROM v_data_exception_queue;

-- Recommended operational queue order for inspection.
SELECT
    referral_id,
    work_priority,
    priority,
    current_status,
    current_queue,
    current_owner_name,
    service_level_due_at,
    current_stage_age_hours,
    recommended_next_action
FROM v_operational_work_queue
ORDER BY
    priority_sort,
    overdue_sort,
    service_level_due_at,
    referral_received_at
LIMIT 25;

-- End of operational_views.sql

	SELECT 'v_referral_lifecycle' AS view_name, COUNT(*) AS row_count
	FROM v_referral_lifecycle

	UNION ALL

	SELECT 'v_operational_work_queue', COUNT(*)
	FROM v_operational_work_queue

	UNION ALL

	SELECT 'v_referral_funnel', COUNT(*)
	FROM v_referral_funnel

	UNION ALL

	SELECT 'v_site_specialty_performance', COUNT(*)
	FROM v_site_specialty_performance

	UNION ALL

	SELECT 'v_data_exception_queue', COUNT(*)
	FROM v_data_exception_queue;
