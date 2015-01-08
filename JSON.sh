#!/usr/bin/env bash

# https://github.com/dominictarr/JSON.sh/blob/master/JSON.sh
# MIT / Apache 2 licenses (C) 2014 by "dominictarr" checked out 2015-01-04
# further development (C) 2015 Jim Klimov <EvgenyKlimov@eaton.com>

throw () {
  echo "$*" >&2
  exit 1
}

BRIEF=0
LEAFONLY=0
PRUNE=0
SORTDATA=""
NORMALIZE=0
EXTRACT_JPATH=""
TOXIC_NEWLINE=0
DEBUG=0
COOKASTRING=0

usage() {
  echo
  echo "Usage: JSON.sh [-b] [-l] [-p] [-x 'regex'] [-S|-S='args'] [--no-newline] [-d]"
  echo "       JSON.sh [-N|-N='args'] < markup.json"
  echo "       JSON.sh [-h]"
  echo "-h - This help text."
  echo
  echo "-p - Prune empty. Exclude fields with empty values."
  echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
  echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
  echo "-x 'regex' - rather than showing all document from the root element,"
  echo "     extract the items rooted at path(s) matching the regex (see the"
  echo "     comma-separated list of nested hierarchy names in general output,"
  echo "     brackets not included) e.g. regex='^\"level1\",\"level2arr\",0'"
  echo "--no-newline - rather than concatenating detected line breaks in markup,"
  echo "     return with error when this is seen in input"
  echo "-d - Enable debugging traces to stderr"
  echo
  echo "Sorting is also available, although limited to single-line strings in"
  echo "the markup (multilines are automatically escaped into backslash+n):"
  echo "-S - Sort the contents of items in JSON markup and leaf-list markup:"
  echo "     'sort' objects by key names and then values, and arrays by values"
  echo "-S='args' - use 'sort \$args' for content sorting, e.g. use -S='-n -r'"
  echo "     for reverse numeric sort"
  echo
  echo "An input JSON markup can be normalized into single-line no-whitespace:"
  echo "-N - Normalize the input JSON markup into a single-line JSON output;"
  echo "     in this mode syntax and spacing are normalized, data order remains"
  echo "-N='args' - Normalize the input JSON markup into a single-line JSON"
  echo "     output with contents sorted like for -S='args', e.g. use -N='-n'"
  echo "     This is equivalent to -N -S='args', just more compact to write"
  echo
  echo "To help JSON-related scripting, with '-Q' an input plaintext can be cooked"
  echo "into a string valid for JSON (backslashes, quotes and newlines escaped,"
  echo "with no trailing newline); after cooking, the script exits:"
  echo '       COOKEDSTRING="`somecommand 2>&1 | JSON.sh -Q`"'
  echo "This can also be used to pack JSON in JSON."
  echo
}

unquote() {
    # Remove single or double quotes surrounding the token
    sed "s,^'\(.*\)'\$,\1," | sed 's,^\"\(.*\)\"$,\1,'
}

parse_options() {
  set -- "$@"
  local ARGN=$#
  while [ $ARGN -ne 0 ]
  do
    case "$1" in
      -h) usage
          exit 0
      ;;
      -b) BRIEF=1
          LEAFONLY=1
          PRUNE=1
      ;;
      -l) LEAFONLY=1
      ;;
      -p) PRUNE=1
      ;;
      -N) NORMALIZE=1
      ;;
      -N=*) SORTDATA="sort `echo "$1" | sed 's,^-N=,,' | unquote `"
          NORMALIZE=1
      ;;
      -S) SORTDATA="sort"
      ;;
      -S=*) SORTDATA="sort `echo "$1" | sed 's,^-S=,,' | unquote `"
      ;;
      -x) EXTRACT_JPATH="$2"
          shift
      ;;
      --no-newline)
          TOXIC_NEWLINE=1
      ;;
      -d) DEBUG=$(($DEBUG+1))
      ;;
      -Q) COOKASTRING=1
      ;;
      ?*) echo "ERROR: Unknown option '$1'."
          usage
          exit 0
      ;;
    esac
    shift 1
    ARGN=$((ARGN-1))
  done

  # For normalized data, we do the whole job and just return the top object
  [ "$NORMALIZE" -eq 1 ] && BRIEF=0 && LEAFONLY=0 && PRUNE=0
}

awk_egrep () {
  local pattern_string=$1

  gawk '{
    while ($0) {
      start=match($0, pattern);
      token=substr($0, start, RLENGTH);
      print token;
      $0=substr($0, start+RLENGTH);
    }
  }' pattern=$pattern_string
}

strip_newlines() {
  # replace line returns inside strings in input with \n string
  local ILINE
  local LINESTRIP
  local NUMQ
  local ODD
  local INSTRING=0
  local LINENUM=0

  # the first "grep" should ensure that input has a trailing newline
  grep '' | while IFS="" read -r ILINE; do
    # Remove escaped quotes:
    LINESTRIP="${ILINE//\\\"}"
    # Remove all chars but remaining quotes:
    LINESTRIP="${LINESTRIP//[^\"]}"
    # Count unescaped quotes:
    NUMQ="${#LINESTRIP}"
    ODD="$(($NUMQ%2))"
    LINENUM="$(($LINENUM+1))"

    if [ "$ODD" -eq 1 -a "$INSTRING" -eq 0 ]; then
      [ "$TOXIC_NEWLINE" = 1 ] && \
        echo "Invalid JSON markup detected: newline in a string value: at line #$LINENUM" >&2 && \
        exit 121
      printf '%s\\n' "$ILINE"
      INSTRING=1
      continue
    fi

    if [ "$ODD" -eq 1 -a "$INSTRING" -eq 1 ]; then
      printf '%s\n' "$ILINE"
      INSTRING=0
      continue
    fi

    if [ "$ODD" -eq 0 -a "$INSTRING" -eq 1 ]; then
      printf '%s\\n' "$ILINE"
      continue
    fi

    if [ "$ODD" -eq 0 -a "$INSTRING" -eq 0 ]; then
      printf '%s\n' "$ILINE"
      continue
    fi
  done
  :
}

