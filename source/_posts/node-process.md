---
title: Nodejs之进程
date: 2020-04-15 15:04:18
tags:
- javascript
- Node
- 原创
categories: [Node,进程]
---

## 前言

> 本文大部分借鉴至深入浅出Node.js

本文开始讲一下 `Node` 的进程，`Node` 是建立在 `V8` 引擎之上的，程序基本上是运行在单进程的单线程上的，那么这样就会导致机器的资源没有被合理的利用，`CPU` 使用率低，所以我们需要多开进程，充分利用多核 `CPU` 服务器，但是多开进程又会面临进程管理方面的问题。下面我们来具体说说。

## 单线程？

我们知道 `JavaScript` 是单线程的，`Node` 也是？，`Node` 其实不是，`Node` 并非真正的单线程架构，`Node` 自身还有 一定的 `I/O` 线程存在，这些 `I/O` 线程由底层 `libuv` 处理，这部分线程对于 `JavaScript` 开发者而言是透明的，只在 `C++` 扩展开发时才会关注到。`JavaScript` 代码永远运行在 `V8` 上，是单线程的。

## 创建多进程

`Node` 提供了创建进程的方法，`child_process`，这里我们使用 `fork` 方法，它还有其他几个方法这里就不作介绍了
`master.js`
```js
const fork = require("child_process").fork
const cpus = require('os').cpus();
for (var i = 0; i < cpus.length; i++) {
  fork('./worker.js'); 
}
```
可以看到我们获取当前机器的 `cpu` 数量，然后批量创建子进程，我们新建 `worker.js`，内容如下
```js
const http = require("http");
process.title = "worker";
console.log(process.pid)
http
  .createServer(function(req, res) {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("Hello World\n");
  })
  .listen(Math.round((1 + Math.random()) * 1000);
```
启动
```
node master.js
```
控制台打印的pid
```
35115
35116
35117
35118
35119
35120
...
```

```js
            +--------+         
            | Master | <------ master.js
            +--------+        
            /   |     \
          /     |       \
        /       |        \ <----复制
      /         |          \
    v           v            v
+--------+   +--------+   +---------+
| 工作进程 |  | 工作进程 |   | 工作进程 | <------ worker.js
+--------+   +--------+   +---------+
```
<!-- more -->
## 多进程通信

进程通信使用 `send` 这个方法，如下
`master` -> `worker` 传递信息
```js
var fork = require("child_process").fork;
var cpus = require("os").cpus();
for (var i = 0; i < cpus.length; i++) {
  const worker = fork("./worker.js");
  worker.send("hello，I'm from master")
}
```
`worker`子进程接收
```js
process.on("message", function(message) {
  console.log("worker accept:", message);
});
```
运行结果如下：
```
worker accept: hello，I'm from master
worker accept: hello，I'm from master
worker accept: hello，I'm from master
```

`worker` -> `master`传递信息
`worker` 子进程发送消息
```js
process.send("hello，I'm from worker");
```
`master`接收
```js
var fork = require("child_process").fork;
var cpus = require("os").cpus();
for (var i = 0; i < cpus.length; i++) {
  const worker = fork("./worker.js");
  worker.on('message',function(){
    console.log("master accept:", message);
  })
}
```
主进程master收到消息，打印如下
```
master accept: hello，I'm from worker
master accept: hello，I'm from worker
master accept: hello，I'm from worker
```
### 进程间通信原理

`IPC` 的全称是`Inter-Process Communication`，即进程间通信。进程间通信的目的是为了让不同的进程能够互相访问资源并进行协调工作。实现进程间通信的技术有很多，如命名管道、匿名管 道、`socket`、信号量、共享内存、消息队列、`Domain Socket`等。`Node` 中实现 `IPC` 通道的是管道(`pipe`) 技术。但此管道非彼管道，在 `Node` 中管道是个抽象层面的称呼，具体细节实现由 `libuv` 提供，在 `Windows`下由命名管道(`named pipe`)实现，`*nix` 系统则采用 `Unix Domain Socket` 实现。表现在应 4 用层上的进程间通信只有简单的 `message` 事件和 `send()` 方法，接口十分简洁和消息化

