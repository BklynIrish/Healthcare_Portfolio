-- ============================================================================
-- Project 4: Closed-Loop Specialty Referral Management
-- File: analytics_queries.sql
-- Purpose: Calculate governed KPIs and identify operational findings.
-- Platform: MySQL 8.0+
-- Prerequisite: operational_views.sql completed and reconciled.
-- Data: Fully synthetic; findings are scenario-based, not client outcomes.
-- ============================================================================

USE healthcare_referral_management;

-- ============================================================================
-- 1. EXECUTIVE KPI SUMMARY
-- Grain: one summary row.
-- ============================================================================

SELECT
    COUNT(*) AS total_referrals,
    SUM(priority = 'Urgent') AS urgent_referrals,
    SUM(current_status NOT IN
        ('Closed—Completed', 'Closed—Not Completed', 'Cancelled'))
        AS open_referrals,
    SUM(overdue_flag) AS overdue_open_referrals,
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
    ROUND(
        SUM(closed_loop_flag)
        / NULLIF(COUNT(*), 0),
        4
    ) AS closed_loop_rate,
    ROUND(
        SUM(referral_leakage_flag)
        / NULLIF(SUM(first_outreach_at IS NOT NULL), 0),
        4
    ) AS referral_leakage_rate,
    ROUND(AVG(days_to_schedule), 2) AS average_days_to_schedule,
    ROUND(AVG(days_to_completion), 2) AS average_days_to_completion,
    ROUND(AVG(report_turnaround_days), 2) AS average_report_turnaround_days
FROM v_referral_lifecycle;

-- ============================================================================
-- 2. MEDIAN CYCLE-TIME KPIs
-- MySQL 8 does not provide a native MEDIAN aggregate. The query ranks each
-- non-null measure and averages its central one or two values.
-- ============================================================================

WITH cycle_values AS (
    SELECT 'Days to Schedule' AS metric_name, days_to_schedule AS metric_value
    FROM v_referral_lifecycle
    WHERE days_to_schedule IS NOT NULL

    UNION ALL

    SELECT 'Days to Completion', days_to_completion
    FROM v_referral_lifecycle
    WHERE days_to_completion IS NOT NULL

    UNION ALL

    SELECT 'Report Turnaround Days', report_turnaround_days
    FROM v_referral_lifecycle
    WHERE report_turnaround_days IS NOT NULL
),
ranked_values AS (
    SELECT
        metric_name,
        metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY metric_name
            ORDER BY metric_value
        ) AS row_num,
        COUNT(*) OVER (PARTITION BY metric_name) AS metric_count
    FROM cycle_values
)
SELECT
    metric_name,
    ROUND(AVG(metric_value), 2) AS median_value,
    MAX(metric_count) AS observations
FROM ranked_values
WHERE row_num IN (
    FLOOR((metric_count + 1) / 2),
    FLOOR((metric_count + 2) / 2)
)
GROUP BY metric_name
ORDER BY metric_name;

-- ============================================================================
-- 3. CURRENT REFERRAL STATUS DISTRIBUTION
-- ============================================================================

SELECT
    current_status,
    COUNT(*) AS referral_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS percent_of_referrals,
    SUM(priority = 'Urgent') AS urgent_count,
    SUM(overdue_flag) AS overdue_open_count
FROM v_referral_lifecycle
GROUP BY current_status
ORDER BY referral_count DESC, current_status;

-- ============================================================================
-- 4. REFERRAL FUNNEL
-- Reached-stage counts are nonexclusive and should decline by stage.
-- ============================================================================

SELECT
    stage_order,
    funnel_stage,
    referral_count,
    percent_of_received,
    referral_count
      - LEAD(referral_count) OVER (ORDER BY stage_order)
        AS drop_to_next_stage,
    ROUND(
        LEAD(referral_count) OVER (ORDER BY stage_order)
        / NULLIF(referral_count, 0),
        4
    ) AS conversion_to_next_stage
