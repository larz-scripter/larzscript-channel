#!/bin/sh
# Fund once, transact off-chain, settle once - and what happens when
# somebody submits an old state.
set -e
cd "$(dirname "$0")/.."
LC="${LARZCHANNEL:-larzscript bin/larzchannel.lz} --file examples/out/demo.json"
mkdir -p examples/out; rm -f examples/out/demo.json

echo "== 1. two parties fund a channel"
$LC fund alice 500.00
$LC fund bob 300.00
$LC open alice bob 500.00 300.00 --window 2
ID=$($LC show | grep ^channel | head -1 | awk '{print $2}')

echo
echo "== 2. three updates, off-chain - nothing touches the escrow"
for n in 1 2 3; do
  A=$((500 - n * 50)); B=$((300 + n * 50))
  SA=$($LC sign $ID $n $A.00 $B.00 a); SB=$($LC sign $ID $n $A.00 $B.00 b)
  $LC update $ID $n $A.00 $B.00 $SA $SB
done
$LC show $ID

echo
echo "== 3. alice tries to close on a state from two updates ago"
SA=$($LC sign $ID 1 450.00 350.00 a); SB=$($LC sign $ID 1 450.00 350.00 b)
$LC unilateral $ID alice 1 450.00 350.00 $SA $SB --now 1000

echo
echo "== 4. bob answers with the real latest state"
SA=$($LC sign $ID 3 350.00 450.00 a); SB=$($LC sign $ID 3 350.00 450.00 b)
$LC dispute $ID 3 350.00 450.00 $SA $SB

echo
echo "== 5. settle after the window"
$LC settle $ID --now 1010
$LC show

rm -rf examples/out
