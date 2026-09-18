-- models/intermediate/int_identity_spine.sql
with normalized as (
    select
        customer_id,
        lower(trim(email)) as email_norm,
        first_name, last_name, phone, state,
        skin_type, acquisition_channel, marketing_consent,
        signup_date
    from {{ ref('stg_customers') }}
    where email is not null
),

canonical as (
    select
        email_norm,
        min(customer_id)  as person_id,          -- deterministic survivor
        min(signup_date)  as first_signup_date,
        count(*)          as account_count,
        max(marketing_consent) as marketing_consent  -- most permissive wins
    from normalized
    group by 1
)

select
    n.customer_id,
    c.person_id,
    c.email_norm as email,
    n.first_name, n.last_name, n.phone, n.state,
    n.skin_type, n.acquisition_channel,
    c.marketing_consent,
    c.first_signup_date,
    c.account_count
from normalized n
join canonical c using (email_norm)