FROM v_referral_funnel
ORDER BY stage_order;

-- ============================================================================
-- 5. OPEN BACKLOG BY STATUS AND PRIORITY
-- ============================================================================

SELECT
    current_status,
    priority,
    COUNT(*) AS open_referrals,
    SUM(overdue_flag) AS overdue_referrals,
    ROUND(AVG(current_stage_age_hours), 1) AS average_stage_age_hours,
    MAX(current_stage_age_hours) AS maximum_stage_age_hours
FROM v_operational_work_queue
GROUP BY current_status, priority
ORDER BY
    FIELD(priority, 'Urgent', 'Routine'),
    overdue_referrals DESC,
    open_referrals DESC;

-- ============================================================================
-- 6. OVERDUE BACKLOG BY WORK PRIORITY
-- ============================================================================

SELECT
    work_priority,
    COUNT(*) AS referral_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS percent_of_work_queue,
    ROUND(AVG(current_stage_age_hours), 1) AS average_stage_age_hours,
    MIN(service_level_due_at) AS earliest_due_at
FROM v_operational_work_queue
GROUP BY work_priority
ORDER BY
    MIN(priority_sort),
    MIN(overdue_sort),
    referral_count DESC;

-- ============================================================================
-- 7. REFERRAL PERFORMANCE BY SITE
-- ============================================================================

SELECT
    referring_location_id,
    referring_location_name,
    SUM(referral_count) AS referral_count,
    SUM(urgent_referral_count) AS urgent_referrals,
    SUM(overdue_open_referral_count) AS overdue_open_referrals,
    ROUND(
        SUM(validated_referral_count) / NULLIF(SUM(referral_count), 0),
        4
    ) AS intake_completeness_rate,
    ROUND(
        SUM(scheduled_referral_count)
        / NULLIF(SUM(validated_referral_count), 0),
        4
    ) AS validated_to_scheduled_rate,
    ROUND(
        SUM(completed_referral_count)
        / NULLIF(SUM(scheduled_referral_count), 0),
        4
    ) AS appointment_completion_rate,
    ROUND(
        SUM(closed_loop_referral_count) / NULLIF(SUM(referral_count), 0),
        4
    ) AS closed_loop_rate,
    ROUND(
        SUM(leaked_referral_count)
        / NULLIF(
            SUM(scheduled_referral_count) + SUM(leaked_referral_count),
            0
        ),
        4
    ) AS indicative_leakage_rate
FROM v_site_specialty_performance
GROUP BY referring_location_id, referring_location_name
ORDER BY closed_loop_rate DESC, referral_count DESC;

-- ============================================================================
-- 8. SPECIALTY PERFORMANCE AND ACCESS
-- ============================================================================

SELECT
    specialty_id,
    specialty_name,
    COUNT(*) AS referral_count,
    SUM(priority = 'Urgent') AS urgent_referrals,
    SUM(overdue_flag) AS overdue_open_referrals,
    ROUND(
        SUM(first_scheduled_at IS NOT NULL)
        / NULLIF(SUM(initial_validation_completed_at IS NOT NULL), 0),
        4
    ) AS validated_to_scheduled_rate,
    ROUND(
        SUM(first_completed_appointment_at IS NOT NULL)
        / NULLIF(SUM(first_scheduled_at IS NOT NULL), 0),
        4
    ) AS appointment_completion_rate,
    ROUND(
        SUM(closed_loop_flag) / NULLIF(COUNT(*), 0),
        4
    ) AS closed_loop_rate,
    ROUND(
        SUM(referral_leakage_flag)
        / NULLIF(COUNT(*), 0),
        4
    ) AS leakage_rate,
    ROUND(AVG(days_to_schedule), 2) AS average_days_to_schedule
FROM v_referral_lifecycle
GROUP BY specialty_id, specialty_name
ORDER BY closed_loop_rate ASC, overdue_open_referrals DESC;

