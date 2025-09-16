
<#
.SYNOPSIS
    Adds TA's as owners to specific Teams and all related private channels and sub-channels based on a CSV file.

.DESCRIPTION
    This script reads a CSV file with columns TeamName;Group;TeamEmail;ChannelEmail.
    It applies a prefix to each TeamName, finds the corresponding Team and all related channels,
    and adds the TeamEmail as owner to the Team and ChannelEmail as owner to each channel and sub-channel.

.PARAMETER TAList
    Path to the CSV file with columns: TeamName;Group;TeamEmail;ChannelEmail

.PARAMETER Prefix
    Prefix to prepend to each TeamName (e.g., PROINZ_25_)

.PARAMETER DryRun
    Switch to simulate actions without making changes.

.EXAMPLE
    .\AddTAsToTeamsAndChannels.ps1 -TAList "PROINZ_TAs_2025.csv" -Prefix "PROINZ_25_" -DryRun

.VERSION
    1.0.1

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
    [string]$TAList,

    [Parameter(Mandatory = $true)]
    [string]$Prefix,

    [switch]$DryRun
)

# Import CSV
try {
    $taData = Import-Csv -Path $TAList -Delimiter ";"
} catch {
    Write-Host "Failed to read CSV file: $TAList" -ForegroundColor Red
    exit
}

# Cache all Teams
$allTeams = Get-Team | Select-Object DisplayName, GroupId

# Prepare log file
$logFile = "AddTAsLog.txt"
if (Test-Path $logFile) { Remove-Item $logFile }

foreach ($entry in $taData) {
    if ([string]::IsNullOrWhiteSpace($entry.TeamName) -or 
        [string]::IsNullOrWhiteSpace($entry.TeamEmail) -or 
        [string]::IsNullOrWhiteSpace($entry.ChannelEmail)) {
        Write-Host "Invalid entry in CSV" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Invalid entry: $($entry | Out-String)"
        continue
    }

    $teamName = "$Prefix$($entry.TeamName)"
    $teamEmail = $entry.TeamEmail
    $channelEmail = $entry.ChannelEmail

    # Lookup Team
    $team = $allTeams | Where-Object { $_.DisplayName -eq $teamName }
    if ($null -eq $team) {
        Write-Host "Team not found: $teamName" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Team not found: $teamName"
        continue
    }

    # Add TeamEmail as owner to the Team
    if ($DryRun) {
        Write-Host "[DryRun] Would add $teamEmail as owner to team: $teamName"
        Add-Content -Path $logFile -Value "[DryRun] Would add $teamEmail as owner to team: $teamName"
    } else {
        try {
            Add-TeamUser -GroupId $team.GroupId -User $teamEmail -Role Owner
            Write-Host "Added $teamEmail as owner to team: $teamName"
            Add-Content -Path $logFile -Value "Added $teamEmail as owner to team: $teamName"
        } catch {
            Write-Host "Failed to add $teamEmail to team: $teamName. Error: $_" -ForegroundColor Red
            Add-Content -Path $logFile -Value "Failed to add $teamEmail to team: $teamName"
        }
    }

    # Get all related channels: split group codes and add Demonstratori
    $groupChannels = $entry.TeamName -split "_"
    $groupChannels += "Demonstratori"

    $channels = Get-TeamChannel -GroupId $team.GroupId

    foreach ($channelName in $groupChannels) {
        $channel = $channels | Where-Object { $_.DisplayName -eq $channelName -and $_.MembershipType -eq "Private" }

        if ($null -eq $channel) {
            Write-Host "Channel not found: $channelName in $teamName" -ForegroundColor Red
            Add-Content -Path $logFile -Value "Channel not found: $channelName in $teamName"
            continue
        }

        # Add ChannelEmail as owner to the channel
        if ($DryRun) {
            Write-Host "[DryRun] Would add $channelEmail as owner to channel $channelName in $teamName"
            Add-Content -Path $logFile -Value "[DryRun] Would add $channelEmail as owner to $channelName in $teamName"
        } else {
            try {
                Add-TeamChannelUser -GroupId $team.GroupId -DisplayName $channelName -User $channelEmail -Role Owner
                Write-Host "Added $channelEmail as owner to channel $channelName in $teamName"
                Add-Content -Path $logFile -Value "Added $channelEmail as owner to $channelName in $teamName"
            } catch {
                Write-Host "Failed to add $channelEmail to $channelName in $teamName. Error: $_" -ForegroundColor Red
                Add-Content -Path $logFile -Value "Failed to add $channelEmail to $channelName in $teamName"
            }
        }

        # Add TA to sub-channels: TGxx.1 to TGxx.4
        for ($i = 1; $i -le 4; $i++) {
            $subTeamName = "T$channelName.$i"
            $subTeam = $allTeams | Where-Object { $_.DisplayName -eq $subTeamName }

            if ($null -eq $subTeam) {
                Write-Host "Sub-team not found: $subTeamName" -ForegroundColor Yellow
                Add-Content -Path $logFile -Value "Sub-team not found: $subTeamName"
                continue
            }

            if ($DryRun) {
                Write-Host "[DryRun] Would add $channelEmail as owner to sub-team: $subTeamName"
                Add-Content -Path $logFile -Value "[DryRun] Would add $channelEmail as owner to sub-team: $subTeamName"
            } else {
                try {
                    Add-TeamUser -GroupId $subTeam.GroupId -User $channelEmail -Role Owner
                    Write-Host "Added $channelEmail as owner to sub-team: $subTeamName"
                    Add-Content -Path $logFile -Value "Added $channelEmail as owner to sub-team: $subTeamName"
                } catch {
                    Write-Host "Failed to add $channelEmail to sub-team: $subTeamName. Error: $_" -ForegroundColor Red
                    Add-Content -Path $logFile -Value "Failed to add $channelEmail to sub-team: $subTeamName"
                }
            }
        }
    }
}

Write-Host "TA assignment to teams, channels, and sub-teams completed. See log: $logFile"
