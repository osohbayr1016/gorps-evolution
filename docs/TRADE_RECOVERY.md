# Durable player-trade recovery contract

Published player trading remains disabled. `TradeReceiptPolicy.lua` defines the
pure state machine. `TradePersistence.lua` now drives that policy through an
injected UpdateAsync-style store with session-token checks and per-profile
recovery; it is not connected to `Data.lua` or live remotes and therefore does
not make the current game production-safe for trading.

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
   applied. The future adapter must additionally verify the active session
   token in the same UpdateAsync callback.

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

- Connect the server-only adapter to the real receipt/profile DataStores while
  preserving its session checks and bounded retries.
- Invoke `recoverProfile` during raw join loading before `Rules.load` strips
  reserved fields; coordinate autosaves so they cannot erase a pending marker.
- Extend the fake-store suite through the concrete DataStore wrapper. The current
  suite covers permanent pre-write failure and a lost response after each of the
  seven durable mutations, but not Roblox throttling or cross-server timing.
- Private published two-account tests for throttling, disconnect, shutdown,
  lease expiry and cross-server rejoin.
- Receipt retention/cleanup limits and operational diagnostics.

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

This separation keeps the fault model executable without granting the module
live DataStore access. Integration, retention and private-published evidence
remain release blockers; `DurableTrades` stays false.
