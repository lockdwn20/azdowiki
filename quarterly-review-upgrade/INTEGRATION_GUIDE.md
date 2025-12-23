# Integration Guide: Adding Quarterly Review to Your Existing Project

## Quick Start

Your Wiki Tag Updater now has **quarterly change tracking**! Here's how to integrate it into your existing project.

---

## What's New?

### Added Features
- ✅ Automatic quarterly baseline creation (JSON snapshots)
- ✅ Change detection (added, deleted, moved, renamed files)
- ✅ Markdown change reports for human review
- ✅ Automatic retention management (1 year of history)
- ✅ Seamless integration with existing tag updates

### Files Added
1. **WikiTools_Enhanced.psm1** - Original functions + 6 new quarterly review functions
2. **Wiki_Metadata_Updates_Enhanced.ps1** - Updated main script with quarterly review
3. **azure-pipelines-enhanced.yml** - Updated pipeline with scheduling options
4. **QUARTERLY_REVIEW_DOCUMENTATION.md** - Complete feature documentation

---

## Integration Steps

### Step 1: Backup Your Current Files

Before making changes, backup your existing files:

```powershell
# Backup current module
Copy-Item WikiTools.psm1 WikiTools.psm1.backup

# Backup current script
Copy-Item Wiki_Metadata_Updates.ps1 Wiki_Metadata_Updates.ps1.backup

# Backup pipeline
Copy-Item azure-pipelines.yml azure-pipelines.yml.backup
```

### Step 2: Replace Module File

Replace your `WikiTools.psm1` with `WikiTools_Enhanced.psm1`:

```powershell
# Option A: Direct replacement
Copy-Item WikiTools_Enhanced.psm1 WikiTools.psm1 -Force

# Option B: Rename if you want to keep both versions
Rename-Item WikiTools.psm1 WikiTools_Original.psm1
Rename-Item WikiTools_Enhanced.psm1 WikiTools.psm1
```

### Step 3: Replace Main Script

Replace your `Wiki_Metadata_Updates.ps1` with `Wiki_Metadata_Updates_Enhanced.ps1`:

```powershell
Copy-Item Wiki_Metadata_Updates_Enhanced.ps1 Wiki_Metadata_Updates.ps1 -Force
```

### Step 4: Update Azure Pipeline (Optional)

If using Azure DevOps pipelines:

```powershell
Copy-Item azure-pipelines-enhanced.yml azure-pipelines.yml -Force
```

Then decide on your scheduling strategy:

#### Option A: Manual/On-Demand (Current Behavior)
Leave the schedule commented out. Quarterly reviews happen automatically when you run the script.

#### Option B: Scheduled Quarterly Runs (Recommended)
Uncomment the schedule section in `azure-pipelines.yml`:

```yaml
schedules:
- cron: "0 0 1 1,4,7,10 *"  # Jan 1, Apr 1, Jul 1, Oct 1 at midnight
  displayName: Quarterly Wiki Review
  branches:
    include:
      - main
  always: true
```

### Step 5: Update Excluded Directories

The new quarterly review uses the same `excludeDirs` as your tag updates. Verify your exclusions:

```powershell
# In Wiki_Metadata_Updates.ps1
param(
    ...
    [string[]]$excludeDirs = @("Archive","Templates","Metadata"),
    ...
)
```

**Note:** You might want to exclude the `Metadata` directory itself from tracking!

### Step 6: Test the Integration

Run a test to verify everything works:

```powershell
# Local test
.\Wiki_Metadata_Updates.ps1 `
    -repoRoot "C:\Your\Wiki\Path" `
    -excludeDirs @("Archive","Templates","Metadata") `
    -backupMode "Create" `
    -enableQuarterlyReview $true
```

Expected output:
```
=== Wiki Update Summary ===
Files Processed: 145
Unique Tags: 87
Log File: C:\Your\Wiki\Path\Metadata\Tag_Update.log

Latest Quarterly Review Report:
C:\Your\Wiki\Path\Metadata\Quarterly_Review\ChangeReport_2025_Q1.md

=== Complete ===
```

---

## What to Expect

