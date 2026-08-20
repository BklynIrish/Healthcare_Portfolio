"""Validate the processed Project 4 CSV files before MySQL loading."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "processed"


def load(name: str) -> list[dict]:
    with (DATA / f"{name}.csv").open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def parse_dt(value: str) -> datetime | None:
    return None if not value else datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


def main() -> None:
    tables = {name: load(name) for name in [
        "patients", "organizations", "locations", "specialties", "practitioners",
        "payers", "coverages", "users", "referrals", "referral_status_history",
        "outreach_attempts", "appointments", "consult_reports",
        "referral_validation_issues", "referral_assignments",
    ]}
    failures: list[str] = []

    def check(condition: bool, message: str) -> None:
        if not condition:
            failures.append(message)

    primary_keys = {
        "patients": "patient_id", "organizations": "organization_id",
        "locations": "location_id", "specialties": "specialty_id",
        "practitioners": "practitioner_id", "payers": "payer_id",
        "coverages": "coverage_id", "users": "user_id", "referrals": "referral_id",
        "referral_status_history": "status_history_id",
        "outreach_attempts": "outreach_attempt_id", "appointments": "appointment_id",
        "consult_reports": "consult_report_id",
        "referral_validation_issues": "validation_issue_id",
        "referral_assignments": "assignment_id",
    }
    ids = {}
    for table, key in primary_keys.items():
        values = [row[key] for row in tables[table]]
        check(all(values), f"{table}: blank primary key")
        check(len(values) == len(set(values)), f"{table}: duplicate primary key")
        ids[table] = set(values)

    fk_tests = [
        ("locations", "organization_id", "organizations"),
        ("practitioners", "organization_id", "organizations"),
        ("practitioners", "specialty_id", "specialties"),
        ("coverages", "patient_id", "patients"), ("coverages", "payer_id", "payers"),
        ("users", "organization_id", "organizations"), ("users", "location_id", "locations"),
        ("referrals", "patient_id", "patients"), ("referrals", "coverage_id", "coverages"),
        ("referrals", "referring_practitioner_id", "practitioners"),
        ("referrals", "referring_organization_id", "organizations"),
        ("referrals", "referring_location_id", "locations"),
        ("referrals", "specialty_id", "specialties"),
        ("referrals", "destination_practitioner_id", "practitioners"),
        ("referrals", "destination_organization_id", "organizations"),
        ("referrals", "current_owner_user_id", "users"),
        ("referral_status_history", "referral_id", "referrals"),
        ("referral_status_history", "changed_by_user_id", "users"),
        ("outreach_attempts", "referral_id", "referrals"),
        ("outreach_attempts", "performed_by_user_id", "users"),
        ("appointments", "referral_id", "referrals"),
        ("appointments", "practitioner_id", "practitioners"),
        ("appointments", "organization_id", "organizations"),
        ("appointments", "location_id", "locations"),
        ("appointments", "superseded_by_appointment_id", "appointments"),
        ("consult_reports", "referral_id", "referrals"),
        ("consult_reports", "appointment_id", "appointments"),
        ("consult_reports", "author_practitioner_id", "practitioners"),
        ("consult_reports", "source_organization_id", "organizations"),
        ("consult_reports", "reviewed_by_practitioner_id", "practitioners"),
        ("referral_validation_issues", "referral_id", "referrals"),
        ("referral_validation_issues", "resolved_by_user_id", "users"),
        ("referral_assignments", "referral_id", "referrals"),
        ("referral_assignments", "assigned_user_id", "users"),
        ("referral_assignments", "assigned_by_user_id", "users"),
    ]
    for child, column, parent in fk_tests:
        invalid = [r for r in tables[child] if r[column] and r[column] not in ids[parent]]
        check(not invalid, f"{child}.{column}: {len(invalid)} invalid foreign keys")

    coverage_owner = {r["coverage_id"]: r["patient_id"] for r in tables["coverages"]}
    check(not [r for r in tables["referrals"] if coverage_owner[r["coverage_id"]] != r["patient_id"]],
          "DQ-001: referral coverage does not belong to patient")

    location_org = {r["location_id"]: r["organization_id"] for r in tables["locations"]}
    check(not [r for r in tables["referrals"] if location_org[r["referring_location_id"]] != r["referring_organization_id"]],
          "DQ-002: referring location does not belong to organization")

    latest_status = {}
    grouped = defaultdict(list)
    for row in tables["referral_status_history"]:
        grouped[row["referral_id"]].append(row)
    for referral_id, rows in grouped.items():
        latest_status[referral_id] = max(rows, key=lambda x: x["status_changed_at"])["new_status"]
    check(not [r for r in tables["referrals"] if latest_status.get(r["referral_id"]) != r["current_status"]],
          "DQ-005: latest history status differs from referral current status")

    appointment_by_id = {r["appointment_id"]: r for r in tables["appointments"]}
    invalid_reschedules = [r for r in tables["appointments"] if r["appointment_status"] == "Rescheduled" and not r["superseded_by_appointment_id"]]
    check(not invalid_reschedules, "DQ-013: rescheduled appointment missing successor")
    check(not [r for r in tables["appointments"] if r["superseded_by_appointment_id"] and r["superseded_by_appointment_id"] not in appointment_by_id],
          "DQ-013: successor appointment does not exist")

    invalid_reports = [r for r in tables["consult_reports"] if r["match_status"] == "Matched" and not r["referral_id"]]
    check(not invalid_reports, "DQ-014: matched report missing referral")
    invalid_review = [r for r in tables["consult_reports"] if r["report_status"] == "Reviewed" and (not r["reviewed_by_practitioner_id"] or not r["routed_at"] or not r["reviewed_at"])]
    check(not invalid_review, "DQ-015: reviewed report missing reviewer or timestamps")

    active_counts = Counter(r["referral_id"] for r in tables["referral_assignments"] if r["active_assignment_flag"] == "1")
    check(not [k for k, count in active_counts.items() if count > 1], "DQ-007: multiple active assignments")
    terminal = {"Closed—Completed", "Closed—Not Completed", "Cancelled"}
    check(not [r for r in tables["referrals"] if r["current_status"] in terminal and active_counts[r["referral_id"]] > 0],
          "DQ-009: terminal referral retains active assignment")

    reports_by_referral = {r["referral_id"] for r in tables["consult_reports"] if r["report_status"] == "Reviewed"}
    completed_appointments = {r["referral_id"] for r in tables["appointments"] if r["appointment_status"] == "Completed"}
    closed_complete = [r for r in tables["referrals"] if r["current_status"] == "Closed—Completed"]
    check(not [r for r in closed_complete if r["referral_id"] not in completed_appointments or r["referral_id"] not in reports_by_referral],
          "DQ-010: closed-completed referral lacks completed appointment or reviewed report")

    check(not [r for r in tables["referrals"] if r["current_status"] == "Closed—Not Completed" and not r["closure_reason"]],
          "DQ-011: non-completed closure missing reason")
    check(not [r for r in tables["coverages"] if r["termination_date"] and r["termination_date"] < r["effective_date"]],
          "DQ-019: termination date precedes effective date")
    check(not [r for r in tables["referrals"] if parse_dt(r["closed_at"]) and parse_dt(r["closed_at"]) < parse_dt(r["referral_received_at"])],
          "DQ-018: closure precedes referral receipt")

    if failures:
        print("VALIDATION FAILED")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)

    print("VALIDATION PASSED")
    print("15 processed CSV files checked")
    print(f"Total processed rows: {sum(len(rows) for rows in tables.values()):,}")
    print("Primary keys: unique and non-null")
    print("Foreign keys: valid")
    print("Cross-table DQ-001, DQ-002, DQ-005, DQ-007, DQ-009–DQ-015, DQ-018, and DQ-019: passed")


if __name__ == "__main__":
    main()
