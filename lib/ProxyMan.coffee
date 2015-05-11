http = require 'http'
util = require 'util'
events = require 'events'
url = require 'url'
extension = require './extension'

ProxyMan = () ->
  @targetUrl = ''
  @proxyServer = http.createServer()
  events.EventEmitter.call this

util.inherits ProxyMan, events.EventEmitter

ProxyMan.prototype.createProxy = (@targetUrl, @outerReq, @outerRes) ->

ProxyMan.prototype.listen = (port, callback) ->
  ctx = this
  @proxyServer.listen port, callback

  @targetUrl = url.parse @targetUrl, true
  @outerReq.setHeader = extension.req.setHeader
  @outerReq.headers.host = ctx.targetUrl.host

  ctx.emit 'beforeReqSend', @outerReq
  ctx.sendRequest @outerReq, @outerRes

ProxyMan.prototype.sendRequest = (req, res) ->
  console.log '---------res---------'
  console.dir res.headers
  console.log '---------res---------'
  ctx = this
  _opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: req.method
    path: @targetUrl.path
    headers: req.headers

  console.dir _opt

  _request = http.request _opt, (targetRes) ->
    buf = []

    targetRes.on 'data', (data) ->
      buf.push data
    targetRes.on 'end', () ->
      body = Buffer.concat(buf, buf.length).toString()
      ctx.emit 'beforeResGet', targetRes
      for key, value of targetRes.headers
        console.log "set #{key} as #{value}"
        res.setHeader key, value

      res.writeHead targetRes.statusCode

      console.log '--------------------'
      console.log "status code #{res.statusCode}"
      console.log res.headers
      console.log body
      console.log '--------------------'

      res.end body

  _request.on 'error', (err) ->
    console.error err

  _request.end()

ProxyMan.prototype.close = (callback) ->
  @proxyServer.close(callback)

exports = module.exports = ProxyMan