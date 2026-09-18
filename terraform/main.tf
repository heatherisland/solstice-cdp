# Phase 8 — the provider is Speakeasy-generated, not first-party.
# Verify the current registry address and supported resources before relying on it.

terraform {
  required_providers {
    hightouch = {
      source  = "<verify the current registry address>"
      version = "~> 4.0"
    }
  }
}

provider "hightouch" {
  api_key = var.hightouch_api_key
}
