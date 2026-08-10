<#
.SYNOPSIS
    Deploys Defender for Office 365 Safe Links and Safe Attachments policies
    via Exchange Online PowerShell.

.NOTES
    Same reasoning as conditional-access/deploy-conditional-access.ps1: these
    are Exchange Online Protection objects, not ARM resources, so Bicep can't
    deploy them — this is the correct tool for the job, not a workaround.

    Requires: ExchangeOnlineManagement module, Exchange admin role.
#>

param(
    [switch]$WhatIf = $true  # Defaults to dry-run — pass -WhatIf:$false to actually apply
)

Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

$safeLinks = Get-Content -Raw -Path "./safe-links-policy.json" | ConvertFrom-Json
$safeAttachments = Get-Content -Raw -Path "./safe-attachments-policy.json" | ConvertFrom-Json

Write-Host "Deploying Safe Links policy: $($safeLinks.policyName)"
New-SafeLinksPolicy -Name $safeLinks.policyName `
    -EnableSafeLinksForEmail $safeLinks.settings.EnableSafeLinksForEmail `
    -EnableSafeLinksForTeams $safeLinks.settings.EnableSafeLinksForTeams `
    -EnableSafeLinksForOffice $safeLinks.settings.EnableSafeLinksForOffice `
    -TrackClicks $safeLinks.settings.TrackClicks `
    -AllowClickThrough $safeLinks.settings.AllowClickThrough `
    -ScanUrls $safeLinks.settings.ScanUrls `
    -EnableForInternalSenders $safeLinks.settings.EnableForInternalSenders `
    -DeliverMessageAfterScan $safeLinks.settings.DeliverMessageAfterScan `
    -WhatIf:$WhatIf

New-SafeLinksRule -Name "$($safeLinks.policyName)-Rule" `
    -SafeLinksPolicy $safeLinks.policyName `
    -RecipientDomainIs $safeLinks.appliesTo.recipientDomains `
    -WhatIf:$WhatIf

Write-Host "Deploying Safe Attachments policy: $($safeAttachments.policyName)"
New-SafeAttachmentPolicy -Name $safeAttachments.policyName `
    -Enable $safeAttachments.settings.Enable `
    -Action $safeAttachments.settings.Action `
    -ActionOnError $safeAttachments.settings.ActionOnError `
    -Redirect $safeAttachments.redirectOnError.enabled `
    -RedirectAddress $safeAttachments.redirectOnError.redirectAddress `
    -WhatIf:$WhatIf

New-SafeAttachmentRule -Name "$($safeAttachments.policyName)-Rule" `
    -SafeAttachmentPolicy $safeAttachments.policyName `
    -RecipientDomainIs "*" `
    -WhatIf:$WhatIf

Write-Host "`nDone. Ran with -WhatIf:$WhatIf — pass -WhatIf:`$false to actually apply these policies."
