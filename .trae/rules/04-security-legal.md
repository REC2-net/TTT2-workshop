---
alwaysApply: true
description: "Security and legal compliance rules."
---

# Security & Legal Compliance

## 1. Copyright & Licensing

- **No Valve/BSP Leaks**: Do not redistribute copyrighted Valve assets, proprietary models, or decompiled BSP content.
- **License**: All public addons must include a GPL-compatible license (e.g., MIT, GPLv3).

## 2. Secrets Management

- **API Keys**: Never hardcode Steam API keys, tokens, or passwords in the source code. The CI/CD pipeline or validation scripts will scan for regex patterns resembling keys (e.g., `^[0-9A-F]{32}$`).
