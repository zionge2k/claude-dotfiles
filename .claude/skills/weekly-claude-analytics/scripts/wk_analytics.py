#!/usr/bin/env python3
"""Weekly Claude Code session analytics (W-methodology consistent with 2026-W30 report).

Active time = sum of adjacent event gaps < 30min (idle excluded), attributed by
the date of the later event, counted only for events on/after week start.
"""
import json, os, glob, sys, re
from datetime import datetime, timedelta, timezone
from collections import defaultdict, Counter

KST = timezone(timedelta(hours=9))

def _env_dt(name, default):
    """Accept 'YYYY-MM-DD' or 'YYYY-MM-DDTHH:MM' from env; fall back to default."""
    v = os.environ.get(name)
    if not v:
        return default
    if len(v) == 10:
        v += "T00:00"
    return datetime.fromisoformat(v).replace(tzinfo=KST)

WEEK_START = _env_dt("WK_START", datetime(2026, 7, 27, 0, 0, tzinfo=KST))
NOW = _env_dt("WK_END", datetime(2026, 8, 2, 0, 0, tzinfo=KST))
OUT = os.environ.get("WK_OUT", "/tmp/wk_sessions.json")
IDLE = timedelta(minutes=30)
ROOT = os.path.expanduser("~/.claude/projects")
print(f"# window: {WEEK_START.isoformat()} .. {NOW.isoformat()} -> {OUT}", file=sys.stderr)

def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).astimezone(KST)
    except Exception:
        return None

def text_of(content):
    if isinstance(content, str):
        return content
    out = []
    if isinstance(content, list):
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                out.append(b.get("text", ""))
    return "\n".join(out)

SCRATCH_RE = re.compile(r"^(/private)?/tmp/")
# W34: 33~48% of "unique edited files" were /private/tmp/claude-501 scratch.
# Count them, but keep them out of the headline product-file metric.

# W34: sessions started with /clear carry no work text in first_prompt.
# Skip harness/meta lines to find the first *substantive* user message.
SKIP_PREFIX = ("<command-", "<system-reminder", "[Request interrupted",
               "<local-command", "<teammate-message", "Caveat:")

