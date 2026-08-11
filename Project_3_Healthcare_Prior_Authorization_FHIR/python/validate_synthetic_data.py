"""
Validate the synthetic prior-authorization CSV datasets.

Author: Brandon McDermott
"""

import csv
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIRECTORY = PROJECT_ROOT / "data" / "source"

errors = []


def load_csv(filename):
    """Load a CSV file as a list of dictionaries."""

    file_path = DATA_DIRECTORY / filename

    if not file_path.exists():
        errors.append(f"Missing file: {filename}")
        return []

    with file_path.open(
        mode="r",
        newline="",
        encoding="utf-8"
    ) as csv_file:
        return list(csv.DictReader(csv_file))


def check_unique(rows, column, dataset_name):
    """Confirm that a key column contains no blanks or duplicates."""

    values = [row[column] for row in rows]

    blank_count = sum(not value for value in values)

    if blank_count:
        errors.append(
            f"{dataset_name}.{column} contains "
            f"{blank_count} blank values."
        )

    duplicates = {
        value
        for value in values
        if value and values.count(value) > 1
    }

    if duplicates:
        errors.append(
            f"{dataset_name}.{column} contains duplicates: "
            f"{sorted(duplicates)}"
        )


def check_allowed_values(
    rows,
    column,
    allowed_values,
    dataset_name
):
    """Confirm values belong to an approved set."""

    invalid_values = {
        row[column]
        for row in rows
        if row[column] not in allowed_values
    }

    if invalid_values:
        errors.append(
            f"{dataset_name}.{column} contains invalid values: "
            f"{sorted(invalid_values)}"
        )


def parse_datetime(value):
    """Convert a populated CSV datetime value."""

    if not value:
        return None

    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


# ------------------------------------------------------------
# Load datasets
# ------------------------------------------------------------

patients = load_csv("patients.csv")
providers = load_csv("providers.csv")
payers = load_csv("payers.csv")
coverages = load_csv("coverages.csv")
procedures = load_csv("procedures.csv")
diagnoses = load_csv("diagnoses.csv")
authorizations = load_csv("authorization_requests.csv")
status_history = load_csv("status_history.csv")


# ------------------------------------------------------------
# Record-count checks
# ------------------------------------------------------------

expected_counts = {
    "patients": (patients, 50),
    "providers": (providers, 10),
    "payers": (payers, 5),
    "coverages": (coverages, 55),
    "procedures": (procedures, 10),
    "diagnoses": (diagnoses, 10),
    "authorization_requests": (authorizations, 200)
}

for dataset_name, dataset_details in expected_counts.items():
    rows, expected_count = dataset_details

    if len(rows) != expected_count:
        errors.append(
            f"{dataset_name} contains {len(rows)} records; "
            f"expected {expected_count}."
        )

if not status_history:
    errors.append("status_history contains no records.")


# ------------------------------------------------------------
# Primary-key checks
# ------------------------------------------------------------

check_unique(patients, "patient_id", "patients")
check_unique(providers, "provider_id", "providers")
check_unique(payers, "payer_id", "payers")
check_unique(coverages, "coverage_id", "coverages")
check_unique(procedures, "procedure_id", "procedures")
check_unique(diagnoses, "diagnosis_id", "diagnoses")
check_unique(
    authorizations,
    "authorization_id",
    "authorization_requests"
)
check_unique(
    status_history,
    "status_event_id",
    "status_history"
)


# ------------------------------------------------------------
# Allowed-value checks
# ------------------------------------------------------------

check_allowed_values(
    patients,
    "administrative_sex",
    {"female", "male", "other", "unknown"},
    "patients"
)

check_allowed_values(
    payers,
    "plan_type",
    {
        "HMO",
        "PPO",
        "EPO",
        "POS",
        "Medicaid",
        "Medicare Advantage"
    },
    "payers"
)

check_allowed_values(
    coverages,
    "coverage_status",
    {"active", "inactive", "cancelled", "pending"},
    "coverages"
)

authorization_statuses = {
    "Draft",
    "Submitted",
    "Additional Information Required",
    "In Review",
    "Approved",
    "Denied",
    "Cancelled"
}

check_allowed_values(
    authorizations,
    "urgency",
    {"standard", "expedited"},
    "authorization_requests"
)

check_allowed_values(
    authorizations,
    "initial_submission_complete",
    {"0", "1"},
    "authorization_requests"
)

check_allowed_values(
    authorizations,
    "documentation_status",
    {
        "complete",
        "incomplete",
        "not-required",
        "pending-review"
    },
    "authorization_requests"
)

check_allowed_values(
    authorizations,
    "current_status",
    authorization_statuses,
    "authorization_requests"
)

check_allowed_values(
    status_history,
    "status",
    authorization_statuses,
    "status_history"
)


# ------------------------------------------------------------
# Foreign-key checks
# ------------------------------------------------------------

