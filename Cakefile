require './src/icing'
{exec}      = require 'child_process'

task 'test', 'Run icing tests', (options) ->
    args = []
    if options.verbose?
        args.push '--spec'
    command = "vows #{args.join ' '} spec/*"
    if options.verbose?
        console.log "$ #{command}"
    exec command,
        (err, stdout, stderr) =>
            if not err
                console.log stdout
                console.log 'done test'
                this.finished()
            else
                console.error stderr

task 'docs', 'Generate docco documentation', (options) ->
   command = "docco src/*"
   if options.verbose?
       console.log "$ #{command}"
    exec command,
        (err, stdout, stderr) =>
            if err
                console.error stderr
            else
                console.log 'done docs'
                this.finished()

task 'all', 'Test and Document', ['docs','test'], (options) -> this.finished()