```js
            IPC创建和实现示意图
  +--------+                  +--------+             
  | 父进程  | <---- IPC ---->  | 子进程  | 
  +--------+        |         +--------+    
                    |
                    |
                    v
                +--------+                  
                | libuv  |
                |  管道   |
                +--------+
                /        \
              /            \
            /                \
          /                   \
        v                       v
    +--------+        +----------------+
    | windows |       |     *nix       |  
    | 命名管道 |       | Domain Scocket |  
    +--------+        +----------------+
```
父进程在实际创建子进程之前，会创建 `IPC` 通道并监听它，然后才真正创建出子进程，并通 过环境变量(`NODE_CHANNEL_FD`)告诉子进程这个 `IPC` 通道的文件描述符。子进程在启动的过程中， 根据文件描述符去连接这个已存在的 `IPC` 通道，从而完成父子进程之间的连接。

```js
            创建IPC管道的步骤示意图
  +--------+                  +--------+             
  | 父进程  | -------------->  | 子进程  | 
  +--------+                  +--------+    
      \                           /
       \                         / 
      监听/接受                 连接
         \                     /
          \                   /
           \   +--------+    /                
            >  |   IPC  |  <
               +--------+
```
建立连接之后的父子进程就可以自由地通信了。由于 `IPC` 通道是用命名管道或 `Domain Socket` 创建的，它们与网络 `socket` 的行为比较类似，属于双向通信。不同的是它们在系统内核中就完成了进程间的通信，而不用经过实际的网络层，非常高效。在 `Node` 中，`IPC` 通道被抽象为 `Stream` 对象，在调用 `send()` 时发送数据(类似于`write()`)，接收到的消息会通过 `message` 事件(类似于 `data` ) 触发给应用层。

## 句柄传递

我们可以看到没创建一个进程就会随机监听一个端口，那么能不能让他们都监听一个端口？我们试试，把 `Math.round((1 + Math.random()) * 1000` 改为3000，让他们都监听3000端口
运行结果如下，报3000端口占用，只能开启一个3000端口的进程
```js
events.js:183
      throw er; // Unhandled 'error' event
      ^
Error: listen EADDRINUSE :::3000
```
为了解决这个问题，我们需要使用发送句柄功能，这个功能在版本 `v0.5.9` 引入。`send()` 方法除了能通过 `IPC` 发送数据外，还能发送句柄，第二个可选参数就是句柄，如下所示
```js
worker.send(message, [sendHandle])
```
那什么是句柄？句柄是一种可以用来标识资源的引用，它的内部包含了指向对象的文件描述符。比如句柄可以用来标识一个服务器端 `socket` 对象、一个客户端 `socket` 对象、一个 `UDP` 套接字、 一个管道等。

修改主进程代码 `master`
```js
const child = require("child_process").fork("worker.js");
const server = require("net").createServer();
server.on("connection", function(socket) {
  socket.end("handled by parent\n");
});
server.listen(3000, function() {
  child.send("server", server);
});
```
子进程代码worker
```js
process.on("message", function(message, server) {
  if (message === "server") {
    server.on("connection", function(socket) {
      socket.end("handled by child\n");
    });
  }
});
```
启动服务
```
node master.js
```
然后新建一个命令行窗口请求刚刚的服务
```
➜ curl "http://127.0.0.1:3000/"
handled by parent
➜ curl "http://127.0.0.1:3000/"
handled by child
➜ curl "http://127.0.0.1:3000/"
handled by parent
```
你会发现程序随机被主进程或者子进程处理

