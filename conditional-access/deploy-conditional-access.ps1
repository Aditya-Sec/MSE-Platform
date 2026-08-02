# Deploys the Conditional Access policies in this folder via Microsoft
# Graph PowerShell — the real, documented method, since Conditional Access
# policies are Microsoft Graph objects (Entra ID), not ARM/Azure resources,
# and can't be deployed with Bicep/az the way the resource-group-scoped
# infrastructure in bicep/foundation can.
#
# Requires: Install-Module Microsoft.Graph -Scope CurrentUser
# Requires: Policy.ReadWrite.ConditionalAccess admin consent

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$policyFiles = Get-ChildItem -Path $PSScriptRoot -Filter "ca*.json"

foreach ($file in $policyFiles) {
    $policyJson = Get-Content $file.FullName -Raw | ConvertFrom-Json

    # Strip the documentation-only fields before sending to Graph — Graph
    # will reject the request if it receives properties it doesn't recognize
    $cleanPolicy = $policyJson | Select-Object -Property * -ExcludeProperty _comment, _deployment_note, _roles_comment

    Write-Host "Deploying: $($cleanPolicy.displayName) [state: $($cleanPolicy.state)]"

    New-MgIdentityConditionalAccessPolicy -BodyParameter ($cleanPolicy | ConvertTo-Json -Depth 10)
}

Write-Host "`nAll policies deployed in 'enabledForReportingButNotEnforced' state."
Write-Host "Review sign-in logs in Entra ID > Sign-in logs > filter by Conditional Access before enforcing."
