#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

INPUT=./solidus/string_with_solidus.json
OUTPUT_ESCAPED=./solidus/string_with_solidus.with-escaping.parsed
OUTPUT_WITHOUT_ESCAPING=./solidus/string_with_solidus.no-escaping.parsed

FAILS=0

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

echo "1..2"
i=0

# Such explicit chaining is equivalent to "pipefail" in non-Bash interpreters
i="$(expr $i + 1)"
JSONSH_OUT="$(jsonsh_cli < "$INPUT")" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "${OUTPUT_ESCAPED}"
JSONSH_RES=$?
if [ "$JSONSH_RES" != 0 ] ; then
    echo "not ok $i - JSON.sh run without -s option should leave solidus escaping intact"
    FAILS="$(expr $FAILS + 1)"
    echo "RETRACE >>>"
    (set -x ; jsonsh_cli < "$INPUT")
    echo "<<<"
else
    echo "ok $i - solidus escaping was left intact"
fi

i="$(expr $i + 1)"
JSONSH_OUT="$(jsonsh_cli -s < "$INPUT")" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "${OUTPUT_WITHOUT_ESCAPING}"
JSONSH_RES=$?
if [ "$JSONSH_RES" != 0 ] ; then
    echo "not ok $i - JSON.sh run with -s option should remove solidus escaping"
    FAILS="$(expr $FAILS + 1)"
    echo "RETRACE >>>"
    (set -x ; jsonsh_cli -s < "$INPUT")
    echo "<<<"
else
    echo "ok $i - solidus escaping has been removed"
fi

echo "$i test(s) executed"
echo "$FAILS test(s) failed"
exit $FAILS

# vi: expandtab sw=2 ts=2
