-- ============================================================================
-- Project 4: Closed-Loop Specialty Referral Management
-- File: load_data.sql
-- Purpose: Load the 15 validated processed CSV files into MySQL.
-- Platform: MySQL 8.0+ / MySQL Workbench
-- ============================================================================

USE healthcare_referral_management;

-- IMPORTANT
-- Replace every occurrence of the placeholder below with the absolute path to
-- your Project 4 data/processed folder. Keep the filename at the end.
--
-- Placeholder:
-- /Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/
--
-- On macOS, run `pwd` in the Project 4 VS Code terminal to obtain the project
-- folder path. Do not use ~ inside LOAD DATA LOCAL INFILE.

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

-- 1. PATIENTS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/patients.csv'
INTO TABLE patients
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@patient_id, @source_patient_id, @first_name, @last_name, @date_of_birth,
 @administrative_sex, @phone_number, @email_address,
 @preferred_contact_channel, @preferred_language, @active_flag,
 @created_at, @updated_at)
SET patient_id = @patient_id,
    source_patient_id = @source_patient_id,
    first_name = @first_name,
    last_name = @last_name,
    date_of_birth = @date_of_birth,
    administrative_sex = @administrative_sex,
    phone_number = NULLIF(@phone_number, ''),
    email_address = NULLIF(@email_address, ''),
    preferred_contact_channel = NULLIF(@preferred_contact_channel, ''),
    preferred_language = @preferred_language,
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 2. ORGANIZATIONS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/organizations.csv'
INTO TABLE organizations
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@organization_id, @source_organization_id, @organization_name,
 @organization_type, @internal_flag, @synthetic_npi, @phone_number,
 @fax_number, @active_flag, @created_at, @updated_at)
SET organization_id = @organization_id,
    source_organization_id = NULLIF(@source_organization_id, ''),
    organization_name = @organization_name,
    organization_type = @organization_type,
    internal_flag = @internal_flag,
    synthetic_npi = NULLIF(@synthetic_npi, ''),
    phone_number = NULLIF(@phone_number, ''),
    fax_number = NULLIF(@fax_number, ''),
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 3. LOCATIONS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/locations.csv'
INTO TABLE locations
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@location_id, @organization_id, @location_name, @address_line_1, @city,
 @state_code, @postal_code, @phone_number, @telehealth_flag, @active_flag,
 @created_at, @updated_at)
SET location_id = @location_id,
    organization_id = @organization_id,
    location_name = @location_name,
    address_line_1 = NULLIF(@address_line_1, ''),
    city = NULLIF(@city, ''),
    state_code = NULLIF(@state_code, ''),
    postal_code = NULLIF(@postal_code, ''),
    phone_number = NULLIF(@phone_number, ''),
    telehealth_flag = @telehealth_flag,
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 4. SPECIALTIES
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/specialties.csv'
INTO TABLE specialties
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@specialty_id, @specialty_code, @specialty_name,
 @routine_intake_sla_hours, @urgent_intake_sla_hours,
 @routine_outreach_sla_hours, @urgent_outreach_sla_hours,
 @active_flag, @created_at, @updated_at)
SET specialty_id = @specialty_id,
    specialty_code = @specialty_code,
    specialty_name = @specialty_name,
    routine_intake_sla_hours = @routine_intake_sla_hours,
    urgent_intake_sla_hours = @urgent_intake_sla_hours,
    routine_outreach_sla_hours = @routine_outreach_sla_hours,
    urgent_outreach_sla_hours = @urgent_outreach_sla_hours,
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 5. PRACTITIONERS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/practitioners.csv'
INTO TABLE practitioners
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@practitioner_id, @source_practitioner_id, @organization_id, @specialty_id,
 @first_name, @last_name, @practitioner_role, @synthetic_npi,
 @internal_flag, @active_flag, @created_at, @updated_at)
