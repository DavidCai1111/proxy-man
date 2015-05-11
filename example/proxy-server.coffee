http = require 'http'
ProxyMan = require '../index'

proxy = new ProxyMan()
proxy.createProxy('http://localhost:9091').listen 8081

proxy.on 'beforeReqSend', (req) ->
  req.setHeader 'X-Special-Proxy-Header', 'foobar'

proxy.on 'beforeResGet', (res) ->
  res.setHeader 'content-type', 'text/plain'
  res.body = 'new response body'

server = http.createServer (req, res) ->
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.write '代理成功！' + '\n' + JSON.stringify(req.headers, true, 2)
  res.end()
server.listen 9091