---
title: Gitlab-CI初探
date: 2019-10-16 15:58:55
tags:
- 原创
- gitlab
categories: [工具, 自动化]
---

因为项目一直都是使用`gitlab`进行自动化部署，但是都是前人种树，后人乘凉的现状。难得抽空花了一点时间来玩一下`gitlab`的`CI`


## 准备工作

- 一台服务器
- 注册`gitlab`账号，并且新建一个项目

## 新建.gitlab-ci.yml

[官方README](https://gitlab.com/help/ci/quick_start/README)

项目下新建文件 `.gitlab-ci.yml`，你也可以使用`Web IDE` 在线新建文件

## 安装Gitlab Runner到服务器

登录你的服务器

```
# For Debian/Ubuntu
$ curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
$ sudo apt-get install gitlab-ci-multi-runner
# For CentOS
$ curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.rpm.sh | sudo bash
$ sudo yum install gitlab-ci-multi-runner
```

1. 接下来注册一个`Runner`
```
sudo gitlab-runner register
```

2. 然后会出现以下提示，我们直接输入 https://gitlab.com
```
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
https://gitlab.com
```

3. 输入`gitlab`新建项目`CI`的`token`，token在项目内的 `Setting` -> `CI/CD` -> `Runners`（点击`expand`展开）
```
Please enter the gitlab-ci token for this runner
这里填token
```
![](/img/ci-token.jpg)

4. 输入runner的描述

```
Please enter the gitlab-ci description for this runner
这里随便填
```

5. 命名`tag`
```
Please enter the gitlab-ci tags for this runner (comma separated):
my-tag // 每一个runner的唯一id，也可以在gitlab后台修改。
```

6. 是否接收未指定 `tags` 的任务
```
Whether to run untagged builds [true/false]
[false]: false
```

7. 选择是否为当前项目锁定该 `Runner`
```
Whether to lock Runner to current project [true/false]:
[false]: false
```

8. 选择 `Runner executor`
```
Please enter the executor: virtualbox, docker+machine, docker-ssh, shell, ssh, docker-ssh+machine, kubernetes, docker, parallels:
shell  // 这里选shell，很多人使用的是docker

// 最后会告诉你注册成功
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

现在刷新一下之前复制token的地方看看，是不是刚刚新建的runner生效了

## Pipeline

一次 `Pipeline` 相当于一次构建任务，里面可以包含多个流程，如安装依赖、运行测试、编译、部署测试服务器、部署生产服务器等流程。我们的任何提交或者 `Merge Request` 的合并都可以触发 `Pipeline`。如下图：
```
+------------------+           +----------------+
|                  |  trigger  |                |
|   Commit / MR    +---------->+    Pipeline    |
|                  |           |                |
+------------------+           +----------------+
```

## stages

`stages`表示构建阶段

- 所有 `stages` 会按照顺序运行，即当一个 `stage` 完成后，下一个 `stage` 才会开始
- 只有当所有 `stages` 完成后，该构建任务 (Pipeline) 才会成功
- 如果任何一个 `stage` 失败，那么后面的 `stages` 不会执行，该构建任务 (Pipeline) 失败

一个`Pipeline`会有多个`Stage`，一步步执行
```
+--------------------------------------------------------+
|                                                        |
|  Pipeline                                              |
|                                                        |
|  +-----------+     +------------+      +------------+  |
|  |  Stage 1  |---->|   Stage 2  |----->|   Stage 3  |  |
|  +-----------+     +------------+      +------------+  |
|                                                        |
+--------------------------------------------------------+
```

## 配置.gitlab-ci.yml

之前我们新建了`.gitlab-ci.yml`，那么我们来填写一些内容，让`CI`变得可用
```yml
stages: 
    - build
    - test
    
job2:
  stage: test 
  script:
    - touch test.json
  only:
    - master  
  tags:
    - my-tag  
    
job1:
  stage: build  
  script:
    - npm init -y
  only:
    - master  
  tags:
    - my-tag 
```

`stages` 就是我们上面讲的构建阶段，这里有两个阶段，先`build`然后`test`，会先执行任务 `job1` 然后 执行 `job2`，这里`job1/2`名称可用随便取，不影响
`stage` 表示构建的子任务
`script` 执行的`shell`命令
`only` 只有在master做操作的时候会触发这个构建
`tags` 这就是我们之前在服务器命名的`tag`，必填


我们把这个文件push到master，然后在 CI/CD -> Pipelines 查看我们正在执行的任务

![](/img/ci-pipe.jpg)

如果status显示passed了，则代表运行成功

至此，大功告成

## 更改执行用户

你可能在上面一步会发现 `npm not found`的情况，但是服务器已经安装了`node`

因为`gitlab-ci`的`runner`默认使用`gitlab-runner`用户执行操作

通过指令`ps aux|grep gitlab-runner`可以看到：

```
/usr/bin/gitlab-ci-multi-runner run --working-directory /home/gitlab-runner --config /etc/gitlab-runner/config.toml --service gitlab-runner --syslog --user gitlab-runner
```
- `--working-directory`：设置工作目录, 默认是/home/{执行user}

- `--config`：设置配置文件目录，默认是/etc/gitlab-runner/config.toml

- `--user`：设置执行用户名，默认是gitlab-runner


因此想要更改`user`为`root`只需要重新设置`--user`属性即可，步骤如下：

1. 删除`gitlab-runner`

```
sudo gitlab-runner uninstall
```

2. 切换为`root`
```
gitlab-runner install --working-directory /home/gitlab-runner --user root
```

3. 重启`gitlab-runner`
```
sudo service gitlab-runner restart
```

重新提交一下`.gitlab-cli.yaml`，应该就能够跑通了



原文地址： http://www.wclimb.site/2019/10/16/Gitlab-CI初探/