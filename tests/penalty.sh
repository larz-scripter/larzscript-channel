#!/bin/sh
# An old state is still a validly signed state. The protocol has to make
# submitting one worse than not: a successful dispute forfeits the whole
# channel to the honest party.
cd "$(dirname "$0")/.."
LC="${LARZCHANNEL:-larzscript bin/larzchannel.lz} --file tests/data/p.json"
mkdir -p tests/data; rm -f tests/data/p.json
$LC fund alice 500.00 > /dev/null
$LC fund bob 300.00 > /dev/null
$LC open alice bob 500.00 300.00 --window 2 > /dev/null
ID=$($LC show | grep ^channel | head -1 | awk '{print $2}')
for n in 1 2 3 4 5; do
  A=$((500 - n * 50)); B=$((300 + n * 50))
  SA=$($LC sign $ID $n $A.00 $B.00 a); SB=$($LC sign $ID $n $A.00 $B.00 b)
  $LC update $ID $n $A.00 $B.00 $SA $SB > /dev/null
done
echo "latest signed state is nonce 5: alice 250 / bob 550"
echo "--- alice submits nonce 2 instead (alice 400 / bob 400)"
SA=$($LC sign $ID 2 400.00 400.00 a); SB=$($LC sign $ID 2 400.00 400.00 b)
$LC unilateral $ID alice 2 400.00 400.00 $SA $SB --now 1000
echo "--- settling early is refused"
$LC settle $ID --now 1001
echo "--- bob disputes"
SA=$($LC sign $ID 5 250.00 550.00 a); SB=$($LC sign $ID 5 250.00 550.00 b)
$LC dispute $ID 5 250.00 550.00 $SA $SB
echo "--- settle"
$LC settle $ID --now 1010
$LC show