SET practitioner_id = @practitioner_id,
    source_practitioner_id = NULLIF(@source_practitioner_id, ''),
    organization_id = @organization_id,
    specialty_id = NULLIF(@specialty_id, ''),
    first_name = @first_name,
    last_name = @last_name,
    practitioner_role = @practitioner_role,
    synthetic_npi = @synthetic_npi,
    internal_flag = @internal_flag,
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 6. PAYERS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/payers.csv'
INTO TABLE payers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@payer_id, @payer_name, @payer_category, @electronic_payer_id,
 @active_flag, @created_at, @updated_at)
SET payer_id = @payer_id,
    payer_name = @payer_name,
    payer_category = @payer_category,
    electronic_payer_id = NULLIF(@electronic_payer_id, ''),
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 7. COVERAGES
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/coverages.csv'
INTO TABLE coverages
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@coverage_id, @source_coverage_id, @patient_id, @payer_id, @member_id,
 @plan_name, @coverage_type, @coverage_status, @effective_date,
 @termination_date, @primary_coverage_flag, @created_at, @updated_at)
SET coverage_id = @coverage_id,
    source_coverage_id = NULLIF(@source_coverage_id, ''),
    patient_id = @patient_id,
    payer_id = @payer_id,
    member_id = @member_id,
    plan_name = NULLIF(@plan_name, ''),
    coverage_type = @coverage_type,
    coverage_status = @coverage_status,
    effective_date = @effective_date,
    termination_date = NULLIF(@termination_date, ''),
    primary_coverage_flag = @primary_coverage_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 8. USERS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/users.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@user_id, @organization_id, @location_id, @display_name, @user_role,
 @active_flag, @created_at, @updated_at)
SET user_id = @user_id,
    organization_id = NULLIF(@organization_id, ''),
    location_id = NULLIF(@location_id, ''),
    display_name = @display_name,
    user_role = @user_role,
    active_flag = @active_flag,
    created_at = @created_at,
    updated_at = @updated_at;

-- 9. REFERRALS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/referrals.csv'
INTO TABLE referrals
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@referral_id, @source_referral_id, @source_system, @patient_id, @coverage_id,
 @referring_practitioner_id, @referring_organization_id,
 @referring_location_id, @specialty_id, @destination_practitioner_id,
 @destination_organization_id, @current_owner_user_id, @source_ordered_at,
 @referral_received_at, @clinical_reason, @diagnosis_code, @priority,
 @current_status, @current_queue, @current_stage_started_at,
 @service_level_due_at, @initial_validation_completed_at, @first_outreach_at,
 @first_scheduled_at, @first_completed_appointment_at,
 @first_report_received_at, @closed_at, @closure_category, @closure_reason,
 @created_at, @updated_at)
SET referral_id = @referral_id,
    source_referral_id = @source_referral_id,
    source_system = @source_system,
    patient_id = @patient_id,
    coverage_id = NULLIF(@coverage_id, ''),
    referring_practitioner_id = @referring_practitioner_id,
    referring_organization_id = @referring_organization_id,
    referring_location_id = @referring_location_id,
    specialty_id = @specialty_id,
    destination_practitioner_id = NULLIF(@destination_practitioner_id, ''),
    destination_organization_id = NULLIF(@destination_organization_id, ''),
    current_owner_user_id = NULLIF(@current_owner_user_id, ''),
    source_ordered_at = @source_ordered_at,
    referral_received_at = @referral_received_at,
    clinical_reason = @clinical_reason,
    diagnosis_code = NULLIF(@diagnosis_code, ''),
    priority = @priority,
    current_status = @current_status,
    current_queue = NULLIF(@current_queue, ''),
    current_stage_started_at = @current_stage_started_at,
    service_level_due_at = NULLIF(@service_level_due_at, ''),
    initial_validation_completed_at = NULLIF(@initial_validation_completed_at, ''),
    first_outreach_at = NULLIF(@first_outreach_at, ''),
    first_scheduled_at = NULLIF(@first_scheduled_at, ''),
    first_completed_appointment_at = NULLIF(@first_completed_appointment_at, ''),
    first_report_received_at = NULLIF(@first_report_received_at, ''),
    closed_at = NULLIF(@closed_at, ''),
    closure_category = NULLIF(@closure_category, ''),
    closure_reason = NULLIF(@closure_reason, ''),
    created_at = @created_at,
    updated_at = @updated_at;