cook_a_string() {
    ### Escape backslashes, double-quotes and newlines, in this order
    grep '' | sed -e 's,\\,\\\\,g' -e 's,\",\\",g' | \
    { FIRST=''; while IFS="" read -r ILINE; do
      printf '%s%s' "$FIRST" "$ILINE"
      [ -z "$FIRST" ] && FIRST='\n'
      done; }
    :
}

tokenize () {
  local GREP
  local ESCAPE
  local CHAR

  if echo "test string" | egrep -ao --color=never "test" &>/dev/null
  then
    GREP='egrep -ao --color=never'
  else
    GREP='egrep -ao'
  fi

  if echo "test string" | egrep -o "test" &>/dev/null
  then
    ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\]'
  else
    GREP=awk_egrep
    ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\\\]'
  fi

  local STRINGVAL="$CHAR*($ESCAPE$CHAR*)*"
  local STRING="(\"$STRINGVAL\")"
  local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'

  $GREP "$STRING|$NUMBER|$KEYWORD|$SPACE|." | egrep -v "^$SPACE$"
}

parse_array () {
  local index=0
  local ary=''
  local aryml=''
  read -r token
  case "$token" in
    ']') ;;
    *)
      while :
      do
        parse_value "$1" "$index"
        index=$((index+1))
        ary="$ary""$value"
        if [ -n "$SORTDATA" ]; then
            [ -z "$aryml" ] && aryml="$value" || aryml="$aryml
$value"
        fi
        read -r token
        case "$token" in
          ']') break ;;
          ',') ary="$ary," ;;
          *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
        esac
        read -r token
      done
      ;;
  esac
  if [ -n "$SORTDATA" ]; then
    ary="`echo -E "$aryml" | $SORTDATA | tr '\n' ',' | sed 's|,*$||' | sed 's|^,*||'`"
  fi
  [ "$BRIEF" -eq 0 ] && value=`printf '[%s]' "$ary"` || value=
  :
}

parse_object () {
  local key
  local obj=''
  local objml=''
  read -r token
  case "$token" in
    '}') ;;
    *)
      while :
      do
        case "$token" in
          '"'*'"') key=$token ;;
          *) throw "EXPECTED string GOT ${token:-EOF}" ;;
        esac
        read -r token
        case "$token" in
          ':') ;;
          *) throw "EXPECTED : GOT ${token:-EOF}" ;;
        esac
        read -r token
        parse_value "$1" "$key"
        obj="$obj$key:$value"
        if [ -n "$SORTDATA" ]; then
            [ -z "$objml" ] && objml="$key:$value" || objml="$objml
$key:$value"
        fi
        read -r token
        case "$token" in
          '}') break ;;
          ',') obj="$obj," ;;
          *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
        esac
        read -r token
      done
    ;;
  esac
  if [ -n "$SORTDATA" ]; then
    obj="`echo -E "$objml" | $SORTDATA | tr '\n' ',' | sed 's|,*$||' | sed 's|^,*||'`"
  fi
  [ "$BRIEF" -eq 0 ] && value=`printf '{%s}' "$obj"` || value=
  :
}

parse_value () {
  local jpath="${1:+$1,}$2" isleaf=0 isempty=0 print=0
  case "$token" in
    '{') parse_object "$jpath"
       [ "$value" = '{}' ] && isempty=1
       ;;
    '[') parse_array  "$jpath"
       [ "$value" = '[]' ] && isempty=1
       ;;
    # At this point, the only valid single-character tokens are digits.
    ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
    *) value=$token
       isleaf=1
       [ "$value" = '""' ] && isempty=1
       ;;
  esac

  if [ "$NORMALIZE" -eq 1 ]; then
    # Ensure a "true" output from the "if" for "return"
    [ "$jpath" != '' ] || printf "%s\n" "$value"
    return
  fi

  ### Skip printing larger objects in brief mode
  [ "$value" = '' ] && return

  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=2
  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=3
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
    [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=4
  ### A special case of an empty array or object - for leaf printing
  ### without pruning, we are interested in these:
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 0 ] && [ "$isempty" -eq 1 ] && \
    [ $PRUNE -eq 0 ] && print=5

  if [ "$print" -ne 0 -a -n "$EXTRACT_JPATH" ] ; then
    ### BASH regex matching:
    [[ ${jpath} =~ ${EXTRACT_JPATH} ]] || print=-1
  fi

  [ "$DEBUG" -gt 0 ] && \
    echo "=== KEY='$jpath' VALUE='$value' B='$BRIEF'" \
	"isleaf='$isleaf'/L='$LEAFONLY' isempty='$isempty'/P='$PRUNE':" \
	"print='$print'" >&2

  [ "$print" -gt 0 ] && printf "[%s]\t%s\n" "$jpath" "$value"
  :
}

parse () {
  read -r token
  parse_value
  read -r token
  case "$token" in
    '') ;;
    *) throw "EXPECTED EOF GOT $token" ;;
  esac
}

smart_parse() {
  strip_newlines | \
  tokenize | if [ -n "$SORTDATA" ] ; then
      ( NORMALIZE=1 LEAFONLY=0 BRIEF=0 parse ) \
      | tokenize | parse
    else
      parse
    fi
}

if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
then
  parse_options "$@"
  if [ "$COOKASTRING" -eq 1 ]; then
    cook_a_string
  else
    smart_parse
  fi
fi
