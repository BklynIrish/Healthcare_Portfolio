"""
Generate FHIR R4 transaction bundles from Project 3 CSV data.

The script creates:
1. One approved prior-authorization bundle
2. One denied prior-authorization bundle

All data is synthetic.

Author: Brandon McDermott
"""

import csv
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRECTORY = PROJECT_ROOT / "data" / "source"
FHIR_DIRECTORY = PROJECT_ROOT / "data" / "fhir"

FHIR_DIRECTORY.mkdir(parents=True, exist_ok=True)

FHIR_BASE_URL = "https://northstar.example.org/fhir"


def load_csv(filename):
    """Load a CSV file into a list of dictionaries."""

    file_path = SOURCE_DIRECTORY / filename

    with file_path.open(
        mode="r",
        newline="",
        encoding="utf-8"
    ) as csv_file:
        return list(csv.DictReader(csv_file))


def index_by(rows, key):
    """Create a dictionary indexed by a specified field."""

    return {
        row[key]: row
        for row in rows
    }


def fhir_datetime(value):
    """Convert a MySQL datetime string to a FHIR datetime."""

    if not value:
        return None

    return value.replace(" ", "T") + "Z"


def add_resource_entry(resource):
    """Create a FHIR transaction Bundle entry."""

    resource_type = resource["resourceType"]
    resource_id = resource["id"]

    return {
        "fullUrl": (
            f"{FHIR_BASE_URL}/{resource_type}/{resource_id}"
        ),
        "resource": resource,
        "request": {
            "method": "PUT",
            "url": f"{resource_type}/{resource_id}"
        }
    }


def service_request_status(local_status):
    """Map the project status to ServiceRequest.status."""

    mapping = {
        "Draft": "draft",
        "Submitted": "active",
        "Additional Information Required": "on-hold",
        "In Review": "active",
        "Approved": "completed",
        "Denied": "completed",
        "Cancelled": "revoked"
    }

    return mapping[local_status]


def task_status(local_status):
    """Map the project status to Task.status."""

    mapping = {
        "Draft": "draft",
        "Submitted": "requested",
        "Additional Information Required": "on-hold",
        "In Review": "in-progress",
        "Approved": "completed",
        "Denied": "completed",
        "Cancelled": "cancelled"
    }

    return mapping[local_status]


# ------------------------------------------------------------
# Load source data
# ------------------------------------------------------------

patients = load_csv("patients.csv")
providers = load_csv("providers.csv")
payers = load_csv("payers.csv")
coverages = load_csv("coverages.csv")
procedures = load_csv("procedures.csv")
diagnoses = load_csv("diagnoses.csv")
authorizations = load_csv("authorization_requests.csv")
status_history = load_csv("status_history.csv")

patients_by_id = index_by(patients, "patient_id")
providers_by_id = index_by(providers, "provider_id")
payers_by_id = index_by(payers, "payer_id")
coverages_by_id = index_by(coverages, "coverage_id")
procedures_by_id = index_by(procedures, "procedure_id")
diagnoses_by_id = index_by(diagnoses, "diagnosis_id")


