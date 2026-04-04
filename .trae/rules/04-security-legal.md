---
alwaysApply: true
---

# Security & Legal Compliance

## 1. Copyright & Licensing

- **No Valve/BSP Leaks**: Do not redistribute copyrighted Valve assets, proprietary models, or decompiled BSP content.
- **License**: All public addons must include a GPL-compatible license (e.g., MIT, GPLv3).

## 2. Secrets Management

- **API Keys**: Never hardcode Steam API keys, tokens, or passwords in the source code. The CI/CD pipeline or validation scripts will scan for regex patterns resembling keys (e.g., `^[0-9A-F]{32}$`).

## 3. Security Considerations & Exploit Prevention

- **Network Exploits**: Always validate client input on the server in `net.Receive`. Never trust data sent from the client (e.g., verify player distances, item ownership, and role statuses).
- **RunString / CompileString**: Strictly avoid using `RunString` or `CompileString` on dynamically generated code or client-provided strings.
- **File Access**: Do not use `file.Read` or `file.Write` with unvalidated user paths to prevent directory traversal attacks.
- **SQL Injections**: If interacting with databases, always use parameterized queries or `sql.SQLStr` to escape input.
- **Anti-Cheat Awareness**: Avoid obfuscating or encrypting `.lua` files. This is often flagged as malicious behavior by server anti-cheats and violates Steam Workshop guidelines.
