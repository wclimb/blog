---
title: webpack系列之编写一个plugin
date: 2019-06-21 09:17:19
tags:
- javascript
- 原创
- webpack
categories: [javascript,webpack]
---

## 写在前面

使用webpack或者自己配置研究过webpack的人都知道plugin，也就是webpack的插件，对于大多数人来说，经常使用的插件诸如：clean-webpack-plugin、html-webpack-plugin等等，在很多情况下，我们只会去用它，知道他是干什么的，但是其内部做的操作缺知之甚少，今天我们就来写一个plugin

## 基础

首先我们看看插件是怎么使用在webpack上的

```js
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
module.exports = {
  entry: '...',
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({
      filename: 'index.html',
      template: './index.html',
    }),
  ]  
}
```
我们经常使用的插件是长这样的，每个插件都是一个构造函数，通过new一个它的实例来使用。知道了插件是一个构造函数，那么我们可以推断出下面的结构
```js
class TestPlguin(){
  ...
}
```
webpack 插件由以下组成：
  - 一个 JavaScript 命名函数。
  - 在插件函数的 prototype 上定义一个 apply 方法。
  - 指定一个绑定到 webpack 自身的事件钩子。
  - 处理 webpack 内部实例的特定数据。
  - 功能完成后调用 webpack 提供的回调。

```js
class TestPlguin() {
  constructor(){
    
  }
  apply(compiler){
    compiler.plugin('webpacksEventHook', function(compilation /* 处理 webpack 内部实例的特定数据。*/, callback) {
      console.log("This is an example plugin!!!");

      // 功能完成后调用 webpack 提供的回调。
      callback();
    });
  }
}
```
上面是官网上的示例，插件一定会有apply方法，传递一个compiler参数，通过 CLI 或 Node API 传递的所有选项，创建出一个 compilation 实例。

在插件开发中最重要的两个资源就是 compiler 和 compilation 对象。理解它们的角色是扩展 webpack 引擎重要的第一步。

- compiler 对象代表了完整的 webpack 环境配置。这个对象在启动 webpack 时被一次性建立，并配置好所有可操作的设置，包括 options，loader 和 plugin。当在 webpack 环境中应用一个插件时，插件将收到此 compiler 对象的引用。可以使用它来访问 webpack 的主环境。
- compilation 对象代表了一次资源版本构建。当运行 webpack 开发环境中间件时，每当检测到一个文件变化，就会创建一个新的 compilation，从而生成一组新的编译资源。一个 compilation 对象表现了当前的模块资源、编译生成资源、变化的文件、以及被跟踪依赖的状态信息。compilation 对象也提供了很多关键时机的回调，以供插件做自定义处理时选择使用。

Compiler 和 Compilation 的区别在于：Compiler 代表了整个 Webpack 从启动到关闭的生命周期，而 Compilation 只是代表了一次新的编译

## 钩子

Compiler和Compilation都有生命周期

### Compiler

举几个例子

1. entryOption：在 entry 配置项处理过之后，执行插件
2. emit：生成资源到 output 目录之前。
3. failed：编译(compilation)失败

```js
class TestPlguin() {
  ...
  apply(compiler){
    compiler.hooks.emit.tap('MyPlugin', params => {
      console.log('我会在生成资源到 output 目录之前执行')
    })
  }
}
```
上面的例子意思是，当webpack执行到最终要输出文件得时候，我在这个操作之前去打印一段话，通常是我们输出文件到dist文件夹之前那一步
如果你实现写好了这些钩子，那么webpack在编译的流程里都会执行上面几个钩子。想了解更多访问 https://www.webpackjs.com/api/compiler-hooks/

### Compilation

Compilation 模块会被 Compiler 用来创建新的编译（或新的构建）。compilation实例能够访问所有的模块和它们的依赖（大部分是循环依赖）。它会对应用程序的依赖图中所有模块进行字面上的编译(literal compilation)。在编译阶段，模块会被加载(loaded)、封存(sealed)、优化(optimized)、分块(chunked)、哈希(hashed)和重新创建(restored)
 
简单的理解就是，当编译期间文件发生各种变化的时候，我们可以通过 Compilation 钩子里的生命周期函数去拦截，然后做你想做的事情

举几个例子

1. buildModule：在模块构建开始之前触发。
2. optimize：优化阶段开始时触发。
3. beforeChunkAssets：在创建 chunk 资源(asset)之前
4. additionalAssets：为编译(compilation)创建附加资源(asset)

```js
class TestPlguin() {
  ...
  apply(compiler){
    compiler.hooks.emit.tap('MyPlugin', compilation => {
      console.log('我会在生成资源到 output 目录之前执行')
      // 以下开始调用compilation钩子，当模块处在优化阶段开始时会执行以下回调
      compilation.plugin("optimize", function() {
        console.log("我在优化阶段开始时触发了");
      });
    })
  }
}
```

想了解更多访问 https://www.webpackjs.com/api/compilation-hooks/
