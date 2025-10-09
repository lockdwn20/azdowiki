# azdowiki
Azure DevOps Wiki
Powershell scripts that will create YAML, Standard and HTML Tags within Azure DevOps Wiki pages based on the filename and directory in a specified root directory.  


# 🛠️ Wiki Automation Script

This PowerShell script automates the process of updating markdown-based wiki documentation in Azure DevOps. It supports modular functions for logging, file discovery, validation, backup handling, content updates, and dictionary generation.

## 📦 Features

- **Modular Function Design**  
  Each core task—logging, discovery, validation, backup, update—is encapsulated in a domain-scoped function for clarity and reuse.

- **Configurable Backup Logic**  
  Supports `create`, `delete`, or `none` modes to manage backups safely before overwriting files.

- **Validation Mode**  
  Preview changes without committing updates. Ensures tag correctness and supports dry-run testing.

- **Recursive File Discovery**  
  Handles root-level and nested markdown files, with exclusion logic for specific paths or filenames.

- **Dictionary Generation**  
  Builds a tag-to-path dictionary for traceability and downstream automation.

- **Audit-Friendly Logging**  
  Outputs structured logs with timestamps, encoding compatibility, and human-readable formatting.

## ⚙️ Parameters

| Parameter         | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| `-Mode`          | Operation mode: `validate`, `update`, or `dictionary`                       |
| `-BackupMode`    | Backup behavior: `create`, `delete`, or `none`                              |
| `-SourcePath`    | Root directory for markdown file discovery                                   |
| `-LogPath`       | Optional path for log file output                                            |
| `-ExcludePaths`  | Array of paths or filenames to exclude from processing                       |

## 🚦 Usage

```powershell
.\WikiAutomation.ps1 -Mode update -BackupMode create -SourcePath "C:\Docs\Wiki" -LogPath "C:\Logs\wiki.log"
