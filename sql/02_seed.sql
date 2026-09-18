-- Phase 1 — synthetic source data, including the duplicates and anonymous events
-- Part of the Solstice CDP capstone build. Fictional brand, synthetic data.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SOLSTICE_WH;
USE SCHEMA SOLSTICE.RAW;

CREATE OR REPLACE TABLE PRODUCTS AS
SELECT
  'prod_' || LPAD(n::string, 4, '0') AS product_id,
  'SS-'   || LPAD(n::string, 4, '0') AS sku,
  GET(ARRAY_CONSTRUCT('Cleanser','Serum','Moisturizer','SPF','Toner','Mask','Eye Cream','Oil'),
      MOD(n, 8))::string
    || ' ' ||
  GET(ARRAY_CONSTRUCT('Calm','Glow','Renew','Bright','Barrier','Hydra'), MOD(n, 6))::string
                                     AS product_name,
  GET(ARRAY_CONSTRUCT('cleanse','treat','moisturize','protect'), MOD(n, 4))::string AS category,
  ROUND(UNIFORM(14, 96, RANDOM()) + 0.99, 2) AS price,
  MOD(n, 3) = 0                      AS subscription_eligible
FROM (SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 40)));

CREATE OR REPLACE TABLE CUSTOMERS AS
WITH g AS (SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 5000))),
base AS (
  SELECT n,
    GET(ARRAY_CONSTRUCT('ava','noah','mia','liam','zoe','ethan','luna','kai',
                        'nora','isla','owen','maya'), UNIFORM(0, 11, RANDOM()))::string AS fn,
    GET(ARRAY_CONSTRUCT('reyes','okafor','tran','silva','haddad','novak',
                        'ibrahim','petrov','nakamura','moreau'), UNIFORM(0, 9, RANDOM()))::string AS ln
  FROM g
)
SELECT
  'cust_' || LPAD(n::string, 6, '0')                          AS customer_id,
  fn                                                          AS first_name,
  ln                                                          AS last_name,
  fn || '.' || ln || n || '@solstice-test.com'                AS email,
  '+1' || UNIFORM(2000000000, 9899999999, RANDOM())::string   AS phone,
  GET(ARRAY_CONSTRUCT('TX','CA','NY','FL','IL','WA','GA','CO','AZ','NC'),
      UNIFORM(0, 9, RANDOM()))::string                        AS state,
  DATEADD(day, -UNIFORM(1, 900, RANDOM()), CURRENT_DATE())::date AS signup_date,
  UNIFORM(1, 10, RANDOM()) <= 7                               AS marketing_consent,
  GET(ARRAY_CONSTRUCT('oily','dry','combination','sensitive','normal'),
      UNIFORM(0, 4, RANDOM()))::string                        AS skin_type,
  GET(ARRAY_CONSTRUCT('paid_social','organic_search','paid_search','email','referral','influencer'),
      UNIFORM(0, 5, RANDOM()))::string                        AS acquisition_channel
FROM base;

-- The duplicates. Same human, second account, dirty email string.
INSERT INTO CUSTOMERS
SELECT
  'cust_9' || LPAD(ROW_NUMBER() OVER (ORDER BY customer_id)::string, 5, '0'),
  first_name, last_name,
  '  ' || UPPER(email) || ' ',
  phone, state,
  DATEADD(day, UNIFORM(1, 60, RANDOM()), signup_date)::date,
  marketing_consent, skin_type, 'referral'
FROM CUSTOMERS SAMPLE (3);

CREATE OR REPLACE TABLE ORDERS AS
WITH c AS (
  SELECT customer_id, signup_date, ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
  FROM CUSTOMERS
),
picks AS (
  SELECT SEQ4() + 1 AS n,
         1 + FLOOR(POWER(UNIFORM(0::float, 1::float, RANDOM()), 2.2)
                   * (SELECT COUNT(*) FROM CUSTOMERS)) AS rn
  FROM TABLE(GENERATOR(ROWCOUNT => 14000))
)
SELECT
  'ord_' || LPAD(p.n::string, 7, '0') AS order_id,
  c.customer_id,
  DATEADD(day, UNIFORM(0, GREATEST(DATEDIFF(day, c.signup_date, CURRENT_DATE()), 1), RANDOM()),
          c.signup_date)::date        AS order_date,
  GET(ARRAY_CONSTRUCT('completed','completed','completed','completed','refunded','cancelled'),
      UNIFORM(0, 5, RANDOM()))::string AS status,
  GET(ARRAY_CONSTRUCT('web','web','web','ios','retail'), UNIFORM(0, 4, RANDOM()))::string AS channel,
  IFF(UNIFORM(1, 10, RANDOM()) <= 3,
      GET(ARRAY_CONSTRUCT('WELCOME15','GLOW20','BFCM30','WINBACK25'),
          UNIFORM(0, 3, RANDOM()))::string, NULL) AS discount_code
FROM picks p JOIN c ON c.rn = p.rn;

