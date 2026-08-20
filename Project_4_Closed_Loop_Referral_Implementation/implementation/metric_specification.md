# Metric Specification

## Project

**Closed-Loop Specialty Referral Management: Healthcare SaaS Implementation and Analytics**

## Purpose

This document governs the KPI definitions used in SQL, Tableau, implementation validation, and portfolio reporting. Each metric defines its business meaning, grain, numerator, denominator, exclusions, date logic, null handling, and interpretation limits.

All values are derived from synthetic data. They demonstrate measurement design and do not represent actual client performance.

## Measurement Conventions

| Convention | Definition |
|---|---|
| Primary analytical grain | One row per referral in `v_referral_lifecycle` |
| Cohort date | `referral_received_at` unless otherwise specified |
| Operational as-of time | `CURRENT_TIMESTAMP` in operational views |
| Terminal statuses | `Closed—Completed`, `Closed—Not Completed`, `Cancelled` |
| Active referral | Any referral not in a terminal status |
| Qualifying report | A report linked to the referral with appropriate matching, routing, and review evidence |
| Rate display | SQL decimal values displayed as percentages in Tableau |
| Cycle-time unit | Calendar days calculated from timestamp differences; business-day calculations are a future enhancement |
| Missing milestone | Excluded from averages for that milestone; retained in the applicable rate denominator |

## Baseline KPI Summary

| KPI | Synthetic result |
|---|---:|
| Total referrals | 2,500 |
| Urgent referrals | 314 |
| Open referrals | 965 |
| Overdue open referrals | 965 |
| Intake completeness rate | 94.36% |
| Scheduling conversion rate | 77.48% |
| Appointment completion rate | 79.12% |
| Closed-loop rate | 45.92% |
| Referral leakage rate | 13.54% |
| Average days to schedule | 3.76 |
| Average days to completion | 23.15 |
| Average report turnaround | 5.58 days |

## KPI Definitions

### KPI-001: Total Referrals

| Component | Specification |
|---|---|
| Business question | How many referrals entered the defined cohort? |
| Numerator | Count of distinct `referral_id` values |
| Denominator | Not applicable |
| Inclusion | Every accepted referral in the selected cohort |
| Exclusion | Rejected raw source rows that never received a target referral ID |
| Date field | `referral_received_at` |
| Null handling | `referral_id` is non-null by database design |
| Baseline result | 2,500 |

### KPI-002: Urgent Referral Count and Rate

| Component | Specification |
|---|---|
| Business question | What volume and share of referrals were clinically designated urgent? |
| Numerator | Referrals where `priority = 'Urgent'` |
| Denominator | Total referrals for the urgent-referral rate |
| Exclusion | None after accepted data pass priority validation |
| Date field | `referral_received_at` |
| Interpretation | Describes documented priority; it does not validate clinical appropriateness |
| Baseline result | 314 referrals; 12.56% of referrals |

### KPI-003: Open Referral Count

| Component | Specification |
|---|---|
| Business question | How many referrals still require operational or clinical follow-up? |
| Numerator | Referrals not in a terminal status |
| Denominator | Not applicable |
| Exclusion | `Closed—Completed`, `Closed—Not Completed`, and `Cancelled` |
| As-of logic | Current status at query time |
| Baseline result | 965 |

### KPI-004: Overdue Open Referrals

| Component | Specification |
|---|---|
| Business question | How many active referrals have exceeded the service level for their current stage? |
| Numerator | Active referrals where `service_level_due_at < CURRENT_TIMESTAMP` |
| Denominator | Open referrals for the overdue-open rate |
| Exclusion | Terminal referrals and active referrals without an applicable due timestamp |
| Null handling | Null due dates are not automatically classified overdue; they should be reviewed as configuration exceptions |
| Baseline result | 965; 100% of open referrals |
| Interpretation | The synthetic dataset intentionally models a historical unresolved backlog. This is not a recommended target or real-world benchmark. |

