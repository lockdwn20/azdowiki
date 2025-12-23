# Wiki Tag Updater - Quarterly Review Enhancement Package

## 📦 Package Contents

This package contains everything you need to add quarterly change tracking to your existing Wiki Tag Updater project.

---

## 📄 Core Files (Replace Existing)

### 1. **WikiTools_Enhanced.psm1**
- **Purpose:** Enhanced PowerShell module with quarterly review functions
- **Action:** Replace your existing `WikiTools.psm1`
- **Changes:**
  - All original functions preserved (100% backward compatible)
  - 6 new functions added for quarterly baseline tracking
  - Export list updated to include new functions

### 2. **Wiki_Metadata_Updates_Enhanced.ps1**
- **Purpose:** Updated main execution script
- **Action:** Replace your existing `Wiki_Metadata_Updates.ps1`
- **Changes:**
  - Calls `Invoke-WikiQuarterlyReview` before tag updates
  - New parameter: `$enableQuarterlyReview` (default: `$true`)
  - Enhanced console output showing quarterly report location
  - Creates `Metadata\` directory if it doesn't exist

### 3. **azure-pipelines-enhanced.yml**
- **Purpose:** Updated Azure DevOps pipeline configuration
- **Action:** Replace your existing `azure-pipelines.yml`
- **Changes:**
  - Commented-out quarterly schedule (ready to enable)
  - New variable: `enableQuarterlyReview`
  - Artifact publishing for quarterly reports
  - Enhanced logging output

---

## 📚 Documentation Files

### 4. **INTEGRATION_GUIDE.md**
- **Start here!** Step-by-step instructions for adding the feature
- Backup procedures
- Testing instructions
- Rollback steps if needed
- Compatibility information

### 5. **QUARTERLY_REVIEW_DOCUMENTATION.md**
- Complete feature documentation
- How the system works
- File formats and structures
- Configuration options
- Troubleshooting guide
- Advanced scenarios

---

## 📊 Example Files (Reference Only)

### 6. **EXAMPLE_Baseline_2025_Q2.json**
- **Purpose:** Shows what a quarterly baseline looks like
- **Contains:** Sample JSON structure with file/directory metadata
- **Use:** Reference to understand data format

### 7. **EXAMPLE_ChangeReport_2025_Q2.md**
- **Purpose:** Shows what a quarterly change report looks like
- **Contains:** Sample markdown report with all sections
- **Use:** Reference to understand report format

---

## 🚀 Quick Start

### Option 1: Full Integration (Recommended)
1. Read `INTEGRATION_GUIDE.md`
2. Backup existing files
3. Replace the 3 core files
4. Test locally
5. Deploy to pipeline

### Option 2: Review First
1. Read `QUARTERLY_REVIEW_DOCUMENTATION.md`
2. Review example files
3. Decide if you want the feature
4. Follow Option 1 if yes

---

## 📂 New Directory Structure

After integration, your project will have:

```
Your-Wiki-Repo/
├── scripts/
│   ├── Wiki_Metadata_Updates.ps1          (updated)
│   └── WikiTools.psm1                     (updated)
│
├── Metadata/                              (existing)
│   ├── Tag_Update.log
│   └── Quarterly_Review/                  (NEW)
│       ├── Baseline_2025_Q1.json
│       ├── ChangeReport_2025_Q1.md
│       ├── Baseline_2025_Q2.json         (next quarter)
│       └── ChangeReport_2025_Q2.md       (next quarter)
│
├── Tags/
│   └── Tag_Dictionary.md
│
└── [Your Wiki Content]/
```

---

## ✨ Key Features Added

1. **Automatic Baseline Creation**
   - Runs at the start of each quarter
   - Creates JSON snapshot of entire wiki structure
   - No manual intervention required

2. **Change Detection**
   - Compares current quarter with previous
   - Identifies: Added, Deleted, Moved, Renamed files
   - Detects directory changes

3. **Change Reports**
   - Markdown format for easy reading
   - Includes review checklist
   - Shows file counts and statistics

4. **Retention Management**
   - Automatically keeps 4 quarters (1 year)
   - Deletes older baselines and reports
   - Prevents unlimited growth

5. **Smart Logic**
   - Only creates baseline once per quarter
   - Handles first run (initial baseline) gracefully
   - Integrates seamlessly with existing tag updates

---

## 🎯 What Doesn't Change

Your existing functionality is **completely preserved**:
- ✅ Tag extraction from paths
- ✅ YAML header generation
- ✅ Footer hashtags
- ✅ HTML comment tags
- ✅ Tag dictionary
- ✅ Backup modes
- ✅ Exclusion logic
- ✅ Logging system

---

## ⚙️ Configuration

### Enable/Disable Feature
```powershell
# In script
-enableQuarterlyReview $true   # Enable (default)
-enableQuarterlyReview $false  # Disable

# In pipeline YAML
enableQuarterlyReview: 'true'  # Enable
enableQuarterlyReview: 'false' # Disable
```

### Schedule Pipeline Runs
```yaml
# Uncomment in azure-pipelines.yml
schedules:
- cron: "0 0 1 1,4,7,10 *"  # Jan 1, Apr 1, Jul 1, Oct 1
  displayName: Quarterly Wiki Review
  branches:
    include:
      - main
  always: true
