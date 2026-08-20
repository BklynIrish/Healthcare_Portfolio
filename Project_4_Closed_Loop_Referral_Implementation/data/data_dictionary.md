# Data Dictionary

## Project

**Closed-Loop Specialty Referral Management: Healthcare SaaS Implementation and Analytics**

## Purpose

This document defines the physical fields planned for the NorthStar Medical Group referral-management database. It is the build specification for the MySQL schema, synthetic-data generator, migration mapping, data-quality checks, analytical views, and selected FHIR mappings.

All records will be synthetic. No protected health information, live credentials, or real clinical documents will be stored.

## Conventions

| Convention | Definition |
|---|---|
| `PK` | Primary key |
| `FK` | Foreign key |
| `UQ` | Unique constraint |
| `NN` | `NOT NULL` |
| `NULL` | Value may be absent |
| Boolean | MySQL `BOOLEAN`, implemented as `TINYINT(1)`; allowed values `0` and `1` |
| Timestamp | MySQL `DATETIME`; interpreted as UTC in the portfolio dataset |
| Identifier | Readable synthetic `VARCHAR` value with an entity prefix |

## Identifier Formats

| Entity | Example format |
|---|---|
| Patient | `PAT000001` |
| Organization | `ORG001` |
| Location | `LOC001` |
| Practitioner | `PRC0001` |
| Payer | `PAY001` |
| Coverage | `COV000001` |
| Specialty | `SPC001` |
| User | `USR001` |
| Referral | `REF000001` |
| Status history | `STH000001` |
| Outreach attempt | `OUT000001` |
| Appointment | `APT000001` |
| Consultation report | `RPT000001` |
| Validation issue | `VAL000001` |
| Assignment | `ASN000001` |

# 1. `patients`

**Grain:** One row per synthetic patient.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `patient_id` | `VARCHAR(12)` | PK, NN | `PAT` + six digits | Internal synthetic patient identifier; unique and immutable |
| `source_patient_id` | `VARCHAR(30)` | UQ, NN | Synthetic source-system identifier | Preserves source traceability |
| `first_name` | `VARCHAR(50)` | NN | Synthetic text | Synthetic given name |
| `last_name` | `VARCHAR(50)` | NN | Synthetic text | Synthetic family name |
| `date_of_birth` | `DATE` | NN | Valid past date | Must precede dataset end date; ages should remain plausible for the scenario |
| `administrative_sex` | `VARCHAR(20)` | NN | `Female`, `Male`, `Unknown`, `Other` | Administrative value used only for synthetic operational data |
| `phone_number` | `VARCHAR(20)` | NULL | Synthetic telephone format | May be null to create outreach exceptions |
| `email_address` | `VARCHAR(100)` | NULL | Synthetic email format | Must contain a valid synthetic domain when populated |
| `preferred_contact_channel` | `VARCHAR(20)` | NULL | `Phone`, `SMS`, `Patient Portal`, `Email`, `Mail` | Patient communication preference when known |
| `preferred_language` | `VARCHAR(40)` | NN | Controlled synthetic language list | Defaults to `English`; supports language-access scenarios |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 2. `organizations`

**Grain:** One row per internal practice or external specialist organization.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `organization_id` | `VARCHAR(10)` | PK, NN | `ORG` + three digits | Internal organization identifier |
| `source_organization_id` | `VARCHAR(30)` | UQ, NULL | Synthetic source identifier | Source traceability when available |
| `organization_name` | `VARCHAR(120)` | NN | Synthetic organization name | Display name |
| `organization_type` | `VARCHAR(30)` | NN | `Primary Care Practice`, `Specialist Practice`, `Hospital`, `Imaging Center`, `Other` | Organization classification |
| `internal_flag` | `BOOLEAN` | NN | `0`, `1` | `1` for NorthStar-controlled organizations |
| `synthetic_npi` | `CHAR(10)` | UQ, NULL | Ten numeric characters | Fictional organizational NPI-like value; not a real credential |
| `phone_number` | `VARCHAR(20)` | NULL | Synthetic telephone format | Main telephone number |
| `fax_number` | `VARCHAR(20)` | NULL | Synthetic fax format | Used for mixed-channel workflow simulation |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 3. `locations`