### First Run
- ✅ Creates `Metadata\Quarterly_Review\` directory
- ✅ Generates `Baseline_2025_Q1.json` (or current quarter)
- ✅ Creates `ChangeReport_2025_Q1.md` (initial baseline report)
- ✅ Continues with normal tag updates

### Subsequent Runs (Same Quarter)
- ⏭️ Skips baseline creation (already exists)
- ✅ Continues with normal tag updates
- 📝 Log shows: "Baseline already exists for 2025_Q1 - skipping creation"

### First Run of Next Quarter
- ✅ Creates new baseline for current quarter
- ✅ Compares with previous quarter
- ✅ Generates detailed change report
- ✅ Shows added, deleted, moved, renamed files
- ✅ Automatically cleans up baselines older than 1 year

---

## Verification Checklist

After integration, verify:

- [ ] Script runs without errors
- [ ] `Metadata\Quarterly_Review\` directory exists
- [ ] Baseline JSON file created for current quarter
- [ ] Change report MD file exists
- [ ] Tag updates still work correctly
- [ ] Log file shows quarterly review messages
- [ ] No duplicate or missing tags

---

## Directory Structure

After integration, your repo structure will look like:

```
Wiki-Root/
├── scripts/
│   ├── Wiki_Metadata_Updates.ps1     (updated)
│   └── WikiTools.psm1                (updated)
├── Metadata/
│   ├── Tag_Update.log
│   └── Quarterly_Review/
│       ├── Baseline_2025_Q1.json
│       ├── ChangeReport_2025_Q1.md
│       ├── Baseline_2025_Q2.json     (appears next quarter)
│       └── ChangeReport_2025_Q2.md   (appears next quarter)
├── Tags/
│   └── Tag_Dictionary.md
└── [Your Wiki Content]/
```

---

## Configuration Options

### Disable Quarterly Review

If you want to disable the feature temporarily:

```powershell
# In Wiki_Metadata_Updates.ps1
param(
    ...
    [bool]$enableQuarterlyReview = $false
)
```

Or pass it as a parameter:

```powershell
.\Wiki_Metadata_Updates.ps1 -enableQuarterlyReview $false
```

### Change Review Directory

To store quarterly reviews in a different location:

```powershell
# In Wiki_Metadata_Updates.ps1
Invoke-WikiQuarterlyReview `
    -RepoRoot $repoRoot `
    -LogPath $logPath `
    -ExcludeDirs $excludeDirs `
    -ReviewDir "CustomFolder\Reviews"  # Change this path
```

---

## Compatibility

### What's Preserved
All your existing functionality remains unchanged:
- ✅ Tag extraction logic
- ✅ YAML header generation
- ✅ Footer hashtags and HTML comments
- ✅ Backup modes (Create/Delete/None)
- ✅ Tag dictionary generation
- ✅ Exclusion logic
- ✅ Logging system

### What's Added
New functionality runs alongside existing features:
- ✅ Quarterly baseline creation
- ✅ Change comparison
- ✅ Report generation
- ✅ Retention management

### Backward Compatibility
- ✅ Old script parameters still work
- ✅ Existing tag updates unchanged
- ✅ Log format enhanced but compatible
- ✅ Can disable quarterly review if needed

---

## Azure Pipeline Notes

### Pipeline Variables

Update your pipeline variables to include the new option:

```yaml
variables:
  repoRoot: '$(Build.SourcesDirectory)/wikiRepo'
  excludeDirs: 'Archive,Templates,Metadata'  # Add Metadata!
  backupMode: 'Create'
  dictLink: '/Wiki/Wiki-Root/Tags/Tag_Dictionary.md'
  dictWritePath: 'Tags/Tag_Dictionary.md'
  enableQuarterlyReview: 'true'  # NEW
```

### Publishing Artifacts

The enhanced pipeline publishes quarterly review reports as artifacts:

```yaml
- task: PublishBuildArtifacts@1
  displayName: 'Publish Quarterly Review Reports'
  inputs:
    PathtoPublish: '$(repoRoot)/Metadata/Quarterly_Review'
    ArtifactName: 'quarterly-review-reports'
```

Access them in Azure DevOps under:
**Pipelines → Runs → Your Run → Artifacts → quarterly-review-reports**

---

## Rollback Instructions

If you need to revert to the original version:

```powershell
# Restore original files from backups
Copy-Item WikiTools.psm1.backup WikiTools.psm1 -Force
Copy-Item Wiki_Metadata_Updates.ps1.backup Wiki_Metadata_Updates.ps1 -Force
Copy-Item azure-pipelines.yml.backup azure-pipelines.yml -Force

# Optional: Remove quarterly review data
Remove-Item "Metadata\Quarterly_Review" -Recurse -Force
```

---

## Next Steps

1. **Review Documentation**: Read `QUARTERLY_REVIEW_DOCUMENTATION.md` for detailed feature info
2. **Test Locally**: Run the script in a test environment first
3. **Schedule Pipeline**: Decide on manual vs. scheduled quarterly runs
4. **Train Team**: Share the change report format with your team
5. **Set Reminders**: Add calendar reminders for quarterly reviews

---

## Support

### Questions?
- Check `QUARTERLY_REVIEW_DOCUMENTATION.md` for detailed explanations
- Review `Metadata\Tag_Update.log` for execution details
- Test in a non-production environment first

### Issues?
- Verify PowerShell version (5.1+ recommended)
- Check file permissions on the Metadata directory
- Ensure JSON files can be written to the filesystem
- Review log files for error messages

---

## Summary

**What You Get:**
- 📊 Quarterly snapshots of wiki structure
- 📈 Automatic change tracking and reporting
- 📁 1 year of history (4 quarters)
- 🤖 Zero manual effort after setup
- ✅ Full backward compatibility

**What Stays The Same:**
- Tag extraction and generation
- YAML/footer/HTML comment tags
- Backup behavior
- Log format (enhanced but compatible)
- Pipeline integration

**Time to Integrate:** ~15 minutes
**Effort Required:** Minimal (mostly copy/paste)
**Risk Level:** Low (easily reversible)

---

Ready to integrate? Follow the steps above and you'll be tracking quarterly changes in no time! 🚀
