# Balatro Multiplayer Lua Style Guide

The Balatro Multiplayer Mod codebase follows the rules below. Each rule identifier leaves room for future insertions.

## Formatting

**BMPLUA0010 – Indentation and whitespace**
Use hard tabs for indentation and avoid mixing in spaces; table literals should align their keys and values on tab stops as in `core.lua`. 【F:stylua.toml†L3-L16】【F:core.lua†L3-L159】

**BMPLUA0020 – Line length**
Limit source lines to 120 characters; favour breaking long expressions across multiple lines using table entries or logical groupings. 【F:stylua.toml†L4-L10】【F:ui/lobby.lua†L63-L115】

**BMPLUA0030 – Blank lines**
Separate top-level declarations (tables, functions, constants) with a single blank line to keep related blocks distinct. 【F:core.lua†L34-L68】【F:misc/insane_int.lua†L7-L87】

**BMPLUA0040 – Parentheses and calls**
Always include parentheses on function calls, even when no arguments are supplied, and avoid inserting a space between a function name and its parentheses. 【F:stylua.toml†L8-L16】【F:ui/lobby.lua†L63-L117】

**BMPLUA0050 – Trailing commas**
Keep trailing commas in multi-line table constructors to minimise diff churn when adding new entries. 【F:core.lua†L14-L123】【F:gamemodes/attrition.lua†L1-L37】

**BMPLUA0060 – Comment style**
Use single-line `--` comments for inline notes and documentation; keep them aligned with the code they describe, and prefer blank comment lines for section breaks. 【F:networking/socket.lua†L1-L60】【F:misc/insane_int.lua†L1-L33】

## Naming Conventions

**BMPLUA0070 – Namespaces and globals**
Treat `MP`, `G`, and other pre-existing global namespaces as PascalCase anchors; extend them with descriptive fields using dot notation (e.g., `MP.ACTIONS`, `G.UIDEF`). 【F:core.lua†L1-L37】【F:ui/lobby.lua†L12-L118】

**BMPLUA0080 – Functions and methods**
Name public mod functions with snake_case verbs that describe their behaviour (e.g., `reset_lobby_config`, `load_mp_file`), while callbacks inherited from external APIs retain the casing they expect. 【F:core.lua†L51-L124】【F:networking/action_handlers.lua†L29-L142】

**BMPLUA0090 – Local variables**
Use succinct camelCase for short-lived loop counters or coroutine controls (e.g., `requestsPerCycle`, `keepAliveInitialTimeout`) and snake_case for persisted state fields (e.g., `ready_to_start`, `keep_alive`). 【F:networking/socket.lua†L33-L87】【F:networking/action_handlers.lua†L39-L142】

**BMPLUA0100 – File and module names**
Name Lua files with lowercase snake_case to reflect their feature (e.g., `networking/action_handlers.lua`, `gamemodes/attrition.lua`); reserve leading underscores for bootstrap registries and uppercase for compatibility shims mirroring external mods. 【F:gamemodes/_gamemodes.lua†L1-L32】【F:compatibility/TheOrder.lua†L1-L44】

**BMPLUA0110 – Constants**
Express constant configuration values and lookups in uppercase snake case within their namespace (e.g., `MP.BANNED_MODS`, `G.C.MULTIPLAYER`). 【F:core.lua†L3-L49】【F:networking/socket.lua†L24-L71】

## Language Constructs & Syntax Rules

**BMPLUA0120 – Module loading**
Load subsidiary Lua files through `MP.load_mp_file` or `MP.load_mp_dir` to ensure consistent sandboxing and logging. 【F:core.lua†L55-L91】

**BMPLUA0130 – Table iteration**
Prefer `ipairs` for ordered collections and `pairs` for associative tables, matching the codebase’s use when iterating lobby lists, ban tables, and configuration maps. 【F:core.lua†L74-L87】【F:networking/action_handlers.lua†L49-L158】

**BMPLUA0140 – Safe execution**
Wrap dynamic loads in `pcall` and surface failures through the logging helpers instead of throwing raw errors. 【F:core.lua†L55-L68】

**BMPLUA0150 – Conditional clarity**
Favour early returns and guard clauses over deeply nested conditionals to keep networking handlers readable. 【F:networking/action_handlers.lua†L129-L220】

**BMPLUA0160 – String handling**
Use Lua’s string library for parsing network payloads and configuration strings, encapsulating repeated logic in helper functions like `parseName`. 【F:networking/action_handlers.lua†L49-L82】

## Code Structure & Organization

**BMPLUA0170 – Directory layout**
Organise features by domain: networking, UI, gamemodes, rulesets, misc utilities, and compatibility patches each live in dedicated directories loaded from `core.lua`. 【F:core.lua†L55-L124】【F:README.md†L1-L40】

**BMPLUA0180 – Bootstrap order**
Keep registry files (prefixed with `_`) responsible for extending SMODS registries and ensure they execute before individual content files. 【F:gamemodes/_gamemodes.lua†L1-L32】【F:rulesets/_rulesets.lua†L1-L88】

