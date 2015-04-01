# JSON.sh

Yo, so it's a JSON parser written in bash!

Pipe JSON to it, and it traverses the json objects and prints out the 
path to the current object (as a JSON array) and then the object,
without whitespace between syntactic constructs (whitespace inside
content strings is preserved).

Further features include the ability to "extract" the JSON paths which
match a specified regex, ability to sort the content (array and object
items), and ability to "cook" raw text into escaped strings acceptable
for passing in JSON markup. Finally, there is a mode to "normalize" an
input JSON markup into a single-line no-extra-whitespace string, with
optional sorting applied, so that the script can be used as a filter to
normalize two JSON documents so they can be compared for differences.

A simple example follows here, and more complex ones are presented
after the break for command-line options:

``` bash
$ ./JSON.sh < package.json
["name"]  "JSON.sh"
["version"]  "0.0.0"
["description"]  ""
["homepage"]  "http://github.com/dominictarr/JSON.sh"
["repository","type"]  "git"
["repository","url"]  "https://github.com/dominictarr/JSON.sh.git"
["repository"]  {"type":"git","url":"https://github.com/dominictarr/JSON.sh.git"}
["bin","json_parse"]  "./JSON.sh"
["bin"]  {"json_parse":"./JSON.sh"}
["dependencies"]  {}
#  ... etc
```

* Pruning of empty arrays/structs (from line-by-line output) is supported
as well as for strings-only before:
```bash
:; ELINE='{"emptyarr":[],"emptyobj":{},"emptystr":""}'

# Here you see them...
:; echo -E "$ELINE" | ./JSON.sh
["emptyarr"]    []
["emptyobj"]    {}
["emptystr"]    ""
[]      {"emptyarr":[],"emptyobj":{},"emptystr":""}

# Here you don't ;)
:; echo -E "$ELINE" | ./JSON.sh -p
[]      {"emptyarr":[],"emptyobj":{},"emptystr":""}
```


a more complex example:

``` bash
curl registry.npmjs.org/express | ./JSON.sh | egrep '\["versions","[^"]*"\]'
... try it and see
```

## Options

### Usual queries, full or filtered
``` bash
Usage: JSON.sh [-b] [-l] [-p] [-x 'regex'] [-S|-S='args'] [--no-newline] [-d]
```

* `-b`
> Brief output. Combines 'Leaf only' and 'Prune empty' options.

* `-l`
> Leaf only. Only show leaf nodes, which stops data duplication.

* `-p`
> Prune empty. Exclude fields with empty values (strings, arrays, objects).

* `-s`
> Remove escaping of the solidus symbol (stright slash).

* `-x 'regex'` or `-x='regex'`
> "Extract" - rather than showing all document from the root element,
extract the items rooted at path(s) matching the regex (see the
comma-separated list of nested hierarchy names in general output,
brackets not included) e.g. `-x='^"level1obj","level2arr",0'`

Sorting is also available, although limited to single-line strings in
the markup (multilines are automatically escaped into backslash+n):

* `-S`
> Sort the contents of items in JSON markup and leaf-list markup:
`sort` objects by key names and then values, and arrays by values

* `-S='args'`
> Use `sort $args` for content sorting, e.g. use `-S='-n -r'` for
reverse numeric sort

* `-So='args'` and/or `-Sa='args'`, or `-So` or `-Sa`
> Only enable `sort` and set the arguments for either objects (`-So`)
or arrays/tuples (`-Sa`). This way sorting of tuples can be avoided
to keep data in valid order (as defined by the programmatic users of
the markup) and/or different rules can be used for arrays vs. objects.
Essentially, the singular `-S{='args'}` option just enables both the
`-Sa` and `-So` options with the same values.

Other options:

* `--no-newline`
> rather than concatenating detected line breaks in markup, return
with error when this is seen in input

* `-d [-d...]` or `-d=NUM`
> Enable debugging traces to `stderr` (repeat or use `-d=NUM` to bump,
see the script source for details on what can be debugged and how to
select what you want)


### Normalization (with optional sorting)
``` bash
Usage: JSON.sh [-N|-N='args'] [-d] < markup.json
```

An input JSON markup can be normalized into single-line no-whitespace:
* `-N`
> Normalize the input JSON markup into a single-line JSON output;
in this mode syntax and spacing are normalized, data order remains

