
__filename=`readlink -f $0`
__dirname=`dirname $__filename`

cd $__dirname

set -e
# valid/array.json
diff <(cat valid/array.json | ../bin/json_parse) valid/array.parsed
echo OK valid/array.json
# valid/empty_array.json
diff <(cat valid/empty_array.json | ../bin/json_parse) valid/empty_array.parsed
echo OK valid/empty_array.json
# valid/empty_object.json
diff <(cat valid/empty_object.json | ../bin/json_parse) valid/empty_object.parsed
echo OK valid/empty_object.json
# valid/many_object.json
diff <(cat valid/many_object.json | ../bin/json_parse) valid/many_object.parsed
echo OK valid/many_object.json
# valid/nested_array.json
diff <(cat valid/nested_array.json | ../bin/json_parse) valid/nested_array.parsed
echo OK valid/nested_array.json
# valid/nested_object.json
diff <(cat valid/nested_object.json | ../bin/json_parse) valid/nested_object.parsed
echo OK valid/nested_object.json
# valid/number.json
diff <(cat valid/number.json | ../bin/json_parse) valid/number.parsed
echo OK valid/number.json
# valid/object.json
diff <(cat valid/object.json | ../bin/json_parse) valid/object.parsed
echo OK valid/object.json
# valid/string.json
diff <(cat valid/string.json | ../bin/json_parse) valid/string.parsed
echo OK valid/string.json
