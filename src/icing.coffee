# **icing** adds dependency management to Cakefiles by extending and
# slightly modifying cake's "task" function. Add icing to your Cakefiles by adding
# a single line:
#
#     require 'icing'
#
# Traditional cake tasks can still be defined as:
#
#     task 'name', 'desc', (options) ->
#
# With icing, tasks can also be defined with a prerequisite/dependency array:
#
#     task 'name', 'desc', [prereqs], recipe
#
# *prereqs* is an array of task or file names this task depends on. If a prereq is a
# task name it **must** be defined prior to being used as a prereq.
#
# *recipe* can be a plain-old function like with traditional Cakefiles or it
# can be an object which responds to the methods *exec* for running the rule and
# *outputs* for reporting an array of files output from the task. By specifying
# outputs the dependency graph can more intelligently decide whether or not a given
# task needs to run.
#
#     recipe = (options) ->
#
#     recipe = 
#         exec:     (options) ->
#         outputs:  (options) -> [filenames]
#
# **_invoke_ is deprecated with icing.** The only major incompatibility with plain
# Cakefiles is that the the *invoke* command is remapped to no-op. This is because
# *invoke* is handled automatically by icing's dependency management. The following
# traditional Cakefile:
#
#     task 'B', 'run B', -> console.log 'B'
#     task 'A', 'run A', ->
#         invoke 'B'
#         console.log 'A'
# 
# Can be rewritten with icing as:
#
#     require 'icing'
#     task 'B', 'run B', -> console.log 'B'
#     task 'A', 'run A', ['B'], -> console.log 'A'
#
# Recipes' *this* context provides special 

# ### Options
option '-v',    '--verbose',    'Display progress as tasks are executed'
option '-w',    '--watch',      'Monitor files for changes and automatically rebuild'

# ### Dependencies and Globals
{ RuleGraph, Rule, RecipeNode } = require './rules'
{ exec }                        = require 'child_process'
fs                              = require 'fs'

# Preserve a reference to cake's task, we'll be using it.
cakeTask = global.task

graph = new RuleGraph

global.task = (target, description, prereqs=undefined, recipe=undefined) ->
    if not prereqs? and not recipe?
        recipe = description
        description = target
        prereqs = []

    if not recipe?
        if description.shift?
            recipe = prereqs
            prereqs = description
            description = target
        else
            recipe = prereqs
            prereqs = []

    # Add a rule to the rule graph.
    graph.rule new Rule target, prereqs, recipe

    # Bootstrap into cake's task book keeping!
    cakeTask target, description, (options) ->
        # Runtime State
        taskIsRunning = false
        recipeNodes = { isEmpty: -> true }
        aRecipeRan = false
        allRecipesProcessed = false
        recipeNode = {}


        runTask = ->
            taskIsRunning = true
            recipeNodes = graph.recipeNodesTo target
            aRecipeRan = false
            allRecipesProcessed = false
            recipeNode = {}
            runNextRecipeCallback = ( ok = true, report = {} ) ->
                if not ok
                    console.error stylize "===== #{report.target} Task Failed =====", 'red'
                    console.error stylize report.message, 'red'
                    if options.watch?
                        taskIsRunning = false
                        return
                    process.exit 1

                if not recipeNodes.isEmpty()
                    if recipeNode.name?
                        recipeNode.refreshOutputs graph

                    recipeNode = recipeNodes.shift()

                    if recipeNode.shouldRun graph
                        context = runRecipeContext graph, recipeNode, runNextRecipeCallback, options
                        recipeNode.run context, options
                        aRecipeRan = true
                    else
                        do runNextRecipeCallback
                else
                    allRecipesProcessed = true
                    if not aRecipeRan and options.verbose?
                        # Homage
                        console.error stylize "cake: Nothing to be done for `#{target}'.", 'yellow'
                    taskIsRunning = false
            do runNextRecipeCallback

        if options.watch?
            fileSources = graph.fileSources(target).names()
            if fileSources.length == 0
                console.error stylize "cake: Nothing to watch for `#{target}'", 'yellow'

            fileSources.forEach (file) ->
                fs.watchFile file, {interval:250}, (curr,prev) ->
                    if taskIsRunning then return
                    if curr.mtime > prev.mtime
                        console.log stylize "! `#{file}` Changed", 'green'
                        graph.refresh file
                        do runTask

        process.on 'exit', ->
            if not allRecipesProcessed and not recipeNodes.isEmpty()
                tasksLeft = recipeNodes.pluck('name').join(',')
                console.error  "\nError: task `#{recipeNode.name}` did not complete.\n" +
                               "Tasks [#{tasksLeft}] should have run, but did not.\n" +
                               "Task `#{recipeNode.name}` should call this.finished() or this.failed(message).\n"

        do runTask

#### Helpers

# Set-up the context that a recipe exec is run in
runRecipeContext = (graph, recipeNode,  runNextRecipeCallback, options) ->

    finishedFn = -> do runNextRecipeCallback

    failedFn = (message) -> runNextRecipeCallback false, { target: recipeNode.name, message: message }

    execFn = (commands) ->
        if not commands.shift?
            commands = [commands]

        runNextCommandCallback = ->
            if commands.length > 0
                command = do commands.shift
                if options.verbose?
                    console.log stylize "$ #{command}", 'grey'
                exec command, (error, stdout, stderr) ->
                    if options.verbose? and stdout != ''
                        console.log stdout
                    if not error?
                        runNextCommandCallback()
                    else
                        failedFn()
            else
                finishedFn()
        
        do runNextCommandCallback

    return {
        callback:           runNextRecipeCallback
        finished:           finishedFn
        failed:             failedFn
        prereqs:            recipeNode.prereqs(graph).names()
        modifiedPrereqs:    recipeNode.modifiedPrereqs(graph).names()
        exec:               execFn
    }

# Stylize function courtesy of vows.js
stylize = (str, style) ->
    styles =
        'bold'      : [1,  22]
        'italic'    : [3,  23]
        'underline' : [4,  24]
        'cyan'      : [96, 39]
        'yellow'    : [33, 39]
        'green'     : [32, 39]
        'red'       : [31, 39]
        'grey'      : [90, 39]
        'green-hi'  : [92, 32]
    "\033[#{styles[style][0]}m#{str}\033[#{styles[style][1]}m"
