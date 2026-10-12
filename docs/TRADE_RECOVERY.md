# Durable player-trade recovery contract

Published player trading remains disabled. `TradeReceiptPolicy.lua` defines the
pure state machine. `TradePersistence.lua` now drives that policy through an
injected UpdateAsync-style store with session-token checks and per-profile
recovery. `Data.lua` invokes raw join recovery before gameplay hydration,
protects pending markers from ordinary saves, and now owns a gated live
settlement entry point. Published trading remains closed while retention,
diagnostics and private-published fault evidence are incomplete.

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

`scripts/test_trade_receipt_policy.luau` simulates a process crash after each
boundary and executes retry/conflict cases against the real policy module.

## Still required before enabling the feature

- Define bounded COMPLETE/ABORTED receipt retention and operational diagnostics.
- Extend fault injection through the concrete DataStore wrapper. Current tests
  cover raw-load PREPARING recovery, marker-safe saves, permanent pre-write
  failure and lost responses, but not Roblox throttling or cross-server timing.
- Private published two-account tests for throttling, disconnect, shutdown,
  lease expiry and cross-server rejoin.

Only after those checks pass may `Config.DurableTrades` be considered for a
separate reviewed change. CI success alone is not approval to enable it.


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

Retention, diagnostics and private-published evidence remain release blockers;
`DurableTrades` stays false.
