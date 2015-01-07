#!/bin/sh

# Generate the reference results in a standardized manner
# (script options, extensions, locale)
LANG=C
LC_ALL=C
export LANG
export C

JSONSH=../../JSON.sh

for F in *.json ; do
	B="`basename "$F" .json`"
	echo "=== Generating results for '$F'..."

	EXT=parsed
	$JSONSH < "$F" > "$B.$EXT" || echo "ERROR with $EXT"

	EXT=sorted
	$JSONSH -S="-n -r" < "$F" > "$B.$EXT" || echo "ERROR with $EXT"

	EXT=normalized
	$JSONSH -N < "$F" > "$B.$EXT" || echo "ERROR with $EXT"

	EXT=normalized_sorted
	$JSONSH -N='-n' < "$F" > "$B.$EXT" || echo "ERROR with $EXT"
done

