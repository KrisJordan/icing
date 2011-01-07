require './src/icing'
_ = require 'underscore'

option '-s','--spec','Run vows with spec option'

task 'version', -> console.log '0.1'

task 'test', ['spec/*','src/*'], (options) ->
        args = []
        if options.spec?
            args.push '--spec'
        tests = _(this.modifiedPrereqs).filter (prereq) -> prereq.match /^spec/
        src = _(this.modifiedPrereqs).filter (prereq) -> prereq.match /^src/
        command = "vows #{args.join ' '} #{tests.join(' ')}"
        this.exec [
            command
        ]

task 'compile', ['task(test)','src/*'],
    recipe: -> this.exec "coffee -c -o lib/ #{this.modifiedPrereqs.join(' ')}"
    outputs: ->
        for prereq in this.filePrereqs
            prereq.replace /src\/(.*).coffee/,"lib/$1.js"

task 'docs', 'Generate docco documentation', ['src/*'],
    recipe: (options) ->
        this.exec "docco #{this.modifiedPrereqs.join(' ')}"
    outputs: ->
        for prereq in this.filePrereqs
            prereq.replace /src\/(.*).coffee/,"docs/$1.html"

task 'all', 'Test and Document', ['task(compile)','task(docs)'], (options) -> this.finished()

task 'clean', 'Remove Generated Files', [], ->
    this.exec [
        "rm -rf docs/* lib/*"
    ]
