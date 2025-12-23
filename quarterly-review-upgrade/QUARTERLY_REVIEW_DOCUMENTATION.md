# Quarterly Review Feature Documentation

## Overview

The **Quarterly Review System** automatically tracks changes to your wiki structure over time, creating snapshots at the beginning of each quarter and generating detailed change reports. This helps maintain naming standards and provides visibility into wiki evolution.

---

## How It Works

### Automatic Detection
- The script automatically determines the current quarter (Q1, Q2, Q3, Q4)
- Creates a baseline snapshot if one doesn't exist for the current quarter
- Compares against the previous quarter to generate a change report
- Maintains up to 4 quarters (1 year) of history

### Quarterly Schedule
- **Q1**: January 1 - March 31
- **Q2**: April 1 - June 30
- **Q3**: July 1 - September 30
- **Q4**: October 1 - December 31

### What Gets Tracked

For each file:
- ✅ Relative path from repo root
- ✅ Filename
- ✅ Last modified timestamp
- ✅ Directory structure/hierarchy

### Change Detection

The system identifies:
1. **Added Files** - New files that didn't exist in the previous quarter
2. **Deleted Files** - Files that existed previously but are now gone
3. **Moved Files** - Files that changed directory location
4. **Renamed Files** - Files that changed name but stayed in the same directory

---

## File Structure

All quarterly review files are stored in: `Metadata\Quarterly_Review\`

### Baseline Files (JSON)
```
Baseline_2025_Q1.json
Baseline_2025_Q2.json
Baseline_2025_Q3.json
Baseline_2025_Q4.json
```

**Example Baseline Structure:**
```json
{
  "Quarter": "2025_Q1",
  "Timestamp": "2025-01-01T00:00:00",
  "RepoRoot": "Wiki-Root",
  "FileCount": 145,
  "DirCount": 28,
  "Files": [
    {
      "RelativePath": "CSIRT\\Incident-Response.md",
      "FileName": "Incident-Response.md",
      "LastModified": "2024-12-15T10:30:00",
      "Directory": "CSIRT"
    }
  ],
  "Directories": [
    "CSIRT",
    "CSIRT\\Playbooks",
    "Templates"
  ]
}
```

### Change Reports (Markdown)
```
ChangeReport_2025_Q1.md
ChangeReport_2025_Q2.md
ChangeReport_2025_Q3.md
ChangeReport_2025_Q4.md
```

**Example Change Report:**
```markdown
# Quarterly Wiki Review - 2025_Q2

**Review Date:** 2025-04-01 10:30:00
**Previous Quarter:** 2025_Q1
**Previous File Count:** 145
**Current File Count:** 158
**Net Change:** +13 files

---

## 📊 Changes Summary

- **Added:** 15 files
- **Deleted:** 3 files
- **Moved/Renamed:** 5 files
- **New Directories:** 2
- **Removed Directories:** 0

---

## ✅ Added Files (15)

- `CSIRT/New-Playbook.md` (Modified: 2025-03-15T14:30:00)
- `CSIRT/Updated-Process.md` (Modified: 2025-03-20T09:15:00)
...

## ❌ Deleted Files (3)

- `Archive/Old-Process.md`
- `Templates/Deprecated-Template.md`
...

## 🔄 Moved/Renamed Files (5)

- `Old/Path/File.md` → `New/Path/File.md` [Moved]
- `CSIRT/Old-Name.md` → `CSIRT/New-Name.md` [Renamed]
...
```

---

## Setup & Configuration

### 1. Enable in Main Script

The feature is **enabled by default**. To disable:

```powershell
# In Wiki_Metadata_Updates.ps1
param(
    ...
    [bool]$enableQuarterlyReview = $false  # Set to false to disable
)
```

### 2. Local Execution

Run the script normally - quarterly review runs automatically:

```powershell
.\Wiki_Metadata_Updates.ps1 `
    -repoRoot "C:\Path\To\Wiki" `
    -excludeDirs @("Archive","Templates") `
    -enableQuarterlyReview $true
```

### 3. Azure Pipeline Configuration

#### Option A: Manual Runs with Auto-Detection (Current)
The pipeline runs when manually triggered or on code changes. The quarterly review logic runs automatically and creates baselines/reports as needed.

#### Option B: Scheduled Quarterly Runs (Recommended)

Uncomment the schedule block in `azure-pipelines.yml`:

```yaml
schedules:
- cron: "0 0 1 1,4,7,10 *"  # Jan 1, Apr 1, Jul 1, Oct 1 at midnight UTC
  displayName: Quarterly Wiki Review
  branches:
    include:
      - main
  always: true  # Run even if no code changes
```

**Cron Syntax Breakdown:**
```
0 0 1 1,4,7,10 *
│ │ │ │       └─ Any year
│ │ │ └───────── Months: January, April, July, October
│ │ └─────────── Day: 1st
│ └───────────── Hour: 00 (midnight)
└─────────────── Minute: 00
```

#### Timezone Considerations
- Azure DevOps schedules use UTC time
- Adjust the hour if you need a specific local time
- Example: For 9 AM EST (UTC-5), use `"0 14 1 1,4,7,10 *"`

---

## Behavior & Logic

### First Run (Initial Baseline)
When no previous baseline exists:
- ✅ Creates baseline for current quarter
- ✅ Generates initial report (no changes)
- ✅ Sets up foundation for future comparisons

### Subsequent Runs (Same Quarter)
If a baseline already exists for the current quarter:
- ⏭️ Skips baseline creation
- ⏭️ Logs "Baseline already exists" message
- ✅ Continues with normal tag updates

