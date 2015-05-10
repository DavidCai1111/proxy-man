http = require 'http'
util = require 'util'
events = require 'events'
url = require 'url'

ProxyMan = () ->
  events.EventEmitter.call this
  @proxyServer = null
  @targetUrl = ''

util.inherits ProxyMan, events.EventEmitter

ProxyMan.prototype.target = (@targetUrl) ->

ProxyMan.prototype.listen = (port, callback) ->
  ctx = this
  @proxyServer = http.createServer (rawReq, rawRes) ->
    ctx.emit 'proxyReq'
    _url = url.parse ctx.targetUrl, true

    console.log '--------------------'
    console.dir _url
    console.log '--------------------'

    rawReq.headers.host = _url.host
    _opt =
      hostname: _url.hostname
      port: _url.port
      method: rawReq.method
      path: _url.path
      headers: rawReq.headers

    console.log '--------------------'
    console.dir _opt
    console.log '--------------------'

    req = http.request _opt, (targetRes) ->
      buf = ''
      targetRes.on 'data', (d) ->
        buf += d
      .on 'end', () ->

        console.log '--------------------'
        console.log "status code #{targetRes.statusCode}"
        console.dir targetRes.headers
        console.log '--------------------'

        rawRes.end(buf)
      .on 'error', (err) ->
        console.error err

    req.end()
  .listen port, '127.0.0.1', callback

ProxyMan.prototype.close = (callback) ->
  @proxyServer.close(callback)

exports = module.exports = ProxyMan