### KPI-005: Intake Completeness Rate

| Component | Specification |
|---|---|
| Business question | What share of accepted referrals completed blocking intake validation? |
| Numerator | Referrals with non-null `initial_validation_completed_at` |
| Denominator | Total accepted referrals |
| Exclusion | Rejected source records without a target referral ID |
| Date field | Referral cohort defined by `referral_received_at` |
| Null handling | Null validation timestamp counts as not completed |
| Baseline result | 94.36% |

### KPI-006: Scheduling Conversion Rate

| Component | Specification |
|---|---|
| Business question | Among referrals reaching patient outreach, what share were scheduled? |
| Numerator | Referrals with non-null `first_scheduled_at` |
| Denominator | Referrals with non-null `first_outreach_at` |
| Exclusion | Referrals not yet reaching outreach |
| Date field | Referral cohort defined by `referral_received_at` |
| Null handling | Outreach referrals with null scheduling timestamp remain denominator-only |
| Baseline result | 77.48% |
| Interpretation | Association with workflow progression; it does not measure clinical need or appointment appropriateness |

### KPI-007: Appointment Completion Rate

| Component | Specification |
|---|---|
| Business question | Among referrals ever scheduled, what share reached a completed specialist appointment? |
| Numerator | Referrals with non-null `first_completed_appointment_at` |
| Denominator | Referrals with non-null `first_scheduled_at` |
| Exclusion | Referrals never scheduled |
| Null handling | Scheduled referrals without completion remain denominator-only |
| Baseline result | 79.12% |
| Limitation | Referral-level rate; repeated appointments do not increase the numerator |

### KPI-008: Closed-Loop Rate

| Component | Specification |
|---|---|
| Business question | What share of referrals completed the specialist visit and returned required clinical communication? |
| Numerator | Referrals satisfying `closed_loop_flag = 1` |
| Denominator | Total accepted referrals |
| Required evidence | Completed appointment, linked report receipt, routing, review, and `Closed—Completed` status |
| Exclusion | None in the portfolio baseline; production reporting may require cohort-maturity exclusions |
| Null handling | Missing required milestones count as not closed loop |
| Baseline result | 45.92% |
| Limitation | Recent cohorts have had less time to mature; production reporting should consider a defined completion window |

### KPI-009: Referral Leakage Rate

| Component | Specification |
|---|---|
| Business question | Among referrals reaching outreach, what share closed without verified specialty completion? |
| Numerator | Referrals where `referral_leakage_flag = 1` |
| Denominator | Referrals with non-null `first_outreach_at` |
| Current flag logic | `Closed—Not Completed`, outreach initiated, and no completed specialist appointment |
| Exclusion | Cancelled referrals and referrals not reaching outreach |
| Baseline result | 13.54% |
| Limitation | This operational definition includes some legitimate non-completion paths and therefore should not be interpreted as avoidable leakage without reason-level review |

### KPI-010: Days to Schedule

| Component | Specification |
|---|---|
| Business question | How long did it take to schedule the first qualifying specialist appointment? |
| Start | `referral_received_at` |
| End | `first_scheduled_at` |
| Population | Referrals with a scheduling milestone |
| Unit | Calendar days, calculated from hours divided by 24 |
| Null handling | Unscheduled referrals excluded from average and median; scheduling rate captures noncompletion |
| Baseline average | 3.76 days |
| Preferred summary | Report median with average as a secondary measure because delays may be right-skewed |

### KPI-011: Days to Completion

| Component | Specification |
|---|---|
| Business question | How long did it take from referral receipt to the first completed specialist appointment? |
| Start | `referral_received_at` |
| End | `first_completed_appointment_at` |
| Population | Referrals with a completed specialist appointment |
| Unit | Calendar days |
| Null handling | Referrals without completion excluded from cycle-time averages and retained in completion-rate reporting |
| Baseline average | 23.15 days |
| Preferred summary | Median plus interquartile range in future analytical enhancement |

