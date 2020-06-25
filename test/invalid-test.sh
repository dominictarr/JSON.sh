#!/bin/sh

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
tests="`ls -1 invalid/* | wc -l`"

[ -n "${tmp-}" ] || tmp="/tmp"

# Avoid duplicate // in plain-shell syntax
tmp="$(echo "$tmp" | sed 's,/+,/,g')"
case "$tmp" in
    */) ;;
    *)  tmp="$tmp/" ;;
esac

echo "1..${tests##* }"
for input in invalid/*
do
  i="$(expr $i + 1)"
  if jsonsh_cli < "$input" > "${tmp}"JSON.sh_outlog 2> "${tmp}"JSON.sh_errlog
  then
    echo "not ok $i - cat $input | ../JSON.sh should have failed"
    #this should be indented with '#' at the start.
    echo "OUTPUT WAS >>>"
    cat "${tmp}"JSON.sh_outlog
    echo "ERRORS WAS >>>"
    cat "${tmp}"JSON.sh_errlog
    echo "<<<"
    fails="$(expr $fails + 1)"
  else
    echo "ok $i - $input was rejected as expected"
    echo "# `cat "${tmp}"JSON.sh_errlog`"
  fi
done

echo "$fails test(s) failed"
exit $fails
