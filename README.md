# icing

`icing` adds dependency management and interactive building to CoffeeScript's `cake` 
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

`icing` introduces a new form of the `task` function that has four parameters:

    task target, description = '', prereqs = [], recipe = (->)

The `target` and `description` strings are unchanged from cake. `prereqs` is an
array of strings that can refer to three different kinds of prereqs:

1. Filenames. Filename strings are globbed, i.e. `src/\*.coffee`
2. Task completion. `task(target)` creates a prereq on the completion of a task.
3. Task outputs. `outputs(target)` uses the file outputs of another task as prereqs. 

`recipe` can be a simple callback or, when a task has outputs, it should be an object
that responds to the methods `recipe` and `outputs`. Like with Cakefiles these
methods will be passed the `options` array containing command-line options. Unlike 
Cakefiles, the `this` context of the methods contains useful callbacks and data.

`outputs`'s `this` context:

`recipe`'s `this` context:

* `exec(command)` - helper function for command line edecution that can take a 
   single string command or an array of commands. It will call the commands 
   one-by-one and upon successful completion of all commands will automatically 
   call the `finished` callback. Else it will call the `failed` callback.
* `finished()` - callback to signal successful completion of task
* `failed(msg)` - callback to signal unsuccessful completion of task
* `prereqs` - array of strings of prerequisites. Often used as inputs to commands
   executed. In this context prereqs have already been globbed so `['src/*.coffee']`
   could become `['src/a.coffee','src/b.coffee']`.
* `outputs` - array of strings resulting from calling the outputs method of the
  recipe object.
* `modifiedPrereqs` - if prereqs and outputs are both defined this is
  the list of files that have been modified more recently than their outputs.


