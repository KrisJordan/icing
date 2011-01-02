_ = require 'underscore'

class Node
    constructor: (@name) ->
    graph: (graph=undefined) ->

class Arc
    constructor: (@outNode,@inNode) ->

class NodeList
    constructor: (@nodes = []) ->
    push: (node) ->
    ofType: (type) ->

class Graph
    constructor: ->
        @nodes = []
        @arcs = []
    node: (node) ->
    arc: (arc) ->
    in: (node) ->
    out: (node) ->
    sources: ->
    order: ->
    hasCycle: ->

_(exports).extend {Node,Arc,NodeList,Graph}
