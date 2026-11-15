#!/bin/sh
# Fund once, transact off-chain, settle once.
cd "$(dirname "$0")/.."
LC="${LARZCHANNEL:-larzscript bin/larzchannel.lz} --file tests/data/coop.json"
mkdir -p tests/data; rm -f tests/data/coop.json
$LC fund alice 500.00
$LC fund bob 300.00
$LC open alice bob 500.00 300.00 --window 2
ID=$($LC show | grep ^channel | head -1 | awk '{print $2}')
for n in 1 2 3; do
  A=$((500 - n * 20)); B=$((300 + n * 20))
  SA=$($LC sign $ID $n $A.00 $B.00 a); SB=$($LC sign $ID $n $A.00 $B.00 b)
  $LC update $ID $n $A.00 $B.00 $SA $SB
done
SA=$($LC sign $ID 3 440.00 360.00 a); SB=$($LC sign $ID 3 440.00 360.00 b)
$LC close $ID 3 440.00 360.00 $SA $SB
echo "--- balances"
$LC show
