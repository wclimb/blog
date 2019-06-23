---
title: webpack系列之初探
date: 2019-06-06 09:09:42
tags:
- javascript
- 原创
- webpack
categories: [javascript,webpack]
---

## 写在前面

相信`webpack`这个名称对于前端的同学来说并不陌生，只要你在用`vue`、`react`等等之类的框架，就得天天和它打交道。但是大部分人都只是直接怼一个`vue-cli`脚手架生成一个项目，运行起来就开始一顿写，完全不会去看这个项目的其他相关的东西，今天开始，咱们就来说说这个又爱又恨的`webpack`

## 问题

使用wepack的时候经常会出现下面这些疑问

1. <font color=red>你webpack只能打包单页面的文件吗？</font>
2. <font color=red>WTF，我包怎么这么大，加载太慢了</font>
3. <font color=red>我打包速度怎么这么慢，什么破玩意？</font>
...

## 为什么要使用webpack

哈，你问我为什么要用？因为大家都在用啊😃😃。开个玩笑，前端发展到今天，新技术新思想新框架爆发式增长，当前的浏览器环境跑不赢啊，你说你写个ES6/7在浏览器环境都能跑起来？扯淡的。这个时候`babel`就出现了，你跑不起来是吧，那我转成`ES5`你总该跑起来吧~，那`babel`我还是不能直接用啊，肯定得借助工具编译呀，所以我们需要webpack去做这件事情了。<font color=red>这个时候有人就要站出来说了，我gulp不服，我也能做，我就不用`webpack`</font>。你这么说我就要跟你唠唠了，现在我们先来比较一下`webpack`和`gulp`。

`gulp` 是 `task runner`，`Webpack` 是 `module bundler`

webpack的优势在模块化，`gulp`除了模块化方面都很不错。但是前端发展至今，模块化真的很重要，`CMD`、`AMD`就是模块化的产物。
简单来说，如果你当前项目需要模块化编程，那就选`webpack`，如果是处理其他事情，比如把图片拼接成雪碧图或者压缩，那么`gulp`是最擅长的

