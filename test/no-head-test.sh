#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
tests="`ls -1 valid/*.json | wc -l`"

[ -n "${tmp-}" ] || tmp="/tmp"

# Avoid duplicate // in plain-shell syntax
tmp="$(echo "$tmp" | sed 's,/+,/,g')"
case "$tmp" in
    */) ;;
    *)  tmp="$tmp/" ;;
esac

echo "1..${tests##* }"

i=0
for input in valid/*.json
do
  expected="${tmp}$(basename "$input" .json).no-head"
  # NOTE: The echo trick is required to ensure EOLs for both empty and populated results
  printf '%s\n' "$(egrep -v '^\[]' < "$(dirname "$input")/$(basename "$input" .json).parsed")" > "$expected"
  i="$(expr $i + 1)"
  # Such explicit chaining is equivalent to "pipefail" in non-Bash interpreters
  JSONSH_OUT="$(jsonsh_cli -n < "$input")" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "$expected"
  JSONSH_RES=$?
  if [ "$JSONSH_RES" != 0 ]
  then
    echo "not ok $i - $input"
    fails="$(expr $fails + 1)"
    echo "INPUT WAS >>>"
    cat "$input"
    printf ">>> JSONSH_OUT='%s'\n" "$JSONSH_OUT"
    echo ">>> EXPECTED : `ls -la $expected`"
    cat "$expected"
    echo "RETRACE >>>"
    (set -x ; jsonsh_cli -n < "$input")
    echo "<<<"
  else
    echo "ok $i - $input"
  fi
done

echo "$i test(s) executed"
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
