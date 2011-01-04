{exec}      = require 'child_process'

option '-v','--verbose','Enable verbose output'

task 'test', 'Run icing tests', (options) ->
    args = []
    if options.verbose?
        args.push '--spec'
    command = "vows #{args.join ' '} spec/rules.vows.coffee"
    if options.verbose?
        console.log "$ #{command}"
    exec command,
        (err, stdout, stderr) ->
            if not err
                console.log stdout
            else
                console.error stderr

task 'docs', 'Generate docco documentation', (options) ->
   command = "docco src/*" 
   if options.verbose?
       console.log "$ #{command}"
    exec command,
        (err, stdout, stderr) ->
            if err
                console.error stderr

task 'all', 'Test and Document', (options) ->
    invoke 'test'
    invoke 'docs'