-- ============================================================================
-- 9. PAYER SEGMENTATION
-- Association only: differences should not be interpreted as payer causation.
-- ============================================================================

SELECT
    payer_category,
    payer_name,
    COUNT(*) AS referral_count,
    SUM(priority = 'Urgent') AS urgent_referrals,
    SUM(overdue_flag) AS overdue_open_referrals,
    ROUND(
        SUM(first_scheduled_at IS NOT NULL)
        / NULLIF(SUM(first_outreach_at IS NOT NULL), 0),
        4
    ) AS scheduling_conversion_rate,
    ROUND(
        SUM(closed_loop_flag) / NULLIF(COUNT(*), 0),
        4
    ) AS closed_loop_rate,
    ROUND(AVG(days_to_schedule), 2) AS average_days_to_schedule
FROM v_referral_lifecycle
GROUP BY payer_category, payer_name
ORDER BY payer_category, referral_count DESC;

-- ============================================================================
-- 10. OUTREACH ATTEMPT EFFECTIVENESS
-- ============================================================================

SELECT
    o.communication_channel,
    o.outreach_outcome,
    COUNT(*) AS attempt_count,
    COUNT(DISTINCT o.referral_id) AS distinct_referrals,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.communication_channel),
        4
    ) AS percent_within_channel
FROM outreach_attempts o
GROUP BY o.communication_channel, o.outreach_outcome
ORDER BY o.communication_channel, attempt_count DESC;

-- Referrals by number of outreach attempts and eventual scheduling.
SELECT
    CASE
        WHEN outreach_attempt_count = 0 THEN '0 attempts'
        WHEN outreach_attempt_count = 1 THEN '1 attempt'
        WHEN outreach_attempt_count = 2 THEN '2 attempts'
        ELSE '3+ attempts'
    END AS attempt_group,
    COUNT(*) AS referral_count,
    SUM(first_scheduled_at IS NOT NULL) AS scheduled_referrals,
    ROUND(
        SUM(first_scheduled_at IS NOT NULL) / NULLIF(COUNT(*), 0),
        4
    ) AS scheduling_rate
FROM v_referral_lifecycle
GROUP BY attempt_group
ORDER BY MIN(outreach_attempt_count);

-- ============================================================================
-- 11. APPOINTMENT OUTCOMES
-- ============================================================================

SELECT
    appointment_status,
    COUNT(*) AS appointment_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS percent_of_appointments,
    COUNT(DISTINCT referral_id) AS distinct_referrals
FROM appointments
GROUP BY appointment_status
ORDER BY appointment_count DESC;

-- ============================================================================
-- 12. CONSULTATION REPORT PERFORMANCE
-- ============================================================================

SELECT
    report_source,
    COUNT(*) AS report_count,
    SUM(match_status = 'Matched') AS matched_reports,
    SUM(report_status = 'Reviewed') AS reviewed_reports,
    ROUND(
        SUM(match_status = 'Matched') / NULLIF(COUNT(*), 0),
        4
    ) AS match_rate,
    ROUND(
        SUM(report_status = 'Reviewed') / NULLIF(COUNT(*), 0),
        4
    ) AS review_completion_rate,
    ROUND(
        AVG(TIMESTAMPDIFF(HOUR, received_at, reviewed_at)) / 24.0,
        2
    ) AS average_received_to_review_days
FROM consult_reports
GROUP BY report_source
ORDER BY report_count DESC;

-- Completed visits still awaiting reports, by specialty.
SELECT
    specialty_name,
    COUNT(*) AS report_pending_referrals,
    SUM(priority = 'Urgent') AS urgent_report_pending,
    SUM(overdue_flag) AS overdue_report_pending,
    ROUND(AVG(current_stage_age_hours), 1) AS average_pending_age_hours,
    MAX(current_stage_age_hours) AS maximum_pending_age_hours
