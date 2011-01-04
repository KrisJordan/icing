vows        = require 'vows'
assert      = require 'assert'
rules       = require '../src/rules'
_           = require 'underscore'

{ RuleGraph, Rule, RecipeNode, FileNode, Recipe } = rules

vows
.describe('rules.RuleGraph')
.addBatch(
    'A RuleGraph':
        topic: new RuleGraph
        'is empty': (graph) ->
            assert.length graph.nodes.items, 0
    'A RuleGraph f([]) -> A':
        topic: ->
            graph = new RuleGraph
            graph.rule new Rule 'A',[],(->)
        'has 1 node that is a RecipeNode': (graph) ->
            assert.length graph.nodes.items, 1
            assert.isTrue graph.nodes.items[0] instanceof RecipeNode
    'A RuleGraph f([A]) -> B':
        topic: ->
            graph = new RuleGraph
            graph.rule new Rule 'B',['A'],(->)
        'has 2 nodes A and B': (graph) ->
            assert.length graph.nodes.items, 2
        'has nodes of type FileNode':
            topic: (graph) -> graph.nodes.ofType FileNode
            'of length 1 with name A': (files) ->
                assert.length files.items, 1
                assert.equal files.items[0].name, 'A'
        'has nodes of type RecipeNode':
            topic: (graph) -> graph.nodes.ofType RecipeNode
            'of length 1 with name B': (recipes) ->
                assert.length recipes.items, 1
                assert.equal recipes.items[0].name, 'B'
        'has arcs':
            topic: (graph) -> graph.arcs.items
            'of length 1, from A to B': (arcs) ->
                assert.length arcs, 1
                assert.equal arcs[0].from, 'A'
                assert.equal arcs[0].to, 'B'
)
.export(module)
