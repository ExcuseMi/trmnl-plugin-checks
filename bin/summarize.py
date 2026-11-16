#!/usr/bin/env python3
"""Turn rspec's results.json into a short summary: totals and failures grouped by reason."""
import collections, json, re, sys

path, name = sys.argv[1], sys.argv[2]
data = json.load(open(path))
ex = data["examples"]
failed = [e for e in ex if e["status"] == "failed"]
print(f"### {name}: {'FAIL' if failed else 'PASS'}")
print(f"{len(ex)} checks, {len(failed)} failed, {sum(e['status'] == 'pending' for e in ex)} pending, "
      f"{data['summary']['duration']:.0f} s\n")
if failed:
    def reason(e):
        msg = (e["exception"]["message"] or "").strip().splitlines()
        first = msg[0] if msg else e["exception"]["class"]
        return re.sub(r"#<[^>]*>", "<screen>", first)[:200]
    groups = collections.defaultdict(list)
    for e in failed:
        groups[reason(e)].append(e["description"])
    print("| Count | Reason | First failing check |\n|---|---|---|")
    for r, d in sorted(groups.items(), key=lambda kv: -len(kv[1]))[:10]:
        print(f"| {len(d)} | {r.replace('|', '/')} | {d[0][:90].replace('|', '/')} |")