sessions = []
for path in glob.glob(os.path.join(ROOT, "*", "*.jsonl")) + glob.glob(os.path.join(ROOT, "*", "*", "subagents", "*.jsonl")):
    rel = os.path.relpath(path, ROOT)
    parts = rel.split(os.sep)
    proj = parts[0]
    is_sub = "subagents" in parts
    ts_all, ts_week = [], []
    tools = Counter()
    files_edited = set()
    first_prompt = None
    real_prompt = None
    user_msgs = 0
    asst_msgs = 0
    models = Counter()
    try:
        with open(path, "r", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    r = json.loads(line)
                except Exception:
                    continue
                t = parse_ts(r.get("timestamp", "")) if r.get("timestamp") else None
                if t:
                    ts_all.append(t)
                    inwk = WEEK_START <= t < NOW
                    if inwk:
                        ts_week.append(t)
                else:
                    inwk = False
                typ = r.get("type")
                msg = r.get("message") or {}
                if typ == "user" and not r.get("isMeta"):
                    c = msg.get("content")
                    txt = text_of(c)
                    if txt and not txt.startswith("<system-reminder"):
                        user_msgs += 1
                        if first_prompt is None:
                            first_prompt = txt[:600]
                        if real_prompt is None and not txt.lstrip().startswith(SKIP_PREFIX):
                            real_prompt = txt[:600]
                if typ == "assistant":
                    asst_msgs += 1
                    if msg.get("model"):
                        models[msg["model"]] += 1
                    for b in (msg.get("content") or []):
                        if isinstance(b, dict) and b.get("type") == "tool_use":
                            name = b.get("name", "?")
                            if inwk:
                                tools[name] += 1
                            if name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
                                fp = (b.get("input") or {}).get("file_path")
                                if fp and inwk:
                                    files_edited.add(fp)
    except Exception as e:
        print("ERR", path, e, file=sys.stderr)
        continue

    if not ts_week:
        continue
    ts_all.sort()
    # active seconds attributed per local date, only for gaps ending in-week
    per_day = defaultdict(float)
    active = 0.0
    for a, b in zip(ts_all, ts_all[1:]):
        gap = b - a
        if gap < IDLE and gap.total_seconds() > 0 and WEEK_START <= b < NOW:
            active += gap.total_seconds()
            per_day[b.date().isoformat()] += gap.total_seconds()
    sessions.append(dict(
        path=path, proj=proj, sub=is_sub,
        start=min(ts_all).isoformat(), start_wk=min(ts_week).isoformat(),
        end=max(ts_all).isoformat(),
        span_h=round((max(ts_all) - min(ts_all)).total_seconds() / 3600, 1),
        active_s=round(active), per_day={k: round(v) for k, v in per_day.items()},
        tools=dict(tools), n_files=len(files_edited), files=sorted(files_edited)[:80],
        n_files_scratch=sum(1 for f in files_edited if SCRATCH_RE.match(f)),
        _all_files=sorted(files_edited),
        user_msgs=user_msgs, asst_msgs=asst_msgs,
        first_prompt=first_prompt or "", real_prompt=real_prompt or "",
        models=dict(models),
    ))

sessions.sort(key=lambda s: s["start_wk"])
json.dump(sessions, open(OUT, "w"), ensure_ascii=False, indent=1)

top = [s for s in sessions if not s["sub"]]
sub = [s for s in sessions if s["sub"]]
def fmt(sec):
    return f"{int(sec)//3600}h {int(sec)%3600//60:02d}m"

# NOTE: s["files"] is truncated to 80 per session — never union it. Use these
# untruncated global sets instead (W31 undercounted 195 vs real 222 this way).
uniq_top = set(); uniq_all = set()
for s in sessions:
    for f in s["_all_files"]:
        uniq_all.add(f)
        if not s["sub"]:
            uniq_top.add(f)
def _split(fs):
    scr = {f for f in fs if SCRATCH_RE.match(f)}
    return len(fs) - len(scr), len(scr)
pt, st = _split(uniq_top); pa, sa = _split(uniq_all)
print(f"UNIQUE edited files: top-level={len(uniq_top)} (product={pt} scratch={st}) "
      f"all(incl subagent)={len(uniq_all)} (product={pa} scratch={sa})")

print(f"files in-week: top-level={len(top)} subagent={len(sub)}")
print(f"active total: top={fmt(sum(s['active_s'] for s in top))} sub={fmt(sum(s['active_s'] for s in sub))}")
print("\n== per project (top-level) ==")
agg = defaultdict(lambda: [0, 0.0, 0])
for s in top:
    a = agg[s["proj"]]
    a[0] += 1; a[1] += s["active_s"]; a[2] += s["n_files"]
for p, (n, a, nf) in sorted(agg.items(), key=lambda kv: -kv[1][1]):
    print(f"{p:60s} n={n:3d} active={fmt(a):>9s} editedfiles={nf}")

print("\n== per day (top-level / subagent) ==")
d1, d2 = defaultdict(float), defaultdict(float)
for s in top:
    for k, v in s["per_day"].items(): d1[k] += v
for s in sub:
    for k, v in s["per_day"].items(): d2[k] += v
for k in sorted(set(d1) | set(d2)):
    print(f"{k}  top={fmt(d1[k]):>9s}  sub={fmt(d2[k]):>9s}")

print("\n== tools (top-level | subagent) ==")
t1, t2 = Counter(), Counter()
for s in top: t1.update(s["tools"])
for s in sub: t2.update(s["tools"])
for name, c in t1.most_common(40):
    print(f"{name:45s} {c:6d} | {t2[name]:6d}")
print("-- subagent-only tools --")
for name, c in t2.most_common(40):
    if name not in t1: print(f"{name:45s} {'':6s} | {c:6d}")

print("\n== top-level sessions ==")
for s in top:
    fp = " ".join(s["first_prompt"].split())[:110]
    print(f"{s['start_wk'][:16]} | act={fmt(s['active_s']):>8s} span={s['span_h']:6.1f}h | msg={s['user_msgs']:3d} | {s['proj'][-34:]:34s} | ew={s['tools'].get('Edit',0)+s['tools'].get('Write',0):4d} f={s['n_files']:3d} | {fp}")

print("\n== jira-ish tokens ==")
pat = re.compile(r"\b[A-Z]{2,10}-\d+\b")
c = Counter()
for s in sessions:
    c.update(pat.findall(s["first_prompt"]))
print(c.most_common(30))

print("\n== models ==")
mm = Counter()
for s in sessions: mm.update(s["models"])
print(mm.most_common())
