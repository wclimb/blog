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

使用`webpack`或者自己配置研究过`webpack`的人都知道plugin，也就是`webpack`的插件，对于大多数人来说，经常使用的插件诸如：`clean-webpack-plugin`、`html-webpack-plugin`等等，在很多情况下，我们只会去用它，知道他是干什么的，但是其内部做的操作缺知之甚少，今天我们就来写一个`plugin`

## 基础

首先我们看看插件是怎么使用在`webpack`上的

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
<!-- more -->
我们经常使用的插件是长这样的，每个插件都是一个构造函数，通过`new`一个它的实例来使用。知道了插件是一个构造函数，那么我们可以推断出下面的结构
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
上面是官网上的示例，插件一定会有`apply`方法，传递一个`compiler`参数，通过 `CLI` 或 `Node API` 传递的所有选项，创建出一个 `compilation` 实例。

在插件开发中最重要的两个资源就是 `compiler` 和 `compilation` 对象。理解它们的角色是扩展 `webpack` 引擎重要的第一步。

- `compiler` 对象代表了完整的 `webpack` 环境配置。这个对象在启动 `webpack` 时被一次性建立，并配置好所有可操作的设置，包括 `options`，`loader` 和 `plugin`。当在 `webpack` 环境中应用一个插件时，插件将收到此 `compiler` 对象的引用。可以使用它来访问 `webpack` 的主环境。
- `compilation` 对象代表了一次资源版本构建。当运行 `webpack` 开发环境中间件时，每当检测到一个文件变化，就会创建一个新的 `compilation`，从而生成一组新的编译资源。一个 `compilation` 对象表现了当前的模块资源、编译生成资源、变化的文件、以及被跟踪依赖的状态信息。`compilation` 对象也提供了很多关键时机的回调，以供插件做自定义处理时选择使用。

`Compiler` 和 `Compilation` 的区别在于：`Compiler` 代表了整个 `Webpack` 从启动到关闭的生命周期，而 `Compilation` 只是代表了一次新的编译

## 钩子

`Compiler`和`Compilation`都有生命周期

### Compiler

举几个例子

1. `entryOption`：在 `entry` 配置项处理过之后，执行插件
2. `emit`：生成资源到 `output` 目录之前。
3. `failed`：编译(compilation)失败

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
上面的例子意思是，当`webpack`执行到最终要输出文件得时候，我在这个操作之前去打印一段话，通常是我们输出文件到`dist`文件夹之前那一步
如果你实现写好了这些钩子，那么`webpack`在编译的流程里都会执行上面几个钩子。想了解更多访问 https://www.webpackjs.com/api/compiler-hooks/

### Compilation

`Compilation` 模块会被 `Compiler` 用来创建新的编译（或新的构建）。`compilation`实例能够访问所有的模块和它们的依赖（大部分是循环依赖）。它会对应用程序的依赖图中所有模块进行字面上的编译(literal compilation)。在编译阶段，模块会被加载(loaded)、封存(sealed)、优化(optimized)、分块(chunked)、哈希(hashed)和重新创建(restored)
 
简单的理解就是，当编译期间文件发生各种变化的时候，我们可以通过 `Compilation` 钩子里的生命周期函数去拦截，然后做你想做的事情

举几个例子

1. `buildModule`：在模块构建开始之前触发。
2. `optimize`：优化阶段开始时触发。
3. `beforeChunkAssets`：在创建 chunk 资源(asset)之前
4. `additionalAssets`：为编译(compilation)创建附加资源(asset)

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


## 编写插件

我们现在假定有一个这么个需求：我需要在打包的时候把一个外部的`js`文件导入到项目中，并且在`index.html`引入，你可能会问了，那你直接在主入口引入不就行了吗？确实，感觉做这件事情很没有意义，但是我就要这个需求，原因在于我在使用`DllPlugin`的时候，提前生成好了一堆文件，这些文件是不会在正常打包的过程引入的，所以我需要在最后打包生成文件之前把他们导入到`dist`文件夹下，并且引入他们。

那么我们现在开始编写，先写个简单的，一个文件的导入，抛砖引玉。

首先我们思考一下🤔，这个插件得有配置呀，和`html-webpack-plugin`一样可以传参数

```js
module.exports = {
  plugin: [
    new TestPlugin({
      filename: 'test.js',
      template: path.resolve(__dirname, './otherFile/test.js'),
    }),
  ]
}
```

