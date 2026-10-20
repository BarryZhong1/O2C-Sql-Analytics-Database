# O2C Process Policy and SLA Context

This file is intentionally simple for the MVP. It provides business context that the agent can retrieve while investigating O2C performance.

## Order processing

Orders should move from order entry to shipment without unnecessary waiting. The existing analytics database measures order-to-ship cycle time and whether shipment met the requested ship date.

A late shipment is an operational exception that should be investigated before attributing it to a specific cause. Potential drivers such as customer segment, channel, inventory constraints, or workload require supporting data.

## Delivery

On-time delivery is defined using promised delivery timestamp versus actual delivery timestamp. Pending deliveries should not be treated as late unless the promised date has passed and the business rule explicitly defines them that way.

## Billing

Invoices are generated after shipment in the current O2C model. Ship-to-invoice delay is therefore a measurable administrative stage in the cash-conversion path.

## Collections

Customer payment terms vary by account. Payment performance should be interpreted against invoice due date and customer terms rather than by raw payment date alone.

Accounts-receivable and collection recommendations are decision support only. The agent may identify high-risk or overdue patterns, but it may not change credit limits, send collection notices, or modify payment terms.

## Process improvement guardrail

A descriptive bottleneck does not prove root cause. The agent should label:
- measured facts as observations;
- plausible explanations as hypotheses;
- what-if inputs as assumptions.

A scenario result estimates the impact if the assumed stage-time improvement is achieved. It does not guarantee that a specific intervention will achieve that improvement.

## Human approval boundary

The system may analyze, retrieve policy, simulate, compare options, and draft recommendations.

The system may not:
- alter orders, invoices, payments, customer credit limits, or inventory;
- contact customers or suppliers;
- commit spending;
- change an SLA or policy;
- implement a process change

without explicit human approval outside this MVP.
