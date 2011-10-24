
throw () {
  echo $* >&2
  exit 1
}

tokenize () {
  egrep -ao '[]|[{}]|:|,|("((\\")|[^"])*")|:|(\-?[0-9]*\.?([0-9]*)?(e?\-?([0-9]*))?)|null|true|false' --color=never
}

parse_array () {
  local index=0
  local ary=''
  read token
  while true;
  do
    key=$index
    case "$token" in
      ']') break ;;
      *)
        parse_value "$1" "$index"
        let index=$index+1
        ary="$ary""$value" 
        read token
        case "$token" in
          ']') break ;;
          ',') ary="$ary", ;;
          *)
            if [ "_$token" = _ ]; then token=EOF; fi
            throw "EXPECTED ] or , GOT $token" 
          ;;
        esac
        read token
      ;;
    esac
  done
  value=`printf '[%s]' $ary`
}

parse_object () {
  local go=true
  local obj=''
  local EXPECT_COMMA=0
  local EXPECT_COLON=0
  read token
  while [ "$go" = true ];
  do
    case "$token" in
      '}') break ;;
      *)

        key=$token
        read colon
        if [ "$colon" != ':' ]; then throw "EXPECTED COLON, GOT $colon"; fi
        if [ "_$key" = _ ];     then throw "NULL KEY"; fi
        read token
        parse_value "$1" "$key"
        obj="$obj$key:$value"        

        read token
        case "$token" in
          '}') break;;
          ,)   obj="$obj,"; read token ;;
          *) 
            if [ "_$token" = _ ]; then token=EOF; fi
            throw "EXPECTED , or }, but got $token"
            ;;
        esac
        ;;
    esac
  done
  value=`printf '{%s}' "$obj"`
}

parse_value () {
  local jpath
  
  if [ "x$1" = "x" ]; then jpath="$2"; else jpath="$1,$2"; fi

  case "$token" in
    {) parse_object "$jpath" ;;
    [) parse_array  "$jpath" ;;
    ','|'}'|']') throw "EXPECTED value, GOT $token" ;;
    *) value=$token
    ;;
  esac
  printf "[%s]\t%s\n" "$jpath" "$value"
}

parse () {
  read token
  parse_value
}
