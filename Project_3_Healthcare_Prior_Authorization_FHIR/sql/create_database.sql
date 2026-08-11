-- ============================================================
-- Project 3: Healthcare Prior Authorization and FHIR
-- Author: Brandon McDermott
-- Organization: Northstar Health Network — Synthetic Case Study
-- Purpose: Create the relational database and eight source tables
-- ============================================================

DROP DATABASE IF EXISTS healthcare_prior_authorization;

CREATE DATABASE healthcare_prior_authorization
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE healthcare_prior_authorization;

-- ============================================================
-- 1. PATIENTS
-- ============================================================

CREATE TABLE patients (
    patient_id VARCHAR(10) NOT NULL,
    medical_record_number VARCHAR(12) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    administrative_sex VARCHAR(10) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,

    CONSTRAINT pk_patients
        PRIMARY KEY (patient_id),

    CONSTRAINT uq_patients_mrn
        UNIQUE (medical_record_number),

    CONSTRAINT chk_patient_sex
        CHECK (
            administrative_sex IN (
                'female',
                'male',
                'other',
                'unknown'
            )
        )
);

-- ============================================================
-- 2. PROVIDERS
-- ============================================================

CREATE TABLE providers (
    provider_id VARCHAR(10) NOT NULL,
    npi CHAR(10) NOT NULL,
    provider_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(75) NOT NULL,
    organization_name VARCHAR(100) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_providers
        PRIMARY KEY (provider_id),

    CONSTRAINT uq_providers_npi
        UNIQUE (npi),

    CONSTRAINT chk_provider_npi
        CHECK (npi REGEXP '^[0-9]{10}$')
);

-- ============================================================
-- 3. PAYERS
-- ============================================================

CREATE TABLE payers (
    payer_id VARCHAR(10) NOT NULL,
    payer_name VARCHAR(100) NOT NULL,
    plan_type VARCHAR(20) NOT NULL,
    standard_sla_hours INT NOT NULL,
    expedited_sla_hours INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_payers
        PRIMARY KEY (payer_id),

    CONSTRAINT uq_payer_name
        UNIQUE (payer_name),

    CONSTRAINT chk_payer_plan_type
        CHECK (
            plan_type IN (
                'HMO',
                'PPO',
                'EPO',
                'POS',
                'Medicaid',
                'Medicare Advantage'
            )
        ),

    CONSTRAINT chk_standard_sla
        CHECK (standard_sla_hours > 0),

    CONSTRAINT chk_expedited_sla
        CHECK (
            expedited_sla_hours > 0
            AND expedited_sla_hours <= standard_sla_hours
        )
);

-- ============================================================
-- 4. COVERAGES
-- ============================================================

CREATE TABLE coverages (
    coverage_id VARCHAR(10) NOT NULL,
    patient_id VARCHAR(10) NOT NULL,
    payer_id VARCHAR(10) NOT NULL,
    member_id VARCHAR(20) NOT NULL,
    group_number VARCHAR(20),
    coverage_start_date DATE NOT NULL,
    coverage_end_date DATE,
    coverage_status VARCHAR(15) NOT NULL,

    CONSTRAINT pk_coverages
        PRIMARY KEY (coverage_id),

    CONSTRAINT uq_coverage_member
        UNIQUE (payer_id, member_id),

    CONSTRAINT fk_coverage_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id),

    CONSTRAINT fk_coverage_payer
        FOREIGN KEY (payer_id)
        REFERENCES payers (payer_id),

    CONSTRAINT chk_coverage_status
        CHECK (
            coverage_status IN (
                'active',
                'inactive',
                'cancelled',
                'pending'
            )
        ),

    CONSTRAINT chk_coverage_dates
        CHECK (
            coverage_end_date IS NULL
            OR coverage_end_date >= coverage_start_date
        )
);

-- ============================================================
-- 5. PROCEDURES
-- ============================================================

CREATE TABLE procedures (
    procedure_id VARCHAR(10) NOT NULL,
    procedure_code VARCHAR(10) NOT NULL,
    procedure_description VARCHAR(150) NOT NULL,
    service_category VARCHAR(50) NOT NULL,
    authorization_required BOOLEAN NOT NULL,

    CONSTRAINT pk_procedures
        PRIMARY KEY (procedure_id),

    CONSTRAINT uq_procedure_code
        UNIQUE (procedure_code)
);

-- ============================================================
-- 6. DIAGNOSES
-- ============================================================

CREATE TABLE diagnoses (
    diagnosis_id VARCHAR(10) NOT NULL,
    diagnosis_code VARCHAR(10) NOT NULL,
    diagnosis_description VARCHAR(150) NOT NULL,
    code_system VARCHAR(20) NOT NULL DEFAULT 'ICD-10-CM',

    CONSTRAINT pk_diagnoses
        PRIMARY KEY (diagnosis_id),

    CONSTRAINT uq_diagnosis_code
        UNIQUE (diagnosis_code),

    CONSTRAINT chk_diagnosis_code_system
        CHECK (code_system = 'ICD-10-CM')
);

