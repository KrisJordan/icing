# icing

`icing` adds **dependency management** and **interactive building** to CoffeeScript's `cake` 
command and Cakefiles.

## Installation

Install with npm: `npm install icing`

To add icing to a Cakefile add include the line:

    require 'icing'

There are two significant ways icing breaks backwards compatibility with pre-existing
Cakefiles.

1. Using the `invoke` function to call other tasks is replaced by dependencies.
2. Task should now end by calling this.finished() or
   this.failed('Error message') to signify the completion of a task.

## Example Cakefile

    task 'js:coffee', 'Compile Coffee Script', ['src/*.coffee'],
        outputs: -> 
            for file in this.filePrereqs
                file.replace /src\/(.*)\.coffee/, 'lib/$1.js'
        recipe: -> 
            this.exec "coffee -c -o lib/ #{this.modifiedPrereqs.join(' ')}"

    task 'js:run', 'Run all compiled scripts', ['outputs(js:coffee)'], 
        outputs: ->
            for file in this.filePrereqs
                "output/#{file.replace /\//, '_'}"
        recipe: ->
            commands = for file in this.modifiedPrereqs
                "node #{file} > output/#{file.replace '/', '_'}"
            commands = ['mkdir -p output/'].concat commands
            this.exec commands

    task 'all', 'Run all tasks', ['task(js:run)'], ->
        console.log 'Done.'
        this.finished()

## Built-in Command Line Options

    -w, --watch,  Interactively build to target as source files change
    -v, --verbose Enable verbose output mode

## API

`icing` introduces a new form of the `task` function that has four parameters:

    task target, description = '', prereqs = [ ], recipe

The `target` and `description` strings are unchanged from cake. `prereqs` is an
array of strings that can refer to three different kinds of prereqs:

1. Filenames. Filename strings are globbed, i.e. `src/*.coffee`
2. Task completion. `task(target)` creates a prereq on the completion of a task.
3. Task outputs. `outputs(target)` uses the file outputs of another task as prereqs. 

`recipe` should be an object that responds to the methods `recipe` and `outputs`. 
When `recipe` is just a function, as it is in traditional Cakefiles, it is turned
into an object whose `recipe` method is that function and whose `outputs` returns [].
Like with Cakefiles these methods will be passed the `options` array containing 
command-line options. Unlike Cakefiles, the `this` context of the methods contains 
callbacks and data.

`outputs` method's `this` context contains:

* `filePrereqs` - array of filenames, post-globbing, that are direct prereqs to the
  rule. This array is often mapped to an array of outputs.
* `recipe` - the object `outputs` and `recipe` methods are defined on
* `prereqs` - array of unprocessed prereqs
* `target` - the name of the task

`recipe` method's `this` context contains:

* `exec(command)` - helper method for command line edecution that can take a 
   single string command or an array of commands. It will call the commands 
   one-by-one and upon successful completion of all commands will automatically 
   call the `finished` callback. Else it will call the `failed` callback.
* `finished()` - callback to signal successful completion of task
* `failed(msg)` - callback to signal unsuccessful completion of task
* `filePrereqs` - array of strings of prerequisites. Often used as inputs to commands
   executed. In this context prereqs have already been globbed so `['src/*.coffee']`
   could become `['src/a.coffee','src/b.coffee']`.
* `outputs` - array of strings resulting from calling the outputs method of the
  recipe object.
* `modifiedPrereqs` - if prereqs and outputs are both defined this is
  the list of files that have been modified more recently than their outputs.

