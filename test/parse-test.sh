
__filename=`readlink -f $0`
__dirname=`dirname $__filename`
cd $__dirname

. ../parse.sh

cat ../package.json | tokenize | parse

#echo '"oooo"  ' | tokenize | parse
echo '[true, 1, [0, {}]]  ' | tokenize | parse
echo '{"true": 1}' | tokenize | parse
