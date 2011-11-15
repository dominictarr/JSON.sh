#! /usr/bin/env bash

cd ${0%/*}
. ../JSON.sh

i=0
fails=0
ttest () {
  let i++
  local input="$1"; shift
  local expected="$(printf '%s\n' "$@")"
  if echo "$input" | tokenize | diff -u - <(echo "$expected")
  then
    echo "ok $i - $input"    
  else 
    echo "not ok $i - $input"
    let fails=$fails+1
  fi
}

ttest '"dah"'       '"dah"'
ttest '""'          '""'
ttest '["dah"]'     '[' '"dah"' ']'
ttest '"   "'       '"   "'
ttest '" \"  "' '" \"  "'

ttest '["dah"]' '[' '"dah"' ']'

ttest '123'       '123'
ttest '123.142'   '123.142'
ttest '-123'        '-123'

ttest '1e23'      '1e23'
ttest '0.1'       '0.1'
ttest '-110'       '-110'
ttest '-110.10'    '-110.10'
ttest '-110e10'    '-110e10'
ttest 'null'       'null'
ttest 'true'       'true'
ttest 'false'      'false'
ttest '[ null   ,  -110e10, "null" ]' \
      '[' 'null' ',' '-110e10' ',' '"null"' ']'
ttest '{"e": false}'     '{' '"e"' ':' 'false' '}'
ttest '{"e": "string"}'  '{' '"e"' ':' '"string"' '}'

if ! cat ../package.json | tokenize >/dev/null
then
  let fails=$fails+1
  echo "Tokenizing package.json failed!"
fi

echo "$fails test(s) failed"
exit $fails
