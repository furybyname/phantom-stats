path = require 'path'
childProcess = require 'child_process'
phantomjs = require 'phantomjs'
binPath = phantomjs.path

###if process.argv.length < 3
  console.log 'Usage: yslownetsniff.coffee <some URL>'
  process.exit(1)

mainUrl = process.argv[2]###

processHARFile = (data) ->
  parsed = JSON.parse(data)
  processor = require('har-summary')
  return processor.run(parsed, {})

run = (url, callback) ->
  childArgs = [
    path.join(__dirname, 'netsniff.js'),
    url
  ]

  childProcess.execFile(binPath, childArgs, (err, stdOut, stdErr) ->

    har = stdOut
    console.log har
    return
    result = processHARFile har

    callback result
  )

#run(mainUrl, (result) -> console.log(result))

exports.run = run
