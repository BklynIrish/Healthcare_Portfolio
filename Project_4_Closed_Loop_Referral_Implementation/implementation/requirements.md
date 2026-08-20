# Solution Requirements

## Project

**Closed-Loop Specialty Referral Management: Healthcare SaaS Implementation and Analytics**

## Document Purpose

This document defines the requirements for NorthStar Medical Group's simulated referral-management SaaS implementation. Each requirement has a unique identifier, priority, and testable acceptance criterion so it can later be traced to solution configuration, technical deliverables, and user-acceptance testing.

NorthStar Medical Group and all requirements are fictional. The document demonstrates a realistic healthcare implementation method and is not a production specification.

## Requirement Conventions

### Requirement types

| Prefix | Type |
|---|---|
| BR | Business requirement |
| FR | Functional requirement |
| DR | Data requirement |
| IR | Integration requirement |
| RR | Reporting and analytics requirement |
| SR | Security, privacy, and audit requirement |
| NFR | Nonfunctional requirement |
| IMR | Implementation, testing, training, and support requirement |

### Priority scale

| Priority | Meaning |
|---|---|
| Must | Required for the portfolio MVP or safe workflow demonstration |
| Should | Important but can follow the core MVP if necessary |
| Could | Valuable future enhancement |

## 1. Business Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| BR-001 | Must | NorthStar shall use one standardized enterprise referral-status model. | Every referral status maps to an approved value with documented entry and exit conditions. |
| BR-002 | Must | Every active referral shall have an accountable owner or operational queue. | A query returns zero active referrals lacking both an owner and valid queue, except documented interface exceptions. |
| BR-003 | Must | The organization shall distinguish referral scheduling, encounter completion, report receipt, and clinical closure. | The data model and workflow contain separate fields or events for all four milestones. |
| BR-004 | Must | Urgent and overdue referrals shall be distinguishable from routine work. | Users can retrieve an urgent or overdue queue using defined priority and service-level logic. |
| BR-005 | Must | Referral closure shall use standardized completed and non-completed criteria. | Every closed referral satisfies completed closure rules or contains an approved non-completion or cancellation reason. |
| BR-006 | Must | Leadership shall be able to evaluate referral performance across the lifecycle. | The dashboard reports intake, outreach, scheduling, completion, report receipt, closure, and aging metrics. |
| BR-007 | Should | Site and specialty performance shall be comparable using governed definitions. | The same metric logic applies to all sites and specialties, with documented exclusions. |
| BR-008 | Must | The implementation shall preserve human review for clinical priority and clinical escalation. | No automated process independently assigns or changes clinical urgency without an authorized user action. |

## 2. Functional Requirements

### 2.1 Referral Intake and Validation

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-001 | Must | The system shall create a unique internal referral record for every accepted source referral. | Each loaded referral has a non-null unique internal identifier and retained source identifier. |
| FR-002 | Must | The system shall record the source system and referral-received timestamp. | Both values are populated for at least 99% of accepted referrals; exceptions are reported. |
| FR-003 | Must | The system shall validate required patient, provider, clinical, payer, specialty, priority, and document fields. | Each referral receives a validation result and a structured list of blocking failures. |
| FR-004 | Must | Referrals with blocking validation failures shall enter `Needs Information`. | A deliberately incomplete test referral is routed to the correct status and queue. |
| FR-005 | Must | Authorized users shall be able to resolve validation failures. | After required corrections, the referral passes validation and advances without losing its history. |
| FR-006 | Should | Authorized users may override selected nonclinical validation rules with a reason. | An override requires user, timestamp, rule, and explanatory reason. |
| FR-007 | Should | The system shall identify possible duplicate active referrals. | A configured duplicate test case is flagged without being automatically deleted. |

### 2.2 Assignment, Queues, and Service Levels

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-008 | Must | The system shall assign complete referrals to an owner or accountable queue. | Every referral leaving intake has a valid assignment. |
| FR-009 | Must | Assignment rules shall consider at least location, specialty, and priority. | Test referrals with different combinations route to their expected queues. |
| FR-010 | Must | The system shall calculate a service-level due date for defined workflow stages. | Expected due dates match the approved rule for representative routine and urgent cases. |
| FR-011 | Must | The system shall flag referrals that exceed their current-stage service level. | A test referral past its due date returns `overdue_flag = 1`. |
| FR-012 | Must | Users shall be able to retrieve new-intake, needs-information, outreach, appointment-verification, report-pending, urgent-escalation, unassigned, and data-exception queues. | Each queue has documented inclusion logic and returns its seeded test cases. |
| FR-013 | Should | Referral managers shall be able to reassign referrals while preserving assignment history. | Reassignment records old owner, new owner, user, timestamp, and reason when required. |

