(function() {
  var RecipeNode, Rule, RuleGraph, cake, cakeTask, exec, fs, graph, runRecipeContext, stylize, _ref;
  option('-v', '--verbose', 'Display progress as tasks are executed');
  option('-w', '--watch', 'Monitor files for changes and automatically rebuild');
  _ref = require('./rules'), RuleGraph = _ref.RuleGraph, Rule = _ref.Rule, RecipeNode = _ref.RecipeNode;
  exec = require('child_process').exec;
  fs = require('fs');
  cake = require('coffee-script/cake');
  cakeTask = global.task;
  graph = new RuleGraph;
  global.task = function(target, description, prereqs, recipe) {
    if (prereqs == null) {
      prereqs = void 0;
    }
    if (recipe == null) {
      recipe = void 0;
    }
    if (!(prereqs != null) && !(recipe != null)) {
      recipe = description;
      description = target;
      prereqs = [];
    }
    if (!(recipe != null)) {
      if (description.shift != null) {
        recipe = prereqs;
        prereqs = description;
        description = target;
      } else {
        recipe = prereqs;
        prereqs = [];
      }
    }
    graph.rule(new Rule(target, prereqs, recipe));
    return cakeTask(target, description, function(options) {
      var aRecipeRan, allRecipesProcessed, fileSources, recipeNode, recipeNodes, runTask, taskIsRunning;
      taskIsRunning = false;
      recipeNodes = {
        isEmpty: function() {
          return true;
        }
      };
      aRecipeRan = false;
      allRecipesProcessed = false;
      recipeNode = {};
      runTask = function() {
        var runNextRecipeCallback;
        taskIsRunning = true;
        recipeNodes = graph.recipeNodesTo(target);
        aRecipeRan = false;
        allRecipesProcessed = false;
        recipeNode = {};
        runNextRecipeCallback = function(ok, report) {
          var context;
          if (ok == null) {
            ok = true;
          }
          if (report == null) {
            report = {};
          }
          if (!ok) {
            console.error(stylize("===== " + report.target + " Task Failed =====", 'red'));
            console.error(stylize(report.message, 'red'));
            if (options.watch != null) {
              taskIsRunning = false;
              return;
            }
            process.exit(1);
          }
          if (!recipeNodes.isEmpty()) {
            if (recipeNode.name != null) {
              recipeNode.refreshOutputs(graph);
            }
            recipeNode = recipeNodes.shift();
            if (recipeNode.shouldRun(graph)) {
              context = runRecipeContext(graph, recipeNode, runNextRecipeCallback, options);
              recipeNode.run(context, options);
              return aRecipeRan = true;
            } else {
              return runNextRecipeCallback();
            }
          } else {
            allRecipesProcessed = true;
            if (!aRecipeRan && (options.verbose != null)) {
              console.error(stylize("cake: Nothing to be done for `" + target + "'.", 'yellow'));
            }
            if (options.watch != null) {
              console.log(stylize("task '" + target + "' finished", 'grey'));
            }
            return taskIsRunning = false;
          }
        };
        return runNextRecipeCallback();
      };
      if (options.watch != null) {
        fileSources = graph.fileSources(target).names();
        if (fileSources.length === 0) {
          console.error(stylize("cake: Nothing to watch for `" + target + "'", 'yellow'));
        }
        fileSources.forEach(function(file) {
          return fs.watchFile(file, {
            interval: 250
          }, function(curr, prev) {
            if (taskIsRunning) {
              return;
            }
            if (curr.mtime > prev.mtime) {
              console.log(stylize("! `" + file + "` Changed", 'green'));
              graph.refresh(file);
              return runTask();
            }
          });
        });
      }
      process.on('exit', function() {
        var tasksLeft;
        if (!allRecipesProcessed && !recipeNodes.isEmpty()) {
          tasksLeft = recipeNodes.pluck('name').join(',');
          return console.error(("\nError: task `" + recipeNode.name + "` did not complete.\n") + ("Tasks [" + tasksLeft + "] should have run, but did not.\n") + ("Task `" + recipeNode.name + "` should call this.finished() or this.failed(message).\n"));
        }
      });
      return runTask();
    });
  };
  runRecipeContext = function(graph, recipeNode, runNextRecipeCallback, options) {
    var execFn, failedFn, finishedFn;
    finishedFn = function() {
      return runNextRecipeCallback();
    };
    failedFn = function(message) {
      return runNextRecipeCallback(false, {
        target: recipeNode.name,
        message: message
      });
    };
    execFn = function(commands) {
      var runNextCommandCallback;
      if (!(commands.shift != null)) {
        commands = [commands];
      }
      runNextCommandCallback = function() {
        var command;
        if (commands.length > 0) {
          command = commands.shift();
          if (options.verbose != null) {
            console.log(stylize("$ " + command, 'grey'));
          }
          return exec(command, function(error, stdout, stderr) {
            if ((options.verbose != null) && stdout !== '') {
              console.log(stdout);
            }
            if (!(error != null)) {
              return runNextCommandCallback();
            } else {
              return failedFn(stderr);
            }
          });
        } else {
          return finishedFn();
        }
      };
      return runNextCommandCallback();
    };
    return {
      callback: runNextRecipeCallback,
      finished: finishedFn,
      failed: failedFn,
      prereqs: recipeNode.prereqs(graph).names(),
      modifiedPrereqs: recipeNode.modifiedPrereqs(graph).names(),
      exec: execFn
    };
  };
  stylize = function(str, style) {
    var styles;
    styles = {
      'bold': [1, 22],
      'italic': [3, 23],
      'underline': [4, 24],
      'cyan': [96, 39],
      'yellow': [33, 39],
      'green': [32, 39],
      'red': [31, 39],
      'grey': [90, 39],
      'green-hi': [92, 32]
    };
    return "\033[" + styles[style][0] + "m" + str + "\033[" + styles[style][1] + "m";
  };
}).call(this);
