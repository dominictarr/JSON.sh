# JSON.sh

yo, so it's a json parser written in bash

pipe json to it, and it traverses the json objects and prints out the 
path to the current object (as a JSON array) and then the object, without whitespace.

``` bash
$ json_parse < package.json
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

a more complex example:

``` bash
curl registry.npmjs.org/express | ./JSON.sh | egrep '\["versions","[^"]*"\]'
... try it and see
```

## Options

-b
> Brief output. Combines 'Leaf only' and 'Prune empty' options.

-f format
> Output format. See below.

-l
> Leaf only. Only show leaf nodes, which stops data duplication.

-p
> Prune empty. Exclude fields with empty values.

-n
> No-head. Don't show nodes that have no path. Normally these output a leading '[]', which you can't use in a bash array.

-s
> Remove escaping of the solidus symbol (stright slash).

-h
> Show help text.

## Format options
By default, parsed values are output in the form

``` bash
[path]<tab>value
```

where ```path``` is the path for the value, ```<tab>``` is a literal tab, and value is the JSON value. That's nice and human-readable, but not always the best for parsing. These additional output formats are available. Note that the -f option will accept the shortest unique name. IE: you can use ```ke``` instead of ```key```, but not just ```k``` because that is ambiguous with the ```key```, ```key-value``` and ```kv``` options.

### default
This is the default output format that you get if ```-f``` isn't specified.

### array
This produces output suitable for loading directly into a bash associative array. It implies -n.

```bash
[path]=value
```

### key
Output just paths, one per line, without []'s. For example, run against package.json you get:

``` bash
...
"bin","JSON.sh"
"bin"
...
```

### key-value (or just kv for short)
Suitable for processing with the read built-in.

``` bash
path<tab>value
```

### value
Similar to key mode, except you get values one-per-line instead.

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