### 2.3 Patient Outreach

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-014 | Must | Users shall record each outreach attempt as a separate event. | Multiple attempts can be stored for one referral without overwriting earlier attempts. |
| FR-015 | Must | Each outreach attempt shall capture timestamp, channel, outcome, and staff member. | These fields are required for all completed outreach events. |
| FR-016 | Should | Outreach attempts shall capture contacted party, next-action date, and optional notes. | Fields are stored and retrievable for representative test events. |
| FR-017 | Must | The system shall calculate attempt count and most recent attempt date. | Derived results match the underlying outreach records. |
| FR-018 | Must | Active outreach referrals shall have a documented next action or approved disposition. | A query identifies referrals lacking both and returns no unresolved critical test cases after remediation. |
| FR-019 | Should | Patient communication preference shall be visible when available. | The preference appears in the referral dataset or work queue without replacing staff judgment. |

### 2.4 Scheduling and Appointment Outcomes

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-020 | Must | Users shall record specialist, appointment date, location or modality, and scheduling source. | A scheduled referral contains all required appointment fields. |
| FR-021 | Must | Setting an appointment shall change referral status to `Scheduled` but shall not close the referral. | A scheduled test referral remains active and does not meet completed-closure logic. |
| FR-022 | Must | The system shall support completed, cancelled, no-show, rescheduled, and unknown appointment outcomes. | Each seeded outcome is accepted and routed according to the workflow. |
| FR-023 | Must | Elapsed appointments lacking a final outcome shall appear in an appointment-verification queue. | A past appointment with no outcome appears in the queue. |
| FR-024 | Should | Rescheduling shall preserve prior appointment history. | Both original and replacement appointment records remain available. |
| FR-025 | Must | Cancellation and no-show outcomes shall require a next action or approved closure review. | Seeded cancelled and no-show cases cannot disappear from active work without disposition. |

### 2.5 Report Follow-Up and Closure

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-026 | Must | A completed appointment shall move the referral to `Completed—Report Pending` unless an approved exception applies. | A completed test encounter enters the report-pending workflow. |
| FR-027 | Must | The system shall capture report received date, source, and document identifier. | These values are available for each linked report. |
| FR-028 | Must | A consultation report shall be linked to the originating referral. | The linked referral identifier is non-null, or the report appears in a matching-exception queue. |
| FR-029 | Must | Unmatched or ambiguously matched reports shall require human review. | Seeded ambiguous reports are not automatically attached and appear in the exception queue. |
| FR-030 | Must | Completed visits without reports shall appear in the report-pending queue. | The queue includes all seeded completed visits lacking reports and excludes those with valid reports. |
| FR-031 | Must | `Closed—Completed` shall require a completed encounter, received linked report, report routing, and required clinician review. | A referral missing any required milestone fails completed-closure validation. |
| FR-032 | Must | `Closed—Not Completed` shall require an approved reason and authorized disposition. | A non-completed closure lacking an approved reason is rejected or flagged. |
| FR-033 | Must | Cancellation shall be distinguishable from non-completion. | Cancelled and closed-not-completed are separate status or disposition values. |
| FR-034 | Should | Authorized users shall be able to reopen a terminal referral with a reason. | The action preserves prior closure data and records the user, timestamp, and reason. |

### 2.6 Status and Audit History

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| FR-035 | Must | Every material referral-status change shall create a history record. | Status-history counts and timestamps reconcile with test-case transitions. |
| FR-036 | Must | Status history shall capture prior status, new status, timestamp, and source or user. | All required fields are present for valid history records. |
| FR-037 | Must | Invalid status transitions shall be rejected or flagged. | Representative invalid transitions produce the expected error or exception. |
| FR-038 | Should | Users shall be able to view a chronological referral timeline. | A query or view returns ordered referral events for a selected record. |

