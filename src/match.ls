{primitive-only-attributes, either-attributes} = require 'grasp-syntax-javascript'
{all, tail} = require 'prelude-ls'
{get-node-at-path} = require './common'

!function match-node results, query, main-node
  if eq main-node, query
    results.push main-node

  for key, val of main-node when key not in <[ loc start end _named ]> and typeof! val in <[ Object Array ]>
    match-node results, query, val

  function eq target-node, selector-node
    selector-node-type = typeof! selector-node
    if selector-node is target-node
      true
    else if selector-node-type isnt typeof! target-node
      false
    else if selector-node-type is 'Object'
      if selector-node.type is 'Grasp'
        match-special target-node, selector-node
      else
        for prop of target-node when prop not in <[ loc start end _named ]>
          return false unless eq target-node[prop], selector-node[prop]
        true
    else if selector-node-type is 'Array'
      match-array selector-node, target-node
    else
      false

  function match-array pattern, input
    pattern-len = pattern.length

    if pattern-len is 0
      input.length is 0
    else if pattern-len is 1
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
          if match-array (tail pattern-rest), input-rest
            true
          else
            delete main-node._named[wildcard-name] if typeof! wildcard-name is 'String'
            match-array pattern, input-rest
        else
          main-node._named[array-wildcard-name].push input-first if array-wildcard-name
          match-array pattern, input-rest
      else
        eq input-first, pattern-first and match-array pattern-rest, input-rest

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
