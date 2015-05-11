http = require 'http'
util = require 'util'
events = require 'events'
url = require 'url'
extension = require './extension'

redirectRegex = /^30(1|2|7|8)$/;

ProxyMan = () ->
  @proxyServer = http.createServer()
  events.EventEmitter.call this

util.inherits ProxyMan, events.EventEmitter

ProxyMan.prototype.createProxy = (@targetUrl, @outerReq, @outerRes) ->

ProxyMan.prototype.listen = (port, callback) ->
  @proxyServer.listen port, callback

  @targetUrl = url.parse @targetUrl, true
  @outerReq.setHeader = extension.req.setHeader
  @outerReq.headers.host = @targetUrl.host

  @emit 'beforeReqSend', @outerReq
  @sendRequest @outerReq, @outerRes

ProxyMan.prototype.sendRequest = (req, res) ->
  ctx = @
  _opt =
    hostname: @targetUrl.hostname
    port: @targetUrl.port
    method: req.method
    path: @targetUrl.path
    headers: req.headers

  _request = http.request _opt, (targetRes) ->
    buf = []

    targetRes.on 'data', (data) ->
      buf.push data
    targetRes.on 'end', () ->
      body = Buffer.concat(buf, buf.length).toString()

      #handle redirect
      if redirectRegex.test targetRes.statusCode
        unless ctx.targetUrl.href == targetRes.headers.location
          console.log ctx.targetUrl.href
          console.log targetRes.headers.location
          @targetUrl = targetRes.headers.location
          return ctx.sendRequest ctx.outerReq, ctx.outRes

      res.statusCode = targetRes.statusCode
      res.body = body
      ctx.emit 'beforeResGet', res

      unless res.headersSent
        for key, value of targetRes.headers
          unless res.getHeader(key) == undefined
            res.setHeader key, value

        res.setHeader 'content-length', res.body.length
        res.writeHead res.statusCode
        res.write res.body
        res.end()

  _request.on 'error', (err) ->
    ctx.emit 'error', err

  _request.end()

ProxyMan.prototype.close = (callback) ->
  @proxyServer.close(callback)

exports = module.exports = ProxyMan