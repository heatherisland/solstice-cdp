-- Phase 9 — activation telemetry, queried from the same warehouse as the customer data
-- Part of the Solstice CDP capstone build. Fictional brand, synthetic data.

-- Which destinations reject the most rows, last 7 days?
select destination, error_reason, count(*) as rows_rejected
from solstice.hightouch_audit.sync_results
where status = 'rejected'
  and created_at > dateadd(day, -7, current_timestamp())
group by 1, 2
order by 3 desc;
