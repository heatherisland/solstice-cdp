#!/usr/bin/env bash
# Phase 0 - RSA key pair for the Hightouch service user.
# Snowflake service users cannot authenticate with a password, so this is the
# only way in. Run it once; Phase 2 generates a second pair for dbt.
set -euo pipefail

# Generate outside the repo. A private key in a folder you will later make
# public is the kind of mistake that is only funny when it happens to someone else.
mkdir -p ~/.ssh

openssl genrsa 2048 \\
  | openssl pkcs8 -topk8 -inform PEM -out ~/.ssh/solstice_ht_key.p8 -nocrypt
openssl rsa -in ~/.ssh/solstice_ht_key.p8 -pubout -out ~/.ssh/solstice_ht_key.pub
chmod 600 ~/.ssh/solstice_ht_key.p8

# Snowflake wants the key as one unbroken string: no PEM header, footer or
# newlines. This strips all three and puts the result on the clipboard.
grep -v '^-' ~/.ssh/solstice_ht_key.pub | tr -d '\\n' | pbcopy
# Linux: ... | xclip -selection clipboard

# The fingerprint, to check against Snowflake's RSA_PUBLIC_KEY_FP in the next step.
openssl rsa -pubin -in ~/.ssh/solstice_ht_key.pub -outform DER \\
  | openssl dgst -sha256 -binary | openssl enc -base64
