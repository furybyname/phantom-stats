path = require 'path'
childProcess = require 'child_process'
phantomjs = require 'phantomjs'
binPath = phantomjs.path
fs = require('fs')

processHARFile = (data, config) ->
  parsed = JSON.parse(data)
  processor = require('har-summary')
  return processor.run(parsed, config)

run = (url, config, callback) ->
  childArgs = [
    path.join(__dirname, 'netsniff.js'),
    url
  ]

  childProcess.execFile(binPath, childArgs, (err, stdOut, stdErr) ->

    fs.readFile("tmp.json", (err, data) ->
      har = data

      result = processHARFile har, config

      try
        fs.unlink "./tmp.json"
      catch
        console.log "Failed to delete tmp file tmp.json"

      callback result
    )
  )

exports.run = run
