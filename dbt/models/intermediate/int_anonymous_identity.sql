-- models/intermediate/int_anonymous_identity.sql
select
    e.anonymous_id,
    min(s.person_id) as person_id
from {{ ref('stg_web_events') }} e
join {{ ref('int_identity_spine') }} s on s.customer_id = e.customer_id
where e.customer_id is not null
group by 1
