# Queue behaviour in Balatro Multiplayer

This document explains how the mod sequences the different random "queues" (shop offers, consumables, vouchers, etc.) and how
that logic changes when **The Order** integration is enabled. Understanding these queues is critical when debugging
synchronisation issues because every player advances the same deterministic RNG streams as long as they consume the same number
of entries from each queue.

## Terminology and prerequisites

* **Queue** – A deterministic sequence produced by calling `pseudorandom`/`pseudorandom_element` with a particular seed key. The
  key usually concatenates a prefix describing the queue with the current ante. The seed produces the same value on every client
  until one player advances the queue by drawing from it.
* **Ante** – `G.GAME.round_resets.ante` increments whenever the run advances to the next round and is used by many vanilla seeds
  to make their queues reset each ante.【F:ui/game.lua†L1801-L1806】
* **The Order** – Optional lobby integration that is on by default when a multiplayer lobby is created.【F:core.lua†L51-L123】 The
  helper `MP.should_use_the_order()` is used throughout the code base to gate the altered queue behaviour.【F:core.lua†L51-L53】

Two helpers are worth remembering:

* `MP.ante_based()` returns the current ante when The Order is disabled and `0` when it is enabled, making any queue keyed with it
  global across all antes.【F:compatibility/TheOrder.lua†L276-L279】
* `MP.order_round_based(ante_based)` keeps deck shuffles deterministic between players. With The Order it incorporates both the
  ante and the active blind key, otherwise it falls back to the ante only.【F:compatibility/TheOrder.lua†L282-L289】

## Vanilla queues (The Order disabled)

When The Order is turned off, all calls to the patched helpers fall back to their vanilla behaviour. `create_card` simply calls
through to the original implementation, so the game uses its stock `key_append` values (which vary per shop slot, pack, etc.) and
never rewrites the ante.【F:compatibility/TheOrder.lua†L3-L24】 As a result:

* **Shop category (Joker/Tarot/Planet/etc.)** – Uses the seed `"cdt" .. G.GAME.round_resets.ante`, so the queue resets at the
  start of every ante.【F:lovely/TheOrder.toml†L78-L86】【F:compatibility/TheOrder.lua†L276-L279】
* **Booster pack contents** – Seeds with `(_key or "pack_generic") .. G.GAME.round_resets.ante`, giving each ante its own pack
  queue.【F:lovely/TheOrder.toml†L52-L59】【F:compatibility/TheOrder.lua†L276-L279】
* **Voucher shop** – Falls back to the vanilla `SMODS.get_next_vouchers`/`get_next_voucher_key`, which run directly on the pool's
  queue without any deduplication logic.【F:compatibility/TheOrder.lua†L236-L274】 Because the underlying vanilla seed already
  depends on the ante, voucher ordering resets each round.
* **Rarity resample** – Vanilla appends `"_resample" .. it` to the pool key, so repeatedly resampling walks forward through a
  dedicated sub-queue for that pool and ante.【F:lovely/TheOrder.toml†L88-L95】
* **Joker editions, stickers, and rentals** – Use the default area-specific keys (`"etperpoll"`, `"packetper"`, etc.) concatenated
  with the current ante, so the edition and rental queues reset every ante and are shared between different jokers.【F:lovely/TheOrder.toml†L97-L135】
* **Seals** – Polling a seal leaves the ante untouched, so the vanilla per-ante seal queue is used.【F:compatibility/TheOrder.lua†L196-L207】
* **Soul/Black Hole consumables** – The queue key is `'soul_' .. _type .. G.GAME.round_resets.ante`, which means each consumable
  type has an independent per-ante queue.【F:lovely/TheOrder.toml†L137-L158】
* **Deck shuffles** – Use `'nr' .. G.GAME.round_resets.ante` and `'cashout' .. G.GAME.round_resets.ante`, so the top of deck resets
  when an ante changes or when cashing out.【F:lovely/TheOrder.toml†L61-L76】【F:compatibility/TheOrder.lua†L282-L289】

In short, without The Order almost every queue is scoped to the current ante; two players that desynchronise their ante counters
will immediately see different shop inventories, booster packs, and seal rolls because each client advances distinct queues.

## The Order queues (integration enabled)

When The Order is active the mod rewrites most queue seeds to remove their ante dependency and to group them by item type instead
of shop slot. The central hook is the patched `create_card`, which temporarily zeroes `G.GAME.round_resets.ante` while a card is
being generated and rewrites `key_append` so that identical rarities share a queue regardless of where they are spawned.
Tarots/Planets/Spectrals are also split into independent queues for shop vs. pack pulls by setting `key_append` to either the type
(e.g. `"Tarot"`) or `<type>_pack`. Non-base cards use their rarity as the key, except for high-stake Judgement cards that must
retain the vanilla queue.【F:compatibility/TheOrder.lua†L3-L21】 Because the ante is forced to `0` for the duration of the call,
all edition/rental/seal rolls triggered inside `create_card` effectively ignore the current ante.