**Grain:** One row per physical or virtual service location.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `location_id` | `VARCHAR(10)` | PK, NN | `LOC` + three digits | Internal location identifier |
| `organization_id` | `VARCHAR(10)` | FK, NN | Existing organization | References `organizations.organization_id` |
| `location_name` | `VARCHAR(120)` | NN | Synthetic text | Location display name |
| `address_line_1` | `VARCHAR(120)` | NULL | Synthetic address | No real patient address information |
| `city` | `VARCHAR(60)` | NULL | Synthetic city | Location city |
| `state_code` | `CHAR(2)` | NULL | Valid US postal abbreviation | Defaults to regional synthetic scenario values |
| `postal_code` | `VARCHAR(10)` | NULL | Synthetic ZIP format | Stored as text to preserve leading zeros |
| `phone_number` | `VARCHAR(20)` | NULL | Synthetic telephone format | Location telephone number |
| `telehealth_flag` | `BOOLEAN` | NN | `0`, `1` | `1` when the location represents virtual service capability |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 4. `specialties`

**Grain:** One row per controlled specialty category.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `specialty_id` | `VARCHAR(10)` | PK, NN | `SPC` + three digits | Internal specialty identifier |
| `specialty_code` | `VARCHAR(20)` | UQ, NN | Uppercase short code | Stable analytical code |
| `specialty_name` | `VARCHAR(80)` | UQ, NN | Controlled specialty name | Human-readable specialty |
| `routine_intake_sla_hours` | `INT` | NN | Positive integer | Default hours allowed for routine intake validation |
| `urgent_intake_sla_hours` | `INT` | NN | Positive integer | Must be less than or equal to routine intake SLA |
| `routine_outreach_sla_hours` | `INT` | NN | Positive integer | Default routine outreach SLA |
| `urgent_outreach_sla_hours` | `INT` | NN | Positive integer | Must be less than or equal to routine outreach SLA |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 5. `practitioners`

**Grain:** One row per synthetic referring or specialist practitioner.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `practitioner_id` | `VARCHAR(12)` | PK, NN | `PRC` + four digits | Internal practitioner identifier |
| `source_practitioner_id` | `VARCHAR(30)` | UQ, NULL | Synthetic source identifier | Source traceability |
| `organization_id` | `VARCHAR(10)` | FK, NN | Existing organization | Primary organization in the MVP |
| `specialty_id` | `VARCHAR(10)` | FK, NULL | Existing specialty | Required for specialist clinicians; may be null for generalist roles |
| `first_name` | `VARCHAR(50)` | NN | Synthetic text | Synthetic given name |
| `last_name` | `VARCHAR(50)` | NN | Synthetic text | Synthetic family name |
| `practitioner_role` | `VARCHAR(30)` | NN | `Referring Clinician`, `Specialist`, `Medical Director`, `Other` | Operational practitioner classification |
| `synthetic_npi` | `CHAR(10)` | UQ, NN | Ten numeric characters | Fictional NPI-like value; not a real credential |
| `internal_flag` | `BOOLEAN` | NN | `0`, `1` | `1` for NorthStar-affiliated clinicians |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 6. `payers`

**Grain:** One row per synthetic payer.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `payer_id` | `VARCHAR(10)` | PK, NN | `PAY` + three digits | Internal payer identifier |
| `payer_name` | `VARCHAR(100)` | UQ, NN | Synthetic payer name | Display name |
| `payer_category` | `VARCHAR(30)` | NN | `Commercial`, `Medicare`, `Medicaid`, `Self-Pay`, `Other` | High-level analytical category |
| `electronic_payer_id` | `VARCHAR(20)` | UQ, NULL | Synthetic code | Fictional routing identifier |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 7. `coverages`

