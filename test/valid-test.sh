#!/bin/sh

# NOTE: Developer of a new feature can pre-create expected result files:
#   JSON_TEST_GENERATE=auto     conditionally (don't replace nonempty files)
#   JSON_TEST_GENERATE=yes      recreate (replace existing results if any)

# To disambiguate tests on sorting, use one locale
LANG=C
LC_ALL=C
export LANG LC_ALL

cd "$(dirname "$0")"

# Can't detect sourcing in sh, so immediately terminate the attempt to parse
JSONSH_SOURCED=yes
. ../JSON.sh </dev/null

# make test output TAP compatible
# http://en.wikipedia.org/wiki/Test_Anything_Protocol

fails=0
passes=0
skips=0
generated=0
i=0

CHOMPEXT='\.\(parsed\|sorted\|numnormalized\|normalized\|json\).*$'
[ $# -gt 0 ] && \
    FILES="$(for F in "$@"; do echo valid/"`basename "$F" | sed "s,${CHOMPEXT},,"`".json ; done | sort | uniq)" || \
    FILES="$(ls -1 valid/*.json)"

[ -z "$FILES" ] && echo "error - no files found to test!" >&2 && exit 1

tests="$(echo "$FILES" | wc -l)"
### We currently have up to 10 extensions to consider per test
tests="$(expr $tests \* 10)"
echo "1..$tests"

# Force zsh to expand $FILES into multiple words
is_wordsplit_disabled="$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')"
if [ "$is_wordsplit_disabled" != 0 ]; then setopt shwordsplit; fi

for input in $FILES
do
  if [ "${is_wordsplit_disabled-}" != 0 ]; then unsetopt shwordsplit; is_wordsplit_disabled=0; fi
  for EXT in parsed sorted normalized normalized_sorted \
        numnormalized numnormalized_stripped \
        normalized_numnormalized normalized_numnormalized_stripped \
        normalized_pretty normalized_sorted_pretty \
  ; do
    if [ ! -f "$input" ]; then
      echo "error - missing input file '$input', assuming all its tests failed"
      fails="$(expr $fails + 8)"
      break
    fi

#    expected="${input%.json}.$EXT"
    expected="$(dirname "$input")/$(basename "$input" .json).$EXT"
    if [ -f "$expected" -o -n "$JSON_TEST_GENERATE" ]; then
      i="$(expr $i + 1)"
      case "$EXT" in
        sorted) OPTIONS="-S='-n -r'" ;;
        normalized) OPTIONS="-N" ;;
        normalized_sorted) OPTIONS="-N=-n" ;;
        normalized_pretty) OPTIONS="-N --pretty-print" ;;
        normalized_sorted_pretty) OPTIONS="-N=-n --pretty-print" ;;
        numnormalized) OPTIONS="-Nn=%.12f" ;;
        numnormalized_stripped) OPTIONS="-Nnx" ;;
        normalized_numnormalized) OPTIONS="-N=-n -Nn=%.12f" ;;
        normalized_numnormalized_stripped) OPTIONS="-N=-n -Nnx" ;;
        parsed|*) OPTIONS="" ;;
      esac
      if [ "$JSON_TEST_GENERATE" = yes ] || \
         [ "$JSON_TEST_GENERATE" = auto -a ! -s "$expected" ]
      then
        # Here we "eval" to pass OPTIONS that may have spaces in sort args
        if ! (eval jsonsh_cli $OPTIONS < "$input" > "$expected")
        then
          echo "generation not ok $i - $input $EXT"
          fails="$(expr $fails + 1)"
          mv -f "$expected" "$expected.failed"
          echo "RETRACE >>>"
          (set -x ; eval jsonsh_cli $OPTIONS < "$input")
          echo "<<<"
        else
          echo "generation ok $i - $input $EXT"
          passes="$(expr $passes + 1)"
          generated="$(expr $generated + 1)"
        fi
        continue
      fi

      # Such explicit chaining is equivalent to "pipefail" in non-Bash interpreters
      JSONSH_OUT="$(eval jsonsh_cli $OPTIONS < "$input")" && \
        printf '%s\n' "$JSONSH_OUT" | diff -u - "${expected}"
      JSONSH_RES=$?
      if [ "$JSONSH_RES" != 0 ]
      then
        echo "not ok $i - $input $EXT"
        fails="$(expr $fails + 1)"
        printf ">>> JSONSH_OUT='%s'\n" "$JSONSH_OUT"
        echo ">>> EXPECTED : `ls -la $expected`"
        cat "$expected"
        echo "RETRACE >>>"
        (set -x ; eval jsonsh_cli $OPTIONS < "$input")
        echo "<<<"
      else
        echo "ok $i - $input $EXT"
        passes="$(expr $passes + 1)"
      fi
    else
      # echo "skip (missing result file) - $input $EXT"
      skips="$(expr $skips + 1)"
    fi
  done
done

[ -n "$JSON_TEST_GENERATE" ] && echo "$generated expected results generated"
[ -n "$skips" ] && echo "$skips test(s) skipped (missing expected results file)"
echo "$i test(s) executed"
echo "$passes test(s) succeeded"
echo "$fails test(s) failed"
exit $fails

# vi: expandtab sw=2 ts=2
