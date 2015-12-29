#!/usr/bin/env bash

#trap 'echo "$BASH_SOURCE: line $LINENO: returned $?" >&2' ERR
#set -o errexit -o errtrace -o pipefail

cd ${0%/*}
. JSON.sh

declare -A Aexec Afunc Akv
spaces='{ "nested key": {"key with spaces": "value with spaces"}, "tab\tkey":"tab\tvalue", "unnested key": "unnested value","\"qk": "qv\"", "bad": "=\\\"" }'
spacetoken=`echo $spaces | tokenize`

echo "You can save tokens in a variable"
tokens=$(tokenize < package.json)
echo
echo "But be careful with quoting"
echo -n '          Raw tokens: ' ; echo $tokens | wc
echo -n '       Quoted tokens: ' ; echo "$tokens" | wc
echo -n '   Raw parsed tokens: ' ; echo $tokens | parse | wc
echo -n 'Quoted parsed tokens: ' ; echo "$tokens" | parse | wc
echo
echo "You can change output options on the fly"
parse_options -f key-only
keys=$( echo "$tokens" | parse )
echo 'Keys are:' $keys
parse_options -f value-only
echo 'Values are:' $( echo "$tokens" | parse )
echo
echo
echo "Grab a single key-value"
parse_options -f default
echo "$tokens" | parse | egrep '^\["repository","url"]'
echo "Or with key-value output"
parse_options -f kv
echo "$tokens" | parse | egrep '^"repository","url"'
echo "Which you can feed to cut because it's tab delimited and JSON doesn't allow tabs"
echo "$tokens" | parse | egrep '^"repository","url"' | cut -f2
echo
echo
echo "Key-value mode is really meant for use with read, and is probably the safest way to use JSON.sh"
lines=0
echo "$tokens" | parse | {
  IFS=$'\t'
  while read -r key value; do
    ((lines++))
    [ "$key" == "author" ] && echo Be careful of quoting $key # Won't match!
    [ "$key" == '"author"' ] && echo Be careful of quoting $value # Note that this can output out of order!
    [ "$key" == '"repository","url"' ] || continue
    echo "line $lines: $value"
    printf 'Or with printf: value=%s\n' "$value"
  done
  echo $lines total lines
}
echo
echo "With spaces in key ($spaces)"
echo Without IFS IS BAD
echo "$spacetoken" | parse | {
  while read -r key value; do
    if echo "$key" | grep -q nest; then
      echo -n 'BAD!: '
    else
      echo -n 'good: '
    fi
    echo "'$key' = '$value'"
  done
}
echo With IFS is good
saveifs=$IFS
IFS=$'\t'
while read -r key value; do
  echo "'$key' = '$value'"
done < <( echo "$spacetoken" | parse )
IFS=$saveifs
echo
echo "You can also use associative arrays, but it's dangerous. If someone figures out how to bypass quoting their arbitrary value will get eval'ed!"
eval Aexec=(`./JSON.sh -f array < package.json`)
parse_options -f array
eval Afunc=(`cat package.json | tokenize | parse`)
echo
[ "${!Aexec[*]}" == "${!Afunc[*]}" ] && echo "Keys match" || echo "Keys don't match!!"
[ "${Aexec[*]}"  == "${Afunc[*]}"  ] && echo "Values match" || echo "Values don't match!!"
for key in "${!Afunc[@]}"; do
  printf '%20s = %s\n' "$key" "${Afunc[$key]}"
done
echo
echo "Need to be careful with array quoting too"
out=`echo "$spacetoken" | parse`
echo $out
eval Afunc=($out)
echo OK
for key in "${!Afunc[@]}"; do printf '%40s = %s\n' "$key" "${Afunc[$key]}"; done
echo bad
for key in ${!Afunc[@]}; do printf '%40s = %s\n' "$key" "${Afunc[$key]}"; done
echo bad
for key in "${!Afunc[*]}"; do printf '%40s = %s\n' "$key" "${Afunc[$key]}"; done
echo bad
for key in ${!Afunc[*]}; do printf '%40s = %s\n' "$key" "${Afunc[$key]}"; done
echo
echo "You can define an associative array in a read loop, and get similar results without the danger of eval."
parse_options -f kv
saveifs=$IFS
IFS=$'\t'
while read -r key value; do
  Akv[$key]=$value
done < <( echo "$spacetoken" | parse )
IFS=$saveifs
parse_options -f array
eval Afunc=(`echo "$spacetoken" | parse`)

echo Akv:
for key in "${!Akv[@]}"; do printf '%40s = %s\n' "$key" "${Akv[$key]}"; done
echo Afunc:
for key in "${!Afunc[@]}"; do printf '%40s = %s\n' "$key" "${Afunc[$key]}"; done

# vi: expandtab ts=2 sw=2
