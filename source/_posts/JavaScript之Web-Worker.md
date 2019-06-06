---
title: JavaScript之Web Worker
date: 2018-09-10 10:29:38
tags:
- javascript
- 原创
categories: [javascript]
---

# 介绍

> Web Worker为Web内容在后台线程中运行脚本提供了一种简单的方法。线程可以执行任务而不干扰用户界面。此外，他们可以使用XMLHttpRequest执行 I/O  (尽管responseXML和channel属性总是为空)。一旦创建， 一个worker 可以将消息发送到创建它的JavaScript代码, 通过将消息发布到该代码指定的事件处理程序（反之亦然）。

# Web Worker使用要点

- 同源限制：分配给 Worker 线程运行的脚本文件，必须与主线程的脚本文件同源。

- DOM 限制：Worker 线程所在的全局对象，与主线程不一样，无法读取主线程所在网页的 DOM 对象，也无法使用document、window、parent这些对象。但是，Worker 线程可以navigator对象和location对象。

- 通信联系：Worker 线程和主线程不在同一个上下文环境，它们不能直接通信，必须通过消息完成。

- 脚本限制：Worker 线程不能执行alert()方法和confirm()方法，但可以使用 XMLHttpRequest 对象发出 AJAX 请求。

- 文件限制：Worker 线程无法读取本地文件，即不能打开本机的文件系统（file://），它所加载的脚本，必须来自网络。后面我们允许会做处理。

<!-- more -->
# 安装http-server

Worker 线程无法读取本地文件，即不能打开本机的文件系统（file://），它所加载的脚本，必须来自网络。所以我们得起一个项目。使用`http-server`最简单
安装：
```
> cnpm i -g http-server
```

使用：
```
> http-server
```

# 基本使用

我们新建一个文件夹名叫`worker`，里面新建三个文件分别是
```
index.html
main.js
worker.js
```

新建一个`worker`线程很简单，只需：

```
var worker = new Worker('worker.js')
```

`main.js`:
```js
var worker = new Worker('./worker.js')
console.log('worker running')
worker.addEventListener('message',e => {
    console.log('main: ', e.data);
})
// 也可使用：
// worker.onmessage = (e)=>{
//     console.log('main: ', e.data);
// }
worker.postMessage('hello worker,I am from main.js')
```

`worker.js`:
```js
console.log('worker task running')
onmessage = (e)=>{
    console.log('worker task receive', e.data);
    // 发送数据事件
    postMessage('Hello, I am from Worker.js');
}
```

在worker文件夹下，命令行输入http-server,启动项目，用浏览器打开，看控制台：
```
worker running
worker task running
worker task receive hello worker,I am from main.js
main:  Hello, I am from Worker.js
```
从上面可以看到，`worker`通过`onmessage`来监听数据，通过`postMessgae`来发送数据


## 终止 worker
```
worker.terminate();
```
## 处理错误
```
worker.addEventListener('error',  (e) => {
  console.log('main error', 'filename:' + e.filename + 'message:' + e.message + 'lineno:' + e.lineno;
});
```

- event.filename: 导致错误的 Worker 脚本的名称；
- event.message: 错误的信息；
- event.lineno: 出现错误的行号；

## 加载外部脚本

main.js
```js
var worker = new Worker('./worker1.js');
```

worker1.js
```js
console.log("I'm worker1")
importScripts('worker2.js', 'worker3.js');
// 或者
// importScripts('worker2.js');
// importScripts('worker3.js');
```
worker2.js
```js
console.log("I'm worker2")
```
worker3.js
```js
console.log("I'm worker3")
```

## 兼容性

[https://caniuse.com/#feat=webworkers](https://caniuse.com/#feat=webworkers)
兼容性还不是很乐观，不过在移动端的兼容性还不错


# 参考

[使用 Web Workers](https://developer.mozilla.org/zh-CN/docs/Web/API/Web_Workers_API/Using_web_workers)
[Web Worker 使用教程](http://www.ruanyifeng.com/blog/2018/07/web-worker.html)