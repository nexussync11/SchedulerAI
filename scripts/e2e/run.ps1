$ErrorActionPreference = 'Stop'
$aliasName = if ($env:SF_TARGET_ORG) { $env:SF_TARGET_ORG } else { 'ladminai-fresh-20260917' }

$seedOutput = sf apex run --target-org $aliasName --file scripts/e2e/seed.apex | Out-String
if ($LASTEXITCODE -ne 0) { throw 'Unable to seed the authorized Salesforce org.' }
if ($seedOutput -notmatch 'E2E_LEAD_ID=([a-zA-Z0-9]{15,18})') { throw 'Unable to resolve the E2E Lead id.' }
$leadId = $Matches[1]
$loginResult = sf org open --target-org $aliasName --path "lightning/n/LadminAI_Smart_Appointment?c__leadId=$leadId" --url-only --json | ConvertFrom-Json
$env:SF_LOGIN_URL = $loginResult.result.url

node node_modules/@playwright/test/cli.js test --reporter=line
exit $LASTEXITCODE
