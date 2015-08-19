#!/usr/bin/env bash
#
# Copyright (C) 2014-2015 Dominic Tarr
# Copyright (C) 2015 Eaton
#
#! \file    JSON.sh
#  \brief   A json parser written in bash
#  \author  Dominic Tarr <https://github.com/dominictarr>
#  \author  Jim Klimov <EvgenyKlimov@Eaton.com>
#  \details Based on Dominic Tarr JSON.sh
#           https://github.com/dominictarr/JSON.sh/blob/master/JSON.sh
#           Forked and further modified by Eaton / Jim Klimov
#           https://github.com/jimklimov/JSON.sh
#
# The MIT License (MIT)
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

throw () {
  echo "$*" >&2
  exit 1
}

BRIEF=0
LEAFONLY=0
PRUNE=0
ALLOWEMPTYINPUT=1
NORMALIZE_SOLIDUS=0
SORTDATA_OBJ=""
SORTDATA_ARR=""
NORMALIZE=0
NORMALIZE_NUMBERS=0
NORMALIZE_NUMBERS_FORMAT='%.6f'
NORMALIZE_NUMBERS_STRIP=0
EXTRACT_JPATH=""
TOXIC_NEWLINE=0
COOKASTRING=0

findbin() {
    # Locates a named binary or one from path, prints to stdout
    local BIN
    for P in "$@" ; do case "$P" in
	/*) [ -x "$P" ] && BIN="$P" && break;;
        *) BIN="`which "$P" 2>/dev/null | tail -1`" && [ -n "$BIN" ] && [ -x "$BIN" ] && break || BIN="";;
    esac; done
    [ -n "$BIN" ] && [ -x "$BIN" ] && echo "$BIN" && return 0
    return 1
}

# May be passed by caller; also may pass AWK_OPTS *for it* then
[ -z "$AWK" ] && AWK_OPTS="" && \
    AWK="`findbin /usr/xpg4/bin/awk gawk nawk oawk awk`"
# Error-checked in one optional place it may be needed

# Different OSes have different greps... we like a GNU one
[ -z "$GGREP" ] && \
    GGREP="`findbin ggrep /usr/xpg4/bin/grep grep`"
[ -n "$GGREP" ] && [ -x "$GGREP" ] || throw "No GNU GREP was found!"

[ -z "$GEGREP" ] && \
    GEGREP="`findbin gegrep /usr/xpg4/bin/egrep egrep`"
[ -n "$GEGREP" ] && [ -x "$GEGREP" ] || throw "No GNU EGREP was found!"

[ -z "$GSORT" ] && \
    GSORT="`findbin gsort sort /usr/xpg4/bin/sort`"
[ -n "$GSORT" ] && [ -x "$GSORT" ] || throw "No GNU SORT was found!"

[ -z "$GSED" ] && \
    GSED="`findbin /usr/xpg4/bin/sed gsed sed`"
[ -n "$GSED" ] && [ -x "$GSED" ] || throw "No GNU SED was found!"

usage() {
  echo
  echo "Usage: JSON.sh [-b] [-l] [-p] [ -P] [-s] [--no-newline] [-d] \ "
  echo "               [-x 'regex'] [-S|-S='args'] [-N|-N='args'] \ "
  echo "               [-Nnx|-Nnx='fmtstr'|-Nn|-Nn='fmtstr'] < markup.json"
  echo "       JSON.sh [-h]"
  echo "-h - This help text."
  echo
  echo "-p - Prune empty. Exclude fields with empty values."
  echo "-P - Pedantic mode, forbids acception of empty input documents."
  echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
  echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
  echo "-s - Remove escaping of the solidus symbol (stright slash)."
  echo "-x 'regex' - rather than showing all document from the root element,"
  echo "     extract the items rooted at path(s) matching the regex (see the"
  echo "     comma-separated list of nested hierarchy names in general output,"
  echo "     brackets not included) e.g. regex='^\"level1obj\",\"level2arr\",0'"
  echo "--no-newline - rather than concatenating detected line breaks in markup,"
  echo "     return with error when this is seen in input"
  echo "-d - Enable debugging traces to stderr (repeat or use -d=NUM to bump)"
  echo
  echo "Sorting is also available, although limited to single-line strings in"
  echo "the markup (multilines are automatically escaped into backslash+n):"
  echo "-S - Sort the contents of items in JSON markup and leaf-list markup:"
  echo "     'sort' objects by key names and then values, and arrays by values"
  echo "-S='args' - use 'sort \$args' for content sorting, e.g. use -S='-n -r'"
  echo "     for reverse numeric sort"
  echo "-So|-So='args' - enable sorting (with given arguments) only for objects"
  echo "-Sa|-Sa='args' - enable sorting (with given arguments) only for arrays"
  echo
  echo "An input JSON markup can be normalized into single-line no-whitespace:"
  echo "-N - Normalize the input JSON markup into a single-line JSON output;"
  echo "     in this mode syntax and spacing are normalized, data order remains"
  echo "-N='args' - Normalize the input JSON markup into a single-line JSON"
  echo "     output with contents sorted like for -S='args', e.g. use -N='-n'"
  echo "     This is equivalent to -N -S='args', just more compact to write"
  echo "-No='args' - enable sorting (with given arguments) only for objects"
  echo "-Na='args' - enable sorting (with given arguments) only for arrays"
  echo
  echo "Numeric values can be normalized (e.g. convert engineering into layman)"
  echo "-Nn='fmtstr' - printf the detected numeric values with the fmtstr conversion"
  echo "-Nn  - assume 'fmtstr'='%.6f' (with 6 precision digits after period)"
  echo "-Nnx - -Nn + strip trailing zeroes and trailing period (for whole numbers)"
  echo
  echo "To help JSON-related scripting, with '-Q' an input plaintext can be cooked"
  echo "into a string valid for JSON (backslashes, quotes and newlines escaped,"
  echo "with no trailing newline); after cooking, the script exits:"
  echo '       COOKEDSTRING="`somecommand 2>&1 | JSON.sh -Q`"'
  echo "This can also be used to pack JSON in JSON."
  echo
}

validate_debuglevel() {
    ### Beside command-line, debugging can be enabled by envvars from the caller
    [ x"$DEBUG" = xy -o x"$DEBUG" = xyes ] && DEBUG=1
    [ -n "$DEBUG" -a "$DEBUG" -ge 0 ] 2>/dev/null || DEBUG=0
}

unquote() {
    # Remove single or double quotes surrounding the token
    $GSED "s,^'\(.*\)'\$,\1," 2>/dev/null | \
    $GSED 's,^\"\(.*\)\"$,\1,' 2>/dev/null
}

### Empty and non-numeric and non-positive values should be filtered out here
is_positive() {
    [ -n "$1" -a "$1" -gt 0 ] 2>/dev/null
}
default_posval() {
    eval is_positive "\$$1" || eval "$1"="$2"
}

print_debug() {
    # Required params:
    #   $1	Debug level of the message
    #   $2..	The message to print to stderr (if $DEBUG>=$1)
    local DL="$1"
    shift
    [ "$DEBUG" -ge "$DL" ] 2>/dev/null && \
        echo -E "[$$]DEBUG($DL): $@" >&2
    :
}

tee_stderr() {
    TEE_TAG="TEE_STDERR: "
    [ -n "$1" ] && TEE_TAG="$1:"
    [ -n "$2" -a "$2" -ge 0 ] 2>/dev/null && \
        TEE_DEBUG="$2" || \
        TEE_DEBUG=$DEBUGLEVEL_PRINTTOKEN_PIPELINE

    ### If debug is not enabled, skip tee'ing quickly with little impact
    [ "$DEBUG" -lt "$TEE_DEBUG" ] 2>/dev/null && cat || \
    while IFS= read -r LINE; do
        echo -E "$LINE"
        print_debug "$TEE_DEBUG" "$TEE_TAG" "$LINE"
    done
    :
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
      -P) ALLOWEMPTYINPUT=0
      ;;
      -s) NORMALIZE_SOLIDUS=1
      ;;
      -N) NORMALIZE=1
      ;;
      -N=*) NORMALIZE=1
          SORTDATA_OBJ="$GSORT `echo "$1" | $GSED 's,^-N=,,' 2>/dev/null | unquote `"
          SORTDATA_ARR="$GSORT `echo "$1" | $GSED 's,^-N=,,' 2>/dev/null | unquote `"
      ;;
      -No=*) NORMALIZE=1
          SORTDATA_OBJ="$GSORT `echo "$1" | $GSED 's,^-No=,,' 2>/dev/null | unquote `"
      ;;
      -Na=*) NORMALIZE=1
          SORTDATA_ARR="$GSORT `echo "$1" | $GSED 's,^-Na=,,' 2>/dev/null | unquote `"
      ;;
      -Nnx) NORMALIZE_NUMBERS_STRIP=1
            NORMALIZE_NUMBERS=1
      ;;
      -Nnx=*) NORMALIZE_NUMBERS_STRIP=1
            NORMALIZE_NUMBERS=1
            NORMALIZE_NUMBERS_FORMAT="`echo "$1" | $GSED 's,^-Nnx=,,' 2>/dev/null | unquote `"
      ;;
      -Nn) NORMALIZE_NUMBERS=1
      ;;
      -Nn=*) NORMALIZE_NUMBERS=1
          NORMALIZE_NUMBERS_FORMAT="`echo "$1" | $GSED 's,^-Nn=,,' 2>/dev/null | unquote `"
      ;;
      -S) SORTDATA_OBJ="$GSORT"
          SORTDATA_ARR="$GSORT"
      ;;
      -So) SORTDATA_OBJ="$GSORT"
      ;;
      -Sa) SORTDATA_ARR="$GSORT"
      ;;
      -S=*)
          SORTDATA_OBJ="$GSORT `echo "$1" | $GSED 's,^-S=,,' 2>/dev/null | unquote `"
          SORTDATA_ARR="$GSORT `echo "$1" | $GSED 's,^-S=,,' 2>/dev/null | unquote `"
      ;;
      -So=*)
          SORTDATA_OBJ="$GSORT `echo "$1" | $GSED 's,^-So=,,' 2>/dev/null | unquote `"
      ;;
      -Sa=*)
          SORTDATA_ARR="$GSORT `echo "$1" | $GSED 's,^-Sa=,,' 2>/dev/null | unquote `"
      ;;
      -x) EXTRACT_JPATH="$2"
          shift
      ;;
      -x=*) EXTRACT_JPATH="`echo "$1" | $GSED 's,^-x=,,' 2>/dev/null`"
      ;;
      --no-newline)
          TOXIC_NEWLINE=1
      ;;
      -d) DEBUG=$(($DEBUG+1))
      ;;
      -d=*) DEBUG="`echo "$1" | $GSED 's,^-d=,,' 2>/dev/null`"
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

  validate_debuglevel

  # For normalized data, we do the whole job and just return the top object
  [ "$NORMALIZE" -eq 1 ] && BRIEF=0 && LEAFONLY=0 && PRUNE=0
}

awk_egrep () {
  local pattern_string=$1

  [ -z "$AWK" ] && throw "No AWK found!"
  [ ! -x "$AWK" ] && throw "Not executable AWK='$AWK'!"

  ${AWK} $AWK_OPTS '{
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

  # The first "grep" should ensure that input for "while" has a trailing newline
  $GGREP '' | \
  tee_stderr BEFORE_STRIP $DEBUGLEVEL_PRINTTOKEN_PIPELINE | \
  while IFS="" read -r ILINE; do
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
        echo "ERROR: Invalid JSON markup detected: newline in a string value: at line #$LINENUM" >&2 && \
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
    ### Escape backslashes, double-quotes, tabs and newlines, in this order
    $GGREP '' | $GSED -e 's,\\,\\\\,g' -e 's,\",\\",g' -e 's,\t,\\t,g' 2>/dev/null | \
    { FIRST=''; while IFS="" read -r ILINE; do
      printf '%s%s' "$FIRST" "$ILINE"
      [ -z "$FIRST" ] && FIRST='\n'
      done; }
    :
}

tokenize () {
  local GREP_O
  local ESCAPE
  local CHAR

  if echo "test string" | $GEGREP -ao --color=never "test" >/dev/null 2>/dev/null
  then
    GREP_O="$GEGREP -ao --color=never"
  elif echo "test string" | $GEGREP -ao "test" >/dev/null 2>/dev/null
  then
    GREP_O="$GEGREP -ao"
  elif echo "test string" | $GEGREP -o "test" >/dev/null 2>/dev/null
  then
    GREP_O="$GEGREP -o"
  fi

  if [ -n "$GREP_O" ] && echo "test string" | $GREP_O "test" >/dev/null
  then
    ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\]'
  else
    GREP_O=awk_egrep
    ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\\\]'
  fi

  # Allow tabs inside strings
  local CHART="($CHAR|[[:blank:]])"
  local STRINGVAL="$CHART*($ESCAPE$CHART*)*"
  local STRING="(\"$STRINGVAL\")"
  local NUMBER='[+-]?([.][0-9]+|(0+|[1-9][0-9]*)([.][0-9]*)?)([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'

  tee_stderr BEFORE_TOKENIZER $DEBUGLEVEL_PRINTTOKEN_PIPELINE | \
  $GREP_O "$STRING|$NUMBER|$KEYWORD|$SPACE|." | $GEGREP -v "^$SPACE$" | \
  tee_stderr AFTER_TOKENIZER $DEBUGLEVEL_PRINTTOKEN_PIPELINE
}

parse_array () {
  local index=0
  local ary=''
  local aryml=''
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse_array(1):" "token='$token'"
  case "$token" in
    ']') ;;
    *)
      while :
      do
        parse_value "$1" "$index"
        index=$((index+1))
        ary="$ary""$value"
        if [ -n "$SORTDATA_ARR" ]; then
            [ -z "$aryml" ] && aryml="$value" || aryml="$aryml
$value"
        fi
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_array(2):" "token='$token'"
        case "$token" in
          ']') break ;;
          ',') ary="$ary," ;;
          *) throw "EXPECTED ',' or ']' GOT '${token:-EOF}'" ;;
        esac
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_array(3):" "token='$token'"
      done
      ;;
  esac
  if [ -n "$SORTDATA_ARR" ]; then
    ary="`echo -E "$aryml" | $SORTDATA_ARR | tr '\n' ',' | $GSED 's|,*$||' 2>/dev/null | $GSED 's|^,*||' 2>/dev/null`"
  fi
  [ "$BRIEF" -eq 0 ] && value=`printf '[%s]' "$ary"` || value=
  :
}

parse_object () {
  local key
  local obj=''
  local objml=''
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(1):" "token='$token'"
  case "$token" in
    '}') ;;
    *)
      while :
      do
        case "$token" in
          '"'*'"') key=$token ;;
          *) throw "EXPECTED string GOT '${token:-EOF}'" ;;
        esac
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(2):" "token='$token'"
        case "$token" in
          ':') ;;
          *) throw "EXPECTED : GOT '${token:-EOF}'" ;;
        esac
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(3):" "token='$token'"
        parse_value "$1" "$key"
        obj="$obj$key:$value"
        if [ -n "$SORTDATA_OBJ" ]; then
            [ -z "$objml" ] && objml="$key:$value" || objml="$objml
$key:$value"
        fi
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(4):" "token='$token'"
        case "$token" in
          '}') break ;;
          ',') obj="$obj," ;;
          *) throw "EXPECTED ',' or '}' GOT '${token:-EOF}'" ;;
        esac
        read -r token
        print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(5):" "token='$token'"
      done
    ;;
  esac
  if [ -n "$SORTDATA_OBJ" ]; then
    obj="`echo -E "$objml" | $SORTDATA_OBJ | tr '\n' ',' | $GSED 's|,*$||' 2>/dev/null | $GSED 's|^,*||' 2>/dev/null`"
  fi
  [ "$BRIEF" -eq 0 ] && value=`printf '{%s}' "$obj"` || value=
  :
}

REGEX_NUMBER='^[+-]?([.][0-9]+|(0+|[1-9][0-9]*)([.][0-9]*)?)([eE][+-]?[0-9]*)?$'
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
    ''|[!0-9]) if [ "$ALLOWEMPTYINPUT" = 1 -a -z "$jpath" ] && [ -z "$token" ]; then
            print_debug $DEBUGLEVEL_PRINTPATHVAL \
                'Got a NULL document as input (no jpath, no token)' >&2
            value='{}'
        else
            throw "EXPECTED value GOT '${token:-EOF}'"
        fi ;;
    +*|-*|[0-9]*|.*)  # Potential number - separate hit in case for efficiency
       print_debug $DEBUGLEVEL_PRINTPATHVAL \
            "token '$token' is a suspected number" >&2
       if [ "$NORMALIZE_NUMBERS" = 1 ] && \
         [[ "$token" =~ ${REGEX_NUMBER} ]] \
       ; then
            value="`printf "$NORMALIZE_NUMBERS_FORMAT" "$token"`" || \
            value=$token
            print_debug $DEBUGLEVEL_PRINTPATHVAL "normalized numeric token" \
                "'$token' into '$value'" >&2
            if [ "$NORMALIZE_NUMBERS_STRIP" = 1 ]; then
                local valuetmp="`echo "$value" | $GSED -e 's,0*$,,g' -e 's,\.$,,' 2>/dev/null`" && \
                value="$valuetmp"
                unset valuetmp
                print_debug $DEBUGLEVEL_PRINTPATHVAL "stripped numeric token" \
                    "'$token' into '$value'" >&2
            fi
       else
        # Not a number or no normalization - process like default
            value=$token
            [ "$NORMALIZE_SOLIDUS" -eq 1 ] && value=${value//\\\//\/}
       fi
       isleaf=1
       [ "$value" = '""' -o "$value" = '' ] && isempty=1
       ;;
    *) value=$token
       # if asked, replace solidus ("\/") in json strings with normalized value: "/"
       [ "$NORMALIZE_SOLIDUS" -eq 1 ] && value=${value//\\\//\/}
       isleaf=1
       [ "$value" = '""' ] && isempty=1
       ;;
  esac

  if [ "$NORMALIZE" -eq 1 ]; then
    # Ensure a "true" output from the "if" for "return"
    if [ "$jpath" != '' ]; then : ; else
        print_debug $DEBUGLEVEL_PRINTPATHVAL \
            "Non-root keys were skipped due to normalization mode"
	printf "%s\n" "$value"
    fi
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

  print_debug $DEBUGLEVEL_PRINTPATHVAL \
	"JPATH='$jpath' VALUE='$value' B='$BRIEF'" \
	"isleaf='$isleaf'/L='$LEAFONLY' isempty='$isempty'/P='$PRUNE':" \
	"print='$print'" >&2

  [ "$print" -gt 0 ] && printf "[%s]\t%s\n" "$jpath" "$value"
  :
}

parse () {
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse(1):" "token='$token'"
  parse_value
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse(2):" "token='$token'"
  case "$token" in
    '') ;;
    *) throw "EXPECTED EOF GOT '$token'" ;;
  esac
}

smart_parse() {
  strip_newlines | \
  tokenize | if [ -n "$SORTDATA_OBJ$SORTDATA_ARR" ] ; then
      ### Any type of sort was enabled
      ( NORMALIZE=1 LEAFONLY=0 BRIEF=0 parse ) \
      | tokenize | parse
    else
      parse
    fi
}

###########################################################
### Active logic

### Caller can disable specific debuggers by setting their level too high
validate_debuglevel
default_posval DEBUGLEVEL_PRINTPATHVAL		1
default_posval DEBUGLEVEL_PRINTTOKEN		2
default_posval DEBUGLEVEL_PRINTTOKEN_PIPELINE	3
default_posval DEBUGLEVEL_TRACE_X		4
default_posval DEBUGLEVEL_TRACE_V		5
default_posval DEBUGLEVEL_MERGE_ERROUT		4

if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
then
  parse_options "$@"
  # Note that the options enable some debug level

  [ "$DEBUG" -ge "$DEBUGLEVEL_MERGE_ERROUT" ] && \
    exec 2>&1 && \
    echo "[$$]DEBUG: Merge stderr and stdout for easier tracing with less" \
	"(DEBUGLEVEL_MERGE_ERROUT=$DEBUGLEVEL_MERGE_ERROUT)" >&2
  [ "$DEBUG" -gt 0 ] && \
    echo "[$$]DEBUG: Enabled (debugging level $DEBUG)" >&2
  [ "$DEBUG" -ge "$DEBUGLEVEL_PRINTPATHVAL" ] && \
    echo "[$$]DEBUG: Enabled tracing of path:value printing decisions" \
	"(DEBUGLEVEL_PRINTPATHVAL=$DEBUGLEVEL_PRINTPATHVAL)" >&2
  [ "$DEBUG" -ge "$DEBUGLEVEL_PRINTTOKEN" ] && \
    echo "[$$]DEBUG: Enabled printing of each processed token" \
	"(DEBUGLEVEL_PRINTTOKEN=$DEBUGLEVEL_PRINTTOKEN)" >&2
  [ "$DEBUG" -ge "$DEBUGLEVEL_PRINTTOKEN_PIPELINE" ] && \
    echo "[$$]DEBUG: Enabled tracing of read-in token conversions" \
	"(DEBUGLEVEL_PRINTTOKEN_PIPELINE=$DEBUGLEVEL_PRINTTOKEN_PIPELINE)" >&2
  [ "$DEBUG" -ge "$DEBUGLEVEL_TRACE_V" ] && \
    echo "[$$]DEBUG: Enable execution tracing (-v)" \
	"(DEBUGLEVEL_TRACE_V=$DEBUGLEVEL_TRACE_V)" >&2 && \
    set +v
  [ "$DEBUG" -ge "$DEBUGLEVEL_TRACE_X" ] && \
    echo "[$$]DEBUG: Enable execution tracing (-x)" \
	"(DEBUGLEVEL_TRACE_X=$DEBUGLEVEL_TRACE_X)" >&2 && \
    set -x

  tee_stderr RAW_INPUT $DEBUGLEVEL_PRINTTOKEN_PIPELINE | \
  if [ "$COOKASTRING" -eq 1 ]; then
    cook_a_string
  else
    smart_parse
  fi
fi
