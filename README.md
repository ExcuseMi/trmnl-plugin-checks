# trmnl-plugin-checks

One base test suite for any TRMNL plugin repo. A new TRMNL device means rerunning, not rewriting.

## What is checked

| Part | What | Source |
|---|---|---|
| Publishable recipe | 4 views x og_png, og_plus (+portrait), v2 (+portrait): no page errors, no overflow, no clipped or overlapping text; dark mode keeps content; API empty, 500 or reset still draws; every select/boolean option; mock for every request; transform error free and inside 5 s / 128 MB | trmnlp `a publishable recipe` |
| Device sweep | every model TRMNL lists (loaded live), every view, landscape and portrait: draws, no overflow, no page error, no leaked `undefined`/`NaN`/`{{` | `spec/checks_spec.rb` |

Models with the same size and screen classes are drawn once (named together in the check). Models without CSS classes (tidbyt, vestaboard) have no HTML screen and are skipped.

## Data

Only the plugin's own: `custom_fields`, `variables` and time zone from its `.trmnlp.yml`; mocks from its `tests/mocks.json`, else `fixtures/<repo-name>/mocks.json` here (for plugins with none). No mocks: requests answer 599 and the error screens are what is drawn.
A mock file maps url (exact, `*`, or `re:<regexp>`) to `{json|body|status|error}`; `json_file` / `body_file` point at a file inside the plugin.

## Run

```
bin/check ~/workspace/trmnl-xyz-plugin      # repo root or its plugin/ folder; flat layout (settings.yml next to the liquid files) is wrapped into src/
docker pull trmnl/trmnlp                    # update the image
TPC_KEEP=1 bin/check ...                    # keep the temp dir (results.json, console.txt, summary.md)
```

The plugin is copied to a temp dir; nothing is written back. Exit code is the suite's. Output: console tail and a summary (totals, failures grouped by reason), also appended to `$GITHUB_STEP_SUMMARY`. A full run takes minutes (hundreds of renders).

## New device

Nothing to do: `TRMNLP::Testing::DeviceModels` reads trmnl.com/api/models on every run, so the next run sweeps it. A new trmnlp feature arrives with `docker pull`.

## GitHub Actions

| File | Use |
|---|---|
| `.github/workflows/plugin-check.yml` | reusable (`workflow_call`); each plugin repo calls it from its own workflow (`examples/call-plugin-check.yml`: on push, daily, by hand). Results stay in that repo's runs |
| `.github/workflows/self-test.yml` | this repo's own tests (`test/retry_test.rb`) |

GitHub-hosted runners only. A font timeout (slow runner) is retried once; any other failure counts on the first try.

## Pilot (2026-11-16, trmnlp image 5558373f96d8)

| Plugin | Result | Top reasons |
|---|---|---|
| lichess-puzzle | 7 of 474 fail, 7 min | overflow on playdate (400x240) only |
| wikimedia-potd (fixture mocks) | 31 of 486 fail, 12 min | playdate overflow; 8 "fonts did not load within 10s" (looks like a flake) |
| comic-library (flat layout, no mocks) | 9 of 480 fail, 6 min | onyx_boox_go_7 overflow; no mock for its feed URLs |
| comic-library copy with a broken view | 139 of 480 fail | leaked `undefined NaN` and a 5000px bar are caught |

Comic Library deploys with `scripts/upload_plugin.py` from a flat `plugin/` folder (no `src/`); bin/check wraps it into `src/` in the copy and never touches the repo.
