http = require 'http'
events = require 'events'
url = require 'url'

class ProxyMan
  proxyServer = null
  targetUrl = ''

  create: (url) ->
    this.targetUrl = url
    this

  listen: (port) ->
    ctx = this
    proxyServer = http.createServer (rawReq, rawRes) ->
      console.log "raw url : #{ctx.targetUrl}"
      _url = url.parse ctx.targetUrl
      console.dir _url
      _opt =
        hostname: _url.hostname
        port : _url.port
        method: rawReq.method
        path: _url.path
        headers: rawReq.headers

      console.dir _opt

      req = http.request _opt, (proxyRes) ->
        buf = ''
        proxyRes.on 'data', (d) ->
          buf += d
        .on 'end', () ->
          rawRes.writeHead 200, {'Content-Type': 'text/pain'}
          rawRes.end(buf)
        .on 'error', (err) ->
          console.log 'fuck'
          console.error err

      req.end()
    .listen port, '127.0.0.1'
    console.log 'listened at port %s', port

exports = module.exports = ProxyMan