**Grain:** One row per patient coverage period.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `coverage_id` | `VARCHAR(12)` | PK, NN | `COV` + six digits | Internal coverage identifier |
| `source_coverage_id` | `VARCHAR(30)` | UQ, NULL | Synthetic source identifier | Source traceability |
| `patient_id` | `VARCHAR(12)` | FK, NN | Existing patient | References `patients.patient_id` |
| `payer_id` | `VARCHAR(10)` | FK, NN | Existing payer | References `payers.payer_id` |
| `member_id` | `VARCHAR(30)` | NN | Synthetic member identifier | Must not represent a real insurance number |
| `plan_name` | `VARCHAR(100)` | NULL | Synthetic plan name | Plan display value |
| `coverage_type` | `VARCHAR(30)` | NN | `Commercial`, `Medicare`, `Medicaid`, `Self-Pay`, `Other` | Should align with payer category where applicable |
| `coverage_status` | `VARCHAR(20)` | NN | `Active`, `Inactive`, `Pending`, `Unknown` | Status at the relevant coverage period |
| `effective_date` | `DATE` | NN | Valid date | Coverage start date |
| `termination_date` | `DATE` | NULL | Valid date | Cannot precede `effective_date` |
| `primary_coverage_flag` | `BOOLEAN` | NN | `0`, `1` | Indicates primary coverage for the period |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 8. `users`

