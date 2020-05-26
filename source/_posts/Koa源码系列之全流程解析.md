---
title: Koa源码系列之全流程解析
date: 2019-12-23 16:13:58
tags:
- javascript
- Koa
- 原创
categories: [Node, Koa]
---

## 写在前面

之前我们已经讲解了`koa`源码中的一些依赖包，[Koa源码系列之依赖包解析](http://www.wclimb.site/2019/12/16/Koa源码系列之依赖包解析/) [Koa源码系列之koa-compose](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)，现在我们来看看`koa`源码的全流程

## 解析

我们首先来看看最简单的用法，一下是官网的示例
```js
const Koa = require('koa');
const app = new Koa();

app.use(async ctx => {
  ctx.body = 'Hello World';
});

app.listen(3000);
```
首先我们引入`koa`包，然后实例化一个对象，也就是`const = new Koa()`。然后调用`use`方法，这个方法之前在[Koa源码系列之koa-compose](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)讲过，用处就是挂载中间件。当前内部执行的方法就是向前端返回一个`hello world`的内容，最后我们将应用挂载在`3000`端口下，这个`listen`很重要，因为一切我们定义的的方法都会从这里执行。我们看看 `Koa` 的构造函数的主入口是从哪暴露的，先来🤔思考一个问题，我们怎么快速找到一个包的主入口呢？如果你发布过`npm`包就知道，我们可以在`package.json`内找到`main`，`koa`的内容是 `"main": "lib/application.js"`，现在我们可以直接去查看`lib`下的`application`文件，是不是很方便？

接下来部分解析可能在代码注释内
https://github.com/koajs/koa/blob/master/lib/application.js#L30
```js
module.exports = class Application extends Emitter {
  constructor(options) {
    super();
    options = options || {};
    this.proxy = options.proxy || false;
    this.subdomainOffset = options.subdomainOffset || 2;
    this.proxyIpHeader = options.proxyIpHeader || 'X-Forwarded-For';
    this.maxIpsCount = options.maxIpsCount || 0;
    this.env = options.env || process.env.NODE_ENV || 'development';
    if (options.keys) this.keys = options.keys;
    // 存放中间件
    this.middleware = [];
    this.context = Object.create(context);
    this.request = Object.create(request);
    this.response = Object.create(response);
    if (util.inspect.custom) {
      this[util.inspect.custom] = this.inspect;
    }
  }
  ...
}
```
<!-- more -->
以上代码就是暴露出来的构造函数，所以我们可以使用`new Koa()`的形式调用，它继承了（`extends Emitter`这段代码）`node`提供的原生 `events`（事件触发器）方法，那么它在哪用到了呢？我们知道`koa`可以使用 `app.on('error')` 来监听错误，可以看下面代码
```js
app.on('error', err => {
  log.error('server error', err)
});
```
我们添加了一个 `“error”` 事件侦听器，那么它在哪会触发，理想的代码肯定是 `xxx.emit('error', ...)`，搜索一下就知道，代码在 [lib/context下的onerror](https://github.com/koajs/koa/blob/master/lib/context.js#L121)，当程序出错走会走这个`onerror`方法。


继续看构造函数内代码，我们可以传递`option`，当前`this`下面挂载了讲过属性，分别是 `proxy`（代理） `subdomainOffset`（作用是子域偏移数） `proxyIpHeader` `maxIpsCount` `env`，这几个属性都可以从外部传入，当然不传的话会有默认值，比如`env`标记开发环境的变量，默认是 `'development'`。

往下看到有一个 `this.middleware = []`，这里是存放中间件的，`app.use()`内的方法都会`push`到这个数组内，那么它在哪会执行这些数组内部的方法呢？它会在当前实例的`callback`函数内调用，这个后面再讲。

然后继续看后面紧跟着三个创建对象的赋值的操作，分别是 `context/request/response`，他们其实都是来自另外三个文件暴露出来的对象。他们的作用简单来说就是对对象数据层做了处理，添加了很多方法，比如我们使用 `ctx.redirect` `ctx.body` `ctx.query`等等，都来自这三个对象内方法。后面会细说，先讲最外层的方法。


那么执行完构造函数，程序还是跑不起来不是？我们知道原生的创建一个后台应用需要使用到`http.createServer`，到目前为止我们还没有说到，我们先来看看原生怎么创建的
```js
var http = require('http');
http.createServer(function (request, response) {
  response.writeHead(200, {'Content-Type': 'text/plain'});
  response.end('Hello World\n');
}).listen(8888);
```
我们之前讲过`app.listen`方法是创建应用的关键，我们来看看源码
https://github.com/koajs/koa/blob/master/lib/application.js#L77
```js
listen(...args) {
  debug('listen');
  const server = http.createServer(this.callback());
  return server.listen(...args);
}
```
是不是跟之前我们写的很像？看上面代码可以看出执行`listen`构建了一个服务，调用了`callback`方法，继续看`callback`
https://github.com/koajs/koa/blob/master/lib/application.js#L141
```js
  callback() {
    const fn = compose(this.middleware);

    if (!this.listenerCount('error')) this.on('error', this.onerror);

    const handleRequest = (req, res) => {
      const ctx = this.createContext(req, res);
      return this.handleRequest(ctx, fn);
    };

    return handleRequest;
  }
```
回调内部首先执行了中间件，调用了`compose`，这个[上上篇文章](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)讲过，继续看，最后返回了一个处理请求的函数`handleRequest`，接收两个参数`req`，`res`，其实就是之前我们原生创建应用返回的数据，内部继续调用了`this.createContext`，该方法主要是对数据进行处理，源码如下：
```js
createContext(req, res) {
  const context = Object.create(this.context);
  const request = context.request = Object.create(this.request);
  const response = context.response = Object.create(this.response);
  context.app = request.app = response.app = this;
  context.req = request.req = response.req = req;
  context.res = request.res = response.res = res;
  request.ctx = response.ctx = context;
  request.response = response;
  response.request = request;
  context.originalUrl = request.originalUrl = req.url;
  context.state = {};
  return context;
}
```
从上面可以看出，它的功能主要是对数据进行进一步处理，把它挂载多个`key`上，这也就是我们可以使用`ctx.req`和`ctx.response`的原因。等会会讲到`this.context/this.request/this.response`内部的实现。
`callback`回调内部使用`this.handleRequest`方法来处理结果，我们看一下源码
https://github.com/koajs/koa/blob/master/lib/application.js#L160
```js
handleRequest(ctx, fnMiddleware) {
  const res = ctx.res;
  res.statusCode = 404;
  const onerror = err => ctx.onerror(err);
  const handleResponse = () => respond(ctx);
  onFinished(res, onerror);
  return fnMiddleware(ctx).then(handleResponse).catch(onerror);
}
```
上面的代码很好理解，意思就是中间件执行完后，再异步里处理返回请求的信息，也就是`respond`方法，如果内部报错自然会走`catch`方法，然后处理的函数是`lib/context.js`文件下暴露的`onerror`方法，这个方法上面有讲过。我们具体看一下`koa`是怎么处理请求返回数据的。

🤔分析之前我们先思考一下开发的时候是怎么返回数据给前端的？我们使用`ctx.body = 'xx'`，当然这个值不一定是字符串，可以是对象、`buffer`等。然后思考一下原生的使用最后一般返回数据是怎么样的呢？肯定不是`ctx.body`，这个只是个语法糖而已，熟悉的人应该立马就知道，原生返回数据我们都是使用`res.end(data)`的形式返回，这里就可以猜测，`koa`肯定是先取到了我们`ctx.body`的值，最后使用`res.end(data)`来返回数据的。

respond方法
```js
function respond(ctx) {
  // allow bypassing koa
  if (false === ctx.respond) return;

  if (!ctx.writable) return;

  const res = ctx.res;
  let body = ctx.body;
  const code = ctx.status;

  // ignore body
  if (statuses.empty[code]) {
    // strip headers
    ctx.body = null;
    return res.end();
  }

  if ('HEAD' === ctx.method) {
    if (!res.headersSent && !ctx.response.has('Content-Length')) {
      const { length } = ctx.response;
      if (Number.isInteger(length)) ctx.length = length;
    }
    return res.end();
  }

  // status body
  if (null == body) {
    if (ctx.req.httpVersionMajor >= 2) {
      body = String(code);
    } else {
      body = ctx.message || String(code);
    }
    if (!res.headersSent) {
      ctx.type = 'text';
      ctx.length = Buffer.byteLength(body);
    }
    return res.end(body);
  }

  // responses
  if (Buffer.isBuffer(body)) return res.end(body);
  if ('string' == typeof body) return res.end(body);
  if (body instanceof Stream) return body.pipe(res);

  // body: json
  body = JSON.stringify(body);
  if (!res.headersSent) {
    ctx.length = Buffer.byteLength(body);
  }
  res.end(body);
}
```
好了，根据之前的理解，再看一下上面的代码是不是清楚很多？不过其中`koa`还是做了一些数据的处理，比如如果我们`ctx.body = {}`，`koa`会自动把对象转字符串，然后就算返回数据的`length`，最后再调用`res.end(body)`。


## context.js

https://github.com/koajs/koa/blob/master/lib/context.js

之前说过会讲到三个文件暴露出来的方法，这是其中一个。他们其实都是对数据进行了一系列的处理。

```js

'use strict';

/**
 * Module dependencies.
 */

const util = require('util');
const createError = require('http-errors');
const httpAssert = require('http-assert');
const delegate = require('delegates');
const statuses = require('statuses');
const Cookies = require('cookies');

const COOKIES = Symbol('context#cookies');

const proto = module.exports = {

  inspect() {
    if (this === proto) return this;
    return this.toJSON();
  },

  toJSON() {
    ...
  },
  assert: httpAssert,

  throw(...args) {
    throw createError(...args);
  },

  onerror(err) {
    ...
  },

  get cookies() {
    if (!this[COOKIES]) {
      this[COOKIES] = new Cookies(this.req, this.res, {
        keys: this.app.keys,
        secure: this.request.secure
      });
    }
    return this[COOKIES];
  },

  set cookies(_cookies) {
    this[COOKIES] = _cookies;
  }
};

if (util.inspect.custom) {
  module.exports[util.inspect.custom] = module.exports.inspect;
}
delegate(proto, 'response')
  ...
  .method('append')
  .method('flushHeaders')
  .access('status')
  .access('message')
  .access('body')
  .access('length')
  .access('type')
  .access('lastModified')
  .access('etag')
  .getter('headerSent')
  .getter('writable');

delegate(proto, 'request')
  ...
  .getter('host')
  .getter('hostname')
  .getter('URL')
  .getter('header')
  .getter('headers')
  .getter('secure')
  .getter('stale')
  .getter('fresh')
  .getter('ips')
  .getter('ip');
```
以上就是`context`的全部内容，我做了精简，把注释和一些相似的代码删除了，但是方法上面全部都在，`context`你可以直接理解为我们经常使用的`ctx`，`ctx`下面是不是有很多方法？其实基本上都是末尾`delegate`方法处理之后得到的，我们可以看到它分别处理了`response`、`request`，其实就算请求体和响应体，[上篇文章](http://www.wclimb.site/2019/12/16/Koa%E6%BA%90%E7%A0%81%E7%B3%BB%E5%88%97%E4%B9%8B%E4%BE%9D%E8%B5%96%E5%8C%85%E8%A7%A3%E6%9E%90/#delegates)我们介绍过它的机制，我们使用的`ctx.body`、`ctx.header`、`ctx.query`....基本上方法都可以在这里看到。除了这些，上面还有获取`cookie`和设置`cookie`的方法，还有我们之前讲到的 `onerror` 方法，

## request.js

现在我们自然可以知道，`body/header/query`这些方法都放在另外两个文件下面，`requset`下面会有`host/hostname/URL/header`.....方法，我们这里只看部分方法，因为方法有点多，篇幅很长
```js
const URL = require('url').URL;
const net = require('net');
const accepts = require('accepts');
const contentType = require('content-type');
const stringify = require('url').format;
const parse = require('parseurl');
const qs = require('querystring');
const typeis = require('type-is');
const fresh = require('fresh');
const only = require('only');
const util = require('util');

const IP = Symbol('context#ip');

/**
 * Prototype.
 */

module.exports = {

  /**
   * Return request header.
   *
   * @return {Object}
   * @api public
   */

  get header() {
    return this.req.headers;
  },

  /**
   * Set request header.
   *
   * @api public
   */

  set header(val) {
    this.req.headers = val;
  },

  /**
   * Return request header, alias as request.header
   *
   * @return {Object}
   * @api public
   */

  get headers() {
    return this.req.headers;
  },

  /**
   * Set request header, alias as request.header
   *
   * @api public
   */

  set headers(val) {
    this.req.headers = val;
  },

  /**
   * Get request URL.
   *
   * @return {String}
   * @api public
   */

  get url() {
    return this.req.url;
  },

  /**
   * Set request URL.
   *
   * @api public
   */

  set url(val) {
    this.req.url = val;
  },
  ...
}
```

上面就是部分`request`内的方法，是不是很简单，就是一些获取和值的设置。
```js
get header() {
  return this.req.headers;
},
set header(val) {
  this.req.headers = val;
},
```
比如上面获取我设置`header`会有两个方法，`ctx.header`，会调用第一个`get`方法，赋值则会走第二个方法，那么`this.req`是什么呢，我们肯定知道是`http.createServer`回调返回的`req`信息，那么`this`具体是什么呢？之前我们就讲过在`application.js`内的`createContext`方法，`request`赋值给了`context.requset`，然后`context.js`内部通过`delegate`代理了数据，`context`下也定义了`req`对象，这样我们就可以直接使用`this.req`直接获取数据
```js
createContext(req, res) {
  const context = Object.create(this.context);
  const request = (context.request = Object.create(this.request));
  const response = (context.response = Object.create(this.response));
  context.app = request.app = response.app = this;
  context.req = request.req = response.req = req;
  context.res = request.res = response.res = res;
  request.ctx = response.ctx = context;
  request.response = response;
  response.request = request;
  context.originalUrl = request.originalUrl = req.url;
  context.state = {};
  return context;
}
```

## response.js

这里跟上面的原理一样，我们简单看一下部分代码吧
```js
module.exports = {

  get status() {
    return this.res.statusCode;
  },

  /**
   * Set response status code.
   *
   * @param {Number} code
   * @api public
   */

  set status(code) {
    if (this.headerSent) return;

    assert(Number.isInteger(code), 'status code must be a number');
    assert(code >= 100 && code <= 999, `invalid status code: ${code}`);
    this._explicitStatus = true;
    this.res.statusCode = code;
    if (this.req.httpVersionMajor < 2) this.res.statusMessage = statuses[code];
    if (this.body && statuses.empty[code]) this.body = null;
  },

  /**
   * Get response status message
   *
   * @return {String}
   * @api public
   */

  get message() {
    return this.res.statusMessage || statuses[this.status];
  },

  /**
   * Set response status message
   *
   * @param {String} msg
   * @api public
   */

  set message(msg) {
    this.res.statusMessage = msg;
  },

  /**
   * Get response body.
   *
   * @return {Mixed}
   * @api public
   */

  get body() {
    return this._body;
  },

  /**
   * Set response body.
   *
   * @param {String|Buffer|Object|Stream} val
   * @api public
   */

  set body(val) {
    const original = this._body;
    this._body = val;

    // no content
    if (null == val) {
      if (!statuses.empty[this.status]) this.status = 204;
      this.remove('Content-Type');
      this.remove('Content-Length');
      this.remove('Transfer-Encoding');
      return;
    }

    // set the status
    if (!this._explicitStatus) this.status = 200;

    // set the content-type only if not yet set
    const setType = !this.has('Content-Type');

    // string
    if ('string' == typeof val) {
      if (setType) this.type = /^\s*</.test(val) ? 'html' : 'text';
      this.length = Buffer.byteLength(val);
      return;
    }

    // buffer
    if (Buffer.isBuffer(val)) {
      if (setType) this.type = 'bin';
      this.length = val.length;
      return;
    }

    // stream
    if ('function' == typeof val.pipe) {
      onFinish(this.res, destroy.bind(null, val));
      ensureErrorHandler(val, err => this.ctx.onerror(err));

      // overwriting
      if (null != original && original != val) this.remove('Content-Length');

      if (setType) this.type = 'bin';
      return;
    }

    // json
    this.remove('Content-Length');
    this.type = 'json';
  },

  /**
   * Set Content-Length field to `n`.
   *
   * @param {Number} n
   * @api public
   */

  set length(n) {
    this.set('Content-Length', n);
  },

  /**
   * Return parsed response Content-Length when present.
   *
   * @return {Number}
   * @api public
   */

  get length() {
    if (this.has('Content-Length')) {
      return parseInt(this.get('Content-Length'), 10) || 0;
    }

    const { body } = this;
    if (!body || body instanceof Stream) return undefined;
    if ('string' === typeof body) return Buffer.byteLength(body);
    if (Buffer.isBuffer(body)) return body.length;
    return Buffer.byteLength(JSON.stringify(body));
  },

  ...
}
```
上面是部分代码，看起来很容易理解，获取状态码使用`ctx.status`，也可以设置。这里我们值得看看`body`方法，看看它是怎么处理的，我们经常使用的`ctx.body`就是来自这里
`body`方法
```js
set body(val) {
  const original = this._body;
  this._body = val;

  // no content
  // 如果没有内容返回状态码204
  if (null == val) {
    if (!statuses.empty[this.status]) this.status = 204;
    this.remove('Content-Type');
    this.remove('Content-Length');
    this.remove('Transfer-Encoding');
    return;
  }

  // set the status
  // 如果我们没有设置状态码，默认是200，this._explicitStatus在set status方法内会有赋值，意思是如果我们显示的设置了状态码，那么它的值为true
  if (!this._explicitStatus) this.status = 200;

  // set the content-type only if not yet set
  // 这里意思是，如果我们没有设置content-type的时候，判断是否需要设置数据类型
  const setType = !this.has('Content-Type');

  // string
  // 如果是字符串类型
  if ('string' == typeof val) {
    // 如果需要设置content-type，那么会有两种类型，html、text
    if (setType) this.type = /^\s*</.test(val) ? 'html' : 'text';
    // 顺便设置他们的length
    this.length = Buffer.byteLength(val);
    return;
  }

  // buffer
  // 如果是buffer，并且需要设置content-type，那么指定类型为bin，同样需要设置length
  if (Buffer.isBuffer(val)) {
    if (setType) this.type = 'bin';
    this.length = val.length;
    return;
  }

  // stream
  // 如果是流文件，类型仍然是bin
  if ('function' == typeof val.pipe) {
    onFinish(this.res, destroy.bind(null, val));
    ensureErrorHandler(val, err => this.ctx.onerror(err));

    // overwriting
    if (null != original && original != val) this.remove('Content-Length');

    if (setType) this.type = 'bin';
    return;
  }

  // json
  // 最后剩下的只有json类型了
  this.remove('Content-Length');
  this.type = 'json';
},
```

## 总结

大体对`koa`执行的流程分析了一遍，总体来说还是很好理解的，就是用文字表达出来可能不太理想，现在其实我们已经可以写一个自己的`koa`了。本文还会继续完善，如有错误，还望指正。

原文地址：http://www.wclimb.site/2019/12/23/Koa源码系列之全流程解析/
