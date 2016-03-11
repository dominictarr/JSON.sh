#!/bin/sh

cd ${0%/*}
fails=0
i=0
tests=`ls valid/*.json | wc -l`
echo "1..${tests##* }"
for input in valid/*.json
do
  expected="${input%.json}.parsed"
  i=$((i+1))
  if ! ../JSON.sh < "$input" | diff -u - "$expected" 
  then
    echo "not ok $i - $input"
    fails=$((fails+1))
  else
    echo "ok $i - $input"    
  fi
done
echo "$fails test(s) failed"
exit $fails
