#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

[ -n "${tmp-}" ] || tmp="/tmp"

# Avoid duplicate // in plain-shell syntax
tmp="$(echo "$tmp" | sed 's,/+,/,g')"
case "$tmp" in
    */) ;;
    *)  tmp="$tmp/" ;;
esac

i=0
fails=0
ttest () {
  i="$(expr $i + 1)"
  input="$1"; shift
  expected="$(printf '%s\n' "$@")"
  echo "$expected" > "${tmp}"json_ttest_expected
  if echo "$input" | tokenize | diff -u - "${tmp}"json_ttest_expected
  then
    echo "ok $i - $input"
  else
    echo "not ok $i - $input"
    fails="$(expr $fails + 1)"
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
  fails="$(expr $fails + 1)"
  echo "Tokenizing package.json failed!"
fi

echo "$fails test(s) failed"
exit $fails
