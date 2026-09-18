-- Phase 6b — normalized, hashed identifiers for ad platform match.
-- Built in the model, not in the sync, so match rate is debuggable.

-- What the destination should receive, built in the model, not in the sync
select
    person_id,
    sha2(lower(trim(email)), 256)                              as email_sha256,
    -- E.164, digits only, country code included; nulls out anything malformed
    case
        when regexp_count(regexp_replace(phone, '[^0-9]', ''), '.') between 11 and 15
        then sha2(regexp_replace(phone, '[^0-9]', ''), 256)
    end                                                        as phone_sha256,
    lower(trim(first_name))                                    as fn_norm,
    lower(trim(last_name))                                     as ln_norm,
    upper(trim(state))                                         as st_norm
from {{ ref('customer_360') }}
where marketing_consent = true
