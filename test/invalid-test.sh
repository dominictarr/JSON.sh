#! /usr/bin/env bash

cd ${0%/*}

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
tests=`ls invalid/* -1l | wc -l`
echo "1..$tests"
for input in invalid/*
do
  let i+=1
  if ../bin/json_parse < "$input" > outlog 2> errlog
  then
    echo "not ok $i - cat $input | ../bin/json_parse should fail"
    #this should be indented with '#' at the start.
    echo "OUTPUT WAS >>>"
    cat outlog
    echo "<<<"
    let fails=$fails+1
  else
    echo "ok $i - $input was rejected"
  
  fi
done
echo "$fails test(s) failed"
exit $fails