```

### Exclude Directories
```powershell
# Same exclusions apply to both tag updates AND quarterly reviews
-excludeDirs @("Archive", "Templates", "Metadata")
```

---

## 🔍 What to Review

Before integrating, review these sections in the documentation:

1. **Integration Guide:**
   - [ ] Backup procedures
   - [ ] File replacement steps
   - [ ] Testing instructions

2. **Feature Documentation:**
   - [ ] How quarterly detection works
   - [ ] Baseline file format
   - [ ] Change report format
   - [ ] Retention policy

3. **Example Files:**
   - [ ] Sample baseline JSON structure
   - [ ] Sample change report format

---

## ⏱️ Timeline

### First Quarter (Q1 2025)
- ✅ Creates initial baseline
- ✅ Generates initial report (no changes)
- 📝 "This is the first quarterly baseline"

### Second Quarter (Q2 2025)
- ✅ Creates new baseline
- ✅ Compares Q2 vs Q1
- ✅ Generates full change report
- 📊 Shows added, deleted, moved files

### Third Quarter (Q3 2025)
- ✅ Creates new baseline
- ✅ Compares Q3 vs Q2
- ✅ Generates full change report

### Fourth Quarter (Q4 2025)
- ✅ Creates new baseline
- ✅ Compares Q4 vs Q3
- ✅ Generates full change report

### First Quarter (Q1 2026)
- ✅ Creates new baseline
- ✅ Compares Q1 2026 vs Q4 2025
- 🗑️ **Deletes Q1 2025** (older than 1 year)

---

## 📊 Azure DevOps Integration

### Viewing Reports in Pipeline

After each run, reports are published as artifacts:

1. Navigate to: **Pipelines → Runs → [Your Run]**
2. Click: **Artifacts**
3. Download: **quarterly-review-reports**
4. Open: `ChangeReport_YYYY_QX.md`

### Scheduling Options

**Option A:** Manual trigger + auto-detection
- Run pipeline manually whenever needed
- Quarterly review runs automatically if it's a new quarter

**Option B:** Scheduled quarterly runs
- Uncomment schedule block in pipeline YAML
- Runs automatically on Jan 1, Apr 1, Jul 1, Oct 1

---

## 🛠️ Troubleshooting

### "No baseline created"
- Check: Is it a new quarter?
- Check: Does baseline already exist?
- Solution: Delete existing baseline to force recreation

### "No change report"
- Check: Is this the first quarter?
- Solution: Normal - wait until next quarter

### "Too many baselines"
- Check: Are they more than 1 year old?
- Solution: Manually delete or wait for auto-cleanup

### "Log shows errors"
- Check: `Metadata\Tag_Update.log`
- Solution: Review error message and check permissions

---

## 📞 Support

### Questions?
1. Read `INTEGRATION_GUIDE.md` for step-by-step instructions
2. Read `QUARTERLY_REVIEW_DOCUMENTATION.md` for detailed feature info
3. Check example files for format references
4. Review log files for execution details

### Issues?
1. Verify PowerShell version (5.1+ recommended)
2. Check file system permissions
3. Ensure JSON can be written
4. Test in non-production first

---

## 📈 Success Metrics

After successful integration, you'll have:
- ✅ Quarterly baseline JSON files
- ✅ Quarterly change reports in markdown
- ✅ Automated retention management
- ✅ Enhanced visibility into wiki changes
- ✅ Better naming standard compliance tracking
- ✅ Historical audit trail (1 year)

---

## 🎉 Benefits

### For Analysts
- 📊 Clear visibility into wiki evolution
- 📈 Easy-to-read change summaries
- ✅ Built-in review checklists
- 📁 Historical tracking

### For Management
- 📑 Quarterly audit reports
- 📊 Growth metrics and trends
- ✅ Naming standard compliance
- 📈 Team activity tracking

### For Operations
- 🤖 Fully automated process
- 🔄 Zero manual intervention
- 💾 Automatic retention management
- 📝 Detailed logging

---

## 📋 Checklist

Before deploying to production:
- [ ] Read integration guide
- [ ] Read feature documentation
- [ ] Review example files
- [ ] Backup existing files
- [ ] Test in non-production environment
- [ ] Verify baseline creation
- [ ] Verify change report format
- [ ] Update pipeline configuration
- [ ] Train team on new reports
- [ ] Set quarterly review reminders

---

## Version Information

**Package Version:** 1.0  
**Release Date:** December 2024  
**Compatible With:** Existing Wiki Tag Updater (all versions)  
**PowerShell Version:** 5.1+  
**Azure DevOps:** Compatible with all recent versions  

---

## File Manifest

| File | Type | Size | Purpose |
|------|------|------|---------|
| WikiTools_Enhanced.psm1 | Module | ~22 KB | Core functionality |
| Wiki_Metadata_Updates_Enhanced.ps1 | Script | ~3 KB | Main execution |
| azure-pipelines-enhanced.yml | YAML | ~2 KB | Pipeline config |
| INTEGRATION_GUIDE.md | Docs | ~15 KB | Integration steps |
| QUARTERLY_REVIEW_DOCUMENTATION.md | Docs | ~25 KB | Feature docs |
| EXAMPLE_Baseline_2025_Q2.json | Example | ~2 KB | JSON reference |
| EXAMPLE_ChangeReport_2025_Q2.md | Example | ~5 KB | Report reference |
| PACKAGE_README.md | Docs | ~8 KB | This file |

**Total Package Size:** ~82 KB

---

Ready to enhance your Wiki Tag Updater with quarterly change tracking? Start with `INTEGRATION_GUIDE.md`! 🚀
