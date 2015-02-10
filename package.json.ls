name: 'grasp-equery'
version: '0.2.1'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'grasp query using example code with wildcards'
homepage: 'http://graspjs.com/docs/equery'
keywords:
  'grasp'
  'query'
  'equery'
  'ast'
  'javascript'
  'search'

files:
  'lib'
  'README.md'
  'LICENSE'
main: './lib/'

bugs: 'https://github.com/gkz/grasp-equery/issues'
licenses:
  * type: 'MIT'
    url: 'https://raw.github.com/gkz/grasp-equery/master/LICENSE'
  ...
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/grasp-equery.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '~1.1.1'
  acorn: '~0.6.0'
  'grasp-syntax-javascript': '~0.1.0'

dev-dependencies:
  LiveScript: '~1.3.1'
  mocha: '~2.1.0'
  istanbul: '~0.3.5'