### KPI-012: Consultation Report Turnaround

| Component | Specification |
|---|---|
| Business question | How long after the completed visit did NorthStar receive the qualifying consultation report? |
| Start | `first_completed_appointment_at` |
| End | `first_report_received_at` |
| Population | Referrals with both milestones |
| Unit | Calendar days |
| Null handling | Completed visits without a report are excluded from the average but remain visible in the report-pending queue |
| Baseline average | 5.58 days |
| Interpretation | Measure report receipt separately from clinician review time |

### KPI-013: No-Show Rate

| Component | Specification |
|---|---|
| Business question | What share of elapsed appointments resulted in no-show? |
| Numerator | Appointment records where `appointment_status = 'No-show'` |
| Denominator | Elapsed appointments with final outcomes: `Completed`, `Cancelled`, or `No-show` |
| Exclusion | Future scheduled, unknown, and superseded rescheduled appointment records |
| Grain | One row per appointment, not referral |
| Date field | `appointment_start_at` |
| Null handling | Unknown outcomes are excluded and reported separately as an operational exception |

### KPI-014: Report Review Completion Rate

| Component | Specification |
|---|---|
| Business question | What share of received consultation reports were documented as reviewed? |
| Numerator | Reports where `report_status = 'Reviewed'` and required reviewer/timestamps are present |
| Denominator | Valid nonduplicate received reports |
| Exclusion | Rejected and duplicate reports |
| Grain | One row per consultation report |
| Interpretation | Report processing metric; not the same as overall referral closed-loop rate |

### KPI-015: Open Validation Issues

| Component | Specification |
|---|---|
| Business question | How many data or workflow exceptions still require resolution? |
| Numerator | Issues with `resolution_status IN ('Open', 'In Progress')` |
| Denominator | Not applicable |
| Segmentation | Severity, rule, field, site, specialty, and age |
| Baseline result | 93 open issues in `v_data_exception_queue` |
| Interpretation | Represents an actionable exception backlog, not a clinical error rate |

## Dashboard Filter Rules

The Tableau dashboard should support filters for:

- Referral received month
- Referring location
- Specialty
- Payer and payer category
- Referring practitioner
- Priority
- Current status
- Current queue
- Current owner

Filters should operate on the referral-level lifecycle dataset unless a worksheet explicitly uses appointment-, report-, or issue-level grain.

## Double-Counting Controls

1. Referral KPIs use `v_referral_lifecycle`, which contains one row per referral.
2. Appointment KPIs use `appointments`, with explicit appointment-level denominators.
3. Report KPIs use `consult_reports`, with duplicate and rejection exclusions where defined.
4. Status-history and outreach-event tables are aggregated before joining to referral-level analysis.
5. Funnel stages are reached-stage counts, not mutually exclusive current-status counts.
6. Site and specialty totals must reconcile to the 2,500-referral cohort when no filters apply.

## Interpretation and Evidence Limits

- All metrics describe a deterministic synthetic scenario.
- The results do not estimate the effect of a real SaaS implementation.
- Differences across sites, specialties, payers, or staff are descriptive associations and should not be interpreted as causal.
- The scenario contains deliberately aged open referrals to demonstrate escalation and backlog-management functionality.
- Average cycle times describe only referrals reaching the relevant milestone; paired rate metrics must be displayed to prevent survivorship bias.
- Production deployment would require business-day calendars, cohort-maturity rules, privacy review, source-system reconciliation, and stakeholder approval.

## Acceptance Criteria

The metric framework is acceptable when:

1. Every dashboard KPI maps to a documented numerator and denominator.
2. SQL results reconcile with Tableau outputs.
3. Grain is explicit for referral-, appointment-, report-, and issue-level metrics.
4. Null and exclusion logic are documented.
5. Synthetic findings are labeled transparently.
6. Rates are presented with their underlying counts where practical.
7. Cycle-time metrics are paired with milestone-completion rates.

