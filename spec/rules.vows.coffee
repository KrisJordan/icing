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
                assert.equal arcs[0].from.name, 'A'
                assert.equal arcs[0].to.name, 'B'
    'A RuleGraph f([A]) -> B .. f([B]) -> C':
        topic: ->
            graph = new RuleGraph
            graph.rule new Rule 'B', ['A'], (->)
            graph.rule new Rule 'C', ['B'], (->)
        'has RecipeNodes':
            topic: (graph) -> graph.nodes.ofType RecipeNode
            'of length 2': (recipes) ->
                assert.length recipes.items, 2
        'has FileNodes':
            topic: (graph) -> graph.nodes.ofType FileNode
            'of length 1': (files) ->
                assert.length files.items, 1
    'A RuleGraph f([A]) -> B=>C':
        topic: ->
            graph = new RuleGraph
            graph.rule new Rule 'B', ['A'], new Recipe (->), (->['C'])
        'has RecipeNodes':
            topic: (graph) -> graph.nodes.ofType RecipeNode
            'of length 1': (recipes) ->
                assert.length recipes.items, 1
        'has FileNodes':
            topic: (graph) -> graph.nodes.ofType FileNode
            'of length 2': (files) ->
                assert.length files.items, 2
            'containing C': (files) ->
                assert.includes (files.pluck 'name'), 'C'
        'has 2 arcs':
            topic: (graph) -> graph.arcs
            'of length 2': (arcs) ->
                assert.length arcs.items, 2
            'from A,B': (arcs) ->
                from = _(arcs.pluck 'from').pluck 'name'
                ['A','B'].forEach (item) ->
                    assert.includes from, item
            'to B,C': (arcs) ->
                to = _(arcs.pluck 'to').pluck 'name'
                ['B','C'].forEach (item) ->
                    assert.includes to, item
    'A RuleGraph f([A])->B=>C, f([B])->D':
        topic: ->
            graph = new RuleGraph
            graph.rule new Rule 'B', ['A'], new Recipe (->), (->['C'])
            graph.rule new Rule 'D', ['B'], (->)
        'has RecipeNodes':
            topic: (graph) -> graph.nodes.ofType RecipeNode
            'of length 2': (recipes) ->
                assert.length recipes.items, 2
        'has FileNodes':
            topic: (graph) -> graph.nodes.ofType FileNode
            'of length 2': (files) ->
                assert.length files.items, 2
        'has Arcs':
            topic: (graph) -> graph.arcs
            'of length 3': (arcs) ->
                assert.length arcs.items, 3
            'from A,B,C': (arcs) ->
                from = _(arcs.pluck 'from').pluck 'name'
                ['A','B','C'].forEach (item) ->
                    assert.includes from, item
            'to B,C,D': (arcs) ->
                to = _(arcs.pluck 'to').pluck 'name'
                ['B','C','D'].forEach (item) ->
                    assert.includes to, item
)
.export(module)