def create_bundle(authorization):
    """Create a connected FHIR transaction Bundle."""

    authorization_id = authorization["authorization_id"]

    patient = patients_by_id[authorization["patient_id"]]
    provider = providers_by_id[authorization["provider_id"]]
    coverage = coverages_by_id[authorization["coverage_id"]]
    payer = payers_by_id[coverage["payer_id"]]
    procedure = procedures_by_id[authorization["procedure_id"]]
    diagnosis = diagnoses_by_id[authorization["diagnosis_id"]]

    related_events = [
        event
        for event in status_history
        if event["authorization_id"] == authorization_id
    ]

    latest_event = max(
        related_events,
        key=lambda event: event["status_at"]
    )

    # --------------------------------------------------------
    # Patient
    # --------------------------------------------------------

    patient_resource = {
        "resourceType": "Patient",
        "id": patient["patient_id"],
        "identifier": [
            {
                "system": (
                    "https://northstar.example.org/"
                    "identifier/medical-record-number"
                ),
                "value": patient["medical_record_number"]
            }
        ],
        "name": [
            {
                "family": patient["last_name"],
                "given": [patient["first_name"]]
            }
        ],
        "gender": patient["administrative_sex"],
        "birthDate": patient["birth_date"],
        "address": [
            {
                "postalCode": patient["postal_code"]
            }
        ]
    }

    # --------------------------------------------------------
    # Practitioner
    # --------------------------------------------------------

    practitioner_resource = {
        "resourceType": "Practitioner",
        "id": provider["provider_id"],
        "active": provider["active"] == "1",
        "identifier": [
            {
                "system": "http://hl7.org/fhir/sid/us-npi",
                "value": provider["npi"]
            }
        ],
        "name": [
            {
                "text": provider["provider_name"]
            }
        ],
        "qualification": [
            {
                "code": {
                    "text": provider["specialty"]
                }
            }
        ]
    }

    # --------------------------------------------------------
    # Payer Organization
    # --------------------------------------------------------

    organization_resource = {
        "resourceType": "Organization",
        "id": payer["payer_id"],
        "active": payer["active"] == "1",
        "type": [
            {
                "text": payer["plan_type"]
            }
        ],
        "name": payer["payer_name"]
    }

    # --------------------------------------------------------
    # Coverage
    # --------------------------------------------------------

    coverage_resource = {
        "resourceType": "Coverage",
        "id": coverage["coverage_id"],
        "status": coverage["coverage_status"],
        "identifier": [
            {
                "system": (
                    "https://northstar.example.org/"
                    "identifier/member-id"
                ),
                "value": coverage["member_id"]
            }
        ],
        "beneficiary": {
            "reference": f"Patient/{patient['patient_id']}"
        },
        "payor": [
            {
                "reference": f"Organization/{payer['payer_id']}"
            }
        ],
        "period": {
            "start": coverage["coverage_start_date"],
            "end": coverage["coverage_end_date"]
        },
        "class": [
            {
                "type": {
                    "coding": [
                        {
                            "system": (
                                "http://terminology.hl7.org/"
                                "CodeSystem/coverage-class"
                            ),
                            "code": "group",
                            "display": "Group"
                        }
                    ]
                },
                "value": coverage["group_number"]
            }
        ]
    }

    # --------------------------------------------------------
    # ServiceRequest
    # --------------------------------------------------------

    service_request_resource = {
        "resourceType": "ServiceRequest",
        "id": authorization_id,
        "status": service_request_status(
            authorization["current_status"]
        ),
        "intent": "order",
        "priority": (
            "urgent"
            if authorization["urgency"] == "expedited"
            else "routine"
        ),
        "code": {
            "coding": [
                {
                    "system": "http://www.ama-assn.org/go/cpt",
                    "code": procedure["procedure_code"],
                    "display": procedure["procedure_description"]
                }
            ],
            "text": procedure["procedure_description"]
        },
        "subject": {
            "reference": f"Patient/{patient['patient_id']}"
        },
        "requester": {
            "reference": (
                f"Practitioner/{provider['provider_id']}"
            )
        },
        "authoredOn": fhir_datetime(
            authorization["created_at"]
        ),
        "reasonCode": [
            {
                "coding": [
                    {
                        "system": (
                            "http://hl7.org/fhir/sid/icd-10-cm"
                        ),
                        "code": diagnosis["diagnosis_code"],
                        "display": (
                            diagnosis["diagnosis_description"]
                        )
                    }
                ]
            }
        ],
        "insurance": [
            {
                "reference": (
                    f"Coverage/{coverage['coverage_id']}"
                )
            }
        ]
    }

    # --------------------------------------------------------
    # Claim: prior-authorization submission
    # --------------------------------------------------------

    claim_resource = {
        "resourceType": "Claim",
        "id": authorization_id,
        "identifier": [
            {
                "system": (
                    "https://northstar.example.org/"
                    "identifier/prior-authorization"
                ),
                "value": authorization_id
            }
        ],
        "status": (
            "cancelled"
            if authorization["current_status"] == "Cancelled"
            else "active"
        ),
        "type": {
            "coding": [
                {
                    "system": (
                        "http://terminology.hl7.org/"
                        "CodeSystem/claim-type"
                    ),
                    "code": "institutional",
                    "display": "Institutional"
                }
            ]
        },
        "use": "preauthorization",
        "patient": {
            "reference": f"Patient/{patient['patient_id']}"
        },
        "created": fhir_datetime(
            authorization["submitted_at"]
            or authorization["created_at"]
        ),
        "insurer": {
            "reference": f"Organization/{payer['payer_id']}"
        },
        "provider": {
            "reference": (
                f"Practitioner/{provider['provider_id']}"
            )
        },
        "priority": {
            "coding": [
                {
                    "system": (
                        "http://terminology.hl7.org/"
                        "CodeSystem/processpriority"
                    ),
                    "code": (
                        "stat"
                        if authorization["urgency"] == "expedited"
                        else "normal"
                    )
                }
            ]
        },
        "diagnosis": [
            {
                "sequence": 1,
                "diagnosisCodeableConcept": {
                    "coding": [
                        {
                            "system": (
                                "http://hl7.org/fhir/"
                                "sid/icd-10-cm"
                            ),
                            "code": diagnosis["diagnosis_code"],
                            "display": (
                                diagnosis[
                                    "diagnosis_description"
                                ]
                            )
                        }
                    ]
                }
            }
        ],
        "insurance": [
            {
                "sequence": 1,
                "focal": True,
                "coverage": {
                    "reference": (
                        f"Coverage/{coverage['coverage_id']}"
                    )
                }
            }
        ],
        "item": [
            {
                "sequence": 1,
                "diagnosisSequence": [1],
                "productOrService": {
                    "coding": [
                        {
                            "system": (
                                "http://www.ama-assn.org/go/cpt"
                            ),
                            "code": procedure["procedure_code"],
                            "display": (
                                procedure["procedure_description"]
                            )
                        }
                    ]
                }
            }
        ]
    }

    # --------------------------------------------------------
    # ClaimResponse: payer decision
    # --------------------------------------------------------

    approved = authorization["current_status"] == "Approved"

    claim_response_resource = {
        "resourceType": "ClaimResponse",
        "id": f"RESP-{authorization_id}",
        "status": "active",
        "type": claim_resource["type"],
        "use": "preauthorization",
        "patient": {
            "reference": f"Patient/{patient['patient_id']}"
        },
        "created": fhir_datetime(
            authorization["decision_at"]
        ),
        "insurer": {
            "reference": f"Organization/{payer['payer_id']}"
        },
        "request": {
            "reference": f"Claim/{authorization_id}"
        },
        "outcome": "complete",
        "disposition": (
            "Prior authorization approved"
            if approved
            else (
                "Prior authorization denied: "
                + authorization["denial_reason"]
            )
        ),
        "item": [
            {
                "itemSequence": 1,
                "adjudication": [
                    {
                        "category": {
                            "coding": [
                                {
                                    "system": (
                                        "https://northstar.example.org/"
                                        "fhir/CodeSystem/"
                                        "prior-auth-adjudication"
                                    ),
                                    "code": "authorization-outcome",
                                    "display": (
                                        "Prior Authorization Outcome"
                                    )
                                }
                            ]
                        },
                        "reason": {
                            "text": (
                                "Approved"
                                if approved
                                else authorization["denial_reason"]
                            )
                        }
                    }
                ]
            }
        ]
    }

    if approved:
        claim_response_resource["preAuthRef"] = (
            authorization["authorization_number"]
        )

    # --------------------------------------------------------
    # Task: operational workflow
    # --------------------------------------------------------

    task_resource = {
        "resourceType": "Task",
        "id": f"TASK-{authorization_id}",
        "status": task_status(
            authorization["current_status"]
        ),
        "businessStatus": {
            "text": authorization["current_status"]
        },
        "intent": "order",
        "code": {
            "text": "Prior authorization management"
        },
        "description": (
            f"Manage prior authorization {authorization_id}"
        ),
        "focus": {
            "reference": f"Claim/{authorization_id}"
        },
        "for": {
            "reference": f"Patient/{patient['patient_id']}"
        },
        "authoredOn": fhir_datetime(
            authorization["created_at"]
        ),
        "lastModified": fhir_datetime(
            latest_event["status_at"]
        ),
        "requester": {
            "reference": (
                f"Practitioner/{provider['provider_id']}"
            )
        },
        "owner": {
            "reference": f"Organization/{payer['payer_id']}"
        },
        "note": [
            {
                "text": (
                    f"Current operational status: "
                    f"{authorization['current_status']}"
                )
            }
        ]
    }

    resources = [
        patient_resource,
        practitioner_resource,
        organization_resource,
        coverage_resource,
        service_request_resource,
        claim_resource,
        claim_response_resource,
        task_resource
    ]

    return {
        "resourceType": "Bundle",
        "id": f"BUNDLE-{authorization_id}",
        "type": "transaction",
        "entry": [
            add_resource_entry(resource)
            for resource in resources
        ]
    }


def save_bundle(filename, bundle):
    """Write a formatted FHIR Bundle JSON file."""

    output_path = FHIR_DIRECTORY / filename

    with output_path.open(
        mode="w",
        encoding="utf-8"
    ) as json_file:
        json.dump(
            bundle,
            json_file,
            indent=2,
            ensure_ascii=False
        )

    print(
        f"Created {filename}: "
        f"{len(bundle['entry'])} resources"
    )


approved_authorization = next(
    authorization
    for authorization in authorizations
    if authorization["current_status"] == "Approved"
)

denied_authorization = next(
    authorization
    for authorization in authorizations
    if authorization["current_status"] == "Denied"
)

approved_bundle = create_bundle(approved_authorization)
denied_bundle = create_bundle(denied_authorization)

save_bundle(
    "approved_authorization_bundle.json",
    approved_bundle
)

save_bundle(
    "denied_authorization_bundle.json",
    denied_bundle
)

print()
print(
    "Approved authorization: "
    f"{approved_authorization['authorization_id']}"
)
print(
    "Denied authorization: "
    f"{denied_authorization['authorization_id']}"
)
print("FHIR bundle generation completed successfully.")