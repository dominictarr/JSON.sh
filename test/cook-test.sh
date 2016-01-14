#! /usr/bin/env bash

cd ${0%/*}

. ../JSON.sh

cooktest() {
    INPUT="$1"
    EXPECT="$2"
    i=$((i+1))
    OUT="$(cook_a_string_arg "$INPUT")"
    if [ $? = 0 -a x"$OUT" = x"$EXPECT" ]; then
        echo "ok $i - '$INPUT' => '$OUT'"
    else
        echo "not ok $i - '$INPUT' => '$OUT' (expected '$EXPECT')"
        fails=$((fails+1))
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