我们在项目里新建文件夹`plugin`，文件夹下新建`TestPlugin.js`。然后在项目里再新建文件夹`otherFile`，文件夹下新建`test.js`，这里文件内容随便

上面我们说了需要传递参数，所以有了下面这段`js`，`options`是我们传递的对象，`apply`就不多说了，每个插件都有这个方法，然后我们把这个插件暴露出来
`TestPlugin.js`
```js
class TestPlugin {
  constructor(options = {}) {
    this.options = options;
  }
  apply(compiler) {
    
  }
}
module.exports = TestPlugin;
```

接下来我们开始写内部方法

我们又要思考一下，我需要在打包完成之前做这个操作，那么`compiler`钩子的生命周期函数是哪个呢？没错，是emit，之前讲过，于是乎有了下面这段js
`TestPlugin.js`
```js
class TestPlugin {
  constructor(options = {}) {
    this.options = options;
  }
  apply(compiler) {
    compiler.hooks.emit.tapAsync('TestPlugin', (compilation, callback) => {
      callback();
    });
  }
}
module.exports = TestPlugin;
```
上面代码，我们注册了一个`emit`，`webpack`在执行打包的最后，会触发这个内部得方法

接下来就是对文件得处理了，需要用到`compilation`

我们思考一下，怎么处理文件？我们需要用到`compilation`下的`asset`，来处理资源文件。
我们先把文件导入到`dist`文件夹下，于是乎有了下面这段js
`TestPlugin.js`
```js
const fs = require('fs');
class TestPlugin {
  constructor(options = {}) {
    this.options = options;
  }
  apply(compiler) {
    compiler.hooks.emit.tapAsync('TestPlugin', (compilation, callback) => {

      let template = fs.readFileSync(this.options.template, 'UTF-8');
      compilation.assets[this.options.filename || 'test.js'] = {
        source: function() {
          return template;
        },
        size: function() {
          return template.length;
        },
      };

      callback();
    });
  }
}
module.exports = TestPlugin;
```
上面代码，我们读取了插件实例传递过来的参数`filename`，调用`compilation`钩子下的`assets`，这个`assets`是一个键值对的形式，`key`是资源文件得名称，`value`是资源文件的内容，也是一个对象。执行`compilation.assets`，如果键值是一个已经存在的文件，`webpack`不会帮你重新创建，你可以去尝试修改一个文件

好了，文件导入了，但是我们还需要在`index.html`去引入这个文件，思考一下，这个`index.html`是已经存在的，我们同样可以使用`compilation.assets`去修改它的文件内容，所以有了下面这段`js`

`TestPlugin.js`
```js
const fs = require('fs');
class TestPlugin {
  constructor(options = {}) {
    this.options = options;
  }
  apply(compiler) {
    compiler.hooks.emit.tapAsync('TestPlugin', (compilation, callback) => {

      let template = fs.readFileSync(this.options.template, 'UTF-8');
      compilation.assets[this.options.filename || 'test.js'] = {
        source: function() {
          return template;
        },
        size: function() {
          return template.length;
        },
      };
      // 这里是新加的
      let source = compilation.assets['index.html'].source();
      source = source.replace(
        /<\/(.*?)>(.*?)<\/body>$/m,
        `</$1><script src="${this.options.filename ||
          'test.js'}"></script></body>`,
      );

      compilation.assets['index.html'] = {
        source: function() {
          return source;
        },
        size: function() {
          return source.length;
        },
      };

      callback();
    });
  }
}
module.exports = TestPlugin;
```
我们通过修改文件的`source`，把一段`script`插入到`body`之前来修改文件

插件写好了，我们在`webpack`去引入吧

```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const TestPlugin = require('./plugin/TestPlugin');
module.exports = {
  mode: 'production',
  entry: {
    app: './src/index.js',
  },
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(__dirname, 'dist/'),
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({ template: 'index.html' }),
    new TestPlugin({
      filename: 'test.js',
      template: path.resolve(__dirname, './otherFile/test.js'),
    }),
  ],
};
```

打包运行一下，看看效果吧

插件代码仓库：https://github.com/wclimb/webpack-plugin

## 总结

今天我们学习了一如何编写一个插件，当然只是简单的操作了，可以思考一下，要实现`clean-webpack-plugin`或者`html-webpack-plugin`插件，我们该怎么做？

本文地址 [webpack系列之输出文件分析](http://www.wclimb.site/2019/06/21/webpack系列之编写一个plugin/)
