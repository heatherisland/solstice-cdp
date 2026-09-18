-- Phase 1 — row counts and the wrinkles that should be there
-- Part of the Solstice CDP capstone build. Fictional brand, synthetic data.

SELECT 'customers' t, COUNT(*) n FROM CUSTOMERS
UNION ALL SELECT 'dupe emails', COUNT(*) FROM (
  SELECT LOWER(TRIM(email)) e FROM CUSTOMERS GROUP BY 1 HAVING COUNT(*) > 1)
UNION ALL SELECT 'orders', COUNT(*) FROM ORDERS
UNION ALL SELECT 'order_items', COUNT(*) FROM ORDER_ITEMS
UNION ALL SELECT 'web_events', COUNT(*) FROM WEB_EVENTS
UNION ALL SELECT 'anon events', COUNT(*) FROM WEB_EVENTS WHERE customer_id IS NULL
UNION ALL SELECT 'email_engagement', COUNT(*) FROM EMAIL_ENGAGEMENT
UNION ALL SELECT 'subscriptions', COUNT(*) FROM SUBSCRIPTIONS;
