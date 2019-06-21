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