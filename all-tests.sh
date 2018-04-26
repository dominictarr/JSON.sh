#!/bin/sh

# This script can now test with various shell interpreters
# which you can pass in a space-separated list of SHELL_PROGS
# To use old behavior : export SHELL_PROGS="-"
# This script runs one or more actual sub-tests named in TEST_PATTERN
# (the value may be a shell wildcard).

cd "$(dirname "$0")"
#set -e

overall_exitcode=0
jsonsh_tests() (
    [ -z "${SHELL_PROG-}" ] && SHELL_PROG=""
    fail=0
    tests=0
    passed=0
    fail_names=""
    #all_tests=${__dirname:}
    #echo PLAN ${#all_tests}
    for test in $TEST_PATTERN
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
        fail_names="$fail_names $test"
      fi
    done

    if [ "$fail" = 0 ]; then
      printf '===== SUCCESS '
      exitcode=0
    else
      printf '===== FAILURE '
      exitcode=1
    fi

    # Note the leading space if populated
    [ -z "$fail_names" ] || fail_names=" : failed for$fail_names"

    # Note the leading space if populated
    [ -z "$SHELL_PROG" ] || fail_names="$fail_names interpreted by '$SHELL_PROG'"

    printf ": passed $passed / $tests tests$fail_names\n"
    exit $exitcode
)

OKAY_SHELLS=""
FAIL_SHELLS=""
SKIP_SHELLS=""
[ -n "$SHELL_PROGS" ] || SHELL_PROGS="bash dash ash zsh busybox"
#SHELL_PROGS="$SHELL_PROGS ksh ksh88 ksh93"
[ -n "$TEST_PATTERN" ] || TEST_PATTERN='test/*.sh'
export TEST_PATTERN

# Force zsh to expand $A into multiple words
is_wordsplit_disabled="$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')"
if [ "$is_wordsplit_disabled" != 0 ]; then setopt shwordsplit; fi

for SHELL_PROG in $SHELL_PROGS ; do
    case "$SHELL_PROG" in
        busybox|*/busybox) SHELL_PROG="$SHELL_PROG sh" ;;
        ' '|'-') SHELL_PROG='' ;; # system default shell
    esac

    if [ -n "$SHELL_PROG" ] ; then
        if $SHELL_PROG -c "date" >/dev/null 2>&1 ; then : ; else
            echo "=== SKIP missing shell : $SHELL_PROG"
            echo ""
            SKIP_SHELLS="$SKIP_SHELLS $SHELL_PROG"
            continue
        fi
        export SHELL_PROG
        echo "=== TESTING WITH shell interpreter : $SHELL_PROG"
    else
        unset SHELL_PROG
        echo "=== TESTING WITH default shell interpreter e.g. likely with /bin/sh, whatever this is in your OS"
    fi

    jsonsh_tests && OKAY_SHELLS="$OKAY_SHELLS $SHELL_PROG" || \
        { overall_exitcode=$? ; FAIL_SHELLS="$FAIL_SHELLS $SHELL_PROG" ; }
    echo ""
done

if [ "${is_wordsplit_disabled-}" != 0 ]; then unsetopt shwordsplit; is_wordsplit_disabled=0; fi

echo "OVERALL RESULT:"
echo "OKAY_SHELLS = $OKAY_SHELLS"
echo "FAIL_SHELLS = $FAIL_SHELLS"
echo "SKIP_SHELLS = $SKIP_SHELLS"
exit $overall_exitcode
