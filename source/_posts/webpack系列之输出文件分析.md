---
title: webpack系列之输出文件分析
date: 2019-06-19 09:34:10
tags:
- javascript
- 原创
- webpack
categories: [javascript,webpack]
---

## 写在前面

上一篇文章我们讲了如何使用 `webpack`，执行打包会在 `dist` 生成一堆文件，那么 `webpack` 输出的文件里面到底长啥样呢？用过的人100%看过，大部分的还是压缩混淆后的代码，一般我们不会去关心它，只管当前持续运行正常就行了。今天我们来看看 `webpack` 输出的文件

## 配置

### 安装

```
> npm inin -y
> cnpm i webpack webpack-cli -D
```

### 新建文件

新建文件 webpack.config.js
新建文件夹 src
webpack.config.js
```js
const path = require('path');
module.exports = {
  devtool: 'inline-source-map',
  mode: 'development',
  entry: './src/main.js',
  output: {
    path: path.resolve(__dirname, './dist'),
    filename: 'bundle.js',
  },
};
```

src文件夹下，新增三个文件 main.js（入口文件） a.js b.js
main.js
```js
import { A1, A2 } from './a';
import B from './b';
console.log(A1, A2);
B();
```
a.js
```js
export const A1 = 'a1';
export const A2 = 'a2';
```
b.js
```js
export default function() {
  console.log('b');
}
```

### 打包

```ksh
npx webpack --config webpack.config.js 
```
然后就会在 `dist` 下生成一个 `bundle.js` 文件，接下来开始分析文件

## 文件分析

首先先来看看大致的结果
```js
(function(modules) {
  function __webpack_require__(moduleId) {
    ...
  }
  ...
  return __webpack_require__(__webpack_require__.s = "./src/main.js");
})({
  "./src/a.js": (function(module, __webpack_exports__, __webpack_require__) {}
  "./src/b.js": (function(module, __webpack_exports__, __webpack_require__) {}
  "./src/main.js": (function(module, __webpack_exports__, __webpack_require__) {}
})
```
从上面我们可以看到一个立即执行的函数，传递了一个对象，也就是modules的值，最终执行了__webpack_require__函数，执行的这个方法其实是我们在webpack里面设置的entry: './src/main.js'，对象里还有key，"./src/a.js" 、"./src/b.js"，也就是我们的 a.js 和 b.js

我们知道最开始执行了 __webpack_require__(__webpack_require__.s = "./src/main.js")方法，也就是 __webpack_require__("./src/main.js")，那么这个__webpack_require__方法又做了什么的

原始的 __webpack_require__ 方法
```js
// The module cache
var installedModules = {};
function __webpack_require__(moduleId) {
  // Check if module is in cache
  if(installedModules[moduleId]) {
    return installedModules[moduleId].exports;
  }
  // Create a new module (and put it into the cache)
  var module = installedModules[moduleId] = {
    i: moduleId,
    l: false,
    exports: {}
  };
  // Execute the module function
  modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
  // Flag the module as loaded
  module.l = true;
  // Return the exports of the module
  return module.exports;
}
```
现在我在这上面写上注释
```js
// 模块缓存
var installedModules = {};
function __webpack_require__(moduleId) {
  // 首先全局有一个模块对象，最先判断是否存在这个模块，是否做过相应操作，如果有则直接返回当前模块的一个对象，这里的exports其实就是一个对象
  if(installedModules[moduleId]) {
    return installedModules[moduleId].exports;
  }
  // 这里就直接创建了一个模块，并且缓存在全局的模块中，这里重点关注这个exports，
  // i 指的是模块的名称，比如 './src/main.js'
  // l 意思是当前模块是否加载
  // exports 就是返回出去的对象内容
  var module = installedModules[moduleId] = {
    i: moduleId,
    l: false,
    exports: {}
  };
  // 到这里就开始通过key去执行 modules（就是刚开始立即执行函数传过来的对象）对象的方法
  // 然后使用call来指向 对象的方法 的this，并且把 module, module.exports, __webpack_require__ 三个值传过去，
  // 这里先做预告，module这个参数传过去其实是没有用到的，主要使用 module.exports 对象, 以及__webpack_require__方法
  modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
  // 上面说到有一个参数 l，到这里当前模块已经加载
  module.l = true;
  // 最后把module.exports这个模块返回出去
  return module.exports;
}
```

