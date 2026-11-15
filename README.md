# larzchannel

Two-party payment channels in [Larzscript](https://github.com/larz-scripter/larzscript):
fund once, transact off-chain as often as you like, settle once.

## What is different about this one

Every other escrow project in this series gates a single transaction on an
**amount** — is there enough, is the pool solvent, do the two halves of a
split reconcile. The gate here is **ordering**.

Two states can both be perfectly valid — correct arithmetic, correct
signatures from both parties — and the only thing that decides which one is
true is a sequence number.

That is what makes a channel work: the parties exchange signed states
privately and only the last one ever reaches the escrow, so N transactions
cost one settlement. It is also what makes a channel dangerous: **an old
state is still a validly signed state**, so the protocol has to make
submitting one worse than not submitting it.

## The four requires, none of them a tautology

1. every update **conserves the total**, to the cent
2. a superseding state must have a **strictly higher nonce**
3. **both parties** must have signed the state being submitted
4. settlement **drains the escrow to exactly $0.00**

Each is demonstrated being refused in `tests/guards.sh`, and the escrow
check is a real accounting closure, not a log line.

## The penalty

A unilateral close opens a dispute window. If the counterparty answers with
a strictly newer signed state, the party who submitted the stale one
**forfeits the whole channel**.

In the demo, alice submits a state giving herself $450 when the latest
signed state gives her $350. Bob disputes. Alice settles for **$0** and bob
takes all $800. Trying to steal $100 costs $350.

## Demo

Real output of `sh examples/demo.sh`:

```
== 1. two parties fund a channel
alice balance $500
bob balance $300
channel 2f09611f open, total $800, dispute window 2s

== 2. three updates, off-chain - nothing touches the escrow
accepted nonce 1
accepted nonce 2
accepted nonce 3
channel 2f09611f  open
  alice: $350   bob: $450
  total $800  nonce 3  updates 3

== 3. alice tries to close on a state from two updates ago
alice submitted nonce 1; settles after 1002

== 4. bob answers with the real latest state
superseded with nonce 3; alice forfeits

== 5. settle after the window
settled after 3 off-chain update(s)
  paid $0 and $800
  alice forfeited the channel for submitting a stale state
alice: $0
bob: $800
channel 2f09611f  settled  nonce 3
```

## Two honest limitations

**The signatures are HMAC, not public-key.** HMAC is symmetric, so the
verifier must know the signing key — which means the board holds both
parties' secrets. That models the protocol's *shape* correctly, and it does
not model unforgeability: in a real channel each party signs locally with a
private key and nobody else can produce their signature. Larzscript's
`crypto` package offers SHA-256, HMAC and PBKDF2, and no asymmetric
primitive, so this is as far as the language goes today.

**It is signature-bound, and not by a little.** `crypto.lz` is pure
Larzscript SHA-256, measured here at **0.45s per HMAC** (40 HMACs in 18s).
Each update costs four — two to sign, two to verify — so a channel runs at
roughly **one update every two seconds**. The whole point of a payment
channel is high-frequency off-chain updates, so that is a real limit and
worth stating plainly rather than burying: the protocol is correct, the
crypto is the bottleneck. `tests/netting.lz` uses 25 updates rather than
500 for exactly this reason.

## Usage

```
larzchannel fund <party> <amount>
larzchannel open <a> <b> <amt_a> <amt_b> [--window SECONDS]
larzchannel sign <id> <nonce> <bal_a> <bal_b> a|b
larzchannel update <id> <nonce> <bal_a> <bal_b> <sig_a> <sig_b>
larzchannel close <id> <nonce> <bal_a> <bal_b> <sig_a> <sig_b>
larzchannel unilateral <id> <by> <nonce> <bal_a> <bal_b> <sig_a> <sig_b>
larzchannel dispute <id> <nonce> <bal_a> <bal_b> <sig_a> <sig_b>
larzchannel settle <id>
larzchannel show [id]
```

`--file` picks the state file (default `channels.json`); `--now` pins the
clock, which is what makes the dispute-window tests deterministic.

## Built with the toolchain

Dependencies were resolved and vendored by
[larzvendor](https://github.com/larz-scripter/larzscript-vendor), which found
the `uuid` → `random` edge on its own — the transitive dependency that
broke a sibling project's CI when it was vendored by hand.

```
  random
  escrow
  crypto
  json
  uuid  -> random
5 package(s) in the closure
```

It is clean under
[larzfmt](https://github.com/larz-scripter/larzscript-fmt),
[larzlint](https://github.com/larz-scripter/larzscript-lint) (0 errors,
0 warnings) and
[larzdoc](https://github.com/larz-scripter/larzscript-doc) (2 of 2 packages
fully documented).

## Install

```
git clone https://github.com/larz-scripter/larzscript-channel
cd larzscript-channel
sh tests/run_tests.sh
sh examples/demo.sh
```

## Licence

MIT.
