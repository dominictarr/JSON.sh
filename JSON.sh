#!/bin/sh
#
# Copyright (C) 2014-2015 Dominic Tarr
# Copyright (C) 2015-2020 Eaton
#
#! \file    JSON.sh
#  \brief   A json parser written in shell-script
#  \author  Dominic Tarr <https://github.com/dominictarr>
#  \author  "aidanhs" <https://github.com/aidanhs> added
#  \author  Jim Klimov <EvgenyKlimov@Eaton.com>
#  \details Based on Dominic Tarr JSON.sh
#           https://github.com/dominictarr/JSON.sh/blob/master/JSON.sh
#           including "aidanhs" added support beyond bash -
#           for ash/dash/zsh shells and busybox shell,
#           Forked and further modified by Eaton / Jim Klimov
#           https://github.com/jimklimov/JSON.sh
#
# NOTE: This script may be used standalone or sourced into your interpreter.
# For the latter use-case it is recommended to pre-set JSONSH_SOURCED=yes
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

# NOTE: The script code requires a shell with support for "local"
# keyword; this includes not only BASH but some more nowadays.
# TODO: Add a way to detect supported shell interpreter features
# (e.g. double-brackets, local keyword, regex expressions...)
# to either refuse running in a shell or pick an implementation
# for certain code paths.

get_shellname() {
    # Linux
    if [ -x "/proc/$$/exe" ] ; then
        readlink "/proc/$$/exe" 2>/dev/null && return 0
        ls -la "/proc/$$/exe" | sed -e 's,^[^\/]*/,/,' -e 's,^.* -> ,,' 2>/dev/null && return 0
    fi

    # Solaris/illumos
    if [ -x "/proc/$$/path/a.out" ] ; then
        readlink "/proc/$$/path/a.out" 2>/dev/null && return 0
        ls -la "/proc/$$/path/a.out" | sed -e 's,^[^\/]*/,/,' -e 's,^.* -> ,,' 2>/dev/null && return 0
    fi

    # By far this is most portable approach... although forking makes it slow
    ps -e -o pid,comm | while read _PID _COMM ; do
        [ "$$" = "$_PID" ] && echo "$_COMM" && return 0
    done

    return 1
}

get_shellbasename() {
    basename "$(get_shellname)" || echo "sh"
}

# Flag that can be passed by caller - if we can not detect the interpreter (or
# know it as unsupported), may we try to re-execute with a more capable one?
[ -n "${SHELL_CANREEXEC-}" ] || SHELL_CANREEXEC=yes
SHELL_BASENAME="$(get_shellbasename)"

# Got support for regular expressions in extended-test [[ "$1" =~ ${regex} ]] ?
SHELL_REGEX=no
# Got support for pattern substitution in curly braces ${varname/pat/subst} ?
SHELL_TWOSLASH=no

SHELL_SUPPORTED=yes
SHELL_PIPEFAIL=no
case "$SHELL_BASENAME" in
    bash)
        SHELL_REGEX=yes
        SHELL_TWOSLASH=yes
        SHELL_PIPEFAIL=yes
        ;;
    dash|ash) # The spartan bare minimum
        ;;
    busybox*)
        #SHELL_TWOSLASH=yes
        SHELL_BASENAME=busybox
        ;;
    #ksh93) ;;
    #ksh88) ;;
    #ksh) ;;
    zsh)
        SHELL_REGEX=yes
        SHELL_TWOSLASH=unquoted
        ;;
    *)
        if [ -n "${BASH-}" ] || [ -n "${BASH_VERSION-}" ] || [ -n "${BASH_SOURCE-}" ] ; then
            SHELL_REGEX=yes
            SHELL_TWOSLASH=yes
            SHELL_BASENAME=bash
            SHELL_PIPEFAIL=yes
        elif [ -n "${ZSH_VERSION-}" ] ; then
            SHELL_REGEX=yes
            SHELL_TWOSLASH=unquoted
            SHELL_BASENAME=zsh
        else
            SHELL_SUPPORTED=no
        fi
        ;;
esac

# TODO: detect having been sourced into non-bash shells?
if [ -z "${JSONSH_SOURCED-}" ]; then
    case "$SHELL_BASENAME" in
        bash)
            if  [ "$0" = "$BASH_SOURCE[0]" ] || [ "$0" = "$BASH_SOURCE" ] ; then
                JSONSH_SOURCED=no
            fi
            if  [ -n "${BASH-}" ] && [ "$0" = "-bash" ] ; then
                JSONSH_SOURCED=yes
            fi
            ;;
        *)  JSONSH_SOURCED=no ;;
    esac
fi