接下来我们看看主入口'./src/main.js'这个key的值的内容

'./src/main.js'，原内容是这样的，接下来来解释一下

```js
{
  "./src/main.js": (function(module, __webpack_exports__, __webpack_require__) {
    "use strict";
    __webpack_require__.r(__webpack_exports__);
    /* harmony import */ var _a__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./a */ "./src/a.js");
    /* harmony import */ var _b__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./b */ "./src/b.js");

    console.log(_a__WEBPACK_IMPORTED_MODULE_0__["A1"], _a__WEBPACK_IMPORTED_MODULE_0__["A2"]);
    Object(_b__WEBPACK_IMPORTED_MODULE_1__["default"])();

  })
}
```

```js
{
  "./src/main.js": (function(module, __webpack_exports__, __webpack_require__) {
    // 上面我们说到 __webpack_require__ 方法内部会执行 modules[moduleId].call，并传递了三个参数，那么他执行的方法就是这个内部方法

    // 这段代码可以先忽略，在当前项目没有作用
    __webpack_require__.r(__webpack_exports__);

    // 我们看到下面有两段__webpack_require__函数代码的执行，你可以回顾一下main.js的内容，我们是不是做了 import { A1, A2 } from './a';并且 console.log(A1, A2);
    /* harmony import */ var _a__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./a */ "./src/a.js");
    /* harmony import */ var _b__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./b */ "./src/b.js");
    console.log(_a__WEBPACK_IMPORTED_MODULE_0__["A1"], _a__WEBPACK_IMPORTED_MODULE_0__["A2"]);

    // 这段代码其实是 import B from './b'; B();代码的执行
    Object(_b__WEBPACK_IMPORTED_MODULE_1__["default"])();

  })
}
```

好了，现在来分析一下 __webpack_require__("./src/a.js") 做了哪些操作，我们先来看看 模块`./src/a.js`的内容
`./src/a.js`
```js
{
  "./src/a.js": (function(module, __webpack_exports__, __webpack_require__) {
      __webpack_require__.r(__webpack_exports__);
      /* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "A1", function() { return A1; });
      /* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "A2", function() { return A2; });
      const A1 = 'a1';
      const A2 = 'a2';
 }),
}
```

代码内容很简单，首先 __webpack_require__("./src/a.js") 执行之后，会创建一个模块，然后去执行模块`./src/a.js`内部得方法，也是是上面这段，执行完成之后最终会把 `module.exports` 返回处理，
那么module.exports这个是什么内容呢？
看看 __webpack_require__ 内部
```js
var module = installedModules[moduleId] = {
    i: moduleId,
    l: false,
    exports: {}
  };
  // Execute the module function
  modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
  return module.exports
```
其实就是我们创建模块时的exports，然后执行到了模块`./src/a.js`内部得方法，它内部方法关键的地方在于又调用了 __webpack_require__.d 方法

__webpack_require__.d

```js
__webpack_require__.d = function(exports, name, getter) {
  if(!__webpack_require__.o(exports, name)) {
    Object.defineProperty(exports, name, { enumerable: true, get: getter });
  }
};
```
执行 __webpack_require__.d(__webpack_exports__, "A1", function() { return A1; }); 可以看出来他给 module.exports 定义了一个key值 "key"，然后取值get的时候返回的是 A1(也就是a1)

所以最终 `return module.exports` 的值为 {A1: 'a1'}，

我们回到 `./src/main.js` 模块，所以这段代码：var _a__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./a */ "./src/a.js");

 _a__WEBPACK_IMPORTED_MODULE_0__ 其实就是等于 {A1: 'a1'} console.log(_a__WEBPACK_IMPORTED_MODULE_0__["A1"])，取值为 a1，A2 同理