我们再多 `fork` 出一个子进程，刚刚只 `fork` 了一个，修改代码
mastet.js
```js
const cp = require('child_process'); 
const child1 = cp.fork('worker.js'); 
const child2 = cp.fork('worker.js');
const server = require('net').createServer(); 
server.on('connection', function (socket) {
  socket.end('handled by parent\n'); 
});
server.listen(3000, function () { 
  child1.send('server', server); 
  child2.send('server', server);
});
```
worker.js
```js
const http = require("http");
const server = http.createServer(function(req, res) {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("handled by child, pid is " + process.pid + "\n");
});
process.on("message", function(message, tcp) {
  if (message === "server") {
    tcp.on("connection", function(socket) {
      server.emit("connection", socket);
    });
  }
});
```
再用 `curl` 测试我们的服务，结果如下
```
➜  curl "http://127.0.0.1:3000/"
handled by child, pid is 35851
➜  curl "http://127.0.0.1:3000/"
handled by child, pid is 35852
➜  curl "http://127.0.0.1:3000/"
handled by parent
➜  curl "http://127.0.0.1:3000/"
handled by child, pid is 35852
➜  curl "http://127.0.0.1:3000/"
handled by child, pid is 35851
```
测试的结果是每次出现的结果都可能不同，结果可能被父进程处理，也可能被不同的子进程处理。并且这是在TCP层面上完成的事情，我们尝试将其转化到HTTP层面来试试。对于主进程 而言，我们甚至想要它更轻量一点，那么是否将服务器句柄发送给子进程之后，就可以关掉服务 器的监听，让子进程来处理请求呢?
我们对主进程进行改动，如下所示:
master.js
```diff
const cp = require('child_process'); 
const child1 = cp.fork('worker.js'); 
const child2 = cp.fork('worker.js');
const server = require('net').createServer(); 
server.on('connection', function (socket) {
  socket.end('handled by parent\n'); 
});
server.listen(3000, function () { 
  child1.send('server', server); 
  child2.send('server', server);
+  server.close();
});
```
再次重启发现不会出现 `handled by parent` 的打印信息了，这样所有的请求都交给子进程处理了

## 异常重启

我们上面讲了子进程的 `send` 方法和 `message` 事件，除了 `message` 事件外，还有如下事件
* `error`: 当子进程无法被复制创建、无法被杀死、无法发送消息时会触发该事件
* `exit`: 子进程退出时触发该事件，子进程如果是正常退出，这个事件的第一个参数为退出 码，否则为 `null`。如果进程是通过 `kill()` 方法被杀死的，会得到第二个参数，它表示杀死进程时的信号。
* `close`: 在子进程的标准输入输出流中止时触发该事件，参数与 `exit` 相同。
* `disconnect`: 在父进程或子进程中调用 `disconnect()` 方法时触发该事件，在调用该方法时将关闭监听IPC通道


修改代码
`master.js`
```js
const fork = require("child_process").fork;
const cpus = require("os").cpus();
const server = require("net").createServer();
server.listen(3000);
const workers = {};
const createWorker = function() {
  const worker = fork(__dirname + "/worker.js"); // 退出时重新启动新的进程
  worker.on("exit", function() {
    console.log("Worker " + worker.pid + " exited.");
    delete workers[worker.pid];
    createWorker();
  });
  // 句柄转发
  worker.send("server", server);
  workers[worker.pid] = worker;
  console.log("Create worker. pid: " + worker.pid);
};
for (let i = 0; i < cpus.length; i++) {
  createWorker();
}
// 进程自己退出时，让所有工作进程退出
process.on("exit", function() {
  for (let pid in workers) {
    workers[pid].kill();
  }
});
```
测试运行
```
➜  node master
Create worker. pid: 36736
Create worker. pid: 36737
Create worker. pid: 36738
Create worker. pid: 36739
Create worker. pid: 36740
Create worker. pid: 36741
Create worker. pid: 36742
Create worker. pid: 36743
Create worker. pid: 36744
Create worker. pid: 36745
Create worker. pid: 36746
Create worker. pid: 36747
```
我们使用命令行杀死一个进程
```
kill 36747
```
36747进程退出后，再看看刚刚的命令行窗口，是不是多了两段，杀死之后又重新创建了一个进程，这里主要是使用了事件 `exit`
```
Worker 36747 exited.
Create worker. pid: 36761
```

但是实际开发中，我们都不会主动去杀死某个进程，大多数都是因为程序错误，所以我们需要处理子进程的异常，修改 `worker.js`
```diff
const http = require("http");
const server = http.createServer(function(req, res) {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("handled by child, pid is " + process.pid + "\n");
});
let worker;
process.on("message", function(message, tcp) {
  if (message === "server") {
    worker = tcp;
    worker.on("connection", function(socket) {
      server.emit("connection", socket);
    });
  }
});
+process.on("uncaughtException", function() {
+  // 停止接收新的连接
+  worker.close(function() {
+    // 所有已有连接断开后，退出进程
+    process.exit(1);
+  });
+});
```
上述代码的处理流程是，一旦有未捕获的异常出现，工作进程就会立即停止接收新的连接; 当所有连接断开后，退出进程。主进程在侦听到工作进程的 `exit` 后，将会立即启动新的进程服务， 以此保证整个集群中总是有进程在为用户服务的

