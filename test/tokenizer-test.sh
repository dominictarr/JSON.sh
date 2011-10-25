#! /usr/bin/env bash

__filename=`readlink -f $0`
__dirname=`dirname $__filename`
cd $__dirname

. ../parse.sh
set -e

diff <( echo '"dah"'    | tokenize ) <( echo   '"dah"' )
diff <( echo '""'    | tokenize ) <( echo   '""' )
diff <( echo '["dah"]'  | tokenize ) <( printf '[\n\"dah\"\n]\n' )
diff <( echo '"   "'  | tokenize ) <( printf '"   "\n' )
diff <( printf '" \\"  "'  | tokenize ) <( printf '" \\"  "\n' )

diff \
<( echo '["dah"]'  | tokenize ) \
<( echo \
'[
"dah"
]')

diff <( echo '123'      | tokenize ) <( echo '123' )
diff <( echo '123.142'  | tokenize ) <( echo '123.142' )
diff <( echo '-123'     | tokenize ) <( echo   '-123')

#diff <( echo '1e23' | tokenize ) <( printf '1e23\n' )
diff <( echo '0.1'      | tokenize ) <( echo '0.1' )
diff <( echo '-110'     | tokenize ) <( echo  '-110' )
diff <( echo '-110.10'  | tokenize ) <( echo  '-110.10' )
diff <( echo '-110e10'  | tokenize ) <( echo  '-110e10' )
diff <( echo 'null'     | tokenize ) <( echo  'null' )
diff <( echo 'true'     | tokenize ) <( echo  'true' )
diff <( echo 'false'     | tokenize ) <( echo  'false' )
diff <( echo '[ null   ,  -110e10, "null" ]' \
                        | tokenize ) <( printf '[\nnull\n,\n-110e10\n,\n"null"\n]\n' )
diff <( echo '{"e": false}'     | tokenize ) <( printf '{\n"e"\n:\nfalse\n}\n' )
diff <( echo '{"e": "string"}'     | tokenize ) <( printf '{\n"e"\n:\n"string"\n}\n' )

cat ../package.json | tokenize