## 3. Data Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| DR-001 | Must | The solution shall maintain defined patient, provider, organization, location, payer, specialty, referral, status-history, outreach, appointment, report, and user entities. | The physical schema contains the approved entities and relationships. |
| DR-002 | Must | Primary and foreign keys shall enforce referential integrity. | Orphan-record tests return zero unexplained records after the validated load. |
| DR-003 | Must | Controlled workflow values shall use reference tables or enforceable constraints. | Invalid statuses, priorities, appointment outcomes, and closure reasons are rejected or captured as exceptions. |
| DR-004 | Must | The database shall preserve source identifiers and source-system attribution. | Migrated records can be traced from target to source. |
| DR-005 | Must | Required timestamps shall use one documented time-zone convention. | The data dictionary identifies the convention and validation finds no invalid timestamp formats. |
| DR-006 | Must | Raw, transformed, and analytical data shall remain distinguishable. | Separate files, schemas, tables, or documented layers exist for each stage. |
| DR-007 | Must | Migration validation shall reconcile source and target record counts. | Counts are documented by entity, including accepted, rejected, and exception records. |
| DR-008 | Must | Migration validation shall check required fields, duplicates, referential integrity, allowed values, and date logic. | Each check has a reproducible SQL or Python result. |
| DR-009 | Must | Synthetic data shall include realistic exceptions and workflow variation. | The dataset contains documented missing, duplicate, late, cancelled, no-show, unmatched, and overdue cases. |
| DR-010 | Must | No real patient data or PHI shall appear in the project. | Manual review and automated scans find no known real patient identifiers or credentials. |
| DR-011 | Should | Analytical fields shall be reproducible from documented source fields and logic. | Each derived KPI field has a definition or transformation rule. |
| DR-012 | Should | Date logic shall reject impossible sequences. | Tests identify cases such as report receipt before encounter completion or closure before referral receipt. |

## 4. Integration Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| IR-001 | Must | The project shall document source-to-target mappings for referral data. | Every required target field maps to a source field, default, transformation, or documented gap. |
| IR-002 | Must | Representative referral information shall map to selected FHIR R4 resources. | The mapping covers `Patient`, `Practitioner`, `Organization`, `ServiceRequest`, `Task`, `Appointment`, and a report resource. |
| IR-003 | Must | FHIR JSON examples shall use syntactically valid JSON and documented identifiers or references. | JSON parsing succeeds and internal references resolve within each test bundle or documented server context. |
| IR-004 | Must | Postman tests shall demonstrate representative create or update and retrieval behavior. | The collection records expected successful responses for the defined positive tests. |
| IR-005 | Must | API testing shall include negative cases. | Missing required data, invalid references, or invalid values produce documented failure behavior. |
| IR-006 | Must | Integration failures shall be traceable to a source transaction or referral. | Error records include source identifier, timestamp, error category, and status. |
| IR-007 | Should | Retryable and non-retryable integration failures shall be distinguishable. | Error-handling documentation assigns representative failures to the correct category. |
| IR-008 | Must | The documentation shall state that the FHIR demonstration is not a production interface or certification. | The limitation appears in the FHIR documentation and README. |

## 5. Reporting and Analytics Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| RR-001 | Must | Every KPI shall have a documented definition, numerator, denominator, exclusions, date field, and null-handling rule. | The metric specification contains all required components before dashboard publication. |
| RR-002 | Must | The dashboard shall display referral volume, intake completeness, scheduling conversion, appointment completion, closed-loop rate, cycle times, no-show rate, and overdue open referrals. | Each KPI is present and reconciles to its approved SQL result. |
| RR-003 | Must | The dashboard shall show the referral funnel by meaningful workflow stage. | Funnel counts follow governed stage definitions and do not double-count referrals. |
| RR-004 | Must | Users shall be able to analyze performance by site, specialty, payer, provider, priority, status, and referral month where data permit. | Filters return expected representative subsets. |
| RR-005 | Must | The dashboard shall contain an actionable overdue-referral work queue. | The queue includes referral identifier, stage, owner, urgency, age, due date, and reason for inclusion. |
| RR-006 | Must | Dashboard calculations shall use reusable SQL views or documented transformations. | Published metrics can be reproduced outside Tableau. |
| RR-007 | Must | KPI validation shall compare Tableau outputs with independent SQL results. | Differences are zero or documented and resolved before publication. |
| RR-008 | Should | The dashboard shall distinguish simulated baseline and post-redesign scenarios without implying real-world causality. | Scenario labels and methodology notes appear in the dashboard or README. |
| RR-009 | Should | Small-cell or privacy-sensitive reporting considerations shall be documented even though data are synthetic. | Reporting documentation states how suppression or access controls would be handled in production. |

## 6. Security, Privacy, and Audit Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| SR-001 | Must | The proposed design shall use role-based access concepts. | A role-permission matrix defines representative access for each user type. |
| SR-002 | Must | Access shall follow a minimum-necessary principle. | Each role has only the permissions needed for its stated duties. |
| SR-003 | Must | Material workflow changes shall be attributable to a user or system source. | Audit fields exist for status, assignment, override, and closure actions. |
| SR-004 | Must | Overrides and terminal-status changes shall require a documented reason where defined. | Test records missing required reasons fail validation. |
| SR-005 | Must | The public repository shall contain only synthetic, nonconfidential data and nonsecret configuration. | Repository review finds no PHI, passwords, access tokens, private keys, or live credentials. |
| SR-006 | Should | Production security considerations shall include authentication, authorization, encryption, logging, retention, and incident response. | The architecture or security notes address all six areas as future production requirements. |
| SR-007 | Should | Analytical access shall be separated conceptually from operational write access. | The role model gives analysts approved read access without routine workflow-update privileges. |

