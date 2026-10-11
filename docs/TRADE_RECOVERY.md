# Durable player-trade recovery contract

Published player trading remains disabled. `TradeReceiptPolicy.lua` defines the
pure state machine that a future DataStore adapter must obey; it does not
perform I/O and does not make the current game production-safe for trading.

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

- A server-only DataStore adapter using `UpdateAsync` for the receipt and both
  profile keys, with session-token checks and bounded retries.
- Join-time recovery before `Rules.load` strips reserved fields.
- A fake-store suite that injects errors before and after every callback,
  including an error whose write actually succeeded.
- Private published two-account tests for throttling, disconnect, shutdown,
  lease expiry and cross-server rejoin.
- Receipt retention/cleanup limits and operational diagnostics.

Only after those checks pass may `Config.DurableTrades` be considered for a
separate reviewed change. CI success alone is not approval to enable it.
