# Project Charter

## Project Title

**Closed-Loop Specialty Referral Management: Healthcare SaaS Implementation and Analytics**

## Document Control

| Field | Value |
|---|---|
| Project type | Simulated healthcare SaaS implementation and analytics case study |
| Client | NorthStar Medical Group (fictional) |
| Project owner | Brandon McDermott |
| Version | 1.0 |
| Status | Approved for portfolio development |
| Data classification | Fully synthetic; no PHI or real patient information |

## 1. Executive Summary

NorthStar Medical Group is a fictional multi-site primary-care organization that refers patients to internal and external specialists. Its current referral process relies on disconnected EHR work queues, telephone calls, faxes, spreadsheets, and manual follow-up. Leadership cannot reliably determine whether referred patients were contacted, scheduled, seen, or returned to the referring clinician with a consultation report.

This project will design and demonstrate a simulated implementation of a closed-loop referral-management SaaS solution. The solution will standardize the referral workflow, validate required information, assign work to operational queues, track outreach and appointments, identify overdue referrals, receive specialist reports, and provide operational and executive analytics.

The case study will cover workflow discovery, requirements definition, solution configuration, relational data modeling, synthetic data migration, data-quality validation, FHIR R4 resource mapping, API testing, Tableau reporting, user-acceptance testing, training, and go-live planning.

## 2. Business Problem

NorthStar lacks a consistent, measurable process for managing specialty referrals from order through clinical closure. Current-state problems include:

- Incomplete clinical or administrative referral information
- Inconsistent ownership after a referral is submitted
- Repeated manual work across practices and the centralized referral team
- Delays reaching patients and scheduling specialist appointments
- Limited visibility into cancellations, no-shows, and abandoned referrals
- Completed visits for which the specialist report is not returned
- No standardized escalation rules for urgent or aging referrals
- Inconsistent status definitions across sites
- No authoritative operational work queue
- Limited reporting by practice, specialty, payer, provider, or workflow stage

These failures can delay care, create avoidable administrative work, reduce continuity between clinicians, and prevent leadership from measuring referral performance.

## 3. Project Purpose

Design a portfolio-ready implementation that demonstrates how a healthcare organization could use workflow standardization, structured data, interoperability, operational analytics, and implementation controls to improve referral visibility and support closed-loop care coordination.

## 4. Project Objectives

1. Document the current-state and future-state referral workflows.
2. Define business, functional, data, integration, reporting, security, and operational requirements.
3. Design a normalized MySQL data model for referral operations.
4. Generate a realistic but fully synthetic 12-month referral dataset.
5. Create a repeatable transformation and migration-validation process using Python and SQL.
6. Configure simulated referral statuses, work queues, service levels, escalation rules, user roles, and closure requirements.
7. Map core referral information to selected FHIR R4 resources.
8. Demonstrate representative API transactions and error handling in Postman.
9. Build a Tableau dashboard for executive monitoring and daily referral operations.
10. Develop UAT, training, go-live, rollback, and post-launch support materials.
11. Publish a transparent case study that distinguishes simulated findings from actual client results.

## 5. Client Profile and Operating Environment

NorthStar Medical Group is assumed to have:

- Six primary-care sites
- Approximately 35 referring clinicians
- A centralized referral-coordination team
- Relationships with approximately 75 specialist clinicians or organizations
- Ten high-volume specialty categories
- Approximately 2,500 referrals during the simulated 12-month period
- A mix of commercial, Medicare, Medicaid, and self-pay patients
- An existing EHR capable of exporting structured referral data
- Continued use of telephone and fax for some external specialist communication

These values are scenario assumptions for portfolio development, not claims about a real organization.

## 6. Stakeholders

| Stakeholder | Primary interest | Project responsibility |
|---|---|---|
| Executive sponsor | Access, care continuity, operational performance | Approves scope and success criteria |
| Director of ambulatory operations | Consistent referral operations | Business process owner |
| Medical director | Clinical appropriateness and patient safety | Clinical governance and escalation review |
| Referral coordinators | Efficient queues and clear ownership | Primary end users and UAT participants |
| Practice managers | Site-level performance and staffing | Local workflow validation |
| Referring clinicians | Timely scheduling and returned consult reports | Clinical workflow validation |
| Health IT/EHR team | Interfaces, identity matching, system reliability | Technical integration owner |
| Data and analytics team | Metric definitions and trusted reporting | Data validation and dashboard owner |
| Compliance/privacy representative | Minimum-necessary access and auditability | Security and privacy review |
| Implementation lead | Scope, configuration, testing, training, go-live | Delivery accountability |

