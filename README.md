# azdowiki
Azure DevOps Wiki
Powershell scripts that will create YAML, Standard and HTML Tags within Azure DevOps Wiki pages based on the filename and directory in a specified root directory.  


# 📘 Wiki Tag Updater

## Overview
The **Wiki Tag Updater** is a PowerShell-based automation tool designed to scan a Markdown-based wiki repository, extract meaningful tags from file paths, and inject standardized YAML headers and footers into each file. It also generates a centralized tag dictionary for easy reference and navigation.

This script is ideal for teams managing structured documentation in Git-backed wikis, especially when tag hygiene, traceability, and automation are key.

---

## 🔧 Features

- ✅ Extracts tags from folder and file names using delimiter logic  
- ✅ Skips excluded directories (e.g., `Archive`, `Templates`)  
- ✅ Handles root-level wiki files gracefully  
- ✅ Injects YAML front matter and Markdown footers with tag metadata  
- ✅ Creates backups before modifying files (configurable)  
- ✅ Generates a tag dictionary listing all unique tags  
- ✅ Modular functions for logging, validation, backup, and updates

---

## 📂 Folder Structure Assumptions

- Wiki root is a folder containing `.md` files and subfolders  
- Each file’s path contributes to its tag set  
- A root-level file named after the repo folder (e.g., `Wiki-Root.md`) is optionally included

---

## 🛠️ Usage

### 1. Configure Parameters

Edit the top of the script to match your environment:

```powershell
$repoRoot      = ""C:\Path\To\Your\Wiki""
$excludeDirs   = @(""Archive"", ""Templates"")
$dictLink      = ""/Wiki/Wiki-Root/Tags/Tag_Dictionary.md""
$dictWritePath = ""Tags\Tag_Dictionary.md""
$logPath       = Join-Path $repoRoot ""TagUpdate.log""
$backupMode    = ""Create""  # Options: Create, Delete, None
```

### 2. Run the Script

Execute the script in PowerShell. It will:

- Discover eligible `.md` files  
- Extract and compare tags  
- Inject or skip updates based on tag differences  
- Write a tag dictionary  
- Log all actions to `TagUpdate.log`

---

## 🧩 Modular Functions

| Function Name                   | Purpose                                      |
|--------------------------------|----------------------------------------------|
| `Get-WikiMetadata`             | Extracts tags and builds YAML/footer blocks |
| `Write-WikiMetadataLog`        | Logs messages with timestamp and severity   |
| `Get-WikiFiles`                | Discovers files, including root-level       |
| `Test-WikiMetadata`            | Compares existing vs expected tags          |
| `Backup-WikiFiles`             | Creates or deletes `.bak` files             |
| `Update-WikiFile`              | Applies updates if tags differ              |
| `Write-WikiMetadataDictionary` | Generates tag dictionary file               |

---

## 🧪 Backup Modes

- `Create`: Save `.bak` before modifying  
- `Delete`: Create then remove `.bak` after update  
- `None`: Skip backups entirely

---

## 📋 Sample Output

Each updated file will include:

- A YAML header with title and tags  
- A Markdown footer with tag links and dictionary reference  
- Inline `<!-- TAG: ... -->` comments for searchability

---

## 📜 License

MIT License — feel free to use, modify, and share.
```
