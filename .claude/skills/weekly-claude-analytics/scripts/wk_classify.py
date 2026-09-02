#!/usr/bin/env python3
import json, re, os
from collections import defaultdict, Counter

S = json.load(open(os.environ.get("WK_OUT", "/tmp/wk_sessions.json")))
top = [s for s in S if not s["sub"]]

def fmt(sec): return f"{int(sec)//3600}h {int(sec)%3600//60:02d}m"

CRON_MARKS = ["브리핑 시스템의 이벤트 확인기", "브리핑 시스템의 이벤트 수집기",
              "시장을 오래 지켜본 담백한 선배"]
# Slash-command / housekeeping sessions that carry no project work. Keep this in
# sync: a new auto-run skill (e.g. weekly-newsletter) otherwise lands in "real".
META_MARKS = ["/clear", "/effort", "/login", "/status", "/model",
              "weekly-claude-analytics", "weekly-newsletter", "daily-work-logger"]


def cls(s):
    p = s["first_prompt"]
    if p.startswith("<teammate-message"): return "worker"
    if any(m in p for m in CRON_MARKS): return "cron"
    if s["user_msgs"] <= 4 and s["active_s"] < 600 and any(m in p for m in META_MARKS): return "meta"
    return "real"

buckets = defaultdict(list)
for s in top: buckets[cls(s)].append(s)

SCRATCH_RE = re.compile(r"^(/private)?/tmp/")


def _files(v):
    """Union, not sum. Summing per-session n_files double-counts any file edited
    in more than one session — the exact sum/union confusion wk_analytics.py
    warns about for s["files"]. Use the untruncated _all_files set."""
    u = set()
    for x in v:
        u.update(x.get("_all_files") or x.get("files") or [])
    scr = {f for f in u if SCRATCH_RE.match(f)}
    return len(u) - len(scr), len(scr)


print("=== classification (top-level) ===")
for k in ["real", "worker", "cron", "meta"]:
    v = buckets[k]
    prod, scr = _files(v)
    print(f"{k:8s} n={len(v):3d} active={fmt(sum(x['active_s'] for x in v)):>9s} "
          f"E+W={sum(x['tools'].get('Edit',0)+x['tools'].get('Write',0) for x in v):5d} "
          f"files={prod + scr} (product={prod} scratch={scr})")

print("\n=== REAL sessions ===")
for s in sorted(buckets["real"], key=lambda x: x["start_wk"]):
    t = s["tools"]
    pw = sum(c for n, c in t.items() if n.startswith("mcp__plugin_playwright"))
    print(f"\n{s['start_wk'][:16]} | {s['proj'].replace('-Users-iseong-','')} | act={fmt(s['active_s'])} span={s['span_h']}h msgs={s['user_msgs']}")
    print(f"   E{t.get('Edit',0)}/W{t.get('Write',0)} files={s['n_files']} Bash={t.get('Bash',0)} Read={t.get('Read',0)} pw={pw} "
          f"Agent={t.get('Agent',0)} Workflow={t.get('Workflow',0)} Send={t.get('SendMessage',0)} Ask={t.get('AskUserQuestion',0)} "
          f"Task={t.get('TaskCreate',0)}/{t.get('TaskUpdate',0)} Web={t.get('WebSearch',0)}/{t.get('WebFetch',0)} Skill={t.get('Skill',0)}")
    print(f"   > {' '.join(s['first_prompt'].split())[:200]}")
    rp = ' '.join((s.get('real_prompt') or '').split())
    if rp and rp[:200] != ' '.join(s['first_prompt'].split())[:200]:
        print(f"   >>real: {rp[:300]}")
    print(f"   files: {', '.join(f.split('/')[-1] for f in s['files'][:14])}")

print("\n=== per-day by class ===")
d = defaultdict(lambda: defaultdict(float))
for s in top:
    for k, v in s["per_day"].items(): d[k][cls(s)] += v
for day in sorted(d):
    row = d[day]
    print(day, " ".join(f"{k}={fmt(row.get(k,0))}" for k in ["real","worker","cron","meta"]), "TOTAL=", fmt(sum(row.values())))

print("\n=== per-project by class ===")
pp = defaultdict(lambda: defaultdict(lambda: [0,0.0]))
for s in top:
    e = pp[s["proj"].replace("-Users-iseong-","")][cls(s)]
    e[0]+=1; e[1]+=s["active_s"]
for p, row in sorted(pp.items(), key=lambda kv: -sum(v[1] for v in kv[1].values())):
    tot = sum(v[1] for v in row.values()); n = sum(v[0] for v in row.values())
    print(f"{p:38s} n={n:3d} act={fmt(tot):>9s} :: " + " ".join(f"{k}({row[k][0]},{fmt(row[k][1])})" for k in row))

# W35: the flat model table lies — worker sessions are always sonnet-4-6, so a
# 10x worker-volume swing reads as "the main model changed". Split by class.
print("\n=== models by class ===")
sub = [x for x in S if x["sub"]]
mc = defaultdict(Counter)
for x in top: mc[cls(x)].update(x["models"])
for x in sub: mc["subagent"].update(x["models"])
for k in ["real", "worker", "cron", "meta", "subagent"]:
    v = mc[k]
    if not v: continue
    tot = sum(v.values())
    print(f"{k:9s} n={tot:6d} :: " + "  ".join(f"{m}={c}({100*c/tot:.0f}%)" for m, c in v.most_common()))
allm = Counter()
for x in S: allm.update(x["models"])
tot = sum(allm.values())
print("ALL      n=%d :: " % tot + "  ".join(f"{m}={c}({100*c/tot:.0f}%)" for m, c in allm.most_common()))
