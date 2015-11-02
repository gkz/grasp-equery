{primitive-only-attributes, either-attributes, syntax-flat} = require 'grasp-syntax-javascript'
{all, tail} = require 'prelude-ls'
{get-node-at-path} = require './common'

!function match-node results, query, main-node
  if eq main-node, query
    results.push main-node

  spec = syntax-flat[main-node.type]
  for key in spec.nodes || [] when main-node[key]
    match-node results, query, main-node[key]
  for key in spec.node-arrays || []
    for sub-node in main-node[key] when sub-node
      match-node results, query, sub-node

  function eq target-node, selector-node
    if target-node is selector-node
      true
    else if selector-node.type is 'Grasp'
      match-special target-node, selector-node
    else if selector-node.type is target-node.type
      type = selector-node.type
      spec = syntax-flat[type]
      all (-> eq target-node[it], selector-node[it]), spec.nodes || [] and
      all (-> match-array target-node[it], selector-node[it]), spec.node-arrays || [] and
      all (-> target-node[it] is selector-node[it]), spec.primitives || []
    else
      false

  function match-array input, pattern
    if typeof! pattern is 'Object' and pattern.type is 'Grasp'
        return match-special input, pattern

    if pattern.length is 0
      input.length is 0
    else if pattern.length is 1
      if is-array-wildcard pattern.0
        if that.name
          main-node._named ?= {}
          main-node._named[that] ?= []
          main-node._named[that] ++= input
        true
      else
        input.length is 1 and eq input.0, pattern.0
    else if input.length is 0
      false
    else
      [pattern-first, ...pattern-rest] = pattern
      [input-first, ...input-rest] = input

      if is-array-wildcard pattern-first
        if that.name
          array-wildcard-name = that
          main-node._named ?= {}
          main-node._named[array-wildcard-name] ?= []
        if eq input-first, pattern-rest.0
          wildcard-name = that
          if match-array input-rest, (tail pattern-rest)
            true
          else
            delete main-node._named[wildcard-name] if typeof! wildcard-name is 'String'
            match-array input-rest, pattern
        else
          main-node._named[array-wildcard-name].push input-first if array-wildcard-name
          match-array input-rest, pattern
      else
        eq input-first, pattern-first and match-array input-rest, pattern-rest

  function match-special target-node, selector-node
    switch selector-node.grasp-type
    | 'wildcard'
      true
    | 'named-wildcard'
      main-node._named ?= {}
      named = main-node._named
      name = selector-node.name
      if named[name]
        if eq target-node, that
          true
        else
          false
      else
        named[name] = target-node
        name # aka 'true' - returns name in order to remove if failed later
    | 'node-type'
      target-node.type is selector-node.value
    | 'matches'
      target-node.type in selector-node.value
    | 'literal'
      target-node.type is 'Literal' and typeof! target-node.value is selector-node.value
    | 'compound'
      ident-match = match-special target-node, selector-node.ident
      attr-match = all (match-attr target-node), selector-node.attrs
      ident-match and attr-match

  function is-array-wildcard node
    clean-node = if node.type is 'ExpressionStatement' then node.expression else node
    clean-node.type is 'Grasp' and clean-node.grasp-type is 'array-wildcard' and clean-node

  function match-attr target-node
    (attr) ->
      node = get-node-at-path target-node, attr.path
      if node?
        attr-value = attr.value
        if attr-value
          last-path = attr.path[*-1]
          if last-path in primitive-only-attributes
            match-primitive attr.op, node, attr-value
          else if last-path in either-attributes
            match-either attr.op, node, attr-value
          else
            match-complex attr.op, node, attr-value
        else
          true
      else
        false

  function match-primitive op, node, attr-value
    if op is '='
      node is attr-value.value
    else
      node isnt attr-value.value

  function match-complex op, node, attr-value
    if op is '='
      eq node, attr-value
    else
      not eq node, attr-value

  function match-either op, node, attr-value
    match-primitive op, node, attr-value or match-complex op, node, attr-value

module.exports = {match-node}
