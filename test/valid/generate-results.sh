#!/bin/sh

# Generate the reference results in a standardized manner
# (script options, extensions, locale)
LANG=C
LC_ALL=C
export LANG
export C

JSONSH=../../JSON.sh

generate() {
	F="$1"
	[ -s "$F" ] || return

	B="`basename "$F" .json`"
	echo "=== Generating results for '$F'..."
	RES=0

	EXT=parsed
	$JSONSH < "$F" > "$B.$EXT" || \
	    { RES=$?; echo "ERROR with $EXT"; }

	EXT=sorted
	$JSONSH -S="-n -r" < "$F" > "$B.$EXT" || \
	    { RES=$?; echo "ERROR with $EXT"; }

	EXT=normalized
	$JSONSH -N < "$F" > "$B.$EXT" || \
	    { RES=$?; echo "ERROR with $EXT"; }

	EXT=normalized_sorted
	$JSONSH -N='-n' < "$F" > "$B.$EXT" || \
	    { RES=$?; echo "ERROR with $EXT"; }

	return $RES
}

if [ $# -gt 0 ]; then
    for F in "$@" ; do
	generate "$F"
    done
else
    for F in *.json ; do
	generate "$F"
    done
fi