CREATE OR REPLACE TABLE ORDER_ITEMS AS
WITH k AS (SELECT SEQ4() + 1 AS i FROM TABLE(GENERATOR(ROWCOUNT => 4))),
prod AS (SELECT product_id, price, ROW_NUMBER() OVER (ORDER BY product_id) AS rn FROM PRODUCTS),
lines AS (
  SELECT o.order_id, k.i,
         1 + MOD(ABS(HASH(o.order_id, k.i)), 40)    AS prn,
         1 + MOD(ABS(HASH(o.order_id, k.i, 3)), 2)  AS qty
  FROM ORDERS o
  JOIN k ON k.i <= 1 + MOD(ABS(HASH(o.order_id)), 4)
)
SELECT l.order_id || '_' || l.i AS order_item_id,
       l.order_id, p.product_id, l.qty AS quantity, p.price AS unit_price
FROM lines l JOIN prod p ON p.rn = l.prn;

CREATE OR REPLACE TABLE WEB_EVENTS AS
WITH c AS (SELECT customer_id, ROW_NUMBER() OVER (ORDER BY customer_id) AS rn FROM CUSTOMERS),
g AS (
  SELECT SEQ4() + 1 AS n,
         1 + FLOOR(POWER(UNIFORM(0::float, 1::float, RANDOM()), 1.8)
                   * (SELECT COUNT(*) FROM CUSTOMERS)) AS rn,
         UNIFORM(1, 100, RANDOM()) AS roll
  FROM TABLE(GENERATOR(ROWCOUNT => 120000))
)
SELECT
  'evt_' || LPAD(g.n::string, 8, '0')                          AS event_id,
  'anon_' || LPAD(g.rn::string, 6, '0') || '_' || MOD(g.n, 3)  AS anonymous_id,
  IFF(g.roll <= 65, c.customer_id, NULL)                       AS customer_id,
  GET(ARRAY_CONSTRUCT('page_view','page_view','page_view','product_viewed',
                      'add_to_cart','checkout_started','search'),
      UNIFORM(0, 6, RANDOM()))::string                         AS event_name,
  DATEADD(second, -UNIFORM(0, 15552000, RANDOM()), CURRENT_TIMESTAMP()) AS event_at,
  'prod_' || LPAD((1 + MOD(ABS(HASH(g.n)), 40))::string, 4, '0') AS product_id,
  GET(ARRAY_CONSTRUCT('google','meta','tiktok','klaviyo','direct'),
      UNIFORM(0, 4, RANDOM()))::string                         AS utm_source,
  GET(ARRAY_CONSTRUCT('always_on','spring_glow','bfcm','winback','none'),
      UNIFORM(0, 4, RANDOM()))::string                         AS utm_campaign
FROM g JOIN c ON c.rn = g.rn;

-- Keyed on email only. No customer_id. This is what an ESP export looks like.
CREATE OR REPLACE TABLE EMAIL_ENGAGEMENT AS
WITH c AS (SELECT email, ROW_NUMBER() OVER (ORDER BY email) AS rn FROM CUSTOMERS),
g AS (
  SELECT SEQ4() + 1 AS n,
         1 + MOD(ABS(HASH(SEQ4())), (SELECT COUNT(*) FROM CUSTOMERS)) AS rn
  FROM TABLE(GENERATOR(ROWCOUNT => 60000))
)
SELECT
  'eml_' || LPAD(g.n::string, 8, '0') AS engagement_id,
  c.email,
  GET(ARRAY_CONSTRUCT('delivered','delivered','open','open','click','unsubscribe'),
      UNIFORM(0, 5, RANDOM()))::string AS event_type,
  GET(ARRAY_CONSTRUCT('welcome_1','welcome_2','abandoned_cart','winback_30',
                      'newsletter','replenishment'), UNIFORM(0, 5, RANDOM()))::string AS campaign_name,
  DATEADD(second, -UNIFORM(0, 15552000, RANDOM()), CURRENT_TIMESTAMP()) AS event_at
FROM g JOIN c ON c.rn = g.rn;

CREATE OR REPLACE TABLE SUBSCRIPTIONS AS
WITH c AS (SELECT customer_id, signup_date, ROW_NUMBER() OVER (ORDER BY customer_id) AS rn FROM CUSTOMERS),
g AS (
  SELECT SEQ4() + 1 AS n,
         1 + FLOOR(POWER(UNIFORM(0::float, 1::float, RANDOM()), 3.0)
                   * (SELECT COUNT(*) FROM CUSTOMERS)) AS rn
  FROM TABLE(GENERATOR(ROWCOUNT => 900))
)
SELECT
  'sub_' || LPAD(g.n::string, 6, '0') AS subscription_id,
  c.customer_id,
  'prod_' || LPAD((1 + MOD(ABS(HASH(g.n)), 40))::string, 4, '0') AS product_id,
  GET(ARRAY_CONSTRUCT('active','active','active','paused','cancelled'),
      UNIFORM(0, 4, RANDOM()))::string AS status,
  DATEADD(day, UNIFORM(0, 200, RANDOM()), c.signup_date)::date AS started_at,
  DATEADD(day, UNIFORM(1, 45, RANDOM()), CURRENT_DATE())::date AS next_ship_date
FROM g JOIN c ON c.rn = g.rn;
