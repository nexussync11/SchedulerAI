# LadminAI Appointment — Phase 0 Risk Register

## Confirmed baseline defects

| ID | Defect | Evidence | Severity | Planned treatment |
|---|---|---|---|---|
| R-01 | No collision enforcement | slot method does not query appointments; booking builds but never uses appointment collision data | Critical | Gate 3 lock + post-lock overlap check |
| R-02 | No booking lock | no `FOR UPDATE`, ledger, reservation, or uniqueness protection | Critical | Gate 3 resource/date ledger |
| R-03 | Broken Aura/Apex parameters | Aura call omits required `leadName` | High | Gate 5 replaces call; compatibility contract test |
| R-04 | Blank booking status risk | UI initializes blank status; controller overwrites `Scheduled` with input | High | Gate 2 validated canonical default |
| R-05 | Premature navigation | Aura navigates before booking callback resolves | High | Gate 5 awaits typed success |
| R-06 | Separate Booked By update | `updateBookedBy` runs apart from booking transaction | High | Gate 2 parent adapter in atomic transaction |
| R-07 | Event and appointment not linked | records share contextual values but no durable relationship | Critical | Gate 4 relationship fields/service |
| R-08 | Reschedule handler bulk defect | SOQL/DML and early return occur inside Event loop | Critical | Gate 4 bulk rewrite and 200-Event test |
| R-09 | Broad permissions | `BookingAppointment` grants CRUD, Modify All, View All/Fields | Critical | Gate 7 least-privilege personas |
| R-10 | Incomplete CRUD/FLS | controllers/handlers lack systematic enforcement | Critical | Gates 2–7 security service/user-mode access |
| R-11 | Missing lookup dependencies | `customLookUpController1` and `customLookupResult` absent | High | replace in LWC; exclude broken bundle from package |
| R-12 | Weak availability validation | invalid times/duplicates can be skipped or silently accepted | High | Gate 6 typed validation and uniqueness |
| R-13 | Obsolete communication flows | 3 Obsolete flows reference missing Twilio/email dependencies | Medium | Gate 8 exclude/classify; no Harley deletion |

## Delivery and product risks

| ID | Risk | Likelihood | Impact | Mitigation / exit evidence |
|---|---|---:|---:|---|
| R-14 | Ledger creation race | Medium | High | unique key, duplicate-insert recovery, then `FOR UPDATE` |
| R-15 | Cross-midnight deadlock | Low | High | acquire two date locks in stable sorted order |
| R-16 | Timezone/DST miscalculation | Medium | High | configured timezone, UTC DTOs, DST boundary tests |
| R-17 | Existing overlapping appointments | Unknown | High | pre-migration audit in non-Harley test copy; never silently rewrite |
| R-18 | Existing duplicate availability rows | Unknown | High | audit before making keys unique; remediation script/document |
| R-19 | Unsupported Event lookup packaging | Medium | Medium | validate in scratch org; single-link fallback |
| R-20 | Idempotency key conflicts with legacy data | Low | High | new nullable unique field; populate only on new path |
| R-21 | Legacy and new paths create different outcomes | High during migration | High | compatibility flag, telemetry, regression matrix, staged cutover |
| R-22 | Trigger double-counts one reschedule | High | High | managed Event marker, durable link, lifecycle-owned counters |
| R-23 | Counter lost updates | Medium | Medium | lock/aggregate parent updates or replace with derived/audit model |
| R-24 | Partial availability upserts presented as success | High | High | typed per-row results; all-or-none policy decision |
| R-25 | Subscriber schema blocks packaging | Medium | High | dependency scan and scratch install before package creation |
| R-26 | Harley-specific fields leak into core | Medium | High | adapters and package-boundary scan |
| R-27 | Credential-shaped object fails security review | High | Critical | exclude/quarantine; migrate integrations to Named/External Credentials |
| R-28 | Community/guest exposure | Unknown | Critical | no guest assumption; explicit custom permission and access tests |
| R-29 | Static validation mistaken for runtime proof | Medium | High | gate report labels runtime pending until dev-org execution |
| R-30 | Legacy deletion causes regression | Low | Critical | no deletion in Phase 0; compatibility classification and rollback |
| R-31 | Record/PII enters source or logs | Low | Critical | synthetic test data, secret scan, no org data retrieval, safe logging |
| R-32 | AppExchange global exposure/API review issue | Medium | High | minimize `global`, run AppExchange rules, threat model in Gate 7 |

## Blockers and dependencies

- A scratch org or dedicated non-Harley development org is required for runtime deployment, Apex coverage, packaging validation, and concurrency harness testing.
- Effective Event relationship metadata must be proven in that development environment.
- Existing subscriber duplicates must be assessed before enforcing availability uniqueness.
- Product ownership must approve canonical statuses, package boundary, and Lead-adapter inclusion.
- Exact runtime usage of Aura, screen flow, obsolete flows, and permission assignments is unknown because Gate 0 performed no data or activity queries.

## Safety controls

- No Salesforce deployment in Gate 0.
- No Salesforce org access or data retrieval in Gate 0.
- No credentials, auth material, patient/customer data, files, messages, or records are added.
- All functional source remains unchanged.
- Existing object API names remain unchanged.