## 7. In Scope

- Referral intake from a structured EHR extract or representative FHIR payload
- Patient, provider, organization, payer, location, and specialty reference data
- Required-field and documentation validation
- Referral prioritization and assignment
- Patient outreach-attempt tracking
- Appointment scheduling and outcome tracking
- Referral status history and aging
- Overdue and escalation rules
- Specialist-report receipt tracking
- Defined referral closure criteria
- MySQL database and analytical views
- Python data generation, transformation, and migration reconciliation
- Selected FHIR R4 mappings and Postman API tests
- Tableau executive dashboard and operational work queue
- Requirements traceability, configuration documentation, UAT, training, and go-live planning

## 8. Out of Scope

- Production deployment to a real EHR or healthcare organization
- Real patient data, PHI, or live credentials
- Clinical decision-making or automated determination of referral necessity
- Insurance authorization adjudication; Project 3 covers prior authorization
- Provider contracting or network adequacy analysis
- Claims submission or payment processing
- Patient-facing mobile application
- Production-grade identity management, single sign-on, or cybersecurity certification
- Complete implementation of every FHIR resource or interoperability profile
- Live SMS, fax, email, or telephony integrations
- Demonstrating causal improvement in patient outcomes

## 9. Proposed Future-State Workflow

1. The EHR transmits or exports a new referral order.
2. The platform validates required patient, clinical, payer, provider, and specialty information.
3. Incomplete referrals enter a documentation-resolution queue.
4. Complete referrals are prioritized and assigned to the appropriate referral coordinator.
5. Outreach attempts and outcomes are recorded.
6. Scheduled appointments are tracked through completion, cancellation, or no-show.
7. Overdue or high-priority referrals are escalated according to defined rules.
8. After the specialist visit, the platform tracks receipt of the consultation report.
9. The referral closes only after the required completion and communication criteria are satisfied or an approved closure reason is documented.
10. Operational and executive dashboards display performance, backlog, aging, leakage, and exceptions.

## 10. Initial Status Model

| Status | Definition |
|---|---|
| Received | Referral entered the platform |
| Needs Information | Required information or documentation is missing |
| Ready for Outreach | Referral passed intake validation |
| Outreach in Progress | Patient contact attempts are underway |
| Scheduled | Specialist appointment has been scheduled |
| Completed—Report Pending | Specialist encounter occurred but report has not been received |
| Closed—Completed | Appointment completed and required report received |
| Closed—Not Completed | Referral ended with an approved non-completion reason |
| Cancelled | Referral was formally withdrawn or entered in error |

## 11. Preliminary KPI Definitions

| KPI | Preliminary definition |
|---|---|
| Intake completeness rate | Referrals passing initial validation / referrals received |
| Scheduling conversion rate | Referrals scheduled / referrals eligible for scheduling |
| Appointment completion rate | Completed appointments / scheduled appointments with an elapsed appointment date |
| Closed-loop rate | Qualifying referrals with a completed visit and received consult report / qualifying referrals |
| Median days to schedule | Median calendar days from referral receipt to first scheduled appointment |
| Median days to completion | Median calendar days from referral receipt to completed specialist encounter |
| Report turnaround time | Median calendar days from completed encounter to consult-report receipt |
| No-show rate | No-show appointments / elapsed scheduled appointments |
| Overdue open referrals | Open referrals exceeding the applicable stage or priority service level |
| Referral leakage rate | Referrals closed without completion / referrals reaching the outreach stage |

Final numerator, denominator, exclusion, date, and null-handling rules will be documented before dashboard development.

## 12. Preliminary Success Criteria

The project will be considered complete when:

- Current-state and future-state workflows are documented.
- Requirements are traceable to configuration, tests, or reporting outputs.
- The database loads the complete synthetic dataset without unresolved integrity failures.
- Record counts and critical fields reconcile between source and target datasets.
- Core KPI queries have documented calculation logic and validation results.
- Representative FHIR resources pass the defined positive API tests.
- Negative API and data-validation tests produce documented expected failures.
- All critical UAT scenarios pass or have a documented disposition.
- The Tableau dashboard supports executive monitoring and operational follow-up.
- The go-live runbook includes readiness, rollback, support, and escalation steps.
- The public README clearly identifies all data and results as synthetic.

## 13. Illustrative Improvement Targets

The following are scenario targets used to guide solution design; they are not measured outcomes or predictions:

