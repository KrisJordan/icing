(function() {
  var Arc, FileNode, Graph, Node, NodeList, Recipe, RecipeNode, Rule, RuleGraph, assert, fs, globSync, _, _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  _ref = require('./dag'), Graph = _ref.Graph, Node = _ref.Node, Arc = _ref.Arc, NodeList = _ref.NodeList;
  _ = require('underscore');
  assert = require('assert');
  globSync = require('glob').globSync;
  fs = require('fs');
  RuleGraph = (function() {
    function RuleGraph() {
      RuleGraph.__super__.constructor.apply(this, arguments);
    }
    __extends(RuleGraph, Graph);
    RuleGraph.prototype.refresh = function(file) {
      return this.nodeMap[file].refresh();
    };
    RuleGraph.prototype.fileSources = function(target) {
      return this.subgraph(target).sources().ofType(FileNode);
    };
    RuleGraph.prototype.recipeNodesTo = function(target) {
      return this.subgraph(target).topologicalOrdering().ofType(RecipeNode);
    };
    RuleGraph.prototype.rule = function(rule) {
      var graph, outputs, target;
      assert.ok(rule instanceof Rule);
      graph = this;
      target = new RecipeNode(rule.target, rule.recipe);
      graph.node(target);
      rule.prereqs = _(rule.prereqs).chain().flatten().map(function(prereq) {
        var globbed;
        if (/\*/.test(prereq)) {
          globbed = globSync(prereq);
          if (globbed.length > 0) {
            return globbed;
          } else {
            return void 0;
          }
        } else {
          return prereq;
        }
      }).compact().flatten().value();
      rule.filePrereqs = [];
      rule.prereqs.forEach(function(prereq) {
        var input, inputsOutputs, kind, specialPrereq;
        specialPrereq = prereq.match(/^(task|outputs)\((.*)\)$/);
        if (specialPrereq) {
          kind = specialPrereq[1];
          prereq = specialPrereq[2];
        }
        input = graph.node(prereq);
        if (input && input instanceof RecipeNode) {
          if (specialPrereq === null) {
            throw new Error("Task prerequisites must be referenced with task(" + prereq + ") or outputs(" + prereq + ")");
          }
          if (!(input instanceof RecipeNode)) {
            console.error("Bad prereq: " + kind + "(" + prereq + ") - " + prereq + " must be the name of a task");
            process.exit(1);
          }
          if (kind === 'outputs') {
            inputsOutputs = graph.arcs.from(input).to().ofType(FileNode);
            if (!inputsOutputs.isEmpty()) {
              inputsOutputs.forEach(function(inputsOutput) {
                graph.arc(inputsOutput.name, target.name);
                return rule.filePrereqs.push(inputsOutput.name);
              });
              return;
            }
          }
        } else if (specialPrereq) {
          console.error("Error: task '" + target.name + "' prereq '" + kind + "(" + prereq + ")'-'" + prereq + "' is not yet defined");
          process.exit(1);
        } else {
          input = new FileNode(prereq);
          rule.filePrereqs.push(prereq);
          graph.node(input);
        }
        return graph.arc(input.name, target.name);
      });
      outputs = rule.recipe.outputs.call(rule);
      outputs.forEach(function(output) {
        output = new FileNode(output);
        graph.node(output);
        return graph.arc(target.name, output.name);
      });
      return this;
    };
    return RuleGraph;
  })();
  Rule = (function() {
    function Rule(target, prereqs, recipe) {
      this.target = target;
      this.prereqs = prereqs;
      this.recipe = recipe;
      if (_(this.recipe).isFunction()) {
        this.recipe = new Recipe(this.recipe);
      }
    }
    return Rule;
  })();
  Recipe = (function() {
    function Recipe(recipe, outputs) {
      this.recipe = recipe != null ? recipe : (function() {});
      this.outputs = outputs != null ? outputs : (function() {
        return [];
      });
    }
    return Recipe;
  })();
  RecipeNode = (function() {
    __extends(RecipeNode, Node);
    function RecipeNode(name, recipe) {
      this.name = name;
      this.recipe = recipe;
    }
    RecipeNode.prototype.equals = function(node) {
      return RecipeNode.__super__.equals.call(this, node) && node instanceof RecipeNode;
    };
    RecipeNode.prototype.clone = function(node) {
      return new RecipeNode(this.name, this.recipe);
    };
    RecipeNode.prototype.prereqs = function(graph) {
      return graph.arcs.to(graph.node(this.name)).from().ofType(FileNode);
    };
    RecipeNode.prototype.outputs = function(graph) {
      return graph.arcs.from(graph.node(this.name)).to().ofType(FileNode);
    };
    RecipeNode.prototype.refreshOutputs = function(graph) {
      return this.outputs(graph).forEach(function(fileNode) {
        return fileNode.refresh();
      });
    };
    RecipeNode.prototype.modifiedPrereqs = function(graph) {
      var outputMin, outputs, prereqMax, prereqs;
      prereqs = this.prereqs(graph);
      outputs = this.outputs(graph);
      if (prereqs.isEmpty() || outputs.isEmpty()) {
        return prereqs;
      }
      if (prereqs.count() === outputs.count()) {
        return new NodeList(_(_.zip(prereqs.items, outputs.items)).chain().map(function(pair) {
          var input, inputTime, output, outputTime;
          input = pair[0], output = pair[1];
          inputTime = input.mtime || Date.now();
          outputTime = output.mtime || 0;
          if (inputTime > outputTime) {
            return input;
          } else {
            return false;
          }
        }).compact().value());
      } else {
        prereqMax = _(prereqs.items).max(function(fileNode) {
          return fileNode.mtime || (fileNode.mtime = Date.now());
        });
        outputMin = _(outputs.items).min(function(fileNode) {
          return fileNode.mtime || (fileNode.mtime = 0);
        });
        if (prereqMax.mtime > outputMin.mtime) {
          return prereqs;
        } else {
          return new NodeList;
        }
      }
    };
    RecipeNode.prototype.shouldRun = function(graph) {
      var outputs, prereqs;
      prereqs = this.prereqs(graph);
      if (prereqs.isEmpty()) {
        return true;
      }
      outputs = this.outputs(graph);
      if (outputs.isEmpty()) {
        return true;
      }
      return !this.modifiedPrereqs(graph).isEmpty();
    };
    RecipeNode.prototype.run = function(context, options) {
      return this.recipe.recipe.call(context, options);
    };
    return RecipeNode;
  })();
  FileNode = (function() {
    __extends(FileNode, Node);
    function FileNode(name) {
      this.name = name;
      this.refresh();
    }
    FileNode.prototype.equals = function(node) {
      return FileNode.__super__.equals.call(this, node) && node instanceof FileNode;
    };
    FileNode.prototype.clone = function(node) {
      return new FileNode(this.name);
    };
    FileNode.prototype.refresh = function() {
      try {
        this.stats = fs.statSync(this.name);
        return this.mtime = this.stats.mtime;
      } catch (Error) {
        this.stats = {};
        return this.mtime = void 0;
      }
    };
    return FileNode;
  })();
  _(exports).extend({
    RuleGraph: RuleGraph,
    Rule: Rule,
    RecipeNode: RecipeNode,
    FileNode: FileNode,
    Recipe: Recipe
  });
}).call(this);
