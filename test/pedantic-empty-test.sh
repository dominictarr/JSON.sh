#!/bin/sh

cd "$(dirname "$0")"

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
tests=8
i=0

echo "1..${tests}"

# Note: weird whitespaces and end-of-lines below are intended
# TODO: populate by printf?
for DOC in \
    "" \
    " " \
    "
" \
"
  
 " \
; do
  i="$(expr $i + 1)"
  if echo "$DOC" | ../JSON.sh
  then
    echo "ok $i - empty input '$DOC' is okay in non-pedantic mode"
  else
    echo "not ok $i - empty input '$DOC' was rejected in non-pedantic mode"
    fails="$(expr $fails + 1)"
  fi

  i="$(expr $i + 1)"
  if echo "$DOC" | ../JSON.sh -P
  then
    echo "not ok $i - empty input '$DOC' should be rejected in pedantic mode"
    fails="$(expr $fails + 1)"
  else
    echo "ok $i - empty input '$DOC' was rejected in pedantic mode"
  fi
done

echo "$i test(s) executed"
echo "$fails test(s) failed"
exit $fails
