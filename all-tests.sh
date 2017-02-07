#!/bin/sh

# This script can now test with various shell interpreters
# which you can pass in a space-separated list of SHELL_PROGS
# To use old behavior : export SHELL_PROGS="-"

cd "$(dirname "$0")"
#set -e

overall_exitcode=0
jsonsh_tests() (
    [ -z "${SHELL_PROG-}" ] && SHELL_PROG=""
    fail=0
    tests=0
    #all_tests=${__dirname:}
    #echo PLAN ${#all_tests}
    for test in test/*.sh ;
    do
      tests="$(expr $tests + 1)"
      echo "TEST: $test"
      # TODO: find a way to use the current shell-interpreter program to
      # run sub-tests (simple sourcing fails ATM because scripts start
      # with "cd `dirname $0`")...
      #( . "./$test" )
      $SHELL_PROG "./$test"
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
      printf 'SUCCESS '
      exitcode=0
    else
      printf 'FAILURE '
      exitcode=1
    fi
    printf ": $passed / $tests\n"
    exit $exitcode
)

OKAY_SHELLS=""
FAIL_SHELLS=""
SKIP_SHELLS=""
[ -n "$SHELL_PROGS" ] || SHELL_PROGS="bash dash ash busybox ksh ksh88 ksh93"
for SHELL_PROG in $SHELL_PROGS ; do
    [ "$SHELL_PROG" = "busybox" ] && SHELL_PROG="busybox sh"
    { [ "$SHELL_PROG" = "-" ] || [ "$SHELL_PROG" = " " ] ; } && \
        SHELL_PROG=''

    if [ -n "$SHELL_PROG" ] ; then
        if $SHELL_PROG -c "date" >/dev/null 2>&1 ; then : ; else
            echo "SKIP missing shell : $SHELL_PROG"
            SKIP_SHELLS="$SKIP_SHELLS $SHELL_PROG"
            continue
        fi
        export SHELL_PROG
        echo "TESTING WITH shell interpreter : $SHELL_PROG"
    else
        unset SHELL_PROG
        echo "TESTING WITH default shell interpreter e.g. likely with /bin/sh, whatever this is in your OS"
    fi

    jsonsh_tests && OKAY_SHELLS="$OKAY_SHELLS $SHELL_PROG" || \
        { overall_exitcode=$? ; FAIL_SHELLS="$FAIL_SHELLS $SHELL_PROG" ; }
    echo ""
done

echo "OVERALL RESULT:"
echo "OKAY_SHELLS = $OKAY_SHELLS"
echo "FAIL_SHELLS = $FAIL_SHELLS"
echo "SKIP_SHELLS = $SKIP_SHELLS"
exit $overall_exitcode
