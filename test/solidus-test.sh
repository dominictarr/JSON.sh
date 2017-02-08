#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

INPUT=./solidus/string_with_solidus.json
OUTPUT_ESCAPED=./solidus/string_with_solidus.with-escaping.parsed
OUTPUT_WITHOUT_ESCAPING=./solidus/string_with_solidus.no-escaping.parsed

FAILS=0

echo "1..2"

# Such explicit chaining is equivalent to "pipefail" in non-Bash interpreters
JSONSH_OUT="$(jsonsh_cli < "$INPUT")" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "${OUTPUT_ESCAPED}"
JSONSH_RES=$?
if [ "$JSONSH_RES" != 0 ] ; then
  echo "not ok - JSON.sh run without -s option should leave solidus escaping intact"
  FAILS="$(expr $FAILS + 1)"
else
  echo "ok $i - solidus escaping was left intact"
fi

JSONSH_OUT="$(jsonsh_cli -s < "$INPUT")" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "${OUTPUT_WITHOUT_ESCAPING}"
JSONSH_RES=$?
if [ "$JSONSH_RES" != 0 ] ; then
  echo "not ok - JSON.sh run with -s option should remove solidus escaping"
  FAILS="$(expr $FAILS + 1)"
else
  echo "ok $i - solidus escaping has been removed"
fi

echo "$FAILS test(s) failed"
exit $FAILS
