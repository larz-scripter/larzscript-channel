#!/bin/sh
# The efficiency claim, measured: N off-chain updates cost exactly one
# settlement. Run in-process because 500 CLI invocations would measure
# interpreter startup, not the protocol.
cd "$(dirname "$0")/.."
larzscript tests/netting.lz
