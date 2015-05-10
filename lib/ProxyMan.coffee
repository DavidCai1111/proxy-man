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
  console.log 'listen'
  ctx = this
  @proxyServer.listen port, '127.0.0.1', callback

  @targetUrl = url.parse @targetUrl, true
  @outerReq.setHeader = extension.req.setHeader
  @outerReq.headers.host = ctx.targetUrl.host

  ctx.emit 'beforeReqSend', @outerReq
  ctx.sendRequest @outerReq, @outerRes

ProxyMan.prototype.sendRequest = (req, res) ->
  console.log 'begin to sent!'
  ctx = this
  _opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: @outerReq.method
    path: @targetUrl.path
    headers: @outerReq.headers

  console.dir _opt

  _request = http.request _opt, (targetRes) ->
    buf = ''

    targetRes.on 'data', (d) ->
      buf += d
    targetRes.on 'end', () ->
      console.log '--------------------'
      console.log "status code #{targetRes.statusCode}"
      console.dir targetRes.headers
      console.log '--------------------'
      ctx.outerRes.end buf

  _request.on 'error', (err) ->
    console.error err

  _request.end()

ProxyMan.prototype.close = (callback) ->
  @proxyServer.close(callback)

exports = module.exports = ProxyMan