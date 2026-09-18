#!/usr/bin/env bash
# Phase 0 — RSA key pair for the Hightouch service user.
set -euo pipefail

openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out solstice_ht_key.p8 -nocrypt
openssl rsa -in solstice_ht_key.p8 -pubout -out solstice_ht_key.pub

# strip header, footer and newlines from the .pub, then in Snowflake:
# ALTER USER SOLSTICE_HT_SVC SET RSA_PUBLIC_KEY = 'MIIBIjANBgkq...';
