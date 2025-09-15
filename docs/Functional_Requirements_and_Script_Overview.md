# 📘 Functional and Non-Functional Requirements

## ✅ Functional Requirements

| **ID** | **Requirement** | **Description** | **Priority** | **Source** | **Acceptance Criteria** |
|--------|------------------|------------------|--------------|------------|--------------------------|
| F-001 | Parameter Input | The script accepts parameters such as Prefix, Description, and StudentList. | High | Requirement Document | Parameters can be entered at runtime and are used in subsequent processing. |
| F-002 | Team Creation | The script creates private Teams with a prefix and description. | High | Stakeholder Requirement | Teams are successfully created and visible in Microsoft Teams. |
| F-003 | Group Channel Creation | The script creates private channels for each group within a Team. | High | Requirement Document | Channels are created with correct names and access type. |
| F-004 | Add Demonstratori Channel | The script adds a 'Demonstratori' channel to each Team. | Medium | Existing System | Channel is present in each Team and has private access. |
| F-005 | Export Created Teams | The script exports data about created Teams to a CSV file. | Medium | Stakeholder Requirement | CSV file contains GroupId, DisplayName, and Description. |
| F-006 | Load Student CSV | The script loads a CSV file with TeamName, Group, StudentADEmail, and Role. | High | Requirement Document | Data is successfully loaded and processed. |
| F-007 | Add Students to Teams | The script adds students to existing Teams as members. | High | Stakeholder Requirement | Students are added to Teams and visible as members. |
| F-008 | Add Students to Group Channels | The script adds students to private channels with appropriate roles. | High | Requirement Document | Students are added to channels with Member or Owner role. |
| F-009 | Data Validation | The script checks for missing or invalid data in the student list. | High | User Feedback | Invalid rows are skipped and errors are logged. |
| F-010 | Error Handling | The script displays errors in the console and logs them to a file. | High | User Feedback | Errors are clearly shown and recorded for review. |

## 🛠️ Script Overview

- CreateTeams.ps1 – Creates Teams and private channels based on predefined groupings and prefix.
- AddUsersToTeams.ps1 – Adds users to existing Teams as default members using a simple CSV.
- AddUsersToGroupChannels.ps1 – Adds users to specific private channels within Teams with roles.

## ⚙️ Non-Functional Requirements

| **ID** | **Category** | **Requirement** |
|--------|--------------|------------------|
| NFR-001 | Performance | The script should efficiently process large CSV files (e.g., 1,000+ entries) without significant delays. |
| NFR-002 | Scalability | The solution should handle increasing numbers of students and Teams without modification. |
| NFR-003 | Usability | The script should be easy to run with clear input parameters and meaningful console output. |
| NFR-004 | Reliability | The script should handle errors gracefully and continue processing valid entries. |
| NFR-005 | Maintainability | The code should be modular and easy to update (e.g., adding logging, retry logic, or new fields). |
| NFR-006 | Security | Only authorized users with sufficient Microsoft Teams permissions should be able to execute the script. |
| NFR-007 | Auditability | All actions (successes and failures) should be logged to a file for review and compliance. |
| NFR-008 | Compatibility | The script should run on systems with PowerShell and the Microsoft Teams module installed. |
| NFR-009 | Localization | The script should support UTF-8 encoding to handle international characters in names and emails. |


## 🚀 Usage Instructions

### Create Teams and Channels
```powershell
./CreateTeams.ps1 -Prefix "PROINZ_25_" -Description "Software engineering Teams 2025"
```

### Add Users to Teams
```powershell
./AddUsersToTeams.ps1 -StudentList "data/Example_StudentToTeams_DefaultMember.csv" -Prefix "PROINZ_25_"
```

### Add Users to Group Channels with Roles
```powershell
./AddUsersToGroupChannels.ps1 -StudentList "data/Example_StudentToTeams.csv" -Prefix "PROINZ_25_"
```