**Grain:** One row per simulated application user.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `user_id` | `VARCHAR(10)` | PK, NN | `USR` + three digits | Internal user identifier |
| `organization_id` | `VARCHAR(10)` | FK, NULL | Existing organization | User's primary organization |
| `location_id` | `VARCHAR(10)` | FK, NULL | Existing location | User's primary site when applicable |
| `display_name` | `VARCHAR(100)` | NN | Synthetic name | User-facing name |
| `user_role` | `VARCHAR(40)` | NN | `Referral Coordinator`, `Referral Manager`, `Referring Clinician`, `Practice Manager`, `Medical Director`, `Health IT Support`, `Data Analyst`, `System Administrator`, `Auditor` | Drives conceptual role-based access |
| `active_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 9. `referrals`

**Grain:** One row per referral, containing the current operational state and major lifecycle milestones.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `referral_id` | `VARCHAR(12)` | PK, NN | `REF` + six digits | Internal referral identifier |
| `source_referral_id` | `VARCHAR(30)` | UQ, NN | Synthetic source identifier | Unique within the source system for this MVP |
| `source_system` | `VARCHAR(40)` | NN | `NorthStar EHR`, `Manual Entry`, `FHIR Test` | Referral origin |
| `patient_id` | `VARCHAR(12)` | FK, NN | Existing patient | References `patients.patient_id` |
| `coverage_id` | `VARCHAR(12)` | FK, NULL | Existing coverage | Must belong to the same patient |
| `referring_practitioner_id` | `VARCHAR(12)` | FK, NN | Existing practitioner | Ordering clinician |
| `referring_organization_id` | `VARCHAR(10)` | FK, NN | Existing organization | Originating organization |
| `referring_location_id` | `VARCHAR(10)` | FK, NN | Existing location | Must belong to the referring organization |
| `specialty_id` | `VARCHAR(10)` | FK, NN | Existing specialty | Requested specialty |
| `destination_practitioner_id` | `VARCHAR(12)` | FK, NULL | Existing practitioner | Selected specialist when known |
| `destination_organization_id` | `VARCHAR(10)` | FK, NULL | Existing organization | Selected destination when known |
| `current_owner_user_id` | `VARCHAR(10)` | FK, NULL | Existing active user | Current accountable user; may be null only when a valid queue owns the referral or an exception exists |
| `source_ordered_at` | `DATETIME` | NN | UTC timestamp | Date and time the source order was created |
| `referral_received_at` | `DATETIME` | NN | UTC timestamp | Cannot materially precede source order without a documented migration exception |
| `clinical_reason` | `TEXT` | NN | Synthetic clinical text | Reason for referral; no real patient information |
| `diagnosis_code` | `VARCHAR(12)` | NULL | Synthetic ICD-10-CM-like code | Used for scenario realism; mappings will be documented |
| `priority` | `VARCHAR(10)` | NN | `Routine`, `Urgent` | Clinically assigned priority preserved by the workflow |
| `current_status` | `VARCHAR(40)` | NN | See referral status values | Current lifecycle status |
| `current_queue` | `VARCHAR(40)` | NULL | See queue values | Required when no individual owner is assigned to an active referral |
| `current_stage_started_at` | `DATETIME` | NN | UTC timestamp | Timestamp when current status began |
| `service_level_due_at` | `DATETIME` | NULL | UTC timestamp | Calculated or assigned due timestamp for the current stage |
| `initial_validation_completed_at` | `DATETIME` | NULL | UTC timestamp | First time blocking intake validation passed |
| `first_outreach_at` | `DATETIME` | NULL | UTC timestamp | Derived or synchronized from outreach events |
| `first_scheduled_at` | `DATETIME` | NULL | UTC timestamp | First time an appointment was scheduled |
| `first_completed_appointment_at` | `DATETIME` | NULL | UTC timestamp | First qualifying specialist completion timestamp |
| `first_report_received_at` | `DATETIME` | NULL | UTC timestamp | First qualifying consultation-report receipt |
| `closed_at` | `DATETIME` | NULL | UTC timestamp | Required for terminal statuses; cannot precede receipt |
| `closure_category` | `VARCHAR(20)` | NULL | `Completed`, `Not Completed`, `Cancelled` | Required for terminal referrals and aligned with status |
| `closure_reason` | `VARCHAR(80)` | NULL | Approved reason list | Required for `Closed—Not Completed` and selected cancellations |
| `created_at` | `DATETIME` | NN | UTC timestamp | Target record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

### Referral status values

- `Received`
- `Needs Information`
- `Ready for Outreach`
- `Outreach in Progress`
- `Scheduled`
- `Completed—Report Pending`
- `Closed—Completed`
- `Closed—Not Completed`
- `Cancelled`

### Queue values

- `New Intake`
- `Needs Information`
- `Ready for Outreach`
- `Outreach Follow-Up`
- `Appointment Verification`
- `Report Pending`
- `Urgent Escalations`
- `Unassigned Referrals`
- `Data Exceptions`

### Approved non-completion reasons

- `Patient Declined`
- `Unable to Contact After Protocol`
- `No Longer Clinically Indicated`
- `Transferred Care`
- `Patient Moved`
- `Duplicate Referral`
- `Insurance or Access Barrier`
- `Patient Chose Another Provider`
- `Other Authorized Reason`

# 10. `referral_status_history`

**Grain:** One row per material status transition.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `status_history_id` | `VARCHAR(12)` | PK, NN | `STH` + six digits | Status-event identifier |
| `referral_id` | `VARCHAR(12)` | FK, NN | Existing referral | References `referrals.referral_id` |
| `previous_status` | `VARCHAR(40)` | NULL | Referral status value | Null only for the first status event |
| `new_status` | `VARCHAR(40)` | NN | Referral status value | Must follow an allowed transition or create a documented exception |
| `status_changed_at` | `DATETIME` | NN | UTC timestamp | Cannot precede referral receipt except migration exceptions |
| `changed_by_user_id` | `VARCHAR(10)` | FK, NULL | Existing user | Null only when `change_source` is an automated source |
| `change_source` | `VARCHAR(30)` | NN | `User`, `Interface`, `Automation`, `Migration`, `Correction` | Identifies action source |
| `change_reason` | `VARCHAR(255)` | NULL | Synthetic text | Required for overrides, corrections, and selected terminal transitions |
| `override_flag` | `BOOLEAN` | NN | `0`, `1` | Defaults to `0`; `1` requires reason and authorized user |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |

# 11. `outreach_attempts`

**Grain:** One row per communication attempt.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `outreach_attempt_id` | `VARCHAR(12)` | PK, NN | `OUT` + six digits | Outreach-event identifier |
| `referral_id` | `VARCHAR(12)` | FK, NN | Existing referral | References `referrals.referral_id` |
| `performed_by_user_id` | `VARCHAR(10)` | FK, NN | Existing user | User recording or performing the attempt |
| `attempt_at` | `DATETIME` | NN | UTC timestamp | Cannot precede referral receipt without a migration exception |
| `communication_channel` | `VARCHAR(20)` | NN | `Phone`, `Voicemail`, `SMS`, `Patient Portal`, `Email`, `Fax`, `Other` | Attempt method |
| `contacted_party` | `VARCHAR(30)` | NN | `Patient`, `Caregiver`, `Specialist Office`, `Referring Office`, `Payer`, `Other` | Intended or reached party |
| `outreach_outcome` | `VARCHAR(30)` | NN | See outreach outcome list | Structured result |
| `next_action_at` | `DATETIME` | NULL | UTC timestamp | Required when active follow-up is expected |
| `outreach_note` | `VARCHAR(500)` | NULL | Synthetic text | Optional operational note; no real PHI |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |

### Outreach outcome values

- `Reached`
- `No Answer`
- `Voicemail Left`
- `Invalid Contact`
- `Callback Requested`
- `Declined`
- `Already Scheduled`
- `Support Needed`
- `Other`

# 12. `appointments`

**Grain:** One row per scheduled appointment instance, including historical reschedules.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `appointment_id` | `VARCHAR(12)` | PK, NN | `APT` + six digits | Appointment identifier |
| `referral_id` | `VARCHAR(12)` | FK, NN | Existing referral | References `referrals.referral_id` |
| `practitioner_id` | `VARCHAR(12)` | FK, NULL | Existing practitioner | Specialist when known |
| `organization_id` | `VARCHAR(10)` | FK, NULL | Existing organization | Appointment organization |
| `location_id` | `VARCHAR(10)` | FK, NULL | Existing location | Appointment location |
| `scheduled_at` | `DATETIME` | NN | UTC timestamp | Time scheduling was recorded |
| `appointment_start_at` | `DATETIME` | NN | UTC timestamp | Planned appointment start; cannot precede referral receipt without exception |
| `appointment_status` | `VARCHAR(20)` | NN | `Scheduled`, `Completed`, `Cancelled`, `No-show`, `Rescheduled`, `Unknown` | Current outcome of this appointment instance |
| `outcome_recorded_at` | `DATETIME` | NULL | UTC timestamp | Required for completed, cancelled, no-show, or rescheduled outcomes |
| `scheduling_source` | `VARCHAR(30)` | NN | `NorthStar Staff`, `Specialist Office`, `Patient`, `Interface`, `Other` | Party or mechanism recording scheduling |
| `telehealth_flag` | `BOOLEAN` | NN | `0`, `1` | Indicates virtual appointment |
| `outcome_reason` | `VARCHAR(100)` | NULL | Approved synthetic reason | Used for cancellation, no-show, and selected exceptions |
| `superseded_by_appointment_id` | `VARCHAR(12)` | FK, NULL | Existing later appointment | Self-references `appointments.appointment_id`; required when rescheduled |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 13. `consult_reports`

**Grain:** One row per consultation-report metadata record.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `consult_report_id` | `VARCHAR(12)` | PK, NN | `RPT` + six digits | Internal report identifier |
| `external_document_id` | `VARCHAR(40)` | UQ, NULL | Synthetic external identifier | Source document traceability |
| `referral_id` | `VARCHAR(12)` | FK, NULL | Existing referral | Null only while report remains unmatched |
| `appointment_id` | `VARCHAR(12)` | FK, NULL | Existing appointment | Completed appointment associated with the report |
| `author_practitioner_id` | `VARCHAR(12)` | FK, NULL | Existing practitioner | Report author when known |
| `source_organization_id` | `VARCHAR(10)` | FK, NULL | Existing organization | Sending organization |
| `reviewed_by_practitioner_id` | `VARCHAR(12)` | FK, NULL | Existing practitioner | Referring or covering clinician who reviewed the report |
| `report_source` | `VARCHAR(30)` | NN | `FHIR`, `EHR Exchange`, `Portal`, `Fax`, `Mail`, `Manual Upload`, `Other` | Inbound channel |
| `report_date` | `DATE` | NULL | Valid date | Date shown on the report |
| `received_at` | `DATETIME` | NN | UTC timestamp | Inbound receipt timestamp |
| `match_method` | `VARCHAR(30)` | NN | `Automatic`, `Manual`, `Unmatched` | How report-to-referral linkage was established |
| `match_status` | `VARCHAR(20)` | NN | `Matched`, `Ambiguous`, `Unmatched` | Ambiguous and unmatched values require human review |
| `routed_at` | `DATETIME` | NULL | UTC timestamp | Time report was routed to clinician |
| `reviewed_at` | `DATETIME` | NULL | UTC timestamp | Cannot precede `routed_at`; required for completed closure |
| `report_status` | `VARCHAR(20)` | NN | `Received`, `Routed`, `Reviewed`, `Rejected`, `Duplicate` | Current report-processing state |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 14. `referral_validation_issues`

**Grain:** One row per detected intake, migration, interface, or data-quality issue.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `validation_issue_id` | `VARCHAR(12)` | PK, NN | `VAL` + six digits | Issue identifier |
| `referral_id` | `VARCHAR(12)` | FK, NULL | Existing referral | May be null for a rejected source record not yet assigned a referral ID |
| `source_record_id` | `VARCHAR(40)` | NULL | Synthetic source identifier | Traceability for rejected or unmatched source records |
| `issue_source` | `VARCHAR(30)` | NN | `Intake`, `Migration`, `Interface`, `Data Quality`, `Workflow` | Origin of issue |
| `rule_code` | `VARCHAR(30)` | NN | Controlled validation-rule code | Stable identifier for reproducible checks |
| `field_name` | `VARCHAR(64)` | NULL | Database or source field name | Field associated with issue when applicable |
| `severity` | `VARCHAR(20)` | NN | `Warning`, `Blocking`, `Critical` | Controls routing and remediation priority |
| `issue_description` | `VARCHAR(500)` | NN | Synthetic description | Human-readable problem statement |
| `detected_at` | `DATETIME` | NN | UTC timestamp | Detection timestamp |
| `resolution_status` | `VARCHAR(25)` | NN | `Open`, `In Progress`, `Resolved`, `Accepted Exception` | Current remediation state |
| `resolved_by_user_id` | `VARCHAR(10)` | FK, NULL | Existing user | Required when resolved or accepted |
| `resolved_at` | `DATETIME` | NULL | UTC timestamp | Required when resolved or accepted; cannot precede detection |
| `resolution_note` | `VARCHAR(500)` | NULL | Synthetic text | Required for accepted exceptions and selected resolutions |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |
| `updated_at` | `DATETIME` | NN | UTC timestamp | Must be greater than or equal to `created_at` |

# 15. `referral_assignments`

**Grain:** One row per referral assignment period.

| Column | MySQL type | Null/key | Allowed values or format | Definition and validation |
|---|---|---|---|---|
| `assignment_id` | `VARCHAR(12)` | PK, NN | `ASN` + six digits | Assignment-event identifier |
| `referral_id` | `VARCHAR(12)` | FK, NN | Existing referral | References `referrals.referral_id` |
| `assigned_user_id` | `VARCHAR(10)` | FK, NULL | Existing active user | May be null only when an accountable queue is populated |
| `queue_name` | `VARCHAR(40)` | NULL | Approved queue value | Required when no user is assigned |
| `assigned_by_user_id` | `VARCHAR(10)` | FK, NULL | Existing user | Null when assigned automatically or during migration |
| `assignment_source` | `VARCHAR(30)` | NN | `User`, `Automation`, `Migration`, `Interface` | Assignment origin |
| `assignment_start_at` | `DATETIME` | NN | UTC timestamp | Assignment start |
| `assignment_end_at` | `DATETIME` | NULL | UTC timestamp | Null for active assignment; cannot precede start |
| `assignment_reason` | `VARCHAR(255)` | NULL | Synthetic text | Required for manual reassignment when policy specifies |
| `active_assignment_flag` | `BOOLEAN` | NN | `0`, `1` | Only one row per referral may equal `1` |
| `created_at` | `DATETIME` | NN | UTC timestamp | Record-created timestamp |

# Derived Analytical Fields

The following fields are not authoritative stored columns in the source tables. They will be calculated in SQL views from stored events and milestones.

| Derived field | Definition |
|---|---|
| `referral_age_days` | Calendar days from `referral_received_at` to closure or dataset as-of timestamp |
| `current_stage_age_hours` | Hours from `current_stage_started_at` to closure or as-of timestamp |
| `overdue_flag` | `1` when an active referral's `service_level_due_at` is earlier than the as-of timestamp |
| `days_to_validation` | Days from referral receipt to initial validation completion |
| `days_to_first_outreach` | Days from referral receipt to first outreach attempt |
| `days_to_schedule` | Days from referral receipt to first scheduled appointment |
| `days_to_completion` | Days from referral receipt to first completed specialist appointment |
| `report_turnaround_days` | Days from completed appointment to first qualifying report receipt |
| `outreach_attempt_count` | Count of outreach attempts for the referral |
| `closed_loop_flag` | `1` when completed visit, report receipt, routing, review, and completed closure criteria are satisfied |
| `referral_leakage_flag` | `1` when a referral reaching outreach closes without verified specialty completion, subject to final exclusions |

# Cross-Table Validation Rules

These rules require validation queries, triggers, procedures, or application logic because they cannot all be enforced through single-table `CHECK` constraints.

| Rule ID | Rule |
|---|---|
| `DQ-001` | Referral coverage must belong to the same patient as the referral |
| `DQ-002` | Referring location must belong to the referring organization |
| `DQ-003` | Destination practitioner should align with destination organization when both are populated |
| `DQ-004` | Status-history events must follow the approved transition map |
| `DQ-005` | Referral current status should equal the latest valid status-history value |
| `DQ-006` | Referral milestone timestamps must reconcile with underlying lifecycle-event records |
| `DQ-007` | Only one referral assignment may be active at a time |
| `DQ-008` | Active referrals must have an active user assignment or accountable queue, except documented issues |
| `DQ-009` | Terminal referrals must not retain an active assignment |
| `DQ-010` | `Closed—Completed` requires a completed appointment and qualifying report workflow |
| `DQ-011` | `Closed—Not Completed` requires an approved closure reason |
| `DQ-012` | Completed, cancelled, no-show, and rescheduled appointments require an outcome timestamp |
| `DQ-013` | Rescheduled appointments require a valid successor appointment |
| `DQ-014` | Matched reports require a referral identifier |
| `DQ-015` | Reviewed reports require routed and reviewed timestamps in logical order |
| `DQ-016` | Resolved or accepted validation issues require resolver and resolution timestamp |
| `DQ-017` | Outreach events cannot precede referral receipt without a documented migration exception |
| `DQ-018` | Closed timestamp cannot precede referral receipt |
| `DQ-019` | Coverage termination cannot precede effective date |
| `DQ-020` | All synthetic identifiers must be unique in their applicable entity |

# Source-to-FHIR Mapping Summary

| Relational field or entity | FHIR R4 location |
|---|---|
| `patients.patient_id` | `Patient.id` |
| Patient source identifier | `Patient.identifier` |
| `practitioners.practitioner_id` | `Practitioner.id` |
| Practitioner synthetic NPI | `Practitioner.identifier` |
| `organizations.organization_id` | `Organization.id` |
| `locations.location_id` | `Location.id` |
| `coverages.coverage_id` | `Coverage.id` |
| `referrals.referral_id` | `ServiceRequest.id` |
| Referral priority | `ServiceRequest.priority` with documented value mapping |
| Referral clinical reason | `ServiceRequest.reasonCode` or supporting text, depending on test design |
| Referral subject | `ServiceRequest.subject` referencing `Patient` |
| Referring clinician | `ServiceRequest.requester` referencing `Practitioner` |
| Referral specialty/service | `ServiceRequest.code` |
| Operational referral workflow | `Task` referencing `ServiceRequest` |
| Appointment | `Appointment` |
| Completed specialist visit | `Encounter` |
| Consultation report metadata | `DiagnosticReport` or `DocumentReference` |

# Data Quality Expectations

The processed target dataset should meet the following expectations after documented exception handling:

- 100% uniqueness for primary keys
- 100% valid foreign-key references
- 100% conformance for required controlled values
- 100% completion of non-nullable target fields for accepted records
- Reconciled source, accepted, rejected, and exception counts
- No unexplained impossible date sequences
- No real patient data, credentials, or clinical documents

The raw synthetic source files will intentionally contain controlled defects so the migration and validation process demonstrates realistic issue detection and remediation.

# Portfolio Transparency Note

NorthStar Medical Group, all identifiers, patient attributes, organizations, clinicians, payers, workflows, and clinical scenarios are fictional. The data dictionary demonstrates healthcare data modeling and implementation methods and is not a production clinical specification.
