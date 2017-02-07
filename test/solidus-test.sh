#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
. ../JSON.sh </dev/null

INPUT=./solidus/string_with_solidus.json
OUTPUT_ESCAPED=./solidus/string_with_solidus.with-escaping.parsed
OUTPUT_WITHOUT_ESCAPING=./solidus/string_with_solidus.no-escaping.parsed

FAILS=0

echo "1..2"

if ! jsonsh_cli < "$INPUT" | diff -u - "${OUTPUT_ESCAPED}" ; then
  echo "not ok - JSON.sh run without -s option should leave solidus escaping intact"
  FAILS="$(expr $FAILS + 1)"
else
  echo "ok $i - solidus escaping was left intact"
fi

if ! jsonsh_cli -s < "$INPUT" | diff -u - "${OUTPUT_WITHOUT_ESCAPING}" ; then
  echo "not ok - JSON.sh run with -s option should remove solidus escaping"
  FAILS="$(expr $FAILS + 1)"
else
  echo "ok $i - solidus escaping has been removed"
fi

echo "$FAILS test(s) failed"
exit $FAILS
