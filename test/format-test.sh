#! /usr/bin/env bash

cd ${0%/*}

tmp=${TEMP:-/tmp}
tmp=${tmp%/}/ # Avoid double //

fails=0
i=0
tab=$'\t'
tests=`ls valid/*.json | wc -l`
tests=$[tests*2]
echo "1..$tests"

for input in valid/*.json
do
  input_file=${input##*/}
  for format in a k
  do
    expected=$tmp${input_file%.json}
    case $format in
      a)
        expected=${expected}.array
        cat ${input%.json}.parsed | tr '\t' = > $expected
        ;;
      k)
        expected=${expected}.keyvalue
        # Pattern matches '^[<not ]]' and extracts the part in the []
        cat ${input%.json}.parsed | sed -e 's/^\[//' -e "s/]$tab/$tab/" > $expected
        ;;
      *)
        echo "Unknown format option $format"
        exit 1
    esac

    i=$((i+1))
    if ! ../JSON.sh -f $format < "$input" | diff -u - "$expected" 
    then
      echo "not ok $i - $input"
      fails=$((fails+1))
    else
      echo "ok $i - $input"    
    fi
  done
done
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
