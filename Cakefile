require './src/icing'

option '-s','--spec','Run vows with spec option'

task 'test', (options) ->
    args = []
    if options.spec?
        args.push '--spec'
    command = "vows #{args.join ' '} spec/*"
    this.exec command

task 'docs', 'Generate docco documentation', (options) ->
   this.exec "docco src/*"

task 'all', 'Test and Document', ['test','docs'], (options) -> this.finished()
