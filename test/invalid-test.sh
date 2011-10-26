#! /usr/bin/env bash

# Define BSD-friendly canonicalized readlink
canonical_readlink () { cd `dirname $1`; __filename=`basename $1`; if [ -h "$__filename" ]; then canonical_readlink `readlink $__filename`; else echo "`pwd -P`/$__filename"; fi }

__filename=$(canonical_readlink $0)
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
  cat $input | ../bin/json_parse > outlog 2> errlog
  ret=$?
  if [ $ret -eq 0 ]; then
    echo "NOT OK: cat $input | ../bin/json_parse SHOULD FAIL"
    echo "OUTPUT WAS >>>"
    cat outlog
    echo "<<<"
    let fails=$fails+1
  else
    echo "OK: cat $input | ../bin/json_parse failed correctly"
    echo "stderr was >>>"
    cat errlog
    echo "<<<"
  fi

done
echo "$fails test(s) failed"
exit $fails