Notable queues under The Order:

* **Shop category (Joker/Tarot/Planet/etc.)** – Still uses `'cdt' .. MP.ante_based()`, but `MP.ante_based()` now returns `0`, so
the category queue is global for the entire run.【F:lovely/TheOrder.toml†L78-L86】【F:compatibility/TheOrder.lua†L276-L279】
* **Rarity queues** – Every non-base card pulls from the queue keyed by its rarity because `key_append` is forced to `_rarity`,
  ensuring that shop slots, rerolls, and tags consume the same rarity stream.【F:compatibility/TheOrder.lua†L14-L21】
* **Tarot/Planet/Spectral** – Distinguishes shop pulls from pack pulls by switching `key_append` between `<type>` and
  `<type>_pack`, so each source has its own deterministic stream while remaining global across antes.【F:compatibility/TheOrder.lua†L8-L13】
* **Booster pack contents** – Use `(_key or "pack_generic") .. MP.ante_based()` and therefore stay in sync across the entire run
  because the helper returns `0`.【F:lovely/TheOrder.toml†L52-L59】【F:compatibility/TheOrder.lua†L276-L279】
* **Voucher shop** – Replaced with a culled pool sampler driven by `'Voucher0'`. It repeatedly samples until it finds an available
  voucher and tracks spawned entries so both players see the same list without `UNAVAILABLE` gaps.【F:compatibility/TheOrder.lua†L236-L274】
* **Seals** – `SMODS.poll_seal` wraps the vanilla function while temporarily zeroing the ante, so seals share a single global
  queue that persists across antes.【F:compatibility/TheOrder.lua†L196-L207】
* **Editions/Stickers/Rentals** – Injected `_order = center.key` prefixes the seed keys, producing an independent queue per joker
  (or card center) instead of sharing one global stream. Because `create_card` zeroes the ante first, the seed effectively becomes
  `<joker key> .. <queue key> .. 0`, so editions and rentals stay tied to the individual card across all players.【F:lovely/TheOrder.toml†L97-L135】【F:compatibility/TheOrder.lua†L3-L21】
* **Soul/Black Hole consumables** – Use constant keys (`'c_soul'`/`'c_black_hole'`) while still concatenating the ante. The
  constant key keeps the queue global and also avoids the black hole roll overwriting a soul roll in the same evaluation.
  Additionally, if a soul roll already succeeded the black hole branch respects that and skips the overwrite.【F:lovely/TheOrder.toml†L137-L158】
* **Rarity resample** – Drops the `"_resample" .. it` suffix when The Order is active, preventing resample loops from skipping
  ahead in the queue and thereby keeping rerolls aligned between players.【F:lovely/TheOrder.toml†L88-L95】
* **Deck shuffles** – Use `MP.order_round_based(true)` so the shuffle seed incorporates the ante and the blind key. This keeps the
  deck order deterministic for every player even when they fight different blinds or skip rounds.【F:lovely/TheOrder.toml†L61-L76】【F:compatibility/TheOrder.lua†L282-L289】
* **Boss selection and other event queues** – Several other RNG hooks (e.g. boss selection, hallucination coin flips) now call the
  same ante-aware helpers to make their queues respect the shared ante counter, ensuring that everyone sees the same sequence as
  long as they trigger those events at the same time.【F:lovely/TheOrder.toml†L43-L59】

## Reset rules and synchronisation summary

The following table summarises what advances or resets each queue:

| Queue | Without The Order | With The Order |
| --- | --- | --- |
| Shop category / rarity | Resets each ante; slot-specific keys | Global per run; keyed by card type or rarity only |
| Tarot/Planet/Spectral | Resets each ante, separate per slot | Global streams split by type and by shop vs. pack |
| Booster packs | Resets each ante | Global per run |
| Vouchers | Vanilla per-ante queue | Global sampler skipping `UNAVAILABLE` entries |
| Seals / Editions / Rentals | Per-ante and shared between cards | Ante forced to `0`, queues keyed by card center |
| Soul & Black Hole chances | Per-ante, per consumable type | Global, constant key while preventing overwrite |
| Rarity resample | `_resample` suffix advances sub-queue | No suffix; resample reuses the base queue |
| Deck shuffle | Seeded by ante only | Seeded by ante + blind key to keep all players in sync |

Because The Order removes most ante-based seeds, queues no longer reset every round. Instead, they remain aligned for the entire
run, so two clients only diverge if they consume entries in different orders (for example, if one player buys an extra shop card
that the other does not). When The Order is disabled, every ante change restarts the queues, so keeping players in sync requires
that their ante counters advance identically.
