if isatty && [ ! -z "$(which isatty)" ];then
    TXT_BLD=$(tput bold)
    TXT_RED=$(tput setaf 1)
    TXT_GREEN=$(tput setaf 2)
    TXT_YLW=$(tput setaf 3)
    TXT_BLUE=$(tput setaf 4)
    TXT_PURPLE=$(tput setaf 5)
    TXT_CYAN=$(tput setaf 6)
    TXT_WHITE=$(tput setaf 7)
    TXT_RESET=$(tput sgr0)
else
    TXT_BLD=
    TXT_RED=
    TXT_GREEN=
    TXT_YLW=
    TXT_BLUE=
    TXT_PURPLE=
    TXT_CYAN=
    TXT_WHITE=
    TXT_RESET=
fi

throw () {
  echo "$*" >&2
  exit 1
}

tokenize () {
  local ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
  local CHAR='[^[:cntrl:]"\\]'
  local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
  local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'
  egrep -ao "$STRING|$NUMBER|$KEYWORD|$SPACE|." --color=never |
    egrep -v "^$SPACE$"  # eat whitespace
}

parse_array () {
  local index=0
  local ary=''
  read -r token
  case "$token" in
    ']') ;;
    *)
      while :
      do
        parse_value "$1" "$index"
        let index=$index+1
        ary="$ary""$value"
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
  value=`printf '[%s]' $ary`
}

parse_object () {
  local key
  local obj=''
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
        obj="$obj$TXT_BLUE$key$TXT_RESET:$TXT_RED$value$TXT_RESET"
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
  value=`printf '{%s}' "$obj"`
}

parse_value () {
  local jpath="${1:+$1,}$2"
  case "$token" in
    '{') parse_object "$jpath" ;;
    '[') parse_array  "$jpath" ;;
    # At this point, the only valid single-character tokens are digits.
    ''|[^0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
    *) value=$token ;;
  esac
  printf "[%s]\t%s\n" "$TXT_GREEN$jpath$TXT_RESET" "$TXT_PURPLE$value$TXT_RESET"
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

if [ $0 = $BASH_SOURCE ];
then
  tokenize | parse
fi
