#!/bin/sh
# The three things an update must satisfy, each refused on its own.
cd "$(dirname "$0")/.."
LC="${LARZCHANNEL:-larzscript bin/larzchannel.lz} --file tests/data/g.json"
mkdir -p tests/data; rm -f tests/data/g.json
$LC fund alice 500.00 > /dev/null
$LC fund bob 300.00 > /dev/null
$LC open alice bob 500.00 300.00 --window 2 > /dev/null
ID=$($LC show | grep ^channel | head -1 | awk '{print $2}')
SA=$($LC sign $ID 1 450.00 350.00 a); SB=$($LC sign $ID 1 450.00 350.00 b)
$LC update $ID 1 450.00 350.00 $SA $SB
echo "--- does not conserve the total"
SA=$($LC sign $ID 2 300.00 300.00 a); SB=$($LC sign $ID 2 300.00 300.00 b)
$LC update $ID 2 300.00 300.00 $SA $SB
echo "--- not newer"
SA=$($LC sign $ID 1 400.00 400.00 a); SB=$($LC sign $ID 1 400.00 400.00 b)
$LC update $ID 1 400.00 400.00 $SA $SB
echo "--- forged signature"
$LC update $ID 2 400.00 400.00 deadbeef deadbeef
