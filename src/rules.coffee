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
{ Graph, Node, Arc, NodeList }  = require './dag'
_                               = require 'underscore'
assert                          = require 'assert'
{ globSync }                    = require 'glob'

class RuleGraph extends Graph
    recipeNodesTo: (target) ->
        this.subgraph(target)
            .topologicalOrdering()
            .ofType RecipeNode

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
                # There's a special case when a RecipeNode's recipe has outputs. When
                # other RecipeNode targets have one as a prereq its dependency is on 
                # those FileNode outputs and not the RecipeNode itself.
                if input instanceof RecipeNode
                    inputsOutputs =  graph.arcs.from(input).to().ofType(FileNode)
                    if not inputsOutputs.isEmpty()
                        inputsOutputs.forEach (inputsOutput) ->
                            graph.arc inputsOutput.name, target.name
                        return
                graph.arc input.name, target.name
            else
                # see if there's an expansion for it
                globbed = globSync prereq
                if globbed.length > 0
                    globbed.forEach (file) ->
                        input = new FileNode file
                        graph.node input
                        graph.arc input.name, target.name
                else
                    input = new FileNode prereq
                    graph.node input
                    graph.arc input.name, target.name

        outputs = rule.recipe.outputs.call rule
        outputs.forEach (output) ->
            output = new FileNode output
            graph.node output
            graph.arc target.name, output.name

        this

#### Rule Graph Elements        
class Rule
    constructor: (@target, @prereqs, @recipe) ->
        if _(@recipe).isFunction()
            @recipe = new Recipe @recipe
        @prereqs = @prereqs.reverse() # Because we push they'll get reversed again

class Recipe
    constructor: (@exec = (->), @outputs = (->[])) ->

#### Additional Graph Nodes
class RecipeNode extends Node
    constructor: (@name, @recipe) ->
    equals: (node) ->
        super(node) && node instanceof RecipeNode
    clone: (node) -> new RecipeNode @name, @recipe
    prereqs: (graph) -> graph.arcs.to(graph.node this.name).from().ofType FileNode
    shouldRun: (graph) -> true
    run: (context, options) -> @recipe.exec.call context, options

class FileNode extends Node
    constructor: (@name) ->
    equals: (node) ->
        super(node) && node instanceof FileNode
    clone: (node) -> new FileNode @name


#### Exports 
_(exports).extend { RuleGraph, Rule, RecipeNode, FileNode, Recipe }