### New Quarter Detected
When the quarter changes:
- ✅ Creates new baseline for current quarter
- ✅ Compares with previous quarter baseline
- ✅ Generates detailed change report
- ✅ Identifies added, deleted, moved, renamed files

### Retention Management
Automatically maintains 1 year of history:
- Keeps the 4 most recent baselines
- Deletes older baselines and reports
- Prevents unbounded growth

---

## Using the Change Reports

### Review Process

1. **Open the Latest Report**
   ```
   Metadata\Quarterly_Review\ChangeReport_2025_Q2.md
   ```

2. **Review Each Section**
   - ✅ **Added Files**: Verify naming conventions and placement
   - ❌ **Deleted Files**: Confirm intentional removals
   - 🔄 **Moved/Renamed**: Check tag consistency
   - 📁 **New Directories**: Validate organizational structure

3. **Use the Checklist**
   Every report includes a checklist:
   ```markdown
   ## 📋 Review Checklist
   
   - [ ] All new files follow naming conventions (descriptive, hyphen-delimited)
   - [ ] Deleted files were intentionally removed or archived
   - [ ] Moved/renamed files maintain tag consistency
   - [ ] New directories align with wiki organizational structure
   - [ ] No orphaned or misplaced content
   ```

### Integration with Analyst Workflow

The quarterly review complements your existing tag system:

```
┌─────────────────────────────────────┐
│   Continuous: Tag Updates           │
│   - YAML headers                    │
│   - Footer hashtags                 │
│   - HTML comment tags               │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Quarterly: Structure Review       │
│   - Baseline snapshots              │
│   - Change reports                  │
│   - Naming standard verification    │
└─────────────────────────────────────┘
```

---

## Advanced Scenarios

### Testing Baseline Creation

To manually trigger a baseline for the current quarter:

```powershell
Import-Module .\WikiTools.psm1

Invoke-WikiQuarterlyReview `
    -RepoRoot "C:\Path\To\Wiki" `
    -LogPath "C:\Path\To\Wiki\test.log" `
    -ExcludeDirs @("Archive","Templates")
```

### Viewing Baseline Data

Baselines are JSON files and can be inspected:

```powershell
$baseline = Get-Content "Metadata\Quarterly_Review\Baseline_2025_Q1.json" | ConvertFrom-Json
Write-Host "Files tracked: $($baseline.FileCount)"
Write-Host "Directories: $($baseline.DirCount)"
$baseline.Files | Format-Table RelativePath, LastModified
```

### Comparing Specific Quarters

To manually compare two specific baselines:

```powershell
Compare-WikiQuarterlyBaselines `
    -PreviousBaselineFile "Metadata\Quarterly_Review\Baseline_2025_Q1.json" `
    -CurrentBaselineFile "Metadata\Quarterly_Review\Baseline_2025_Q2.json" `
    -ReportDir "Metadata\Quarterly_Review" `
    -Quarter "2025_Q2_Custom" `
    -LogPath "comparison.log"
```

### Excluding Directories from Tracking

Same exclusions used for tag updates apply to quarterly reviews:

```powershell
# These directories won't be tracked in baselines
-excludeDirs @("Archive", "Templates", "Drafts", "Personal")
```

---

## Troubleshooting

### Issue: No Report Generated

**Symptom:** Baseline created but no change report
**Cause:** No previous baseline exists (first quarter)
**Solution:** Normal behavior - wait until next quarter

### Issue: Baseline Already Exists

**Symptom:** Log shows "Baseline already exists for 2025_Q2 - skipping creation"
**Cause:** Script already ran this quarter
**Solution:** Normal behavior - to force recreation, delete the existing baseline file

### Issue: Wrong Quarter Detected

**Symptom:** Creating baseline for unexpected quarter
**Cause:** System date might be incorrect or timezone issue
**Solution:** Check server/container date with `Get-Date`

### Issue: Old Baselines Not Deleted

**Symptom:** More than 4 baseline files exist
**Cause:** Retention cleanup runs only when a new baseline is created
**Solution:** Manual cleanup or wait for next quarter

---

## Log Messages

The quarterly review system logs detailed information:

```
2025-04-01 00:00:15 [INFO] === Starting Quarterly Review Process ===
2025-04-01 00:00:16 [INFO] Creating quarterly baseline for 2025_Q2
2025-04-01 00:00:16 [INFO] Created baseline directory: C:\Wiki\Metadata\Quarterly_Review
2025-04-01 00:00:22 [INFO] Baseline created: Baseline_2025_Q2.json (158 files, 32 directories)
2025-04-01 00:00:23 [INFO] Comparing baselines for 2025_Q2
2025-04-01 00:00:25 [INFO] Change report created: ChangeReport_2025_Q2.md
2025-04-01 00:00:25 [INFO] Summary - Added: 15, Deleted: 3, Moved/Renamed: 5
2025-04-01 00:00:26 [INFO] Removed old baseline: Baseline_2024_Q2.json
2025-04-01 00:00:26 [INFO] Removed old report: ChangeReport_2024_Q2.md
2025-04-01 00:00:26 [INFO] === Quarterly Review Process Complete ===
```

---

## Future Enhancements

Potential additions for future versions:

- **Content hash comparison** for detecting file content changes
- **Tag evolution tracking** showing how tags change over time
- **Naming convention violation detection** with automated warnings
- **Quarterly metrics dashboard** with visualizations
- **Email notifications** for new quarterly reports
- **API integration** for dashboard/reporting tools

---

## Support & Feedback

For issues or feature requests related to the quarterly review system:
1. Check the log file: `Metadata\Tag_Update.log`
2. Review generated reports in: `Metadata\Quarterly_Review\`
3. Submit feedback using your organization's process

---

*Last Updated: December 2024*
*Feature Version: 1.0*
