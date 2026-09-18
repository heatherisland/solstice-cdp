#!/usr/bin/env bash
# Phase 8 — read the workspace before you write to it.
# 200 requests per 10 seconds per workspace.
set -euo pipefail

export HT_KEY=...
curl -s https://api.hightouch.com/api/v1/sources \\
  -H "Authorization: Bearer $HT_KEY" | jq '.data[] | {id, name, type}'

curl -s https://api.hightouch.com/api/v1/syncs \\
  -H "Authorization: Bearer $HT_KEY" | jq '.data[] | {id, slug, model_id, destination_id, schedule}'
