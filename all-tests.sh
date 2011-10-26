#! /usr/bin/env bash

# Define BSD-friendly canonicalized readlink
canonical_readlink () { cd `dirname $1`; __filename=`basename $1`; if [ -h "$__filename" ]; then canonical_readlink `readlink $__filename`; else echo "`pwd -P`/$__filename"; fi }

__filename=$(canonical_readlink $0)
__dirname=`dirname $__filename`
cd $__dirname

#set -e
fail=0
tests=0
#all_tests=${__dirname:}
#echo PLAN ${#all_tests}
for test in test/*.sh ;
do
  let tests=$tests+1
  echo TEST: $test
  bash $test
  ret=$? 
  if [ $ret -eq 0 ] ; then
    echo OK: ---- $test
    let passed=$passed+1
  else
    echo FAIL: $test $fail
    let fail=$fail+$ret
  fi
done

if [ $fail -eq 0 ]; then
  echo -n 'SUCCESS '
else
  echo -n 'FAILURE '
fi
echo   $passed / $tests
