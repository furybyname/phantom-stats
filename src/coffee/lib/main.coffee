path = require 'path'
childProcess = require 'child_process'
phantomjs = require 'phantomjs'
binPath = phantomjs.path
fs = require('fs')
sanitize = require('sanitize-filename')
processHARFile = (data, config) ->
  parsed = JSON.parse(data)
  processor = require('har-summary')
  return processor.run(parsed, config)

run = (url, config, callback, device = 'mobile') ->
  filename = sanitize(url).replace(/\./g, '') + '.json'

  console.log 'device: ' + device
  childArgs = [
    '--disk-cache=false',
    '--max-disk-cache-size=0',
    path.join(__dirname, 'netsniff.js'),
    url,
    filename,
    device
  ]

  childProcess.execFile(binPath, childArgs, (err, stdOut, stdErr) ->
    fs.readFile(filename, (err, data) ->
      har = data

      result = processHARFile har, config

      try
        fs.unlink(filename, ->
          callback result
        )
      catch
        console.log "Failed to delete tmp file tmp.json"
        callback result
    )
  )

exports.run = run
