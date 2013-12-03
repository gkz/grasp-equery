# grasp equery [![Build Status](https://travis-ci.org/gkz/grasp-equery.png?branch=master)](https://travis-ci.org/gkz/grasp-equery)
A query engine for [grasp](http://graspjs.com) - use JavaScript code examples with wildcards.

For documentation on the selector format, see [the grasp page on equery](http://graspjs.com/docs/equery).

See also the other query engine for grasp: [squery](https://github.com/gkz/grasp-squery).

## Usage

Add `grasp-equery` to your `package.json`, and then require it: `var equery = require('grasp-equery);`.

The `squery` object exposes four properties: three functions, `parse`, `queryParsed`, `query`, and the version string as `VERSION`.

Use `parse(selector)` to parse a string selector into a parsed selector.

Use `queryParsed(parsedSelector, ast)` to query your parsed selector.

`query(selector, ast)` is shorthand for doing `queryParsed(parse(selector), ast)`.

The AST must be in the [Mozilla SpiderMonkey AST format](https://developer.mozilla.org/en-US/docs/SpiderMonkey/Parser_API) - you can use [acorn](https://github.com/marijnh/acorn) to parse a JavaScript file into the format.

If you are using one selector for multiple ASTs, parse it first, and then feed the parsed version to `queryParsed`. If you are only using the selector once, just use `query`.
