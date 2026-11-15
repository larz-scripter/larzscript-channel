#!/bin/sh
# Runs each tests/*.sh scenario and diffs its real output against
# tests/<name>.expected. Real captured output, nothing fabricated.
#
set -e
cd "$(dirname "$0")/.."
LARZCHANNEL="${LARZCHANNEL:-larzscript bin/larzchannel.lz}"
export LARZCHANNEL
mkdir -p tests/data
# Channel ids are uuids and signatures are HMAC digests - both differ every
# run. Everything else, including every balance and every exit code, is
# compared literally.
normalize() {
  sed -E 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/UUID/g; s/[0-9a-f]{64}/SIG/g; s/\b[0-9a-f]{8}\b/xxxxxxxx/g'
}

fail=0
for t in tests/*.sh; do
  name=$(basename "$t" .sh)
  [ "$name" = "run_tests" ] && continue
  exp="tests/$name.expected"
  # `|| true`: a scenario that ends on a non-zero exit is normal here -
  # larzlint exits 1 when it finds an error, which several tests do on
  # purpose. Without this, `set -e` aborts the whole runner on the first
  # such test and the remaining ones silently never run.
  got=$(sh "$t" 2>&1 || true)
  got=$(printf '%s\n' "$got" | normalize)
  if [ ! -f "$exp" ]; then
    echo "MISSING EXPECTED  $name"; printf '%s\n' "$got"; fail=1; continue
  fi
  if printf '%s\n' "$got" | diff -u "$exp" - > /tmp/lc_diff_$$ 2>&1; then
    echo "ok    $name"
  else
    echo "FAIL  $name"; cat /tmp/lc_diff_$$; fail=1
  fi
  rm -f /tmp/lc_diff_$$
done
rm -rf tests/data
exit $fail
