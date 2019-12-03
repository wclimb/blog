---
title: Docker快速入门
date: 2019-12-03 09:18:04
tags:
- 原创
- 教程
- Docker
categories: [Docker, 教程]
---



## 什么是Docker？

`Docker` 是一个开源的应用容器引擎，可以让开发者打包他们的应用以及依赖包到一个轻量级、可移植的容器中，然后发布到任何流行的 `Linux` 机器上，也可以实现虚拟化

## 为什么要用Docker


### 更高效的利用系统资源

  由于容器不需要进行硬件虚拟以及运行完整操作系统等额外开销，`Docker` 对系统资源的利用率更高。无论是应用执行速度、内存损耗或者文件存储速度，都要比传统虚拟机技术更高效。因此，相比虚拟机技术，一个相同配置的主机，往往可以运行更多数量的应用。


### 更快速的启动时间


  传统的虚拟机技术启动应用服务往往需要数分钟，而 `Docker` 容器应用，由于直接运行于宿主内核，无需启动完整的操作系统，因此可以做到秒级、甚至毫秒级的启动时间。大大的节约了开发、测试、部署的时间。
<!-- more -->
### 一致的运行环境

  开发过程中一个常见的问题是环境一致性问题。由于开发环境、测试环境、生产环境不一致，导致有些 `bug` 并未在开发过程中被发现。而 `Docker` 的镜像提供了除内核外完整的运行时环境，确保了应用运行环境一致性，从而不会再出现 「这段代码在我机器上没问题啊」 这类问题
### 持续交付和部署

  对开发和运维人员来说，最希望的就是一次创建或配置，可以在任意地方正常运行。

  使用 `Docker` 可以通过定制应用镜像来实现持续集成、持续交付、部署。开发人员可以通过 `Dockerfile` 来进行镜像构建，并结合 持续集成系统进行集成测试，而运维人员则可以直接在生产环境中快速部署该镜像，甚至结合 持续部署系统进行自动部署。

  而且使用 `Dockerfile` 使镜像构建透明化，不仅仅开发团队可以理解应用运行环境，也方便运维团队理解应用运行所需条件，帮助更好的生产环境中部署该镜像。

### 更轻松的迁移

  由于 `Docker` 确保了执行环境的一致性，使得应用的迁移更加容易。`Docker` 可以在很多平台上运行，无论是物理机、虚拟机、公有云、私有云，甚至是笔记本，其运行结果是一致的。因此用户可以很轻易的将在一个平台上运行的应用，迁移到另一个平台上，而不用担心运行环境的变化导致应用无法正常运行的情况。

### 更轻松的维护和扩展

  使用的分层存储以及镜像的技术，使得应用重复部分的复用更为容易，也使得应用的维护更新更加简单，基于基础镜像进一步扩展镜像也变得非常简单。此外，`Docker` 团队同各个开源项目团队一起维护了一大批高质量的 官方镜像，既可以直接在生产环境使用，又可以作为基础进一步定制，大大的降低了应用服务的镜像制作成本。


### 对比传统虚拟机总结

| 特性   | 容器    |  虚拟机  |
| :----: | :----:   | :----: |
|   启动    |   秒级    |   分钟级    |
|   硬盘使用    |   一般为 MB    |   一般为 GB    |
|   性能    |   接近原生    |   弱于    |
|  系统支持量    | 单机支持上千个容器      |   一般几十个    |


以上摘自 https://yeasy.gitbooks.io/docker_practice/introduction/why.html


## 安装

