---
alwaysApply: false
globs: **/*.lua
---

# GLua Quality Gates & Performance

## 1. Encoding

- **UTF-8**: All `.lua` files MUST be encoded in UTF-8 (without BOM) to prevent parsing errors in Garry's Mod.

## 2. Formatting & Linting

- **glualint**: Code must pass `glualint` without warnings.
- **stylua**: Code must be formatted using `stylua`.
- **Naming Conventions**: Use `CamelCase` for global functions/classes, `snake_case` for local variables. Prefix network strings with your addon's identifier.

## 3. Lua Coding Standards & TTT2 Best Practices

- **TTT2 Standards**: Follow TTT2 specific API conventions. Place TTT2 addon files in `lua/terrortown/autorun/` utilizing the correct `server/`, `client/`, or `shared/` subdirectories.
- **Global Pollution**: Avoid global namespace pollution. Use localized tables and functions where possible.
- **Hooks**: Use standard hooks (`hook.Add`). Always provide unique hook identifiers prefixed with your addon name (e.g., `hook.Add("Think", "MyAddon_Think", ...)`).

## 4. Performance Optimization Guidelines

- **Think Hooks**: Minimize the use of `Think` or `Tick` hooks. If necessary, throttle them using `CurTime()` checks.
- **Networking**: Optimize `net` messages. Send only essential data. Use `net.WriteUInt` or `net.WriteInt` over `net.WriteFloat` when possible. Avoid networking large tables; serialize or send delta updates.
- **Caching**: Cache frequently accessed global functions (e.g., `local math_min = math.min`) inside tight loops.
- **Client-side Rendering**: Keep `HUDPaint` and `PreDrawOpaqueRenderables` lightweight. Avoid creating materials or fonts inside draw hooks; initialize them once globally.