等等，刚刚一个进程程序出错了之后我们关闭了，那么少了一个进程，`CPU`没有完全利用，我们需要通知主进程去重新创建一个进程，这里给主进程发送自杀信号

worker
```diff
process.on("uncaughtException", function() {
+  process.send({act: 'suicide'});
  // 停止接收新的连接
  worker.close(function() {
    // 所有已有连接断开后，退出进程
    process.exit(1);
  });
});
```
mater.js主进程接收自杀信号
```diff
const fork = require("child_process").fork;
const cpus = require("os").cpus();
const server = require("net").createServer();
server.listen(3000);
const workers = {};
const createWorker = function() {
  const worker = fork(__dirname + "/worker.js"); // 退出时重新启动新的进程
+  worker.on("message", function(message) {
+    if (message.act === "suicide") {
+      createWorker();
+    }
+  });
  worker.on("exit", function() {
    console.log("Worker " + worker.pid + " exited.");
    delete workers[worker.pid];
    createWorker();
  });
  // 句柄转发
  worker.send("server", server);
  workers[worker.pid] = worker;
  console.log("Create worker. pid: " + worker.pid);
};
for (let i = 0; i < cpus.length; i++) {
  createWorker();
}
// 进程自己退出时，让所有工作进程退出
process.on("exit", function() {
  for (let pid in workers) {
    workers[pid].kill();
  }
});
```
我们模拟一个异常，修改子进程代码
```diff
...
const server = http.createServer(function(req, res) {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("handled by child, pid is " + process.pid + "\n");
+  throw new Error("throw exception");
});
...
```
然后启动所有的进程，如下
```
➜  node master
Create worker. pid: 37169
Create worker. pid: 37170
Create worker. pid: 37171
Create worker. pid: 37172
Create worker. pid: 37173
Create worker. pid: 37174
Create worker. pid: 37175
Create worker. pid: 37176
Create worker. pid: 37177
Create worker. pid: 37178
Create worker. pid: 37179
Create worker. pid: 37180
Create worker. pid: 37185
```
```
➜  curl http://127.0.0.1:3000/
handled by child, pid is 37173
```
回头看看
```
Worker 37173 exited.
Create worker. pid: 37189
```
嗯，工作正常了

## 状态共享

### 第三方数据存储

解决数据共享最直接、简单的方式就是通过第三方来进行数据存储，比如将数据存放到数据库、磁盘文件、缓存服务(如 `Redis` )中，所有工作进程启动时将其读取进内存中。但这种方式存在的问题是如果数据发生改变，还需要一种机制通知到各个子进程，使得它们的内部状态也得 到更新。
实现状态同步的机制有两种，一种是各个子进程去向第三方进行，定时轮询定时轮询带来的问题是轮询时间不能过密，如果子进程过多，会形成并发处理，如果数据没有发生改变，这些轮询会没有意义，白白增加查询状态的开销。如果轮询时间过长，数据发生改 变时，不能及时更新到子进程中，会有一定的延迟。

### 主动通知

一种改进的方式是当数据发生更新时，主动通知子进程。当然，即使是主动通知，也需要一种机制来及时获取数据的改变。这个过程仍然不能脱离轮询，但我们可以减少轮询的进程数量， 我们将这种用来发送通知和查询状态是否更改的进程叫做通知进程。为了不混合业务逻辑，可以将这个进程设计为只进行轮询和通知，不处理任何业务逻辑。
这种推送机制如果按进程间信号传递，在跨多台服务器时会无效，是故可以考虑采用 `TCP` 或 `UDP`的方案。进程在启动时从通知服务处除了读取第一次数据外，还将进程信息注册到通知服务处。一旦通过轮询发现有数据更新后，根据注册信息，将更新后的数据发送给工作进程。由于不 涉及太多进程去向同一地方进行状态查询，状态响应处的压力不至于太过巨大，单一的通知服务轮询带来的压力并不大，所以可以将轮询时间调整得较短，一旦发现更新，就能实时地推送到各个子进程中。

### Egg的agent模式

