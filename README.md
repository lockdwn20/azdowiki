# azdowiki
Azure DevOps Wiki
PowerShell scripts that will create YAML, Standard and HTML Tags within Azure DevOps Wiki pages based on the filename and directory in a specified root directory.


# 📘 Wiki Tag Updater

## Overview
The **Wiki Tag Updater** is a PowerShell-based automation tool designed to scan a Markdown-based wiki repository, extract meaningful tags from file paths, and inject standardized YAML headers and footers into each file. It also generates a centralized tag dictionary for easy reference and navigation.

**NEW:** The tool now includes **Quarterly Review** functionality that automatically tracks changes to your wiki structure over time, helping maintain naming standards and providing visibility into wiki evolution.

This script is ideal for teams managing structured documentation in Git-backed wikis, especially when tag hygiene, traceability, and automation are key.

---

## 🔧 Features

### Tag Management
- ✅ Extracts tags from folder and file names using delimiter logic  
- ✅ Skips excluded directories (e.g., `Archive`, `Templates`)  
- ✅ Handles root-level wiki files gracefully  
- ✅ Injects YAML front matter and Markdown footers with tag metadata  
- ✅ Creates backups before modifying files (configurable)  
- ✅ Generates a tag dictionary listing all unique tags  
- ✅ Modular functions for logging, validation, backup, and updates

### Quarterly Review (New!)
- ✅ Automatic quarterly baseline creation (JSON snapshots)
- ✅ Change detection (added, deleted, moved, renamed files)
- ✅ Markdown change reports for governance reviews
- ✅ Automatic retention management (1 year of history)
- ✅ Smart duplicate prevention (one baseline per quarter)
- ✅ Azure Pipeline integration with optional scheduling

---

## 📂 Folder Structure Assumptions

- Wiki root is a folder containing `.md` files and subfolders  
- Each file's path contributes to its tag set  
- A root-level file named after the repo folder (e.g., `Wiki-Root.md`) is optionally included

---

## 🛠️ Usage

### 1. Configure Parameters

Edit the top of the script to match your environment:

```powershell
$repoRoot      = "C:\Path\To\Your\Wiki"
$excludeDirs   = @("Archive", "Templates", "Metadata")
$dictLink      = "/Wiki/Wiki-Root/Tags/Tag_Dictionary.md"
$dictWritePath = "Tags\Tag_Dictionary.md"
$backupMode    = "Create"  # Options: Create, Delete, None
$enableQuarterlyReview = $true  # Enable/disable quarterly tracking
```

### 2. Run the Script

Execute the script in PowerShell. It will:

- **Quarterly Review (if enabled):**
  - Check current quarter and create baseline if needed
  - Compare with previous quarter and generate change report
  - Manage retention (keep 4 quarters)
  
- **Tag Updates:**
  - Discover eligible `.md` files  
  - Extract and compare tags  
  - Inject or skip updates based on tag differences  
  - Write a tag dictionary  
  - Log all actions to `Metadata\Tag_Update.log`

### 3. Azure Pipeline Integration

Configure automatic quarterly runs:

```yaml
schedules:
- cron: "0 0 1 1,4,7,10 *"  # Jan 1, Apr 1, Jul 1, Oct 1
  displayName: Quarterly Wiki Review
  branches:
    include:
      - main
  always: true

variables:
  enableQuarterlyReview: 'true'
```

---

## 🧩 Modular Functions

### Core Tag Functions
| Function Name                   | Purpose                                      |
|--------------------------------|----------------------------------------------|
| `Get-WikiMetadata`             | Extracts tags and builds YAML/footer blocks |
| `Add-WikiMetadataLog`          | Logs messages with timestamp and severity   |
| `Get-WikiFiles`                | Discovers files, including root-level       |
| `Test-WikiMetadata`            | Compares existing vs expected tags          |
| `Backup-WikiFiles`             | Creates or deletes `.bak` files             |
| `Update-WikiFile`              | Applies updates if tags differ              |
| `Save-WikiMetadataDictionary`  | Generates tag dictionary file               |

### Quarterly Review Functions (New!)
| Function Name                     | Purpose                                    |
|----------------------------------|---------------------------------------------|
| `Get-QuarterInfo`                | Determines current quarter                  |
| `Get-PreviousQuarterInfo`        | Retrieves previous quarter information      |
| `New-WikiQuarterlyBaseline`      | Creates quarterly snapshot (JSON)           |
| `Compare-WikiQuarterlyBaselines` | Compares two quarters and detects changes   |
| `New-QuarterlyChangeReport`      | Generates markdown change report            |
| `Invoke-WikiQuarterlyReview`     | Main orchestration for quarterly tracking   |

---

## 🧪 Backup Modes

- `Create`: Save `.bak` before modifying  
- `Delete`: Create then remove `.bak` after update  
- `None`: Skip backups entirely

---

## 📊 Quarterly Review System

### How It Works

1. **Automatic Detection:** Script determines the current quarter (Q1-Q4)
2. **Baseline Creation:** Creates a JSON snapshot of all files and directories (once per quarter)
3. **Change Comparison:** Compares current quarter with previous quarter
4. **Report Generation:** Produces a markdown report showing:
   - Added files
   - Deleted files
   - Moved/renamed files
   - New/removed directories
   - Summary statistics

