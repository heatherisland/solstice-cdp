-- Phase 9 - querying audience membership history.

-- Audience Snapshots write one row per enter and exit event, so membership
-- becomes history you can query rather than a number that moves silently.
-- Requires the Lightning engine and a writable warehouse.

-- How long do people stay in the at-risk audience before they leave it?
with spans as (
  select
      user_id,
      timestamp as entered_at,
      lead(timestamp) over (partition by user_id order by timestamp) as exited_at,
      event
  from solstice.hightouch_planner.audience_membership
  where audience_id = '<your audience id>'
)
select
    date_trunc('week', entered_at)                          as cohort_week,
    count(*)                                                as entered,
    avg(datediff('day', entered_at, exited_at))             as avg_days_in_audience
from spans
where event = 'enter'
group by 1
order by 1 desc
