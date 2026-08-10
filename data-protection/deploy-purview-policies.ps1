<#
.SYNOPSIS
    Deploys Purview sensitivity labels and the DLP policy that references
    them, in the correct order — labels must exist before a DLP policy
    can condition on them, so this script enforces that sequencing rather
    than leaving it to chance.

.NOTES
    Requires: ExchangeOnlineManagement module (Security & Compliance
    PowerShell endpoint), Compliance Administrator role.
#>

param(
    [switch]$WhatIf = $true
)

Import-Module ExchangeOnlineManagement
Connect-IPPSSession  # Security & Compliance PowerShell, distinct from Connect-ExchangeOnline

$labels = (Get-Content -Raw -Path "./sensitivity-labels.json" | ConvertFrom-Json).labelTaxonomy
$dlpPolicy = Get-Content -Raw -Path "./dlp-confidential-data-policy.json" | ConvertFrom-Json

Write-Host "Step 1 — creating sensitivity labels (must exist before the DLP policy below can reference them)"
foreach ($label in $labels) {
    Write-Host "  Creating label: $($label.name)"
    New-Label -DisplayName $label.name `
        -Name ($label.name -replace ' ', '') `
        -Tooltip "Priority $($label.priority) — $($label.name)" `
        -WhatIf:$WhatIf
}

Write-Host "`nStep 2 — creating DLP policy: $($dlpPolicy.policyName)"
New-DlpCompliancePolicy -Name $dlpPolicy.policyName `
    -SharePointLocation "All" `
    -OneDriveLocation "All" `
    -TeamsLocation "All" `
    -ExchangeLocation "All" `
    -WhatIf:$WhatIf

New-DlpComplianceRule -Name "$($dlpPolicy.policyName)-Rule" `
    -Policy $dlpPolicy.policyName `
    -ContentContainsSensitiveInformation @{Name="Confidential"} `
    -BlockAccess $true `
    -NotifyUser "SiteAdmin" `
    -GenerateIncidentReport "SiteAdmin" `
    -IncidentReportContent "All" `
    -WhatIf:$WhatIf

Write-Host "`nDone. Ran with -WhatIf:$WhatIf — pass -WhatIf:`$false to actually apply."
