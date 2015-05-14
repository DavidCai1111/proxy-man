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
  if @outerReq == undefined || @outerRes == undefined
    if @_proxyServer == null then @_proxyServer = http.createServer()
    @_proxyServer.on 'request', ((req, res) ->
      @outerReq = req
      @outerRes = res
      @pretreatment.call(@)
      @sendRequest()
    ).bind @
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
  @emit 'beforeReqSend', @outerReq
  _opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: @outerReq.method
    path: @targetUrl.path
    headers: @outerReq.headers

  _request = http.request _opt, ( (targetRes) ->
    buf = []

    targetRes.on 'data', (data) ->
      buf.push data
    targetRes.on 'end', ( () ->
      body = Buffer.concat(buf, buf.length).toString()
      #handle redirect
      if redirectRegex.test targetRes.statusCode
        unless @targetUrl.href == targetRes.headers.location
          @targetUrl = targetRes.headers.location
          return @sendRequest @outerReq, @outRes

      @outerRes.statusCode = targetRes.statusCode
      @outerRes.body = body
      @emit 'beforeResGet', @outerRes

      unless @outerRes.headersSent
        for key, value of targetRes.headers
          unless @outerRes.getHeader(key) == undefined
            @outerRes.setHeader key, value

        @outerRes.setHeader 'content-length', @outerRes.body.length
        @outerRes.writeHead @outerRes.statusCode
        @outerRes.write @outerRes.body
        @outerRes.end()
        @close()

    ).bind @
  ).bind @

  _request.on 'error', ( (err) ->
    @emit 'error', err
  ).bind @

  _request.end()

ProxyMan.prototype.close = (callback) ->
  unless @_proxyServer == null
    @_proxyServer.close(callback)

exports = module.exports = ProxyMan