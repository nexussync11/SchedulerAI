# Validation and Packaging Evidence

## Package identity

- Product: LadminAI Appointment Scheduler
- Package type: managed second-generation package (2GP)
- Namespace: `LadminAI`
- Package ID: `0HoOS00000003Nh0AI`
- Validated beta: `1.0.0.6`
- Subscriber Package Version ID: `04tOS00000MJ0ndYAD`
- Source path: `ladminai-appointment`
- Ancestor: none
- Dependency on Data Search, Lead Balancer or legacy LadminAI package: none
- Validation source commit: `6e2cc33d440467d88b4e7a9315588823556947a9`

The package aliases above are recorded in `../../sfdx-project.json`. A read-only `sf package version report` against the authorized non-Harley `pbo-devhub` confirmed this identity and status on 2026-10-02.

## Test record

| Gate | Result |
|---|---|
| Source Apex tests | 37/37 passed, twice during final stabilization |
| Package build coverage | 79% |
| Managed 2GP beta build | Passed |
| Dev Hub package report | Confirmed `1.0.0.6`, managed, unreleased, 196 metadata files, no ancestor, 79% coverage, coverage check passed |
| Fresh isolated non-Harley install | Passed |
| Packaged permission sets | Six of six assigned and exercised |
| Installed-package Apex tests | 37/37 passed |
| Core scheduling without an OpenAI secret | Passed |
| Lead booking action present | Passed; subscriber placement on the chosen Lead page layout is a documented post-install step |
| Uninstall from isolated test org | Passed after removing permission-set assignments as required by Salesforce |

## Functional smoke scope

The validated run covered application launch/navigation, doctors/resources, locations, availability, Lead appointment booking, appointment schedule and lifecycle changes, dashboard/analytics, Salesforce Event creation/synchronization, reminder/reconciliation behavior, permission-set enforcement and the safe AI-unconfigured path.

## Supporting repository artifacts

- `../../test-results/fresh-org-tests.json` — retained source/fresh-org test output from an earlier validation run; it records 79% org-wide coverage. It is supplementary, not a substitute for the final installed-package 37/37 validation statement above.
- `artifacts/CodeAnalyzerReport.json` — final machine-readable AppExchange scan.
- `artifacts/CodeAnalyzerReport.html` — retained human-readable analyzer result.
- Git history at `6e2cc33...` — package version `1.0.0.6` recording and stabilized-test changes.

## Evidence limitation

The repository does not contain a dedicated exported Partner Portal/Checkmarx completion certificate or the final installed-org Apex result as a standalone raw JSON file. The final results are recorded in the validated release history and this manifest. If Salesforce requests raw portal evidence, export it from the Partner Security Portal and add it without including credentials.
