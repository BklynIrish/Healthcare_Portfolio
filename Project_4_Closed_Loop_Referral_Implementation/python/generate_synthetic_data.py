"""Generate deterministic synthetic data for Healthcare Portfolio Project 4.

Outputs
-------
data/processed/: 15 database-ready CSV files, one per relational table.
data/raw/: selected source-style CSV extracts containing documented defects.
data/raw/intentional_defects_manifest.csv: exact seeded defect inventory.

The script uses only Python's standard library and generates no real PHI.
"""

from __future__ import annotations

import csv
import random
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path


SEED = 20260814
RNG = random.Random(SEED)
AS_OF = datetime(2026, 8, 1, 12, 0, 0)
START = datetime(2025, 8, 1, 8, 0, 0)
ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"


FIRST_NAMES = [
    "Avery", "Jordan", "Taylor", "Morgan", "Riley", "Cameron", "Casey",
    "Parker", "Quinn", "Reese", "Rowan", "Skyler", "Alex", "Jamie",
    "Drew", "Emerson", "Finley", "Hayden", "Logan", "Micah",
]
LAST_NAMES = [
    "Adams", "Bennett", "Carter", "Diaz", "Edwards", "Foster", "Garcia",
    "Hughes", "Irwin", "Johnson", "Kim", "Lewis", "Morris", "Nguyen",
    "Owens", "Patel", "Reed", "Singh", "Turner", "Walker",
]
LANGUAGES = ["English", "English", "English", "Spanish", "Portuguese", "Korean"]
SITES = ["Morristown", "Denville", "Parsippany", "Wayne", "Newark", "Paterson"]
SPECIALTY_NAMES = [
    ("CARD", "Cardiology"), ("DERM", "Dermatology"),
    ("ENDO", "Endocrinology"), ("GAST", "Gastroenterology"),
    ("NEUR", "Neurology"), ("ORTH", "Orthopedics"),
    ("ENT", "Otolaryngology"), ("PULM", "Pulmonology"),
    ("RHEU", "Rheumatology"), ("GSUR", "General Surgery"),
]
PAYER_DATA = [
    ("Garden State Health", "Commercial"),
    ("MetroChoice Benefits", "Commercial"),
    ("NorthEast Preferred", "Commercial"),
    ("Federal Medicare", "Medicare"),
    ("Garden Medicaid", "Medicaid"),
    ("Community Health Plan", "Medicaid"),
    ("UnionCare", "Commercial"),
    ("Self-Pay", "Self-Pay"),
]


def dt(value: datetime | None) -> str:
    return "" if value is None else value.strftime("%Y-%m-%d %H:%M:%S")


def d(value: date | None) -> str:
    return "" if value is None else value.isoformat()


def random_dt(start: datetime, end: datetime) -> datetime:
    seconds = int((end - start).total_seconds())
    return start + timedelta(seconds=RNG.randint(0, max(seconds, 0)))


