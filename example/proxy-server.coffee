http = require 'http'
ProxyMan = require '../index'

proxy = new ProxyMan()

proxy.createProxy('http://localhost:9091').listen 8081

server = http.createServer (req, res) ->
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.write '代理成功！' + '\n' + JSON.stringify(req.headers, true, 2)
  res.end()

server.listen 9091