<#

.SYNOPSIS
    Adds users to specific group channels in Microsoft Teams based on a CSV file.

.DESCRIPTION
    This script reads a CSV file with columns TeamName, Group, StudentADEmail, and Role.
    It applies a prefix to each TeamName, finds the corresponding Team and channel,
    and adds the user to the private channel with the specified role.

.PARAMETER StudentList
    Path to the CSV file with columns: TeamName;Group;StudentADEmail;Role


.PARAMETER Prefix
    Prefix to prepend to each TeamName (e.g., PROINZ_25_)

.EXAMPLE
    .\AddUsersToChannels.ps1 -StudentList "C:\Data\PROINZ_Students_Group_2025.csv" -Prefix "PROINZ_25_"

.COPYRIGHT
    Copyright © 2023 Vlado Sruk

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
    [string]$StudentList,

    [Parameter(Mandatory = $true)]
    [string]$Prefix
)


# Import CSV
try {
    $userData = Import-Csv -Path $StudentList -Delimiter ";"
} catch {
    Write-Host "Failed to read CSV file: $StudentList" -ForegroundColor Red
    exit
}

# Cache all Teams
$allTeams = Get-Team | Select-Object DisplayName, GroupId

# Prepare log file
$logFile = "AddGroupUsersLog.txt"
if (Test-Path $logFile) { Remove-Item $logFile }

foreach ($entry in $userData) {
    if ([string]::IsNullOrWhiteSpace($entry.TeamName) -or 
        [string]::IsNullOrWhiteSpace($entry.Group) -or 
        [string]::IsNullOrWhiteSpace($entry.StudentADEmail) -or 
        [string]::IsNullOrWhiteSpace($entry.Role)) {
        Write-Host "Invalid entry in CSV" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Invalid entry: $($entry | Out-String)"
        continue
    }

    $teamName = "$Prefix$($entry.TeamName)"
    $groupChannel = $entry.Group
    $userEmail = $entry.StudentADEmail
    $role = $entry.Role

    # Lookup Team
    $team = $allTeams | Where-Object { $_.DisplayName -eq $teamName }
    if ($null -eq $team) {
        Write-Host "Team not found: $teamName" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Team not found: $teamName"
        continue
    }

    # Get channels in the Team
    $channels = Get-TeamChannel -GroupId $team.GroupId
    $channel = $channels | Where-Object { $_.DisplayName -eq $groupChannel -and $_.MembershipType -eq "Private" }

    if ($null -eq $channel) {
        Write-Host "Channel not found: $groupChannel in $teamName" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Channel not found: $groupChannel in $teamName"
        continue
    }

    # Add user to channel with role
    try {
        Add-TeamChannelUser -GroupId $team.GroupId -DisplayName $groupChannel -User $userEmail -Role $role
        Write-Host "Added $userEmail to channel $groupChannel in $teamName with role $role"
        Add-Content -Path $logFile -Value "Added $userEmail to $groupChannel in $teamName with role $role"
    } catch {
        Write-Host "Failed to add $userEmail to $groupChannel in $teamName. Error: $_" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Failed to add $userEmail to $groupChannel in $teamName"
    }
}

Write-Host "User assignment to group channels completed. See log: $logFile"
