USE healthcare_prior_authorization;

-- ============================================================
-- ANALYTICAL REFERENCE TIME
-- Fixed at July 1, 2026 for reproducible pending-age metrics.
-- ============================================================

CREATE OR REPLACE VIEW vw_authorization_operations AS

SELECT
    ar.authorization_id,
    ar.patient_id,
    ar.provider_id,
    pr.provider_name,
    pr.specialty,
    c.coverage_id,
    py.payer_id,
    py.payer_name,
    py.plan_type,
    ar.procedure_id,
    pc.procedure_code,
    pc.procedure_description,
    pc.service_category,
    ar.diagnosis_id,
    d.diagnosis_code,
    d.diagnosis_description,
    ar.created_at,
    ar.submitted_at,
    ar.decision_at,
    ar.requested_service_date,
    ar.urgency,
    ar.initial_submission_complete,
    ar.documentation_status,
    ar.current_status,
    ar.authorization_number,
    ar.denial_reason,

    CASE
        WHEN ar.urgency = 'expedited'
            THEN py.expedited_sla_hours
        ELSE py.standard_sla_hours
    END AS applicable_sla_hours,

    CASE
        WHEN ar.current_status IN ('Approved', 'Denied')
            THEN 1
        ELSE 0
    END AS final_decision_flag,

    CASE
        WHEN ar.current_status = 'Approved'
            THEN 'Approved'
        WHEN ar.current_status = 'Denied'
            THEN 'Denied'
        ELSE 'No Final Decision'
    END AS decision_outcome,

    CASE
        WHEN ar.submitted_at IS NOT NULL
         AND ar.current_status NOT IN (
             'Approved',
             'Denied',
             'Cancelled'
         )
            THEN 1
        ELSE 0
    END AS pending_flag,

    CASE
        WHEN ar.decision_at IS NOT NULL
            THEN TIMESTAMPDIFF(
                HOUR,
                ar.submitted_at,
                ar.decision_at
            )
        ELSE NULL
    END AS turnaround_hours,

    CASE
        WHEN ar.submitted_at IS NOT NULL
         AND ar.current_status NOT IN (
             'Approved',
             'Denied',
             'Cancelled'
         )
            THEN TIMESTAMPDIFF(
                HOUR,
                ar.submitted_at,
                '2026-07-01 00:00:00'
            )
        ELSE NULL
    END AS pending_age_hours,

    CASE
        WHEN ar.submitted_at IS NOT NULL
         AND ar.current_status NOT IN (
             'Approved',
             'Denied',
             'Cancelled'
         )
         AND TIMESTAMPDIFF(
             HOUR,
             ar.submitted_at,
             '2026-07-01 00:00:00'
         ) >
         CASE
             WHEN ar.urgency = 'expedited'
                 THEN py.expedited_sla_hours
             ELSE py.standard_sla_hours
         END
            THEN 1
        ELSE 0
    END AS overdue_flag,

    CASE
        WHEN ar.decision_at IS NOT NULL
         AND TIMESTAMPDIFF(
             HOUR,
             ar.submitted_at,
             ar.decision_at
         ) <=
         CASE
             WHEN ar.urgency = 'expedited'
                 THEN py.expedited_sla_hours
             ELSE py.standard_sla_hours
         END
            THEN 1
        WHEN ar.decision_at IS NOT NULL
            THEN 0
        ELSE NULL
    END AS decision_within_sla_flag,

    CASE
        WHEN COALESCE(sh.rework_events, 0) > 0
            THEN 1
        ELSE 0
    END AS rework_flag,

    COALESCE(sh.rework_events, 0) AS rework_event_count

FROM authorization_requests AS ar

JOIN providers AS pr
    ON ar.provider_id = pr.provider_id

JOIN coverages AS c
    ON ar.coverage_id = c.coverage_id

JOIN payers AS py
    ON c.payer_id = py.payer_id

JOIN procedures AS pc
    ON ar.procedure_id = pc.procedure_id

JOIN diagnoses AS d
    ON ar.diagnosis_id = d.diagnosis_id

LEFT JOIN (
    SELECT
        authorization_id,
        SUM(
            CASE
                WHEN status = 'Additional Information Required'
                    THEN 1
                ELSE 0
            END
        ) AS rework_events
    FROM status_history
    GROUP BY authorization_id
) AS sh
    ON ar.authorization_id = sh.authorization_id;


-- ============================================================
-- 1. VERIFY THE VIEW
-- Expected: 200 rows
-- ============================================================

