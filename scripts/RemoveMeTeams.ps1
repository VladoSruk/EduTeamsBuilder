<#
.SYNOPSIS
    Removes the current user from a predefined list of Microsoft Teams after confirmation and logs the actions.

.DESCRIPTION
    This script connects to Microsoft Teams, confirms with the user, removes them from specific Teams based on a prefix and list,
    and logs the results to a timestamped log file.



.PARAMETER Prefix
    The prefix to prepend to each Team name.

.PREREQUISITES
    - PowerShell execution policy must allow script execution:
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    - Microsoft Teams PowerShell module must be installed:
        Install-Module -Name MicrosoftTeams -Scope CurrentUser
    - You must sign in using Connect-MicrosoftTeams
    - Your account must have sufficient permissions (Teams Administrator minimum)

.VERSION
    1.0.0
	
.COPYRIGHT
    Copyright © 2024 Vlado Sruk

.LICENSE
    Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
    You may share and adapt this code with proper attribution.

    You are free to use this code within your own applications, add-ins, and documents.
    However, you are expressly forbidden from selling or distributing this source code
    without prior written consent. This includes posting free demo projects made from
    this code or reproducing the code in text or HTML format.


.AUTHOR
    Vlado Sruk
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Prefix
)

# List of base team names
$baseTeamNames = @(
    "G01_G08_G09",
#    "G02",
    "G03_G04",
    "G05_G06_G07",
    "G10_G11",
    "G12_G13_G18",
    "G14_G15",
    "G16_G17"
)

# Display teams to be removed
Write-Host "You are about to be removed from the following Teams(Did you add TA's?):"
foreach ($baseName in $baseTeamNames) {
    Write-Host " - $Prefix$baseName"
}

# Ask for confirmation
$confirmation = Read-Host "Are you sure you want to proceed? Type 'YES' to confirm"
if ($confirmation -ne "YES") {
    Write-Host "Operation cancelled by user."
    return
}

# Get current user
$currentUser = Get-CsOnlineUser | Select-Object -ExpandProperty UserPrincipalName

# Prepare log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "TeamsSelectiveRemovalLog_$timestamp.txt"
Add-Content -Path $logFile -Value "Selective Teams Removal Log - $timestamp"
Add-Content -Path $logFile -Value "User: $currentUser`n"

# Get all teams
$teams = Get-Team

foreach ($baseName in $baseTeamNames) {
    $fullTeamName = "$Prefix$baseName"
    $team = $teams | Where-Object { $_.DisplayName -eq $fullTeamName }

    if ($team) {
        try {
            $members = Get-TeamUser -GroupId $team.GroupId -Role Member
            if ($members.User -contains $currentUser) {
                Write-Host "Removing user from team: $($team.DisplayName)"
                Remove-TeamUser -GroupId $team.GroupId -User $currentUser
                Add-Content -Path $logFile -Value "Removed from team: $($team.DisplayName)"
            } else {
                Add-Content -Path $logFile -Value "User not a member of team: $($team.DisplayName)"
            }
        } catch {
            $errorMsg = "Failed to process team: $($team.DisplayName). Error: $_"
            Write-Warning $errorMsg
            Add-Content -Path $logFile -Value $errorMsg
        }
    } else {
        Add-Content -Path $logFile -Value "Team not found: $fullTeamName"
    }
}

Write-Host "Selective team removal complete. Log saved to $logFile"
