-- Phase 2 - the model layer. Lean parent, related models, pre-aggregates.
-- "A good schema shows the right data, not all of it."

-- models/marts/customer_core.sql  --  THE PARENT MODEL
-- Lean on purpose. "A bloated table is a slow table. Keep your parent model
-- lean by moving rarely used columns into related models." Every audience
-- starts here, so every column you add is paid for in every preview, every
-- size calculation and every sync.
--
-- The test for a column belonging here: would a marketer filter on it in most
-- audiences? Identity, consent, and the two derived states do. Order counts,
-- revenue and engagement rates do not -- they live in related models.

select
    s.person_id,
    s.email,
    s.first_name,
    s.last_name,
    s.phone,
    s.state,
    s.skin_type,
    s.acquisition_channel,
    s.marketing_consent,
    s.first_signup_date,
    t.lifecycle_tier,
    t.churn_risk
from {{ ref('int_identity_spine') }} s
left join {{ ref('int_lifecycle_tiers') }} t using (person_id)
qualify row_number() over (partition by s.person_id order by s.customer_id) = 1

-- models/marts/customer_purchase_stats.sql  --  RELATED MODEL, 1:1 on person_id
-- Everything a marketer filters on occasionally rather than constantly.
select
    person_id,
    order_count,
    net_revenue,
    aov,
    first_order_date,
    last_order_date,
    days_since_last_order,
    median_days_between_orders,
    top_category,
    rfm_r, rfm_f, rfm_m, rfm_score
from {{ ref('int_order_facts') }}

-- models/marts/customer_engagement_stats.sql  --  RELATED MODEL, 1:1 on person_id
select
    person_id,
    email_opens_90d,
    email_clicks_90d,
    last_email_click_at,
    unsubscribed,
    sessions_30d,
    product_views_30d,
    carts_30d,
    last_web_event_at
from {{ ref('int_engagement_rollup') }}

-- The course's own examples of pre-aggregated tables, built because the
-- audience builder should never aggregate millions of event rows on the fly:
--   "Pre-aggregate heavy metrics into dedicated tables."

-- models/marts/user_last_90d_purchases.sql
select
    person_id,
    count(*)                      as orders_90d,
    sum(line_total)               as revenue_90d,
    max(order_date)               as last_order_date_90d,
    array_agg(distinct category)  as categories_90d
from {{ ref('fct_order_items') }}
where order_date >= dateadd(day, -90, current_date())
group by 1

-- models/marts/user_pageview_counts_30d.sql
select
    person_id,
    count(*)                                             as pageviews_30d,
    count(distinct date_trunc('day', event_at))          as active_days_30d,
    count_if(event_name = 'product_viewed')              as product_views_30d,
    count_if(event_name = 'add_to_cart')                 as carts_30d
from {{ ref('fct_web_events') }}
where event_at >= dateadd(day, -30, current_timestamp())
group by 1