SELECT COUNT(*) AS view_record_count
FROM vw_authorization_operations;


-- ============================================================
-- 2. EXECUTIVE KPI SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_requests,

    SUM(submitted_at IS NOT NULL)
        AS submitted_requests,

    SUM(final_decision_flag)
        AS finalized_requests,

    ROUND(
        100.0 * SUM(current_status = 'Approved')
        / NULLIF(SUM(final_decision_flag), 0),
        1
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(current_status = 'Denied')
        / NULLIF(SUM(final_decision_flag), 0),
        1
    ) AS denial_rate_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN submitted_at IS NOT NULL
                    THEN initial_submission_complete
                ELSE 0
            END
        )
        / NULLIF(SUM(submitted_at IS NOT NULL), 0),
        1
    ) AS first_pass_completeness_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN submitted_at IS NOT NULL
                    THEN rework_flag
                ELSE 0
            END
        )
        / NULLIF(SUM(submitted_at IS NOT NULL), 0),
        1
    ) AS rework_rate_pct,

    ROUND(
        AVG(turnaround_hours),
        1
    ) AS average_turnaround_hours,

    ROUND(
        100.0 * SUM(decision_within_sla_flag = 1)
        / NULLIF(
            SUM(decision_within_sla_flag IS NOT NULL),
            0
        ),
        1
    ) AS decision_sla_compliance_pct,

    SUM(pending_flag)
        AS pending_requests,

    ROUND(
        AVG(
            CASE
                WHEN pending_flag = 1
                    THEN pending_age_hours
            END
        ),
        1
    ) AS average_pending_age_hours,

    SUM(overdue_flag)
        AS overdue_requests,

    ROUND(
        100.0 * SUM(overdue_flag)
        / NULLIF(SUM(pending_flag), 0),
        1
    ) AS overdue_pending_rate_pct

FROM vw_authorization_operations;


-- ============================================================
-- 3. STATUS DISTRIBUTION
-- ============================================================

SELECT
    current_status,
    COUNT(*) AS request_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        1
    ) AS percentage_of_requests
FROM vw_authorization_operations
GROUP BY current_status
ORDER BY request_count DESC;


-- ============================================================
-- 4. PAYER PERFORMANCE
-- ============================================================

SELECT
    payer_name,
    COUNT(*) AS total_requests,
    SUM(final_decision_flag) AS finalized_requests,

    ROUND(
        100.0 * SUM(current_status = 'Approved')
        / NULLIF(SUM(final_decision_flag), 0),
        1
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(rework_flag)
        / COUNT(*),
        1
    ) AS rework_rate_pct,

    ROUND(
        AVG(turnaround_hours),
        1
    ) AS average_turnaround_hours,

    SUM(pending_flag) AS pending_requests,
    SUM(overdue_flag) AS overdue_requests

FROM vw_authorization_operations
GROUP BY payer_id, payer_name
ORDER BY average_turnaround_hours DESC;


-- ============================================================
-- 5. PROCEDURE PERFORMANCE
-- ============================================================

SELECT
    procedure_code,
    procedure_description,
    COUNT(*) AS request_count,
    SUM(current_status = 'Approved') AS approvals,
    SUM(current_status = 'Denied') AS denials,

    ROUND(
        100.0 * SUM(current_status = 'Denied')
        / NULLIF(SUM(final_decision_flag), 0),
        1
    ) AS denial_rate_pct,

    ROUND(
        AVG(turnaround_hours),
        1
    ) AS average_turnaround_hours

FROM vw_authorization_operations
GROUP BY
    procedure_code,
    procedure_description
ORDER BY request_count DESC;


-- ============================================================
-- 6. DENIAL REASONS
-- ============================================================

SELECT
    denial_reason,
    COUNT(*) AS denial_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        1
    ) AS percentage_of_denials
FROM vw_authorization_operations
WHERE current_status = 'Denied'
GROUP BY denial_reason
ORDER BY denial_count DESC;


-- ============================================================
-- 7. OVERDUE WORK QUEUE
-- ============================================================

SELECT
    authorization_id,
    patient_id,
    provider_name,
    payer_name,
    procedure_description,
    urgency,
    current_status,
    submitted_at,
    applicable_sla_hours,
    pending_age_hours
FROM vw_authorization_operations
WHERE overdue_flag = 1
ORDER BY
    urgency = 'expedited' DESC,
    pending_age_hours DESC;
	