### Quarterly Schedule

- **Q1:** January 1 - March 31
- **Q2:** April 1 - June 30
- **Q3:** July 1 - September 30
- **Q4:** October 1 - December 31

### Retention Policy

Automatically maintains **4 quarters (1 year)** of history. Older baselines and reports are automatically deleted.

### Sample Quarterly Report

```markdown
# Quarterly Wiki Review - 2025_Q2

**Review Date:** 2025-04-01 08:30:15
**Previous Quarter:** 2025_Q1
**Previous File Count:** 142
**Current File Count:** 158
**Net Change:** +16 files

## 📊 Changes Summary

- **Added:** 18 files
- **Deleted:** 5 files
- **Moved/Renamed:** 3 files
- **New Directories:** 2
- **Removed Directories:** 1

## 📋 Review Checklist

- [ ] All new files follow naming conventions
- [ ] Deleted files were intentionally removed
- [ ] Moved/renamed files maintain tag consistency
- [ ] New directories align with wiki structure
```

---

## 📋 Sample Tag Output

Each updated file will include:

### YAML Header
```yaml
---
title: Incident Response Playbook
description:
tags:
  - CSIRT
  - Incident
  - Response
  - Playbook
---
```

### Markdown Footer
```markdown
---
**Tags:** #CSIRT, #Incident, #Response, #Playbook

<!-- TAG: CSIRT -->
<!-- TAG: Incident -->
<!-- TAG: Response -->
<!-- TAG: Playbook -->

<!-- BEGIN NOTOC -->
[Tag Dictionary](/Wiki/Wiki-Root/Tags/Tag_Dictionary.md)
<!-- END NOTOC -->
---
```

### Benefits

1. **YAML Tags:** Structured metadata for automation and search
2. **Footer Hashtags:** Human-friendly, lightweight categorization
3. **HTML Comments:** Invisible enrichment for pipeline integration

---

## 🔄 Typical Workflow

### Initial Setup
1. Configure script parameters
2. Run script to create initial baseline and tag all files
3. Review generated tag dictionary
4. Configure Azure Pipeline (optional)

### Ongoing Usage

**Continuous (Anytime):**
- Script runs on code changes or manual triggers
- Updates tags on modified files
- Maintains tag dictionary

**Quarterly (Jan 1, Apr 1, Jul 1, Oct 1):**
- Creates new baseline snapshot
- Compares with previous quarter
- Generates change report for governance review
- Team reviews naming standards compliance

---

## 🚀 Quick Start

### Local Testing

```powershell
# Clone the repository
git clone <your-repo-url>
cd wiki-scripts

# Run the script
.\Wiki_Metadata_Updates.ps1 `
    -repoRoot "C:\Path\To\Wiki" `
    -excludeDirs @("Archive","Templates","Metadata") `
    -enableQuarterlyReview $true
```

### Azure Pipeline Setup

1. Copy `azure-pipelines.yml` to your repository root
2. Update variables for your environment
3. Uncomment the `schedules:` block for automatic quarterly runs
4. Commit and push to trigger initial run

---

## 📖 Additional Documentation

- **INTEGRATION_GUIDE.md** - Step-by-step integration instructions
- **QUARTERLY_REVIEW_DOCUMENTATION.md** - Detailed quarterly review feature documentation
- **Tagging_Reference_for_Analysts.md** - Tag system guide for analysts

---

## ⚙️ Configuration Reference

### Script Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `repoRoot` | string | Required | Path to wiki repository root |
| `excludeDirs` | array | `@("Archive","Templates")` | Directories to exclude from processing |
| `backupMode` | string | `"Create"` | Backup behavior: Create, Delete, None |
| `dictLink` | string | Required | Markdown link to tag dictionary |
| `dictWritePath` | string | Required | File system path for tag dictionary |
| `enableQuarterlyReview` | bool | `$true` | Enable/disable quarterly tracking |

### Azure Pipeline Variables

```yaml
variables:
  repoRoot: '$(Build.SourcesDirectory)/wikiRepo'
  excludeDirs: 'Archive,Templates,Metadata'
  backupMode: 'Create'
  dictLink: '/Wiki/Wiki-Root/Tags/Tag_Dictionary.md'
  dictWritePath: 'Tags/Tag_Dictionary.md'
  enableQuarterlyReview: 'true'
```

---

## 🐛 Troubleshooting

### Tags Not Updating
- Check log file: `Metadata\Tag_Update.log`
- Verify file isn't in excluded directory
- Ensure file has `.md` extension

### Quarterly Baseline Not Created
- Check if baseline already exists for current quarter
- Verify `enableQuarterlyReview` is set to `$true`
- Review log for error messages

### Pipeline Not Running on Schedule
- Verify cron syntax in `azure-pipelines.yml`
- Check branch name in schedule configuration
- Ensure `always: true` is set for schedule

---

## 📜 License

MIT License — feel free to use, modify, and share.

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with detailed description

---

## 📞 Support

For issues or questions:
1. Check the log file: `Metadata\Tag_Update.log`
2. Review documentation in the repository
3. Submit an issue with detailed reproduction steps

---

**Version:** 2.0 (with Quarterly Review)  
**Last Updated:** December 2024  
**PowerShell Version Required:** 5.1+
