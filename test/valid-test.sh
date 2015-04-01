#! /usr/bin/env bash

# NOTE: Developer of a new feature can pre-create expected result files:
#   JSON_TEST_GENERATE=auto     conditionally (don't replace nonempty files)
#   JSON_TEST_GENERATE=yes      recreate (replace existing results if any)

# To disambiguate tests on sorting, use one locale
LANG=C
LC_ALL=C
export LANG LC_ALL

cd ${0%/*}
fails=0
passes=0
skips=0
generated=0
i=0

CHOMPEXT='\.\(parsed\|sorted\|numnormalized\|normalized\|json\).*$'
[ $# -gt 0 ] && \
    FILES="$(for F in "$@"; do echo valid/"`basename "$F" | sed "s,${CHOMPEXT},,"`".json ; done | sort | uniq)" || \
    FILES="`ls valid/*.json -1`"

[ -z "$FILES" ] && echo "error - no files found to test!" >&2 && exit 1

tests="`echo "$FILES" | wc -l`"
### We currently have up to 8 extensions to consider per test
tests=$(($tests*8))
echo "1..$tests"

for input in $FILES
do
  for EXT in parsed sorted normalized normalized_sorted \
        numnormalized numnormalized_stripped \
        normalized_numnormalized normalized_numnormalized_stripped \
  ; do
    if [ ! -f "$input" ]; then
      echo "error - missing input file '$input', assuming all its tests failed"
      fails=$(($fails+8))
      break
    fi

    expected="${input%.json}.$EXT"
    if [ -f "$expected" -o -n "$JSON_TEST_GENERATE" ]; then
      i=$((i+1))
      case "$EXT" in
        sorted) OPTIONS="-S='-n -r'" ;;
        normalized) OPTIONS="-N" ;;
        normalized_sorted) OPTIONS="-N=-n" ;;
        numnormalized) OPTIONS="-Nn=%.12f" ;;
        numnormalized_stripped) OPTIONS="-Nnx" ;;
        normalized_numnormalized) OPTIONS="-N=-n -Nn=%.12f" ;;
        normalized_numnormalized_stripped) OPTIONS="-N=-n -Nnx" ;;
        parsed|*) OPTIONS="" ;;
      esac
      if [ "$JSON_TEST_GENERATE" = yes ] || \
         [ "$JSON_TEST_GENERATE" = auto -a ! -s "$expected" ]
      then
        if ! eval ../JSON.sh $OPTIONS < "$input" > "$expected"
        then
          echo "generation not ok $i - $input $EXT"
          fails=$((fails+1))
          mv -f "$expected" "$expected.failed"
        else
          echo "generation ok $i - $input $EXT"
          passes=$(($passes+1))
          generated=$(($generated+1))
        fi
        continue
      fi

      if ! eval ../JSON.sh $OPTIONS < "$input" | diff -u - "$expected" 
      then
        echo "not ok $i - $input $EXT"
        fails=$((fails+1))
      else
        echo "ok $i - $input $EXT"
        passes=$(($passes+1))
      fi
    else
      # echo "skip (missing result file) - $input $EXT"
      skips=$(($skips+1))
    fi
  done
done
[ -n "$JSON_TEST_GENERATE" ] && echo "$generated expected results generated"
[ -n "$skips" ] && echo "$skips test(s) skipped (missing expected results file)"
echo "$passes test(s) succeeded"
echo "$fails test(s) failed"
exit $fails
