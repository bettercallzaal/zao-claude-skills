#!/usr/bin/env python3
"""
airtable-crm-write.py - write meeting recap data into the ZAO CRM AGENTIC
Airtable base. Default-ON in /meeting Phase 4 (Flow E per doc 737).

Input: the /meeting Phase 2 extracted JSON (the same file fed to
append-actions.sh + bonfire-episode.sh).

What this does:
  1. For each meeting.attendee NOT already in `contacts`, insert a minimum
     contact row (name, met_via=meeting-skill, first_contact_date).
  2. Insert ONE activity row of type=meeting linked to all attendees,
     raw_source = research doc number, source = meeting-skill.
  3. Do NOT auto-create opportunities. The /meeting Phase 3 surface lists
     proposed opportunities and only writes them on explicit Zaal OK.

Best-effort: if AIRTABLE_CRM_TOKEN / AIRTABLE_CRM_BASE_ID unset, prints
"skipped (no airtable env)" and exits 0. A 4xx/5xx from Airtable logs
the error and exits 0 - never aborts the larger meeting flow.

Usage:
  airtable-crm-write.py <extracted-json-path> [--recap-doc <NNN>]

Env (sourced from ~/.zao/zao.env if not in process env):
  AIRTABLE_CRM_TOKEN
  AIRTABLE_CRM_BASE_ID

Table IDs are hardcoded per the build done on 2026-05-24 per doc 737:
  contacts:      tbld4piB9auXPXYEn
  activity:      tblHGmWeoH0ijetPH
  opportunities: tblnjqTNvYd1lyez3
"""
import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path


CONTACTS_TABLE = "tbld4piB9auXPXYEn"
ACTIVITY_TABLE = "tblHGmWeoH0ijetPH"


def load_env():
    """Source ~/.zao/zao.env into os.environ if AIRTABLE_CRM_TOKEN is missing."""
    if os.environ.get("AIRTABLE_CRM_TOKEN"):
        return
    env_path = Path.home() / ".zao" / "zao.env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        if v.startswith("PASTE_"):
            continue
        os.environ.setdefault(k.strip(), v.strip())


def api(method, path, body=None):
    token = os.environ["AIRTABLE_CRM_TOKEN"]
    base_id = os.environ["AIRTABLE_CRM_BASE_ID"]
    url = f"https://api.airtable.com/v0/{base_id}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}


def find_contact_by_name(name):
    """Return record id if a contact with this name exists, else None."""
    safe = name.replace("'", "\\'")
    formula = f"{{name}}='{safe}'"
    status, resp = api(
        "GET",
        f"/{CONTACTS_TABLE}?filterByFormula={urllib_quote(formula)}&fields[]=name&maxRecords=1",
    )
    if status == 200 and resp.get("records"):
        return resp["records"][0]["id"]
    return None


def urllib_quote(s):
    import urllib.parse as p
    return p.quote(s, safe="")


def ensure_contact(name, meeting_date, source_tag):
    """Find or create a contact row. Returns record id."""
    existing = find_contact_by_name(name)
    if existing:
        print(f"  contact '{name}' exists -> {existing}", file=sys.stderr)
        return existing
    body = {"records": [{"fields": {
        "name": name,
        "met_via": f"meeting-skill ({source_tag})",
        "first_contact_date": meeting_date,
        "last_touch_date": meeting_date,
    }}]}
    status, resp = api("POST", f"/{CONTACTS_TABLE}", body)
    if status not in (200, 201):
        print(f"  ERROR creating contact '{name}': {status} {resp}", file=sys.stderr)
        return None
    rid = resp["records"][0]["id"]
    print(f"  created contact '{name}' -> {rid}", file=sys.stderr)
    return rid


def slugify(text, max_len=40):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower())
    return s.strip("-")[:max_len]


