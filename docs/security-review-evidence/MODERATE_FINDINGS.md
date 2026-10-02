# Moderate `ProtectSensitiveData` Findings

The final AppExchange ruleset reports seven Moderate findings and no Critical or High findings. Each Moderate is a name-based scanner match. None of the seven fields stores an authentication secret, credential, encryption key, session identifier, or access token.

| # | Field | Actual purpose | Disposition |
|---|---|---|---|
| 1 | `LadminAI_Appointment_Settings__mdt.LadminAI_OpenAI_Named_Credential__c` | Stores the **developer name/reference** of the Salesforce Named Credential to invoke. It never stores the OpenAI API key or authorization header. The secret is populated by the subscriber in External Credential setup. | False positive; retain the descriptive API name. |
| 2 | `Resource_Availability__c.Override_Key__c` | Deterministic external-ID/uniqueness value used to upsert a date override without creating duplicates. | False positive; operational record key, not an auth token. |
| 3 | `Resource_Availability__c.Resource_Day_Key__c` | Composite scheduling key used to associate/deduplicate a resource and weekday/day definition. | False positive; scheduling identifier. |
| 4 | `Scheduler_Location_Resource__c.Location_Resource_Key__c` | Unique composite external ID for the Location–Resource association. | False positive; relationship identity. |
| 5 | `ServiceAppointment__c.LadminAI_Idempotency_Key__c` | Client/request idempotency value used to prevent duplicate appointment creation when the same booking request is retried. It confers no authority and cannot authenticate a user. | False positive; request deduplication identifier. |
| 6 | `Service_Location_Eligibility__c.Eligibility_Key__c` | Unique composite identifier for a Service–Location eligibility rule. | False positive; relationship identity. |
| 7 | `Service_Resource_Eligibility__c.Eligibility_Key__c` | Unique composite identifier for a Service–Resource eligibility rule. | False positive; relationship identity. |

## Reviewer verification

1. Inspect the field metadata referenced by `artifacts/CodeAnalyzerReport.json`.
2. Trace the fields' Apex usage. Values are constructed from business-record identifiers or configuration references; they are not read as authorization material.
3. Inspect the Named/External Credential metadata. No secret is present in source control or package metadata.
4. Confirm no documentation or test fixture contains an actual API key.

Renaming these public API fields solely to suppress a heuristic would introduce needless schema churn and would not improve security. The findings should therefore be documented, not hidden.
