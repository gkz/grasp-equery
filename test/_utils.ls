parser = require 'flow-parser'
{query} = require '..'
require! assert

{map, all, is-type, keys} = require 'prelude-ls'

p = (input, {unwrap-exp-state=true, unwrap-program=true} = {}) ->
  parser-options =
      loc: false
      source-type: 'module'
      range: false
  res = parser.parse input, parser-options
  res-prime = if unwrap-program then res.body.0 else res
  if unwrap-exp-state and res-prime.type is 'ExpressionStatement' then res-prime.expression else res-prime

extract = (options, input) -->
  if is-type 'Object', input
    input
  else
    p input, options

q = (selector, code, locations = false) ->
  parser-options =
      loc: locations
      source-type: 'module'
      range: locations
  parsed = parser.parse code, parser-options
  query selector, parsed

normalize-typeof = (input) -> if input is 'Null' then 'Undefined' else input

deep-equal = (actual, expected, key) !->
  type-actual = normalize-typeof typeof! actual
  type-expected = normalize-typeof typeof! expected
  assert.strict-equal type-actual, type-expected, "typeof actual and expected do not match: #type-actual, #type-expected - actual: #actual, expected: #expected - key #key"
  switch type-actual
  | 'Array'   =>
    assert.strict-equal actual.length, expected.length, "array length not equal: #{ JSON.stringify actual}, #{JSON.stringify expected}"
    for x, i in actual
      deep-equal x, expected[i], i
  | 'Object'  =>
    for key, val of actual when key not in <[ loc range ]>
      deep-equal val, expected[key], key
    assert.deep-equal (keys actual._named), (keys expected._named) if expected._named
  | otherwise => assert.deep-equal actual, expected, "primitive value not equal: #actual, #expected"

eq = (answers, selectors, code, unwrap-exp-state = true, unwrap-program = true, loc = false) ->
  assert code, 'no code given'
  answers = [].concat answers
  selectors = [].concat selectors

  for selector in selectors
    results = q selector, code, loc
    extracted-answers = (map (extract {unwrap-exp-state, unwrap-program}), answers)
    try
      deep-equal results, extracted-answers
    catch
      console.log 'expected'
      console.log JSON.stringify extracted-answers, null, 2
      console.log 'results'
      console.log JSON.stringify results, null, 2
      throw e

make-prop = (key, value) ->
  type: 'Property'
  key: p key
  value: p value
  kind: 'init'
  method: false
  shorthand: false
  computed: false

module.exports = {eq, p, q, make-prop}
