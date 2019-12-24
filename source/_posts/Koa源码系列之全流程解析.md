---
title: Koa源码系列之全流程解析
date: 2019-12-23 16:13:58
tags:
- javascript
- Koa
- 原创
categories: [javascript, Koa]
---

## 写在前面

之前我们已经讲解了koa源码中的一些依赖包，[Koa源码系列之依赖包解析](http://www.wclimb.site/2019/12/16/Koa源码系列之依赖包解析/) [Koa源码系列之koa-compose](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)，现在我们来看看koa源码的全流程

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
首先我们引入`koa`包，然后实例化一个对象，也就是`const = new Koa()`。然后调用use方法，这个方法之前在[Koa源码系列之koa-compose](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)讲过，用处就是挂载中间件。当前内部执行的方法就是向前端返回一个`hello world`的内容，最后我们将应用挂载在`3000`端口下，这个listen很重要，因为一切我们定义的的方法都会从这里执行。我们看看 Koa 的构造函数的主入口是从哪暴露的，先来🤔思考一个问题，我们怎么快速找到一个包的主入口呢？如果你发布过npm包就知道，我们可以在`package.json`内找到`main`，`koa`的内容是 `"main": "lib/application.js"`，现在我们可以直接去查看`lib下`的`application`文件，是不是很方便？

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
以上代码就是暴露出来的构造函数，所以我们可以使用`new Koa()`的形式调用，它继承了`node`提供的原生 `events`（事件触发器）方法，那么它在哪用到了呢？我们知道我们可以使用 `app.on('error')` 来监听错误，可以看下面代码
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
是不是跟之前我们写的很像？看上面代码可以看出执行listen构建了一个服务，调用了`callback`方法，继续看`callback`
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
回调内部首先执行了中间件，调用了`compose`，这个[上上篇文章](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)讲过，继续看，最后返回了一个处理请求的函数`handleRequest`，接收两个参数`req`，`res`，其实就是原生返回的数据，内部继续调用了`this.createContext`，该方法主要是最数据进行处理，源码如下
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
从上面可以看出，它的功能主要是对数据进行进一步处理，把挂载多个`key`上，这也就是我们可以使用`ctx.req`和`ctx.response`的原因。等会会讲到`this.context/this.request/this.response`内部的实现
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