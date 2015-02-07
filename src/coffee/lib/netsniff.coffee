getUserAgent = (device) ->
  agents =
    desktop : 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36'
    mobile  : 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7'
    tablet  : 'Mozilla/5.0 (Linux; Android 4.4.2; Nexus 7 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.59 Safari/537.36'

  agents[device] or agents['desktop']

waitFor = (testFx, onReady, timeOutMillis) ->
  maxtimeOutMillis = (if timeOutMillis then timeOutMillis else 3000)
  start = new Date().getTime()
  condition = false
  interval = setInterval(->
    if (new Date().getTime() - start < maxtimeOutMillis) and not condition

      # If not time-out yet and condition not yet fulfilled
      condition = ((if typeof (testFx) is "string" then eval(testFx) else testFx())) #< defensive code
    else
      unless condition

        # If condition still not fulfilled (timeout but condition is 'false')
        phantom.exit 1
      else

        # Condition fulfilled (timeout and/or condition is 'true')
        (if typeof (onReady) is "string" then eval(onReady) else onReady()) #< Do what it's supposed to do once the condition is fulfilled
        clearInterval interval #< Stop this interval
    return
  , 250) #< repeat check every 250ms
  return

total = 0
retry = 0
doWait = (p, d, fname) ->

  if total > 0 and retry < 3
    retry++
    return setTimeout(->
      doWait(p,d,fname)

    , 2000
    )
  now = new Date().valueOf()

  p.endTime = new Date()

  p.title = p.evaluate ->
    document.title

  har = createHAR p.address, p.title, p.startTime, p.resources
  fs = require('fs')

  try
    filePath = fname
    fs.write(filePath, JSON.stringify(har), "w")
  catch e
    console.log e
    phantom.exit()

  phantom.exit()

if not Date::toISOString
  Date::toISOString = ->
    pad = (n) ->
      if n < 10 then '0' + n else n
    ms = (n) ->
      if n < 10 then '00' + n else (if n < 100 then '0' + n else n)
    @getFullYear() + '-' +
    pad(@getMonth() + 1) + '-' +
    pad(@getDate()) + 'T' +
    pad(@getHours()) + ':' +
    pad(@getMinutes()) + ':' +
    pad(@getSeconds()) + '.' +
    ms(@getMilliseconds()) + 'Z'

createHAR = (address, title, startTime, resources) ->
  entries = []

  resources.forEach (resource) ->
    request = resource.request
    startReply = resource.startReply
    endReply = resource.endReply

    if not request or not startReply or not endReply
      return

    entries.push
      startedDateTime: request.time.toISOString()
      time: endReply.time - request.time
      request:
        method: request.method
        url: request.url
        httpVersion: 'HTTP/1.1'
        cookies: []
        headers: request.headers
        queryString: []
        headersSize: -1
        bodySize: -1

      response:
        status: endReply.status
        statusText: endReply.statusText
        httpVersion: 'HTTP/1.1'
        cookies: []
        headers: endReply.headers
        redirectURL: ''
        headersSize: -1
        bodySize: startReply.bodySize
        content:
          size: startReply.bodySize
          mimeType: endReply.contentType

      cache: {}
      timings:
        blocked: 0
        dns: -1
        connect: -1
        send: 0
        wait: startReply.time - request.time
        receive: endReply.time - startReply.time
        ssl: -1
      pageref: address

  log:
    version: '1.2'
    creator:
      name: 'PhantomJS'
      version: phantom.version.major + '.' + phantom.version.minor + '.' + phantom.version.patch

    pages: [
      startedDateTime: startTime.toISOString()
      id: address
      title: title
      pageTimings:
        onLoad: page.endTime - page.startTime
    ]
    entries: entries

page = require('webpage').create()
system = require 'system'

if system.args.length < 3
  console.log 'Usage: netsniff.coffee <some URL> <filename> [<device>]'
  phantom.exit 1
else
  try
    page.address = system.args[1]
    page.resources = []

    filename = system.args[2]

    page.onLoadStarted = ->
      page.startTime = new Date()

    page.onResourceRequested = (req) ->
      total++
      page.resources[req.id] =
        request: req
        startReply: null
        endReply: null

    page.onResourceReceived = (res) ->
      if res.stage is 'start'

        page.resources[res.id].startReply = res
      if res.stage is 'end'
        total--
        page.resources[res.id].endReply = res

    device = if system.args.length == 4 then system.args[3] else 'mobile'

    page.settings.userAgent = getUserAgent(device)

    page.open page.address, (status) ->
      if status isnt 'success'
        console.log 'FAIL to load the address'
        phantom.exit(1)
      else

        setTimeout(-> doWait(page, document, filename)
          ,
          1500)


  catch e
    phantom.exit(1)



