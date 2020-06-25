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

  # Such explicit chaining is equivalent to "pipefail" in non-Bash interpreters
  JSONSH_OUT="$(echo "$input" | tokenize)" && \
    printf '%s\n' "$JSONSH_OUT" | diff -u - "${tmp}"json_ttest_expected
  JSONSH_RES=$?
  if [ "$JSONSH_RES" = 0 ]
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

i="$(expr $i + 1)"
input="Tokenizing the 'package.json' file"
if tokenize < ../package.json >/dev/null
then
  echo "ok $i - $input"
else
  echo "not ok $i - $input"
  fails="$(expr $fails + 1)"
fi

echo "$fails test(s) failed"
exit $fails
