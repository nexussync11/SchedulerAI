$ErrorActionPreference = 'Stop'
$org = if ($env:SF_TARGET_ORG) { $env:SF_TARGET_ORG } else { 'ladminai-release-check-20260920' }
sf org create user --target-org $org --definition-file config/users/operations-user.json --set-alias ladminai-operations
if ($LASTEXITCODE -ne 0) { throw 'Unable to create operations persona.' }
sf org assign permset --target-org $org --on-behalf-of ladminai-operations@example.test --name LadminAI_Appointment_Booker --name LadminAI_Analytics_Viewer
if ($LASTEXITCODE -ne 0) { throw 'Unable to assign operations permissions.' }
sf org create user --target-org $org --definition-file config/users/administrator-user.json --set-alias ladminai-administrator
if ($LASTEXITCODE -ne 0) { throw 'Unable to create administrator persona.' }
sf org assign permset --target-org $org --on-behalf-of ladminai-administrator@example.test --name LadminAI_Appointment_Configurator --name LadminAI_Location_Administrator --name LadminAI_Resource_Administrator --name LadminAI_Availability_Manager
if ($LASTEXITCODE -ne 0) { throw 'Unable to assign administrator permissions.' }