* `-N='args'`
> Normalize the input JSON markup into a single-line JSON output with
contents sorted like for `-S='args'`, e.g. use `-N='-n'`.
This is equivalent to `-N -S='args'`, just more compact to write.

* `-No='args'` and/or `-Na='args'`
> Normalize with sorting like above, but only enable and set the `sort`
arguments for either objects (`-No`) or arrays/tuples (`-Na`). This way
sorting of tuples can be avoided to keep data in valid order (as defined
by the programmatic users of the markup).

### Cook raw data
``` bash
Usage: COOKEDSTRING="`somecommand 2>&1 | ./JSON.sh -Q`"
```

Cooking:
* `-Q`
> To help JSON-related scripting, a block of input plaintext can be
"cooked" into a string valid for JSON (backslashes, quotes and newlines
escaped, with no trailing newline); after cooking, the script exits.
This mode can also be used to pack JSON into JSON.

### Ask for help
``` bash
Usage: JSON.sh [-h]
```

Helping:
* `-h`
> Show help text.

## Complex usage examples

A picture shows more than a thousand words, heh?
So here is a few thousand words for you, to display the new features ;)

* First, define a complicated value contrived just for show-off. This example
can be found in the source checkout as `tests/valid/documented_example.json`.
It may be arguable that newlines in the markup are invalid... but for some
practical example, if the actual data is generated by some shell-script
(storing a copy of a multiline file or command output, etc.) - then the new
features in `JSON.sh` precisely allow to turn that into (more) valid markup ;)
```bash
:; LINE='{"var1":"val1","split
key":"value","var0":"escaped \" quote","splitValue":"there
  are a newline and three spaces (one after \"there\" and two before \"are\")",
"array":["z","a","b",3,20,0,"","","\""
,"escaping\"several\"\"
quote\"s and
newlines"],"aNumber":1,"var8":"string\nwith\nproper\\\nnewlines",
"var38":"","emptyarr":[],"emptyobj":{},
"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},
  {"var":"val2","str":"z"},{"var":"val2","str":"x"},
  {"var":"val1","str":"S"},{"var":"val1","str":"\""},
{"var":"val1","str":5},{"var":"val1","str":"5"}]}'

### Examples related to sorting will also need this to be reproducible:
:; LANG=C; LC_ALL=C; export LANG; export LC_ALL
```

* Note also the use of `echo -E` to avoid shell's processing of escaped
characters (such as `\\\n` in `var8`):
```bash
:; echo -E "$LINE"
{"var1":"val1","split
key":"value","var0":"escaped \" quote","splitValue":"there
  are a newline and three spaces (one after \"there\" and two before \"are\")",
"array":["z","a","b",3,20,0,"","","\""
,"escaping\"several\"\"
quote\"s and
newlines"],"aNumber":1,"var8":"string\nwith\nproper\\\nnewlines",
"var38":"","emptyarr":[],"emptyobj":{},
"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},
  {"var":"val2","str":"z"},{"var":"val2","str":"x"},
  {"var":"val1","str":"S"},{"var":"val1","str":"\""},
{"var":"val1","str":5},{"var":"val1","str":"5"}]}
```

* There is a mode to detect invalid input (due to newlines in strings):
```bash
:; echo "$LINE" | ./JSON.sh --no-newline
Invalid JSON markup detected: newline in a string value: at line #1
EXPECTED value GOT EOF
```