FROM v_referral_lifecycle
WHERE current_status = 'Completed—Report Pending'
GROUP BY specialty_name
ORDER BY overdue_report_pending DESC, report_pending_referrals DESC;

-- ============================================================================
-- 13. NON-COMPLETION AND REFERRAL LEAKAGE
-- ============================================================================

SELECT
    closure_reason,
    COUNT(*) AS referral_count,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER (),
        4
    ) AS percent_of_noncompleted_closures,
    SUM(priority = 'Urgent') AS urgent_referrals
FROM v_referral_lifecycle
WHERE current_status = 'Closed—Not Completed'
GROUP BY closure_reason
ORDER BY referral_count DESC, closure_reason;

SELECT
    referring_location_name,
    specialty_name,
    COUNT(*) AS leaked_referrals,
    ROUND(AVG(days_to_first_outreach), 2) AS average_days_to_first_outreach,
    ROUND(AVG(outreach_attempt_count), 2) AS average_outreach_attempts
FROM v_referral_lifecycle
WHERE referral_leakage_flag = 1
GROUP BY referring_location_name, specialty_name
HAVING COUNT(*) >= 3
ORDER BY leaked_referrals DESC, referring_location_name, specialty_name;

-- ============================================================================
-- 14. STAFF WORKLOAD DISTRIBUTION
-- ============================================================================

SELECT
    current_owner_user_id,
    current_owner_name,
    COUNT(*) AS active_referral_count,
    SUM(priority = 'Urgent') AS urgent_referral_count,
    SUM(overdue_flag) AS overdue_referral_count,
    ROUND(AVG(current_stage_age_hours), 1) AS average_stage_age_hours
FROM v_operational_work_queue
GROUP BY current_owner_user_id, current_owner_name
ORDER BY active_referral_count DESC, current_owner_name;

-- ============================================================================
-- 15. OPEN DATA-QUALITY EXCEPTIONS
-- ============================================================================

SELECT
    severity,
    rule_code,
    field_name,
    COUNT(*) AS open_issue_count,
    ROUND(AVG(issue_age_hours), 1) AS average_issue_age_hours,
    MAX(issue_age_hours) AS maximum_issue_age_hours
FROM v_data_exception_queue
GROUP BY severity, rule_code, field_name
ORDER BY
    MIN(severity_sort),
    open_issue_count DESC,
    rule_code;

-- ============================================================================
-- 16. MONTHLY REFERRAL VOLUME AND CLOSED-LOOP COHORT PERFORMANCE
-- Cohort month is based on referral receipt, not closure month.
-- ============================================================================

SELECT
    referral_month,
    COUNT(*) AS referral_count,
    SUM(priority = 'Urgent') AS urgent_referrals,
    SUM(first_scheduled_at IS NOT NULL) AS scheduled_referrals,
    SUM(first_completed_appointment_at IS NOT NULL) AS completed_referrals,
    SUM(closed_loop_flag) AS closed_loop_referrals,
    ROUND(SUM(closed_loop_flag) / NULLIF(COUNT(*), 0), 4)
        AS closed_loop_rate,
    SUM(overdue_flag) AS currently_overdue_referrals
FROM v_referral_lifecycle
GROUP BY referral_month
ORDER BY referral_month;

-- ============================================================================
-- 17. TOP 25 ACTIONABLE REFERRALS
-- Operational inspection query; patient names are intentionally excluded.
-- ============================================================================

SELECT
    referral_id,
    work_priority,
    priority,
    current_status,
    current_queue,
    current_owner_name,
    referring_location_name,
    specialty_name,
    service_level_due_at,
    current_stage_age_hours,
    outreach_attempt_count,
    recommended_next_action
FROM v_operational_work_queue
ORDER BY
    priority_sort,
    overdue_sort,
    service_level_due_at,
    referral_received_at
LIMIT 25;

-- End of analytics_queries.sql
