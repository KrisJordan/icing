require './src/icing'

option '-s','--spec','Run vows with spec option'

task 'version', -> console.log '0.1'

task 'test', ['spec/*'], (options) ->
        args = []
        if options.spec?
            args.push '--spec'
        command = "vows #{args.join ' '} #{this.prereqs.join(' ')}"
        this.exec [
            command
        ]

task 'docs', 'Generate docco documentation', ['src/*'],
    exec: (options) ->
        this.exec "docco #{this.modifiedPrereqs.join(' ')}"
    outputs: ->
        for prereq in this.prereqs
            prereq.replace /src\/(.*).coffee/,"docs/$1.html"

task 'all', 'Test and Document', ['test','docs'], (options) -> this.finished()

task 'clean', 'Remove Generated Files', [], ->
    this.exec [
        "rm -rf docs/*"
    ]
