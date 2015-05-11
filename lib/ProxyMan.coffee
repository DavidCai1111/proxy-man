http = require 'http'
util = require 'util'
events = require 'events'
url = require 'url'
extension = require './extension'

redirectRegex = /^30(1|2|7|8)$/;

ProxyMan = () ->
  @_proxyServer = null
  events.EventEmitter.call @

util.inherits ProxyMan, events.EventEmitter

ProxyMan.prototype.createProxy = (@targetUrl, @outerReq, @outerRes) ->
  ctx = @
  if @outerReq == undefined || @outerRes == undefined
    if @_proxyServer == null then @_proxyServer = http.createServer()
    @_proxyServer.on 'request', (req, res) ->
      ctx.outerReq = req
      ctx.outerRes = res
      ctx.pretreatment.call(ctx)
      ctx.sendRequest()
    @
  else
    @pretreatment()
    @sendRequest()

ProxyMan.prototype.listen = (port, callback) ->
  @_proxyServer.listen port, callback

ProxyMan.prototype.pretreatment = () ->
  @targetUrl = url.parse @targetUrl, true
  @outerReq.setHeader = extension.req.setHeader
  @outerReq.headers.host = @targetUrl.host

ProxyMan.prototype.sendRequest = () ->
  ctx = @
  @emit 'beforeReqSend', @outerReq
  _opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: @outerReq.method
    path: @targetUrl.path
    headers: @outerReq.headers

  _request = http.request _opt, (targetRes) ->
    buf = []

    targetRes.on 'data', (data) ->
      buf.push data
    targetRes.on 'end', () ->
      body = Buffer.concat(buf, buf.length).toString()

      #handle redirect
      if redirectRegex.test targetRes.statusCode
        unless ctx.targetUrl.href == targetRes.headers.location
          @targetUrl = targetRes.headers.location
          return ctx.sendRequest ctx.outerReq, ctx.outRes

      ctx.outerRes.statusCode = targetRes.statusCode
      ctx.outerRes.body = body
      ctx.emit 'beforeResGet', ctx.outerRes

      unless ctx.outerRes.headersSent
        for key, value of targetRes.headers
          unless ctx.outerRes.getHeader(key) == undefined
            ctx.outerRes.setHeader key, value

        ctx.outerRes.setHeader 'content-length', ctx.outerRes.body.length
        ctx.outerRes.writeHead ctx.outerRes.statusCode
        ctx.outerRes.write ctx.outerRes.body
        ctx.outerRes.end()
        ctx.close()

  _request.on 'error', (err) ->
    ctx.emit 'error', err

  _request.end()

ProxyMan.prototype.close = (callback) ->
  unless @_proxyServer == null
    @_proxyServer.close(callback)

exports = module.exports = ProxyMan