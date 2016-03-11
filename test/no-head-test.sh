#!/bin/sh

cd ${0%/*}
tmp=${TEMP:-/tmp}
tmp=${tmp%%/}/ # Avoid duplicate //

fails=0
i=0
tests=`ls valid/*.json | wc -l`
echo "1..$tests"
for input in valid/*.json
do
  input_file=${input##*/}
  expected="${tmp}${input_file%.json}.no-head"
  egrep -v '^\[]' < ${input%.json}.parsed > $expected
  i=$((i+1))
  if ! ../JSON.sh -n < "$input" | diff -u - "$expected" 
  then
    echo "not ok $i - $input"
    fails=$((fails+1))
  else
    echo "ok $i - $input"    
  fi
done
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
