#!/bin/sh

cd "$(dirname "$0")"
[ -n "${tmp-}" ] || tmp="/tmp"

# Avoid duplicate // in plain-shell syntax
tmp="$(echo "$tmp" | sed 's,/+,/,g')"
case "$tmp" in
    */) ;;
    *)  tmp="$tmp/" ;;
esac

fails=0
i=0
tests="$(ls -1 valid/*.json | wc -l)"
echo "1..$tests"
for input in valid/*.json
do
  expected="${tmp}$(basename "$input" .json).no-head"
  egrep -v '^\[]' < "$(dirname "$input")/$(basename "$input" .json).parsed" > "$expected"
  i="$(expr $i + 1)"
  if ! ../JSON.sh -n < "$input" | diff -u - "$expected"
  then
    echo "not ok $i - $input"
    fails="$(expr $fails + 1)"
  else
    echo "ok $i - $input"
  fi
done

echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
