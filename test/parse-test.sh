#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

ptest () {
  tokenize | parse >/dev/null
}

fails=0
i=0
echo "1..6"
for input in \
    '"oooo"  ' \
    '[true, 1, [0, {}]]  ' \
    '{"true": 1}' \
; do
  i="$(expr $i + 1)"
  if echo "$input" | ptest
  then
    echo "ok $i - $input"
  else
    echo "not ok $i - $input"
    fails="$(expr $fails + 1)"
  fi
done

i="$(expr $i + 1)"
if ! ptest < ../package.json
then
  echo "not ok $i - Parsing package.json failed!"
  fails="$(expr $fails + 1)"
else
  echo "ok $i - package.json"
fi

i="$(expr $i + 1)"
JSONSH_OUT="$(jsonsh_cli --shellable-output=strings -x '^"name"$' < ../package.json 2>/dev/null)" \
&& [ -n "$JSONSH_OUT" ] ; JSONSH_RES=$?
if [ "$JSONSH_RES" = 0 ] && [ "$JSONSH_OUT" = 'JSON.sh' ] ; then
  echo "ok $i - package.json with extraction of one entry"
else
  echo "not ok $i - Parsing package.json with extraction of one entry failed!"
  fails="$(expr $fails + 1)"
fi

i="$(expr $i + 1)"
JSONSH_OUT="$(jsonsh_cli -So=-r -b --shellable-output=arrays -x '^"repository"' < ../package.json 2>/dev/null)" \
&& [ -n "$JSONSH_OUT" ] ; JSONSH_RES=$?
if [ "$JSONSH_RES" = 0 ] && [ "$JSONSH_OUT" = '"https://github.com/dominictarr/JSON.sh.git"
"git"' ] ; then
  echo "ok $i - package.json with extraction of several entries with array markup"
else
  echo "not ok $i - Parsing package.json with extraction of several entries with array markup failed!"
  echo "==="
  echo "$JSONSH_OUT"
  echo "==="
  fails="$(expr $fails + 1)"
fi

echo "$i test(s) executed"
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
