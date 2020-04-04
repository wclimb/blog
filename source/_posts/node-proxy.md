---
title: Nodejs之实现代理
date: 2020-04-04 15:23:19
tags:
- javascript
- Node
- 原创
categories: [Node,代理]
---

## 前言

我们上线一个网站，往往需要代理来完成需求，不然的话就只能使用 `IP` 加端口的方式来访问应用，目前基本上都会使用 `Nginx` 来完成反向代理，那么我们开发 `Node` 应用一定需要 `Nginx` 吗？肯定不是，我们完全可以通过 `Node` 来做，但是大多是不建议你用 `Node` 去处理，因为 `Nginx` 功能更强大，比如负载均衡，本文主要是帮你了解如何通过 `Node` 实现代理

## 使用http-proxy

最简单的做法是拿已经写好的包直接使用

```
$ cnpm i http-proxy
```

```js
const proxy = require("http-proxy").createProxyServer({});

server = require("http").createServer(function(req, res) {
  const host = req.headers.host;
  switch (host) {
    case "your domain":
      proxy.web(req, res, { target: "http://localhost:8000" });
      break;
    default:
      res.writeHead(200, {
        "Content-Type": "text/plain"
      });
      res.end("Welcome to my server!");
  }
});

console.log("listening on port 80");

server.listen(80);
```

上面👆代码监听 `80` 端口（如果你的服务器目前使用来 `Nginx`，暂用`80` 端口的话，需要先暂停 `Nginx` 服务），然后我们通过访问域名（前提是域名做好了解析），然后使用 `proxy.web`方法反向代理到当前服务下的 `8000` 端口，到此一个简单的服务完成了
<!-- more -->

## 原生实现

```js
const http = require("http");
const url = require("url");

function request(req, res) {
  const reqUrl = url.parse(req.url);
  const target = url.parse("http://localhost:3000");
  const options = {
    hostname: target.hostname,
    port: target.port,
    path: reqUrl.path,
    method: req.method,
    headers: req.headers
  };

  const proxyReq = http.request(options);

  proxyReq.on("response", proxyRes => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  req.pipe(proxyReq);
}

http
  .createServer()
  .on("request", request)
  .listen(8003);
```
是不是很简单？通过访问 `8003` 端口，我们将请求转发到 `3000` 端口，可以复制当前代码尝试一下，前提是 `3000` 端口可以正常访问。当访问 `8003` 端口的时候，内部重新请求我们需要代理的地址，然后通过 `pipe` 返回转发后的数据

## http-proxy源码实现原理