def synthetic_npi(number: int) -> str:
    return f"99999{number:05d}"[-10:]


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        raise ValueError(f"No rows supplied for {path.name}")
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def make_reference_data() -> dict[str, list[dict]]:
    created = datetime(2025, 7, 1, 12, 0, 0)
    specialties = []
    for i, (code, name) in enumerate(SPECIALTY_NAMES, 1):
        specialties.append({
            "specialty_id": f"SPC{i:03d}", "specialty_code": code,
            "specialty_name": name, "routine_intake_sla_hours": 48,
            "urgent_intake_sla_hours": 8, "routine_outreach_sla_hours": 72,
            "urgent_outreach_sla_hours": 24, "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })

    organizations = []
    locations = []
    for i, site in enumerate(SITES, 1):
        oid, lid = f"ORG{i:03d}", f"LOC{i:03d}"
        organizations.append({
            "organization_id": oid, "source_organization_id": f"SRC-{oid}",
            "organization_name": f"NorthStar {site} Primary Care",
            "organization_type": "Primary Care Practice", "internal_flag": 1,
            "synthetic_npi": synthetic_npi(i), "phone_number": f"973-555-{1000+i:04d}",
            "fax_number": f"973-555-{2000+i:04d}", "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })
        locations.append({
            "location_id": lid, "organization_id": oid,
            "location_name": f"{site} Primary Care Campus",
            "address_line_1": f"{100+i} Portfolio Avenue", "city": site,
            "state_code": "NJ", "postal_code": f"07{i:03d}",
            "phone_number": f"973-555-{3000+i:04d}", "telehealth_flag": 0,
            "active_flag": 1, "created_at": dt(created), "updated_at": dt(created),
        })

    for j in range(1, 26):
        i = 6 + j
        specialty = specialties[(j - 1) % len(specialties)]
        oid, lid = f"ORG{i:03d}", f"LOC{i:03d}"
        city = RNG.choice(SITES)
        organizations.append({
            "organization_id": oid, "source_organization_id": f"SRC-{oid}",
            "organization_name": f"Portfolio {specialty['specialty_name']} Group {j:02d}",
            "organization_type": "Specialist Practice", "internal_flag": 0,
            "synthetic_npi": synthetic_npi(i), "phone_number": f"862-555-{1000+j:04d}",
            "fax_number": f"862-555-{2000+j:04d}", "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })
        locations.append({
            "location_id": lid, "organization_id": oid,
            "location_name": f"{specialty['specialty_name']} Center {j:02d}",
            "address_line_1": f"{300+j} Synthetic Plaza", "city": city,
            "state_code": "NJ", "postal_code": f"07{100+j:03d}",
            "phone_number": f"862-555-{3000+j:04d}",
            "telehealth_flag": 1 if j % 4 == 0 else 0, "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })

    payers = []
    for i, (name, category) in enumerate(PAYER_DATA, 1):
        payers.append({
            "payer_id": f"PAY{i:03d}", "payer_name": name,
            "payer_category": category,
            "electronic_payer_id": "" if category == "Self-Pay" else f"EPAY{i:04d}",
            "active_flag": 1, "created_at": dt(created), "updated_at": dt(created),
        })

    return {
        "specialties": specialties, "organizations": organizations,
        "locations": locations, "payers": payers,
    }


def make_people(ref: dict[str, list[dict]]) -> dict[str, list[dict]]:
    created = datetime(2025, 7, 1, 12, 0, 0)
    patients = []
    for i in range(1, 2001):
        first, last = RNG.choice(FIRST_NAMES), RNG.choice(LAST_NAMES)
        dob = date(1935, 1, 1) + timedelta(days=RNG.randint(0, 75 * 365))
        patients.append({
            "patient_id": f"PAT{i:06d}", "source_patient_id": f"EHR-P{i:07d}",
            "first_name": first, "last_name": last, "date_of_birth": d(dob),
            "administrative_sex": RNG.choice(["Female", "Male", "Unknown", "Other"]),
            "phone_number": f"201-555-{i % 10000:04d}",
            "email_address": f"patient{i:06d}@example.test" if i % 7 else "",
            "preferred_contact_channel": RNG.choice(["Phone", "SMS", "Patient Portal", "Email"]),
            "preferred_language": RNG.choice(LANGUAGES), "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })

    practitioners = []
    for i in range(1, 36):
        oid = f"ORG{((i - 1) % 6) + 1:03d}"
        practitioners.append({
            "practitioner_id": f"PRC{i:04d}", "source_practitioner_id": f"EHR-PRC{i:05d}",
            "organization_id": oid, "specialty_id": "",
            "first_name": RNG.choice(FIRST_NAMES), "last_name": RNG.choice(LAST_NAMES),
            "practitioner_role": "Medical Director" if i == 1 else "Referring Clinician",
            "synthetic_npi": synthetic_npi(1000 + i), "internal_flag": 1,
            "active_flag": 1, "created_at": dt(created), "updated_at": dt(created),
        })
    for j in range(1, 76):
        i = 35 + j
        org_num = 7 + ((j - 1) % 25)
        specialty = ref["specialties"][(org_num - 7) % 10]
        practitioners.append({
            "practitioner_id": f"PRC{i:04d}", "source_practitioner_id": f"EXT-PRC{i:05d}",
            "organization_id": f"ORG{org_num:03d}", "specialty_id": specialty["specialty_id"],
            "first_name": RNG.choice(FIRST_NAMES), "last_name": RNG.choice(LAST_NAMES),
            "practitioner_role": "Specialist", "synthetic_npi": synthetic_npi(1000 + i),
            "internal_flag": 0, "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })

    users = []
    roles = (["Referral Coordinator"] * 14 + ["Referral Manager"] * 3 +
             ["Practice Manager"] * 6 + ["Medical Director"] * 1 +
             ["Health IT Support"] * 2 + ["Data Analyst"] * 2 +
             ["System Administrator"] * 1 + ["Auditor"] * 1)
    for i, role in enumerate(roles, 1):
        site_num = ((i - 1) % 6) + 1
        users.append({
            "user_id": f"USR{i:03d}", "organization_id": f"ORG{site_num:03d}",
            "location_id": f"LOC{site_num:03d}",
            "display_name": f"{RNG.choice(FIRST_NAMES)} {RNG.choice(LAST_NAMES)}",
            "user_role": role, "active_flag": 1,
            "created_at": dt(created), "updated_at": dt(created),
        })

    return {"patients": patients, "practitioners": practitioners, "users": users}


def make_coverages(patients: list[dict], payers: list[dict]) -> list[dict]:
    rows = []
    for i, patient in enumerate(patients, 1):
        payer = RNG.choice(payers)
        effective = date(2024, 1, 1) + timedelta(days=RNG.randint(0, 540))
        rows.append({
            "coverage_id": f"COV{i:06d}", "source_coverage_id": f"EHR-COV{i:07d}",
            "patient_id": patient["patient_id"], "payer_id": payer["payer_id"],
            "member_id": f"SYN-MBR-{i:07d}", "plan_name": f"{payer['payer_name']} Standard",
            "coverage_type": payer["payer_category"], "coverage_status": "Active",
            "effective_date": d(effective), "termination_date": "",
            "primary_coverage_flag": 1, "created_at": dt(START), "updated_at": dt(START),
        })
    for j in range(1, 201):
        i = 2000 + j
        patient = patients[j - 1]
        payer = RNG.choice(payers[:-1])
        effective = date(2023, 1, 1) + timedelta(days=RNG.randint(0, 365))
        termination = effective + timedelta(days=RNG.randint(180, 540))
        rows.append({
            "coverage_id": f"COV{i:06d}", "source_coverage_id": f"EHR-COV{i:07d}",
            "patient_id": patient["patient_id"], "payer_id": payer["payer_id"],
            "member_id": f"SYN-MBR-{i:07d}", "plan_name": f"{payer['payer_name']} Prior Plan",
            "coverage_type": payer["payer_category"], "coverage_status": "Inactive",
            "effective_date": d(effective), "termination_date": d(termination),
            "primary_coverage_flag": 0, "created_at": dt(START), "updated_at": dt(START),
        })
    return rows


def choose_status() -> str:
    values = [
        "Received", "Needs Information", "Ready for Outreach", "Outreach in Progress",
        "Scheduled", "Completed—Report Pending", "Closed—Completed",
        "Closed—Not Completed", "Cancelled",
    ]
    weights = [2, 4, 3, 8, 14, 8, 45, 12, 4]
    return RNG.choices(values, weights=weights, k=1)[0]


def make_lifecycle(
    people: dict[str, list[dict]], ref: dict[str, list[dict]], coverages: list[dict]
) -> dict[str, list[dict]]:
    referrals, history, outreach, appointments, reports, issues, assignments = ([] for _ in range(7))
    coverage_by_patient = {r["patient_id"]: r for r in coverages if r["coverage_status"] == "Active"}
    internal_practitioners = people["practitioners"][:35]
    specialists = people["practitioners"][35:]
    coordinators = [u for u in people["users"] if u["user_role"] == "Referral Coordinator"]
    status_counter = outreach_counter = appointment_counter = report_counter = issue_counter = assignment_counter = 0

    paths = {
        "Received": ["Received"],
        "Needs Information": ["Received", "Needs Information"],
        "Ready for Outreach": ["Received", "Ready for Outreach"],
        "Outreach in Progress": ["Received", "Ready for Outreach", "Outreach in Progress"],
        "Scheduled": ["Received", "Ready for Outreach", "Outreach in Progress", "Scheduled"],
        "Completed—Report Pending": ["Received", "Ready for Outreach", "Outreach in Progress", "Scheduled", "Completed—Report Pending"],
        "Closed—Completed": ["Received", "Ready for Outreach", "Outreach in Progress", "Scheduled", "Completed—Report Pending", "Closed—Completed"],
        "Closed—Not Completed": ["Received", "Ready for Outreach", "Outreach in Progress", "Closed—Not Completed"],
        "Cancelled": ["Received", "Cancelled"],
    }
    queue_map = {
        "Received": "New Intake", "Needs Information": "Needs Information",
        "Ready for Outreach": "Ready for Outreach", "Outreach in Progress": "Outreach Follow-Up",
        "Scheduled": "Appointment Verification", "Completed—Report Pending": "Report Pending",
    }
    closure_reason_values = [
        "Patient Declined", "Unable to Contact After Protocol", "No Longer Clinically Indicated",
        "Transferred Care", "Patient Moved", "Duplicate Referral",
        "Insurance or Access Barrier", "Patient Chose Another Provider",
    ]

    for i in range(1, 2501):
        referral_id = f"REF{i:06d}"
        patient = RNG.choice(people["patients"])
        coverage = coverage_by_patient[patient["patient_id"]]
        referrer = RNG.choice(internal_practitioners)
        org_id = referrer["organization_id"]
        site_num = int(org_id[-3:])
        specialty = RNG.choice(ref["specialties"])
        eligible = [p for p in specialists if p["specialty_id"] == specialty["specialty_id"]]
        specialist = RNG.choice(eligible)
        destination_org = specialist["organization_id"]
        destination_location = f"LOC{int(destination_org[-3:]):03d}"
        owner = RNG.choice(coordinators)
        priority = "Urgent" if RNG.random() < 0.12 else "Routine"
        received = random_dt(START, datetime(2026, 7, 15, 17, 0, 0))
        ordered = received - timedelta(hours=RNG.randint(0, 24))
        current_status = choose_status()
        path = paths[current_status]
        event_times = [received]
        for _ in path[1:]:
            event_times.append(event_times[-1] + timedelta(hours=RNG.randint(4, 96)))
        if event_times[-1] > AS_OF:
            shift = event_times[-1] - AS_OF + timedelta(hours=1)
            event_times = [x - shift for x in event_times]
            received, ordered = event_times[0], event_times[0] - timedelta(hours=RNG.randint(0, 24))

        terminal = current_status in {"Closed—Completed", "Closed—Not Completed", "Cancelled"}
        current_stage = event_times[-1]
        sla_hours = 24 if priority == "Urgent" else 72
        due = None if terminal else current_stage + timedelta(hours=sla_hours)
        initial_validation = event_times[1] if len(path) > 1 and path[1] != "Needs Information" else None

        contact_times = []
        if current_status in {"Outreach in Progress", "Scheduled", "Completed—Report Pending", "Closed—Completed", "Closed—Not Completed"}:
            first_contact = received + timedelta(hours=RNG.randint(8, 120))
            for attempt_num in range(RNG.randint(1, 3)):
                at = first_contact + timedelta(days=attempt_num * RNG.randint(1, 3))
                contact_times.append(at)
                outreach_counter += 1
                final_attempt = attempt_num == 0 and current_status not in {"Outreach in Progress", "Closed—Not Completed"}
                outcome = "Reached" if final_attempt else RNG.choice(["No Answer", "Voicemail Left", "Callback Requested", "Reached"])
                outreach.append({
                    "outreach_attempt_id": f"OUT{outreach_counter:06d}", "referral_id": referral_id,
                    "performed_by_user_id": owner["user_id"], "attempt_at": dt(at),
                    "communication_channel": RNG.choice(["Phone", "Voicemail", "SMS", "Patient Portal"]),
                    "contacted_party": "Patient", "outreach_outcome": outcome,
                    "next_action_at": dt(at + timedelta(days=2)) if outcome != "Reached" else "",
                    "outreach_note": "Synthetic outreach event", "created_at": dt(at),
                })

        first_scheduled = first_completed = first_report = closed_at = None
        closure_category = closure_reason = ""
        appointment_id = ""
        if current_status in {"Scheduled", "Completed—Report Pending", "Closed—Completed"}:
            scheduled_at = (contact_times[0] if contact_times else received) + timedelta(hours=RNG.randint(2, 48))
            appointment_start = scheduled_at + timedelta(days=RNG.randint(3, 35))
            first_scheduled = scheduled_at
            appointment_counter += 1
            final_appointment_id = f"APT{appointment_counter:06d}"
            appointment_id = final_appointment_id
            completed = current_status in {"Completed—Report Pending", "Closed—Completed"}
            status = "Completed" if completed else "Scheduled"
            outcome_at = appointment_start + timedelta(hours=1) if completed else None
            appointments.append({
                "appointment_id": final_appointment_id, "referral_id": referral_id,
                "practitioner_id": specialist["practitioner_id"], "organization_id": destination_org,
                "location_id": destination_location, "scheduled_at": dt(scheduled_at),
                "appointment_start_at": dt(appointment_start), "appointment_status": status,
                "outcome_recorded_at": dt(outcome_at), "scheduling_source": "NorthStar Staff",
                "telehealth_flag": 1 if RNG.random() < 0.18 else 0, "outcome_reason": "",
                "superseded_by_appointment_id": "", "created_at": dt(scheduled_at),
                "updated_at": dt(outcome_at or scheduled_at),
            })
            if completed:
                first_completed = appointment_start

            if RNG.random() < 0.05:
                appointment_counter += 1
                old_id = f"APT{appointment_counter:06d}"
                appointments.append({
                    "appointment_id": old_id, "referral_id": referral_id,
                    "practitioner_id": specialist["practitioner_id"], "organization_id": destination_org,
                    "location_id": destination_location,
                    "scheduled_at": dt(scheduled_at - timedelta(days=5)),
                    "appointment_start_at": dt(appointment_start - timedelta(days=7)),
                    "appointment_status": "Rescheduled", "outcome_recorded_at": dt(scheduled_at),
                    "scheduling_source": "Specialist Office", "telehealth_flag": 0,
                    "outcome_reason": "Specialist schedule changed",
                    "superseded_by_appointment_id": final_appointment_id,
                    "created_at": dt(scheduled_at - timedelta(days=5)), "updated_at": dt(scheduled_at),
                })

            if current_status == "Closed—Completed":
                received_report = appointment_start + timedelta(days=RNG.randint(1, 10))
                routed = received_report + timedelta(hours=RNG.randint(1, 12))
                reviewed = routed + timedelta(hours=RNG.randint(1, 24))
                first_report = received_report
                report_counter += 1
                reports.append({
                    "consult_report_id": f"RPT{report_counter:06d}",
                    "external_document_id": f"DOC-{report_counter:07d}",
                    "referral_id": referral_id, "appointment_id": appointment_id,
                    "author_practitioner_id": specialist["practitioner_id"],
                    "source_organization_id": destination_org,
                    "reviewed_by_practitioner_id": referrer["practitioner_id"],
                    "report_source": RNG.choice(["FHIR", "EHR Exchange", "Portal", "Fax"]),
                    "report_date": d(appointment_start.date()), "received_at": dt(received_report),
                    "match_method": RNG.choice(["Automatic", "Manual"]), "match_status": "Matched",
                    "routed_at": dt(routed), "reviewed_at": dt(reviewed),
                    "report_status": "Reviewed", "created_at": dt(received_report),
                    "updated_at": dt(reviewed),
                })
                closed_at = reviewed + timedelta(hours=RNG.randint(1, 12))
                closure_category = "Completed"
        elif current_status == "Closed—Not Completed":
            closed_at = event_times[-1]
            closure_category = "Not Completed"
            closure_reason = RNG.choice(closure_reason_values)
        elif current_status == "Cancelled":
            closed_at = event_times[-1]
            closure_category = "Cancelled"
            closure_reason = RNG.choice(["Duplicate Referral", "No Longer Clinically Indicated"])

        queue = "" if terminal else queue_map[current_status]
        referrals.append({
            "referral_id": referral_id, "source_referral_id": f"EHR-REF{i:07d}",
            "source_system": "NorthStar EHR", "patient_id": patient["patient_id"],
            "coverage_id": coverage["coverage_id"],
            "referring_practitioner_id": referrer["practitioner_id"],
            "referring_organization_id": org_id, "referring_location_id": f"LOC{site_num:03d}",
            "specialty_id": specialty["specialty_id"],
            "destination_practitioner_id": specialist["practitioner_id"],
            "destination_organization_id": destination_org,
            "current_owner_user_id": "" if terminal else owner["user_id"],
            "source_ordered_at": dt(ordered), "referral_received_at": dt(received),
            "clinical_reason": f"Synthetic evaluation request for {specialty['specialty_name']}",
            "diagnosis_code": f"Z{RNG.randint(10, 89)}.{RNG.randint(0, 9)}",
            "priority": priority, "current_status": current_status, "current_queue": queue,
            "current_stage_started_at": dt(current_stage), "service_level_due_at": dt(due),
            "initial_validation_completed_at": dt(initial_validation),
            "first_outreach_at": dt(contact_times[0] if contact_times else None),
            "first_scheduled_at": dt(first_scheduled),
            "first_completed_appointment_at": dt(first_completed),
            "first_report_received_at": dt(first_report), "closed_at": dt(closed_at),
            "closure_category": closure_category, "closure_reason": closure_reason,
            "created_at": dt(received), "updated_at": dt(closed_at or current_stage),
        })

        previous = None
        for status, event_at in zip(path, event_times):
            status_counter += 1
            history.append({
                "status_history_id": f"STH{status_counter:06d}", "referral_id": referral_id,
                "previous_status": previous or "", "new_status": status,
                "status_changed_at": dt(event_at), "changed_by_user_id": owner["user_id"],
                "change_source": "User" if previous else "Interface",
                "change_reason": "Synthetic lifecycle event", "override_flag": 0,
                "created_at": dt(event_at),
            })
            previous = status

        assignment_counter += 1
        assignments.append({
            "assignment_id": f"ASN{assignment_counter:06d}", "referral_id": referral_id,
            "assigned_user_id": owner["user_id"], "queue_name": queue or "Ready for Outreach",
            "assigned_by_user_id": "", "assignment_source": "Automation",
            "assignment_start_at": dt(received), "assignment_end_at": dt(closed_at),
            "assignment_reason": "Initial routing", "active_assignment_flag": 0 if terminal else 1,
            "created_at": dt(received),
        })

        if current_status == "Needs Information" or RNG.random() < 0.08:
            issue_counter += 1
            open_issue = current_status == "Needs Information"
            detected = received + timedelta(hours=2)
            resolved_at = None if open_issue else detected + timedelta(days=RNG.randint(1, 4))
            issues.append({
                "validation_issue_id": f"VAL{issue_counter:06d}", "referral_id": referral_id,
                "source_record_id": f"EHR-REF{i:07d}", "issue_source": "Intake",
                "rule_code": RNG.choice(["REQ-DOC-001", "REQ-COV-002", "REQ-CONTACT-003"]),
                "field_name": RNG.choice(["clinical_reason", "coverage_id", "phone_number"]),
                "severity": "Blocking" if open_issue else "Warning",
                "issue_description": "Synthetic referral validation issue",
                "detected_at": dt(detected), "resolution_status": "Open" if open_issue else "Resolved",
                "resolved_by_user_id": "" if open_issue else owner["user_id"],
                "resolved_at": dt(resolved_at),
                "resolution_note": "" if open_issue else "Corrected during intake review",
                "created_at": dt(detected), "updated_at": dt(resolved_at or detected),
            })

    return {
        "referrals": referrals, "referral_status_history": history,
        "outreach_attempts": outreach, "appointments": appointments,
        "consult_reports": reports, "referral_validation_issues": issues,
        "referral_assignments": assignments,
    }


def create_raw_extracts(processed: dict[str, list[dict]]) -> list[dict]:
    defects = []
    raw_patients = [row.copy() for row in processed["patients"]]
    raw_coverages = [row.copy() for row in processed["coverages"]]
    raw_referrals = [row.copy() for row in processed["referrals"]]

    for idx in range(5):
        raw_patients[idx]["phone_number"] = "INVALID"
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "patients_raw.csv", "record_id": raw_patients[idx]["patient_id"], "field_name": "phone_number", "rule_code": "RAW-PHONE-001", "description": "Invalid telephone format"})
    for idx in range(5):
        row = raw_coverages[idx]
        row["termination_date"] = d(date.fromisoformat(row["effective_date"]) - timedelta(days=30))
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "coverages_raw.csv", "record_id": row["coverage_id"], "field_name": "termination_date", "rule_code": "DQ-019", "description": "Termination date precedes effective date"})
    for idx in range(5):
        raw_referrals[idx]["specialty_id"] = ""
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "referrals_raw.csv", "record_id": raw_referrals[idx]["referral_id"], "field_name": "specialty_id", "rule_code": "RAW-REQ-001", "description": "Required specialty is missing"})
    for idx in range(5, 10):
        raw_referrals[idx]["priority"] = "STAT"
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "referrals_raw.csv", "record_id": raw_referrals[idx]["referral_id"], "field_name": "priority", "rule_code": "RAW-VAL-002", "description": "Priority is outside allowed values"})
    for idx in range(10, 15):
        raw_referrals[idx]["source_referral_id"] = raw_referrals[0]["source_referral_id"]
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "referrals_raw.csv", "record_id": raw_referrals[idx]["referral_id"], "field_name": "source_referral_id", "rule_code": "RAW-DUP-003", "description": "Duplicate source referral identifier"})
    for idx in range(15, 20):
        ordered = datetime.strptime(raw_referrals[idx]["source_ordered_at"], "%Y-%m-%d %H:%M:%S")
        raw_referrals[idx]["referral_received_at"] = dt(ordered - timedelta(days=1))
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "referrals_raw.csv", "record_id": raw_referrals[idx]["referral_id"], "field_name": "referral_received_at", "rule_code": "RAW-DATE-004", "description": "Referral received before source order"})
    for idx in range(20, 25):
        other = processed["coverages"][(idx + 100) % len(processed["coverages"])]
        raw_referrals[idx]["coverage_id"] = other["coverage_id"]
        defects.append({"defect_id": f"DEF{len(defects)+1:03d}", "file_name": "referrals_raw.csv", "record_id": raw_referrals[idx]["referral_id"], "field_name": "coverage_id", "rule_code": "DQ-001", "description": "Coverage belongs to another patient"})

    write_csv(RAW_DIR / "patients_raw.csv", raw_patients)
    write_csv(RAW_DIR / "coverages_raw.csv", raw_coverages)
    write_csv(RAW_DIR / "referrals_raw.csv", raw_referrals)
    write_csv(RAW_DIR / "intentional_defects_manifest.csv", defects)
    return defects


def main() -> None:
    ref = make_reference_data()
    people = make_people(ref)
    coverages = make_coverages(people["patients"], ref["payers"])
    lifecycle = make_lifecycle(people, ref, coverages)
    processed = {**ref, **people, "coverages": coverages, **lifecycle}

    ordered_tables = [
        "patients", "organizations", "locations", "specialties", "practitioners",
        "payers", "coverages", "users", "referrals", "referral_status_history",
        "outreach_attempts", "appointments", "consult_reports",
        "referral_validation_issues", "referral_assignments",
    ]
    for table in ordered_tables:
        write_csv(PROCESSED_DIR / f"{table}.csv", processed[table])
    defects = create_raw_extracts(processed)

    print(f"Generated {len(ordered_tables)} processed CSV files.")
    for table in ordered_tables:
        print(f"{table}: {len(processed[table]):,}")
    print(f"Intentional raw defects: {len(defects)}")


if __name__ == "__main__":
    main()
