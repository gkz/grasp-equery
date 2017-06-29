name: 'grasp-equery'
version: '0.4.0'

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
license: 'MIT'
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/grasp-equery.git'
scripts:
  test: "make test"

dependencies:
  'flow-parser': '^0.*'
  'prelude-ls': '^1.1.2'
  'grasp-syntax-javascript': '^0.2.0'

dev-dependencies:
  livescript: '^1.4.0'
  mocha: '^2.3.4'
  istanbul: '^0.4.1'
