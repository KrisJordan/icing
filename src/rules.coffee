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
fs                              = require 'fs'

class RuleGraph extends Graph

    refresh: (file) ->
        do this.nodeMap[file].refresh
    
    fileSources: (target) ->
        this.subgraph(target)
            .sources()
            .ofType FileNode

    recipeNodesTo: (target) ->
        this.subgraph(target)
            .topologicalOrdering()
            .ofType RecipeNode

    rule: (rule) ->
        assert.ok rule instanceof Rule

        graph = this

        target = new RecipeNode rule.target, rule.recipe
        graph.node target

        # Glob Prereqs
        rule.prereqs = _(rule.prereqs)
            .chain()
            .map( (prereq) ->
                globbed = globSync prereq
                if globbed.length > 0
                    globbed
                else
                    prereq
            )
            .flatten()
            .value()

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
            else
                # see if there's an expansion for it
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
    outputs: (graph) -> graph.arcs.from(graph.node this.name).to().ofType FileNode
    refreshOutputs: (graph) ->
        this.outputs(graph).forEach (fileNode) -> fileNode.refresh()
    modifiedPrereqs: (graph) ->
        prereqs = this.prereqs graph
        outputs = this.outputs graph
        if prereqs.isEmpty() or outputs.isEmpty() then return prereqs

        # There are file inputs and outputs. If there is the same number of inputs
        # as outputs we take a special case and compare them 1 by 1. If there are
        # a different number of inputs and outputs we check to see if the greatest
        # modified time of the inputs is greater than the oldest output. If so we
        # should run.
        if prereqs.count() == outputs.count()
            return new NodeList _(_.zip prereqs.items,outputs.items)
                .chain()
                .map((pair) ->
                    [input,output] = pair
                    inputTime = input.mtime || Date.now()
                    outputTime = output.mtime || 0
                    if inputTime > outputTime
                        input
                    else
                        false
                )
                .compact()
                .value()
        else
            prereqMax = _(prereqs.items).max (fileNode) -> fileNode.mtime ||= Date.now()
            outputMin = _(outputs.items).min (fileNode) -> fileNode.mtime ||= 0
            if prereqMax.mtime > outputMin.mtime
                return prereqs
            else
                return new NodeList

    shouldRun: (graph) ->
        prereqs = this.prereqs graph
        # Recipes without prereqs always run
        if prereqs.isEmpty() then return true

        outputs = this.outputs graph
        # Recipes without file outputs always run
        if outputs.isEmpty() then return true

        return not this.modifiedPrereqs(graph).isEmpty()

    run: (context, options) -> @recipe.exec.call context, options

class FileNode extends Node
    constructor: (@name) -> this.refresh()
    equals: (node) ->
        super(node) && node instanceof FileNode
    clone: (node) -> new FileNode @name
    refresh: ->
        try
            @stats = fs.statSync @name
            @mtime = @stats.mtime
        catch Error
            @stats = {}
            @mtime = undefined

#### Exports 
_(exports).extend { RuleGraph, Rule, RecipeNode, FileNode, Recipe }