感兴趣的可以看看这个回答 [gulp 有哪些功能是 webpack 不能替代的？](https://www.zhihu.com/question/45536395/answer/164361274)

## 安装

这里可以参考[webpack官网](https://www.webpackjs.com/guides/getting-started/#%E5%9F%BA%E6%9C%AC%E5%AE%89%E8%A3%85)
开发环境 `webpack: 4.34.0`
```
> mkdir webpack && cd webpack
> npm init -y
> npm install webpack webpack-cli -D
```

## 入口（entry）

每个`webpack`都会有一个`entry`，就是入口的意思，指示 `webpack` 应该使用哪个模块，来作为构建其内部依赖图的开始。

注意点：
1. 入口可以有多个，如果是单页面只需要一个入口，多页面可以设置多个路口
2. 入口的文件必须是`.js`文件，因为`webpack`只认识`js`

举个🌰
<!-- more -->
我们新建`webpack.config.js`和新建`src`文件夹，并且文件夹下新建`index.js`文件
目录如下

```
- webpack/
-   src/
-     index.js
-   webpack.config.js
```

webpack.config.js
```js
module.exports = {
  entry: './src/index.js'
};
```

我们上面指定`webpack`的入口文件为`index.js`文件，这是总入口

## 出口（output）

有入口当然就会有出口了，就是你导出的文件

webpack.config.js
```js
module.exports = {
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  }
};
```

上述`entry`已经介绍过了，我们来看看`output`，他有文件导出的路径（path）和导出的文件名（filename）

关于`filename`这里需要注意的地方有：
1. 出口的文件名可以定制化，当前如果你是单页面的话，简单的可以写死一个filename，就如上面的`bundle.js`一样
2. 你也可以这么写，使用入口名称的名称：`filename: '[name].bundle.js'`,当然还需要改一下entry，把它改成以下形式，name就会变成 -> app

```js
module.exports = {
  entry: {
    app: './src/index.js'
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  }
};
```

现在我们来试一下webapck打包

## 小试牛刀

第一步，新建一个文件夹webpack-demo
```
> mkdir webpack-demo && cd webpack-demo
> npm init -y
> cnpm install webpack webpack-cli -D
```
第二步，新建src/index.js文件和webpack.config.js文件

webpack.config.js

```js
const path = require('path');
module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist/'),
  },
};
```

index.js
```js
document.write('hello webpack');
```

第三步，打包
命令行输入
```
> npx webpack --config webpack.config.js
```
然后控制台就会输出
```
Hash: 348dca17387cd3f29cef
Version: webpack 4.33.0
Time: 227ms
Built at: 2019-06-08 15:24:07
    Asset       Size  Chunks             Chunk Names
bundle.js  961 bytes       0  [emitted]  main
Entrypoint main = bundle.js
[0] ./src/index.js 33 bytes {0} [built]
```
看到这个信息证明你已经大功告成了，去看看dist/文件夹下是不是有打包好的js文件
最后面你会看到有黄色的警告，说mode没有设置，待会再讲

<font color=red>这个时候你就会想，我每次生成的文件都叫bundle.js，我都区分不开，也不好做缓存，这个时候你就需要配置一下filename了</font>

我们把webpack.config.js改成以下

```js
const path = require('path');
module.exports = {
  entry: {
    app: './src/index.js',
  },
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(__dirname, 'dist/'),
  },
};
```
然后执行 
```
> npx webpack --config webpack.config.js
```

这个时候dist/文件夹下就会多出个类似`app.32434c7cc602e3049dac.js`的文件，而且如果你反复执行打包命令，你发现app.32434c7cc602e3049dac.js文件名都没有改变，这是为什么呢？
因为webpack会判断你的文件是否有更改而来觉得文件夹hash的变更，现在你可以尝试修改一下index.js文件之后打包的效果就知道了。


## 模式（mode ）

上面说到每次打包的时候都会报警告，告诉我们没有设置mode，现在我们来说说mode
首先mode有两个值，分别是development和production，意思就是，当前项目打包的开发环境还是生成环境的代码
如果你设置了mode: 'development'，在项目里你可以使用 process.env.NODE_ENV 来获取当前的环境的值
你可以尝试把webpack.config.js改成以下，然后在index.js里把这个值打印出来，运行一下效果

webpack.config.js
```js
const path = require('path');
module.exports = {
  mode: 'development',
  entry: {
    app: './src/index.js',
  },
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(__dirname, 'dist/'),
  },
};
```
index.js
```js
document.write(`hello webpack，this is ${process.env.NODE_ENV}`); 
```
现在我们只有js文件，你可以先在根目录新建一个index.html文件，把js引入在浏览器环境执行(或者直接在浏览器控制台执行js)，你会看到浏览器显示 -> hello webpack，this is development
你分别运行之后会发现他们的效果是不一样的，一个是被压缩的，一个没有被压缩

<font color=red>这个时候你就会想了，怎么这么麻烦，我打包还得自己去新建html文件引入js然后运行或者去执行js文件，能不能让他自动运行跑起来？</font>
当然是可以的，下面我们来说说plugins

## 插件（plugins）

插件是 webpack 的支柱功能。webpack 自身也是构建于，你在 webpack 配置中用到的相同的插件系统之上！（官网的解释）
插件怎么说呢？不好解释它，你可以理解为处理工具，插件目的在于解决 `loader`(这个等会再讲，现在用不上) 无法实现的其他事

插件怎么配置？就像下面这样，当然不是随便找的插件，我们会用到下面配置的插件

```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
module.exports = {
  mode: 'development',
  entry: {
    app: './src/index.js',
  },
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(__dirname, 'dist/'),
  },
  plugins: [
    new HtmlWebpackPlugin({template: 'index.html'})
  ]
};
```
我们先在根目录新建一个index.html文件，之前不是说运行项目很麻烦嘛？现在教你简单的方法
然后我们用到了html-webpack-plugin，需要先安装他才能使用
```
> cnpm i html-webpack-plugin -D
```
下一步打包运行项目
```
> npx webpack --config webpack.config.js
```
运行结果：
```
Hash: bea857ae13cad8af6e66
Version: webpack 4.33.0
Time: 274ms
Built at: 2019-06-08 16:00:33
                      Asset      Size  Chunks             Chunk Names
app.bea857ae13cad8af6e66.js  3.83 KiB     app  [emitted]  app
                 index.html  74 bytes          [emitted]  
Entrypoint app = app.bea857ae13cad8af6e66.js
[./src/index.js] 65 bytes {app} [built]
Child html-webpack-plugin for "index.html":
     1 asset
    Entrypoint undefined = index.html
    [./node_modules/_html-webpack-plugin@3.2.0@html-webpack-plugin/lib/loader.js!./index.html] 209 bytes {0} [built]
    [./node_modules/_webpack@4.33.0@webpack/buildin/global.js] (webpack)/buildin/global.js 472 bytes {0} [built]
    [./node_modules/_webpack@4.33.0@webpack/buildin/module.js] (webpack)/buildin/module.js 497 bytes {0} [built]
        + 1 hidden module
```
去查看dist文件夹下，你会发现多出了两个文件，js和index.html文件，这就是插件的功劳
html-webpack-plugin这个插件需要指定是那个html模板，然后最后打包的时候就是以这个模板为主，把打包好的js文件放到这个index.html里面，你可以查看html文件里的内容：

index.html
```html
<script type="text/javascript" src="app.1b0b2001b0579faec32d.js"></script>
```
<font color=red>这个时候你会发现，我靠，我dist文件怎么这么多啊，怎么办啊？别急，我们再来用一个插件解决这个问题</font>

安装插件clean-webpack-plugin
```
> cnpm i clean-webpack-plugin -D
```
然后配置文件去添加插件

```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
module.exports = {
  mode: 'development',
  entry: {
    app: './src/index.js',
  },
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(__dirname, 'dist/'),
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({template: 'index.html'})
  ]
};
```

然后你再去看看dist文件夹里的文件，是不是只有两个文件了？这个插件的作用是，先把dist文件夹里的文件先清空然后再把打包好的文件放入dist。

<font color=red>那么你还会有问题，这还是麻烦啊，我不能只运行命令行，让重新自己打开浏览器运行我打包的项目吗？</font>当然可以啊

首先安装 webpack-dev-server
```
> cnpm i webpack-dev-server -D
```
然后
```
> webpack-dev-server --open --config webpack.config.js
```
你会发现重新自动打开了浏览器，页面显示 hello webpack，this is development。是不是很简单？
你现在可以去修改index.js然后保存文件，去浏览器看看是不是自动刷新了你刚刚更改的内容呢？

<font color=red>现在你可能还会有问题，我去，这太简单了吧，我要用css和图片怎么办？js不能导入css文件啊！我怎么跟vue一样在自己的ip访问项目啊？现在肯定是问题一大堆</font>

## loader

loader 用于对模块的源代码进行转换。loader 可以使你在 import 或"加载"模块时预处理文件。比如可以把typescript转换成JavaScript，less转成css
现在我们就来解决你上一章节末的问题，教你配置简单的loader，来加载css或者图片
首先我们先安装css-loader/style-loader，来加载解析css文件
```
> cnpm i css-loader style-loader -D
```
下一步在src文件夹下新建test.css文件，再在index.js导入
test.css
```css
body {
  background: #ccc;
}
```

index.js
```js
import './test.css';
document.write(`hello webpack，this is ${process.env.NODE_ENV}，test`);
```
如果你直接运行会发现控制台报错了 
```
ERROR in ./src/test.css 1:5
Module parse failed: Unexpected token (1:5)
You may need an appropriate loader to handle this file type.
> body {
|   background: #ccc;
| }
 @ ./src/index.js 1:0-20
```
这个时候loader登场了，我们修改配置文件
webpack.config.js
```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
module.exports = {
  mode: 'development',
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
  ],
  module: {
    rules:[
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
    ]
  }
};
```
然后运行命令行
```
> webpack-dev-server --open --config webpack.config.js
```
你会发现页面背景颜色变了

现在我们来说说配置：
module.rules 允许你在 webpack 配置中指定多个 loader，上面我们规定正则匹配css文件，然后如果匹配到了，则使用style-laoder和css-loader去处理css文件，css-laoder负责解析css文件，style-loader负责把css文件放到页面中去，你打开调试可以看到head里被插入了style样式标签，当前如果你想解析例如xx.ts文件，则可以在数组里面新增：
```js
 {
  test: /\.ts$/,
  use: 'ts-loader',
},
```

下面来看看怎么加载图片资源，还是跟上述原一样，图片也是有类型的，我们首先得匹配文件后缀，然后去用loader去解析他们，这里我们需要用到 url-loader file-loader
按照惯例先安装
```
> cnpm i url-loader file-loader -D
```
```js
module.exports = {
  ...
  module: {
    rules:[
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|jpe?g|gif|svg)(\?.*)?$/,
        loader: 'url-loader',
        options: {
          limit: 6000,
          name: 'img/[name].[hash:7].[ext]',
        },
      }
    ]
  }
};
```
下一步就是往项目里增加图片了
我们修改test.css文件
test.css
```
body {
  background: url(img.jpg);
}
```

浏览器就显示的全是刚刚设置的重复图片了

** 这里你又会问了，不对，你这里只用到了url-loader，file-loader不是多余的吗？** 不是的，你可以看看options，有一个limit参数，规定如果超过了6000bytes大小的文件会交给file-loader处理，因为如果图片小于这个数值，url-loader会把图片转成base64格式的图片加载，如果超过就自己不处理了，所以他们两者是有相依性的


## 使用npm脚本

上面基本上都是使用一大段的命令行来执行项目，现在我们来简化一下
修改package.json
```js
"scripts": {
  "dev": "webpack-dev-server --open --config webpack.config.js",
  "build": "webpack --config webpack.config.js"
},
```
命令行运行项目
```
> npm run dev
> npm run build
```

## devServer

在开发中你可能有很多需求，比如怎么通过ip访问项目，怎么把控制台信息输出的精简点，怎么修改端口等等？这个时候就需要用到devServer的配置了
我们修改webpack.config.js,增加以下：

```js
module.exports = {
  ...
  devServer: {
    contentBase: './dist', // 告诉服务器从哪里提供内容
    host: '0.0.0.0', // 指定使用一个 host。默认是 localhost
    useLocalIp: true, // 是否使用本地ip
    open: true, // 是否自动打开浏览器
    port: 8080, // 端口号
    noInfo: true, // 显示的 webpack 包(bundle)信息」的消息将被隐藏
  },
}
```
是的，你现在可以不用在命令行里增加--open这个参数，在这里配置也是一样的

## 最后

累了累了，写到这已经是凌晨了。不多BB了，现在基本的webpack操作应该都已经学会了吧，后面就是稍微深入的玩一玩webpack了，成为一个webpack配置工程师？

<font size=10>to be continued...</font>

本文地址 [webpack系列之初探](http://www.wclimb.site/2019/06/06/webpack%E7%B3%BB%E5%88%97%E4%B9%8B%E5%88%9D%E6%8E%A2/)
