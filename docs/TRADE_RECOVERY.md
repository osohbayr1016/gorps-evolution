# Durable player-trade recovery contract

Published player trading remains disabled. `TradeReceiptPolicy.lua` defines the
pure state machine. `TradePersistence.lua` now drives that policy through an
injected UpdateAsync-style store with session-token checks and per-profile
recovery. `Data.lua` invokes raw join recovery before gameplay hydration,
protects pending markers from ordinary saves, and now owns a gated live
settlement entry point. `TradeReceiptRetention.lua` schedules safe terminal
payload compaction and `Data.lua` keeps bounded server-only diagnostics.
Published trading remains closed while concrete/private-published fault
evidence is incomplete.

## Safety invariants

1. A receipt contains immutable participant IDs, offers, and before/after
   gameplay snapshots. A retry must match the entire stored receipt.
2. Preparing a profile adds only a reserved `_trade` marker. It never deducts
   or grants an asset.
3. The coordinator may commit only after both exact profile markers exist.
4. `PREPARING` recovery aborts and clears markers, preserving both before
   states. `COMMITTED` recovery applies both after states.
5. `_tradeResult` makes commit and abort resolution idempotent. Repeating an
   UpdateAsync response after an unknown network outcome cannot duplicate the
   transfer.
6. A committed receipt cannot abort. A receipt cannot become `COMPLETE` until
   both profiles confirm the committed result.
7. Session metadata is preserved when the committed gameplay snapshot is
   applied, and every profile callback verifies the active session token.
8. A normal autosave cannot erase `_trade`. Final unload may release session
   ownership while preserving the marker, and `_tradeResult` survives later
   saves as terminal idempotency evidence.
9. Both live profiles are locked before exact preconditions are persisted. A
   COMPLETE result replaces both in-memory profiles from detached receipt
   snapshots; ABORTED changes neither; PENDING forces raw release and rejoin.
10. ABORTED unlocks live memory only after both profile markers are cleared or
    their absence is durably observed under the owned sessions. Unconfirmed
    cleanup remains PENDING even when the receipt already says ABORTED.
11. The 30-day retention clock begins only after both sides are durably terminal.
    On the first owned profile load at or after the deadline, the receipt becomes
    an immutable archive containing IDs, participant IDs, outcome and timestamps,
    but no offers or before/after snapshots. A terminal profile marker clears
    only after that matching archive is observed. Conflicts fail closed.

## Required durable write order

| Boundary | Durable write | Crash recovery |
| --- | --- | --- |
| 1 | Create immutable `PREPARING` receipt | Abort; neither profile changed |
| 2 | Prepare profile A | Abort; clear A marker |
| 3 | Prepare profile B | Abort; clear both markers |
| 4 | Change receipt to `COMMITTED` | Apply both after snapshots |
| 5 | Resolve profile A | Resolve B; A retry is a no-op |
| 6 | Resolve profile B | Mark receipt complete |
| 7 | Change receipt to `COMPLETE` | Terminal no-op |
| 8 | Attach terminal retention deadline | Retry later; terminal gameplay result stays final |

`scripts/test_trade_receipt_policy.luau` simulates the seven decision boundaries.
`scripts/test_trade_persistence.luau` injects response loss across all eight
adapter mutations. `scripts/test_trade_retention.luau` covers the deadline,
archive payload removal, both marker cleanups, conflicts and a lost cleanup
response against the real retention/persistence modules.

## Still required before enabling the feature

- Extend fault injection through the concrete DataStore wrapper. Current tests
  cover raw-load PREPARING recovery, marker-safe saves, permanent pre-write
  failure and lost responses, but not Roblox throttling or cross-server timing.
- Private published two-account tests for throttling, disconnect, shutdown,
  lease expiry and cross-server rejoin.

Only after those checks pass may `Config.DurableTrades` be considered for a
separate reviewed change. CI success alone is not approval to enable it.

## Terminal retention and diagnostics

Full terminal receipts retain recovery snapshots for 30 days **after** both
profiles have confirmed COMPLETE or safe ABORTED cleanup. After that deadline,
the next session-owned load atomically replaces the full receipt with a compact
archive and then clears only that player's matching `_tradeResult`. The peer
does the same on its next owned load. No global receipt index or unowned profile
write is introduced. Consequently, a receipt that no player accesses after the
deadline can remain full longer; proving scheduled cleanup would require a
separate indexed/background design and live DataStore budget evidence.

The server adapter emits only bounded metadata (`id`, status, reason and time)
to a 64-entry in-memory diagnostic ring exposed to server code through
`Data.getTradeDiagnostics()`. It never records offers, inventory snapshots or
other gameplay payloads, and it is not a durable analytics system.


## Implemented adapter boundary

`TradePersistence.execute` accepts only an injected store whose `update`
method has UpdateAsync-style callback semantics. Every profile callback checks
the currently persisted session token. Unknown post-write outcomes are retried
against immutable receipts and idempotent markers/results; a pre-commit failure
durably aborts, while a committed decision is never rolled back.
`recoverProfile` resolves one raw marked profile on join and fails closed when
the session token, role, user, receipt, or marker does not match.

`Data.load` now adapts the live profile DataStore to this interface before
`Rules.load`, so PREPARING and COMMITTED markers resolve while still raw.
Invalid recovery fails closed and best-effort releases the claimed session.
`SessionPolicy.save` defers an autosave that observes `_trade`, preserves a
terminal `_tradeResult`, and `releaseRaw` lets shutdown relinquish ownership
without deleting recovery evidence.

`TradeSettlement.execute` now builds the immutable receipt from detached
TradeRules results and exposes live snapshots only after a matching COMPLETE
receipt. `Data.settleTrade` blocks remote actions, harvesting, minute ticks and
ordinary save mutation for both participants, revalidates identity/version/
session ownership, and fails closed to join-time recovery on an unknown result.

Concrete DataStore fault injection, cross-server diagnostics and private-
published evidence remain release blockers; `DurableTrades` stays false.