- At least 95% of new referrals pass required-field validation or route to a defined exception queue.
- At least 90% of open referrals have an assigned owner.
- At least 90% of urgent overdue referrals appear in the escalation queue.
- At least 85% of completed specialist visits have a recorded report outcome.
- Reduce the simulated median referral-to-scheduling interval by 20% after workflow redesign.
- Increase the simulated closed-loop rate by 15 percentage points after workflow redesign.

Any before-and-after analysis will be explicitly labeled as scenario modeling based on synthetic data and assumptions. It will not support causal claims about real-world effectiveness.

## 14. Constraints

- The project must be executable on a Mac using accessible or free tools.
- No proprietary EHR environment or production SaaS platform is available.
- All clinical and operational data must be synthetic.
- The first portfolio-ready release should be achievable within approximately three weeks.
- The solution will demonstrate implementation methods, not production scalability or regulatory certification.
- Tableau Public content must not contain confidential information.

## 15. Assumptions

- A structured EHR export is available for initial migration.
- Patient and provider identifiers are stable within the simulated source system.
- Referral coordinators will use standardized statuses and disposition reasons.
- Specialist appointment and report information may arrive through mixed electronic and manual channels.
- Leadership accepts the preliminary KPI framework subject to validation.
- FHIR tests represent integration behavior and do not constitute a production interface.

## 16. Risks and Initial Mitigations

| Risk | Impact | Initial mitigation |
|---|---|---|
| Scope expands into a full referral product | Delayed completion | Maintain explicit MVP and backlog |
| Synthetic data appear unrealistically clean | Weak analytical credibility | Introduce documented missing, duplicate, late, and inconsistent records |
| Metrics use ambiguous denominators | Misleading results | Create a metric specification before visualization |
| Project duplicates prior-authorization work | Reduced portfolio value | Keep authorization adjudication out of scope and emphasize implementation lifecycle |
| FHIR work becomes overly technical | Core implementation artifacts remain unfinished | Limit resources and transactions to the referral workflow |
| Dashboard becomes decorative rather than operational | Limited hiring relevance | Build actionable queues and aging logic before visual styling |
| Simulated results are mistaken for client outcomes | Credibility risk | Label synthetic data and scenario targets throughout the repository |

## 17. Major Deliverables

1. Project charter and stakeholder analysis
2. Current-state and future-state workflow diagrams
3. Business, functional, technical, data, reporting, and security requirements
4. Requirements traceability matrix
5. Data dictionary and entity-relationship diagram
6. Synthetic source dataset
7. MySQL schema, validation checks, KPI queries, and operational views
8. Python transformation and migration-validation scripts
9. SaaS configuration workbook
10. Source-to-target mapping workbook
11. FHIR resource mapping and Postman test collection
12. Tableau dashboard and operational work queue
13. UAT plan, cases, results, and defect log
14. Training plan and go-live runbook
15. Portfolio README, screenshots, and demonstration script

## 18. Milestones

| Milestone | Target project day |
|---|---:|
| Charter, stakeholders, and scope approved | 1 |
| Current-state and future-state workflows completed | 3 |
| Requirements and traceability baseline completed | 5 |
| Database schema and synthetic data completed | 8 |
| Migration and data-quality validation completed | 10 |
| Configuration and FHIR/API testing completed | 13 |
| SQL analytics and Tableau dashboard completed | 16 |
| UAT, training, and go-live documentation completed | 19 |
| README, demonstration, QA, and publication completed | 21 |

## 19. Governance and Change Control

- Scope changes will be recorded in the project decision log.
- New features that do not support the stated objectives will enter a future-enhancement backlog.
- KPI changes require an updated metric definition and validation query.
- Database or status-model changes require corresponding updates to the data dictionary, mapping, requirements traceability, and affected test cases.
- Critical defects must be resolved or formally accepted before the project is represented as implementation-ready.

## 20. Evidence and Standards Basis

The project is conceptually grounded in:

- AHRQ's definition of care coordination as deliberately organizing care activities and sharing information among participants to support safer and more effective care.
- The federal Closing the Referral Loop measure, which treats receipt of a report from the clinician receiving the referral as central to successful closure.
- ONC SAFER guidance addressing reliable clinician communication, referrals, and EHR-related follow-up processes.
- HL7 FHIR as a standard for healthcare data exchange, using a limited set of workflow-relevant R4 resources.

Detailed references and access dates will be maintained in the final README.

## 21. Approval

This charter authorizes development of the simulated Project 4 MVP under the scope, assumptions, constraints, and transparency rules stated above.

| Role | Approval status |
|---|---|
| Portfolio owner / implementation lead | Approved |
| Fictional executive sponsor | Assumed approved for case-study purposes |

