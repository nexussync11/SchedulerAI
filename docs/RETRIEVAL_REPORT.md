# Retrieval Report

## Source

- Salesforce org alias: `harley-partial`
- Org type: Partial Copy sandbox
- Salesforce API version: 67.0
- Retrieval method: targeted Salesforce Metadata API retrieval using `manifest/package.xml`
- Retrieval date: 2026-07-28

## Discovery

Metadata names were searched for Appointment, Booking, Calendar, Availability, Resource, Scheduler, Doctor, Location, ServiceAppointment, ServiceResource, AssignedResource, Mapping, Tracking, and Reschedule.

The known classes were verified first. Source and custom metadata references then identified the `CreateReferralCMP` booking entry point, supporting lookup/event Aura bundles, `Component_Config__mdt`, and standard-object custom fields.

## Security review

- No Salesforce records were queried or retrieved.
- `.sf`, `.sfdx`, local authentication files, and environment files are excluded by `.gitignore`.
- No API keys, OAuth tokens, certificates, private keys, or genuine credentials were found in retrieved source.
- Email addresses found by scanning are synthetic `example.com` values in Apex tests.
- `RequestResource__c` contains metadata definitions for fields named `Password__c`, `Authentication__c`, and `Username__c`; these are schema definitions only. No field records or credential values were retrieved.
- The custom metadata record contains component configuration and an expiry timestamp, not a secret.

## Missing or external dependencies

- Standard Salesforce objects used by the application include Lead, Event, User, Account, Contact, and Opportunity.
- Several historical/obsolete workflow-style flows reference organization-specific Lead, Account, Opportunity, Event, and SMS-related fields. They were preserved as retrieved; a deployment to another org would require validating those org-level field dependencies.
- No appointment/referral Quick Action metadata was identifiable by its metadata name, although `CreateReferralCMP` declares Lightning quick-action and page interfaces.
- No scheduling-specific Lightning application or FlexiPage was identifiable from metadata naming/dependency discovery.

## Safeguards

- No deployment command was run.
- No create, update, delete, or destructive Salesforce operation was run.
- No Salesforce metadata or data was modified.
- The retrieved source was not refactored or modernized.

