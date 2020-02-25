#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

cooktest() {
    INPUT="$1"
    EXPECT="$2"
    i="$(expr $i + 1)"
    OUT="$(cook_a_string_arg "$INPUT")"
    if [ $? = 0 ] && [ x"$OUT" = x"$EXPECT" ]; then
        echo "ok $i - '$INPUT' => '$OUT'"
    else
        echo "not ok $i - '$INPUT' => '$OUT' (expected '$EXPECT')"
        fails="$(expr $fails+1)"
        echo "RETRACE >>>"
        (set -x ; cook_a_string_arg "$INPUT")
        echo "<<<"
    fi
}

fails=0
i=0

echo "1..4"
cooktest 'a@b' 'a@b'
cooktest 'a"b' 'a\"b'
cooktest 'a\"b' 'a\\\"b'
cooktest 'a b' 'a b'

echo "$i test(s) executed"
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