1. 注册账号 https://hub.docker.com/
2. 下载安装Docker [mac安装地址](https://download.docker.com/mac/stable/Docker.dmg)
3. 命令行输入 `docker --version` 查看当前 `Docker` 版本
4. 镜像加速，鉴于国内网络问题，后续拉取 Docker 镜像十分缓慢，我们可以需要配置加速器来解决。`Docker for mac 应用图标 -> Perferences... -> Daemon -> Registry mirrors`，在列表中填写加速器地址 `http://hub-mirror.c.163.com`。修改完成之后点击 Apply & Restart 按钮。最后我们输入命令行 `docker info` 查看当前使用的镜像


## 实战

我们先快速搭建一个`web`服务器
命令行输入
```
docker run -p 80 --name web -it centos /bin/bash
```
然后安装 `nginx`
```
rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum install -y nginx
```
安装完成可以通过命令`whereis nginx`查看安装路径，最后输入一下命令
```
nginx
```
最后我们执行 `ctrl + P + Q` 切换到后台，输入命令 `docker ps -a` 查看分配的端口号，我这里是端口号是32768

```
CONTAINER ID    IMAGE      COMMAND         CREATED            STATUS               PORTS                   NAMES
3db42e2903a0    centos    "/bin/bash"    About a minute ago   Up About a minute    0.0.0.0:32768->80/tcp    web
```

浏览器输入 http://localhost:32768 ，看到 `Welcome to nginx` 就算成功了


那么我们刚刚输入的一系列命令代表什么意思呢？

我们输入`docker run -p 80 --name web -it centos /bin/bash` 

- `docker run`表示运行一个新的容器，`Docker` 首先在本机中寻找该镜像，如果没有安装，`Docker` 在 `Docker Hub` 上查找该镜像并下载安装到本机，最后 `Docker` 创建一个新的容器并启动该程序
- `-i` 选项是让容器标准输入打开，就可以接受键盘输入了
- `-t` 选项是让docker分配一个伪终端，绑定到标准输入上。通过这个伪终端就可以像操作一台 `linux` 机器来操作这个容器了
- `--name` <容器名称> 选项为容器指定一个名称，这里是`web`
- `-p 80` 告诉`docker`开放`80`端口

我们需要注意的是，`docker run`每次都会创建一个新的容器，如果需要操作之前创建的容器

重启容器
```
docker start web
```

进入容器
```
docker attach web
```

停止容器
```
docker stop web
```
## 镜像

我们运行容器都需要镜像，上面我们使用到的的镜像是 `centos`

查看本地镜像
```
docker images
```
显示
```
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
nodejs                latest              779742e01ba3        2 weeks ago         907MB
node                  latest              4ac0e1872789        5 weeks ago         933MB
nginx                 latest              540a289bab6c        5 weeks ago         126MB
nginx                 stable-alpine       aaad4724567b        6 weeks ago         21.2MB
centos                latest              0f3e07c0138f        2 months ago        220MB
```

- `REPOSITORY`：仓库名称。
- `TAG`： 镜像标签，其中 lastest 表示最新版本。注意的是，一个镜像可以有多个标签，那么我们就可以通过标签来管理有用的版本和功能标签。
- `IMAGE ID` ：镜像唯一ID。
- `CREATED` ：创建时间。
- `SIZE` ：镜像大小。

如果第一次我们通过 `docker pull centos:latest` 拉取镜像，那么当我们执行 `docker run -p 80 --name web -it centos /bin/bash` 时，它就不会再去远程获取了，因为本机中已经安装该镜像，所以 `Docker` 会直接创建一个新的容器并启动该程序。

事实上，镜像有很多，我们可以在 https://hub.docker.com 搜索仓库，输入框输入`nginx`，会出现很多nginx相关的镜像，我们也可以使用 `docker search nginx` 获取镜像列表
```
$ docker search nginx

NAME                              DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
nginx                             Official build of Nginx.                        12284               [OK]
jwilder/nginx-proxy               Automated Nginx reverse proxy for docker con…   1696                                    [OK]
richarvey/nginx-php-fpm           Container running Nginx + PHP-FPM capable of…   746                                     [OK]
......
```
直接通过 `docker pull nginx` 就可以拉取镜像


## 构建自己的镜像

要想构建自己的镜像，需要有一个`Dockerfile`文件，现在我们尝试把 `node` 程序 `Docker` 化

### 创建 Node.js 应用
```js
{
  "name": "docker_web_app",
  "version": "1.0.0",
  "description": "Node.js on Docker",
  "author": "First Last <first.last@example.com>",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.16.1"
  }
}
```
然后，创建一个 `server.js` 文件，使用 `Express.js` 框架定义一个 Web 应用
```js
'use strict';

const express = require('express');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
  res.send('Hello world\n');
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);

```
### Dockerfile

创建一个空文件，命名为 Dockerfile
```
touch Dockerfile
```
Dockerfile
```
# node版本为10的镜像
FROM node:10

# 应用程序工作目录
WORKDIR /usr/src/app

# 拷贝文件，有两种方法ADD、COPY，用法都一样，唯一不同的是 ADD  支持将归档文件（tar, gzip, bzip2, etc）做提取和解压操作
# 注意的是，COPY 指令需要复制的目录一定要放在 Dockerfile 文件的同级目录下。
COPY package*.json ./

# 执行命令
RUN npm install

COPY . .

# 暴露端口
EXPOSE 8080

# 执行命令 node server.js
CMD [ "node", "server.js" ]
```

### .dockerignore 文件

在 `Dockerfile` 的同一个文件夹中创建一个 `.dockerignore` 文件，带有以下内容
```
node_modules
npm-debug.log
```
这将避免你的本地模块以及调试日志被拷贝进入到你的 `Docker` 镜像中，以至于把你镜像原有安装的模块给覆盖了


### 构建你的镜像

构建需要一点时间
```
docker build -t wclimb/node-web-app .
```
然后查看刚刚构建的镜像

```
docker images

REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
wclimb/node-web-app   latest              04fe1cd8e0b2        49 seconds ago      907MB
```

### 运行镜像

```
docker run -p 49160:8080 -d wclimb/node-web-app
```
查看刚刚运行的容器
```
docker ps 
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS              PORTS                               NAMES
ffe453510350        wclimb/node-web-app   "docker-entrypoint.s…"   4 seconds ago       Up 3 seconds        8081/tcp, 0.0.0.0:49160->8080/tcp   unruffled_kare
```

查看容器内的`log`信息
```
docker logs CONTAINER ID
打印出
Running on http://0.0.0.0:8080
```
访问 http://0.0.0.0:8080 出现`hello world`

### 将镜像推送到远程仓库

```
docker push wclimb/node-web-app:v1
```
格式为 `docker push [OPTIONS] NAME[:TAG]`，这里`TAG`为`v1`


## 总结

至此简单入门的`docker`教程就全部结束了，我们首先安装docker -> 创建容器 -> 搜索拉取镜像 -> 构建自己的镜像(`Dockerfile`) -> 发布镜像，文章大部分其实参阅了各个平台的教程或者文档。简单的`docker`就这样跑起来了，但是真正我们去使用的时候往往会有很多问题，用法也不是直接这么暴力的去使用，例如直接拉取 `centos` 镜像往里面安装 `nginx`，会很浪费资源，也没有做到真正的隔离环境。下一篇讲使用`docker-compose`讲多个容器组合起来，尽可能实战操作

## reference

[把一个 Node.js web 应用程序给 Docker 化](https://nodejs.org/zh-cn/docs/guides/nodejs-docker-webapp/)
[30 分钟快速入门 Docker 教程](https://juejin.im/post/5cacbfd7e51d456e8833390)
[Docker — 从入门到实践](https://yeasy.gitbooks.io/docker_practice/)


本文地址： http://www.wclimb.site/2019/12/03/Docker快速入门/