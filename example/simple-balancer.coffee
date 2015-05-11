http = require 'http'
ProxyMan = require '../index'

proxy = new ProxyMan()

address = ['http://localhost:9090', 'http://localhost:9091', 'http://localhost:9092']

proxy.on 'error', (err) ->
  console.error err

ProxyServer = http.createServer (req, res) ->
  target = address.shift()
  proxy.createProxy(target, req, res)
  address.push target
ProxyServer.listen 8081

server1 = http.createServer (req, res) ->
  res.end '1'
server1.listen 9090

server2 = http.createServer (req, res) ->
  res.end '2'
server2.listen 9091

server3 = http.createServer (req, res) ->
  res.end '3'
server3.listen 9092