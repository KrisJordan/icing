{exec}      = require 'child_process'

option '-v','--verbose','Enable verbose output'

task 'test', 'Run icing tests', (options) ->
    args = []
    if options.verbose?
        args.push '--spec'
    command = "vows #{args.join ' '} spec/*"
    if options.verbose?
        console.log "$ #{command}"
    exec command,
        (err, stdout, stderr) ->
            if not err
                console.log stdout
            else
                console.error stderr
