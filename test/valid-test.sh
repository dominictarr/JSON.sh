#! /usr/bin/env bash

# To disambiguate tests on sorting, use one locale
LANG=C
LC_ALL=C
export LANG LC_ALL

cd ${0%/*}
fails=0
i=0
tests=`ls valid/*.json -1l | wc -l`
tests=$(($tests*4))
echo "1..$tests"
for input in valid/*.json
do
  for EXT in parsed sorted normalized normalized_sorted; do
    expected="${input%.json}.$EXT"
    i=$((i+1))
    case "$EXT" in
      sorted) OPTIONS="-S='-n -r'" ;;
      normalized) OPTIONS="-N" ;;
      normalized_sorted) OPTIONS="-N=-n" ;;
      parsed|*) OPTIONS="" ;;
    esac
    if ! eval ../JSON.sh $OPTIONS < "$input" | diff -u - "$expected" 
    then
      echo "not ok $i - $input $EXT"
      fails=$((fails+1))
    else
      echo "ok $i - $input $EXT"
    fi
  done
done
echo "$fails test(s) failed"
exit $fails
