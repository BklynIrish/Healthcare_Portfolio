-- ============================================================================
-- Project 4: Closed-Loop Specialty Referral Management
-- File: create_referral_database_v2.sql
-- Purpose: Create the portfolio database, 15 relational tables, constraints,
--          and operational indexes.
-- Platform: MySQL 8.0+
-- Data: Fully synthetic; no PHI or live credentials
-- ============================================================================

DROP DATABASE IF EXISTS healthcare_referral_management;
CREATE DATABASE healthcare_referral_management
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE healthcare_referral_management;

-- ============================================================================
-- 1. PATIENTS
-- ============================================================================

CREATE TABLE patients (
    patient_id                 VARCHAR(12)  NOT NULL,
    source_patient_id          VARCHAR(30)  NOT NULL,
    first_name                 VARCHAR(50)  NOT NULL,
    last_name                  VARCHAR(50)  NOT NULL,
    date_of_birth              DATE         NOT NULL,
    administrative_sex        VARCHAR(20)  NOT NULL,
    phone_number               VARCHAR(20)  NULL,
    email_address              VARCHAR(100) NULL,
    preferred_contact_channel VARCHAR(20)  NULL,
    preferred_language        VARCHAR(40)  NOT NULL DEFAULT 'English',
    active_flag                BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at                 DATETIME     NOT NULL,
    updated_at                 DATETIME     NOT NULL,

    CONSTRAINT pk_patients PRIMARY KEY (patient_id),
    CONSTRAINT uq_patients_source_patient_id UNIQUE (source_patient_id),
    CONSTRAINT chk_patients_id_format
        CHECK (patient_id REGEXP '^PAT[0-9]{6}$'),
    CONSTRAINT chk_patients_administrative_sex
        CHECK (administrative_sex IN ('Female', 'Male', 'Unknown', 'Other')),
    CONSTRAINT chk_patients_contact_channel
        CHECK (
            preferred_contact_channel IS NULL
            OR preferred_contact_channel IN
                ('Phone', 'SMS', 'Patient Portal', 'Email', 'Mail')
        ),
    CONSTRAINT chk_patients_active_flag
        CHECK (active_flag IN (0, 1)),
    CONSTRAINT chk_patients_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 2. ORGANIZATIONS
-- ============================================================================

CREATE TABLE organizations (
    organization_id        VARCHAR(10)  NOT NULL,
    source_organization_id VARCHAR(30)  NULL,
    organization_name      VARCHAR(120) NOT NULL,
    organization_type      VARCHAR(30)  NOT NULL,
    internal_flag          BOOLEAN      NOT NULL DEFAULT FALSE,
    synthetic_npi          CHAR(10)     NULL,
    phone_number           VARCHAR(20)  NULL,
    fax_number             VARCHAR(20)  NULL,
    active_flag            BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at             DATETIME     NOT NULL,
    updated_at             DATETIME     NOT NULL,

    CONSTRAINT pk_organizations PRIMARY KEY (organization_id),
    CONSTRAINT uq_organizations_source_id UNIQUE (source_organization_id),
    CONSTRAINT uq_organizations_synthetic_npi UNIQUE (synthetic_npi),
    CONSTRAINT chk_organizations_id_format
        CHECK (organization_id REGEXP '^ORG[0-9]{3}$'),
    CONSTRAINT chk_organizations_type
        CHECK (
            organization_type IN
                ('Primary Care Practice', 'Specialist Practice', 'Hospital',
                 'Imaging Center', 'Other')
        ),
    CONSTRAINT chk_organizations_synthetic_npi
        CHECK (synthetic_npi IS NULL OR synthetic_npi REGEXP '^[0-9]{10}$'),
    CONSTRAINT chk_organizations_flags
        CHECK (internal_flag IN (0, 1) AND active_flag IN (0, 1)),
    CONSTRAINT chk_organizations_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 3. LOCATIONS
-- ============================================================================

CREATE TABLE locations (
    location_id    VARCHAR(10)  NOT NULL,
    organization_id VARCHAR(10) NOT NULL,
    location_name  VARCHAR(120) NOT NULL,
    address_line_1 VARCHAR(120) NULL,
    city           VARCHAR(60)  NULL,
    state_code     CHAR(2)      NULL,
    postal_code    VARCHAR(10)  NULL,
    phone_number   VARCHAR(20)  NULL,
    telehealth_flag BOOLEAN     NOT NULL DEFAULT FALSE,
    active_flag    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     DATETIME     NOT NULL,
    updated_at     DATETIME     NOT NULL,

    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT fk_locations_organizations
        FOREIGN KEY (organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_locations_id_format
        CHECK (location_id REGEXP '^LOC[0-9]{3}$'),
    CONSTRAINT chk_locations_state_code
        CHECK (state_code IS NULL OR state_code REGEXP '^[A-Z]{2}$'),
    CONSTRAINT chk_locations_flags
        CHECK (telehealth_flag IN (0, 1) AND active_flag IN (0, 1)),
    CONSTRAINT chk_locations_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 4. SPECIALTIES
-- ============================================================================

CREATE TABLE specialties (
    specialty_id               VARCHAR(10) NOT NULL,
    specialty_code             VARCHAR(20) NOT NULL,
    specialty_name             VARCHAR(80) NOT NULL,
    routine_intake_sla_hours   INT         NOT NULL,
    urgent_intake_sla_hours    INT         NOT NULL,
    routine_outreach_sla_hours INT         NOT NULL,
    urgent_outreach_sla_hours  INT         NOT NULL,
    active_flag                BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at                 DATETIME    NOT NULL,
    updated_at                 DATETIME    NOT NULL,

    CONSTRAINT pk_specialties PRIMARY KEY (specialty_id),
    CONSTRAINT uq_specialties_code UNIQUE (specialty_code),
    CONSTRAINT uq_specialties_name UNIQUE (specialty_name),
    CONSTRAINT chk_specialties_id_format
        CHECK (specialty_id REGEXP '^SPC[0-9]{3}$'),
    CONSTRAINT chk_specialties_sla_positive
        CHECK (
            routine_intake_sla_hours > 0
            AND urgent_intake_sla_hours > 0
            AND routine_outreach_sla_hours > 0
            AND urgent_outreach_sla_hours > 0
        ),
    CONSTRAINT chk_specialties_sla_order
        CHECK (
            urgent_intake_sla_hours <= routine_intake_sla_hours
            AND urgent_outreach_sla_hours <= routine_outreach_sla_hours
        ),
    CONSTRAINT chk_specialties_active_flag
        CHECK (active_flag IN (0, 1)),
    CONSTRAINT chk_specialties_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 5. PRACTITIONERS
-- ============================================================================

CREATE TABLE practitioners (
    practitioner_id        VARCHAR(12) NOT NULL,
    source_practitioner_id VARCHAR(30) NULL,
    organization_id        VARCHAR(10) NOT NULL,
    specialty_id           VARCHAR(10) NULL,
    first_name             VARCHAR(50) NOT NULL,
    last_name              VARCHAR(50) NOT NULL,
    practitioner_role      VARCHAR(30) NOT NULL,
    synthetic_npi          CHAR(10)    NOT NULL,
    internal_flag          BOOLEAN     NOT NULL DEFAULT FALSE,
    active_flag            BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at             DATETIME    NOT NULL,
    updated_at             DATETIME    NOT NULL,

    CONSTRAINT pk_practitioners PRIMARY KEY (practitioner_id),
    CONSTRAINT uq_practitioners_source_id UNIQUE (source_practitioner_id),
    CONSTRAINT uq_practitioners_synthetic_npi UNIQUE (synthetic_npi),
    CONSTRAINT fk_practitioners_organizations
        FOREIGN KEY (organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_practitioners_specialties
        FOREIGN KEY (specialty_id)
        REFERENCES specialties (specialty_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_practitioners_id_format
        CHECK (practitioner_id REGEXP '^PRC[0-9]{4}$'),
    CONSTRAINT chk_practitioners_role
        CHECK (
            practitioner_role IN
                ('Referring Clinician', 'Specialist', 'Medical Director', 'Other')
        ),
    CONSTRAINT chk_practitioners_synthetic_npi
        CHECK (synthetic_npi REGEXP '^[0-9]{10}$'),
    CONSTRAINT chk_practitioners_flags
        CHECK (internal_flag IN (0, 1) AND active_flag IN (0, 1)),
    CONSTRAINT chk_practitioners_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 6. PAYERS
-- ============================================================================

CREATE TABLE payers (
    payer_id            VARCHAR(10)  NOT NULL,
    payer_name          VARCHAR(100) NOT NULL,
    payer_category      VARCHAR(30)  NOT NULL,
    electronic_payer_id VARCHAR(20)  NULL,
    active_flag         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          DATETIME     NOT NULL,
    updated_at          DATETIME     NOT NULL,

    CONSTRAINT pk_payers PRIMARY KEY (payer_id),
    CONSTRAINT uq_payers_name UNIQUE (payer_name),
    CONSTRAINT uq_payers_electronic_id UNIQUE (electronic_payer_id),
    CONSTRAINT chk_payers_id_format
        CHECK (payer_id REGEXP '^PAY[0-9]{3}$'),
    CONSTRAINT chk_payers_category
        CHECK (
            payer_category IN
                ('Commercial', 'Medicare', 'Medicaid', 'Self-Pay', 'Other')
        ),
    CONSTRAINT chk_payers_active_flag
        CHECK (active_flag IN (0, 1)),
    CONSTRAINT chk_payers_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 7. COVERAGES
-- ============================================================================

CREATE TABLE coverages (
    coverage_id          VARCHAR(12)  NOT NULL,
    source_coverage_id   VARCHAR(30)  NULL,
    patient_id           VARCHAR(12)  NOT NULL,
    payer_id             VARCHAR(10)  NOT NULL,
    member_id            VARCHAR(30)  NOT NULL,
    plan_name            VARCHAR(100) NULL,
    coverage_type        VARCHAR(30)  NOT NULL,
    coverage_status      VARCHAR(20)  NOT NULL,
    effective_date       DATE         NOT NULL,
    termination_date     DATE         NULL,
    primary_coverage_flag BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at           DATETIME     NOT NULL,
    updated_at           DATETIME     NOT NULL,

    CONSTRAINT pk_coverages PRIMARY KEY (coverage_id),
    CONSTRAINT uq_coverages_source_id UNIQUE (source_coverage_id),
    CONSTRAINT fk_coverages_patients
        FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_coverages_payers
        FOREIGN KEY (payer_id)
        REFERENCES payers (payer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_coverages_id_format
        CHECK (coverage_id REGEXP '^COV[0-9]{6}$'),
    CONSTRAINT chk_coverages_type
        CHECK (
            coverage_type IN
                ('Commercial', 'Medicare', 'Medicaid', 'Self-Pay', 'Other')
        ),
    CONSTRAINT chk_coverages_status
        CHECK (coverage_status IN ('Active', 'Inactive', 'Pending', 'Unknown')),
    CONSTRAINT chk_coverages_date_order
        CHECK (termination_date IS NULL OR termination_date >= effective_date),
    CONSTRAINT chk_coverages_primary_flag
        CHECK (primary_coverage_flag IN (0, 1)),
    CONSTRAINT chk_coverages_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 8. USERS
-- ============================================================================

CREATE TABLE users (
    user_id         VARCHAR(10)  NOT NULL,
    organization_id VARCHAR(10)  NULL,
    location_id     VARCHAR(10)  NULL,
    display_name    VARCHAR(100) NOT NULL,
    user_role       VARCHAR(40)  NOT NULL,
    active_flag     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      DATETIME     NOT NULL,
    updated_at      DATETIME     NOT NULL,

    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT fk_users_organizations
        FOREIGN KEY (organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_users_locations
        FOREIGN KEY (location_id)
        REFERENCES locations (location_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_users_id_format
        CHECK (user_id REGEXP '^USR[0-9]{3}$'),
    CONSTRAINT chk_users_role
        CHECK (
            user_role IN
                ('Referral Coordinator', 'Referral Manager', 'Referring Clinician',
                 'Practice Manager', 'Medical Director', 'Health IT Support',
                 'Data Analyst', 'System Administrator', 'Auditor')
        ),
    CONSTRAINT chk_users_active_flag
        CHECK (active_flag IN (0, 1)),
    CONSTRAINT chk_users_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 9. REFERRALS
-- ============================================================================

CREATE TABLE referrals (
    referral_id                    VARCHAR(12)  NOT NULL,
    source_referral_id             VARCHAR(30)  NOT NULL,
    source_system                  VARCHAR(40)  NOT NULL,
    patient_id                     VARCHAR(12)  NOT NULL,
    coverage_id                    VARCHAR(12)  NULL,
    referring_practitioner_id      VARCHAR(12)  NOT NULL,
    referring_organization_id      VARCHAR(10)  NOT NULL,
    referring_location_id          VARCHAR(10)  NOT NULL,
    specialty_id                   VARCHAR(10)  NOT NULL,
    destination_practitioner_id    VARCHAR(12)  NULL,
    destination_organization_id    VARCHAR(10)  NULL,
    current_owner_user_id          VARCHAR(10)  NULL,
    source_ordered_at              DATETIME     NOT NULL,
    referral_received_at           DATETIME     NOT NULL,
    clinical_reason                TEXT         NOT NULL,
    diagnosis_code                 VARCHAR(12)  NULL,
    priority                       VARCHAR(10)  NOT NULL,
    current_status                 VARCHAR(40)  NOT NULL,
    current_queue                  VARCHAR(40)  NULL,
    current_stage_started_at       DATETIME     NOT NULL,
    service_level_due_at           DATETIME     NULL,
    initial_validation_completed_at DATETIME    NULL,
    first_outreach_at              DATETIME     NULL,
    first_scheduled_at             DATETIME     NULL,
    first_completed_appointment_at DATETIME     NULL,
    first_report_received_at       DATETIME     NULL,
    closed_at                      DATETIME     NULL,
    closure_category               VARCHAR(20)  NULL,
    closure_reason                 VARCHAR(80)  NULL,
    created_at                     DATETIME     NOT NULL,
    updated_at                     DATETIME     NOT NULL,

    CONSTRAINT pk_referrals PRIMARY KEY (referral_id),
    CONSTRAINT uq_referrals_source_id UNIQUE (source_referral_id),
    CONSTRAINT fk_referrals_patients
        FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_coverages
        FOREIGN KEY (coverage_id)
        REFERENCES coverages (coverage_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_referring_practitioner
        FOREIGN KEY (referring_practitioner_id)
        REFERENCES practitioners (practitioner_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_referring_organization
        FOREIGN KEY (referring_organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_referring_location
        FOREIGN KEY (referring_location_id)
        REFERENCES locations (location_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_specialties
        FOREIGN KEY (specialty_id)
        REFERENCES specialties (specialty_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_destination_practitioner
        FOREIGN KEY (destination_practitioner_id)
        REFERENCES practitioners (practitioner_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_destination_organization
        FOREIGN KEY (destination_organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referrals_current_owner
        FOREIGN KEY (current_owner_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_referrals_id_format
        CHECK (referral_id REGEXP '^REF[0-9]{6}$'),
    CONSTRAINT chk_referrals_source_system
        CHECK (source_system IN ('NorthStar EHR', 'Manual Entry', 'FHIR Test')),
    CONSTRAINT chk_referrals_priority
        CHECK (priority IN ('Routine', 'Urgent')),
    CONSTRAINT chk_referrals_status
        CHECK (
            current_status IN
                ('Received', 'Needs Information', 'Ready for Outreach',
                 'Outreach in Progress', 'Scheduled',
                 'Completed—Report Pending', 'Closed—Completed',
                 'Closed—Not Completed', 'Cancelled')
        ),
    CONSTRAINT chk_referrals_queue
        CHECK (
            current_queue IS NULL
            OR current_queue IN
                ('New Intake', 'Needs Information', 'Ready for Outreach',
                 'Outreach Follow-Up', 'Appointment Verification',
                 'Report Pending', 'Urgent Escalations',
                 'Unassigned Referrals', 'Data Exceptions')
        ),
    CONSTRAINT chk_referrals_closure_category
        CHECK (
            closure_category IS NULL
            OR closure_category IN ('Completed', 'Not Completed', 'Cancelled')
        ),
    CONSTRAINT chk_referrals_closure_reason
        CHECK (
            closure_reason IS NULL
            OR closure_reason IN
                ('Patient Declined', 'Unable to Contact After Protocol',
                 'No Longer Clinically Indicated', 'Transferred Care',
                 'Patient Moved', 'Duplicate Referral',
                 'Insurance or Access Barrier',
                 'Patient Chose Another Provider', 'Other Authorized Reason')
        ),
    CONSTRAINT chk_referrals_received_order
        CHECK (referral_received_at >= source_ordered_at),
    CONSTRAINT chk_referrals_current_stage
        CHECK (current_stage_started_at >= referral_received_at),
    CONSTRAINT chk_referrals_closed_at
        CHECK (closed_at IS NULL OR closed_at >= referral_received_at),
    CONSTRAINT chk_referrals_terminal_fields
        CHECK (
            (
                current_status NOT IN
                    ('Closed—Completed', 'Closed—Not Completed', 'Cancelled')
                AND closed_at IS NULL
                AND closure_category IS NULL
            )
            OR
            (
                current_status = 'Closed—Completed'
                AND closed_at IS NOT NULL
                AND closure_category = 'Completed'
            )
            OR
            (
                current_status = 'Closed—Not Completed'
                AND closed_at IS NOT NULL
                AND closure_category = 'Not Completed'
                AND closure_reason IS NOT NULL
            )
            OR
            (
                current_status = 'Cancelled'
                AND closed_at IS NOT NULL
                AND closure_category = 'Cancelled'
            )
        ),
    CONSTRAINT chk_referrals_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 10. REFERRAL STATUS HISTORY
-- ============================================================================

CREATE TABLE referral_status_history (
    status_history_id  VARCHAR(12)  NOT NULL,
    referral_id        VARCHAR(12)  NOT NULL,
    previous_status    VARCHAR(40)  NULL,
    new_status         VARCHAR(40)  NOT NULL,
    status_changed_at  DATETIME     NOT NULL,
    changed_by_user_id VARCHAR(10)  NULL,
    change_source      VARCHAR(30)  NOT NULL,
    change_reason      VARCHAR(255) NULL,
    override_flag      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at         DATETIME     NOT NULL,

    CONSTRAINT pk_referral_status_history PRIMARY KEY (status_history_id),
    CONSTRAINT fk_status_history_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_status_history_users
        FOREIGN KEY (changed_by_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_status_history_id_format
        CHECK (status_history_id REGEXP '^STH[0-9]{6}$'),
    CONSTRAINT chk_status_history_previous
        CHECK (
            previous_status IS NULL
            OR previous_status IN
                ('Received', 'Needs Information', 'Ready for Outreach',
                 'Outreach in Progress', 'Scheduled',
                 'Completed—Report Pending', 'Closed—Completed',
                 'Closed—Not Completed', 'Cancelled')
        ),
    CONSTRAINT chk_status_history_new
        CHECK (
            new_status IN
                ('Received', 'Needs Information', 'Ready for Outreach',
                 'Outreach in Progress', 'Scheduled',
                 'Completed—Report Pending', 'Closed—Completed',
                 'Closed—Not Completed', 'Cancelled')
        ),
    CONSTRAINT chk_status_history_source
        CHECK (change_source IN ('User', 'Interface', 'Automation', 'Migration', 'Correction')),
    CONSTRAINT chk_status_history_override
        CHECK (
            override_flag IN (0, 1)
            AND (override_flag = 0 OR change_reason IS NOT NULL)
        )
) ENGINE = InnoDB;

-- ============================================================================
-- 11. OUTREACH ATTEMPTS
-- ============================================================================

CREATE TABLE outreach_attempts (
    outreach_attempt_id  VARCHAR(12)  NOT NULL,
    referral_id          VARCHAR(12)  NOT NULL,
    performed_by_user_id VARCHAR(10)  NOT NULL,
    attempt_at           DATETIME     NOT NULL,
    communication_channel VARCHAR(20) NOT NULL,
    contacted_party      VARCHAR(30)  NOT NULL,
    outreach_outcome     VARCHAR(30)  NOT NULL,
    next_action_at       DATETIME     NULL,
    outreach_note        VARCHAR(500) NULL,
    created_at           DATETIME     NOT NULL,

    CONSTRAINT pk_outreach_attempts PRIMARY KEY (outreach_attempt_id),
    CONSTRAINT fk_outreach_attempts_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_outreach_attempts_users
        FOREIGN KEY (performed_by_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_outreach_attempts_id_format
        CHECK (outreach_attempt_id REGEXP '^OUT[0-9]{6}$'),
    CONSTRAINT chk_outreach_attempts_channel
        CHECK (
            communication_channel IN
                ('Phone', 'Voicemail', 'SMS', 'Patient Portal', 'Email', 'Fax', 'Other')
        ),
    CONSTRAINT chk_outreach_attempts_party
        CHECK (
            contacted_party IN
                ('Patient', 'Caregiver', 'Specialist Office',
                 'Referring Office', 'Payer', 'Other')
        ),
    CONSTRAINT chk_outreach_attempts_outcome
        CHECK (
            outreach_outcome IN
                ('Reached', 'No Answer', 'Voicemail Left', 'Invalid Contact',
                 'Callback Requested', 'Declined', 'Already Scheduled',
                 'Support Needed', 'Other')
        ),
    CONSTRAINT chk_outreach_attempts_next_action
        CHECK (next_action_at IS NULL OR next_action_at >= attempt_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 12. APPOINTMENTS
-- ============================================================================

CREATE TABLE appointments (
    appointment_id               VARCHAR(12)  NOT NULL,
    referral_id                  VARCHAR(12)  NOT NULL,
    practitioner_id              VARCHAR(12)  NULL,
    organization_id              VARCHAR(10)  NULL,
    location_id                  VARCHAR(10)  NULL,
    scheduled_at                 DATETIME     NOT NULL,
    appointment_start_at         DATETIME     NOT NULL,
    appointment_status           VARCHAR(20)  NOT NULL,
    outcome_recorded_at          DATETIME     NULL,
    scheduling_source            VARCHAR(30)  NOT NULL,
    telehealth_flag              BOOLEAN      NOT NULL DEFAULT FALSE,
    outcome_reason               VARCHAR(100) NULL,
    superseded_by_appointment_id VARCHAR(12)  NULL,
    created_at                   DATETIME     NOT NULL,
    updated_at                   DATETIME     NOT NULL,

    CONSTRAINT pk_appointments PRIMARY KEY (appointment_id),
    CONSTRAINT fk_appointments_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_practitioners
        FOREIGN KEY (practitioner_id)
        REFERENCES practitioners (practitioner_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_organizations
        FOREIGN KEY (organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_locations
        FOREIGN KEY (location_id)
        REFERENCES locations (location_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_superseded_by
        FOREIGN KEY (superseded_by_appointment_id)
        REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_appointments_id_format
        CHECK (appointment_id REGEXP '^APT[0-9]{6}$'),
    CONSTRAINT chk_appointments_status
        CHECK (
            appointment_status IN
                ('Scheduled', 'Completed', 'Cancelled', 'No-show', 'Rescheduled', 'Unknown')
        ),
    CONSTRAINT chk_appointments_scheduling_source
        CHECK (
            scheduling_source IN
                ('NorthStar Staff', 'Specialist Office', 'Patient', 'Interface', 'Other')
        ),
    CONSTRAINT chk_appointments_outcome_timestamp
        CHECK (
            appointment_status IN ('Scheduled', 'Unknown')
            OR outcome_recorded_at IS NOT NULL
        ),
    CONSTRAINT chk_appointments_outcome_order
        CHECK (
            outcome_recorded_at IS NULL
            OR outcome_recorded_at >= scheduled_at
        ),
    -- MySQL Error 3823 prevents a column used by a foreign key with
    -- referential actions from also being used in this CHECK constraint.
    -- The rule "Rescheduled requires superseded_by_appointment_id" is
    -- therefore enforced by the DQ-013 validation query after data loading.
    CONSTRAINT chk_appointments_telehealth_flag
        CHECK (telehealth_flag IN (0, 1)),
    CONSTRAINT chk_appointments_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 13. CONSULT REPORTS
-- ============================================================================

CREATE TABLE consult_reports (
    consult_report_id           VARCHAR(12)  NOT NULL,
    external_document_id        VARCHAR(40)  NULL,
    referral_id                 VARCHAR(12)  NULL,
    appointment_id              VARCHAR(12)  NULL,
    author_practitioner_id      VARCHAR(12)  NULL,
    source_organization_id      VARCHAR(10)  NULL,
    reviewed_by_practitioner_id VARCHAR(12)  NULL,
    report_source               VARCHAR(30)  NOT NULL,
    report_date                 DATE         NULL,
    received_at                 DATETIME     NOT NULL,
    match_method                VARCHAR(30)  NOT NULL,
    match_status                VARCHAR(20)  NOT NULL,
    routed_at                   DATETIME     NULL,
    reviewed_at                 DATETIME     NULL,
    report_status               VARCHAR(20)  NOT NULL,
    created_at                  DATETIME     NOT NULL,
    updated_at                  DATETIME     NOT NULL,

    CONSTRAINT pk_consult_reports PRIMARY KEY (consult_report_id),
    CONSTRAINT uq_consult_reports_external_id UNIQUE (external_document_id),
    CONSTRAINT fk_consult_reports_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_consult_reports_appointments
        FOREIGN KEY (appointment_id)
        REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_consult_reports_author
        FOREIGN KEY (author_practitioner_id)
        REFERENCES practitioners (practitioner_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_consult_reports_source_organization
        FOREIGN KEY (source_organization_id)
        REFERENCES organizations (organization_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_consult_reports_reviewer
        FOREIGN KEY (reviewed_by_practitioner_id)
        REFERENCES practitioners (practitioner_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_consult_reports_id_format
        CHECK (consult_report_id REGEXP '^RPT[0-9]{6}$'),
    CONSTRAINT chk_consult_reports_source
        CHECK (
            report_source IN
                ('FHIR', 'EHR Exchange', 'Portal', 'Fax', 'Mail', 'Manual Upload', 'Other')
        ),
    CONSTRAINT chk_consult_reports_match_method
        CHECK (match_method IN ('Automatic', 'Manual', 'Unmatched')),
    CONSTRAINT chk_consult_reports_match_status
        CHECK (match_status IN ('Matched', 'Ambiguous', 'Unmatched')),
    CONSTRAINT chk_consult_reports_report_status
        CHECK (report_status IN ('Received', 'Routed', 'Reviewed', 'Rejected', 'Duplicate')),
    -- DQ-014 validates that every matched report has a referral_id.
    -- MySQL Error 3823 prevents referral_id from being used here because it
    -- also participates in a foreign key with referential actions.
    CONSTRAINT chk_consult_reports_routing_order
        CHECK (routed_at IS NULL OR routed_at >= received_at),
    CONSTRAINT chk_consult_reports_review_order
        CHECK (
            reviewed_at IS NULL
            OR (routed_at IS NOT NULL AND reviewed_at >= routed_at)
        ),
    -- DQ-015 validates that reviewed reports have a reviewer and logically
    -- ordered routed/reviewed timestamps. reviewed_by_practitioner_id cannot
    -- participate in a CHECK because it is also a foreign-key column.
    CONSTRAINT chk_consult_reports_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 14. REFERRAL VALIDATION ISSUES
-- ============================================================================

CREATE TABLE referral_validation_issues (
    validation_issue_id VARCHAR(12)  NOT NULL,
    referral_id         VARCHAR(12)  NULL,
    source_record_id    VARCHAR(40)  NULL,
    issue_source        VARCHAR(30)  NOT NULL,
    rule_code           VARCHAR(30)  NOT NULL,
    field_name          VARCHAR(64)  NULL,
    severity            VARCHAR(20)  NOT NULL,
    issue_description   VARCHAR(500) NOT NULL,
    detected_at         DATETIME     NOT NULL,
    resolution_status   VARCHAR(25)  NOT NULL DEFAULT 'Open',
    resolved_by_user_id VARCHAR(10)  NULL,
    resolved_at         DATETIME     NULL,
    resolution_note     VARCHAR(500) NULL,
    created_at          DATETIME     NOT NULL,
    updated_at          DATETIME     NOT NULL,

    CONSTRAINT pk_referral_validation_issues PRIMARY KEY (validation_issue_id),
    CONSTRAINT fk_validation_issues_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_validation_issues_users
        FOREIGN KEY (resolved_by_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_validation_issues_id_format
        CHECK (validation_issue_id REGEXP '^VAL[0-9]{6}$'),
    CONSTRAINT chk_validation_issues_source
        CHECK (
            issue_source IN
                ('Intake', 'Migration', 'Interface', 'Data Quality', 'Workflow')
        ),
    CONSTRAINT chk_validation_issues_severity
        CHECK (severity IN ('Warning', 'Blocking', 'Critical')),
    CONSTRAINT chk_validation_issues_resolution_status
        CHECK (
            resolution_status IN
                ('Open', 'In Progress', 'Resolved', 'Accepted Exception')
        ),
    -- DQ-016 validates that resolved or accepted issues have a resolver and
    -- resolution timestamp. resolved_by_user_id cannot participate in a
    -- CHECK because it is also a foreign-key column.
    CONSTRAINT chk_validation_issues_resolution_order
        CHECK (resolved_at IS NULL OR resolved_at >= detected_at),
    CONSTRAINT chk_validation_issues_exception_note
        CHECK (
            resolution_status <> 'Accepted Exception'
            OR resolution_note IS NOT NULL
        ),
    CONSTRAINT chk_validation_issues_timestamps
        CHECK (updated_at >= created_at)
) ENGINE = InnoDB;

-- ============================================================================
-- 15. REFERRAL ASSIGNMENTS
-- ============================================================================

CREATE TABLE referral_assignments (
    assignment_id         VARCHAR(12)  NOT NULL,
    referral_id           VARCHAR(12)  NOT NULL,
    assigned_user_id      VARCHAR(10)  NULL,
    queue_name            VARCHAR(40)  NULL,
    assigned_by_user_id   VARCHAR(10)  NULL,
    assignment_source     VARCHAR(30)  NOT NULL,
    assignment_start_at   DATETIME     NOT NULL,
    assignment_end_at     DATETIME     NULL,
    assignment_reason     VARCHAR(255) NULL,
    active_assignment_flag BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at            DATETIME     NOT NULL,

    CONSTRAINT pk_referral_assignments PRIMARY KEY (assignment_id),
    CONSTRAINT fk_referral_assignments_referrals
        FOREIGN KEY (referral_id)
        REFERENCES referrals (referral_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referral_assignments_assigned_user
        FOREIGN KEY (assigned_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_referral_assignments_assigned_by
        FOREIGN KEY (assigned_by_user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_referral_assignments_id_format
        CHECK (assignment_id REGEXP '^ASN[0-9]{6}$'),
    CONSTRAINT chk_referral_assignments_queue
        CHECK (
            queue_name IS NULL
            OR queue_name IN
                ('New Intake', 'Needs Information', 'Ready for Outreach',
                 'Outreach Follow-Up', 'Appointment Verification',
                 'Report Pending', 'Urgent Escalations',
                 'Unassigned Referrals', 'Data Exceptions')
        ),
    -- DQ-008 validates that each active referral has an accountable user or
    -- queue. assigned_user_id cannot participate in a CHECK because it is
    -- also a foreign-key column.
    CONSTRAINT chk_referral_assignments_source
        CHECK (assignment_source IN ('User', 'Automation', 'Migration', 'Interface')),
    CONSTRAINT chk_referral_assignments_date_order
        CHECK (
            assignment_end_at IS NULL
            OR assignment_end_at >= assignment_start_at
        ),
    CONSTRAINT chk_referral_assignments_active_fields
        CHECK (
            active_assignment_flag IN (0, 1)
            AND (
                (active_assignment_flag = 1 AND assignment_end_at IS NULL)
                OR (active_assignment_flag = 0 AND assignment_end_at IS NOT NULL)
            )
        )
) ENGINE = InnoDB;

-- ============================================================================
-- OPERATIONAL AND ANALYTICAL INDEXES
-- Foreign-key columns are also indexed explicitly for clarity and portability.
-- ============================================================================

CREATE INDEX idx_locations_organization
    ON locations (organization_id);

CREATE INDEX idx_practitioners_organization_specialty
    ON practitioners (organization_id, specialty_id);

CREATE INDEX idx_coverages_patient_status
    ON coverages (patient_id, coverage_status, effective_date, termination_date);

CREATE INDEX idx_coverages_payer
    ON coverages (payer_id);

CREATE INDEX idx_users_location_role
    ON users (location_id, user_role, active_flag);

CREATE INDEX idx_referrals_work_queue
    ON referrals (current_status, priority, service_level_due_at);

CREATE INDEX idx_referrals_owner_queue
    ON referrals (current_queue, current_owner_user_id);

CREATE INDEX idx_referrals_received
    ON referrals (referral_received_at);

CREATE INDEX idx_referrals_site_specialty
    ON referrals (referring_location_id, specialty_id, referral_received_at);

CREATE INDEX idx_referrals_patient
    ON referrals (patient_id, referral_received_at);

CREATE INDEX idx_referrals_destination
    ON referrals (destination_organization_id, destination_practitioner_id);

CREATE INDEX idx_status_history_referral_time
    ON referral_status_history (referral_id, status_changed_at);

CREATE INDEX idx_status_history_new_status
    ON referral_status_history (new_status, status_changed_at);

CREATE INDEX idx_outreach_referral_time
    ON outreach_attempts (referral_id, attempt_at);

CREATE INDEX idx_outreach_next_action
    ON outreach_attempts (next_action_at, outreach_outcome);

CREATE INDEX idx_appointments_referral_start
    ON appointments (referral_id, appointment_start_at);

CREATE INDEX idx_appointments_status_start
    ON appointments (appointment_status, appointment_start_at);

CREATE INDEX idx_consult_reports_referral_received
    ON consult_reports (referral_id, received_at);

CREATE INDEX idx_consult_reports_matching
    ON consult_reports (match_status, received_at);

CREATE INDEX idx_validation_issues_work_queue
    ON referral_validation_issues
        (resolution_status, severity, detected_at);

CREATE INDEX idx_validation_issues_referral
    ON referral_validation_issues (referral_id, resolution_status);

CREATE INDEX idx_assignments_referral_active
    ON referral_assignments (referral_id, active_assignment_flag);

CREATE INDEX idx_assignments_user_active
    ON referral_assignments (assigned_user_id, active_assignment_flag);

-- ============================================================================
-- SCHEMA VERIFICATION
-- Run these read-only statements after the script completes.
-- Expected table count: 15
-- ============================================================================

SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'healthcare_referral_management'
  AND table_type = 'BASE TABLE';

SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'healthcare_referral_management'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'healthcare_referral_management'
ORDER BY table_name, constraint_type, constraint_name;

-- End of create_database.sql