def infer_relevance(meeting):
    """Heuristic zao_relevance based on title + attendees."""
    text = (meeting.get("title", "") + " " + " ".join(meeting.get("attendees", []))).lower()
    rules = [
        (("zabal-games", "zabal games"), "ZABAL-Games"),
        (("zaostock", "zao stock"), "ZAOstock"),
        (("wavewarz", "wave warz"), "WaveWarZ"),
        (("zao music",), "ZAO-Music"),
        (("zao devz", "zao-devz", "iman"), "ZAO-Devz"),
        (("hermes",), "Hermes"),
        (("zoe",), "ZOE"),
        (("bonfire",), "Bonfire"),
        (("fractal",), "Fractal"),
    ]
    tags = []
    for kws, tag in rules:
        if any(k in text for k in kws):
            tags.append(tag)
    return tags or ["ops"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input_json", help="path to /meeting Phase 2 extracted JSON")
    ap.add_argument("--recap-doc", default=None, help="research events doc number (e.g. 736)")
    ap.add_argument(
        "--source-slug",
        default=None,
        help="slug used in source_tag / bonfire episode names (default: slug from title)",
    )
    args = ap.parse_args()

    load_env()
    if not os.environ.get("AIRTABLE_CRM_TOKEN") or not os.environ.get("AIRTABLE_CRM_BASE_ID"):
        print("[airtable-crm] AIRTABLE_CRM_TOKEN / BASE_ID unset - skipping CRM write", file=sys.stderr)
        print("Airtable CRM: skipped (no env)")
        return 0

    with open(args.input_json) as f:
        data = json.load(f)

    meeting = data.get("meeting", {})
    title = meeting.get("title", "Untitled meeting")
    date = meeting.get("date", "")  # YYYY-MM-DD
    attendees = meeting.get("attendees", [])
    if not date:
        print(f"[airtable-crm] no meeting.date in input - aborting", file=sys.stderr)
        print("Airtable CRM: skipped (no date)")
        return 0

    source_slug = args.source_slug or slugify(title)
    source_tag = f"meeting:{source_slug}-{date}"

    # ---------- 1. Ensure contacts ----------
    print(f"\n[airtable-crm] ensuring {len(attendees)} contacts", file=sys.stderr)
    contact_ids = []
    for name in attendees:
        rid = ensure_contact(name, date, source_tag)
        if rid:
            contact_ids.append(rid)

    # ---------- 2. Insert activity row ----------
    raw_source = (
        f"research/events/{args.recap_doc}-{source_slug}/" if args.recap_doc
        else f"meeting-skill:{source_tag}"
    )

    # Time: use 00:00 if only date is known
    date_iso = f"{date}T00:00:00.000Z"

    activity_row = {
        "title": title,
        "date": date_iso,
        "type": "meeting",
        "contacts": contact_ids,
        "direction": "mutual",
        "source": "meeting-skill",
        "raw_source": raw_source,
        "zao_relevance": infer_relevance(meeting),
        "summary": (
            f"{len(data.get('decisions', []))} decisions, "
            f"{len(data.get('actions', []))} actions, "
            f"{len(data.get('quotes', []))} quotes captured. "
            f"See {raw_source} for full recap."
        ),
        "bonfire_episode_id": f"meeting:{date}:{source_slug}:summary",
    }
    print(f"\n[airtable-crm] inserting activity row...", file=sys.stderr)
    status, resp = api("POST", f"/{ACTIVITY_TABLE}", {"records": [{"fields": activity_row}]})
    if status not in (200, 201):
        print(f"[airtable-crm] activity insert FAILED ({status}): {resp}", file=sys.stderr)
        print("Airtable CRM: activity insert FAILED")
        return 0
    activity_id = resp["records"][0]["id"]
    print(f"[airtable-crm] activity row -> {activity_id}", file=sys.stderr)

    print(f"\nAirtable CRM: {len(contact_ids)} contacts + 1 activity row ({activity_id})")
    print(f"  next: propose any opportunities to Zaal in Phase 3 before writing to opportunities table")
    return 0


if __name__ == "__main__":
    sys.exit(main())