if [ "$SHELL_SUPPORTED" != "yes" ]; then
    echo "Unknown shell for JSON.sh: $SHELL_BASENAME" >&2
    if [ "$SHELL_CANREEXEC" != no ] && [ "$JSONSH_SOURCED" != "yes" ] ; then
        # NOTE: This can break scripts which source this file and are not in bash
        for _TRY_SHELL in bash dash zsh ash busybox false ; do
            [ "$_TRY_SHELL" = busybox ] && _TRY_SHELL="busybox sh"
            ( $_TRY_SHELL -c "date" >/dev/null 2>/dev/null ) && break
        done

        echo "ERROR: JSON.sh requires to be run with BASH/ZSH/ASH/DASH interpreter! Subshelling due to SHELL_CANREEXEC=$SHELL_CANREEXEC : $_TRY_SHELL ..." >&2
        ( $_TRY_SHELL "$0" "$@" )
        exit $?
    else
        echo "WARNING: Not changing shell because SHELL_CANREEXEC=$SHELL_CANREEXEC or JSONSH_SOURCED=$JSONSH_SOURCED - but JSON parsing can fail later on" >&2
    fi
fi

throw() {
  echo "$*" >&2
  exit 1
}

BRIEF=0
LEAFONLY=0
PRUNE=0
NO_HEAD=0
ALLOWEMPTYINPUT=1
NORMALIZE_SOLIDUS=0
SORTDATA_OBJ=""
SORTDATA_ARR=""
NORMALIZE=0
NORMALIZE_NUMBERS=0
NORMALIZE_NUMBERS_FORMAT='%.6f'
NORMALIZE_NUMBERS_STRIP=0
PRETTYPRINT=0
EXTRACT_JPATH=""
SHELLABLE_OUTPUT=""
TOXIC_NEWLINE=0
COOKASTRING=0
COOKASTRING_INPUT=""

