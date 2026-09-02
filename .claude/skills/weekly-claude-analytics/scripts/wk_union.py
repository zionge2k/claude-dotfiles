#!/usr/bin/env python3
"""Wall-clock active time — merges concurrent sessions (W33 addition).

The per-session "active time" in wk_analytics.py double-counts overlapping
sessions: running 2 sessions side by side for an hour reports 2h. W33 hit
20h 46m on a single calendar day this way. This script merges every top-level
session's active intervals into a union, giving true elapsed hours.

Run wk_analytics.py first (it produces WK_OUT), then:
  U_START=2026-08-08T08:00 U_END=2026-08-15T08:00 WK_OUT=/tmp/wk33.json \
    python3 wk_union.py
"""
import json, glob, os
from datetime import datetime, timedelta, timezone
from collections import defaultdict

KST = timezone(timedelta(hours=9))
IDLE = timedelta(minutes=30)
ROOT = os.path.expanduser("~/.claude/projects")


def _env_dt(name, fallback):
    """U_START/U_END win, but fall back to the WK_* pair wk_analytics.py used.
    Defining the window twice under different names let the summed and merged
    numbers describe different windows without ever erroring."""
    v = os.environ.get(name) or os.environ.get(fallback)
    if not v:
        raise SystemExit(f"set {name} (or {fallback}) — e.g. 2026-08-15T08:00")
    if len(v) == 10:
        v += "T00:00"
    return datetime.fromisoformat(v).replace(tzinfo=KST)


WS, NOW = _env_dt("U_START", "WK_START"), _env_dt("U_END", "WK_END")
SESSIONS = json.load(open(os.environ.get("WK_OUT", "/tmp/wk_sessions.json")))
# only top-level files that the analytics pass already accepted for this window
keep = {s["path"] for s in SESSIONS if not s["sub"]}


def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).astimezone(KST)
    except Exception:
        return None


intervals = []
for path in glob.glob(os.path.join(ROOT, "*", "*.jsonl")):
    if path not in keep:
        continue
    ts = []
    for line in open(path, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            r = json.loads(line)
        except Exception:
            continue
        t = parse_ts(r.get("timestamp", "")) if r.get("timestamp") else None
        if t:
            ts.append(t)
    ts.sort()
    for a, b in zip(ts, ts[1:]):
        if timedelta(0) < b - a < IDLE and WS <= b < NOW:
            intervals.append((max(a, WS), b))

intervals.sort()
merged = []
for a, b in intervals:
    if merged and a <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], b)
    else:
        merged.append([a, b])


def fmt(sec):
    return f"{int(sec)//3600}h {int(sec)%3600//60:02d}m"


total = sum((b - a).total_seconds() for a, b in merged)
print(f"# window: {WS.isoformat()} .. {NOW.isoformat()}")
print("union wall-clock active:", fmt(total))

per = defaultdict(float)
for a, b in merged:
    per[b.date().isoformat()] += (b - a).total_seconds()
print("\n== per day (merged) ==")
for k in sorted(per):
    print(k, fmt(per[k]))

print("\n== longest continuous blocks ==")
for a, b in sorted(merged, key=lambda x: -(x[1] - x[0]).total_seconds())[:8]:
    print(f"  {a.strftime('%m-%d %H:%M')} -> {b.strftime('%m-%d %H:%M')}  "
          f"{fmt((b - a).total_seconds())}")
