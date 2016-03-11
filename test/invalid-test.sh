#!/bin/sh

cd ${0%/*}

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
tests=`ls invalid/* | wc -l`

echo "1..${tests##* }"
for input in invalid/*
do
  i=$((i+1))
  if ../JSON.sh < "$input" > /tmp/JSON.sh_outlog 2> /tmp/JSON.sh_errlog 
  then
    echo "not ok $i - cat $input | ../JSON.sh should fail"
    #this should be indented with '#' at the start.
    echo "OUTPUT WAS >>>"
    cat /tmp/JSON.sh_outlog
    echo "<<<"
    fails=$((fails+1))
  else
    echo "ok $i - $input was rejected"
    echo "#" `cat /tmp/JSON.sh_errlog`
  fi
done
echo "$fails test(s) failed"
exit $fails
