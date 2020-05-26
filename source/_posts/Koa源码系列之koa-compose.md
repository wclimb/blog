---
title: Koa源码系列之koa-compose
date: 2019-12-11 16:39:19
tags:
- javascript
- Koa
- 原创
categories: [Node,Koa]
---

## 写在前面

  从今天开始阅读学习一下`Koa`源码，`Koa`对前端来说肯定不陌生，使用`node`做后台大部分会选择`Koa`来做，`Koa`源码的代码量其实很少，接下来让我们一层层剥离，分析其中的源码

## Koa用法

```js
const Koa = require("koa");
const app = new Koa();
app.use(async ctx => {
  ctx.body = {
    a: 1
  };
});
app.listen(3000);
```

浏览器打开 http://localhost:3000 可以看到返回了一个对象 `{a:1}`
<!-- more -->

## 洋葱模型

Koa最经典的就是基于洋葱模型的HTTP中间件处理流程，可以看下图

![](/img/koa-img-1.png)

看下面代码是否能理解

```js
const Koa = require("koa");
const app = new Koa();
app.use(async (ctx,next) => {
  console.log(1);
  setTimeout(()=>{
    next()
    console.log(2)
  },1000)
});
app.use(async (ctx,next) => {
  console.log(3);
  next()
  console.log(4)
});
app.use(async (ctx,next) => {
  console.log(5);
  setTimeout(()=>{
    console.log(6)
  },1000)
  next()
  console.log(7)
});
app.listen(3000);
```

访问 http://localhost:3000 输出
```js
1
3  // 1秒后开始输出
5
7
4
2
6 // 1秒后开始输出
```

不知道看到这你是否能够明白，不明白也没关系，我们可以深入源码来分析具体的实现

## koa源码


https://github.com/koajs/koa/blob/master/lib/application.js#L77 

执行`app.listen(3000)`;会走以下代码

```js
  /**
   * Shorthand for:
   *
   *    http.createServer(app.callback()).listen(...)
   *
   * @param {Mixed} ...
   * @return {Server}
   * @api public
   */

  listen(...args) {
    debug('listen');
    const server = http.createServer(this.callback());
    return server.listen(...args);
  }、
```
https://github.com/koajs/koa/blob/master/lib/application.js#L141
我们接着看`callback`方法
```js
  /**
   * Return a request handler callback
   * for node's native http server.
   *
   * @return {Function}
   * @api public
   */

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
在上面`callback`执行了`compose`方法来处理中间件，`compose`方法就是今天我们需要重点讲的方法，等会再说，我们知道`Koa`大部分情况都是在处理中间件，那么它们是怎么拿到中间件的呢？
上面可以看到有一个`this.middleware`，中间件肯定是放在这里面的，于是我们搜索，在最上层可以在构造函数里看到初始化的时候，它把`this.middleware = []`;置为一个数组，我们使用中间件的时候是通过`app.use`来使用的。继续寻找`use`方法
https://github.com/koajs/koa/blob/master/lib/application.js#L120
`use`方法
```js
  /**
   * Use the given middleware `fn`.
   *
   * Old-style middleware will be converted.
   *
   * @param {Function} fn
   * @return {Application} self
   * @api public
   */

  use(fn) {
    if (typeof fn !== 'function') throw new TypeError('middleware must be a function!');
    if (isGeneratorFunction(fn)) {
      deprecate('Support for generators will be removed in v3. ' +
                'See the documentation for examples of how to convert old middleware ' +
                'https://github.com/koajs/koa/blob/master/docs/migration.md');
      fn = convert(fn);
    }
    debug('use %s', fn._name || fn.name || '-');
    this.middleware.push(fn);
    return this;
  }
```
每次我们调用`app.use`，`koa`都是把这个方法`push`到`middleware`数组里面。感觉说得有点啰嗦了，流程大体就是这样。

```
定义中间件数组 -> 收集中间件放到middleware数组里 -> 通过compose方法处理中间件达到洋葱模式
```

## koa-compose

https://github.com/koajs/compose/blob/master/index.js

`compose`是引用的`koa-compose`包，查看源码发现关键只有20几行

```js
/**
 * Compose `middleware` returning
 * a fully valid middleware comprised
 * of all those which are passed.
 *
 * @param {Array} middleware
 * @return {Function}
 * @api public
 */
function compose (middleware) {
  if (!Array.isArray(middleware)) throw new TypeError('Middleware stack must be an array!')
  for (const fn of middleware) {
    if (typeof fn !== 'function') throw new TypeError('Middleware must be composed of functions!')
  }

  /**
   * @param {Object} context
   * @return {Promise}
   * @api public
   */

  return function (context, next) {
    // last called middleware #
    let index = -1
    return dispatch(0)
    function dispatch (i) {
      if (i <= index) return Promise.reject(new Error('next() called multiple times'))
      index = i
      let fn = middleware[i]
      if (i === middleware.length) fn = next
      if (!fn) return Promise.resolve()
      try {
        return Promise.resolve(fn(context, dispatch.bind(null, i + 1)));
      } catch (err) {
        return Promise.reject(err)
      }
    }
  }
}
```
我们默许中间件传入的是数组函数，进一步剥离，精简的代码如下

```js
function compose (middleware) {
  return function (context, next) {
    let index = -1
    return dispatch(0)
    function dispatch (i) {
      if (i <= index) return Promise.reject(new Error('next() called multiple times'))
      index = i
      let fn = middleware[i]
      if (i === middleware.length) fn = next
      if (!fn) return Promise.resolve()
      try {
        return Promise.resolve(fn(context, dispatch.bind(null, i + 1)));
      } catch (err) {
        return Promise.reject(err)
      }
    }
  }
}
```
初略的看，`compose`返回的是一个函数，首先执行了`dispatch(0)`，函数内容返回的都是Promise对象。
最初执行`dispatch(0)`；通过递归的方式不断的运行中间件，每个中间件都接收了两个参数，分别是`context`和`next`，`context`其实就是`koa`的`ctx`，如果我们不传递`next`方法，后面的中间件就不会继续执行下去。

之前的代码我们可以初略的想象一下以下代码
```js
function fn1(context, next) {
  console.log(1);
  next();
  console.log(2);
}

function fn2(context, next) {
  console.log(3);
  next();
  console.log(4);
}

function fn3(context, next) {
  console.log(5);
  next();
  console.log(6);
}
function compose() {
  return fn1('', () => {
    return fn2('', () => {
      return fn3('', () => {
      });
    });
  });
}
```
输出：
```js
1
3
5
6
4
2
```
其实就是一层层嵌套执行中间件的方法，执行完`next`再往上执行

```
       -------------------------------------------------------------------------------------
        |                                                                                  |
        |                                       fn1                                        |
        |          +-----------------------------------------------------------+           |
        |          |                                                           |           |    
        |          |                            fn2                            |           |
        |          |            +---------------------------------+            |           |
        |          |            |                                 |            |           |
        |          |            |               fn3               |            |           |
        |          |            |                                 |            |           |
---------------------------------------------------------------------------------------------------->
        |          |            |                                 |            |           |
        |     1    |      3     |       5                 6       |     4      |      2    |
        |          |            |                                 |            |           |
        |          |            +---------------------------------+            |           |
        |          |                                                           |           |
        |          +-----------------------------------------------------------+           |
        |                                                                                  |
        +----------------------------------------------------------------------------------+

```

## 最后

`koa-compose`大致就这些，流程大致如洋葱一样，代码也不多，很好理解，以后使用中间件的时候就清晰很多了。

原文地址： http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/