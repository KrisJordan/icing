# **dag** is a simple library for constructing and operating on 
# [directed acyclic graphs](http://en.wikipedia.org/wiki/Directed_acyclic_graph).
# Its primary purpose is to support command execution pipelines for **icing**.
# 
# **dag**'s key operations are:
#
# * finding the sources of a graph,
# * extracting the subgraph to a particular node, and 
# * obtaining a topological ordering of nodes for a given graph.
#
# Our graph is composed of **Nodes** and **Arcs**. Each node has a unique name.
# Each arc flows out of one node and into another. A source is a node with no 
# incoming edges. A [topological ordering](http://en.wikipedia.org/wiki/Topological_ordering)
# is a "linear ordering of its nodes in which each node comes before all nodes which
# it has outbound edges."
#
# *Disclaimer:  dag's intention is not to be a complete or robust
# DAG library. Nor is it meant to be highly performant, just simple.*

# **Dependencies** 
_ = require 'underscore'

#### Graph

class Graph

    # A graph is just a collection of Nodes and Arcs. We keep maps
    # of node names and arcs to ensure each node or arc between two
    # nodes is represented by a single, unique object in the graph.
    constructor: (@nodes = new NodeList, @arcs = new ArcList) ->
        @nodeMap = {}
        @arcMap = {}
        graph = this
        @nodes.forEach (node) -> graph.node node

    # Add a node to the graph and give the node a reference
    # back to the graph. Nodes are required to have unique names.
    # If the same node is added twice we silently noop. Different
    # nodes of the same name with throw an error.
    node: (node) -> # Graph || Node
        if _(node).isString()
            if @nodeMap[node]?
                return @nodeMap[node]
            else
                return undefined

        if @nodeMap[node.name]?
            if node.equals(@nodeMap[node.name])
                return this
            else
                throw new Error "Node of name #{node.name} already exists."
        @nodes.push node
        @nodeMap[node.name] = node
        this

    # Add an arc to the graph by specifying the names of nodes **from -arc-> to**
    # Ensure the arc is unique to the graph.
    arc: (fromName, toName) -> # Graph
        if @arcMap[fromName]?
            if @arcMap[fromName][toName]?
                return this

        if not @nodeMap[fromName]?
            throw new Error "Node #{fromName} does not exist"
        else
            fromNode = @nodeMap[fromName]

        if not @nodeMap[toName]?
            throw new Error "Node #{toName} does not exist"
        else
            toNode = @nodeMap[toName]

        # Create the Arc
        arc = new Arc fromNode, toNode
        @arcs.push arc

        # Cache it in the arcMap
        if not @arcMap[fromNode.name]?
            @arcMap[fromNode.name] = {}

        @arcMap[fromNode.name][toNode.name] = arc

        this

    # Find sources by gathering all nodes that have
    # inbound arcs and then removing those from the
    # list of all nodes.
    sources: -> # NodeList
        nodesWithoutInboundArcs = do @nodes.clone
        _(@arcs.pluckUniq 'to').forEach (node) ->
            nodesWithoutInboundArcs.remove node
        nodesWithoutInboundArcs


    # Obtain a topological ordering by starting with
    # source nodes. We visit each source node and:
    #
    # 1. Add it to topological order
    # 2. Remove its outbound arcs from graph
    # 3. Check to see if we've created new sources after removing arcs and placing them
    #  in the sources list
    # 4. Repeat until out of sources
    #
    # If there are arcs left in the graph after this process there
    # is a cycle in the graph. Otherwise we return the topologically sorted
    # NodeList.
    topologicalOrdering: -> # NodeList
        nodes = new NodeList
        sources = do this.sources
        arcs = do @arcs.clone
        while not sources.isEmpty()
            source = do sources.pop
            nodes.push source
            arcs.from(source).forEach (arc) ->
                arcs.remove arc
                if arcs.to(arc.to).isEmpty()
                    sources.push arc.to
        if arcs.isEmpty()
            nodes
        else
            throw new Error "Cycle detected in graph."

    # Utility function to determine if a cycle exists. 
    # Works by trying to find a topological ordering. If
    # none exists then a cycle is present.
    hasCycle: -> # bool
        try
            this.topologicalOrdering()
            false
        catch Error
            true

    # Obtain a subgraph by constructing a new Graph by 
    # backtracking from the target to sources.
    subgraph: (target) -> #Graph
        if this.hasCycle() then throw new Error "Can't create subgraph in a cyclic graph."
        if not @nodeMap[target]? then throw new Error "Target #{target} does not exist."
        else
            target = @nodeMap[target]
        graph = this
        subgraph = new Graph
        reconstruct = (to) ->
            toClone = do to.clone
            subgraph.node toClone
            graph.arcs.to(to).forEach (arc) ->
               fromClone = do arc.from.clone
               subgraph.node fromClone
               subgraph.arc fromClone.name, toClone.name
               reconstruct arc.from
        reconstruct target
        subgraph

#### Graph Components

# The base Node only has a name. It retains a reference
# to its graph for looking up arcs inbound to and outbound from
# the Node.
class Node
    constructor: (@name) ->
    clone: -> return new Node @name
    equals: (node) -> return @name == node.name

# Arc is a simple data structure referencing two unique nodes.
class Arc
    constructor: (@from,@to) ->
        if @from == @to then throw new Error "An arc's from Node cannot also be its to Node"

# List provides useful helpers around arrays
# that are used by Graph via subclasses NodeList
# and ArcList
class List
    constructor: (@items = []) ->
    push: (item) ->
        if _(@items).contains item
            @items = _(@items).without item
        @items.push item
    filter: (fn) -> _(@items).filter fn
    clone: -> new List @items.slice 0
    forEach: (fn) -> _(@items).forEach fn
    remove: (item) -> @items = _(@items).without item
    isEmpty: -> @items.length == 0
    pop: -> do @items.pop
    pluck: (property) ->
        _(@items).pluck property

class NodeList extends List
    ofType: (type) -> new NodeList _(@items).filter (node) -> node instanceof type
    clone: -> new NodeList super().items

class ArcList extends List
    from: (node) ->
        new ArcList _(@items).filter (arc) -> arc.from == node
    to: (node) ->
        new ArcList _(@items).filter (arc) -> arc.to == node
    pluckUniq: (property) ->
        _(@items).chain().pluck(property).uniq().value()
    clone: -> new ArcList super().items

####  Exports 
_(exports).extend {Node,Arc,List,NodeList,ArcList,Graph}
