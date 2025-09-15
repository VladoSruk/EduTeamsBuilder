<#
.SYNOPSIS
    Creates Microsoft Teams with a specified prefix and description, then exports all Teams.

.DESCRIPTION
    This script connects to Microsoft Teams, creates private Teams for student groups with a given prefix and description,
    and exports all Teams in the tenant to a CSV file for tracking and auditing.

.PARAMETER Description
    The description to assign to each created Team.

.PARAMETER Prefix
    The prefix to prepend to each Team name.

.PREREQUISITES
    - PowerShell execution policy must allow script execution:
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    - Microsoft Teams PowerShell module must be installed:
        Install-Module -Name MicrosoftTeams -Scope CurrentUser
    - You must sign in using Connect-MicrosoftTeams
    - Your account must have sufficient permissions (Teams Administrator minimum)

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
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [string]$Prefix
)

# List of base team names
$baseTeamNames = @(
    "G01_G08_G09",
    "G02",
    "G03_G04",
    "G05_G06_G07",
    "G10_G11",
    "G12_G13_G18",
    "G14_G15",
    "G16_G17"
)


# Track created teams
$createdTeams = @()

# Create each team with prefix
foreach ($baseName in $baseTeamNames) {
    $teamName = "$Prefix$baseName"
    try {
        Write-Host "Creating team: $teamName"
        $newTeam = New-Team -DisplayName $teamName -Description $Description -Visibility "Private"
        $createdTeams += $newTeam
		
        # Extract individual group codes from the team name
        $groupChannels = $baseName -split "_"

        # Add group channels
        foreach ($channelName in $groupChannels) {
            Write-Host " Adding channel: $channelName"
            New-TeamChannel -GroupId $newTeam.GroupId -DisplayName $channelName -MembershipType Private
        
			# Create 4 additional teams for each group
            for ($i = 1; $i -le 4; $i++) {
                $subTeamName = "T$channelName.$i"
                Write-Host "Creating team: $subTeamName"
                New-Team -DisplayName $subTeamName -Description "$Description - $subTeamName" -Visibility "Private"
            }
		}

        # Add Demonstratori channel
        Write-Host " Adding channel: Demonstratori"
        New-TeamChannel -GroupId $newTeam.GroupId -DisplayName "Demonstratori" -MembershipType Private

    } catch {
        Write-Warning " Failed to create team or channel: $teamName. Error: $_"
    }
}

Write-Host "All specified teams processed."

# Export only newly created Teams to CSV
try {
    $teamsInfo = $createdTeams | Select-Object GroupId, DisplayName, Description
    $exportPath = "${Prefix}created_teams_list.csv"
    $teamsInfo | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported created team info to $exportPath"
} catch {
    Write-Warning "Failed to export created team list. Error: $_"
}
