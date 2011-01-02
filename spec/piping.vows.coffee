vows        = require 'vows'
assert      = require 'assert'
piping      = require '../src/piping'
_           = require 'underscore'

{ Node, Arc, NodeList, Graph } = piping

vows
.describe('piping.Node')
.addBatch(
    'A Node(A)':
        topic: new Node('A')
        'has name A': (node) ->
            assert.equal node.name, 'A'
)
.export(module)

vows
.describe('piping.Arc')
.addBatch(
    'An Arc(A,B)':
        topic: new Arc(new Node('A'), new Node('B'))
        'has outNode(A)': (arc) ->
            assert.deepEqual arc.outNode, new Node 'A'
        'has inNode(B)': (arc) ->
            assert.deepEqual arc.inNode, new Node 'B'
)
.export(module)

vows
.describe('piping.NodeList')
.addBatch(
    'A NodeList':
        topic: new NodeList
        'has no nodes': (list) ->
            assert.length list.nodes, 0
)
.export(module)

vows
.describe('piping.Graph')
.addBatch(
    'A Graph':
        topic: new Graph
        'has no nodes': (graph) ->
            assert.length graph.nodes, 0
        'has no arcs': (graph) ->
            assert.length graph.arcs, 0
)
.export(module)