-- ============================================================
-- 7. AUTHORIZATION REQUESTS
-- ============================================================

CREATE TABLE authorization_requests (
    authorization_id VARCHAR(12) NOT NULL,
    patient_id VARCHAR(10) NOT NULL,
    provider_id VARCHAR(10) NOT NULL,
    coverage_id VARCHAR(10) NOT NULL,
    procedure_id VARCHAR(10) NOT NULL,
    diagnosis_id VARCHAR(10) NOT NULL,
    created_at DATETIME NOT NULL,
    submitted_at DATETIME,
    urgency VARCHAR(15) NOT NULL,
    documentation_status VARCHAR(20) NOT NULL,
    current_status VARCHAR(40) NOT NULL,
    decision_at DATETIME,
    authorization_number VARCHAR(30),
    denial_reason VARCHAR(150),
    requested_service_date DATE NOT NULL,

    CONSTRAINT pk_authorization_requests
        PRIMARY KEY (authorization_id),

    CONSTRAINT uq_authorization_number
        UNIQUE (authorization_number),

    CONSTRAINT fk_authorization_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id),

    CONSTRAINT fk_authorization_provider
        FOREIGN KEY (provider_id)
        REFERENCES providers (provider_id),

    CONSTRAINT fk_authorization_coverage
        FOREIGN KEY (coverage_id)
        REFERENCES coverages (coverage_id),

    CONSTRAINT fk_authorization_procedure
        FOREIGN KEY (procedure_id)
        REFERENCES procedures (procedure_id),

    CONSTRAINT fk_authorization_diagnosis
        FOREIGN KEY (diagnosis_id)
        REFERENCES diagnoses (diagnosis_id),

    CONSTRAINT chk_authorization_urgency
        CHECK (
            urgency IN (
                'standard',
                'expedited'
            )
        ),

    CONSTRAINT chk_documentation_status
        CHECK (
            documentation_status IN (
                'complete',
                'incomplete',
                'not-required',
                'pending-review'
            )
        ),

    CONSTRAINT chk_authorization_status
        CHECK (
            current_status IN (
                'Draft',
                'Submitted',
                'Additional Information Required',
                'In Review',
                'Approved',
                'Denied',
                'Cancelled'
            )
        ),

    CONSTRAINT chk_created_before_submitted
        CHECK (
            submitted_at IS NULL
            OR submitted_at >= created_at
        ),

    CONSTRAINT chk_decision_after_submission
        CHECK (
            decision_at IS NULL
            OR (
                submitted_at IS NOT NULL
                AND decision_at >= submitted_at
            )
        ),

    CONSTRAINT chk_final_decision_date
        CHECK (
            current_status NOT IN ('Approved', 'Denied')
            OR decision_at IS NOT NULL
        ),

    CONSTRAINT chk_approved_number
        CHECK (
            current_status <> 'Approved'
            OR authorization_number IS NOT NULL
        ),

    CONSTRAINT chk_denied_reason
        CHECK (
            current_status <> 'Denied'
            OR denial_reason IS NOT NULL
        ),

    CONSTRAINT chk_service_date
        CHECK (requested_service_date >= DATE(created_at))
);

-- ============================================================
-- 8. STATUS HISTORY
-- ============================================================

CREATE TABLE status_history (
    status_event_id VARCHAR(14) NOT NULL,
    authorization_id VARCHAR(12) NOT NULL,
    status VARCHAR(40) NOT NULL,
    status_at DATETIME NOT NULL,
    actor_type VARCHAR(30) NOT NULL,
    action_required BOOLEAN NOT NULL DEFAULT FALSE,
    event_notes VARCHAR(255),

    CONSTRAINT pk_status_history
        PRIMARY KEY (status_event_id),

    CONSTRAINT fk_status_authorization
        FOREIGN KEY (authorization_id)
        REFERENCES authorization_requests (authorization_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_history_status
        CHECK (
            status IN (
                'Draft',
                'Submitted',
                'Additional Information Required',
                'In Review',
                'Approved',
                'Denied',
                'Cancelled'
            )
        ),

    CONSTRAINT chk_actor_type
        CHECK (
            actor_type IN (
                'Ordering Provider',
                'Clinical Staff',
                'Authorization Specialist',
                'Payer',
                'Scheduling Staff',
                'System'
            )
        )
);

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================

CREATE INDEX idx_authorization_patient
    ON authorization_requests (patient_id);

CREATE INDEX idx_authorization_provider
    ON authorization_requests (provider_id);

CREATE INDEX idx_authorization_status
    ON authorization_requests (current_status);

CREATE INDEX idx_authorization_submitted
    ON authorization_requests (submitted_at);

CREATE INDEX idx_status_authorization_time
    ON status_history (authorization_id, status_at);

-- ============================================================
-- VERIFICATION
-- ============================================================

SHOW TABLES;