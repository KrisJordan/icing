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

# ### Options
option '-v','--verbose','Display progress as tasks are executed'
# coming soon - option '-w','--watch','Monitor files for changes and automatically rebuild'

# ### Dependencies and Globals
{ RuleGraph, Rule, RecipeNode } = require './rules'
# Preserve a reference to cake's task, we'll be using it.
cakeTask = global.task

graph = new RuleGraph

global.task = (target, description, prereqs, recipe=undefined) ->
    if not recipe?
        recipe = prereqs
        prereqs = []

    # Add a rule to the rule graph.
    graph.rule new Rule target, prereqs, recipe

    # Bootstrap into cake's task book keeping
    cakeTask target, description, (options) ->
        recipeNodes = graph.recipeNodesTo target
        aRecipeRan = false
        runNextRecipeCallback = ( ok = true, report = {} ) ->
            if not ok
                console.error "===== #{report.rule.target} Failed ====="
                console.error report.message
                process.exit 1

            if not recipeNodes.isEmpty()
                recipeNode = recipeNodes.shift()

                if recipeNode.shouldRun graph
                    context = runRecipeContext graph, recipeNode, runNextRecipeCallback, options
                    recipeNode.run context, options
                    aRecipeRan = true
                else
                    do runNextRecipeCallback
            else
                if not aRecipeRan
                    # Homage to make
                    console.log "cake: Nothing to be done for `#{target}'."

        do runNextRecipeCallback

#### Helpers

# Set-up the context that a recipe exec is run in.
runRecipeContext = (graph, recipeNode,  runNextRecipeCallback, options) ->

    finishedFn = -> do runNextRecipeCallback

    failedFn = (message) -> runNextRecipeCallback false, { target: recipeNode.name, message: message }

    execFn = (commands) ->
        if not commands instanceof Array
            commands = [commands]

        runNextCommandCallback = ->
            if commands.length > 0
                command = do commands.shift
                if options.verbose?
                    console.log "$ #{command}"
                exec command, (error, stdout, stderr) ->
                    if options.verbose? and stdout != ''
                        console.log stdout
                    if not error?
                        runNextCommandCallback()
                    else
                        failedFn()
            else
                finishedFn()

    return {
        callback:   runNextRecipeCallback
        finished:   finishedFn
        failed:     failedFn
        prereqs:    recipeNode.prereqs graph
    }