[源码地址](https://github.com/http-party/node-http-proxy/blob/master/lib/http-proxy/index.js#L96)
执行 `proxy.web`
```js
function ProxyServer(options) {
  ...

  this.web = this.proxyRequest = createRightProxy('web')(options);

  ...
}
```

[源码地址](https://github.com/http-party/node-http-proxy/blob/master/lib/http-proxy/index.js#L726)

内部关键代码执行了一下这段，`passes` 是一个数组方法，包含`deleteLength`、`timeout`、`XHeaders`、`stream`，关键点在 `stream`，其他基本是辅助作用，`XHeaders` 功能是设置 `x-forwarded-*` 这种 `header`，不过前提是 `option` 配置了 `xfwd` 才行，`timeout` 是设置超时时间的，`deleteLength` 只有请求方法是 `OPTIONS` 和 `DELETE` 才会执行
```js
...
for(var i=0; i < passes.length; i++) {
  if(passes[i](req, res, requestOptions, head, this, cbl)) { // passes can return a truthy value to halt the loop
    break;
  }
}
```
[源码地址](https://github.com/http-party/node-http-proxy/blob/master/lib/http-proxy/passes/web-incoming.js#L100)
`stream` 方法
```js
module.exports = {
  deleteLength: ....,
  timeout: ...,
  XHeaders: ...,
  stream: function stream(req, res, options, _, server, clb) {

    // And we begin!
    server.emit('start', req, res, options.target || options.forward);

    var agents = options.followRedirects ? followRedirects : nativeAgents;
    var http = agents.http;
    var https = agents.https;

    if(options.forward) {
      // If forward enable, so just pipe the request
      var forwardReq = (options.forward.protocol === 'https:' ? https : http).request(
        common.setupOutgoing(options.ssl || {}, options, req, 'forward')
      );

      // error handler (e.g. ECONNRESET, ECONNREFUSED)
      // Handle errors on incoming request as well as it makes sense to
      var forwardError = createErrorHandler(forwardReq, options.forward);
      req.on('error', forwardError);
      forwardReq.on('error', forwardError);

      (options.buffer || req).pipe(forwardReq);
      if(!options.target) { return res.end(); }
    }

    // Request initalization
    var proxyReq = (options.target.protocol === 'https:' ? https : http).request(
      common.setupOutgoing(options.ssl || {}, options, req)
    );

    // Enable developers to modify the proxyReq before headers are sent
    proxyReq.on('socket', function(socket) {
      if(server) { server.emit('proxyReq', proxyReq, req, res, options); }
    });

    // allow outgoing socket to timeout so that we could
    // show an error page at the initial request
    if(options.proxyTimeout) {
      proxyReq.setTimeout(options.proxyTimeout, function() {
          proxyReq.abort();
      });
    }

    // Ensure we abort proxy if request is aborted
    req.on('aborted', function () {
      proxyReq.abort();
    });

    // handle errors in proxy and incoming request, just like for forward proxy
    var proxyError = createErrorHandler(proxyReq, options.target);
    req.on('error', proxyError);
    proxyReq.on('error', proxyError);

    function createErrorHandler(proxyReq, url) {
      return function proxyError(err) {
        if (req.socket.destroyed && err.code === 'ECONNRESET') {
          server.emit('econnreset', err, req, res, url);
          return proxyReq.abort();
        }

        if (clb) {
          clb(err, req, res, url);
        } else {
          server.emit('error', err, req, res, url);
        }
      }
    }

    (options.buffer || req).pipe(proxyReq);

    proxyReq.on('response', function(proxyRes) {
      if(server) { server.emit('proxyRes', proxyRes, req, res); }

      if(!res.headersSent && !options.selfHandleResponse) {
        for(var i=0; i < web_o.length; i++) {
          if(web_o[i](req, res, proxyRes, options)) { break; }
        }
      }

      if (!res.finished) {
        // Allow us to listen when the proxy has completed
        proxyRes.on('end', function () {
          if (server) server.emit('end', req, res, proxyRes);
        });
        // We pipe to the response unless its expected to be handled by the user
        if (!options.selfHandleResponse) proxyRes.pipe(res);
      } else {
        if (server) server.emit('end', req, res, proxyRes);
      }
    });
  }
}
```

关键代码
```js
// Request initalization
var proxyReq = (options.target.protocol === 'https:' ? https : http).request(
  common.setupOutgoing(options.ssl || {}, options, req)
);
(options.buffer || req).pipe(proxyReq);
proxyReq.on('response', function(proxyRes) {
  if(!res.headersSent && !options.selfHandleResponse) {
    for(var i=0; i < web_o.length; i++) {
      if(web_o[i](req, res, proxyRes, options)) { break; }
    }
  }
  if (!res.finished) {
    // We pipe to the response unless its expected to be handled by the user
    if (!options.selfHandleResponse) proxyRes.pipe(res);
  } 
});
```
实现大致和我们之前写得差不多，但是他考虑得更多，支持 `https`，错误处理也做得很好，已经很成熟了

## 结尾

至此就基本讲完了，本文意在实操，理论讲解涉及极少，在写一个功能的时候，还是要多了解一下内部的原理知识，能帮助你更好的理解，如果错误还望指正。

本文地址 [Nodejs之实现代理](http://www.wclimb.site/2020/04/04/node-proxy/)
