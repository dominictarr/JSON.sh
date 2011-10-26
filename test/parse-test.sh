
# Define BSD-friendly canonicalized readlink
canonical_readlink () { cd `dirname $1`; __filename=`basename $1`; if [ -h "$__filename" ]; then canonical_readlink `readlink $__filename`; else echo "`pwd -P`/$__filename"; fi }

__filename=$(canonical_readlink $0)
__dirname=`dirname $__filename`
cd $__dirname

. ../parse.sh

cat ../package.json | tokenize | parse

#echo '"oooo"  ' | tokenize | parse
echo '[true, 1, [0, {}]]  ' | tokenize | parse
echo '{"true": 1}' | tokenize | parse
