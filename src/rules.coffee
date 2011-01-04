# **rules** models task pipelines using directed acyclic graph (**dag.coffee**) primitives.
# Following in the heritage of *make*, rules have a target, prerequisites, and a recipe.
# Unlike *make* target is a symbolic name and prerequisites can refer to other rules or to
# files on disk.
# 
# * **target** - the name of a rule
# * **prerequisites** - rules or files that the target depends on having previously run
# * **recipe** - an object with an exec method that satisfies the target and, optionally, 
# a method describing its outputs
#
# One way of describing their relationship would be: *recipe(prerequisites) -> target*
#
# Rules are modeled on the dag as FileNodes and RecipeNodes. The target is always
# a RecipeNode. It has inbound arcs coming from prerequisites which can be either
# RecipeNodes or FileNodes. If a recipe defines its outputs they are FileNodes and
# are connected with outbound arcs from the target RecipeNode. Rules with other rules
# as prerequisites will substitute the rule prereq with the rule's recipe's outputs
# if they exist.

# **Dependencies**
{ Graph, Node, Arc }    = require './dag'
_                       = require 'underscore'
assert                  = require 'assert'

class RuleGraph extends Graph
    rule: (rule) ->
        assert.ok rule instanceof Rule

        graph = this

        target = new RecipeNode rule.target, rule.recipe
        graph.node target

        rule.prereqs.forEach (prereq) ->
            # If a prereq already exists, we use it. Targets must therefore
            # always be defined prior to being referenced as prerequisites in other
            # rules.
            if graph.node prereq
                input = graph.node prereq
            else
                input = new FileNode prereq
                graph.node input
            graph.arc input.name, target.name

        this

class Rule
    constructor: (@target, @prereqs, @recipe) ->
        
class RecipeNode extends Node
    constructor: (@name, @recipe) ->
    equals: (node) ->
        super(node) && node instanceof RecipeNode

class FileNode extends Node
    constructor: (@name) ->
    equals: (node) ->
        super(node) && node instanceof FileNode

class Recipe
    constructor: (@fn = (->), @outputs = (->[])) ->

#### Exports 
_(exports).extend { RuleGraph, Rule, RecipeNode, FileNode, Recipe }