-- 10. REFERRAL STATUS HISTORY
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/referral_status_history.csv'
INTO TABLE referral_status_history
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@status_history_id, @referral_id, @previous_status, @new_status,
 @status_changed_at, @changed_by_user_id, @change_source, @change_reason,
 @override_flag, @created_at)
SET status_history_id = @status_history_id,
    referral_id = @referral_id,
    previous_status = NULLIF(@previous_status, ''),
    new_status = @new_status,
    status_changed_at = @status_changed_at,
    changed_by_user_id = NULLIF(@changed_by_user_id, ''),
    change_source = @change_source,
    change_reason = NULLIF(@change_reason, ''),
    override_flag = @override_flag,
    created_at = @created_at;

-- 11. OUTREACH ATTEMPTS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/outreach_attempts.csv'
INTO TABLE outreach_attempts
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@outreach_attempt_id, @referral_id, @performed_by_user_id, @attempt_at,
 @communication_channel, @contacted_party, @outreach_outcome,
 @next_action_at, @outreach_note, @created_at)
SET outreach_attempt_id = @outreach_attempt_id,
    referral_id = @referral_id,
    performed_by_user_id = @performed_by_user_id,
    attempt_at = @attempt_at,
    communication_channel = @communication_channel,
    contacted_party = @contacted_party,
    outreach_outcome = @outreach_outcome,
    next_action_at = NULLIF(@next_action_at, ''),
    outreach_note = NULLIF(@outreach_note, ''),
    created_at = @created_at;

-- 12. APPOINTMENTS
-- The processed CSV orders successor appointment rows before the historical
-- Rescheduled rows that reference them, allowing the self-referencing FK to pass.
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/appointments.csv'
INTO TABLE appointments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@appointment_id, @referral_id, @practitioner_id, @organization_id,
 @location_id, @scheduled_at, @appointment_start_at, @appointment_status,
 @outcome_recorded_at, @scheduling_source, @telehealth_flag, @outcome_reason,
 @superseded_by_appointment_id, @created_at, @updated_at)
SET appointment_id = @appointment_id,
    referral_id = @referral_id,
    practitioner_id = NULLIF(@practitioner_id, ''),
    organization_id = NULLIF(@organization_id, ''),
    location_id = NULLIF(@location_id, ''),
    scheduled_at = @scheduled_at,
    appointment_start_at = @appointment_start_at,
    appointment_status = @appointment_status,
    outcome_recorded_at = NULLIF(@outcome_recorded_at, ''),
    scheduling_source = @scheduling_source,
    telehealth_flag = @telehealth_flag,
    outcome_reason = NULLIF(@outcome_reason, ''),
    superseded_by_appointment_id = NULLIF(@superseded_by_appointment_id, ''),
    created_at = @created_at,
    updated_at = @updated_at;

-- 13. CONSULT REPORTS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/consult_reports.csv'
INTO TABLE consult_reports
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@consult_report_id, @external_document_id, @referral_id, @appointment_id,
 @author_practitioner_id, @source_organization_id,
 @reviewed_by_practitioner_id, @report_source, @report_date, @received_at,
 @match_method, @match_status, @routed_at, @reviewed_at, @report_status,
 @created_at, @updated_at)
SET consult_report_id = @consult_report_id,
    external_document_id = NULLIF(@external_document_id, ''),
    referral_id = NULLIF(@referral_id, ''),
    appointment_id = NULLIF(@appointment_id, ''),
    author_practitioner_id = NULLIF(@author_practitioner_id, ''),
    source_organization_id = NULLIF(@source_organization_id, ''),
    reviewed_by_practitioner_id = NULLIF(@reviewed_by_practitioner_id, ''),
    report_source = @report_source,
    report_date = NULLIF(@report_date, ''),
    received_at = @received_at,
    match_method = @match_method,
    match_status = @match_status,
    routed_at = NULLIF(@routed_at, ''),
    reviewed_at = NULLIF(@reviewed_at, ''),
    report_status = @report_status,
    created_at = @created_at,
    updated_at = @updated_at;

