# JSON.sh

yo, so it's a json parser written in bash

this is what the interface in gonna be:

``` bash
cat package.json | JSONsh '.dependencies'

#key  value
foo   ~1
```

or a more complex example:

``` bash
curl registry.npmjs.org/module : JSONsh '.versions[*]'

#key  value
0.0.0 {...}

```


curl registry.npmjs.org/assertions | ./bin/json_parse | egrep '\["versions","[^"]*"\]'
