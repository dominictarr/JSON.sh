#!/bin/sh

cd "$(dirname "$0")"

#set -e
fail=0
tests=0
#all_tests=${__dirname:}
#echo PLAN ${#all_tests}
for test in test/*.sh ;
do
  tests="$(expr $tests + 1)"
  echo "TEST: $test"
  "./$test"
  ret=$?
  if [ $ret -eq 0 ] ; then
    echo "OK: ---- $test"
    passed="$(expr $passed + 1)"
  else
    echo "FAIL: $test ($ret)"
    fail="$(expr $fail + 1)"
  fi
done

if [ "$fail" = 0 ]; then
  echo -n 'SUCCESS '
  exitcode=0
else
  echo -n 'FAILURE '
  exitcode=1
fi
echo " $passed / $tests"
exit $exitcode
