# Runbook

What to check when the activation layer misbehaves, in the order to check it.
Fill in the specifics as you hit each one during the build — a runbook written from
failures you actually caused is worth more than one written from imagination.

---

## Sync failed with an auth error

1. Has the Snowflake service user's key rotated or expired?
2. Does `SOLSTICE_HIGHTOUCH` still hold `SELECT` on the object the model reads?
   Future grants cover new tables, not new schemas — check `GRANT USAGE ON FUTURE SCHEMAS`.
3. Destination side: has the API key been rotated in Klaviyo or the ad platform?

Tell: nobody, if you fix it inside the sync interval. Otherwise the lifecycle owner,
because a missed run means a missed send.

## Sync succeeded but rejected rows

This reports green. It is the failure mode that costs money quietly.

1. Open the sync run and read the row-level errors — they name the field.
2. Is it a shape problem (missing identifier, bad type) or a destination limit
   (batch size, rate limit, plan cap)?
3. Fix shape problems in the dbt model, not in the field mapping. A mapping patch
   fixes one sync; the model fixes every sync that reads it.

Tell: the lifecycle owner if more than a few percent of rows dropped, with the number.

## Audience count dropped unexpectedly

1. Did `dbt build` run? A stale `customer_360` is the most common cause.
2. Did a join key type change upstream? Type mismatches return zero rows silently.
3. Did someone edit the audience? Customer Studio audiences are not covered by Git Sync,
   so there is no diff to read — check the audience's own history.

Tell: whoever owns the campaign, before they notice.

## dbt run failed

1. Which model, and did it fail on a test or on the SQL?
2. If a `unique` test on `person_id` failed, the identity spine has a duplicate —
   do not disable the test to unblock the run. Syncing duplicates to a destination
   is worse than not syncing.
3. Syncs will keep running happily against the last good tables. Decide whether to
   pause them; stale data reaching a journey is how people get emailed about a
   purchase they already made.

## Snowflake credits spiking

1. `SELECT * FROM snowflake.account_usage.warehouse_metering_history` for the last 7 days.
2. Is a sync scheduled more often than the data changes? Hourly on a table dbt builds
   daily is 23 wasted runs.
3. Is the Lightning engine doing full scans because the model has no reliable
   change-detection column?
4. Auto-suspend should be 60 seconds. Confirm nobody raised it.
