# 🧩 Tagging Reference for Analysts

## 1. YAML Tags
**Format:**
```yaml
---
title: CSIRT Incident Response Playbook
description: 
tags:
  - CSIRT
  - Incident 
  - Response
  - Playbook
---
```

- Visible? Yes, in the page header
- Purpose: Structured metadata
- Benefits for Analysts:
    - Instantly searchable on commit
    - Powers navigation menus and dashboards
    - Automation‑ready for pipelines and reports

## 2. Footer #tags
**Format:**
```text
#CSIRT #Workflow #Policy
```

- Visible? Yes, at the bottom of the page
- Purpose: Lightweight categorization
- Benefits for Analysts:
    - Quick search keywords
    - No overhead, easy to add
    - Human‑friendly cues for page context

## 3. HTML Comment Tags
**Format:**
```HTML
<!-- Tag: AuditTrail -->
<!-- Tag: ExecutiveSummary -->
```

- Visible? No, hidden in source
- Purpose: Invisible enrichment metadata
- Benefits for Analysts:
    - Still searchable in the repo
    - Can be parsed by automation pipelines
    - Enables Splunk → TheHive enrichment (alerts auto‑link to relevant wiki pages)

## Analyst Takeaway
- YAML tags = structured, automation‑ready
- Footer tags = lightweight, human‑friendly
- HTML tags = invisible, enrichment hooks

Together, these give analysts three layers of metadata: visible, lightweight, and invisible — all designed to make searches faster, navigation easier, and alerts smarter.