name: 'grasp-equery'
version: '0.2.3'

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
  'prelude-ls': '~1.1.2'
  acorn: '~2.5.0'
  'grasp-syntax-javascript': '~0.1.0'

dev-dependencies:
  livescript: '~1.4.0'
  mocha: '~2.1.0'
  istanbul: '~0.3.5'
