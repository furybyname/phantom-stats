waitFor = (testFx, onReady, timeOutMillis) ->
  maxtimeOutMillis = (if timeOutMillis then timeOutMillis else 3000) #< Default Max Timout is 3s
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

if system.args.length is 1
  console.log 'Usage: netsniff.coffee <some URL>'
  phantom.exit 1
else
  page.address = system.args[1]
  page.resources = []

  page.onLoadStarted = ->
    page.startTime = new Date()

  page.onResourceRequested = (req) ->
    page.resources[req.id] =
      request: req
      startReply: null
      endReply: null

  page.onResourceReceived = (res) ->
    if res.stage is 'start'
      page.resources[res.id].startReply = res
    if res.stage is 'end'
      page.resources[res.id].endReply = res

  page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36'
  #page.onResourceRequested = (request) -> # no-op to wait for full page load
  #page.onResourceReceived = (response) -> # no-op to wait for full page load
  page.open page.address, (status) ->
    if status isnt 'success'
      console.log 'FAIL to load the address'
      phantom.exit(1)
    else
      now = new Date().valueOf()
      waitFor(-> new Date().valueOf() - 5000 > now
        ,
        ->
          page.endTime = new Date()
          page.title = page.evaluate ->
            document.title

          har = createHAR page.address, page.title, page.startTime, page.resources
          console.log JSON.stringify har
          phantom.exit()
        , 8000
      )