**BMPLUA0190 – Function scope**
Limit local helper functions to the file where they are used (e.g., `send_lobby_options`, `begin_pvp_blind`) and expose only behaviour that needs to be reused across modules. 【F:ui/lobby.lua†L5-L118】【F:networking/action_handlers.lua†L29-L142】

**BMPLUA0200 – Import grouping**
Place `require` calls and namespace aliases at the top of each file before declarations to make dependencies explicit. 【F:networking/action_handlers.lua†L1-L28】【F:networking/socket.lua†L1-L33】

## Documentation & Comments

**BMPLUA0210 – API annotations**
Use EmmyLua-style annotations (`---@param`, `---@return`) when documenting function parameters or return types exposed to other modules. 【F:networking/action_handlers.lua†L115-L147】

**BMPLUA0220 – TODOs and notes**
Prefix work-in-progress notes with `-- TODO:` and keep them actionable; these TODOs should remain close to the logic they reference. 【F:networking/action_handlers.lua†L84-L99】

**BMPLUA0230 – Intent-first comments**
Employ comments to describe intent, edge cases, or integration context rather than restating obvious code. 【F:compatibility/TheOrder.lua†L1-L44】【F:networking/socket.lua†L24-L73】

## Error Handling & Logging

**BMPLUA0240 – Logging helpers**
Route informational, warning, and error messages through the provided helpers (`sendDebugMessage`, `sendWarnMessage`, `sendErrorMessage`, `sendTraceMessage`) so that UI overlays and consoles stay consistent. 【F:core.lua†L55-L127】【F:networking/action_handlers.lua†L5-L220】

**BMPLUA0250 – Graceful degradation**
On recoverable failures (e.g., lost network connections) reset state and notify the UI rather than crashing threads outright. 【F:networking/socket.lua†L33-L100】【F:networking/action_handlers.lua†L97-L220】

**BMPLUA0260 – Validation checks**
Validate incoming data (bounds-check blind colours, ensure scores parse) before mutating shared state to avoid corrupted lobbies. 【F:networking/action_handlers.lua†L49-L210】

## Testing Standards

**BMPLUA0270 – Manual verification focus**
Because the project embeds into Balatro, tests centre on in-game verification; ensure lobby interactions and network flows are exercised manually after changes. 【F:README.md†L17-L40】【F:networking/action_handlers.lua†L29-L220】

**BMPLUA0280 – Configuration safeguards**
When altering lobby defaults or timers, verify host/guest synchronisation paths (`lobby_info`, `sync_client`) continue to operate using representative seeds. 【F:core.lua†L93-L160】【F:networking/action_handlers.lua†L39-L127】

## Performance & Security Guidelines

**BMPLUA0290 – Cooperative yielding**
In threaded networking code, yield coroutines regularly (`requestsPerCycle`, timers) to prevent locking the Love2D thread. 【F:networking/socket.lua†L33-L103】

**BMPLUA0300 – Rate limits**
Guard loops with cycle limits (e.g., process at most 25 messages per frame) and throttle keep-alive retries to avoid flooding the server. 【F:networking/socket.lua†L33-L98】

**BMPLUA0310 – Input sanitisation**
Clamp user-supplied values like blind colour indices and validate lobby payloads before use. 【F:networking/action_handlers.lua†L49-L210】

## Tooling & Automation

**BMPLUA0320 – Formatter**
Run `stylua` with the repository’s configuration before committing Lua code to enforce spacing, quoting, and wrapping rules. 【F:stylua.toml†L1-L16】

**BMPLUA0330 – Logging infrastructure**
Leverage the built-in logging endpoints to trace issues instead of introducing ad-hoc print statements, which aids remote debugging. 【F:networking/action_handlers.lua†L5-L220】

**BMPLUA0340 – Build integration**
Ensure new files are loaded through `MP.load_mp_file`/`MP.load_mp_dir` or the appropriate registry list so they execute when the mod boots. 【F:core.lua†L55-L124】【F:gamemodes/_gamemodes.lua†L1-L32】

## Philosophy / Guiding Principles

**BMPLUA0350 – Readability over cleverness**
Favour explicit, readable logic (clear helper functions, descriptive tables) over terse idioms to support contributors of varying Lua experience. 【F:networking/action_handlers.lua†L29-L220】【F:ui/lobby.lua†L45-L118】

**BMPLUA0360 – Multiplayer parity**
Keep host and guest experiences symmetrical; shared structures such as lobby config tables should be the single source of truth for UI and gameplay. 【F:core.lua†L93-L160】【F:networking/action_handlers.lua†L39-L210】

**BMPLUA0370 – Compatibility respect**
When integrating with other mods or the base game, mirror their APIs carefully (see `compatibility/TheOrder.lua`) to avoid breaking upstream behaviour. 【F:compatibility/TheOrder.lua†L1-L60】