* Otherwise automatic conversion of these takes place:
```bash
:; echo -E "$LINE" | ./JSON.sh
["var1"]        "val1"
["split\nkey"]  "value"
["var0"]        "escaped \" quote"
["splitValue"]  "there\n  are a newline and three spaces (one after \"there\" and two before \"are\")"
["array",0]     "z"
["array",1]     "a"
["array",2]     "b"
["array",3]     3
["array",4]     20
["array",5]     0
["array",6]     ""
["array",7]     ""
["array",8]     "\""
["array",9]     "escaping\"several\"\"\nquote\"s and\nnewlines"
["array"]       ["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"]
["aNumber"]     1
["var8"]        "string\nwith\nproper\\\nnewlines"
["var38"]       ""
["emptyarr"]    []
["emptyobj"]    {}
["arrOfObjs",0,"var"]   "val1"
["arrOfObjs",0,"str"]   "s"
["arrOfObjs",0] {"var":"val1","str":"s"}
["arrOfObjs",1,"var"]   "val30"
["arrOfObjs",1,"str"]   "s"
["arrOfObjs",1] {"var":"val30","str":"s"}
["arrOfObjs",2,"var"]   "val2"
["arrOfObjs",2,"str"]   "z"
["arrOfObjs",2] {"var":"val2","str":"z"}
["arrOfObjs",3,"var"]   "val2"
["arrOfObjs",3,"str"]   "x"
["arrOfObjs",3] {"var":"val2","str":"x"}
["arrOfObjs",4,"var"]   "val1"
["arrOfObjs",4,"str"]   "S"
["arrOfObjs",4] {"var":"val1","str":"S"}
["arrOfObjs",5,"var"]   "val1"
["arrOfObjs",5,"str"]   "\""
["arrOfObjs",5] {"var":"val1","str":"\""}
["arrOfObjs",6,"var"]   "val1"
["arrOfObjs",6,"str"]   5
["arrOfObjs",6] {"var":"val1","str":5}
["arrOfObjs",7,"var"]   "val1"
["arrOfObjs",7,"str"]   "5"
["arrOfObjs",7] {"var":"val1","str":"5"}
["arrOfObjs"]   [{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}]
[]      {"var1":"val1","split\nkey":"value","var0":"escaped \" quote","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","array":["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"],"aNumber":1,"var8":"string\nwith\nproper\\\nnewlines","var38":"","emptyarr":[],"emptyobj":{},"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}]}
```

