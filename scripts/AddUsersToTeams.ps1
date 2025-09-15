<#

.SYNOPSIS
    Adds users to Microsoft Teams based on a CSV input file.

.DESCRIPTION
    This script reads a CSV file containing TeamName and StudentEmail,
    applies a prefix to the TeamName, and adds each user to the corresponding Team.

.PARAMETER StudentList
    Path to the CSV file with columns: TeamName;StudentEmail

.PARAMETER Prefix
    Prefix to prepend to each TeamName (e.g., PROINZ_25_)

.EXAMPLE
    .\AddUsersToTeams.ps1 -StudentList "C:\Data\PROINZ_Students_Group_2025.csv" -Prefix "PROINZ_25_"

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
$logFile = "AddStudentTeamLog.txt"
if (Test-Path $logFile) { Remove-Item $logFile }

foreach ($entry in $userData) {
    # Validate input
    if ([string]::IsNullOrWhiteSpace($entry.TeamName) -or [string]::IsNullOrWhiteSpace($entry.StudentEmail)) {
        Write-Host "Invalid entry: missing TeamName or StudentEmail" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Invalid entry: $($entry | Out-String)"
        continue
    }

    $teamName = "$Prefix$($entry.TeamName)"
    $userEmail = $entry.StudentEmail

    # Lookup team
    $team = $allTeams | Where-Object { $_.DisplayName -eq $teamName }
    if ($null -eq $team) {
        Write-Host "Team not found: $teamName" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Team not found: $teamName"
        continue
    }

    # Check if user is already a member
    $existingMembers = Get-TeamUser -GroupId $team.GroupId
    if ($existingMembers.User -contains $userEmail) {
        Write-Host "$userEmail is already a member of $teamName"
        Add-Content -Path $logFile -Value "$userEmail already in $teamName"
        continue
    }

    # Add user with retry logic
    $maxRetries = 3
    $attempt = 0
    $success = $false

    do {
        try {
            Add-TeamUser -GroupId $team.GroupId -User $userEmail
            Write-Host "Added $userEmail to $teamName"
            Add-Content -Path $logFile -Value "Added $userEmail to $teamName"
            $success = $true
        } catch {
            $attempt++
            Write-Host "Attempt $attempt failed for $userEmail in $teamName. Error: $_" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } while (-not $success -and $attempt -lt $maxRetries)

    if (-not $success) {
        Add-Content -Path $logFile -Value "Failed to add $userEmail to $teamName after $maxRetries attempts"
    }
}

Write-Host "User assignment completed. See log: $logFile"
