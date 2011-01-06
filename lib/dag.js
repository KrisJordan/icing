(function() {
  var Arc, ArcList, Graph, List, Node, NodeList, _;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  _ = require('underscore');
  Graph = (function() {
    function Graph(nodes, arcs) {
      var graph;
      this.nodes = nodes != null ? nodes : new NodeList;
      this.arcs = arcs != null ? arcs : new ArcList;
      this.nodeMap = {};
      this.arcMap = {};
      graph = this;
      this.nodes.forEach(function(node) {
        return graph.node(node);
      });
    }
    Graph.prototype.node = function(node) {
      if (_(node).isString()) {
        if (this.nodeMap[node] != null) {
          return this.nodeMap[node];
        } else {
          return void 0;
        }
      }
      if (this.nodeMap[node.name] != null) {
        if (node.equals(this.nodeMap[node.name])) {
          return this;
        } else {
          throw new Error("Node of name " + node.name + " already exists.");
        }
      }
      this.nodes.push(node);
      this.nodeMap[node.name] = node;
      return this;
    };
    Graph.prototype.arc = function(fromName, toName) {
      var arc, fromNode, toNode;
      if (this.arcMap[fromName] != null) {
        if (this.arcMap[fromName][toName] != null) {
          return this;
        }
      }
      if (!(this.nodeMap[fromName] != null)) {
        throw new Error("Node " + fromName + " does not exist");
      } else {
        fromNode = this.nodeMap[fromName];
      }
      if (!(this.nodeMap[toName] != null)) {
        throw new Error("Node " + toName + " does not exist");
      } else {
        toNode = this.nodeMap[toName];
      }
      arc = new Arc(fromNode, toNode);
      this.arcs.push(arc);
      if (!(this.arcMap[fromNode.name] != null)) {
        this.arcMap[fromNode.name] = {};
      }
      this.arcMap[fromNode.name][toNode.name] = arc;
      return this;
    };
    Graph.prototype.sources = function() {
      var nodesWithoutInboundArcs;
      nodesWithoutInboundArcs = this.nodes.clone();
      this.arcs.to().forEach(function(node) {
        return nodesWithoutInboundArcs.remove(node);
      });
      return nodesWithoutInboundArcs;
    };
    Graph.prototype.topologicalOrdering = function() {
      var arcs, nodes, source, sources;
      nodes = new NodeList;
      sources = this.sources();
      arcs = this.arcs.clone();
      while (!sources.isEmpty()) {
        source = sources.pop();
        nodes.push(source);
        arcs.from(source).forEach(function(arc) {
          arcs.remove(arc);
          if (arcs.to(arc.to).isEmpty()) {
            return sources.push(arc.to);
          }
        });
      }
      if (arcs.isEmpty()) {
        return nodes;
      } else {
        throw new Error("Cycle detected in graph.");
      }
    };
    Graph.prototype.hasCycle = function() {
      try {
        this.topologicalOrdering();
        return false;
      } catch (Error) {
        return true;
      }
    };
    Graph.prototype.subgraph = function(target) {
      var graph, reconstruct, subgraph;
      if (this.hasCycle()) {
        throw new Error("Can't create subgraph in a cyclic graph.");
      }
      if (!(this.nodeMap[target] != null)) {
        throw new Error("Target " + target + " does not exist.");
      } else {
        target = this.nodeMap[target];
      }
      graph = this;
      subgraph = new Graph;
      reconstruct = function(to) {
        var toClone;
        toClone = to.clone();
        subgraph.node(toClone);
        return graph.arcs.to(to).forEach(function(arc) {
          var fromClone;
          fromClone = arc.from.clone();
          subgraph.node(fromClone);
          subgraph.arc(fromClone.name, toClone.name);
          return reconstruct(arc.from);
        });
      };
      reconstruct(target);
      return subgraph;
    };
    return Graph;
  })();
  Node = (function() {
    function Node(name) {
      this.name = name;
    }
    Node.prototype.clone = function() {
      return new Node(this.name);
    };
    Node.prototype.equals = function(node) {
      return this.name === node.name;
    };
    return Node;
  })();
  Arc = (function() {
    function Arc(from, to) {
      this.from = from;
      this.to = to;
      if (this.from === this.to) {
        throw new Error("An arc's from Node cannot also be its to Node");
      }
    }
    return Arc;
  })();
  List = (function() {
    function List(items) {
      this.items = items != null ? items : [];
    }
    List.prototype.push = function(item) {
      if (_(this.items).contains(item)) {
        this.items = _(this.items).without(item);
      }
      return this.items.push(item);
    };
    List.prototype.filter = function(fn) {
      return _(this.items).filter(fn);
    };
    List.prototype.clone = function() {
      return new List(this.items.slice(0));
    };
    List.prototype.forEach = function(fn) {
      return _(this.items).forEach(fn);
    };
    List.prototype.remove = function(item) {
      return this.items = _(this.items).without(item);
    };
    List.prototype.isEmpty = function() {
      return this.items.length === 0;
    };
    List.prototype.pop = function() {
      return this.items.pop();
    };
    List.prototype.shift = function() {
      return this.items.shift();
    };
    List.prototype.count = function() {
      return this.items.length;
    };
    List.prototype.pluck = function(property) {
      return _(this.items).pluck(property);
    };
    return List;
  })();
  NodeList = (function() {
    function NodeList() {
      NodeList.__super__.constructor.apply(this, arguments);
    }
    __extends(NodeList, List);
    NodeList.prototype.ofType = function(type) {
      return new NodeList(_(this.items).filter(function(node) {
        return node instanceof type;
      }));
    };
    NodeList.prototype.clone = function() {
      return new NodeList(NodeList.__super__.clone.call(this).items);
    };
    NodeList.prototype.names = function() {
      return _(this.items).pluck('name');
    };
    return NodeList;
  })();
  ArcList = (function() {
    function ArcList() {
      ArcList.__super__.constructor.apply(this, arguments);
    }
    __extends(ArcList, List);
    ArcList.prototype.from = function(node) {
      if (node != null) {
        return new ArcList(_(this.items).filter(function(arc) {
          return arc.from === node;
        }));
      } else {
        return new NodeList(this.pluckUniq('from'));
      }
    };
    ArcList.prototype.to = function(node) {
      if (node != null) {
        return new ArcList(_(this.items).filter(function(arc) {
          return arc.to === node;
        }));
      } else {
        return new NodeList(this.pluckUniq('to'));
      }
    };
    ArcList.prototype.pluckUniq = function(property) {
      return _(this.items).chain().pluck(property).uniq().value();
    };
    ArcList.prototype.clone = function() {
      return new ArcList(ArcList.__super__.clone.call(this).items);
    };
    return ArcList;
  })();
  _(exports).extend({
    Node: Node,
    Arc: Arc,
    List: List,
    NodeList: NodeList,
    ArcList: ArcList,
    Graph: Graph
  });
}).call(this);
