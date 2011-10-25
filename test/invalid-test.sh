#! /usr/bin/env bash

__filename=`readlink -f $0`
__dirname=`dirname $__filename`
cd $__dirname

echo  _=$_
echo  0=$0
echo __filename=$__filename
echo __dirname=$__dirname
echo  PWD=$PWD
#env
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
#  else
#    echo "OK: cat $input | ../bin/json_parse failed correctly"
#    echo "stderr was >>>"
#    cat errlog
#    echo "<<<"
  fi
done
echo "$fails test(s) failed"
exit $fails
