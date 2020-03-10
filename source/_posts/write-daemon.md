---
title: 编写一个守护进程
date: 2020-03-08 22:09:44
tags:
- javascript
- 原创
- node
categories: [javascript,node]
---

## 为什么

我们编写`node`程序的时候，立马会去执行它，如下所示

```js
// app.js
const http = require("http");
http.createServer((req, res) => {
  res.end("hello world");
}).listen(3000);
```
执行下面命令运行
```
node app.js
```
我们接着访问`3000`端口，貌似没毛病。但是当你退出命令行窗口或者 `ctrl+c` 终止了程序，再去访问这个程序发现它炸了！你很不解，开始抱怨上天为什么这样对你，然后。。。额，算了，玩笑到此为止，那么怎么才能让它再后台运行呢？
<!-- more -->
## 背景

市面上也有很多进程守护工具，比如

- `pm2`
- `forever`

当然如果我们使用`docker`，就不需要这些了
## 编写

编写之前想运行流程
1. 创建一个父进程
2. 父进程下面构建出一个子进程
3. 父进程退出

第一个流程没问题，第二个，我们怎么创建一个子进程呢？这里我们需要借助`child_process`，名字就很明显了，子进程。我们可以借助方法 `spawn` 来实现，用得比较多的还有`exec`方法（可以执行`shell`命令）
```js
const spawn = require("child_process").spawn;
const child = spawn("node", ["app.js"], {
  detached: true,
  stdio: "ignore"
});
child.on("close", function(code) {
  console.log("close", code);
});
child.on("error", function(code) {
  console.log("error", code);
});
console.log(process.pid, child.pid);
```
![](/img/daemon-1.jpg)
从上图我们看到，开启了两个进程，`38715`是父进程，`38716`是子进程，至此我们实现了步骤二

接着我们实现步骤三，往下增加下面一段代码
```js
child.unref();
//or
process.exit()
```
现在我们可以打开浏览器查看3000端口是否依然可以访问正常

## 扩展-使用cluster

上面我们只开启了一个子进程，没有充分利用多核系统，尽可能的压榨机器。我们所熟知的`pm2`就是基于这个来实现的

下面是官网的一个示例，我们可以把之前的`app.js`替换为下面的代码
```js
const cluster = require('cluster');
const http = require('http');
const numCPUs = require('os').cpus().length;

if (cluster.isMaster) {
  console.log(`主进程 ${process.pid} 正在运行`);

  // 衍生工作进程。
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`工作进程 ${worker.process.pid} 已退出`);
  });
} else {
  // 工作进程可以共享任何 TCP 连接。
  // 在本例子中，共享的是 HTTP 服务器。
  http.createServer((req, res) => {
    res.writeHead(200);
    res.end('你好世界\n');
  }).listen(8000);

  console.log(`工作进程 ${process.pid} 已启动`);
}
```
![](/img/daemon-2.jpg)
可以看到我们又开启了多个子进程，来达到负载均衡，还有进程间通信相关的知识就不往下说了。

## 总结

至此我们实现了一个最最简单的守护进程，然而好像并没有什么用？感兴趣的可以去看 `pm2` 的源码，不过就是有点多。可以去看看 `egg-cluster` 的实现，关于这方面的知识还有很多需要学习的地方，行了，又有两车砖来了，今天先到这，希望下一篇可以深入分享

本文地址 [编写一个守护进程](http://www.wclimb.site/2020/03/08/write-daemon/)