## 7. Nonfunctional Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| NFR-001 | Must | The MVP shall run using Mac-compatible and accessible tools. | Core deliverables run in MySQL Workbench, Python, Postman, Tableau Public, VS Code, and GitHub. |
| NFR-002 | Must | SQL, Python, JSON, and documentation shall be reproducible from repository instructions. | A reviewer can follow the README to reproduce the core data and analytical workflow. |
| NFR-003 | Must | Naming conventions shall be consistent across datasets, database objects, code, and documentation. | QA finds no unexplained conflicting names for core entities or fields. |
| NFR-004 | Should | Queries and views shall complete within a reasonable time for approximately 2,500 referrals and their related events. | Core analytical queries execute without material delay in the portfolio environment. |
| NFR-005 | Must | Errors shall be understandable and traceable. | Data and API exception outputs identify the affected record and rule or error category. |
| NFR-006 | Must | Documentation shall distinguish implemented behavior, simulated behavior, assumptions, and future production needs. | README and major deliverables use explicit labels consistently. |
| NFR-007 | Should | Workflow and dashboard outputs shall be understandable to both operational and technical reviewers. | UAT or structured review confirms that key actions and metric definitions can be identified without source-code inspection. |

## 8. Implementation, Testing, Training, and Support Requirements

| ID | Priority | Requirement | Acceptance criterion |
|---|---|---|---|
| IMR-001 | Must | Requirements shall be traceable to configuration, code, documentation, or tests. | A traceability matrix contains every Must requirement and its verification method. |
| IMR-002 | Must | The implementation shall maintain a configuration workbook. | Statuses, queues, controlled values, service levels, and selected business rules are documented. |
| IMR-003 | Must | Data migration shall include pre-load, load, and post-load validation. | The migration report records results for all three stages. |
| IMR-004 | Must | UAT shall include positive, negative, boundary, and end-to-end referral scenarios. | The UAT plan contains all four test categories. |
| IMR-005 | Must | Critical workflow scenarios shall pass before go-live readiness is declared. | No open critical defects remain, or a formal non-go-live decision is documented. |
| IMR-006 | Must | Defects shall record severity, owner, status, evidence, resolution, and retest result. | Every logged defect contains all required fields. |
| IMR-007 | Must | Training shall be role-based. | Referral coordinators, managers, clinicians, and support staff have distinct learning objectives or materials. |
| IMR-008 | Must | The go-live runbook shall include readiness checks, cutover steps, validation, rollback, support, and escalation. | All six sections are present and assigned. |
| IMR-009 | Should | The implementation shall define post-launch adoption and performance monitoring. | The support plan includes queue usage, data quality, defects, KPI stability, and user feedback. |
| IMR-010 | Must | Scope changes and key design decisions shall be documented. | A decision log or change log records the date, decision, rationale, owner, and affected deliverables. |
| IMR-011 | Must | The final portfolio README shall explain the problem, approach, solution, validation, findings, limitations, and how to reproduce the work. | All sections are present and linked to supporting artifacts. |
| IMR-012 | Must | The public case study shall not describe simulated improvements as actual client outcomes. | QA review confirms that all modeled results are labeled as synthetic or scenario-based. |

## 9. Requirements Summary

| Type | Must | Should | Could | Total |
|---|---:|---:|---:|---:|
| Business | 7 | 1 | 0 | 8 |
| Functional | 30 | 8 | 0 | 38 |
| Data | 10 | 2 | 0 | 12 |
| Integration | 7 | 1 | 0 | 8 |
| Reporting and analytics | 7 | 2 | 0 | 9 |
| Security, privacy, and audit | 5 | 2 | 0 | 7 |
| Nonfunctional | 5 | 2 | 0 | 7 |
| Implementation and support | 11 | 1 | 0 | 12 |
| **Total** | **81** | **20** | **0** | **101** |

## 10. Approval and Baseline

For this portfolio simulation, version 1.0 establishes the initial requirements baseline. Subsequent changes should record:

- Requirement ID
- Requested change
- Reason
- Requestor or owner
- Impact on workflow, data, configuration, reporting, testing, or training
- Decision and decision date
- Updated version

## Portfolio Transparency Note

The requirements are intentionally more complete than the features that will be technically implemented in the MVP. A final traceability matrix will identify whether each requirement is demonstrated through working code, SQL, configuration, API testing, documentation, or a future-production recommendation. This prevents documentation-only requirements from being misrepresented as functioning software.
