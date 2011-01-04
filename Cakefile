require './src/icing'

option '-s','--spec','Run vows with spec option'

task 'version', -> console.log '0.1'

task 'test', ['spec/*'], (options) ->
    args = []
    if options.spec?
        args.push '--spec'
    command = "vows #{args.join ' '} #{this.prereqs.join(' ')}"
    this.exec command

task 'docs', 'Generate docco documentation', ['src/*'], (options) ->
   this.exec "docco #{this.prereqs.join(' ')}"

task 'all', 'Test and Document', ['test','docs'], (options) -> this.finished()
