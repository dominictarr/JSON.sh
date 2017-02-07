#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
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
    fi
}

fails=0
i=0

echo "1..4"
cooktest 'a@b' 'a@b'
cooktest 'a"b' 'a\"b'
cooktest 'a\"b' 'a\\\"b'
cooktest 'a b' 'a b'

echo "$fails test(s) failed"
exit $fails
