# Project Requirements

**Project:** Healthcare Prior Authorization Workflow and FHIR API Integration  
**Organization:** Northstar Health Network — Synthetic Case Study  
**Author:** Brandon McDermott  
**Status:** In Development  

## 1. Purpose

This document defines the business, functional, data, technical, and reporting requirements for a prototype prior-authorization workflow.

The prototype will demonstrate how Northstar Health Network could improve authorization submission completeness, status tracking, operational visibility, and performance measurement.

## 2. Business Requirements

### BR-01: Submission Completeness

The solution must identify whether a prior-authorization request contains the information required for payer review.

### BR-02: Authorization Status Tracking

The solution must track each request through its major statuses:

- Draft
- Submitted
- Additional Information Required
- In Review
- Approved
- Denied
- Cancelled

### BR-03: Workflow Visibility

Authorized users must be able to determine the current status of each request and identify requests requiring action.

### BR-04: Delay Identification

The solution must identify requests that exceed the established turnaround-time target.

### BR-05: Performance Measurement

The solution must support calculation of operational prior-authorization KPIs.

### BR-06: Data Privacy

The project must use synthetic data only and must not contain protected health information.

## 3. Functional Requirements

### FR-01: Create an Authorization Request

The prototype must represent a prior-authorization request containing:

- Authorization ID
- Patient ID
- Ordering provider ID
- Payer ID
- Procedure code
- Procedure description
- Diagnosis code
- Request date
- Urgency level
- Supporting-documentation status
- Authorization status

### FR-02: Validate Required Fields

The solution must detect missing or invalid required fields before a request is submitted.

### FR-03: Assign a Status

Every authorization request must have one valid status.

### FR-04: Record Status Changes

The solution must record when an authorization status changes.

### FR-05: Record the Payer Decision

The solution must record whether the payer:

- Approved the request
- Denied the request
- Requested additional information
- Had not yet reached a decision

### FR-06: Calculate Turnaround Time

The solution must calculate the elapsed time between request submission and the payer’s decision.

### FR-07: Identify Pending Requests

The solution must identify requests without a final payer decision.

### FR-08: Identify Overdue Requests

The solution must flag pending requests that exceed the applicable service-level target.

### FR-09: Analyze Outcomes

The solution must summarize authorization outcomes by payer, procedure, provider, urgency, and time period.

## 4. Data Requirements

The synthetic dataset must include information representing:

- Patients
- Providers
- Payers
- Insurance coverage
- Procedures
- Diagnoses
- Authorization requests
- Status-history events
- Payer decisions

The dataset must include both normal and problematic records, including:

- Complete submissions
- Incomplete submissions
- Approved requests
- Denied requests
- Requests for additional information
- Pending requests
- Overdue requests
- Requests requiring rework

## 5. FHIR-Aligned Requirements

The project will use selected HL7 FHIR R4 resources to demonstrate healthcare-data interoperability concepts.

The initial resource mapping will include:

| Project information | FHIR resource |
|---|---|
| Patient demographics | Patient |
| Ordering provider | Practitioner |
| Insurance information | Coverage |
| Requested clinical service | ServiceRequest |
| Authorization submission | Claim |
| Payer response | ClaimResponse |
| Workflow status and required action | Task |

The project is a FHIR-aligned educational prototype. It is not represented as a certified or production-conformant prior-authorization implementation.

## 6. Technical Requirements

The project will use:

- Visual Studio Code for development
- Git and GitHub for version control
- JSON for FHIR-aligned resource files
- Postman for REST API testing
- Python for validation and transformation
- MySQL for structured storage and analysis
- Markdown for technical documentation

All required project components must run on the developer’s MacBook Pro or use free browser-based tools.

## 7. KPI Requirements

The prototype must support calculation of:

| KPI | Definition |
|---|---|
| Approval rate | Approved requests divided by requests receiving a final decision |
| Denial rate | Denied requests divided by requests receiving a final decision |
| First-pass completeness rate | Complete initial submissions divided by all submitted requests |
| Rework rate | Requests requiring correction or additional information divided by submitted requests |
| Average turnaround time | Average elapsed time from submission to payer decision |
| Pending-request volume | Number of requests without a final decision |
| Average pending age | Average age of requests that remain unresolved |
| Overdue-request rate | Pending requests exceeding the target divided by all pending requests |

## 8. Nonfunctional Requirements

### NFR-01: Reproducibility

Another user must be able to follow the documentation and reproduce the analysis.

### NFR-02: Maintainability

Files, variables, tables, and fields must use consistent and descriptive names.

### NFR-03: Data Integrity

Identifiers and relationships must remain consistent across the synthetic datasets and FHIR-aligned resources.

### NFR-04: Usability

Documentation must be understandable to both technical and healthcare-operational audiences.

### NFR-05: Traceability

Business requirements, technical components, and final analytical outputs must be connected and documented.

## 9. Out of Scope

The initial prototype will not include:

- Real patient information
- Connectivity to a production EHR
- Connectivity to a production payer system
- Electronic prescribing
- Medical-necessity decision automation
- Automated denial appeals
- Production authentication or authorization
- HIPAA certification
- Complete implementation of every Da Vinci PAS requirement
- Deployment as a production healthcare application

## 10. Acceptance Criteria

The project will be considered complete when:

1. The current-state and future-state workflows are documented.
2. A synthetic prior-authorization dataset has been created.
3. Selected records have been represented as valid JSON.
4. FHIR-aligned resource relationships are documented.
5. API requests have been demonstrated in Postman.
6. Python validates and transforms the project data.
7. MySQL stores and analyzes authorization records.
8. Required KPIs have been calculated.
9. Project findings and recommendations are documented.
10. GitHub contains sufficient instructions to understand and reproduce the project.