findbin() {
    # Locates a named binary or one from path, prints to stdout
    BIN=""
    for P in "$@" ; do case "$P" in
        /*) [ -x "$P" ] && BIN="$P" && break;;
        *) BIN="$(which "$P" 2>/dev/null | tail -1)" && [ -n "$BIN" ] && [ -x "$BIN" ] && break || BIN="";;
    esac; done
    [ -n "$BIN" ] && [ -x "$BIN" ] && echo "$BIN" && return 0
    return 1
}

# May be passed by caller; also may pass AWK_OPTS *for it* then
[ -z "$AWK" ] && AWK_OPTS="" && \
    AWK="$(findbin /usr/xpg4/bin/awk gawk nawk oawk awk)"
# Error-checked in one optional place it may be needed

# Different OSes have different greps... we like a GNU one
[ -z "$GGREP" ] && \
    GGREP="$(findbin /{usr,opt}/{gnu,sfw}/bin/grep ggrep /usr/xpg4/bin/grep grep)"
[ -n "$GGREP" ] && [ -x "$GGREP" ] || throw "No GNU GREP was found!"

[ -z "$GEGREP" ] && \
    GEGREP="$(findbin /{usr,opt}/{gnu,sfw}/bin/egrep gegrep /usr/xpg4/bin/egrep egrep)"
[ -n "$GEGREP" ] && [ -x "$GEGREP" ] || throw "No GNU EGREP was found!"

[ -z "$GSORT" ] && \
    GSORT="$(findbin /{usr,opt}/{gnu,sfw}/bin/sort gsort sort /usr/xpg4/bin/sort)"
[ -n "$GSORT" ] && [ -x "$GSORT" ] || throw "No GNU SORT was found!"

[ -z "$GSED" ] && \
    GSED="$(findbin /{usr,opt}/{gnu,sfw}/bin/sed /usr/xpg4/bin/sed gsed sed)"
[ -n "$GSED" ] && [ -x "$GSED" ] || throw "No GNU SED was found!"

usage() {
  echo
  echo "Usage: JSON.sh [-b] [-l] [-p] [-P] [-s] [--no-newline] [-d] \ "
  echo "               [-x 'regex'] [-S|-S='args'] [-N|-N='args'] \ "
  echo "               [-Nnx|-Nnx='fmtstr'|-Nn|-Nn='fmtstr'] < markup.json"
  echo "       JSON.sh [-h]"
  echo "-h - This help text."
  echo
  echo "-p - Prune empty. Exclude fields with empty values."
  echo "-P - Pedantic mode, forbids acception of empty input documents."
  echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
  echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
  echo "-n - No-head. Do not show nodes that have no path (lines that start with [])."
  echo "-s - Remove escaping of the solidus symbol (straight slash)."
  echo "-x 'regex' - rather than showing all document from the root element,"
  echo "     extract the items rooted at path(s) matching the regex (see the"
  echo "     comma-separated list of nested hierarchy names in general output,"
  echo "     brackets not included) e.g. regex='^\"level1obj\",\"level2arr\",0'"
  echo "--shellable-output=strings - Do not print the path column nor quotes"
  echo "     around values to ease backticked picking of exact data path items"
  echo '     into scripts (non-exact matches will be same as multiword text):'
  echo '     VALUE="$(JSON.sh --shellable-output=strings -x '"'"'^"field"$'"'"')"'
  echo "--shellable-output=string - same but returns one string (first hit if any)"
  echo "--shellable-output=arrays - Do not print the path column, add quotes:"
  echo '     ARR=( $(JSON.sh --shellable-output=arrays -x '"'"'^"array",[0-9]'"'"') )'
  echo "--get-string 'regex' - Alias to -l -x 'regex' --shellable-output=string"
  echo "--get-strings 'regex' - Alias to -l -x 'regex' --shellable-output=strings"
  echo "--get-array(s) 'regex' - Alias to -l -x 'regex' --shellable-output=arrays"
  echo "     intended for cases where caller knows data schema to make assumptions."
  echo "NOTE: The --shellable-output options only make sense for -l/-b mode,"
  echo "or -x preferably with -l/-b modes. Each found value is output with EOL"
  echo 'so you can pipe the output to `| while read LINE; do ... ; done` sanely.'
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
  echo "-No|-No='args' - enable sorting (with given arguments) only for objects"
  echo "-Na|-Na='args' - enable sorting (with given arguments) only for arrays"
  echo
  echo "Numeric values can be normalized (e.g. convert engineering into layman)"
  echo "-Nn='fmtstr' - printf the detected numeric values with the fmtstr conversion"
  echo "-Nn  - assume 'fmtstr'='%.6f' (with 6 precision digits after period)"
  echo "-Nnx - -Nn + strip trailing zeroes and trailing period (for whole numbers)"
  echo
  echo "--pretty-print - enable line-separated TAB-indented output mode"
  echo "     Note that it makes sense with normalized output (can be sorted too)"
  echo "     or a strict-matching --shellable-output=strings request"
  echo
  echo "To help JSON-related scripting, with '-Q' an input plaintext can be cooked"
  echo "into a string valid for JSON (backslashes, quotes and newlines escaped,"
  echo "with no trailing newline); after cooking, the script exits:"
  echo '       COOKEDSTRING="$(somecommand 2>&1 | JSON.sh -Q)"'
  echo "A '-QQ' mode also exists to cook a (single) command-line argument:"
  echo '       COOKEDSTRING="$(JSON.sh -QQ "$SAVED_INPUT")"'
  echo "This can also be used to pack JSON in JSON. Note that '-QQ' ignores stdin."
  echo
}

validate_debuglevel() {
    ### Beside command-line, debugging can be enabled by envvars from the caller
    { [ x"${DEBUG-}" = xy ] || [ x"${DEBUG-}" = xyes ] ; } && DEBUG=1
    [ -n "${DEBUG-}" ] && [ "${DEBUG-}" -ge 0 ] 2>/dev/null || DEBUG=0
}

unquote() {
    # Remove single or double quotes surrounding the token
    $GSED "s,^'\(.*\)'\$,\1," 2>/dev/null | \
    $GSED 's,^\"\(.*\)\"$,\1,' 2>/dev/null
}

### Empty and non-numeric and non-positive values should be filtered out here
is_positive() {
    [ -n "$1" ] && [ "$1" -gt 0 ] 2>/dev/null
}
default_posval() {
    eval is_positive "\$$1" || eval "$1"="$2"
}

print_debug() {
    # Required params:
    #   $1    Debug level of the message
    #   $2..  The message to print to stderr (if $DEBUG>=$1)
    DL="$1"
    shift
    [ "$DEBUG" -ge "$DL" ] 2>/dev/null && \
        printf '[%s]DEBUG(%s): %s\n' "$$" "$DL" "$*" >&2
    :
}

tee_stderr() {
    TEE_TAG="TEE_STDERR: "
    [ -n "$1" ] && TEE_TAG="$1:"
    [ -n "$2" ] && [ "$2" -ge 0 ] 2>/dev/null && \
        TEE_DEBUG="$2" || \
        TEE_DEBUG=$DEBUGLEVEL_PRINTTOKEN_PIPELINE

    ### If debug is not enabled, skip tee'ing quickly with little impact
    ### The first "grep" should ensure that input for "while" has a trailing newline
    [ "$DEBUG" -lt "$TEE_DEBUG" ] 2>/dev/null && cat || \
    $GGREP '' | while IFS= read -r LINE; do
        printf '%s\n' "$LINE"
        print_debug "$TEE_DEBUG" "$TEE_TAG" "$LINE"
    done
    :
}

parse_options() {
  set -- "$@"
  while [ "$#" -gt 0 ]
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
      -n) NO_HEAD=1
      ;;
      -s) NORMALIZE_SOLIDUS=1
      ;;
      --pretty-print) PRETTYPRINT=1
      ;;
      -N) NORMALIZE=1
      ;;
      -N=*) NORMALIZE=1
          SORTDATA_OBJ="$GSORT $(echo "$1" | $GSED 's,^-N=,,' 2>/dev/null | unquote )"
          SORTDATA_ARR="$GSORT $(echo "$1" | $GSED 's,^-N=,,' 2>/dev/null | unquote )"
      ;;
      -No=*) NORMALIZE=1
          SORTDATA_OBJ="$GSORT $(echo "$1" | $GSED 's,^-No=,,' 2>/dev/null | unquote )"
      ;;
      -Na=*) NORMALIZE=1
          SORTDATA_ARR="$GSORT $(echo "$1" | $GSED 's,^-Na=,,' 2>/dev/null | unquote )"
      ;;
      -No) SORTDATA_OBJ="$GSORT"
            NORMALIZE=1
      ;;
      -Na) SORTDATA_ARR="$GSORT"
            NORMALIZE=1
      ;;
      -Nnx) NORMALIZE_NUMBERS_STRIP=1
            NORMALIZE_NUMBERS=1
      ;;
      -Nnx=*) NORMALIZE_NUMBERS_STRIP=1
            NORMALIZE_NUMBERS=1
            NORMALIZE_NUMBERS_FORMAT="$(echo "$1" | $GSED 's,^-Nnx=,,' 2>/dev/null | unquote )"
      ;;
      -Nn) NORMALIZE_NUMBERS=1
      ;;
      -Nn=*) NORMALIZE_NUMBERS=1
          NORMALIZE_NUMBERS_FORMAT="$(echo "$1" | $GSED 's,^-Nn=,,' 2>/dev/null | unquote )"
      ;;
      -S) SORTDATA_OBJ="$GSORT"
          SORTDATA_ARR="$GSORT"
      ;;
      -So) SORTDATA_OBJ="$GSORT"
      ;;
      -Sa) SORTDATA_ARR="$GSORT"
      ;;
      -S=*)
          SORTDATA_OBJ="$GSORT $(echo "$1" | $GSED 's,^-S=,,' 2>/dev/null | unquote )"
          SORTDATA_ARR="$GSORT $(echo "$1" | $GSED 's,^-S=,,' 2>/dev/null | unquote )"
      ;;
      -So=*)
          SORTDATA_OBJ="$GSORT $(echo "$1" | $GSED 's,^-So=,,' 2>/dev/null | unquote )"
      ;;
      -Sa=*)
          SORTDATA_ARR="$GSORT $(echo "$1" | $GSED 's,^-Sa=,,' 2>/dev/null | unquote )"
      ;;
      -x|--get-strings|--get-string|--get-arrays|--get-array)
          case "$1" in
            --get-string) SHELLABLE_OUTPUT="string" ; LEAFONLY=1 ;;
            --get-strings) SHELLABLE_OUTPUT="strings" ; LEAFONLY=1 ;;
            --get-array*) SHELLABLE_OUTPUT="arrays" ; LEAFONLY=1 ;;
          esac
          EXTRACT_JPATH="$2"
          shift
      ;;
      -x=*|--get-strings=*|--get-string=*|--get-arrays=*|--get-array=*)
          EXTRACT_JPATH="$(echo "$1" | $GSED 's,^\(-x\|--get-strings*\|--get-arrays*\)=,,' 2>/dev/null)"
          case "$1" in
            --get-string) SHELLABLE_OUTPUT="string" ; LEAFONLY=1 ;;
            --get-strings) SHELLABLE_OUTPUT="strings" ; LEAFONLY=1 ;;
            --get-array*) SHELLABLE_OUTPUT="arrays" ; LEAFONLY=1 ;;
          esac
      ;;
      --shellable-output=string)
          SHELLABLE_OUTPUT="string"
      ;;
      --shellable-output=strings)
          SHELLABLE_OUTPUT="strings"
      ;;
      --shellable-output=array|--shellable-output=arrays)
          SHELLABLE_OUTPUT="arrays"
      ;;
      --no-newline)
          TOXIC_NEWLINE=1
      ;;
      -d) DEBUG="$(expr $DEBUG + 1)"
          JSONSH_DEBUGGING_SETUP=notdone
          JSONSH_DEBUGGING_REPORT=notdone
      ;;
      -d=*) DEBUG="$(echo "$1" | $GSED 's,^-d=,,' 2>/dev/null)"
          JSONSH_DEBUGGING_SETUP=notdone
          JSONSH_DEBUGGING_REPORT=notdone
      ;;
      -Q) COOKASTRING=1
      ;;
      -QQ) COOKASTRING=2
          COOKASTRING_INPUT="$2"
          shift
      ;;
      ?*) echo "ERROR: Unknown option: '$1'."
          usage
          exit 0
      ;;
    esac
    shift 1
  done

  if [ -n "$SHELLABLE_OUTPUT" ] && [ -z "$EXTRACT_JPATH" ] && [ "$LEAFONLY" = 0 ] ; then
    throw "ERROR: Option --shellable-output only makes sense with -x 'regex' and/or -l/-b"
  fi

  validate_debuglevel

  # For normalized data, we do the whole job and just return the top object
  [ "$NORMALIZE" = 1 ] && BRIEF=0 && LEAFONLY=0 && PRUNE=0
}

awk_egrep() {
  pattern_string="$1"

  [ -z "${AWK-}" ] && throw "No AWK found!"
  [ ! -x "$AWK" ] && throw "Not executable AWK='$AWK'!"

  "${AWK}" $AWK_OPTS '{
    while ($0) {
      start=match($0, pattern);
      token=substr($0, start, RLENGTH);
      print token;
      $0=substr($0, start+RLENGTH);
    }
  }' pattern="$pattern_string"
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
    case "$SHELL_TWOSLASH" in
      yes|quoted)
        # Remove escaped quotes as usual chars inside strings:
        LINESTRIP="${ILINE//\\\"}"
        # Remove all other chars but remaining quotes:
        LINESTRIP="${LINESTRIP//[^\"]}"
        ;;
      unquoted)
        LINESTRIP=${ILINE//\\\"}
        LINESTRIP=${LINESTRIP//[^\"]}
        ;;
      *)
        LINESTRIP="$(printf '%s\n' "$ILINE" | $GSED -e 's,\\\",,g' -e 's,[^"],,g')" ;;
    esac
    # Count unescaped quotes:
    NUMQ="${#LINESTRIP}"
    ODD="$(expr $NUMQ % 2)"
    LINENUM="$(expr $LINENUM + 1)"

    if [ "$ODD" -eq 1 ] && [ "$INSTRING" -eq 0 ]; then
      [ "$TOXIC_NEWLINE" = 1 ] && \
        echo "ERROR: Invalid JSON markup detected: newline in a string value: at line #$LINENUM" >&2 && \
        exit 121
      printf '%s\\n' "$ILINE"
      INSTRING=1
      continue
    fi

    if [ "$ODD" -eq 1 ] && [ "$INSTRING" -eq 1 ]; then
      printf '%s\n' "$ILINE"
      INSTRING=0
      continue
    fi

    if [ "$ODD" -eq 0 ] && [ "$INSTRING" -eq 1 ]; then
      printf '%s\\n' "$ILINE"
      continue
    fi

    if [ "$ODD" -eq 0 ] && [ "$INSTRING" -eq 0 ]; then
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
      [ -n "$FIRST" ] || FIRST='\n'
      done; }
    :
}

cook_a_string_arg() {
    # Use routine above to cook a string passed as "$1" unless it is trivial
    [ -z "$1" ] && return 0
    # Strangely, for some OSes it does not suffice that all chars must be from
    # the first pattern - should explicitly test that some are not forbidden
    IS_TRIVIAL=no
    if [ "$SHELL_REGEX" = yes ]; then
        # Bash-compatible regex support required for code below.
        if ! [[ "$1" =~ [\\\"] ]] >/dev/null && \
            [[ "$1" =~ ^[A-Za-z0-9\ \-\.\+\/\@\:\;\!\%\,\&\(\)\{\}]*$ ]] >/dev/null \
        ; then IS_TRIVIAL=yes; fi
    else
        # Support for other shells if bash-regex syntax
        # is not supported there (e.g. revert to sed/grep/awk)...
        if [ -n "$(echo "$1" | $GEGREP -v '[\\\"]' | $GEGREP '^[A-Za-z0-9\ \-\.\+\/\@\:\;\!\%\,\&\(\)\{\}]*$' )" ] \
        ; then IS_TRIVIAL=yes; fi
    fi

    if [ "$IS_TRIVIAL" = yes ] ; then
        print_debug $DEBUGLEVEL_PRINTTOKEN_PIPELINE "cook_a_string_arg(): input trivial, not cooking: '$1'"
        echo "$1"
        return 0
    fi

    print_debug $DEBUGLEVEL_PRINTTOKEN_PIPELINE "cook_a_string_arg(): input not trivial, cooking: '$1'"
    echo "$1" | cook_a_string
}

tokenize() {
  local GREP_O
  local ESCAPE
  local CHAR

  if echo "test string" | $GEGREP -ao --color=never "test" >/dev/null 2>&1
  then
    GREP_O="$GEGREP -ao --color=never"
  elif echo "test string" | $GEGREP -ao "test" >/dev/null 2>&1
  then
    GREP_O="$GEGREP -ao"
  elif echo "test string" | $GEGREP -o "test" >/dev/null 2>&1
  then
    GREP_O="$GEGREP -o"
  fi

  if [ -n "$GREP_O" ] && echo "test string" | $GREP_O "test" >/dev/null 2>&1
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

  # Force zsh to expand $GREP_O into multiple words
  is_wordsplit_disabled="$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')"
  if [ "$is_wordsplit_disabled" != 0 ]; then setopt shwordsplit; fi
  # Note: we do not fail for empty documents (including whitespace-only) here
  # The pedantic mode handles that if desired by caller
  # We do just in case make sure last line ends with EOL however
  # which in particular fixes cases like `JSON.sh < /dev/null`
  { cat ; echo ""; } | \
  tee_stderr BEFORE_TOKENIZER $DEBUGLEVEL_PRINTTOKEN_PIPELINE | \
  $GREP_O "$STRING|$NUMBER|$KEYWORD|$SPACE|.|^$" | { $GEGREP -v "^$SPACE"'*$' || true ; } | \
  tee_stderr AFTER_TOKENIZER $DEBUGLEVEL_PRINTTOKEN_PIPELINE
  RES=$?
  if [ "$is_wordsplit_disabled" != 0 ]; then unsetopt shwordsplit; fi
  unset is_wordsplit_disabled || true
  return $RES
}

# Collect indentation chars
TABCHAR="`printf '\t'`"
INDENT=''
parse_array() {
  local index=0
  local ary=''
  local aryml=''
  local INDENT_NEXT="${INDENT}${TABCHAR}"
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse_array(1):" "token='$token'"
  case "$token" in
    ']') ;;
    *)
      while :
      do
        INDENT="${INDENT_NEXT}" parse_value "$1" "$index"
        index="$(expr $index + 1)"
        if [ "$PRETTYPRINT" = 1 ]; then
            [ -z "$ary" ] && ary="${INDENT_NEXT}$value" || ary="$ary
${INDENT_NEXT}$value"
            if [ -n "$SORTDATA_ARR" ]; then
                aryml="$ary"
            fi
        else
            ary="$ary""$value"
            if [ -n "$SORTDATA_ARR" ]; then
                [ -z "$aryml" ] && aryml="$value" || aryml="$aryml
$value"
            fi
        fi
        read -r token
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
  if [ -n "$SORTDATA_ARR" ] && [ "$PRETTYPRINT" = 0 ]; then
    # For sorting mode, smart_parse first normalizes and sorts
    # the input data without other optional constraints, then
    # the result is filtered for final output with another pass,
    # where we might indent it below.
    # Force zsh to expand $SORTDATA* into multiple words
    is_wordsplit_disabled="$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')"
    if [ "$is_wordsplit_disabled" != 0 ]; then setopt shwordsplit; fi
    ary="$(printf '%s\n' "$aryml" | $SORTDATA_ARR | tr '\n' ',' | $GSED 's|,*$||' 2>/dev/null | $GSED 's|^,*||' 2>/dev/null)"
    if [ "$is_wordsplit_disabled" != 0 ]; then unsetopt shwordsplit; fi
    unset is_wordsplit_disabled || true
  fi
  [ "$BRIEF" = 0 ] && \
  if [ "$PRETTYPRINT" = 1 ]; then
    # The opening bracket trails a space after preceding object name (being its value)
    if [ "${#ary}" = 0 ]; then
        value="$(printf '[\n%s]\n' "$INDENT")"
    else
        value="$(printf '[\n%s\n%s]\n' "$ary" "$INDENT")"
    fi
  else
    value="$(printf '[%s]' "$ary")"
  fi || value=""
  :
}

parse_object() {
  local key=''
  local obj=''
  local objml=''
  local INDENT_NEXT="${INDENT}${TABCHAR}"
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse_object(1):" "token='$token'"
  case "$token" in
    '}') ;;
    *)
      while :
      do
        case "$token" in
          '"'*'"') key="$token" ;;
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
        INDENT="${INDENT_NEXT}" parse_value "$1" "$key"
        if [ "$PRETTYPRINT" = 1 ]; then
            [ -z "$obj" ] && obj="${INDENT_NEXT}$key : $value" || obj="$obj
${INDENT_NEXT}$key : $value"
            if [ -n "$SORTDATA_OBJ" ]; then
                objml="$obj"
            fi
        else
            obj="$obj$key:$value"
            if [ -n "$SORTDATA_OBJ" ]; then
                [ -z "$objml" ] && objml="$key:$value" || objml="$objml
$key:$value"
            fi
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
  if [ -n "$SORTDATA_OBJ" ] && [ "$PRETTYPRINT" = 0 ]; then
    # For sorting mode, smart_parse first normalizes and sorts
    # the input data without other optional constraints, then
    # the result is filtered for final output with another pass,
    # where we might indent it below.
    # Force zsh to expand $SORTDATA* into multiple words
    is_wordsplit_disabled="$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')"
    if [ "$is_wordsplit_disabled" != 0 ]; then setopt shwordsplit; fi
    obj="$(printf '%s\n' "$objml" | $SORTDATA_OBJ | tr '\n' ',' | $GSED 's|,*$||' 2>/dev/null | $GSED 's|^,*||' 2>/dev/null)"
    if [ "$is_wordsplit_disabled" != 0 ]; then unsetopt shwordsplit; fi
    unset is_wordsplit_disabled || true
  fi
  [ "$BRIEF" = 0 ] && \
  if [ "$PRETTYPRINT" = 1 ]; then
    # The opening brace trails a space after preceding object name (being its value)
    if [ "${#obj}" = 0 ]; then
        value="$(printf '{\n%s}\n' "$INDENT")"
    else
        value="$(printf '{\n%s\n%s}\n' "$obj" "$INDENT")"
    fi
  else
    value="$(printf '{%s}' "$obj")"
  fi || value=""
  :
}

REGEX_NUMBER='^[+-]?([.][0-9]+|(0+|[1-9][0-9]*)([.][0-9]*)?)([eE][+-]?[0-9]*)?$'
QUICK_ABORT=false
parse_value() {
  if $QUICK_ABORT ; then return 0 ; fi
  local jpath="${1:+$1,}$2"
  local isleaf=0
  local isempty=0
  local print=0
  local INDENT_VALUE=""
  case "$token" in
    '{') parse_object "$jpath"
        INDENT_VALUE="${INDENT}"
        if [ "$PRETTYPRINT" = 1 ]; then
            [ "$value" = '{
'"${INDENT}"'}' ] && isempty=1
        else
            [ "$value" = '{}' ] && isempty=1
        fi
        ;;
    '[') parse_array  "$jpath"
        INDENT_VALUE="${INDENT}"
        if [ "$PRETTYPRINT" = 1 ]; then
            [ "$value" = '[
'"${INDENT}"']' ] && isempty=1
        else
            [ "$value" = '[]' ] && isempty=1
        fi
        ;;
    # At this point, the only valid single-character tokens are digits.
    ''|[!0-9]) if [ "$ALLOWEMPTYINPUT" = 1 ] && [ -z "$jpath" ] && [ -z "$token" ]; then
            print_debug $DEBUGLEVEL_PRINTPATHVAL \
                'Got a NULL document as input (no jpath, no token)' >&2
            if [ "$PRETTYPRINT" = 1 ]; then
                value='{
'"${INDENT}"'}'
            else
                value='{}'
            fi
            isempty=1
        else
            throw "EXPECTED value GOT '${token:-EOF}'"
        fi ;;
    +*|-*|[0-9]*|.*)  # Potential number - separate hit in case for efficiency
       print_debug $DEBUGLEVEL_PRINTPATHVAL \
            "token '$token' is a suspected number" >&2
       # TODO: Bash regex and more if's
       DO_NORMALIZE=no
       if [ "$NORMALIZE_NUMBERS" = 1 ] ; then
           if [ "$SHELL_REGEX" = yes ]; then
                [[ "$token" =~ ${REGEX_NUMBER} ]] && DO_NORMALIZE=yes
           else
                [ -n "$(echo "$token" | $GEGREP "${REGEX_NUMBER}" )" ] && DO_NORMALIZE=yes
           fi
       fi

       if [ "$DO_NORMALIZE" = yes ]; then
            value="$(printf "$NORMALIZE_NUMBERS_FORMAT" "$token")" || \
            value="$token"
            print_debug $DEBUGLEVEL_PRINTPATHVAL "normalized numeric token" \
                "'$token' into '$value'" >&2
            if [ "$NORMALIZE_NUMBERS_STRIP" = 1 ]; then
                valuetmp="$(echo "$value" | $GSED -e 's,0*$,,g' -e 's,\.$,,' 2>/dev/null)" && \
                    value="$valuetmp"
                unset valuetmp
                print_debug $DEBUGLEVEL_PRINTPATHVAL "stripped numeric token" \
                    "'$token' into '$value'" >&2
            fi
       else
            # Not a number or no normalization - process like default
            value="$token"
            if [ "$NORMALIZE_SOLIDUS" = 1 ]; then
                case "$SHELL_TWOSLASH" in
                    yes|quoted) value="${value//\\\//\/}" ;;
                    unquoted) value=${value//\\\//\/} ;;
                    *) value="$(echo "$value" | $GSED 's#\\/#/#g')" ;;
                esac
            fi
       fi
       isleaf=1
       { [ "$value" = '""' ] || [ "$value" = '' ] ; } && isempty=1
       ;;
    *) value="$token"
       # if asked, replace solidus ("\/") in json strings with normalized value: "/"
       if [ "$NORMALIZE_SOLIDUS" = 1 ]; then
            case "$SHELL_TWOSLASH" in
                yes|quoted) value="${value//\\\//\/}" ;;
                unquoted) value=${value//\\\//\/} ;;
                *) value="$(echo "$value" | $GSED 's#\\/#/#g')" ;;
            esac
       fi
       isleaf=1
       [ "$value" = '""' ] && isempty=1
       ;;
  esac

  if [ "$NORMALIZE" = 1 ]; then
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
  [ "$NO_HEAD" -eq 1 ] && [ -z "$jpath" ] && return

  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=2
  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=3
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
    [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=4

  ### A special case of an empty array or object - for leaf printing
  ### without pruning, we are interested in these:
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 0 ] && [ "$isempty" -eq 1 ] && \
    [ $PRUNE -eq 0 ] && print=5

  if [ "$print" -ne 0 ] && [ -n "$EXTRACT_JPATH" ] ; then
    if [ "$SHELL_REGEX" = yes ]; then
        ### BASH regex matching:
        [[ "${jpath}" =~ ${EXTRACT_JPATH} ]] || print=-1
    else
        [ -n "$(echo "${jpath}" | $GEGREP "${EXTRACT_JPATH}")" ] || print=-1
    fi
  fi

  print_debug $DEBUGLEVEL_PRINTPATHVAL \
	"JPATH='$jpath' VALUE='$value' B='$BRIEF'" \
	"isleaf='$isleaf'/L='$LEAFONLY' isempty='$isempty'/P='$PRUNE':" \
	"print='$print'" >&2

  if [ "$print" -gt 0 ] ; then
    if [ -n "$SHELLABLE_OUTPUT" ]; then
        case "$value" in
            '"'*'"') pvalue="$(echo "$value" | $GSED -e 's,^",,' -e 's,"$,,')" ;;
            *) pvalue="$value" ;;
        esac
        if [ "$PRETTYPRINT" = 1 ]; then
           pvalue="$(printf '%s%s' "$INDENT_VALUE" "$pvalue")"
        fi
    fi
    case "$SHELLABLE_OUTPUT" in
        string)   printf '%s\n' "$pvalue" ; QUICK_ABORT=true ; return 0 ;;
        strings)  printf '%s\n' "$pvalue" ; return 0 ;;
        arrays)   printf '"%s"\n' "$pvalue" ; return 0 ;;
        *)        printf '[%s]\t%s\n' "$jpath" "$value" ;;
    esac
  fi
  :
}

parse() {
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse(1):" "token='$token'"
  parse_value
  read -r token
  print_debug $DEBUGLEVEL_PRINTTOKEN "parse(2):" "token='$token' QUICK_ABORT=$QUICK_ABORT"
  case "$token" in
    '') return 0 ;;
    *) $QUICK_ABORT || throw "EXPECTED EOF GOT '$token'" ;;
  esac
}

smart_parse() {
  ### Piping obfuscates errors thrown by parse()
  local THIS_PID=""
  if [ "$SHELL_PIPEFAIL" = yes ]; then
    set -o pipefail
  else
    THIS_PID=$$
  fi

  strip_newlines | \
  tokenize | if [ -n "$SORTDATA_OBJ$SORTDATA_ARR" ] ; then
      ### Any type of sort was enabled
      ( ( NORMALIZE=1 LEAFONLY=0 BRIEF=0 PRETTYPRINT=0 parse ) || { RET=$? ; if [ -n "$THIS_PID" ] ; then kill -15 $THIS_PID ; exit $RET; fi; } ) \
      | tokenize | parse
    else
      parse
    fi
}

JSONSH_DEBUGGING_SETUP=notdone
JSONSH_DEBUGGING_REPORT=notdone
JSONSH_DEBUGGING_DEFAULTS=notdone
jsonsh_debugging_defaults() {
    [ x"$JSONSH_DEBUGGING_DEFAULTS" = xdone ] && return 0
    ### Caller can disable specific debuggers by setting their level too high
    validate_debuglevel
    default_posval DEBUGLEVEL_PRINTPATHVAL		1
    default_posval DEBUGLEVEL_PRINTTOKEN		2
    default_posval DEBUGLEVEL_PRINTTOKEN_PIPELINE	3
    default_posval DEBUGLEVEL_TRACE_X		4
    default_posval DEBUGLEVEL_TRACE_V		5
    default_posval DEBUGLEVEL_MERGE_ERROUT		4
    JSONSH_DEBUGGING_DEFAULTS="done"
}

jsonsh_debugging_setup() {
    [ x"$JSONSH_DEBUGGING_SETUP" = xdone ] && return 0
    # Note that the CLI options enable some debug level

    [ "$DEBUG" -ge "$DEBUGLEVEL_MERGE_ERROUT" ] && \
        exec 2>&1
    [ "$DEBUG" -ge "$DEBUGLEVEL_TRACE_V" ] && \
        set +v
    [ "$DEBUG" -ge "$DEBUGLEVEL_TRACE_X" ] && \
        set -x

    JSONSH_DEBUGGING_SETUP="done"
}

jsonsh_debugging_report() {
    [ x"$JSONSH_DEBUGGING_REPORT" = xdone ] && return 0
    # Note that the CLI options enable some debug level

    [ "$DEBUG" -ge "$DEBUGLEVEL_MERGE_ERROUT" ] && \
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
        "(DEBUGLEVEL_TRACE_V=$DEBUGLEVEL_TRACE_V)" >&2
    [ "$DEBUG" -ge "$DEBUGLEVEL_TRACE_X" ] && \
        echo "[$$]DEBUG: Enable execution tracing (-x)" \
        "(DEBUGLEVEL_TRACE_X=$DEBUGLEVEL_TRACE_X)" >&2

    JSONSH_DEBUGGING_REPORT="done"
}

jsonsh_cli() {
  # All the logic needed to parse the CLI options and the JSON stdin
  # for a common case "cat file.json | tokenize | parse" can suffice
  # NOTE: If the caller sets up some specific different debugging envvars
  # then consider changing JSONSH_DEBUGGING_SETUP and JSONSH_DEBUGGING_REPORT
  # to e.g. "notdone" as well
  parse_options "$@"
  jsonsh_debugging_setup
  jsonsh_debugging_report
  if [ "$COOKASTRING" -eq 2 ]; then
    if [ "$DEBUG" -ge "$DEBUGLEVEL_PRINTTOKEN" ] || \
       [ "$DEBUG" -ge "$DEBUGLEVEL_PRINTTOKEN_PIPELINE" ] ; then
        echo "[$$]DEBUG: Cooking an argument into JSON string and exiting:" "$1" >&2
    fi
    cook_a_string_arg "$COOKASTRING_INPUT"
  else
    tee_stderr RAW_INPUT $DEBUGLEVEL_PRINTTOKEN_PIPELINE | \
    case "$COOKASTRING" in
      1) cook_a_string ;;
      *) smart_parse ;;
    esac
  fi
}

jsonsh_cli_subshell() (
  # Same as above, but isolated in a subshell (no variables come back)
  jsonsh_cli "$@"
  exit $?
)


###########################################################
### Active logic
jsonsh_debugging_defaults

# If NOT sourced into a bash script, parse stdin and quit
#[ "${JSONSH_SOURCED-}" != yes ] || \
#if  [ "$0" = "$BASH_SOURCE[0]" ] || [ "$0" = "$BASH_SOURCE" ] || [ -z "${BASH-}" ] || [ -z "$BASH_SOURCE" ]; \
if [ "${JSONSH_SOURCED-}" != yes ]
then
  jsonsh_cli "$@"
  exit $?
fi

#if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
#then
#  parse_options "$@"
#  tokenize | parse
#fi

# vi: expandtab sw=2 ts=2