-- 14. REFERRAL VALIDATION ISSUES
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/referral_validation_issues.csv'
INTO TABLE referral_validation_issues
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@validation_issue_id, @referral_id, @source_record_id, @issue_source,
 @rule_code, @field_name, @severity, @issue_description, @detected_at,
 @resolution_status, @resolved_by_user_id, @resolved_at, @resolution_note,
 @created_at, @updated_at)
SET validation_issue_id = @validation_issue_id,
    referral_id = NULLIF(@referral_id, ''),
    source_record_id = NULLIF(@source_record_id, ''),
    issue_source = @issue_source,
    rule_code = @rule_code,
    field_name = NULLIF(@field_name, ''),
    severity = @severity,
    issue_description = @issue_description,
    detected_at = @detected_at,
    resolution_status = @resolution_status,
    resolved_by_user_id = NULLIF(@resolved_by_user_id, ''),
    resolved_at = NULLIF(@resolved_at, ''),
    resolution_note = NULLIF(@resolution_note, ''),
    created_at = @created_at,
    updated_at = @updated_at;

-- 15. REFERRAL ASSIGNMENTS
LOAD DATA LOCAL INFILE '/Users/brandon_mcdermott/Documents/Healthcare_Portfolio/Project_4_Closed_Loop_Referral_Implementation/data/processed/referral_assignments.csv'
INTO TABLE referral_assignments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@assignment_id, @referral_id, @assigned_user_id, @queue_name,
 @assigned_by_user_id, @assignment_source, @assignment_start_at,
 @assignment_end_at, @assignment_reason, @active_assignment_flag, @created_at)
SET assignment_id = @assignment_id,
    referral_id = @referral_id,
    assigned_user_id = NULLIF(@assigned_user_id, ''),
    queue_name = NULLIF(@queue_name, ''),
    assigned_by_user_id = NULLIF(@assigned_by_user_id, ''),
    assignment_source = @assignment_source,
    assignment_start_at = @assignment_start_at,
    assignment_end_at = NULLIF(@assignment_end_at, ''),
    assignment_reason = NULLIF(@assignment_reason, ''),
    active_assignment_flag = @active_assignment_flag,
    created_at = @created_at;

COMMIT;

-- ============================================================================
-- ROW-COUNT RECONCILIATION
-- Expected counts from the deterministic generator are listed for comparison.
-- ============================================================================

SELECT 'patients' AS table_name, COUNT(*) AS actual_rows, 2000 AS expected_rows FROM patients
UNION ALL SELECT 'organizations', COUNT(*), 31 FROM organizations
UNION ALL SELECT 'locations', COUNT(*), 31 FROM locations
UNION ALL SELECT 'specialties', COUNT(*), 10 FROM specialties
UNION ALL SELECT 'practitioners', COUNT(*), 110 FROM practitioners
UNION ALL SELECT 'payers', COUNT(*), 8 FROM payers
UNION ALL SELECT 'coverages', COUNT(*), 2200 FROM coverages
UNION ALL SELECT 'users', COUNT(*), 30 FROM users
UNION ALL SELECT 'referrals', COUNT(*), 2500 FROM referrals
UNION ALL SELECT 'referral_status_history', COUNT(*), 11636 FROM referral_status_history
UNION ALL SELECT 'outreach_attempts', COUNT(*), 4294 FROM outreach_attempts
UNION ALL SELECT 'appointments', COUNT(*), 1783 FROM appointments
UNION ALL SELECT 'consult_reports', COUNT(*), 1148 FROM consult_reports
UNION ALL SELECT 'referral_validation_issues', COUNT(*), 262 FROM referral_validation_issues
UNION ALL SELECT 'referral_assignments', COUNT(*), 2500 FROM referral_assignments;

-- Overall reconciliation: expected processed total = 28,543 rows.
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
    AS total_loaded_rows,
    28543 AS expected_total_rows;

-- End of load_data.sql
