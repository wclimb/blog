---
title: Koa源码系列之依赖包解析
date: 2019-12-16 10:19:49
tags:
- javascript
- Koa
- 原创
categories: [javascript, Koa]
---

## 写在前面

上一篇我们讲了 [Koa源码系列之koa-compose](http://www.wclimb.site/2019/12/11/Koa源码系列之koa-compose/)，其实也可以归为到这篇文章。今天开始我们看看`Koa`源码中使用了哪些包，他们起到了什么作用。ps: 这里不准备讲所有的包

## is-generator-function

https://github.com/koajs/koa/blob/master/lib/application.js#L122
```js
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
可以看看上面一段代码，`koa`在注入中间件的之前先判断传入是否是函数，然后判断当前传入的函数是否是 `generator`，如果是 `generator` 那么使用`convert`（`koa-convert`包，下面会讲到）进行转换，其实转换出来返回的是一个 `promise`，那么怎么判断是否是 `generator` 函数的呢？使用了`isGeneratorFunction`方法，也就是 `is-generator-function`包，下面是源码
<!-- more -->
https://github.com/inspect-js/is-generator-function/blob/master/index.js
```js
var toStr = Object.prototype.toString;
var fnToStr = Function.prototype.toString;
var isFnRegex = /^\s*(?:function)?\*/; 
var hasToStringTag = typeof Symbol === 'function' && typeof Symbol.toStringTag === 'symbol';
var getProto = Object.getPrototypeOf;
var getGeneratorFunc = function () { // eslint-disable-line consistent-return
	if (!hasToStringTag) {
		return false;
	}
	try {
		return Function('return function*() {}')();
	} catch (e) {
	}
};
var generatorFunc = getGeneratorFunc();
var GeneratorFunction = generatorFunc ? getProto(generatorFunc) : {};

module.exports = function isGeneratorFunction(fn) {
  // 首先判断是否是函数，如果不是直接返回false
	if (typeof fn !== 'function') {
		return false;
	}
  // 先将函数转为字符串，然后正则匹配判断
	if (isFnRegex.test(fnToStr.call(fn))) {
		return true;
	}
	if (!hasToStringTag) {
		var str = toStr.call(fn);
		return str === '[object GeneratorFunction]';
	}
	return getProto(fn) === GeneratorFunction;
};
```

### 函数转字符串正则匹配

```js
var isFnRegex = /^\s*(?:function)?\*/;
```
上面代码正则匹配 `function* (){}`，这里其实匹配有问题，因为可以写成 `function  * (){}`，没有规定`*`一定到紧跟`function`，正则可以改成 `/^\s*(?:function)?(\s+)?\*/`


### 判断`Symbol.toStringTag`

```js
var hasToStringTag = typeof Symbol === 'function' && typeof Symbol.toStringTag === 'symbol';
```
上面这段代码很多人其实很疑惑，其实这里就想得出有没有`Symbol`以及有没有`toStringTag`方法，这个很重要，如果存在`toStringTag`，那么我们用 `Object.prototype.toString `来判断数据类型变得不可靠了。我们可以看下面这段代码
```js
class ValidatorClass {
  get [Symbol.toStringTag]() {
    return 'Validator';
  }
}
console.log(Object.prototype.toString.call(new ValidatorClass()));
// expected output: "[object Validator]"
```

有了`toStringTag`方法，我们可以伪造数据类型，这肯定会有风险，所以之前首先判断是否存在，如果存在它会使用 `Object.getPrototypeOf`来判断他们的原型是不是来自同一个，也就是下面的代码
```js
var generatorFunc = getGeneratorFunc();
var getProto = Object.getPrototypeOf;
var GeneratorFunction = generatorFunc ? getProto(generatorFunc) : {};

...

return getProto(fn) === GeneratorFunction;

```

### 直接使用`Object.prototype.toString`

如果不存在`Symbol.toStringTag`，那么自然我们可以使用 `Object.prototype.toString` 来判断数据类型
```js
if (!hasToStringTag) {
  var str = toStr.call(fn);
  return str === '[object GeneratorFunction]';
}
```
## delegates

在koa内使用
https://github.com/koajs/koa/blob/master/lib/context.js#L191
```js
/**
 * Response delegation.
 */
delegate(proto, 'response')
  .method('attachment')
  .method('redirect')
  .method('remove')
  .method('vary')
  .method('has')
  .method('set')
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
```
乍一看看不出它有啥用处，其实很简单，它相当于做了代理，本来我们访问`body`需要`ctx.response.body`，现在你只需要`ctx.body`就可以了。是不是很简单？那么我们看一下这个包的源码具体怎么实现的
```js
function Delegator(proto, target) {
 ...
}
Delegator.prototype.getter = function(name){
  ...
};
Delegator.prototype.access = function(name){
  ...
};
Delegator.prototype.setter = function(name){
  ...
};
Delegator.prototype.method = function(name){
  ...
};
```
上面的👆代码就是 [delegates](https://github.com/tj/node-delegates) 包的大致总体结构，还有其他几个方法这里不做介绍。我们可以先来看一下方法 `Delegator` 构造函数
```js
function Delegator(proto, target) {
  if (!(this instanceof Delegator)) return new Delegator(proto, target);
  this.proto = proto;
  this.target = target;
  // 以下可以忽略
  this.methods = [];
  this.getters = [];
  this.setters = [];
  this.fluents = [];
}
```
从上面我们可以看到，接收两个参数，分别是对应的对象和目标`key`值，`koa`使用的是 `delegate(proto, 'response')`，`proto`就是`ctx`，`response`就是目标`key`值。

继续看`getter`
```js 
Delegator.prototype.getter = function(name){
  var proto = this.proto;
  var target = this.target;
  this.getters.push(name);

  proto.__defineGetter__(name, function(){
    return this[target][name];
  });

  return this;
};
```
通过以上代码可以得知，它使用的是`__defineGetter__`来代理获取值，访问`ctx.body`的时候，其实返回的值是 `this[target][name]`，`target`我们已经知道，是`response`，然后在这里`body`就是`name`了。
但是我查看 [__defineGetter__](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/__defineGetter__) 这个`api`，发现 **该特性是非标准的，请尽量不要在生产环境中使用它！**，我们思考以下，其实我们可以使用`Object.defineProperty`，把它进行改造
```js
Object.defineProperty(proto, name, {
  get: function() {
    return this[target][name];
  }
});
```
其实我们看一下该项目的`PR`会发现，已经有人提了`PR`，但是一直没有`meger`。
剩下的可以同理，`setter`使用的是`__defineSetter__`方法，我们就可以借助`Object.defineProperty`的`set`进行改造。
`access`方法则是两者方法的集合，如果满足可以获取值和设置值条件，都可以使用`access`，比较方便，它的源码也很好理解，同时调用 `get`和`set`
```js
Delegator.prototype.access = function(name){
  return this.getter(name).setter(name);
};
```

## koa-convert

我们在上个模块看到了`Koa`源码有判断中间件传入的是否是 `generator` ，如果是`true`，那么它就调用了 `convert(fn)`，也就是这个模块需要解析的包 `koa-convert`，那么他到底有什么用呢？看下面他的源码

```js
const co = require('co')
const compose = require('koa-compose')
module.exports = convert

function convert (mw) {
  if (typeof mw !== 'function') {
    throw new TypeError('middleware must be a function')
  }
  if (mw.constructor.name !== 'GeneratorFunction') {
    // assume it's Promise-based middleware
    return mw
  }
  const converted = function (ctx, next) {
    return co.call(ctx, mw.call(ctx, createGenerator(next)))
  }
  converted._name = mw._name || mw.name
  return converted
}
function * createGenerator (next) {
  return yield next()
}

convert.compose = function (arr) {
  if (!Array.isArray(arr)) {
    arr = Array.from(arguments)
  }
  return compose(arr.map(convert))
}
convert.back = function (mw) {
  ...
}
```
我们可以直接跳到第13行代码，直观的看到他使用了 `co` 方法，通过 `co`包（这里不展开讲这个包）处理返回的结果拿到最终需要转换的函数，使用 `call` 主要是想把 `this` 指向 `ctx` 对象。通过co处理得到的是一个 `Promise对象`，当然 `convert` 下还有两个方法，这里介绍一下，一个是 `compose`，看过上篇文章的应该知道，它依赖了 `koa-compose`，主要功能是将一个数组里的中间件全转成 `Promise` 对象。另一个方法是back，字面意思就能知道，就是回退，可以把函数转成 `generator`


## only

看了koa源码你会发现在好几个地方用到了这个依赖包，这个包主要是输出你想要的对象数据，例子如下
```
var obj = {
  name: 'tobi',
  last: 'holowaychuk',
  email: 'tobi@learnboost.com',
  _id: '12345'
};
var user = only(obj, 'name last email');
输出：
{
  name: 'tobi',
  last: 'holowaychuk',
  email: 'tobi@learnboost.com'
}
```

koa源码使用的例子 https://github.com/koajs/koa/blob/master/lib/application.js#L92
```js
toJSON() {
  return only(this, [
    'subdomainOffset',
    'proxy',
    'env'
  ]);
}
```

依赖包源码 https://github.com/tj/node-only/blob/master/index.js
```js
module.exports = function(obj, keys){
  obj = obj || {};
  if ('string' == typeof keys) keys = keys.split(/ +/);
  return keys.reduce(function(ret, key){
    if (null == obj[key]) return ret;
    ret[key] = obj[key];
    return ret;
  }, {});
};
```
代码很简单，看源码知道，我们可以传字符串或者直接数组的形式传递需要的`key`值，默认定义一个空对象，调用`reduce`把结果循环传递下去，最终返回，如果没找指定的`value`，直接返回`ret`。额，感觉没有讲的必要，那么就。。。

## 总结

本来一股脑想讲5 6个依赖包，但是看了一下，简单的讲起来感觉有点没意思，大部分依赖包内部又依赖其他包，想讲明白其实不容易，篇幅太长，所以先讲到这里吧，下一篇讲讲总体的`koa`构造流程，有一个更清楚的认识，毕竟看源码也主要是为了这一点。

原文地址：http://www.wclimb.site/2019/12/16/Koa源码系列之依赖包解析/