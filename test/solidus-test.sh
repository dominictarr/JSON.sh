#!/bin/sh

cd ${0%/*}

INPUT=./solidus/string_with_solidus.json
OUTPUT_ESCAPED=./solidus/string_with_solidus.with-escaping.parsed
OUTPUT_WITHOUT_ESCAPING=./solidus/string_with_solidus.no-escaping.parsed

FAILS=0

echo "1..2"

if ! ../JSON.sh < $INPUT| diff -u - ${OUTPUT_ESCAPED}; then
  echo "not ok - JSON.sh run without -s option should leave solidus escaping intact"
  FAILS=$((FAILS + 1))
else
  echo "ok $i - solidus escaping was left intact"
fi

if ! ../JSON.sh -s < $INPUT| diff -u - ${OUTPUT_WITHOUT_ESCAPING}; then
  echo "not ok - JSON.sh run with -s option should remove solidus escaping"
  FAILS=$((FAILS+1))
else
  echo "ok $i - solidus escaping has been removed"
fi

echo "$FAILS test(s) failed"
exit $FAILS
