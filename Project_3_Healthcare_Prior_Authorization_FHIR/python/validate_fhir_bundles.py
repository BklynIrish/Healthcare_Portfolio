"""
Validate the generated FHIR R4 transaction bundles.

This script performs structural and reference-integrity checks.
It does not replace validation by a dedicated FHIR server.

Author: Brandon McDermott
"""

import json
import sys
from collections import Counter
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FHIR_DIRECTORY = PROJECT_ROOT / "data" / "fhir"

BUNDLE_FILENAMES = [
    "approved_authorization_bundle.json",
    "denied_authorization_bundle.json"
]

EXPECTED_RESOURCE_TYPES = {
    "Patient",
    "Practitioner",
    "Organization",
    "Coverage",
    "ServiceRequest",
    "Claim",
    "ClaimResponse",
    "Task"
}


def load_json(filename):
    """Load and parse a JSON file."""

    file_path = FHIR_DIRECTORY / filename

    if not file_path.exists():
        raise FileNotFoundError(
            f"Missing FHIR file: {file_path}"
        )

    with file_path.open(
        mode="r",
        encoding="utf-8"
    ) as json_file:
        return json.load(json_file)


def collect_references(value):
    """Recursively collect FHIR reference values."""

    references = []

    if isinstance(value, dict):
        reference = value.get("reference")

        if isinstance(reference, str):
            references.append(reference)

        for nested_value in value.values():
            references.extend(
                collect_references(nested_value)
            )

    elif isinstance(value, list):
        for item in value:
            references.extend(
                collect_references(item)
            )

    return references


def validate_bundle(filename, bundle):
    """Run structural checks on one Bundle."""

    errors = []

    if bundle.get("resourceType") != "Bundle":
        errors.append("Top-level resourceType must be Bundle.")

    if bundle.get("type") != "transaction":
        errors.append("Bundle.type must be transaction.")

    entries = bundle.get("entry", [])

    if len(entries) != 8:
        errors.append(
            f"Bundle contains {len(entries)} entries; expected 8."
        )

    resources = [
        entry.get("resource", {})
        for entry in entries
    ]

    resource_types = [
        resource.get("resourceType")
        for resource in resources
    ]

    resource_type_counts = Counter(resource_types)

    if set(resource_types) != EXPECTED_RESOURCE_TYPES:
        errors.append(
            "Bundle resource types do not match the expected set."
        )

    for resource_type in EXPECTED_RESOURCE_TYPES:
        if resource_type_counts[resource_type] != 1:
            errors.append(
                f"Expected one {resource_type}; found "
                f"{resource_type_counts[resource_type]}."
            )

    available_references = set()

    for resource in resources:
        resource_type = resource.get("resourceType")
        resource_id = resource.get("id")

        if not resource_type:
            errors.append(
                "A resource is missing resourceType."
            )

        if not resource_id:
            errors.append(
                f"{resource_type or 'Unknown resource'} "
                f"is missing id."
            )

        if resource_type and resource_id:
            available_references.add(
                f"{resource_type}/{resource_id}"
            )

    for entry in entries:
        resource = entry.get("resource", {})
        resource_type = resource.get("resourceType")
        resource_id = resource.get("id")

        request = entry.get("request", {})

        if request.get("method") != "PUT":
            errors.append(
                f"{resource_type}/{resource_id} does not "
                f"use PUT in Bundle.entry.request."
            )

        expected_url = f"{resource_type}/{resource_id}"

        if request.get("url") != expected_url:
            errors.append(
                f"{resource_type}/{resource_id} has an "
                f"incorrect transaction URL."
            )

    all_references = []

    for resource in resources:
        all_references.extend(
            collect_references(resource)
        )

    for reference in all_references:
        if (
            reference.startswith("http://")
            or reference.startswith("https://")
            or reference.startswith("urn:")
            or reference.startswith("#")
        ):
            continue

        if reference not in available_references:
            errors.append(
                f"Unresolved internal reference: {reference}"
            )

    resources_by_type = {
        resource["resourceType"]: resource
        for resource in resources
        if resource.get("resourceType")
    }

    service_request = resources_by_type.get(
        "ServiceRequest",
        {}
    )

    if service_request.get("intent") != "order":
        errors.append(
            "ServiceRequest.intent must equal order."
        )

    claim = resources_by_type.get("Claim", {})

    if claim.get("use") != "preauthorization":
        errors.append(
            "Claim.use must equal preauthorization."
        )

    if not claim.get("insurance"):
        errors.append(
            "Claim must contain insurance information."
        )

    claim_response = resources_by_type.get(
        "ClaimResponse",
        {}
    )

    if claim_response.get("use") != "preauthorization":
        errors.append(
            "ClaimResponse.use must equal preauthorization."
        )

    if claim_response.get("outcome") != "complete":
        errors.append(
            "ClaimResponse.outcome must equal complete."
        )

    task = resources_by_type.get("Task", {})

    if task.get("intent") != "order":
        errors.append("Task.intent must equal order.")

    if filename.startswith("approved"):
        if not claim_response.get("preAuthRef"):
            errors.append(
                "Approved ClaimResponse is missing preAuthRef."
            )

        if (
            "approved"
            not in claim_response.get(
                "disposition",
                ""
            ).lower()
        ):
            errors.append(
                "Approved ClaimResponse disposition is incorrect."
            )

    if filename.startswith("denied"):
        if claim_response.get("preAuthRef"):
            errors.append(
                "Denied ClaimResponse must not contain preAuthRef."
            )

        if (
            "denied"
            not in claim_response.get(
                "disposition",
                ""
            ).lower()
        ):
            errors.append(
                "Denied ClaimResponse disposition is incorrect."
            )

    return errors, resource_type_counts, len(all_references)


def main():
    """Validate every generated FHIR Bundle."""

    total_errors = 0

    print()
    print("FHIR Bundle Validation")
    print("----------------------")

    for filename in BUNDLE_FILENAMES:
        try:
            bundle = load_json(filename)
        except (FileNotFoundError, json.JSONDecodeError) as error:
            print(f"\n{filename}: FAILED")
            print(f"- {error}")
            total_errors += 1
            continue

        errors, resource_counts, reference_count = (
            validate_bundle(filename, bundle)
        )

        print(f"\n{filename}")
        print(f"Entries:    {sum(resource_counts.values())}")
        print(f"References: {reference_count}")

        if errors:
            print(f"Result: FAILED — {len(errors)} error(s)")

            for error in errors:
                print(f"- {error}")

            total_errors += len(errors)
        else:
            print("Result: PASSED")

    print()

    if total_errors:
        print(
            f"FHIR VALIDATION FAILED: "
            f"{total_errors} error(s)"
        )
        sys.exit(1)

    print("FHIR VALIDATION PASSED")
    print(
        "Both bundles passed structural and "
        "reference-integrity checks."
    )


if __name__ == "__main__":
    main()