---
title: webpack系列之编写一个loader
date: 2019-07-05 09:24:45
tags:
- javascript
- 原创
- webpack
categories: [javascript,webpack]
---

## 写在前面

`webpack`的`loader`的应用是非常广泛的，完全离不开它，我们开发的过程往往都是使用别人编写好的`loader`来处理文件，今天我们就来编写一个`loader`。

## 基础

首先我们看看`loader`是怎么使用在`webpack`上的

```js
module.exports = {
  entry: '...',
  module: {
    rules: [
      {
        test: /\.css$/,
        use: 'css-loader',
      },
    ],
  },
}
```
使用起来很简单，如果你需要处理`css`文件，那么安装好`css-loader`包，然后正则匹配到所有`.css`的文件，使用`css-loader`进行文件得处理

<!-- more -->

## 编写

编写之前我们先给定个需求吧，设想我们能不能像vue那样编写，处理`style/script/template`，这样，我们先只处理`style`的内容，把他提取处理。

### 安装

```
> npm init -y
> cnpm i webpack webpack-cli webpack-dev-server clean-webpack-plugin html-webpack-plugin -D
```

### 配置

先来编写一个配置文件

新建文件 `webpack.config.js`
```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
module.exports = {
  entry: './src/main.js',
  output: {
    path: path.resolve(__dirname, './dist'),
    filename: 'bundle.js',
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({ template: 'index.html' }),
  ],
  module: {
    rules: [
      {
        test: /\.css/,
        use: path.resolve(__dirname, 'loader/loader.js'),
      },
    ],
  },
};
```

项目下新建`src`文件夹，`src`项目新建`main.js`、`a.test`文件

`main.js`
```js
import './a.test';
console.log('loader test');
```
`a.test`
```css
<style>
body{
  background: #ccc
}
</style>
```
我们重点是`a.test`文件，等会我会用`loader`处理他，让他显示到页面中

-----------分割线-----------

现在我们在项目下新建`loader`文件夹，文件夹下面新建`loader.js`，这就是我们编写的`loader`

`loader/loader.js`
```js
module.exports = function(sSource) {
  let sStyleString = sSource
    .match(/<style>([\s\S]*)<\/style>/)[1]
    .replace(/\n/g, '');
  return `
      let head = document.querySelector('head');
      let style = document.createElement('style');
      style.type = 'text/css';
      let cssNode = document.createTextNode('${sStyleString}');
      style.appendChild(cssNode);
      head.appendChild(style);`;
};
```

没错，就这么多，`loader`接收一个参数，也就是`sSource`，内容就是`.test`后缀下的文件内容，我们只需要获取内容，然后做我们想做的一切事情，比如，我提取了文件里`css`的部分，像`.vue`那样，然后去写一段`js`，把这段`css`通过`<style></style>`的方式放到页面上去

现在你运行一下这个项目，然后查看浏览器，浏览器的背景是否变了颜色？

## api

`loader`的上下文通过`this`访问，举几个例子

### this.query

1. 如果这个 `loader` 配置了 `options` 对象的话，`this.query` 就指向这个 `option` 对象
2. 如果 `loader` 中没有 `options`，而是以 `query` 字符串作为参数调用时，`this.query` 就是一个以 `?` 开头的字符串

### this.context

模块所在的目录

### this.emitFile

```js
emitFile(name: string, content: Buffer|string, sourceMap: {...})
```
可以通过用它来生成一个文件

## 总结

写一个`loader`很简单，只需要你有对文件内容处理的能力，还是很容易上手的，关键不在`loader`，而在于你的需求复杂程度

本文地址 [webpack系列之编写一个loader](http://www.wclimb.site/2019/07/05/webpack系列之编写一个loader/)
