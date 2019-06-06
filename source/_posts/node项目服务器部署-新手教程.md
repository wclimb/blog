---
title: node项目服务器部署(新手教程)
date: 2018-07-28 15:16:46
tags:
- Node
- javascript
- 原创

categories: [javascript,node,教程]
---
# 写在前面

之前在github写了几个项目，然后一直有很多人问我node项目怎么部署到服务器上，于是乎应大家要求就写了这篇文章，此篇教程只提供给新手借鉴，如果你是大佬的话可以不用往下看了，教程多少有些缺陷，都是按照自己的印象写出来的，所以有问题还望指正。

## linux服务器安装node

首先
下载node包
```
wget https://npm.taobao.org/mirrors/node/latest-v8.x/node-v8.1.0-linux-x64.tar.gz
```
解压
```
tar xvf node-v8.1.0-linux-x64.tar.gz
```
<!-- more -->

```
ln -s ~/node-v8.1.0-linux-x64/bin/node /usr/local/bin/node
ln -s ~/node-v8.1.0-linux-x64/bin/npm /usr/local/bin/npm
```

最后`node -v`查看node版本，如果出现以下就表示安装成功了
```
v8.1.0
```
如果你需要升级`node`版本，执行以下命令即可
```
sudo npm i -g n
n stable
```

## 安装pm2

`pm2`是一个进程守护工具,类似的还有`forever`

```
sudo npm i pm2 -g
```
然后执行，如果不映射的话，会出现`pm2`不是内部指令的错误
```
ln -s ~/node-v8.1.0-linux-x64/bin/pm2 /usr/local/bin/pm2
```
我们顺便把`git`和`cnpm`也安装了
```
yum install git
sudo npm i -g cnpm
ln -s ~/node-v8.1.0-linux-x64/bin/cnpm /usr/bin/cnpm
```

## 安装mysql

卸载已有的`mysql`
```
rpm -qa|grep -i mysql
yum remove 'mysql'
```
下载`mysql`的`repo`源 
```
wget http://repo.mysql.com//mysql57-community-release-el7-7.noarch.rpm
rpm -ivh mysql57-community-release-el7-7.noarch.rpm
```
安装
```
yum install mysql-server
yum install mysql-devel
yum install mysql
```
然后查看刚刚安装的`mysql`
```
rpm -qa|grep -i mysql
```
登录
```
service mysqld status     查看mysql当前的状态
service mysqld stop       停止mysql
service mysqld restart    重启mysql
service mysqld start      启动mysql
```

在完成上述步骤之后登陆时可能遇到`ERROR 2002 (HY000): Can‘t connect to local MySQL server through socket ‘/var/lib/mysql/mysql.sock‘ (2)`错误。

> 这个错误的原因是`/var/lib/mysql`的访问权限问题。下面的命令把`/var/lib/mysql`的拥有者改为当前用户。

```
chown -R openscanner:openscanner /var/lib/mysql
chown -R root:root /var/lib/mysql
```

于是乎接下来就是查看一下`/var/lib/mysql/mysql.sock`文件是否存在，第一次查看时该文件不存在，后来在`/etc/my.cnf`文件中添加了`user=mysql`
然后尝试登录
```
mysql -u root 
```
会出现`ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)` 登录root帐号需要密码，现在我们没有设置密码，哪来的密码。
于是乎我们开始忘记密码的操作
第一步，在/etc/my.cnf文件中添加skip-grant-tables
第二步，重启mysql，service mysqld restart
第三步，登录mysql，`mysql -u root`
第四步，修改密码：
```
mysql>use mysql;
mysql>update mysql.user set authentication_string=password('你的密码') where user='root';
mysql>flush privileges;
mysql>exit;
```
第五步，恢复/etc/my.cnf，将skip-grant-tables删除或者注释掉
第六步，重启mysql，service mysqld restart

分配用户
> host指定该用户在哪个主机上可以登陆，此处的"localhost"，是指该用户只能在本地登录，不能在另外一台机器上远程登录，如果想远程登录的话，将"localhost"改为"%"，表示在任何一台电脑上都可以登录;也可以指定某台机器可以远程登录;

```
CREATE USER 'username'@'host' IDENTIFIED BY 'password';
CREATE USER 'test'@'%' IDENTIFIED BY '密码'; 
```

给创建的用户权限
> privileges：用户的操作权限,如SELECT，INSERT，UPDATE等.如果要授予所的权限则使用ALL;
databasename：数据库名。
tablename：表名,如果要授予该用户对所有数据库和表的相应操作权限则可用*表示, 如*.*.

```
GRANT privileges ON databasename.tablename TO 'username'@'host'
```

> 下面表示给test用户所有数据库和表的权限

mysql>GRANT ALL ON *.* TO 'test'@'%'; 

## 安装nginx
安装
```
yum -y install nginx
```
启动
```
service nginx start
```
查找nginx安装在哪，我这里是`/etc/nginx/conf.d`
```
whereis nginx
```
进入文件夹
```
cd /etc/nginx/conf.d
```
然后新建文件，这里以我的域名为例
```
vi www.wclimb.site.conf
```
然后里面的文件内容我们先不写，我们先把node项目部署一下

## 使用pm2启动node项目

这里以我的项目为例[koa2-blog](https://github.com/wclimb/Koa2-blog)
我们先找到合适的文件夹存放我们得项目，然后`git clone`一下（git我们之前安装过了）

> 该项目的数据库名叫nodeSql，使用运行之前得先建立好数据库，然后再运行项目，登录数据库执行 create database nodesql;

```
git clone https://github.com/wclimb/Koa2-blog.git
cd Koa2-blog
cnpm i 
pm2 start index.js
```
上面pm2我们也安装过，该项目监听的是3000端口，项目已经运行起来了
可以使用`pm2 list`查看进程列表，使用`pm2 log`打印日志
## nginx配置

记得刚刚我们没有编写`www.wclimb.site.conf`文件
现在开始写入以下内容，`blog.wclimb.site`是我的域名，你可以在你的服务器平台去解析一下，目前我们监听的是`3000`端口，所以代理到`3000`
```
server {
    listen 80;
    server_name blog.wclimb.site;
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```
检验nginx是否正确配置
```
nginx -t
```
重启nginx
```
service nginx restart
```
如果不成功，可能还需执行一下命令
```
systemctl stop httpd
systemctl disable httpd
```

## 完结

OK，现在访问域名看看是否有效果了，整个流程可能有写纰漏，大致流程也差不多了，希望对你有帮助

GitHub：[wclimb](https://github.com/wclimb)

## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)