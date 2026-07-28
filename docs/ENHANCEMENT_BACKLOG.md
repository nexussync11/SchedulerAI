# Enhancement Backlog

No enhancements are implemented on this branch.

## Phase 0 — urgent stabilization

1. Enforce atomic server-side overlap checks and slot locking.
2. Repair and contract-test `CreateReferralCMP` ↔ `convertToDateTime` parameters/status/name.
3. Retrieve or replace missing `customLookUpController1` and `customLookupResult`.
4. Make booking success/error await the server response; remove premature navigation and separate Lead update.
5. Bulkify Event reschedule handler and scope it to scheduler Events.
6. Add CRUD/FLS/user-mode enforcement and least-privilege permission sets.
7. Establish canonical appointment status values and transition rules.
8. Add high-risk booking, concurrency, rollback, bulk, and security tests.
9. Validate start/end/break rules and enforce unique schedule/day keys.
10. Confirm/disable obsolete SMS/email automation and document missing integration dependencies.

## Phase 1 — usability and reliability

- Guided reschedule and cancellation journeys.
- Synchronize Event and custom appointment with a durable relationship.
- Resource/location/specialty filtering and availability exceptions.
- Configurable duration, buffers, lead time, booking horizon, and capacity.
- User-facing error messages, retry, booking confirmation, and audit trail.
- Time-zone-aware model with DST tests.
- Operational dashboards and reconciliation reports.
- Mobile-first availability editor and accessible booking experience.

## Phase 2 — architecture modernization

- Consolidate booking into a domain service with typed request/response DTOs.
- Replace Aura with Lightning Web Components.
- Introduce canonical Appointment, Resource, Availability, Location, and Service models.
- Use platform events/outbox pattern for notifications and integrations.
- Replace plaintext integration configuration with Named/External Credentials.
- Retire obsolete flows and version active automation.
- Add CI validation, static analysis, test data factory, and deployment runbook.
- Evaluate Salesforce Scheduler/Field Service standard objects versus custom clones.

## Phase 3 — AI capabilities

- Ranked resource/slot recommendations with explainable constraints.
- No-show probability and intervention recommendations.
- Waitlist matching and automatic backfill suggestions.
- Demand forecasting and staffing/availability recommendations.
- Natural-language booking assistant with strict authorization and confirmation.
- Model monitoring, bias/privacy review, human override, and audit logging.

## Phase 4 — productization/AppExchange readiness

- Namespace/package architecture and subscriber-safe configuration.
- Permission-set groups and least-privilege personas.
- Multi-org/multi-clinic configuration, localization, and time zones.
- Security review readiness, threat model, privacy controls, and data retention.
- Upgrade-safe metadata, feature flags, telemetry, support diagnostics.
- Comprehensive installation, migration, rollback, and admin documentation.
- Licensing, limits, performance benchmarks, and accessibility certification.

## Top ten recommended enhancements

The Phase 0 numbered items are the recommended top ten, in priority order.

