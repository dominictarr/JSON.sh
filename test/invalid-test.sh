#! /usr/bin/env bash

cd ${0%/*}

fails=0
for input in invalid/*
do
  if ../bin/json_parse < "$input" > outlog 2> errlog
  then
    echo "NOT OK: cat $input | ../bin/json_parse SHOULD FAIL"
    echo "OUTPUT WAS >>>"
    cat outlog
    echo "<<<"
    let fails=$fails+1
  fi
done
echo "$fails test(s) failed"
exit $fails
