vows        = require 'vows'
assert      = require 'assert'
dag      = require '../src/dag'
_           = require 'underscore'

{ Node, Arc, List, NodeList, ArcList, Graph } = dag

graphFromMap = (map) ->
    graph = new Graph
    for target,prereqs of map
        graph.node new Node target
        for prereq in prereqs
            graph.node new Node prereq
            graph.arc prereq,target
    graph

stringFromMap = (map) ->
    pairs = []
    for target,prereqs of map
        if prereqs.length == 0
            pairs.push "\t#{target}"
        else
            pairs.push "\t#{target} <- [#{prereqs.join ','}]\t"
    "{\n#{pairs.join "\n"}\n}"

testGraph = (options) ->
    title = "Graph:\n#{stringFromMap options.graph}"
    context = {}
    focus = context
    focus[title] = {}
    
    focus = focus[title]
    focus.topic = graphFromMap options.graph
    
    focus["has #{options.nodes.length} nodes: [#{options.nodes.join(',')}]"] = (graph) ->
        assert.length graph.nodes.items, options.nodes.length
        actualNodes = graph.nodes.pluck 'name'
        options.nodes.forEach (node) ->
            assert.include actualNodes, node

    focus["has #{options.arcs} arcs"] = (graph) ->
        assert.length graph.arcs.items, options.arcs

    focus["does #{ if not options.hasCycle then "not " else "" }have a cycle"] = (graph) ->
        assert.equal graph.hasCycle(), options.hasCycle

    if options.topologicalOrdering? and options.topologicalOrdering.length > 0
        focus["has a topological sort: [#{options.topologicalOrdering.join ','}]"] = (graph) ->
            assert.deepEqual (graph.topologicalOrdering().pluck 'name'), options.topologicalOrdering

    if options.sources?
        focus["has sources of length #{options.sources.length} containing [#{options.sources.join ','}]"] = (graph) ->
            sources = graph.sources().pluck 'name'
            assert.length sources, options.sources.length
            options.sources.forEach (source) ->
                assert.include sources, source

    return context

vows
.describe('dag.Graph')
.addBatch(
    testGraph
        graph: {}
        nodes: []
        arcs: 0
        sources: []
        hasCycle: false
)
.addBatch(
    testGraph
        graph:
            'A':[]
        nodes: ['A']
        arcs: 0
        sources:['A']
        hasCycle: false
        topologicalOrdering: ['A']
)
.addBatch(
    testGraph
        graph:
            'B':['A']
        nodes: ['A','B']
        arcs: 1
        sources:['A']
        hasCycle: false
        topologicalOrdering:['A','B']
)
.addBatch(
    testGraph
        graph:
            'js:append':['js:coffee','c.js']
            'js:coffee':['a.coffee','b.coffee']
            'js:min':['js:append']
        nodes:  ['js:append','js:coffee','c.js','a.coffee','b.coffee','js:min']
        arcs: 5
        sources: ['a.coffee','b.coffee','c.js']
        hasCycle: false
        topologicalOrdering: [
            'b.coffee'
            'a.coffee'
            'js:coffee'
            'c.js'
            'js:append'
            'js:min'
        ]
)
.addBatch(
    testGraph
        graph:
            'B':['A']
            'C':['B']
            'A':['C']
        nodes: ['A','B','C']
        arcs: 3
        hasCycle: true
)
.addBatch(
    'A graph with one node':
        topic: ->
            graph = new Graph
            graph.node new Node 'A'
        'will throw if different node of same name added': (graph) ->
            Aprime = new Node 'A'
            Aprime.foo = 'bar'
            assert.throws graph.node Aprime, Error
    'A graph with two deep equal A nodes':
        topic: ->
            graph = new Graph
            graph.node new Node 'A'
            graph.node new Node 'A'
        'has a node list':
            topic: (graph) -> graph.nodes
            'with one element': (nodes) ->
                assert.length nodes.items, 1
)
.export(module)

vows
.describe('dag.List')
.addBatch(
    'A List':
        topic: new List
        'has no nodes': (list) ->
            assert.length list.items, 0
)
.export(module)

vows
.describe('dag.Node')
.addBatch(
    'A Node(A)':
        topic: new Node('A')
        'has name A': (node) ->
            assert.equal node.name, 'A'
)
.export(module)

vows
.describe('dag.Arc')
.addBatch(
    'An Arc(A,B)':
        topic: new Arc(new Node('A'), new Node('B'))
        'has from(A)': (arc) ->
            assert.deepEqual arc.from, new Node 'A'
        'has to(B)': (arc) ->
            assert.deepEqual arc.to, new Node 'B'
)
.export(module)


