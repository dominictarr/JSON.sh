
# Define BSD-friendly canonicalized readlink
canonical_readlink () { cd `dirname $1`; __filename=`basename $1`; if [ -h "$__filename" ]; then canonical_readlink `readlink $__filename`; else echo "`pwd -P`/$__filename"; fi }

__filename=$(canonical_readlink $0)
__dirname=`dirname $__filename`

cd $__dirname

set -e
fails=0
for input in valid/*.json
do
  expected="${input%.json}.parsed"
  if ! ../bin/json_parse < "$input" | diff -u - "$expected"
  then
    let fails=$fails+1
  fi
done
echo "$fails test(s) failed"
exit $fails
