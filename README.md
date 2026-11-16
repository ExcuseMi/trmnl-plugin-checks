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
| `.github/workflows/plugin-check.yml` | reusable (`workflow_call`); a plugin repo calls it, see `examples/call-plugin-check.yml` |
| `.github/workflows/daily.yml` | 04:17 UTC matrix over the public repos in `plugins.txt`; outcome only in the run and job summaries |

GitHub-hosted runners only. The reusable workflow needs this repo readable by the caller (same org, or public).
