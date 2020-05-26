---
title: Node+Koa2+Mysql 搭建简易博客
date: 2017-07-12 14:23:15
tags:
- Node
- Koa
- Mysql
- javascript
- 原创

categories: [Node]
---

## Koa2-blog

> 2018-1-5 更新教程（新增上传头像、新增分页、样式改版、发布文章和评论支持markdown语法）
> 现在GitHub的代码结构有变，优化了蛮多东西

Node+Koa2+Mysql 搭建简易博客

## 预览地址

http://blog.wclimb.site

## 写在前面

本篇教程一方面是为了自己在学习的过程加深记忆，也是总结的过程。另一方面给对这方面不太了解的同学以借鉴经验。如发现问题还望指正，
如果你觉得这篇文章帮助到了你，那就赏脸给个star吧，https://github.com/wclimb/Koa2-blog
下一篇可能是 Node + express + mongoose 或 zepto源码系列
感谢您的阅读^_^
ps：关于markdown代码缩进问题，看起来不太舒服，但复制到编辑器是正常的哟！

## 演示效果

![img](http://www.wclimb.site/cdn/blog1.gif)

## 开发环境

- nodejs `v8.1.0`
- koa `v2.3.0`
- mysql `v5.7.0`

## 准备工作

文中用到了promise、async await等语法，所以你需要一点es6的语法，传送门当然是阮老师的教程了 http://es6.ruanyifeng.com/ 

如果你已经配置好node和mysql可以跳过

> 经常会有人问报错的问题，运行出错大部分是因为不支持async，升级node版本可解决

```
$ node -v   查看你的node版本，如果过低则去nodejs官网下载替换之前的版本
```
下载mysql，并设置好用户名和密码，默认可以为用户名：root，密码：123456

```
进入到 bin 目录下 比如 cd C:\Program Files\MySQL\MySQL Server 5.7\bin

```
然后开启mysql
```
$ mysql -u root -p	

```
输入密码之后创建`database`(数据库)，`nodesql`是我们创建的数据库
```
$ create database nodesql;
```
记住sql语句后面一定要跟`;`符号，接下来看看我们创建好的数据库列表

```
$ show databases;
```
![img](/img/database.png)

启用创建的数据库
```
$ use nodesql;
```
查看数据库中的表
<!-- more -->
```
$ show tables;
```
显示`Empty set (0.00 sec)`，因为我们还没有建表，稍后会用代码建表
注释：
这是后面建表之后的状态
![img](/img/tables.png)

## 目录结构

![img](/img/item.png)

- config 存放默认文件
- lib 存放操作数据库文件
- middlewares 存放判断登录与否文件
- public 存放样式和头像文件
- routes 存放路由文件
- views 存放模板文件
- index 程序主文件
- package.json 包括项目名、作者、依赖等等

首先我们创建koa2-blog文件夹，然后`cd koa2-blog`
```
 接着使用 npm init 来创建package.json
```
接着安装包，安装之前我们使用[cnpm](https://npm.taobao.org/)安装 
```
$ npm install -g cnpm --registry=https://registry.npm.taobao.org
```
```
$ cnpm i koa koa-bodyparser koa-mysql-session koa-router koa-session-minimal koa-static koa-views md5 moment mysql ejs markdown-it chai mocha koa-static-cache --save-dev
```
各模块用处

1. `koa node`框架
2. `koa-bodyparser` 表单解析中间件
3. `koa-mysql-session`、`koa-session-minimal` 处理数据库的中间件
4. `koa-router` 路由中间件
5. `koa-static` 静态资源加载中间件
6. `ejs` 模板引擎
7. `md5` 密码加密
8. `moment` 时间中间件
9. `mysql` 数据库
10. `markdown-it` markdown语法
11. `koa-views` 模板呈现中间件
12. `chai` `mocha` 测试使用
13. `koa-static-cache` 文件缓存

在文件夹里面新建所需文件

![img](/img/view.png)


## 首先配置config

我们新建`default.js`文件 

```
const config = {
  // 启动端口
  port: 3000,

  // 数据库配置
  database: {
    DATABASE: 'nodesql',
    USERNAME: 'root',
    PASSWORD: '123456',
    PORT: '3306',
    HOST: 'localhost'
  }
}

module.exports = config

```
这是我们所需的一些字段，包括端口和数据库连接所需，最后我们把它exports暴露出去，以便可以在别的地方使用

## 配置index.js文件
`index.js`

```js
const Koa=require('koa');
const path=require('path')
const bodyParser = require('koa-bodyparser');
const ejs=require('ejs');
const session = require('koa-session-minimal');
const MysqlStore = require('koa-mysql-session');
const config = require('./config/default.js');
const router=require('koa-router')
const views = require('koa-views')
// const koaStatic = require('koa-static')
const staticCache = require('koa-static-cache')
const app = new Koa()


// session存储配置
const sessionMysqlConfig= {
  user: config.database.USERNAME,
  password: config.database.PASSWORD,
  database: config.database.DATABASE,
  host: config.database.HOST,
}

// 配置session中间件
app.use(session({
  key: 'USER_SID',
  store: new MysqlStore(sessionMysqlConfig)
}))


// 配置静态资源加载中间件
// app.use(koaStatic(
//   path.join(__dirname , './public')
// ))
// 缓存
app.use(staticCache(path.join(__dirname, './public'), { dynamic: true }, {
  maxAge: 365 * 24 * 60 * 60
}))
app.use(staticCache(path.join(__dirname, './images'), { dynamic: true }, {
  maxAge: 365 * 24 * 60 * 60
}))

// 配置服务端模板渲染引擎中间件
app.use(views(path.join(__dirname, './views'), {
  extension: 'ejs'
}))
app.use(bodyParser({
  formLimit: '1mb'
}))

//  路由(我们先注释三个，等后面添加好了再取消注释，因为我们还没有定义路由，稍后会先实现注册)
//app.use(require('./routers/signin.js').routes())
app.use(require('./routers/signup.js').routes())
//app.use(require('./routers/posts.js').routes())
//app.use(require('./routers/signout.js').routes())


app.listen(3000)

console.log(`listening on port ${config.port}`)

```
我们使用`koa-session-minimal``koa-mysql-session`来进行数据库的操作
使用`koa-static`配置静态资源，目录设置为`public`
使用`ejs`模板引擎
使用`koa-bodyparser`来解析提交的表单信息
使用`koa-router`做路由
使用`koa-static-cache`来缓存文件
之前我们配置了default.js，我们就可以在这里使用了
首先引入进来 var config = require('./config/default.js');
然后在数据库的操作的时候，如config.database.USERNAME，得到的就是root。



如果你觉得这篇文章帮助到了你，那就赏脸给个star吧，https://github.com/wclimb/Koa2-blog


## 配置lib的mysql.js文件


关于数据库的使用这里介绍一下，首先我们建立了数据库的连接池，以便后面的操作都可以使用到，我们创建了一个函数`query`，通过返回promise的方式以便可以方便用`.then()`来获取数据库返回的数据，然后我们定义了三个表的字段，通过`createTable`来创建我们后面所需的三个表，包括posts(存储文章)，users(存储用户)，comment(存储评论)，create table if not exists users()表示如果users表不存在则创建该表，避免每次重复建表报错的情况。后面我们定义了一系列的方法，最后把他们exports暴露出去。

> 这里只介绍注册用户insertData，后续的可以自行查看，都差不多


```js
// 注册用户
let insertData = function( value ) {
  let _sql = "insert into users set name=?,pass=?,avator=?,moment=?;"
  return query( _sql, value )
}
```
我们写了一个_sql的sql语句，意思是插入到users的表中（在这之前我们已经建立了users表）然后要插入的数据分别是name、pass、avator、moment，就是用户名、密码、头像、注册时间，最后调用`query`函数把sql语句传进去（之前的写法是`"insert into users(name,pass) values(?,?);"`,换成现在得更容易理解）


lib/mysql.js
```js
var mysql = require('mysql');
var config = require('../config/default.js')

var pool  = mysql.createPool({
  host     : config.database.HOST,
  user     : config.database.USERNAME,
  password : config.database.PASSWORD,
  database : config.database.DATABASE
});

let query = function( sql, values ) {

  return new Promise(( resolve, reject ) => {
    pool.getConnection(function(err, connection) {
      if (err) {
        reject( err )
      } else {
        connection.query(sql, values, ( err, rows) => {

          if ( err ) {
            reject( err )
          } else {
            resolve( rows )
          }
          connection.release()
        })
      }
    })
  })

}


// let query = function( sql, values ) {
// pool.getConnection(function(err, connection) {
//   // 使用连接
//   connection.query( sql,values, function(err, rows) {
//     // 使用连接执行查询
//     console.log(rows)
//     connection.release();
//     //连接不再使用，返回到连接池
//   });
// });
// }

let users =
    `create table if not exists users(
     id INT NOT NULL AUTO_INCREMENT,
     name VARCHAR(100) NOT NULL,
     pass VARCHAR(100) NOT NULL,
     avator VARCHAR(100) NOT NULL,
     moment VARCHAR(100) NOT NULL,
     PRIMARY KEY ( id )
    );`

let posts =
    `create table if not exists posts(
     id INT NOT NULL AUTO_INCREMENT,
     name VARCHAR(100) NOT NULL,
     title TEXT(0) NOT NULL,
     content TEXT(0) NOT NULL,
     md TEXT(0) NOT NULL,
     uid VARCHAR(40) NOT NULL,
     moment VARCHAR(100) NOT NULL,
     comments VARCHAR(200) NOT NULL DEFAULT '0',
     pv VARCHAR(40) NOT NULL DEFAULT '0',
     avator VARCHAR(100) NOT NULL,
     PRIMARY KEY ( id )
    );`

let comment =
    `create table if not exists comment(
     id INT NOT NULL AUTO_INCREMENT,
     name VARCHAR(100) NOT NULL,
     content TEXT(0) NOT NULL,
     moment VARCHAR(40) NOT NULL,
     postid VARCHAR(40) NOT NULL,
     avator VARCHAR(100) NOT NULL,
     PRIMARY KEY ( id )
    );`

let createTable = function( sql ) {
  return query( sql, [] )
}

// 建表
createTable(users)
createTable(posts)
createTable(comment)

// 注册用户
let insertData = function( value ) {
  let _sql = "insert into users set name=?,pass=?,avator=?,moment=?;"
  return query( _sql, value )
}
// 删除用户
let deleteUserData = function( name ) {
  let _sql = `delete from users where name="${name}";`
  return query( _sql )
}
// 查找用户
let findUserData = function( name ) {
  let _sql = `select * from users where name="${name}";`
  return query( _sql )
}
// 发表文章
let insertPost = function( value ) {
  let _sql = "insert into posts set name=?,title=?,content=?,md=?,uid=?,moment=?,avator=?;"
  return query( _sql, value )
}
// 更新文章评论数
let updatePostComment = function( value ) {
  let _sql = "update posts set comments=? where id=?"
  return query( _sql, value )
}

// 更新浏览数
let updatePostPv = function( value ) {
  let _sql = "update posts set pv=? where id=?"
  return query( _sql, value )
}

// 发表评论
let insertComment = function( value ) {
  let _sql = "insert into comment set name=?,content=?,moment=?,postid=?,avator=?;"
  return query( _sql, value )
}
// 通过名字查找用户
let findDataByName = function ( name ) {
  let _sql = `select * from users where name="${name}";`
  return query( _sql)
}
// 通过文章的名字查找用户
let findDataByUser = function ( name ) {
  let _sql = `select * from posts where name="${name}";`
  return query( _sql)
}
// 通过文章id查找
let findDataById = function ( id ) {
  let _sql = `select * from posts where id="${id}";`
  return query( _sql)
}
// 通过评论id查找
let findCommentById = function ( id ) {
  let _sql = `select * FROM comment where postid="${id}";`
  return query( _sql)
}

// 查询所有文章
let findAllPost = function () {
  let _sql = ` select * FROM posts;`
  return query( _sql)
}
// 查询分页文章
let findPostByPage = function (page) {
  let _sql = ` select * FROM posts limit ${(page-1)*10},10;`
  return query( _sql)
}
// 查询个人分页文章
let findPostByUserPage = function (name,page) {
  let _sql = ` select * FROM posts where name="${name}" order by id desc limit ${(page-1)*10},10 ;`
  return query( _sql)
}
// 更新修改文章
let updatePost = function(values){
  let _sql = `update posts set  title=?,content=?,md=? where id=?`
  return query(_sql,values)
}
// 删除文章
let deletePost = function(id){
  let _sql = `delete from posts where id = ${id}`
  return query(_sql)
}
// 删除评论
let deleteComment = function(id){
  let _sql = `delete from comment where id=${id}`
  return query(_sql)
}
// 删除所有评论
let deleteAllPostComment = function(id){
  let _sql = `delete from comment where postid=${id}`
  return query(_sql)
}
// 查找评论数
let findCommentLength = function(id){
  let _sql = `select content from comment where postid in (select id from posts where id=${id})`
  return query(_sql)
}

// 滚动无限加载数据
let findPageById = function(page){
  let _sql = `select * from posts limit ${(page-1)*5},5;`
  return query(_sql)
}
// 评论分页
let findCommentByPage = function(page,postId){
  let _sql = `select * from comment where postid=${postId} order by id desc limit ${(page-1)*10},10;`
  return query(_sql)
}

module.exports = {
	query,
	createTable,
	insertData,
  	deleteUserData,
  	findUserData,
	findDataByName,
  	insertPost,
  	findAllPost,
  	findPostByPage,
	findPostByUserPage,
	findDataByUser,
	findDataById,
	insertComment,
	findCommentById,
	updatePost,
	deletePost,
	deleteComment,
	findCommentLength,
	updatePostComment,
	deleteAllPostComment,
	updatePostPv,
	findPageById,
	findCommentByPage
}


```
下面是我们建的表

| users   | posts    |  comment  |
| :----: | :----:   | :----: |
|   id    |   id    |   id    |
|   name    |   name    |   name    |
|   pass    |   title    |   content    |
|   avator     | content      |   moment    |
|    moment     | md      |    postid   |
|     -    | uid      |   avator    |
|     -    | moment      |    -   |
|     -   | comments      |    -   |      
|     -   | pv             |   -   |      
|     -   |  avator       |    -   |    


* id主键递增
* name: 用户名
* pass：密码
* avator：头像
* title：文章标题
* content：文章内容和评论
* md：markdown语法
* uid：发表文章的用户id 
* moment：创建时间
* comments：文章评论数
* pv：文章浏览数
* postid：文章id


现在感觉有点枯燥，那我们先来实现一下注册吧

## 实现注册页面

routers/singup.js 
```js
const router = require('koa-router')();
const userModel = require('../lib/mysql.js');
const md5 = require('md5')
const checkNotLogin = require('../middlewares/check.js').checkNotLogin
const checkLogin = require('../middlewares/check.js').checkLogin
const moment = require('moment');
const fs = require('fs')
// 注册页面
router.get('/signup', async(ctx, next) => {
    await checkNotLogin(ctx)
    await ctx.render('signup', {
        session: ctx.session,
    })
})
    
module.exports = router
```
使用get方式得到'/signup'页面，然后渲染signup模板，这里我们还没有在写signup.ejs

views/signup.ejs

```html
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>注册</title>
</head>
<body>
	<div class="container">
		<form class="form create" method="post">
			<div>
				<label>用户名：</label> 
				<input placeholder="请输入用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input placeholder="请输入密码" class="password" type="password" name="password">
			</div>
			<div>
				<label>重复密码：</label> 
				<input placeholder="请确认密码" class="repeatpass" type="password" name="repeatpass">
			</div>
			<div>
				<label>上传头像：</label>
				<input type="file" name="avator" id="avator">
				<input type="hidden" id="avatorVal">
				<img class="preview" alt="预览头像">
			</div>
			<div class="submit">注册</div>
		</form>
	</div>
</body>
</html>
```
我们先安装supervisor

```
$ cnpm i supervisor -g
```
supervisor的作用是会监听文件的变化，而我们修改文件之后不必去重启程序
```
supervisor --harmony index
```
现在访问 localhost:3000/signup 看看效果吧。注意数据库一定要是开启的状态，不能关闭

## 完善注册功能

首先我们来完善一下样式吧，稍微美化一下

public/index.css

```css
body,
header,
ul,
li,
p,
div,
html,
span,
h3,
a,
blockquote {
    margin: 0;
    padding: 0;
    color: #333;
}

body {
    margin-bottom: 20px;
}
ul,li{
    list-style-type: none;
}
a {
    text-decoration: none;
}

header {
    width: 60%;
    margin: 20px auto;
}
header:after{
    content: '';
    clear: both;
    display: table;
}
header .user_right{
    float: right
}
header .user_right .active{
    color: #5FB878;
    background: #fff;
    border: 1px solid #5FB878;
    box-shadow: 0 5px 5px #ccc;
}
header .user_name {
    float: left
}
.user_name {
    font-size: 20px;
}

.has_user a,
.has_user span,
.none_user a {
    padding: 5px 15px;
    background: #5FB878;
    border-radius: 15px;
    color: #fff;
    cursor: pointer;
    border: 1px solid #fff;
    transition: all 0.3s;
}

.has_user a:hover,.has_user span:hover{
    color: #5FB878;
    background: #fff;
    border: 1px solid #5FB878;
    box-shadow: 0 5px 5px #ccc;
}

.posts{
    border-radius: 4px; 
    border: 1px solid #ddd;
}
.posts > li{
    padding: 10px;
    position: relative;
    padding-bottom: 40px;
}
.posts .comment_pv{
    position: absolute;
    bottom: 5px;
    right: 10px;
}
.posts .author{
    position: absolute;
    left: 10px;
    bottom: 5px;
}
.posts .author span{
    margin-right: 5px;
}
.posts > li:hover {
    background: #f2f2f2;
}
.posts > li:hover pre{
    border: 1px solid #666;
}
.posts > li:hover .content{
    border-top: 1px solid #fff;
    border-bottom: 1px solid #fff;
}
.posts > li + li{
    border-top: 1px solid #ddd;
}
.posts li .title span{
    position: absolute;
    left: 10px;
    top: 10px;
    color: #5FB878;
    font-size: 14px;
}
.posts li .title{
     margin-left: 40px;
     font-size: 20px;
     color: #222;
}
.posts .userAvator{
    position: absolute;
    left: 3px;
    top: 3px;
    width: 40px;
    height: 40px;
    border-radius: 5px;
}
.posts .content{
    border-top: 1px solid #f2f2f2;
    border-bottom: 1px solid #f2f2f2;
    margin: 10px 0 0 0 ;
    padding: 10px 0;
    margin-left: 40px;
}
.userMsg img{
    width: 40px;
    height: 40px;
    border-radius: 5px;
    margin-right: 10px;
    vertical-align: middle;
    display: inline-block;
}
.userMsg span{
    font-size: 18px;
    color:#333;
    position: relative;
    top: 2px;
}
.posts li img{
    max-width: 100%;
}
.spost .comment_pv{
    position: absolute;
    top: 10px;
}
.spost .edit {
    position: absolute;
    right: 20px;
    bottom: 5px;
}

.spost .edit p {
    display: inline-block;
    margin-left: 10px;
}

.comment_wrap {
    width: 60%;
    margin: 20px auto;
}

.submit {
    display: block;
    width: 100px;
    height: 40px;
    line-height: 40px;
    text-align: center;
    border-radius: 4px;
    background: #5FB878;
    cursor: pointer;
    color: #fff;
    float: left;
    margin-top: 20px ;
    border:1px solid #fff;
}
.submit:hover{
    background: #fff;
    color: #5FB878;
    border:1px solid #5FB878;
}
.comment_list{
    border: 1px solid #ddd;
    border-radius: 4px;
}
.cmt_lists:hover{
    background: #f2f2f2;
}
.cmt_lists + .cmt_lists{
    border-top: 1px solid #ddd;
}
.cmt_content {
    padding: 10px;
    position: relative;
    border-radius: 4px;
    word-break: break-all;
}
.cmt_detail{
    margin-left: 48px;
}
.cmt_content img{
    max-width: 100%;
}
/* .cmt_content:after {
    content: '#content';
    position: absolute;
    top: 5px;
    right: 5px;
    color: #aaa;
    font-size: 13px;
}
 */
.cmt_name {
    position: absolute;
    right: 8px;
    bottom: 5px;
    color: #333;
}

.cmt_name a {
    margin-left: 5px;
    color: #1E9FFF;
}
.cmt_time{
    position: absolute;
    font-size: 12px;
    right: 5px;
    top: 5px;
    color: #aaa
}
.form {
    margin: 0 auto;
    width: 50%;
    margin-top: 20px;
}

textarea {
    width: 100%;
    height: 150px;
    padding:10px 0 0 10px;
    font-size: 20px;
    border-radius: 4px;   
	border: 1px solid #d7dde4;
    -webkit-appearance: none;
    resize: none;
}

textarea#spContent{
    width: 98%;
}

.tips {
    margin: 20px 0;
    color: #ec5051;
    text-align: center;
}

.container {
    width: 60%;
    margin: 0 auto;
}
.form img.preview {
    width:100px;
    height:100px;
    border-radius: 50%;
    display: none;
    margin-top:10px;
}
input {
    display: block;
    width: 100%;
    height: 35px;
    font-size: 18px;
    padding: 6px 7px;	
	border-radius: 4px;   
	border: 1px solid #d7dde4;
	-webkit-appearance: none;
}

input:focus,textarea:focus{
    outline: 0;
    box-shadow: 0 0 0 2px rgba(51,153,255,.2);
    border-color: #5cadff;
}

input:hover,input:active,textarea:hover,textarea:active{
    border-color: #5cadff;
}

.create label {
    display: block;
    margin: 10px 0;
}

.comment_wrap form {
    width: 100%;
    margin-bottom: 85px;
}

.delete_comment,
.delete_post {
    cursor: pointer;
}

.delete_comment:hover,
.delete_post:hover,
a:hover {
    color: #ec5051;
}
.disabled{
    user-select: none;
    cursor: not-allowed !important;
}
.error{
    color: #ec5051;
}
.success{
    color: #1E9FFF;
}
.container{
    width: 60%;
    margin:0 auto;
}
.message{
    position: fixed;
    top: -100%;
    left: 50%;
    transform: translateX(-50%);
    padding: 10px 20px;
    background: rgba(0, 0, 0, 0.7);
    color: #fff;
    border-bottom-left-radius: 15px;
    border-bottom-right-radius: 15px;
    z-index: 99999;
}
.markdown pre{
    display: block;
    overflow-x: auto;
    padding: 0.5em;
    background: #F0F0F0;
    border-radius: 3px;
    border: 1px solid #fff;
}
.markdown blockquote{
    padding: 0 1em;
    color: #6a737d;
    border-left: 0.25em solid #dfe2e5;
    margin: 10px 0;
}
.markdown ul li{
    list-style: circle;
    margin-top: 5px;
}
```

我们再把模板引擎的header和footer独立出来

/views/header.ejs
顺便引入index.css和jq
```html
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>koa2-blog</title>
	<link rel="icon" href="http://www.wclimb.site/images/avatar.png">
	<link rel="stylesheet" href="/index.css">
	<script src="http://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
	<script>
		function fade(txt){
			$('.message').text(txt)
			$('.message').animate({
				top:0
			})
			setTimeout(function(){
				$('.message').animate({
					top: '-100%'
				})
			},1500)
		}
		$(function(){
			$('.signout').click(()=>{
				$.ajax({
					url: "/signout",
					type: "GET",
					cache: false,
					dataType: 'json',
					success: function (msg) {
						if (msg) {
							fade('登出成功')
							setTimeout(()=>{
								window.location.href = "/posts"
							},1500)	
						}
					},
					error: function () {
						alert('异常');
					}
				})
			})
		})
	</script>
</head>
<body>
	<header>
		<div class="user_name">
			<% if(session.user){ %>
				 Hello,<%= session.user %>
			<% } %>
			<% if(!session.user){ %>
				欢迎注册登录^_^
			<% } %>
		</div>
		<div class="message">登录成功</div>
		<div class="user_right">
			<%  if(session.user){ %>
				<div class="has_user">
					<a target="__blank" href="https://github.com/wclimb/Koa2-blog">GitHub</a>
					<% if(type == 'all'){ %>
						<a class="active" href="/posts">全部文章</a>
					<% }else{ %>
						<a href="/posts">全部文章</a>
					<% }%>
					<% if(type == 'my'){ %>
						<a class="active" href="/posts?author=<%= session.user %>">我的文章</a>
					<% }else{ %>
						<a href="/posts?author=<%= session.user %>">我的文章</a>
					<% }%>
					<% if(type == 'create'){ %>
						<a class="active" href="/create">发表文章</a>
					<% }else{ %>
						<a href="/create">发表文章</a>
					<% }%>
					
					<span class="signout">登出</span>
				</div>
			<% } %>
			<% if(!session.user){ %>
				<div class="none_user has_user">
					<a target="__blank" href="https://github.com/wclimb/Koa2-blog">GitHub</a>
					<% if(type == 'all'){ %>
						<a class="active" href="/posts">全部文章</a>
					<% }else{ %>
						<a href="/posts">全部文章</a>
					<% }%>
					<% if(type == 'signup'){ %>
						<a class="active" href="/signup">注册</a>
					<% }else{ %>
						<a href="/signup">注册</a>
					<% }%>
					<% if(type == 'signin'){ %>
						<a class="active" href="/signin">登录</a>
					<% }else{ %>
						<a href="/signin">登录</a>
					<% }%>
				</div>
			<% } %>
		</div>
	</header>

```
首先我们看到用到了session.user，这个值从哪来呢？请看下面的代码
```js
// 注册页面
router.get('/signup', async(ctx, next) => {
    await checkNotLogin(ctx)
    await ctx.render('signup', {
        session: ctx.session,
    })
})
```
我们可以看到我们向模板传了一个session值，session:ctx.session，这个值存取的就是用户的信息，包括用户名、登录之后的id等，session一般是你关闭浏览器就过期了，等于下次打开浏览器的时候就得重新登录了，用if判断他存不存在，就可以知道用户是否需要登录，如果不存在用户，则只显示`全部文章` `注册` `登录` ,如果session.user存在则有登出的按钮。

在上面我们会看到我用了另外一个if判断，判断type类型，这样做的目的是比如我们登录注册页面，注册页面的导航会高亮，其实就是添加了class：active;
之后我们每个ejs文件的头部会这样写`<%- include("header",{type:'signup'}) %>` 登录页面则是`<%- include("header",{type:'signin'}) %>`


/views/footer.ejs
```html
	
</body>
</html>
```

修改views/signup.ejs 
```html
<%- include("header",{type:'signup'}) %>
	<div class="container">
		<form class="form create" method="post">
			<div>
				<label>用户名：</label> 
				<input placeholder="请输入用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input placeholder="请输入密码" class="password" type="password" name="password">
			</div>
			<div>
				<label>重复密码：</label> 
				<input placeholder="请确认密码" class="repeatpass" type="password" name="repeatpass">
			</div>
			<div>
				<label>上传头像：</label>
				<input type="file" name="avator" id="avator">
				<input type="hidden" id="avatorVal">
				<img class="preview" alt="预览头像">
			</div>
			<div class="submit">注册</div>
		</form>
	</div>
	<script>
		$(window).keyup(function (e) {
			//console.log(e.keyCode)
			if (e.keyCode == 13) {
				$('.submit').click()
			}
		})
		$('#avator').change(function(){
			if (this.files.length != 0) {
				var file = this.files[0],
					reader = new FileReader();
				if (!reader) {
					this.value = '';
					return;
				};
				console.log(file.size)
				if (file.size >= 1024 * 1024 / 2) {
					fade("请上传小于512kb的图片!")
					return 
				}
				reader.onload = function (e) {
					this.value = '';
					$('form .preview').attr('src', e.target.result)
					$('form .preview').fadeIn()
					$('#avatorVal').val(e.target.result)
				};
				reader.readAsDataURL(file);
			};
		})
		$('.submit').click(()=>{
			// console.log($('.form').serialize())
			if ($('input[name=name]').val().trim() == '') {
				fade('请输入用户名！')
			}else if($('input[name=name]').val().match(/[<'">]/g)){
				fade('请输入合法字符！')
			}else if($('#avatorVal').val() == ''){
				fade('请上传头像！')
			}else{
				$.ajax({
					url: "/signup",
					data: {
						name: $('input[name=name]').val(),
						password: $('input[name=password]').val(),
						repeatpass: $('input[name=repeatpass]').val(),
						avator: $('#avatorVal').val(),
					},
					type: "POST",
					cache: false,
					dataType: 'json',
					success: function (msg) {
					   if (msg.data == 1) {           		
						   $('input').val('')
						   fade('用户名存在')
					   }
					   else if (msg.data == 2){
							fade('请输入重复的密码')	               		
					   }
					   else if(msg.data == 3){
							fade('注册成功')
							setTimeout(()=>{
								window.location.href="/signin"	  
							},1000)
					   	}
					},
					error: function () {
						alert('异常');
	
					}
				})			
			}
		})		
	</script>
<% include footer %>
```
先看我们请求的url地址，是'/signup'，为什么是这个呢？我们看下面这段代码(后面有完整的)
```js
router.post('/signup', async(ctx, next) => {
    //console.log(ctx.request.body)
    let user = {
        name: ctx.request.body.name,
        pass: ctx.request.body.password,
        repeatpass: ctx.request.body.repeatpass,
        avator: ctx.request.body.avator
    }
    ....
}
```
我们的请求方式是post，地址是`/signup`所以走了这段代码，之后会获取我们输入的信息，通过ctx.request.body拿到

这里重点就在于ajax提交了，提交之后换回数据 1 2 3，然后分别做正确错误处理，把信息写在error和success中

修改routers/signup.js
```js
const router = require('koa-router')();
const userModel = require('../lib/mysql.js');
const md5 = require('md5')
const checkNotLogin = require('../middlewares/check.js').checkNotLogin
const checkLogin = require('../middlewares/check.js').checkLogin
const moment = require('moment');
const fs = require('fs')
// 注册页面
router.get('/signup', async(ctx, next) => {
    await checkNotLogin(ctx)
    await ctx.render('signup', {
        session: ctx.session,
    })
})
// post 注册
router.post('/signup', async(ctx, next) => {
    //console.log(ctx.request.body)
    let user = {
        name: ctx.request.body.name,
        pass: ctx.request.body.password,
        repeatpass: ctx.request.body.repeatpass,
        avator: ctx.request.body.avator
    }
    await userModel.findDataByName(user.name)
        .then(async (result) => {
            console.log(result)
            if (result.length) {
                try {
                    throw Error('用户已经存在')
                } catch (error) {
                    //处理err
                    console.log(error)
                }
                // 用户存在
                ctx.body = {
                    data: 1
                };;
                
            } else if (user.pass !== user.repeatpass || user.pass === '') {
                ctx.body = {
                    data: 2
                };
            } else {
                // ctx.session.user=ctx.request.body.name   
                let base64Data = user.avator.replace(/^data:image\/\w+;base64,/, "");
                let dataBuffer = new Buffer(base64Data, 'base64');
                let getName = Number(Math.random().toString().substr(3)).toString(36) + Date.now()
                await fs.writeFile('./public/images/' + getName + '.png', dataBuffer, err => { 
                    if (err) throw err;
                    console.log('头像上传成功') 
                });            
                await userModel.insertData([user.name, md5(user.pass), getName, moment().format('YYYY-MM-DD HH:mm:ss')])
                    .then(res=>{
                        console.log('注册成功',res)
                        //注册成功
                        ctx.body = {
                            data: 3
                        };
                    })
            }
        })
})
module.exports = router
```
- 我们使用md5实现密码加密，长度是32位的
- 使用我们之前说的`bodyParse`来解析提交的数据，通过`ctx.request.body`得到
- 我们引入了数据库的操作 findDataByName和insertData，因为之前我们在/lib/mysql.js中已经把他们写好，并暴露出来了。意思是先从数据库里面查找注册的用户名，如果找到了证明该用户名已经被注册过了，如果没有找到则使用insertData增加到数据库中
- ctx.body 是我们通过ajax提交之后给页面返回的数据，比如提交ajax成功之后`msg.data=1`的时候就代表用户存在，`msg.data`出现在后面的`signup.ejs`模板ajax请求中
- 上传头像之前要新建好文件夹，我们ajax发送的是base64的格式，然后使用fs.writeFile来生成图片

我们使用ajax来提交数据，方便来做成功错误的处理

## 模板引擎ejs

我们使用的是ejs，语法可以见[ejs](https://www.npmjs.com/package/ejs)

之前我们写了这么一段代码
```js
router.get('/signup',async (ctx,next)=>{
	await ctx.render('signup',{
		session:ctx.session,
	})
})
```
这里就用到了ejs所需的session 我们通过渲染signup.ejs模板，将值ctx.session赋值给session，之后我们就可以在signup.ejs中使用了
ejs的常用标签为：

- `<% code %>`：运行 JavaScript 代码，不输出
- `<%= code %>`：显示转义后的 HTML内容
- `<%- code %>`：显示原始 HTML 内容

`<%= code %>`和`<%- code %>`的区别在于，<%= code %>不管你写什么都会原样输出，比如code为 `<strong>hello</strong>`的时候 `<%= code %>` 会显示`<strong>hello</strong>`
而`<%- code %>`则显示加粗的hello



## 实现登录页面
![img](/img/signin1.png)

修改 /routers/signin.js
```js
const router = require('koa-router')();
const userModel = require('../lib/mysql.js')
const md5 = require('md5')
const checkNotLogin = require('../middlewares/check.js').checkNotLogin
const checkLogin = require('../middlewares/check.js').checkLogin

router.get('/signin', async(ctx, next) => {
    await checkNotLogin(ctx)
    await ctx.render('signin', {
        session: ctx.session,
    })
})
module.exports=router
```

修改 /views/signin.ejs

```html
<%- include("header",{type:'signin'}) %>
	<div class="container">
		<form class="form create" method="post ">
			<div>
				<label>用户名：</label> 
				<input placeholder="用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input placeholder="密码" type="password" name="password">
			</div>
			<div class="submit">登录</div>
		</form>		
	</div>
<% include footer %>
```

修改 index.js 文件 把下面这段代码注释去掉，之前注释是因为我们没有写signin的路由，以免报错，后面还有文章页和登出页的路由，大家记住一下

```js
app.use(require('./routers/signin.js').routes())

```

现在注册一下来看看效果吧
```
$ supervisor --harmony index
```
![img](/img/signup1.png)

我们怎么查看我们注册好的账号和密码呢？打开mysql控制台

```
$ select * from users;
```
这样刚刚我们注册的用户信息都出现了
![img](/img/users.png)


如果你觉得这篇文章帮助到了你，那就赏脸给个star吧，https://github.com/wclimb/Koa2-blog

## 登录页面

修改signin
routers/signin.js
```js
const router = require('koa-router')();
const userModel = require('../lib/mysql.js')
const md5 = require('md5')
const checkNotLogin = require('../middlewares/check.js').checkNotLogin
const checkLogin = require('../middlewares/check.js').checkLogin

router.get('/signin', async(ctx, next) => {
    await checkNotLogin(ctx)
    await ctx.render('signin', {
        session: ctx.session,
    })
})

router.post('/signin', async(ctx, next) => {
    console.log(ctx.request.body)
    let name = ctx.request.body.name;
    let pass = ctx.request.body.password;

    await userModel.findDataByName(name)
        .then(result => {
            let res = result
            if (name === res[0]['name'] && md5(pass) === res[0]['pass']) {
                ctx.body = true
                ctx.session.user = res[0]['name']
                ctx.session.id = res[0]['id']
                console.log('ctx.session.id', ctx.session.id)
                console.log('session', ctx.session)
                console.log('登录成功')
            }else{
                ctx.body = false
                console.log('用户名或密码错误!')
            }
        }).catch(err => {
            console.log(err)
        })

})

module.exports = router
```
我们进行登录操作，判断登录的用户名和密码是否有误，使用md5加密
我们可以看到登录成功返回的结果是`result` 结果是这样的一个json数组：id：4 name：rrr  pass：...
[ RowDataPacket { id: 4, name: 'rrr', pass: '44f437ced647ec3f40fa0841041871cd' } ]

修改views/signin.ejs
signin.ejs
```html
<%- include("header",{type:'signin'}) %>
	<div class="container">
		<form class="form create" method="post ">
			<div>
				<label>用户名：</label> 
				<input placeholder="用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input placeholder="密码" type="password" name="password">
			</div>
			<div class="submit">登录</div>
		</form>		
	</div>
	<script>
		$(window).keyup(function(e){
			//console.log(e.keyCode)
			if (e.keyCode == 13) {
				$('.submit').click()
			}
		})
		$('.submit').click(()=>{
			if ($('input[name=name]').val().trim() == '' || $('input[name=password]').val().trim() == '' ) {
				fade('请输入用户名或密码')
			}else{
				console.log($('.form').serialize())
				$.ajax({
					url: "/signin",
					data: $('.form').serialize(),
					type: "POST",
					cache: false,
					dataType: 'json',
					success: function (msg) {
					    if (!msg) {
							$('input').val('')
						    fade('用户名或密码错误')
					    } else{
						    fade('登录成功')
						    setTimeout(()=>{
							    window.location.href = "/posts"
						    },1500)	               	
					    }
					},
					error: function () {
						alert('异常');
					}
				})			
			}
		})		
	</script>
<% include footer %>
```
我们增加了ajax请求，在routers/signin.js里，我们设置如果登录失败就返回false，登录成功返回true

```
ctx.body = false
ctx.body = true
```
那我们登录成功后要做跳转，可以看到`window.location.href="/posts"`跳转到posts页面

## 全部文章
![img](/img/posts1.png)
修改routers/posts.js

posts.js
```js
const router = require('koa-router')();
const userModel = require('../lib/mysql.js')
const moment = require('moment')
const checkNotLogin = require('../middlewares/check.js').checkNotLogin
const checkLogin = require('../middlewares/check.js').checkLogin;
const md = require('markdown-it')();  
// 重置到文章页
router.get('/', async(ctx, next) => {
    ctx.redirect('/posts')
})
// 文章页
router.get('/posts', async(ctx, next) => {
    let res,
        postsLength,
        name = decodeURIComponent(ctx.request.querystring.split('=')[1]);
    if (ctx.request.querystring) {
        console.log('ctx.request.querystring', name)
        await userModel.findDataByUser(name)
            .then(result => {
                postsLength = result.length
            })
        await userModel.findPostByUserPage(name,1)
            .then(result => {
                res = result
            })
        await ctx.render('selfPosts', {
            session: ctx.session,
            posts: res,
            postsPageLength:Math.ceil(postsLength / 10),
        })
    } else {
        await userModel.findPostByPage(1)
            .then(result => {
                //console.log(result)
                res = result
            })
        await userModel.findAllPost()
            .then(result=>{
                postsLength = result.length
            })    
        await ctx.render('posts', {
            session: ctx.session,
            posts: res,
            postsLength: postsLength,
            postsPageLength: Math.ceil(postsLength / 10),
            
        })
    }
})
// 首页分页，每次输出10条
router.post('/posts/page', async(ctx, next) => {
    let page = ctx.request.body.page;
    await userModel.findPostByPage(page)
            .then(result=>{
                //console.log(result)
                ctx.body = result   
            }).catch(()=>{
            ctx.body = 'error'
        })  
})
// 个人文章分页，每次输出10条
router.post('/posts/self/page', async(ctx, next) => {
    let data = ctx.request.body
    await userModel.findPostByUserPage(data.name,data.page)
            .then(result=>{
                //console.log(result)
                ctx.body = result   
            }).catch(()=>{
            ctx.body = 'error'
        })  
})
module.exports = router
```

修改 index.js

app.use(require('./routers/posts.js').routes())的注释去掉


修改 views/posts.ejs

```
<%- include("header",{type:'posts'}) %>

    posts

<% include footer %>
```
现在看看登录成功之后的页面吧

接下来我们实现登出页面

## 登出页面

修改 router/signout.js

signout.js
```js
const router = require('koa-router')();

router.get('/signout', async(ctx, next) => {
    ctx.session = null;
    console.log('登出成功')
    ctx.body = true
})

module.exports = router
```
把session设置为null即可

修改 index.js

app.use(require('./routers/posts.js').routes())的注释去掉，现在把注释的路由全部取消注释就对了


然后我们看看 `views/header.ejs`

我们点击登出后的ajax 的提交，成功之后回到posts页面

## 发表文章

修改router/posts
在后面增加
```js
// 发表文章页面
router.get('/create', async(ctx, next) => {
    await ctx.render('create', {
        session: ctx.session,
    })
})

// post 发表文章
router.post('/create', async(ctx, next) => {
    let title = ctx.request.body.title,
        content = ctx.request.body.content,
        id = ctx.session.id,
        name = ctx.session.user,
        time = moment().format('YYYY-MM-DD HH:mm:ss'),
        avator,
        // 现在使用markdown不需要单独转义
        newContent = content.replace(/[<">']/g, (target) => { 
            return {
                '<': '&lt;',
                '"': '&quot;',
                '>': '&gt;',
                "'": '&#39;'
            }[target]
        }),
        newTitle = title.replace(/[<">']/g, (target) => {
            return {
                '<': '&lt;',
                '"': '&quot;',
                '>': '&gt;',
                "'": '&#39;'
            }[target]
        });

    //console.log([name, newTitle, content, id, time])
    await userModel.findUserData(ctx.session.user)
        .then(res => {
            console.log(res[0]['avator'])
            avator = res[0]['avator']       
        })
    await userModel.insertPost([name, newTitle, md.render(content), content, id, time,avator])
            .then(() => {
                ctx.body = true
            }).catch(() => {
                ctx.body = false
            })

})
```

修改 views/create.ejs

create.ejs
![img](/img/create1.png)
```html
<%- include("header",{type:'create'}) %>
<div class="container">
	<form style="width:100%" method="post" class="form create">
		<div>
			<label>标题：</label>
			<input placeholder="请输入标题" type="text" name="title">
		</div>
		<div>
			<label>内容：</label>
			<textarea placeholder="请输入内容" name="content" id="" cols="42" rows="10"></textarea>
		</div>
		<div class="submit">发表</div>
	</form>
</div>
<script>
    $('.submit').click(()=>{
        if ($('input[name=title]').val().trim() == '') {
            fade('请输入标题')
        }else if ($('textarea').val().trim() == '') {
            fade('请输入内容')
        }else{          
            $.ajax({
                url: "/create",
                data: $('.form').serialize(),
                type: "POST",
                cache: false,
                dataType: 'json',
                success: function (msg) {
                    if (msg) {
                        fade('发表成功')
                        setTimeout(()=>{
                            window.location.href="/posts"
                        },1000)
                    }else{
                        fade('发表失败')
                    }
                },
                error: function () {
                    alert('异常');
                }
            })			
        }   
    })
</script>
<% include footer %>
```
现在看看能不能发表吧

即使我们发表了文章，但是当前我们的posts的页面没有显示，因为还没有获取到数据

我们可以看我们之前写的代码 `router.get('/posts', async(ctx, next) => {}`路由
```js
if (ctx.request.querystring) {
	...
}else {
        await userModel.findPostByPage(1)
            .then(result => {
                //console.log(result)
                res = result
            })
        await userModel.findAllPost()
            .then(result=>{
                postsLength = result.length
            })    
        await ctx.render('posts', {
            session: ctx.session,
            posts: res,
            postsLength: postsLength,
            postsPageLength: Math.ceil(postsLength / 10),
            
        })
    }
```
if前面这部分我们先不用管，后面会说。只需要看else后面的代码我们通过`userModel.findPostByPage(1)`来获取第一页的数据，然后查找所有文章的数量，最后除以10拿到首页文章的页数，把数据`postsPageLength`的值传给模板posts.ejs。这样就可以渲染出来了

修改 views/posts.ejs

posts.ejs

```html
<%- include("header",{type:'all'}) %>
	<div class="container">
		<ul class="posts">
			<% posts.forEach(function(res){ %>
				<li>
					<div class="author">
						<span title="<%= res.name %>"><a href="/posts?author=<%= res.name %> ">author: <%= res.name %></a></span>
						<span>评论数：<%= res.comments %></span>
						<span>浏览量：<%= res.pv %></span>
					</div>
					<div class="comment_pv">
						<span><%= res.moment %></span>
					</div>
					<a href="/posts/<%= res.id %>">
						<div class="title">
							<img class="userAvator" src="images/<%= res.avator %>.png">
							<%= res.title %>
						</div>
						<div class="content markdown">
							<%- res.content %>
						</div>
					</a>
				</li>
			<% }) %>
		</ul>
		<div style="margin-top: 30px" class="pagination" id="page"></div>	
	</div>
	<script src="http://www.wclimb.site/pagination/pagination.js"></script>
	<script>
		pagination({
			selector: '#page',
			totalPage: <%= postsPageLength %>,
			currentPage: 1,
			prev: '上一页',
			next: '下一页',
			first: true,
			last: true,
			showTotalPage: true,
			count: 2//当前页前后显示的数量
		},function(val){
			// 当前页
			$.ajax({
				url: "posts/page",
				type: 'POST',
				data:{
					page: val
				},
				cache: false,
				success: function (msg) {
					console.log(msg)
					if (msg != 'error') {
						$('.posts').html(' ')
						$.each(msg,function(i,val){
							//console.log(val.content)
							$('.posts').append(
								'<li>'+
									'<div class=\"author\">'+
										'<span title=\"'+ val.name +'\"><a href=\"/posts?author='+ val.name +' \">author: '+ val.name +'</a></span>'+
										'<span>评论数：'+ val.comments +'</span>'+
										'<span>浏览量：'+ val.pv +'</span>'+
									'</div>'+
									'<div class=\"comment_pv\">'+
										'<span>'+ val.moment +'</span>'+
									'</div>'+
									'<a href=\"/posts/'+ val.id +'\">'+
										'<div class=\"title\">'+
											'<img class="userAvator" src="images/'+ val.avator +'.png">'+
											 val.title +
										'</div>'+
										'<div class=\"content\">'+
											 val.content +
										'</div>'+
									'</a>'+
								'</li>'
							)
						})
					}else{
						alert('分页不存在')
					} 
				}
			})
		})
	</script>
<% include footer %>
```
现在看看posts页面有没有文章出现了

我们看到是所第一页的文章数据，初始化的稍后我们是用服务端渲染的数据，使用了分页，每页显示10条数据，然后通过请求页数。
下面是服务端请求拿到的第一页的数据
```
await userModel.findPostByUserPage(name,1)
        .then(result => {
            res = result
        })
```
要拿到别的页面数据的话要向服务器发送post请求，如下
```
// 首页分页，每次输出10条
router.post('/posts/page', async(ctx, next) => {
    let page = ctx.request.body.page;
    await userModel.findPostByPage(page)
            .then(result=>{
                //console.log(result)
                ctx.body = result   
            }).catch(()=>{
            ctx.body = 'error'
        })  
})
```

## 单篇文章页面
![img](/img/postcontent1.png)
但是我需要点击单篇文章的时候，显示一篇文章怎么办呢？

修改 routers/posts.js

在posts.js后面增加

```js
// 单篇文章页
router.get('/posts/:postId', async(ctx, next) => {
    let comment_res,
        res,
        pageOne,
        res_pv; 
    await userModel.findDataById(ctx.params.postId)
        .then(result => {
            //console.log(result )
            res = result
            res_pv = parseInt(result[0]['pv'])
            res_pv += 1
           // console.log(res_pv)
        })
    await userModel.updatePostPv([res_pv, ctx.params.postId])
    await userModel.findCommentByPage(1,ctx.params.postId)
        .then(result => {
            pageOne = result
            //console.log('comment', comment_res)
        })
    await userModel.findCommentById(ctx.params.postId)
        .then(result => {
            comment_res = result
            //console.log('comment', comment_res)
        })
    await ctx.render('sPost', {
        session: ctx.session,
        posts: res[0],
        commentLenght: comment_res.length,
        commentPageLenght: Math.ceil(comment_res.length/10),
        pageOne:pageOne
    })

})
```

现在的设计是，我们点进去出现的url是 /posts/1 这类的 1代表该篇文章的id，我们在数据库建表的时候就处理了，让id为主键，然后递增

我们通过userModel.findDataById 文章的id来查找数据库
我们通过userModel.findCommentById 文章的id来查找文章的评论，因为单篇文章里面有评论的功能
最后通过sPost.ejs模板渲染单篇文章


修改 views/sPost.ejs

sPost.ejs

```html
<%- include("header",{type:''}) %>
	<div class="container">
		<ul class="posts spost">
			<li>
				<div class="author">
					<span title="<%= posts.name %>"><a href="/posts?author=<%= posts.name %> ">author: <%= posts.name %></a></span>
					<span>评论数：<%= posts.comments %></span>
					<span>浏览量：<%= posts.pv %></span>
				</div>
				<div class="comment_pv">
					<span><%= posts.moment %></span>
				</div>
				<a href="/posts/<%= posts.id %>">
					<div class="title">
						<img class="userAvator" src="../images/<%= posts.avator %>.png">
						<%= posts.title %>
					</div>
					<div class="content markdown">
						<%- posts.content %>
					</div>
				</a>
				<div class="edit">
					<% if(session && session.user ===  posts.name  ){ %>
					<p><a href="<%= posts['id'] %>/edit">编辑</a></p>
					<p><a class="delete_post">删除</a></p>
					<% } %>
				</div>
			</li>
		</ul>
	</div>
	<div class="comment_wrap">
		<% if(session.user){ %>
		<form class="form" method="post" action="/<%= posts.id %>">
			<textarea id="spContent" name="content" cols="82"></textarea>
			<div class="submit">发表留言</div>
		</form>
		<% } else{ %>
			<p class="tips">登录之后才可以评论哟</p>
		<% } %>
		<% if (commentPageLenght > 0) { %>
		<div class="comment_list markdown">
			<% pageOne.forEach(function(res){ %>
				<div class="cmt_lists">
					<div class="cmt_content">
						<div class="userMsg">
							<img src="../images/<%= res['avator'] %>.png" alt=""><span><%= res['name'] %></span>
						</div>
						<div class="cmt_detail">
							<%- res['content'] %>
						</div>
						<span class="cmt_time"><%= res['moment'] %></span>
						<span class="cmt_name">
							<% if(session && session.user ===  res['name']){ %>
								<a class="delete_comment" href="javascript:delete_comment(<%= res['id'] %>);"> 删除</a>
							<% } %>
						</span>
					</div>
				</div>
			<% }) %>
		</div>	
		<% } else{ %>
			<p class="tips">还没有评论，赶快去评论吧！</p>
		<% } %>
		<div style="margin-top: 30px" class="pagination" id="page"></div>	
	</div>
	<script src="http://www.wclimb.site/pagination/pagination.js"></script>
	<script>
		var userName = "<%- session.user %>"
		pagination({
			selector: '#page',
			totalPage: <%= commentPageLenght %>,
			currentPage: 1,
			prev: '上一页',
			next: '下一页',
			first: true,
			last: true,
			showTotalPage:true,
			count: 2//当前页前面显示的数量
		},function(val){
			// 当前页
			var _comment = ''
			$.ajax({
				url: "<%= posts.id %>/commentPage",
				type: 'POST',
				data:{
					page: val
				},
				cache: false,
				success: function (msg) {
					//console.log(msg)
					_comment = ''
					if (msg != 'error') {
						$('.comment_list').html(' ')
						$.each(msg,function(i,val){
							//console.log(val.content)
							_comment += '<div class=\"cmt_lists\"><div class=\"cmt_content\"><div class=\"userMsg\"><img src = \"../images/'+ val.avator +'.png\" ><span>'+ val.name +'</span></div ><div class="cmt_detail">'+ val.content + '</div><span class=\"cmt_time\">'+ val.moment +'</span><span class=\"cmt_name\">';
								if (val.name == userName) {
									_comment += '<a class=\"delete_comment\" href=\"javascript:delete_comment('+ val.id +');\"> 删除</a>'
								}
							_comment += '</span></div></div>'
						})
						$('.comment_list').append(_comment)
					}else{
						alert('分页不存在')
					} 
				}
			})
		
		})
		
		// 删除文章
		$('.delete_post').click(() => {
			$.ajax({
				url: "<%= posts.id %>/remove",
				type: 'POST',
				cache: false,
				success: function (msg) {
					if (msg.data == 1) {
						fade('删除文章成功')
						setTimeout(() => {
							window.location.href = "/posts"
						}, 1000)
					} else if (msg.data == 2) {
						fade('删除文章失败');
						setTimeout(() => {
							window.location.reload()
						}, 1000)
					}
				}
			})
		})
		// 评论
		var isAllow = true
		$('.submit').click(function(){
			if (!isAllow) return
			isAllow = false
			if ($('textarea').val().trim() == '') {
				fade('请输入评论！')
			}else{
				$.ajax({
					url: '/' + location.pathname.split('/')[2],
					data:$('.form').serialize(),
					type: "POST",
					cache: false,
					dataType: 'json',
					success: function (msg) {
						if (msg) {
							fade('发表留言成功')							
							setTimeout(()=>{
								isAllow = true
								window.location.reload()
							},1500)  	
						}
					},
					error: function () {
						alert('异常');
					}
				})
			}
		})
		// 删除评论
		function delete_comment(id) {
			$.ajax({
				url: "<%= posts.id %>/comment/" + id + "/remove",
				type: 'POST',
				cache: false,
				success: function (msg) {
					if (msg.data == 1) {
						fade('删除留言成功')
						setTimeout(() => {
							window.location.reload()
						}, 1000)
					} else if (msg.data == 2) {
						fade('删除留言失败');
						setTimeout(() => {
							window.location.reload()
						}, 1500)
					}
				},
				error: function () {
					alert('异常')
				}
			})
		}
	</script>
<% include footer %>
```
现在点击单篇文章试试，进入单篇文章页面，但是编辑、删除、评论都还没有做，点击无效，我们先不做，先实现每个用户自己发表的文章列表，我们之前在 get '/posts' 里面说先忽略if (ctx.request.querystring) {}里面的代码，这里是做了一个处理，假如用户点击了某个用户，该用户发表了几篇文章，我们需要只显示该用户发表的文章，那么进入的url应该是 /posts?author=xxx ,这个处理在posts.ejs 就已经加上了，就在文章的左下角，作者：xxx就是一个链接。我们通过判断用户来查找文章，继而有了`ctx.request.querystring` 获取到的是：`author=xxx`

注：这里我们处理了，通过判断 `session.user ===  res['name']` 如果不是该用户发的文章，不能编辑和删除，评论也是。这里面也可以注意一下包裹的`<a href=""></a>`标签

## 个人已发表文章列表里面
还记得之前在 get '/post' 里面的代码吗？
下面的代码就是之前说先不处理的代码片段，不过这个不用再次添加，之前已经添加好了，这段代码处理个人发布的文章列表，我们是通过selfPosts.ejs模板来渲染的，样式和全部文章列表一样，但是牵扯到分页的问题，
分页请求的是不同的接口地址

```js
if (ctx.request.querystring) {
        console.log('ctx.request.querystring', name)
        await userModel.findDataByUser(name)
            .then(result => {
                postsLength = result.length
            })
        await userModel.findPostByUserPage(name,1)
            .then(result => {
                res = result
            })
        await ctx.render('selfPosts', {
            session: ctx.session,
            posts: res,
            postsPageLength:Math.ceil(postsLength / 10),
        })
    }
```
修改 selfPost.ejs

```html
<%- include("header",{type:'my'}) %>
	<div class="container">
		<ul class="posts">
			<% posts.forEach(function(res){ %>
				<li>
					<div class="author">
						<span title="<%= res.name %>"><a href="/posts?author=<%= res.name %> ">author: <%= res.name %></a></span>
						<span>评论数：<%= res.comments %></span>
						<span>浏览量：<%= res.pv %></span>
					</div>
					<div class="comment_pv">
						<span><%= res.moment %></span>
					</div>
					<a href="/posts/<%= res.id %>">
						<div class="title">
							<img class="userAvator" src="images/<%= res.avator %>.png">
							<%= res.title %>
						</div>
						<div class="content markdown">
							<%- res.content %>
						</div>
					</a>
				</li>
			<% }) %>
		</ul>
		<div style="margin-top: 30px" class="pagination" id="page"></div>	
	</div>
	<script src="http://www.wclimb.site/pagination/pagination.js"></script>
	<script>
		pagination({
			selector: '#page',
			totalPage: <%= postsPageLength %>,
			currentPage: 1,
			prev: '上一页',
			next: '下一页',
			first: true,
			last: true,
			showTotalPage: true,
			count: 2//当前页前后显示的数量
		},function(val){
			// 当前页
			$.ajax({
				url: "posts/self/page",
				type: 'POST',
				data:{
					page: val,
					name: location.search.slice(1).split('=')[1]
				},
				cache: false,
				success: function (msg) {
					//console.log(msg)
					if (msg != 'error') {
						$('.posts').html(' ')
						$.each(msg,function(i,val){
							//console.log(val.content)
							$('.posts').append(
								'<li>'+
									'<div class=\"author\">'+
										'<span title=\"'+ val.name +'\"><a href=\"/posts?author='+ val.name +' \">author: '+ val.name +'</a></span>'+
										'<span>评论数：'+ val.comments +'</span>'+
										'<span>浏览量：'+ val.pv +'</span>'+
									'</div>'+
									'<div class=\"comment_pv\">'+
										'<span>'+ val.moment +'</span>'+
									'</div>'+
									'<a href=\"/posts/'+ val.id +'\">'+
										'<div class=\"title\">'+
											'<img class="userAvator" src="images/' + val.avator + '.png">' +
											 val.title +
										'</div>'+
										'<div class=\"content\">'+
											 val.content +
										'</div>'+
									'</a>'+
								'</li>'
							)
						})
					}else{
						alert('分页不存在')
					} 
				}
			})
		
		})
	</script>
<% include footer %>
```


## 编辑文章、删除文章、评论、删除评论

> 评论

修改routers/posts.js 

在post.js 后面增加

```js
// 发表评论
router.post('/:postId', async(ctx, next) => {
    let name = ctx.session.user,
        content = ctx.request.body.content,
        postId = ctx.params.postId,
        res_comments,
        time = moment().format('YYYY-MM-DD HH:mm:ss'),
        avator;
    await userModel.findUserData(ctx.session.user)
        .then(res => {
            console.log(res[0]['avator'])
            avator = res[0]['avator']
        })   
    await userModel.insertComment([name, md.render(content),time, postId,avator])
    await userModel.findDataById(postId)
        .then(result => {
            res_comments = parseInt(result[0]['comments'])
            res_comments += 1
        })
    await userModel.updatePostComment([res_comments, postId])
        .then(() => {
            ctx.body = true
        }).catch(() => {
            ctx.body = false
        })
})
// 评论分页
router.post('/posts/:postId/commentPage', async function(ctx){
    let postId = ctx.params.postId,
        page = ctx.request.body.page;
    await userModel.findCommentByPage(page,postId)
        .then(res=>{
            ctx.body = res
        }).catch(()=>{
            ctx.body = 'error'
        })  
})
```
现在试试发表评论的功能吧，之所以这样简单，因为我们之前就在sPost.ejs做了好几个ajax的处理，删除文章和评论也是如此
评论我们也做了分页，所以后面会有一个评论的分页的接口，我们已经在sPost.ejs里面写好了ajax请求

> 删除评论

修改routers/posts.js 

继续在post.js 后面增加

```js
// 删除评论
router.post('/posts/:postId/comment/:commentId/remove', async(ctx, next) => {
    let postId = ctx.params.postId,
        commentId = ctx.params.commentId,
        res_comments;
    await userModel.findDataById(postId)
        .then(result => {
            res_comments = parseInt(result[0]['comments'])
            //console.log('res', res_comments)
            res_comments -= 1
            //console.log(res_comments)
        })
    await userModel.updatePostComment([res_comments, postId])
    await userModel.deleteComment(commentId)
        .then(() => {
            ctx.body = {
                data: 1
            }
        }).catch(() => {
            ctx.body = {
                data: 2
            }

        })
})
```
现在试试删除评论的功能吧

> 删除文章

只有自己发表的文字删除的文字才会显示出来，才能被删除，

修改routers/posts.js 

继续在post.js 后面增加

```js
// 删除单篇文章
router.post('/posts/:postId/remove', async(ctx, next) => {
    let postId = ctx.params.postId
    await userModel.deleteAllPostComment(postId)
    await userModel.deletePost(postId)
        .then(() => {
            ctx.body = {
                data: 1
            }
        }).catch(() => {
            ctx.body = {
                data: 2
            }
        })
})
```
现在试试删除文章的功能吧

> 编辑文章

修改routers/posts.js 

继续在post.js 后面增加

```js
// 编辑单篇文章页面
router.get('/posts/:postId/edit', async(ctx, next) => {
    let name = ctx.session.user,
        postId = ctx.params.postId,
        res;
    await userModel.findDataById(postId)
        .then(result => {
            res = result[0]
            //console.log('修改文章', res)
        })
    await ctx.render('edit', {
        session: ctx.session,
        postsContent: res.md,
        postsTitle: res.title
    })

})

// post 编辑单篇文章
router.post('/posts/:postId/edit', async(ctx, next) => {
    let title = ctx.request.body.title,
        content = ctx.request.body.content,
        id = ctx.session.id,
        postId = ctx.params.postId,
         // 现在使用markdown不需要单独转义
        newTitle = title.replace(/[<">']/g, (target) => {
            return {
                '<': '&lt;',
                '"': '&quot;',
                '>': '&gt;',
                "'": '&#39;'
            }[target]
        }),
        newContent = content.replace(/[<">']/g, (target) => {
            return {
                '<': '&lt;',
                '"': '&quot;',
                '>': '&gt;',
                "'": '&#39;'
            }[target]
        });
    await userModel.updatePost([newTitle, md.render(content), content, postId])
        .then(() => {
            ctx.body = true
        }).catch(() => {
            ctx.body = false
        })
})

```

修改views/edit.js 

```html
<%- include("header",{type:''}) %>
<div class="container">
	<form style="width:100%" class="form create" method="post">
		<div>
			<label>标题：</label>
			<input placeholder="标题" type="text" name="title" value="<%- postsTitle %>">
		</div>
		<div>
			<label>内容：</label>
			<textarea name="content" id="" cols="42" rows="10"><%= postsContent %></textarea>
		</div>
		<div class="submit">修改</div>
	</form>
</div>
<script>
	$('.submit').click(()=>{
		$.ajax({
            url: '',
            data: $('.form').serialize(),
            type: "POST",
            cache: false,
            dataType: 'json',
            success: function (msg) {
               if (msg) {
               		fade('修改成功')
               		setTimeout(()=>{
	               		window.location.href="/posts"
               		},1000)
               }
            },
            error: function () {
                alert('异常');
            }
        })		
	})
</script>
<% include footer %>
```

现在试试编辑文字然后修改提交吧

## 结语 

至此一个简单的blog就已经制作好了，其他扩展功能相信你已经会了吧！如果出现问题，还望积极提问哈，我会尽快处理的

所有的代码都在 https://github.com/wclimb/Koa2-blog 里面，如果觉得不错就star一下吧。有问题可以提问哟
下一篇可能是 Node + express + mongoose 或 zepto源码系列
感谢您的阅读^_^

## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)