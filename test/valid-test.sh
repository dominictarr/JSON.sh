
__filename=`readlink -f $0`
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