* Returning a valid JSON markup string without the JSON path (i.e. use of
`JSON.sh` as a filter to convert scripted output into more valid JSON:
```bash
:; echo -E "$LINE" | ./JSON.sh -N
{"var1":"val1","split\nkey":"value","var0":"escaped \" quote","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","array":["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"],"aNumber":1,"var8":"string\nwith\nproper\\\nnewlines","var38":"","emptyarr":[],"emptyobj":{},"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}]}
```

* Sorted output with defaults taken by `sort` program in your OS, i.e.
alphabetic order (where `3` is greater than `20`), etc. and according to
currently exported locale/collation (influencing order of numbers over
punctuation over letters, sorting of letters with diacritics, etc.):
```bash
:; $ echo -E "$LINE" | ./JSON.sh -S
["aNumber"]     1
["arrOfObjs",0,"str"]   "5"
["arrOfObjs",0,"var"]   "val1"
["arrOfObjs",0] {"str":"5","var":"val1"}
["arrOfObjs",1,"str"]   "S"
["arrOfObjs",1,"var"]   "val1"
["arrOfObjs",1] {"str":"S","var":"val1"}
["arrOfObjs",2,"str"]   "\""
["arrOfObjs",2,"var"]   "val1"
["arrOfObjs",2] {"str":"\"","var":"val1"}
["arrOfObjs",3,"str"]   "s"
["arrOfObjs",3,"var"]   "val1"
["arrOfObjs",3] {"str":"s","var":"val1"}
["arrOfObjs",4,"str"]   "s"
["arrOfObjs",4,"var"]   "val30"
["arrOfObjs",4] {"str":"s","var":"val30"}
["arrOfObjs",5,"str"]   "x"
["arrOfObjs",5,"var"]   "val2"
["arrOfObjs",5] {"str":"x","var":"val2"}
["arrOfObjs",6,"str"]   "z"
["arrOfObjs",6,"var"]   "val2"
["arrOfObjs",6] {"str":"z","var":"val2"}
["arrOfObjs",7,"str"]   5
["arrOfObjs",7,"var"]   "val1"
["arrOfObjs",7] {"str":5,"var":"val1"}
["arrOfObjs"]   [{"str":"5","var":"val1"},{"str":"S","var":"val1"},{"str":"\"","var":"val1"},{"str":"s","var":"val1"},{"str":"s","var":"val30"},{"str":"x","var":"val2"},{"str":"z","var":"val2"},{"str":5,"var":"val1"}]
["array",0]     ""
["array",1]     ""
["array",2]     "\""
["array",3]     "a"
["array",4]     "b"
["array",5]     "escaping\"several\"\"\nquote\"s and\nnewlines"
["array",6]     "z"
["array",7]     0
["array",8]     20
["array",9]     3
["array"]       ["","","\"","a","b","escaping\"several\"\"\nquote\"s and\nnewlines","z",0,20,3]
["emptyarr"]    []
["emptyobj"]    {}
["splitValue"]  "there\n  are a newline and three spaces (one after \"there\" and two before \"are\")"
["split\nkey"]  "value"
["var0"]        "escaped \" quote"
["var1"]        "val1"
["var38"]       ""
["var8"]        "string\nwith\nproper\\\nnewlines"
[]      {"aNumber":1,"arrOfObjs":[{"str":"5","var":"val1"},{"str":"S","var":"val1"},{"str":"\"","var":"val1"},{"str":"s","var":"val1"},{"str":"s","var":"val30"},{"str":"x","var":"val2"},{"str":"z","var":"val2"},{"str":5,"var":"val1"}],"array":["","","\"","a","b","escaping\"several\"\"\nquote\"s and\nnewlines","z",0,20,3],"emptyarr":[],"emptyobj":{},"splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","split\nkey":"value","var0":"escaped \" quote","var1":"val1","var38":"","var8":"string\nwith\nproper\\\nnewlines"}
```

* Sorting with parameters, several can be passed as a single quoted string -
for example we request numeric (`20` is greater than `3` - though only for
standalone number tokens) and reversed (`a` is after `z`) sorting:
```bash
:; echo -E "$LINE" | ./JSON.sh -S='-r -n'
["var8"]        "string\nwith\nproper\\\nnewlines"
["var38"]       ""
["var1"]        "val1"
["var0"]        "escaped \" quote"
["split\nkey"]  "value"
["splitValue"]  "there\n  are a newline and three spaces (one after \"there\" and two before \"are\")"
["emptyobj"]    {}
["emptyarr"]    []
["array",0]     20
["array",1]     3
["array",2]     0
["array",3]     "z"
["array",4]     "escaping\"several\"\"\nquote\"s and\nnewlines"
["array",5]     "b"
["array",6]     "a"
["array",7]     "\""
["array",8]     ""
["array",9]     ""
["array"]       [20,3,0,"z","escaping\"several\"\"\nquote\"s and\nnewlines","b","a","\"","",""]
["arrOfObjs",0,"var"]   "val30"
["arrOfObjs",0,"str"]   "s"
["arrOfObjs",0] {"var":"val30","str":"s"}
["arrOfObjs",1,"var"]   "val2"
["arrOfObjs",1,"str"]   "z"
["arrOfObjs",1] {"var":"val2","str":"z"}
["arrOfObjs",2,"var"]   "val2"
["arrOfObjs",2,"str"]   "x"
["arrOfObjs",2] {"var":"val2","str":"x"}
["arrOfObjs",3,"var"]   "val1"
["arrOfObjs",3,"str"]   5
["arrOfObjs",3] {"var":"val1","str":5}
["arrOfObjs",4,"var"]   "val1"
["arrOfObjs",4,"str"]   "s"
["arrOfObjs",4] {"var":"val1","str":"s"}
["arrOfObjs",5,"var"]   "val1"
["arrOfObjs",5,"str"]   "\""
["arrOfObjs",5] {"var":"val1","str":"\""}
["arrOfObjs",6,"var"]   "val1"
["arrOfObjs",6,"str"]   "S"
["arrOfObjs",6] {"var":"val1","str":"S"}
["arrOfObjs",7,"var"]   "val1"
["arrOfObjs",7,"str"]   "5"
["arrOfObjs",7] {"var":"val1","str":"5"}
["arrOfObjs"]   [{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":5},{"var":"val1","str":"s"},{"var":"val1","str":"\""},{"var":"val1","str":"S"},{"var":"val1","str":"5"}]
["aNumber"]     1
[]      {"var8":"string\nwith\nproper\\\nnewlines","var38":"","var1":"val1","var0":"escaped \" quote","split\nkey":"value","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","emptyobj":{},"emptyarr":[],"array":[20,3,0,"z","escaping\"several\"\"\nquote\"s and\nnewlines","b","a","\"","",""],"arrOfObjs":[{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":5},{"var":"val1","str":"s"},{"var":"val1","str":"\""},{"var":"val1","str":"S"},{"var":"val1","str":"5"}],"aNumber":1}
```

* Normalized output can also be sorted, upon request - although *NOTE* that if
your document schema has arrays whose order of items has syntactic meaning for
your application (aka "tuples"), such ordering will likely make the document
invalid for your application's use-case - and in such case you might want to
use `-No{='args'}` to only sort objects; this warning *should* be irrelevant
for objects (the `{"key":value}` pairs) though:
```bash
:; echo -E "$LINE" | ./JSON.sh -N='-n'
{"aNumber":1,"arrOfObjs":[{"str":"5","var":"val1"},{"str":"S","var":"val1"},{"str":"\"","var":"val1"},{"str":"s","var":"val1"},{"str":"s","var":"val30"},{"str":"x","var":"val2"},{"str":"z","var":"val2"},{"str":5,"var":"val1"}],"array":["","","\"","a","b","escaping\"several\"\"\nquote\"s and\nnewlines","z",0,3,20],"emptyarr":[],"emptyobj":{},"splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","split\nkey":"value","var0":"escaped \" quote","var1":"val1","var38":"","var8":"string\nwith\nproper\\\nnewlines"}

:; echo -E "$LINE" | ./JSON.sh -N=-r
{"var8":"string\nwith\nproper\\\nnewlines","var38":"","var1":"val1","var0":"escaped \" quote","split\nkey":"value","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","emptyobj":{},"emptyarr":[],"array":[3,20,0,"z","escaping\"several\"\"\nquote\"s and\nnewlines","b","a","\"","",""],"arrOfObjs":[{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":5},{"var":"val1","str":"s"},{"var":"val1","str":"\""},{"var":"val1","str":"S"},{"var":"val1","str":"5"}],"aNumber":1}

:; echo -E "$LINE" | ./JSON.sh -N="-r -n"
{"var8":"string\nwith\nproper\\\nnewlines","var38":"","var1":"val1","var0":"escaped \" quote","split\nkey":"value","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","emptyobj":{},"emptyarr":[],"array":[20,3,0,"z","escaping\"several\"\"\nquote\"s and\nnewlines","b","a","\"","",""],"arrOfObjs":[{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":5},{"var":"val1","str":"s"},{"var":"val1","str":"\""},{"var":"val1","str":"S"},{"var":"val1","str":"5"}],"aNumber":1}

### Normalize sorting only objects (arrays/tuples remain in original order):
:; echo -E "$LINE" | ./JSON.sh -No='-r -n'
{"var8":"string\nwith\nproper\\\nnewlines","var38":"","var1":"val1","var0":"escaped \" quote","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","split\nkey":"value","emptystr":"","emptyobj":{},"emptyarr":[],"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}],"array":["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"],"aNumber":1}

:; echo -E "$LINE" | ./JSON.sh -No='-n'
{"aNumber":1,"array":["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"],"arrOfObjs":[{"str":"s","var":"val1"},{"str":"s","var":"val30"},{"str":"z","var":"val2"},{"str":"x","var":"val2"},{"str":"S","var":"val1"},{"str":"\"","var":"val1"},{"str":5,"var":"val1"},{"str":"5","var":"val1"}],"emptyarr":[],"emptyobj":{},"emptystr":"","split\nkey":"value","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","var0":"escaped \" quote","var1":"val1","var38":"","var8":"string\nwith\nproper\\\nnewlines"}
```

* And note that the normalized output returns (maybe sorted) JSON markup of
the top-level item without whitespaces between syntactic elements, and other
`JSON.sh` modifiers are essentially ignored (`-x` option is detailed below):
```bash
:; echo -E "$LINE" | ./JSON.sh -x 'empty' -N
{"var1":"val1","split\nkey":"value","var0":"escaped \" quote","splitValue":"there\n  are a newline and three spaces (one after \"there\" and two before \"are\")","array":["z","a","b",3,20,0,"","","\"","escaping\"several\"\"\nquote\"s and\nnewlines"],"aNumber":1,"var8":"string\nwith\nproper\\\nnewlines","var38":"","emptyarr":[],"emptyobj":{},"arrOfObjs":[{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}]}

### Normalization mode can still be used for validation of input markup though:
:; echo -E "$LINE" | ./JSON.sh --no-newline -N
Invalid JSON markup detected: newline in a string value: at line #1
EXPECTED value GOT EOF
```

* As developers of the script itself, we can debug why something is or is not
printed and thanks to which logical block (interesting excerpts copypasted);
several keys have been defined to pring different debug values if the debug
level is big enough, and can be easily redefined by `export` from the caller
(see `JSON.sh` source):
```bash
:; echo -E "$LINE" | ./JSON.sh -p -l -d
# Leaf value printed
=== KEY='"var1"' VALUE='"val1"' B='1' isleaf='1'/L='1' isempty='0'/P='1': print='4'
["var1"]        "val1"
# Empty value pruned from line-by-line output (not from JSON markup, not from index numbering):
=== KEY='"array",6' VALUE='""' B='1' isleaf='1'/L='1' isempty='1'/P='1': print='0'
=== KEY='"array",7' VALUE='""' B='1' isleaf='1'/L='1' isempty='1'/P='1': print='0'
=== KEY='"var38"' VALUE='""' B='1' isleaf='1'/L='1' isempty='1'/P='1': print='0'
# Empty arrays and objects are NOW also pruned on request (this is different from brief mode which just does not output objects/arrays at all):
=== KEY='"emptyarr"' VALUE='[]' B='0' isleaf='0'/L='1' isempty='1'/P='1': print='0'
=== KEY='"emptyobj"' VALUE='{}' B='0' isleaf='0'/L='1' isempty='1'/P='1': print='0'
# Non-leaf items skipped from line-by-line printing:
=== KEY='"arrOfObjs",7' VALUE='{"var":"val1","str":"5"}' B='0' isleaf='0'/L='1' isempty='0'/P='1': print='0'
=== KEY='"arrOfObjs"' VALUE='[{"var":"val1","str":"s"},{"var":"val30","str":"s"},{"var":"val2","str":"z"},{"var":"val2","str":"x"},{"var":"val1","str":"S"},{"var":"val1","str":"\""},{"var":"val1","str":5},{"var":"val1","str":"5"}]' B='0' isleaf='0'/L='1' isempty='0'/P='1': print='0'
=== KEY='' VALUE='...' B='0' isleaf='0'/L='1' isempty='0'/P='1': print='0'
```

* Last but not least, we now have an "extractor" to simplify scripted requests
to particular entries by their jpaths, which helps scripted interaction with
the JSON markup:
```bash
:; echo -E "$LINE" | ./JSON.sh -x 'empty'
["emptyarr"]    []
["emptyobj"]    {}

:; echo -E "$LINE" | ./JSON.sh -x 'var'
["var1"]        "val1"
["var0"]        "escaped \" quote"
["var8"]        "string\nwith\nproper\\\nnewlines"
["var38"]       ""
["arrOfObjs",0,"var"]   "val1"
["arrOfObjs",1,"var"]   "val30"
["arrOfObjs",2,"var"]   "val2"
["arrOfObjs",3,"var"]   "val2"
["arrOfObjs",4,"var"]   "val1"
["arrOfObjs",5,"var"]   "val1"
["arrOfObjs",6,"var"]   "val1"
["arrOfObjs",7,"var"]   "val1"

# Regex can be used:
:; echo -E "$LINE" | ./JSON.sh -x '^\"var'
["var1"]        "val1"
["var0"]        "escaped \" quote"
["var8"]        "string\nwith\nproper\\\nnewlines"
["var38"]       ""

:; echo -E "$LINE" | ./JSON.sh -x 'var\"$'
["arrOfObjs",0,"var"]   "val1"
["arrOfObjs",1,"var"]   "val30"
["arrOfObjs",2,"var"]   "val2"
["arrOfObjs",3,"var"]   "val2"
["arrOfObjs",4,"var"]   "val1"
["arrOfObjs",5,"var"]   "val1"
["arrOfObjs",6,"var"]   "val1"
["arrOfObjs",7,"var"]   "val1"

# You can also pick array elements...
:; echo -E "$LINE" | ./JSON.sh -x 'arrOfObjs\",[0-9]*$'
["arrOfObjs",0] {"var":"val1","str":"s"}
["arrOfObjs",1] {"var":"val30","str":"s"}
["arrOfObjs",2] {"var":"val2","str":"z"}
["arrOfObjs",3] {"var":"val2","str":"x"}
["arrOfObjs",4] {"var":"val1","str":"S"}
["arrOfObjs",5] {"var":"val1","str":"\""}
["arrOfObjs",6] {"var":"val1","str":5}
["arrOfObjs",7] {"var":"val1","str":"5"}

#... unless of course you use leaf-only mode:
:; echo -E "$LINE" | ./JSON.sh -x 'arrOfObjs\",[0-9]*$' -l

#...or you can pick just the contents of the arrays:
:; echo -E "$LINE" | ./JSON.sh -x 'arrOfObjs\",[0-9]+,.+$'
["arrOfObjs",0,"var"]   "val1"
["arrOfObjs",0,"str"]   "s"
["arrOfObjs",1,"var"]   "val30"
["arrOfObjs",1,"str"]   "s"
["arrOfObjs",2,"var"]   "val2"
["arrOfObjs",2,"str"]   "z"
["arrOfObjs",3,"var"]   "val2"
["arrOfObjs",3,"str"]   "x"
["arrOfObjs",4,"var"]   "val1"
["arrOfObjs",4,"str"]   "S"
["arrOfObjs",5,"var"]   "val1"
["arrOfObjs",5,"str"]   "\""
["arrOfObjs",6,"var"]   "val1"
["arrOfObjs",6,"str"]   5
["arrOfObjs",7,"var"]   "val1"
["arrOfObjs",7,"str"]   "5"

#...or perhaps just the items in these arrays starting with an "s":
:; echo -E "$LINE" | ./JSON.sh -x 'arrOfObjs\",[0-9]+,\"s.+$'
["arrOfObjs",0,"str"]   "s"
["arrOfObjs",1,"str"]   "s"
["arrOfObjs",2,"str"]   "z"
["arrOfObjs",3,"str"]   "x"
["arrOfObjs",4,"str"]   "S"
["arrOfObjs",5,"str"]   "\""
["arrOfObjs",6,"str"]   5
["arrOfObjs",7,"str"]   "5"

# Note that only jpaths (not contents themselves) are matched:
:; echo -E "$LINE" | ./JSON.sh -x '\n' -l
["split\nkey"]  "value"
```

* Another new feature to help scripting is "cooking" of input strings into
escaped JSON that should be valid markup (with no trailing newline as well);
this currently allows to escape newlines, backslashes and TAB characters which
otherwise made the `JSON.sh` parser sad:
```bash
:; RAWLINE='[ This is text
It has
Several "lines"
maybe \n escaped \"
}'

:; ESCAPED="`echo -E "$RAWLINE" | ./JSON.sh -Q`"; echo -E "'$ESCAPED'"
'[ This is text\nIt has\nSeveral \"lines\"\nmaybe \\n escaped \\\"\n}'
```

For a more practical example, let's turn some text-file dumps into
JSON markup with escaped newlines:

```bash
:; ( echo '['; for F in /etc/motd /etc/release ; do \
     printf '{"filename":"'"$F"'","contents":"%s"},\n' \
       "`cat "$F"`"; done; echo '{}]' ) | ./JSON.sh -N
[{"filename":"/etc/motd","contents":"The Illumos Project        SunOS 5.11      illumos-ad69a33 January 2015"},{"filename":"/etc/release","contents":"             OpenIndiana Development oi_151.1.8 X86 (powered by illumos)\n        Copyright 2011 Oracle and/or its affiliates. All rights reserved.\n                        Use is subject to license terms.\n                           Assembled 19 February 2013"},{}]
```

Escaping for TAB characters in string contents during "cooking", as well as
toleration during processing, can be seen in `/etc/motd` of this example both
above and below:
```
:; cat /etc/motd | ./JSON.sh -Q ; echo ""
The Illumos Project\tSunOS 5.11\tillumos-ad69a33\tJanuary 2015
```

## Cool Links

* [step-/JSON.awk](https://github.com/step-/JSON.awk) JSON.sh ported to awk
* [kristopolous/TickTick](https://github.com/kristopolous/TickTick) Object Oriented BASH
* [archan937/jsonv.sh](https://github.com/archan937/jsonv.sh)

## Installation

install via npm or from AUR on archlinux

* `npm install -g JSON.sh`
* `yaourt -Sy json-sh`
  ([json-sh on aur](https://aur.archlinux.org/packages/json-sh/)
  thanks to [kremlin-](https://github.com/kremlin-))

## License

This software is available under the following licenses:

  * MIT
  * Apache 2
