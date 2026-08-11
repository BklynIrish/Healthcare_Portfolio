# Project Charter

**Author:** Brandon McDermott  
**Organization:** Northstar Health Network — Synthetic Case Study  
**Project Start Date:** August 2026  
**Status:** In Development

## Project Title

Healthcare Prior Authorization Workflow and FHIR API Integration

## Project Type

Healthcare interoperability, workflow analysis, API integration, and operational analytics portfolio project.

## Business Problem
Northstar Health Network, as other healthcare organizations do, relies on fragmented and partially manual processes to submit, monitor, and resolve prior-authorization requests. Incomplete submissions, delayed payer responses, limited status visibility, and inconsistent handoffs contribute to administrative rework and delays in patient care.

## Project Objective

Design and prototype a FHIR-aligned prior-authorization workflow that improves submission completeness, status visibility, operational tracking, and performance measurement.

## Primary Stakeholders

- Patients
- Ordering providers
- Clinical staff
- Prior-authorization specialists
- Revenue-cycle personnel
- Payers
- Healthcare IT and integration teams
- Operational leadership

## Project Scope

The project will:

1. Document the current-state prior-authorization workflow.
2. Identify workflow delays, failure points, and information gaps.
3. Design an improved future-state workflow.
4. Create synthetic healthcare and authorization data.
5. Represent selected data using FHIR-aligned JSON resources.
6. Test REST API requests using Postman.
7. Validate and transform data using Python.
8. Store operational data in MySQL.
9. Calculate prior-authorization performance metrics.
10. Present findings and implementation recommendations.

## Initial KPIs

- Authorization turnaround time
- Approval rate
- Denial rate
- First-pass submission completeness
- Rework rate
- Pending authorization volume
- Average age of pending requests
- Requests exceeding the service-level target

## Technology

- Visual Studio Code
- Git and GitHub
- Python
- Postman
- JSON
- REST APIs
- HL7 FHIR R4
- MySQL and MySQL Workbench
- Tableau, if appropriate

## Data Disclaimer

All patients, providers, payers, procedures, authorization requests, and outcomes used in this project are synthetic. The project contains no protected health information.

## Implementation Disclaimer

This project is an educational, FHIR-aligned prototype. It is not represented as a production implementation or a fully conformant implementation of the HL7 Da Vinci Prior Authorization Support Implementation Guide.