https://eggjs.org/zh-cn/core/cluster-and-ipc.html#agent-%E6%9C%BA%E5%88%B6
```js
                +--------+          +-------+
                | Master |<-------->| Agent |
                +--------+          +-------+
                ^   ^    ^
               /    |     \
             /      |       \
           /        |         \
         v          v          v
+----------+   +----------+   +----------+
| Worker 1 |   | Worker 2 |   | Worker 3 |
+----------+   +----------+   +----------+
```
1. `Master` 启动后先 `fork Agent` 进程
2. `Agent` 初始化成功后，通过 `IPC` 通道通知 `Master`
3. `Master` 再 `fork` 多个 `App Worker`
4. `App Worker` 初始化成功，通知 `Master`
5. 所有的进程初始化成功后，`Master` 通知 `Agent` 和 `Worker` 应用启动成功

另外，关于 Agent Worker 还有几点需要注意的是：

- 由于 `App Worker` 依赖于 `Agent`，所以必须等 `Agent` 初始化完成后才能 `fork App Worker`
- `Agent` 虽然是 `App Worker` 的『小秘』，但是业务相关的工作不应该放到 `Agent` 上去做，不然把她累垮了就不好了
- 由于 `Agent` 的特殊定位，我们应该保证它相对稳定。当它发生未捕获异常，框架不会像 `App Worker` 一样让他退出重启，而是记录异常日志、报警等待人工处理
- `Agent` 和普通 `App Worker` 挂载的 `API` 不完全一样，如何识别差异可查

## Cluster

`Cluster` 这个放到最后来将比较合适，`Cluster` 的实现机制是基于 `child_process` 的，`Node`基于 `child_process` 进一步封装了一下，来看看怎么使用

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
运行代码，则工作进程会共享 8000 端口：
```
➜  node server.js
主进程 3596 正在运行
工作进程 4324 已启动
工作进程 4520 已启动
工作进程 6056 已启动
工作进程 5644 已启动
```

是不是比之前我们用 `child_process` 更简单？不过这里推荐使用 `setupMaster` 来 `fork` 子进程，官方示例中忽而判断 `cluster.isMaster`、忽而判断 `cluster.isWorker`，对于代码的可读性十分差，`setupMaster()` 这个 `API`，将主进程和工作进程从代码上完全剥离， 如同 `send()` 方法看起来直接将服务器从主进程发送到子进程那样神奇，剥离代码之后，甚至都感觉不到主进程中有任何服务器相关的代码
通过 `cluster.setupMaster()` 创建子进程而不是使用 `cluster.fork()`，程序结构不再凌乱，逻辑分明，代码的可读性和可维护性较好。
```js
const cluster = require('cluster');
cluster.setupMaster({
  exec: 'worker.js',
  args: ['--use', 'https'],
  silent: true
});
cluster.fork(); // https 工作进程
cluster.setupMaster({
  exec: 'worker.js',
  args: ['--use', 'http']
});
cluster.fork();
```
在 `cluster` 模块应用中，一个主进程只能管理一组工作进程
```js
            +--------+         
            | Master |
            +--------+        
            /   |     \
          /     |       \
        /       |         \
      /         |          \
    v           v            v
+--------+   +--------+   +---------+
| 工作进程 |  | 工作进程 |   | 工作进程 |
+--------+   +--------+   +---------+
```
对于自行通过 `child_process` 来操作时，则可以更灵活地控制工作进程，甚至控制多组工作
进程。其原因在于自行通过 `child_process` 操作子进程时，可以隐式地创建多个 `TCP` 服务器，使得子进程可以共享多个的服务器端 `socket`
```js
                  +--------+         
                  | Master |
                  +--------+        
                  /   |     \
                /     |       \
              /       |         \
            /         |          \
          v           v            v
+------------+    +-----------+    +------------+
| 进程app1.js |   | 进程app2.js |   | 进程app3.js |
+------------+    +-----------+    +------------+
```

综上比较得出
1. `cluster` 是 `child_process` 演变而来
2. `cluster` 使用起来更方便，直接解决了端口占用的问题，`api`也足够用
3. `child_process` 更灵活，写起来代码会比较多

推荐二者结合起来使用，简单看了一下 [Egg](https://github.com/eggjs) 的源码，它就是这么做的。主进程 `fork` 使用 [cfork](https://github.com/node-modules/cfork)，`agent` 进程使用`child_process` `fork`而来


## 结尾

oh，又水一篇文章，代码基本参照`深入浅出Node.js`第九章玩转进程，在文章最后添加了一些最近看到的知识，加深一下印象和理解吧

## Reference

* [深入浅出Node.js](https://book.douban.com/subject/25768396/)

本文地址 [Nodejs之进程](http://www.wclimb.site/2020/04/15/node-process/)