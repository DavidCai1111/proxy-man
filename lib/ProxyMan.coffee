http = require 'http'
util = require 'util'
events = require 'events'
url = require 'url'
extension = require './extension'

redirectRegex = /^30(1|2|7|8)$/;

ProxyMan = () ->
  @proxyServer = null
  events.EventEmitter.call @

util.inherits ProxyMan, events.EventEmitter

ProxyMan.prototype.createProxy = (@targetUrl, @outerReq, @outerRes) ->
  if @outerReq is undefined or @outerRes is undefined
    if @proxyServer is null then @proxyServer = http.createServer()
    @proxyServer.on 'request', (req, res) =>
      @outerReq = req
      @outerRes = res
      @pretreatment()
      @sendRequest()
    @
  else
    @pretreatment()
    @sendRequest()

ProxyMan.prototype.listen = (port, callback) ->
  @proxyServer.listen port, callback

ProxyMan.prototype.pretreatment = () ->
  @targetUrl = url.parse @targetUrl, true
  @outerReq.setHeader = extension.req.setHeader
  @outerReq.headers.host = @targetUrl.host

ProxyMan.prototype.sendRequest = () ->
  @emit 'beforeReqSend', @outerReq
  opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: @outerReq.method
    path: @targetUrl.path
    headers: @outerReq.headers

  request = http.request opt, (targetRes) =>
    buf = []

    targetRes.on 'data', (data) -> buf.push data

    targetRes.on 'end', () =>
      body = Buffer.concat(buf, buf.length).toString()
      #redirect
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

  request.on 'error', (err) => @emit 'error', err

  request.end()

ProxyMan.prototype.close = (callback) ->
  unless @proxyServer == null
    @proxyServer.close callback

exports = module.exports = ProxyMan