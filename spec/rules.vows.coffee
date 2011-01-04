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
            graph.rule 'A',[],(->)
        'has 1 node that is a RecipeNode': (graph) ->
            assert.length graph.nodes.items, 1
            assert.isTrue graph.nodes.items[0] instanceof RecipeNode
)
.export(module)
