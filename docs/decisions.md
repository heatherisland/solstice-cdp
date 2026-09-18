# Decisions

Three choices in this build required judgment rather than syntax. Each one has a
defensible answer and a defensible opposite, which is what makes them worth writing
down — a client is buying the reasoning, not the SQL.

---

## 1. Which record survives an identity merge, and what happens to consent

**The situation.** About 3% of the customer base has two accounts under the same email
address, differing only by casing and whitespace. `int_identity_spine` collapses them
to one `person_id`.

**What this build does.** `min(customer_id)` survives — deterministic and reproducible
across runs, which matters more than picking the "best" record. Consent takes
`max(marketing_consent)`: the most permissive flag across the merged accounts wins.

**The opposite case.** Taking `min(marketing_consent)` instead — the most restrictive
flag wins — is what most legal teams will ask for, on the reasoning that a person who
opted out anywhere has opted out. The counter-argument is that a second account created
*after* an opt-out is usually a re-subscribe, and treating it as a continued opt-out
loses a customer who asked to hear from you.

**What to actually do.** Ask. Write the answer down with a date and who approved it.
This is not a choice a data engineer should make alone, and the document is the
deliverable.

<!-- Your notes from the build: -->

---

## 2. Why churn risk is relative to each customer's own cadence

**The situation.** A single "lapsed at 90 days" threshold treats a monthly
replenishment buyer and an annual gift buyer identically. One of them is in trouble
at 90 days; the other is behaving normally.

**What this build does.** Churn risk compares `days_since_last_order` to that person's
own `median_days_between_orders` — high past 2× their cadence, medium past 1.5×.
Customers with fewer than two orders get null rather than a guess.

**The cost.** It needs at least two orders to say anything, so it's silent on exactly
the customers a first-purchase program targets. Lifecycle tier still covers those; the
two fields do different jobs and shouldn't be collapsed.

<!-- Your notes from the build: -->

---

## 3. Why discount-dependent customers are excluded from the discount branch

**The situation.** The winback journey can offer a discount. The Discount dependence
trait measures what share of a customer's orders carried a discount code.

**What this build does.** Customers with high discount dependence get the winback
message without the discount.

**The reasoning.** It is a margin argument, not a data argument. A customer who only
ever buys on promotion is not being reactivated by another promotion — they are being
paid to do what they were going to do anyway, at a worse unit economic. The discount
budget does more work aimed at customers who normally pay full price and have lapsed.

**The risk.** You will suppress some genuine reactivations. The holdout split is how
you find out whether that trade is worth it, which is the reason the split exists.

<!-- Your notes from the build: -->
