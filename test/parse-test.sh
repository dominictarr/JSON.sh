#! /usr/bin/env bash

cd ${0%/*}

. ../parse.sh

ptest () {
  tokenize | parse >/dev/null
}

fails=0
for input in '"oooo"  ' '[true, 1, [0, {}]]  ' '{"true": 1}'
do
  echo "$input" | ptest || let fails=$fails+1
done

if ! ptest < ../package.json
then
  echo "Parsing package.json failed!"
  let fails=$fails+1
fi

echo "$fails test(s) failed"
exit $fails
