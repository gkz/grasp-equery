{attr-map} = require 'grasp-syntax-javascript'

get-node-at-path = (node, path) ->
  for prop in path
    if node[attr-map[prop] or prop]?
      node = that
    else
      return
  node

module.exports = {get-node-at-path}
