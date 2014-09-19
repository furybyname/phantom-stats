path = require 'path'
childProcess = require 'child_process'
phantomjs = require 'phantomjs'
binPath = phantomjs.path

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

    result = processHARFile har

    callback result
  )

exports.run = run
