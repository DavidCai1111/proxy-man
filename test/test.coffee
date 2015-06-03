http = require 'http'
request = require 'supertest'
should = require 'should'
ProxyMan = require '../index'

describe 'test proxy-man', () ->
  this.timeout 1000 * 60

  it 'proxy serve', (done) ->
    proxy = new ProxyMan()
    ProxyServer = http.createServer (req, res) -> proxy.createProxy('http://localhost:9091', req, res)
    ProxyServer.listen 8081

    server = http.createServer (req, res) ->
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.write '代理成功！' + '\n' + JSON.stringify(req.headers, true, 2)
      res.end()
    server.listen 9091

    request(ProxyServer)
      .get '/'
      .expect 'Content-Type', /text/
      .expect 200, () -> done()

  it 'proxy server', (done) ->
    proxy = new ProxyMan()
    proxy.createProxy('http://localhost:9092').listen 8082
    server = http.createServer (req, res) ->
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.write '代理成功！' + '\n' + JSON.stringify(req.headers, true, 2)
      res.end()
    server.listen 9092

    request(proxy.proxyServer)
      .get '/'
      .expect 'Content-Type', /text/
      .expect 200, () -> done()
