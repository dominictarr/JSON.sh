#! /usr/bin/env bash

trap 'echo "$BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail

cd ${0%/*}

# NOTE short forms not allowed here.
formats=(array default key-only key-value value-only)
declare -A short_formats=([array]=a [default]=d [key-only]=key [key-value]=kv [value-only]=value)

tmp=${TEMP:-/tmp}
tmp=${tmp%/}/ # Avoid double //

fails=0
i=0
tab=$'\t'
tests=`ls valid/*.json | wc -l`
tests=$[tests*${#formats[*]}*2] # *2 for short formats.
echo "1..$tests"

# Figure out longest format length just once
longest_format=0
for format in ${formats[@]}
do
  [ ${#format} -gt $longest_format ] && longest_format=${#format}
done

runtest() {
  local arg=$1 out

  printf -v out "${0%/*}/../JSON.sh %q %-${longest_format}s < %q" '-f' "$arg" "${0%/*}/$input"
  i=$((i+1))
  if ! ../JSON.sh -f $arg < "$input" | diff -u - "$expected" 
  then
    echo "not ok $i - $out"
    fails=$((fails+1))
    return 1
  else
    echo "ok $i - $out"
  fi
}

safegrep() {
  # grep returns 1 if no lines were selected, so we need to ignore it
  grep "$@" && return 0 || rc=$?
  [ $rc -eq 1 ] && return 0
  echo "grep returned $rc at line $LINENO" >&2
  exit $rc
}

for input in valid/*.json
do
  input_file=${input##*/}
  parsed=${input%.json}.parsed

  for format in ${formats[@]}
  do
    expected=$tmp${input_file%.json}.$format
    case "$format" in
      array)
        cat $parsed | tr '\t' = | safegrep -E -v '^\[]=' > $expected
        $reset
        ;;
      default)
        cp $parsed $expected
        ;;
      key-only)
        # Pattern matches '^[<not ]]' and extracts the part in the []
        cat $parsed | sed -e 's/^\[//' -e "s/]$tab/$tab/" | cut -f 1 | safegrep -E -v '^$' > $expected
        ;;
      key-value)
        # Pattern matches '^[<not ]]' and extracts the part in the []
        cat $parsed | sed -e 's/^\[//' -e "s/]$tab/$tab/" > $expected
        ;;
      value-only)
        # Pattern matches '^[<not ]]' and extracts the part in the []
        cat $parsed | sed -e 's/^\[//' -e "s/]$tab/$tab/" | cut -f 2 | safegrep -E -v '^$' > $expected
        ;;
      *)
        echo "$0: Unknown format option '$format'"
        exit 1
    esac

    bothpass=0
    runtest $format && bothpass=1

    # Just blow up if we don't have a valid short format
    [ -n "${short_formats[$format]}" ] || ( echo "Tests definition error: no short format for '$format'."; exit 1 )
    runtest ${short_formats[$format]} && [ $bothpass -eq 1 ] && rm $expected
  done
done

if [ $i -ne $tests ]; then
  echo "Count of tests run ($i) does not match expected test count ($tests)"
  exit 1
fi

echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