patient_ids = {row["patient_id"] for row in patients}
provider_ids = {row["provider_id"] for row in providers}
payer_ids = {row["payer_id"] for row in payers}
coverage_ids = {row["coverage_id"] for row in coverages}
procedure_ids = {row["procedure_id"] for row in procedures}
diagnosis_ids = {row["diagnosis_id"] for row in diagnoses}
authorization_ids = {
    row["authorization_id"]
    for row in authorizations
}

for coverage in coverages:
    if coverage["patient_id"] not in patient_ids:
        errors.append(
            f'{coverage["coverage_id"]} references an invalid patient.'
        )

    if coverage["payer_id"] not in payer_ids:
        errors.append(
            f'{coverage["coverage_id"]} references an invalid payer.'
        )

coverage_by_id = {
    row["coverage_id"]: row
    for row in coverages
}

for authorization in authorizations:
    authorization_id = authorization["authorization_id"]

    foreign_keys = [
        (
            "patient_id",
            authorization["patient_id"],
            patient_ids
        ),
        (
            "provider_id",
            authorization["provider_id"],
            provider_ids
        ),
        (
            "coverage_id",
            authorization["coverage_id"],
            coverage_ids
        ),
        (
            "procedure_id",
            authorization["procedure_id"],
            procedure_ids
        ),
        (
            "diagnosis_id",
            authorization["diagnosis_id"],
            diagnosis_ids
        )
    ]

    for column, value, valid_values in foreign_keys:
        if value not in valid_values:
            errors.append(
                f"{authorization_id} has an invalid {column}: {value}"
            )

    coverage = coverage_by_id.get(
        authorization["coverage_id"]
    )

    if (
        coverage
        and coverage["patient_id"]
        != authorization["patient_id"]
    ):
        errors.append(
            f"{authorization_id} does not match the patient "
            f"assigned to its coverage."
        )

for event in status_history:
    if event["authorization_id"] not in authorization_ids:
        errors.append(
            f'{event["status_event_id"]} references an invalid '
            f'authorization.'
        )


# ------------------------------------------------------------
# Authorization business-rule checks
# ------------------------------------------------------------

for authorization in authorizations:
    authorization_id = authorization["authorization_id"]
    current_status = authorization["current_status"]

    created_at = parse_datetime(
        authorization["created_at"]
    )
    submitted_at = parse_datetime(
        authorization["submitted_at"]
    )
    decision_at = parse_datetime(
        authorization["decision_at"]
    )

    if submitted_at and submitted_at < created_at:
        errors.append(
            f"{authorization_id}: submitted_at occurs before created_at."
        )

    if decision_at and not submitted_at:
        errors.append(
            f"{authorization_id}: decision exists without submission."
        )

    if (
        decision_at
        and submitted_at
        and decision_at < submitted_at
    ):
        errors.append(
            f"{authorization_id}: decision occurs before submission."
        )

    if current_status in {"Approved", "Denied"} and not decision_at:
        errors.append(
            f"{authorization_id}: final status has no decision date."
        )

    if (
        current_status == "Approved"
        and not authorization["authorization_number"]
    ):
        errors.append(
            f"{authorization_id}: approved request has no "
            f"authorization number."
        )

    if (
        current_status == "Denied"
        and not authorization["denial_reason"]
    ):
        errors.append(
            f"{authorization_id}: denied request has no denial reason."
        )


# ------------------------------------------------------------
# Status-history checks
# ------------------------------------------------------------

history_by_authorization = defaultdict(list)

for event in status_history:
    history_by_authorization[
        event["authorization_id"]
    ].append(event)

for authorization in authorizations:
    authorization_id = authorization["authorization_id"]
    events = history_by_authorization.get(
        authorization_id,
        []
    )

    if not events:
        errors.append(
            f"{authorization_id} has no status-history events."
        )
        continue

    sorted_events = sorted(
        events,
        key=lambda event: parse_datetime(event["status_at"])
    )

    latest_status = sorted_events[-1]["status"]

    if latest_status != authorization["current_status"]:
        errors.append(
            f"{authorization_id}: latest history status "
            f"'{latest_status}' does not match current status "
            f"'{authorization['current_status']}'."
        )


# ------------------------------------------------------------
# Results
# ------------------------------------------------------------

print()
print("Synthetic Data Validation")
print("-------------------------")
print(f"Patients:               {len(patients)}")
print(f"Providers:              {len(providers)}")
print(f"Payers:                 {len(payers)}")
print(f"Coverages:              {len(coverages)}")
print(f"Procedures:             {len(procedures)}")
print(f"Diagnoses:              {len(diagnoses)}")
print(f"Authorization requests: {len(authorizations)}")
print(f"Status-history events:  {len(status_history)}")
print()

if errors:
    print(f"VALIDATION FAILED: {len(errors)} error(s)")
    print()

    for error in errors:
        print(f"- {error}")

    sys.exit(1)

print("VALIDATION PASSED")
print("All required data-quality checks completed successfully.")