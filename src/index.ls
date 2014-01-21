{parse} = require './parse'
{match-node} = require './match'

VERSION = '0.2.0'

query = (selector, ast) ->
  query-parsed (parse selector), ast

query-parsed = (parsed-selector, ast) ->
  results = []
  match-node results, parsed-selector, ast
  results

module.exports = {parse, query-parsed, query, VERSION}
