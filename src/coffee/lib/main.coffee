path = require 'path'
childProcess = require 'child_process'
phantomjs = require 'phantomjs'
binPath = phantomjs.path
fs = require('fs')
sanitize = require('sanitize-filename')

processHARFile = (data, config) ->
  if not data
    console.log 'no data'

  parsed = JSON.parse(data)
  processor = require('har-summary')
  return processor.run(parsed, config)

run = (url, config, callback, device = 'mobile') ->
  filename = sanitize(url).replace(/\./g, '') + ".#{device}.json"

  childArgs = [
    '--disk-cache=false',
    '--max-disk-cache-size=0',
    path.join(__dirname, 'netsniff.js'),
    url,
    filename,
    device
  ]

  childProcess.execFile(binPath, childArgs, (err, stdOut, stdErr) ->

    if not fs.existsSync(filename)
      console.log "file does not exist: #{filename}"

    fs.readFile(filename, (err, data) ->
      console.log 'file: ' + filename
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
