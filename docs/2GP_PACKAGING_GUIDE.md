# LadminAI Appointment 2GP Packaging Guide

## Current readiness

The project uses one planned managed 2GP package directory:

- `ladminai-appointment` — new commercial product metadata; default package directory
- `force-app` — legacy retrieved source retained as a non-default reference directory

The namespace remains blank in source. No package, namespace, package version, or release was created in Gate 1.

## Dev Hub preparation

Run these commands only against an authorized packaging Dev Hub, never a Harley org:

```powershell
sf org login web --alias ladminai-dev-hub --set-default-dev-hub
sf package create --name "LadminAI Appointment" --package-type Managed --path ladminai-appointment --target-dev-hub ladminai-dev-hub
```

The package-create command adds a package alias to `sfdx-project.json`. Review that generated change before committing it.

Create a development scratch org:

```powershell
sf org create scratch --definition-file config/project-scratch-def.json --alias ladminai-appointment-dev --target-dev-hub ladminai-dev-hub --duration-days 7
```

Do not create a package version until package boundaries and dependencies are finalized in Gate 8.

## Known Gate 1 boundary concern

The new Lightning app references existing object and availability tabs stored under `force-app`. Those legacy objects/tabs are not yet in the commercial package directory. This is intentional during staged migration, but it blocks standalone package-version compilation until Gate 8 moves or explicitly includes the approved dependencies.

The incomplete `customLookup`, obsolete communication flows, hard-coded Calendly flow, and `RequestResource__c` are not dependencies of the new Gate 1 package shell.

## Gate 1 validation status

- Salesforce source-to-Metadata API conversion succeeds without warnings.
- JSON, XML, API-name length, JavaScript syntax, naming, secret, and prohibited-runtime scans pass.
- Code Analyzer `eslint`, `retire-js`, and `regex` recommended rules report zero violations.
- PMD, CPD, and Salesforce Graph Engine could not run because Java 11+ is not available locally. No software was installed.
- Apex compilation, metadata deployment validation, and standalone package compilation remain pending until an authorized non-Harley development org and packaging boundary are available.

## Namespace safety

- Source contains no hard-coded namespace.
- LWC references use local bundle names.
- Apex types use product-prefixed names but no namespace literals.
- Existing API names are not renamed.

## Prohibited actions

- Do not package or deploy from a Harley org.
- Do not store authentication URLs, tokens, certificates, keys, or usernames in source.
- Do not create or release a managed package version during Phase 0 without explicit approval.
