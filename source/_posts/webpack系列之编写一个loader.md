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

webpack的loader的应用是非常广泛的，完全离不开它，我们开发的过程往往都是使用别人编写好的loader来处理文件，今天我们就来编写一个loader。

## 基础

首先我们看看loader是怎么使用在`webpack`上的

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
使用起来很简单，如果你需要处理css文件，那么安装好css-loader包，然后正则匹配到所有.css的文件，使用css-loader进行文件得处理

<!-- more -->

## 编写

编写之前我们先给定个需求吧，设想我们能不能像vue那样编写，处理style/script/template，这样，我们先只处理style的内容，把他提取处理。

### 安装

```
> npm init -y
> cnpm i webpack webpack-cli webpack-dev-server clean-webpack-plugin html-webpack-plugin -D
```

### 配置

先来编写一个配置文件

新建文件 webpack.config.js
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

项目下新建src文件夹，src项目新建main.js、a.test文件

main.js
```js
import './a.test';
console.log('loader test');
```
a.test
```css
<style>
body{
  background: #ccc
}
</style>
```
我们重点是a.test文件，等会我会用loader处理他，让他显示到页面中

-----------分割线-----------

现在我们在项目下新建loader文件夹，文件夹下面新建loader.js，这就是我们编写的loader

loader/loader.js

```js

```

