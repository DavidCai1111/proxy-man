# proxy-man
[![Build Status](https://travis-ci.org/DavidCai1993/proxy-man.svg?branch=master)](https://travis-ci.org/DavidCai1993/proxy-man)
[![Coverage Status](https://coveralls.io/repos/DavidCai1993/proxy-man/badge.svg)](https://coveralls.io/r/DavidCai1993/proxy-man)

## 简介
proxy-man是一个基于原生http模块实现的代理，它可以用来代理`http请求`，并在代理请求将要发出时，和将要接受目标响应时提供事件钩子，用来做自定义的修改。

## 安装
直接通过npm：
```SHELL
npm install proxy-man --save
```

## 例子
```js
//代理功能
var http = require('http');
var ProxyMan = require('proxy-man');

var proxy = new ProxyMan();

http.createServer(function(req, res) {
  proxy.createProxy('http://localhost:9091', req, res);
}).listen(8081);

http.createServer(function(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/plain'
  });
  res.write(JSON.stringify(req.headers, true, 2));
  res.end();
}).listen(9091);
```

```js
//简单的代理服务器
var http = require('http');
var ProxyMan = require('proxy-man');

var proxy = new ProxyMan();
proxy.createProxy('http://localhost:9091').listen(8081);

//请求即将发出前触发
proxy.on('beforeReqSend', function(req) {
  req.setHeader('X-Special-Proxy-Header', 'foo');
});
//响应即将返回前触发
proxy.on('beforeResGet', function(res) {
  res.writeHead(500, {
    'Content-Type': 'text/plain'
  });
  res.end('always 500, haha');
});

http.createServer(function(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/plain'
  });
  res.write(JSON.stringify(req.headers, true, 2));
  res.end();
}).listen(9091);
```

```js
//简单负载均衡
var http = require('http');
var ProxyMan = require('proxy-man');

var proxy = new ProxyMan();
var address = ['http://localhost:9090', 'http://localhost:9091', 'http://localhost:9092'];

http.createServer(function(req, res) {
  var target = address.shift();
  proxy.createProxy(target, req, res);
  address.push(target);
}).listen(8081);
```

## API

#### new ProxyMan()
```js
var proxy = new ProxyMan();
```
返回一个独立的ProxyMan实例

#### createProxy(targetUrl, [req, res])
若参数中含有`req`以及`res`，则作为服务器内部的代理服务，将请求发往`targetUrl`
```js
http.createServer(function(req, res) {
  proxy.createProxy('http://localhost:9091', req, res);
}).listen(8081);
```
若参数中没有`req`以及`res`，则作为独立的代理服务器，需要继续调用`listen()`方法监听指定端口
```js
proxy.createProxy('http://localhost:9091').listen(8081);
```

#### listen(port)
仅作为代理服务器使用时有效，监听指定端口

#### close()
仅作为代理服务器使用时有效，关闭此代理服务器

#### event: beforeReqSend
function (request) { }

代理请求即将发出前触发，`request`即为将要发出的请求，可以在此事件内对其做出修改，并提供便捷方法`setHeader(name, value)`
```js
proxy.on('beforeReqSend', function(req) {
  req.setHeader('X-Special-Proxy-Header', 'foo');
});
```

#### event: beforeResGet
function (response) { }

响应即将返回前触发，`response`即为将要返回的响应，可以在此事件内对其做出修改，`response`对象提供了便捷属性`body`来修改响应体，支持直接在事件中返回响应
```js
proxy.on('beforeResGet', function(res) {
  res.setHeader('content-type', 'text/plain');
  res.body = 'new response body'
});
//or
proxy.on('beforeResGet', function(res) {
  res.writeHead(500, {
    'Content-Type': 'text/plain'
  });
  res.end('always 500, haha');
});
```
