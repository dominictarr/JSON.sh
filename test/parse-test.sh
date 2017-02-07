#!/bin/sh

cd ${0%/*}

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
. ../JSON.sh </dev/null

ptest () {
  tokenize | parse >/dev/null
}

fails=0
i=0
echo "1..4"
for input in '"oooo"  ' '[true, 1, [0, {}]]  ' '{"true": 1}'
do
  i=$((i+1))
  if echo "$input" | ptest 
  then
    echo "ok $i - $input"
  else
    echo "not ok $i - $input"
    fails=$((fails+1))
  fi
done

if ! ptest < ../package.json
then
  echo "not ok 4 - Parsing package.json failed!"
  fails=$((fails+1))
else 
  echo "ok $i - package.json"
fi

echo "$fails test(s) failed"
exit $fails
