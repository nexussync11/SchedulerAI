# Partner Security Review Submission Manifest

## Include

1. Exact managed package/version identity: `0HoOS00000003Nh0AI` / `04tOS00000MJ0ndYAD`.
2. Source repository or reviewer-accessible source archive pinned to commit `6e2cc33d440467d88b4e7a9315588823556947a9`.
3. `docs/security-review-evidence/artifacts/CodeAnalyzerReport.json` for internal traceability.
4. `docs/security-review-evidence/artifacts/CodeAnalyzerReport.html` as the uploadable Code Analyzer report.
5. This evidence folder, especially the Moderate finding and system-context explanations.
6. Customer installation guide and security reviewer test guide prepared for this version.
7. Privacy policy, terms of service and support details after the publisher confirms their public URLs/contact information.
8. Partner Portal/Checkmarx report or completion reference after the manual portal scan is run.

## Do not include

- OpenAI API keys or External Credential secrets.
- Scratch-org usernames/passwords in the repository.
- Customer data.
- Harley metadata or org information.
- Data Search, Lead Balancer or legacy LadminAI package artifacts.
- Beta installation key in public documentation.

## Manual confirmations before submission

- Promote the technically validated beta only after explicit approval. Salesforce's current security-review pre-queue guidance rejects beta packages; the submitted artifact must be managed and released.
- Confirm listing owner, support email/URL, privacy-policy URL and terms URL.
- Confirm a dedicated reviewer org and time-limited reviewer credentials exist; no such credentials are recorded in this repository.
- Complete the official Partner Portal scan and retain its report/reference. The local Code Analyzer report does not by itself prove Partner Portal/Checkmarx completion.
- Ensure the package version submitted in the portal exactly matches the version tested and documented here.
