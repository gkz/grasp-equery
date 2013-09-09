{primitive-only-attributes, either-attributes} = require 'grasp-syntax-javascript'
{all} = require 'prelude-ls'
{get-node-at-path} = require './common'

!function match-node results, query, node
  if eq node, query
    results.push node

  for key, val of node when key not in  <[ loc start end ]> and typeof! val in <[ Object Array ]>
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
      for prop of target-node when prop not in <[ loc start end ]>
        return false unless eq target-node[prop], selector-node[prop]
      true
  else if selector-node-type is 'Array'
    len = selector-node.length
    target-len = target-node.length
    arr-wildcard-matched = false
    i = 0
    for node in selector-node
      if match-array-wildcard node
        if i + 1 is len
          return true
        else
          arr-wildcard-matched = true
          targets-left = len - i - 1
          i = target-len - targets-left
      else
        return false unless eq target-node[i], node
        i++
    arr-wildcard-matched or len is target-len
  else
    false

function match-special target-node, selector-node
  switch selector-node.grasp-type
  | 'wildcard'
    true
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

function match-array-wildcard node
  clean-node = if node.type is 'ExpressionStatement' then node.expression else node
  clean-node.type is 'Grasp' and clean-node.grasp-type is 'array-wildcard'

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
