# LadminAI Appointment Scheduler — Security Review Evidence

Evidence baseline: Git commit `6e2cc33d440467d88b4e7a9315588823556947a9` and managed 2GP beta `1.0.0.6` (`04tOS00000MJ0ndYAD`) in package `0HoOS00000003Nh0AI`.

This folder is the reviewer-facing index for the Appointment Scheduler product only. It does not describe or include LadminAI Data Search, LadminAI Lead Balancer, the legacy LadminAI package, or Harley metadata.

## Evidence index

| Evidence | Location | Result / purpose |
|---|---|---|
| Final AppExchange Code Analyzer JSON | [`artifacts/CodeAnalyzerReport.json`](artifacts/CodeAnalyzerReport.json) | 0 severity 1 (Critical), 0 severity 2 (High), 7 severity 3 (Moderate) |
| Human-readable analyzer report | [`artifacts/CodeAnalyzerReport.html`](artifacts/CodeAnalyzerReport.html) | Browser-readable scan evidence |
| Moderate finding disposition | [MODERATE_FINDINGS.md](MODERATE_FINDINGS.md) | Field-by-field explanation of all seven `ProtectSensitiveData` results |
| CRUD/FLS/sharing assessment | [CRUD_FLS_SHARING.md](CRUD_FLS_SHARING.md) | Security enforcement and intentional system-context justification |
| Test and packaging evidence | [VALIDATION_EVIDENCE.md](VALIDATION_EVIDENCE.md) | Package identity, test, install and uninstall record |
| Submission manifest | [SUBMISSION_MANIFEST.md](SUBMISSION_MANIFEST.md) | Files to upload or make available to the reviewer |

## Analyzer integrity

- `artifacts/CodeAnalyzerReport.json` SHA-256: `54C837B64F2B803AEAA508BC990F5B4C3C817002A87231F2E8821CF6DF77837B`
- `artifacts/CodeAnalyzerReport.html` SHA-256: `5099675DCC57C3D3E32AD9907410DCE0F96C4D024F86C98BA739EF4363E583A4`
- Analyzer versions recorded by the JSON: Salesforce Code Analyzer `0.48.0`, PMD engine `0.41.0`.

## Secret-handling statement

No OpenAI API key, bearer token, customer credential, reviewer password, or installation key is included here. The package contains the Named Credential and External Credential structure only. A subscriber administrator populates the secret after installation and grants principal access separately.

## Before portal submission

Upload the immutable HTML report and the relevant supporting Markdown documents in the security-review wizard. Salesforce's current guidance requires a Code Analyzer report generated with the AppExchange and Recommended:Security rule selectors, and separately requires the Source Code Scanner (Checkmarx) scan. Confirm the submitted package version is the promoted version intended for review; this folder documents beta `1.0.0.6` and must be refreshed if a different version is submitted.

Official references:

- [Produce Code Analyzer Reports for AppExchange Security Review](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/appexchange.html)
- [Scan Your Managed Package with Salesforce Code Analyzer](https://developer.salesforce.com/docs/platform/isvforce/guide/security-review-code-analyzer-scan.html)
