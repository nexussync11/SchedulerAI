# LadminAI Appointment Scheduler — Security Review Evidence

Evidence baseline: exact package-build source commit `924973268fb7c0c6e66b756fc23be9c9e921b194` and released managed 2GP version `1.0.0.7` (`04tOS00000MJ7abYAD`) in package `0HoOS00000003Nh0AI`.

This folder is the reviewer-facing index for the Appointment Scheduler product only. It does not describe or include LadminAI Data Search, LadminAI Lead Balancer, the legacy LadminAI package, or Harley metadata.

## Evidence index

| Evidence | Location | Result / purpose |
|---|---|---|
| Final AppExchange Code Analyzer JSON | [`artifacts/CodeAnalyzerReport-1.0.0.7.json`](artifacts/CodeAnalyzerReport-1.0.0.7.json) | 0 severity 1 (Critical), 0 severity 2 (High), 7 severity 3 (Moderate) |
| Human-readable analyzer report | [`artifacts/CodeAnalyzerReport-1.0.0.7.html`](artifacts/CodeAnalyzerReport-1.0.0.7.html) | Browser-readable scan evidence |
| Moderate finding disposition | [MODERATE_FINDINGS.md](MODERATE_FINDINGS.md) | Field-by-field explanation of all seven `ProtectSensitiveData` results |
| CRUD/FLS/sharing assessment | [CRUD_FLS_SHARING.md](CRUD_FLS_SHARING.md) | Security enforcement and intentional system-context justification |
| Test and packaging evidence | [VALIDATION_EVIDENCE.md](VALIDATION_EVIDENCE.md) | Package identity, test, install and uninstall record |
| Submission manifest | [SUBMISSION_MANIFEST.md](SUBMISSION_MANIFEST.md) | Files to upload or make available to the reviewer |

## Analyzer integrity

- `artifacts/CodeAnalyzerReport-1.0.0.7.json` SHA-256: `54C837B64F2B803AEAA508BC990F5B4C3C817002A87231F2E8821CF6DF77837B`
- `artifacts/CodeAnalyzerReport-1.0.0.7.html` SHA-256: `F7EC717B57B432D6A9CD1C8034E4CDEF2F49148A187B8B36583E5C80972707A3`
- Analyzer versions recorded by the JSON: Salesforce Code Analyzer `0.48.0`, PMD engine `0.41.0`.

## Secret-handling statement

No OpenAI API key, bearer token, customer credential, reviewer password, or installation key is included here. The package contains the Named Credential and External Credential structure only. A subscriber administrator populates the secret after installation and grants principal access separately.

## Before portal submission

Upload the immutable HTML report and the relevant supporting Markdown documents in the security-review wizard. Salesforce's current guidance requires a Code Analyzer report generated with the AppExchange and Recommended:Security rule selectors, and separately requires the Source Code Scanner (Checkmarx) scan. This folder documents released version `1.0.0.7`; it must be refreshed if a different version is submitted.

Official references:

- [Produce Code Analyzer Reports for AppExchange Security Review](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/appexchange.html)
- [Scan Your Managed Package with Salesforce Code Analyzer](https://developer.salesforce.com/docs/platform/isvforce/guide/security-review-code-analyzer-scan.html)
