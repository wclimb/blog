## Koa2-blog

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

![img](http://www.wclimb.site/cdn/blog.gif)

## 开发环境

- nodejs `v8.1.0`
- koa `v2.3.0`
- mysql `v5.7.0`

## 准备工作

文中用到了promise、async await等语法，所以你需要一点es6的语法，传送门当然是阮老师的教程了 http://es6.ruanyifeng.com/ 

如果你已经配置好node和mysql可以跳过

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
![img](http://www.wclimb.site/cdn/database.png)

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
![img](http://www.wclimb.site/cdn/tables.png)

## 目录结构

![img](http://www.wclimb.site/cdn/item.png)

- config 存放默认文件
- lib 存放操作数据库文件
- middlewares 存放判断登录与否文件
- public 存放样式文件
- routes 存放路由文件
- views 存放模板文件
- index 程序主文件
- package.json 包括项目名、作者、依赖等等

首先我们创建koa2-blog文件夹，然后`cd koa2-blog`
```
 接着使用 `npm init` 来创建package.json
```
接着安装包，安装之前我们使用[cnpm](https://npm.taobao.org/)安装 
```
$ npm install -g cnpm --registry=https://registry.npm.taobao.org
```
```
$ cnpm i koa koa-bodyparser koa-mysql-session koa-router koa-session-minimal koa-static koa-views md5 moment mysql ejs --save
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
10. `koa-views` 模板呈现中间件

在文件夹里面新建所需文件

![img](http://www.wclimb.site/cdn/view.png)


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
var Koa=require('koa');
var path=require('path')
var bodyParser = require('koa-bodyparser');
var ejs=require('ejs');
var session = require('koa-session-minimal');
var MysqlStore = require('koa-mysql-session');
var config = require('./config/default.js');
var router=require('koa-router')
var views = require('koa-views')
var koaStatic = require('koa-static')
var app=new Koa()


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
app.use(koaStatic(
  path.join(__dirname , './public')
))

// 配置服务端模板渲染引擎中间件
app.use(views(path.join(__dirname, './views'), {
  extension: 'ejs'
}))

// 使用表单解析中间件
app.use(bodyParser())

// 使用新建的路由文件
// app.use(require('./routers/signin.js').routes())
app.use(require('./routers/signup.js').routes())
// app.use(require('./routers/posts.js').routes())
// app.use(require('./routers/signout.js').routes())

// 监听在3000端口
app.listen(3000)

console.log(`listening on port ${config.port}`)
```
我们使用`koa-session-minimal``koa-mysql-session`来进行数据库的操作
使用`koa-static`配置静态资源，目录设置为`public`
使用`ejs`模板引擎
使用`koa-bodyparser`来解析提交的表单信息
使用`koa-router`做路由

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
  let _sql = "insert into users(name,pass) values(?,?);"
  return query( _sql, value )
}
```
我们写了一个_sql的sql语句，意思是插入到users的表中（在这之前我们已经建立了users表）然后要插入的数据分别是name和pass，就是用户名和密码，后面values(?,?)意思很简单，你有几个值就写几个问号，最后调用`query`函数把sql语句传进去


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
        resolve( err )
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

users=
`create table if not exists users(
 id INT NOT NULL AUTO_INCREMENT,
 name VARCHAR(100) NOT NULL,
 pass VARCHAR(40) NOT NULL,
 PRIMARY KEY ( id )
);`

posts=
`create table if not exists posts(
 id INT NOT NULL AUTO_INCREMENT,
 name VARCHAR(100) NOT NULL,
 title VARCHAR(40) NOT NULL,
 content  VARCHAR(40) NOT NULL,
 uid  VARCHAR(40) NOT NULL,
 moment  VARCHAR(40) NOT NULL,
 comments  VARCHAR(40) NOT NULL DEFAULT '0',
 pv  VARCHAR(40) NOT NULL DEFAULT '0',
 PRIMARY KEY ( id )
);`

comment=
`create table if not exists comment(
 id INT NOT NULL AUTO_INCREMENT,
 name VARCHAR(100) NOT NULL,
 content VARCHAR(40) NOT NULL,
 postid VARCHAR(40) NOT NULL,
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
  let _sql = "insert into users(name,pass) values(?,?);"
  return query( _sql, value )
}
// 发表文章
let insertPost = function( value ) {
  let _sql = "insert into posts(name,title,content,uid,moment) values(?,?,?,?,?);"
  return query( _sql, value )
}
// 更新文章评论数
let updatePostComment = function( value ) {
  let _sql = "update posts set  comments=? where id=?"
  return query( _sql, value )
}

// 更新浏览数
let updatePostPv = function( value ) {
  let _sql = "update posts set  pv=? where id=?"
  return query( _sql, value )
}

// 发表评论
let insertComment = function( value ) {
  let _sql = "insert into comment(name,content,postid) values(?,?,?);"
  return query( _sql, value )
}
// 通过名字查找用户
let findDataByName = function (  name ) {
  let _sql = `
    SELECT * from users
      where name="${name}"
      `
  return query( _sql)
}
// 通过文章的名字查找用户
let findDataByUser = function (  name ) {
  let _sql = `
    SELECT * from posts
      where name="${name}"
      `
  return query( _sql)
}
// 通过文章id查找
let findDataById = function (  id ) {
  let _sql = `
    SELECT * from posts
      where id="${id}"
      `
  return query( _sql)
}
// 通过评论id查找
let findCommentById = function ( id ) {
  let _sql = `
    SELECT * FROM comment where postid="${id}"
      `
  return query( _sql)
}

// 查询所有文章
let findAllPost = function (  ) {
  let _sql = `
    SELECT * FROM posts
      `
  return query( _sql)
}
// 更新修改文章
let updatePost = function(values){
  let _sql=`update posts set  title=?,content=? where id=?`
  return query(_sql,values)
}
// 删除文章
let deletePost = function(id){
  let _sql=`delete from posts where id = ${id}`
  return query(_sql)
}
// 删除评论
let deleteComment = function(id){
  let _sql=`delete from comment where id = ${id}`
  return query(_sql)
}
// 删除所有评论
let deleteAllPostComment = function(id){
  let _sql=`delete from comment where postid = ${id}`
  return query(_sql)
}
// 查找
let findCommentLength = function(id){
  let _sql=`select content from comment where postid in (select id from posts where id=${id})`
  return query(_sql)
}



module.exports={
  query,
  createTable,
  insertData,
  findDataByName,
  insertPost,
  findAllPost,
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
  updatePostPv
}
```
下面是我们建的表

| users   | posts    |  comment  |
| :----: | :----:   | :----: |
|   id    |   id    |   id    |
|   name    |   name    |   name    |
|   pass    |   title    |   content    |
|         | content      |   postid    |
|         | uid      |       |
|         | moment      |       |
|         | comments      |       |
|        | pv      |       |      |

* id主键递增
* name: 用户名
* pass：密码
* title：文章标题
* content：文章内容和评论
* uid：发表文章的用户id 
* moment：创建时间
* comments：文章评论数
* pv：文章浏览数
* postid：文章id


现在感觉有点枯燥，那我们先来实现一下注册吧

## 实现注册页面

routers/singup.js 

```js
var router=require('koa-router')();

// GET '/signup' 注册页

router.get('/signup',async (ctx,next)=>{
 await ctx.render('signup',{		
 })
})

module.exports=router
```
使用get方式得到'/signup'页面，然后渲染signup模板，这里我们还没有在写signup.ejs

views/signup.ejs

```html
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Document</title>
</head>
<body>
	<div class="container">
		<form class="form create" method="post">
			<div>
				<label>用户名：</label> 
				<input placeholder="用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input class="password" type="password" name="password">
			</div>
			<div>
				<label>重复密码：</label> 
				<input class="repeatpass" type="password" name="repeatpass">
			</div>
			<div class="submit">注册</div>
		</form>
	</div>
</body>
</html>
```
我们先安装supervisor

```
$ cnpm i supervisor
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
body,header,ul,li,p,div,html,span,h3,a{
	margin: 0;
	padding: 0;
	color: #333;
}
body{
	margin-bottom: 20px;
}
a{
	text-decoration: none;
}
header{
	width: 60%;
	margin: 20px auto;
	display: -webkit-flex;
	display: -moz-flex;
	display: -ms-flex;
	display: -o-flex;
	display: flex;
	justify-content: space-between;
}
.user_name{
	font-size: 20px;
}
.has_user{
	
}
.has_user a,.has_user span,.none_user a{
	padding: 5px 15px;
	background: #5FB878;
	border-radius: 15px;
	color: #fff;
	cursor: pointer;
}
.posts{
	list-style: none;
	width: 60%;
	margin: 0 auto;
}
.posts li{
	margin-top: 10px;
	border: 1px solid #ccc;
	border-radius: 5px;
	position: relative;
	padding-bottom: 50px;
}
h3{
	display: inline-block;
	padding: 5px 10px;
	background: #1E9FFF;
	color: #fff;
	border-radius: 10px;
}
.post_title p,.post_content p{
	margin: 10px 0;
	background: #eee;
	padding: 10px 20px;
	border: 1px solid #ddd;
	border-radius: 4px;
}
.post_time{
	position: absolute;
	bottom: 5px;
	right: 10px;
}

.post_3{
	position: absolute;
	bottom: 5px;
	left: 10px;
}
.post_3 p{
	display: inline-block;
	margin-left: 5px;
}
.post_title{
	padding: 10px 20px;
}
.post_content{
	padding: 0 20px;
}
.spost{
	width: 60%;
	margin:0 auto;
	border: 1px solid #ddd;
	position: relative;
	padding-bottom: 40px;
}
.spost_user{
	position: absolute;
	left: 20px;
	bottom: 5px;
}
.edit{
	position: absolute;
	right: 20px;
	bottom: 5px;
}
.edit p{
	display: inline-block;
	margin-left: 10px;	
}
.comment_wrap{
	width: 60%;
	margin:20px auto;	
}
.submit{
	display: block;
	width: 90px;
	height: 35px;
	line-height: 35px;
	text-align: center;
	border-radius: 10px;
	background: #5FB878;
	cursor: pointer;
	color: #fff;
	float: right;
	margin-top: 20px;
}
.cmt_content{
	background: #eee;
	padding: 20px ;
	position: relative;
}
.cmt_name{
	position: absolute;
	right: 20px;
	bottom: 5px;
}
.cmt_name a{
	margin-left: 10px;
}
.cmt_content{
	margin-top: 10px;
}
.form{
	margin:0 auto;
	width: 50%;
	margin-top: 20px;
}
textarea{
	width: 100%;
	height: 200px;
	padding-left: 20px;
	font-size: 20px;
}
.container{
	width: 60%;
	margin: 0 auto;
}
input{
	display: block;
	width: 100%;
	height: 40px;
	padding-left: 20px;
	font-size: 20px;
}
.create label{
	display: block;
	margin: 10px 0;
}
.comment_wrap form{
	width: 100%;
}
.delete_comment,.delete_post{
	cursor: pointer;
}
.delete_comment:hover,.delete_post:hover{
	color: #f60;
}
a:hover{
	color: #f60;
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
	<title>Document</title>
</head>
	<link rel="stylesheet" href="/index.css">
	<script src="http://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<body>

```
/views/footer.ejs

```
	
</body>
</html>
```

修改views/signup.ejs 

```html
<% include header %>
	<div class="container">
		<form class="form create" method="post">
			<div>
				<label>用户名：</label> 
				<input placeholder="用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input class="password" type="password" name="password">
			</div>
			<div>
				<label>重复密码：</label> 
				<input class="repeatpass" type="password" name="repeatpass">
			</div>
			<div class="submit">注册</div>
		</form>
	</div>
<% include footer %>
```

修改routers/signup.js

```js
var router=require('koa-router')();
// 处理数据库（之前已经写好，在mysql.js）
var userModel=require('../lib/mysql.js');
// 加密
var md5=require('md5')

router.get('/signup',async (ctx,next)=>{
	await ctx.render('signup',{
		session:ctx.session,
	})
})


// POST '/signup' 注册页
router.post('/signup',async (ctx,next)=>{
	console.log(ctx.request.body)
	var user={
		name:ctx.request.body.name,
		pass:ctx.request.body.password,
		repeatpass:ctx.request.body.repeatpass
	}
	await userModel.findDataByName(user.name)
			.then(result=>{
				// var res=JSON.parse(JSON.stringify(reslut))
				console.log(result)

				if (result.length){
					try {
						throw Error('用户存在')
					}catch (error){
						//处理err
						console.log(error)	
					}			
					ctx.body={
						data:1
					};;				
				}else if (user.pass!==user.repeatpass || user.pass==''){
					ctx.body={
						data:2
					};				
				}else{
					ctx.body={
						data:3
					};
					console.log('注册成功')
					// ctx.session.user=ctx.request.body.name
			 		userModel.insertData([ctx.request.body.name,md5(ctx.request.body.password)])
				}							
			})

})


module.exports=router
```
- 我们使用md5实现密码加密
- 使用我们之前说的`bodyParse`来解析提交的数据，通过`ctx.request.body`得到
- 我们引入了数据库的操作 findDataByName和insertData，因为之前我们在/lib/mysql.js中已经把他们写好，并暴露出来了。意思是先从数据库里面查找注册的用户名，如果找到了证明该用户名已经被注册过了，如果没有找到则使用insertData增加到数据库中
- ctx.body 是我们通过ajax提交之后给页面返回的数据，比如提交ajax成功之后`msg.data=1`的时候就代表用户存在，`msg.data`出现在后面的`signup.ejs`模板ajax请求中

我们使用ajax来提交数据，方便来做成功错误的处理

## 模板引擎ejs

我们使用的是ejs，语法可以见[ejs官网](https://www.npmjs.com/package/ejs)

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

修改/views/signup.ejs

```html
<% include header %>
	<div class="container">
		<form class="form create" method="post">
			<div>
				<label>用户名：</label> 
				<input placeholder="用户名" type="text" name="name">
			</div>
			<div>
				<label>密码：</label> 
				<input class="password" type="password" name="password">
			</div>
			<div>
				<label>重复密码：</label> 
				<input class="repeatpass" type="password" name="repeatpass">
			</div>
			<div class="submit">注册</div>
		</form>	
	</div>
	<script>
		$('.submit').click(()=>{
			console.log($('.form').serialize())
			$.ajax({
	            url: "/signup",
	            data: $('.form').serialize(),
	            type: "POST",
	            cache: false,
	            dataType: 'json',
	            success: function (msg) {
	               if (msg.data == 1) {
	               		
	               		$('.error').text('用户名存在')
	               		$('input').val('')
	               		fade('.error')
	               }
	               else if (msg.data == 2){
	               		$('.error').text('请输入重复的密码')
	               		fade('.error')
	               		
	               }
	               else if(msg.data == 3){
	               		$('.success').text('注册成功')
	               		fade('.success')
	               		setTimeout(()=>{
	               			window.location.href="/signin"
		  
	               		},1000)
	               }	              
	                //console.log($('.ui.error.message').text);
	            },
	            error: function () {
	                alert('异常');
	            }
	        })		
		})
	</script>
<% include footer %>
```
这里重点就在于ajax提交了，提交之后换回数据 1 2 3，然后分别做正确错误处理，把信息写在error和success中

		
修改/views/header.ejs

>  我们之前在/routers/signup.js get '/signup' 中 向模板传递了session参数  session:ctx.session,存取的就是用户的信息，包括用户名、登录之后的id等，之所以可以通过ctx.session获取到，因为我们在后面登录的时候已经赋值 如ctx.session.user=res[0]['name']

```html
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>koa-blog</title>
</head>
<body>
	<link rel="stylesheet" href="/index.css">
	<script src="http://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
	<header>
		<div class="user_name">
			user：
			<% if(session.user){ %>
				 <%= session.user %>
			<% } %>
			<% if(!session.user){ %>
				未登录
			<% } %>
		</div>
		<div class="message">
			<div class="error"></div>
			<div class="success"></div>
		</div>
		<div class="user_right">
			<%  if(session.user){ %>
				<div class="has_user">
					<a href="/posts">全部文章</a>
					<a href="/create">发表文章</a>
					<span class="signout">登出</span>
				</div>
			<% } %>
			<% if(!session.user){ %>
				<div class="none_user">
					<a href="/posts">全部文章</a>
					<a  href="/signup">注册</a>
					<a href="/signin">登录</a>
				</div>
			<% } %>
		</div>
	</header>
	<script>
		function fade(data){
			if ($(data).css('display')!=='none') {
           		$(data).fadeOut(1500)
       		}
       		else{
       			$(data).show()
           		$(data).fadeOut(1500)
       		}
		}
	</script>
```
我们可以看到，如果不存在用户，则只显示`全部文章` `注册` `登录` ,如果session.user存在则有登出的按钮

我们可以看到当状态data为 3 的时候window.location.href="/signin"
为了方便跳转，我们先简单实现一下signin页面

修改 /routers/signin.js

```js
var router=require('koa-router')();

// get '/signin'登录页面
router.get('/signin',async (ctx,next)=>{
	await ctx.render('signin',{
		session:ctx.session,
	})
})
module.exports=router
```

修改 /views/signin.ejs

```html
<% include header %>
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
![img](/img/signup.png)

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
var router=require('koa-router')();
// 处理数据库（之前已经写好，在mysql.js）
var userModel=require('../lib/mysql.js')
// 加密
var md5=require('md5')

// get '/signin'登录页面
router.get('/signin',async (ctx,next)=>{
	await ctx.render('signin',{
		session:ctx.session,
	})
})
// post '/signin'登录页面
router.post('/signin',async (ctx,next)=>{
	console.log(ctx.request.body)
	var name=ctx.request.body.name;
	var pass=ctx.request.body.password;
	
	// 这里先查找用户名存在与否，存在则判断密码正确与否，不存在就返回false
	await userModel.findDataByName(name)
	 	.then(result =>{
		 	// console.log(reslut)
			var res=JSON.parse(JSON.stringify(result))
			if (name === res[0]['name'] && md5(pass) === res[0]['pass']) {
				ctx.body='true'
				// ctx.flash.success='登录成功!';
				ctx.session.user=res[0]['name']
				ctx.session.id=res[0]['id']
				console.log('ctx.session.id',ctx.session.id)
				// ctx.redirect('/posts')
				console.log('session',ctx.session)
				console.log('登录成功')
			}				
		 }).catch(err=>{
		 	ctx.body='false'
		 	console.log('用户名或密码错误!')
		 	// ctx.redirect('/signin')
		 })
})

module.exports=router
```
我们进行登录操作，判断登录的用户名和密码是否有误，使用md5加密
我们可以看到登录成功返回的结果是`result` 然后处理一下 var res=JSON.parse(JSON.stringify(result))
为什么呢？
因为返回的结果是这样的一个数组：id：4 name：rrr  pass：...
[ RowDataPacket { id: 4, name: 'rrr', pass: '44f437ced647ec3f40fa0841041871cd' } ]

修改views/signin.ejs
signin.ejs

```html
<% include header %>
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
		$('.submit').click(()=>{
			console.log($('.form').serialize())
			$.ajax({
	            url: "/signin",
	            data: $('.form').serialize(),
	            type: "POST",
	            cache: false,
	            dataType: 'json',
	            success: function (msg) {
	               if (!msg) {
	               		$('.error').text('用户名或密码错误')
	               		$('input').val('')
	               		fade('.error')
	               }
	               else{
	               		$('.success').text('登录成功')
	               		fade('.success')
	               		setTimeout(()=>{
		               		window.location.href="/posts"
	               		},1000)    	
	               }      
	                //console.log($('.ui.error.message').text);
	            },
	            error: function () {
	                alert('异常');
	            }
	        })
			
		})
		
	</script>
<% include footer %>
```
我们增加了ajax请求，在routers/singin.js里，我们设置如果登录失败就返回false，登录成功返回true
```
ctx.body='false'
ctx.body='true'
```
那我们登录成功后要做跳转，可以看到`window.location.href="/posts"`跳转到posts页面

## 全部文章

修改routers/posts.js

posts.js

```js
var router=require('koa-router')();
// 处理数据库（之前已经写好，在mysql.js）
var userModel=require('../lib/mysql.js')
// 时间中间件
var moment=require('moment')

// get '/'页面
router.get('/',async (ctx,next)=>{
	ctx.redirect('/posts')
})
// get '/posts'页面
router.get('/posts',async (ctx,next)=>{
	await ctx.render('posts',{
		session:ctx.session
	})
	
})
module.exports=router
```

修改 index.js

app.use(require('./routers/posts.js').routes())的注释去掉

修改 views/posts.ejs

```
<% include header %>

	posts

<% include footer %>
```
现在看看登录成功之后的页面吧

接下来我们事先登出页面

## 登出页面

修改 router/signout.js
signout.js

```js
var router=require('koa-router')();

router.get('/signout',async (ctx,next)=>{
	ctx.session=null;
	console.log('登出成功')
	ctx.body='true'
	
})

module.exports=router
```
把session设置为null即可

修改 index.js

app.use(require('./routers/posts.js').routes())的注释去掉，现在把注释的路由全部取消注释就对了


然后修改 views/header.ejs

```html
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>koa-blog</title>
</head>
<body>
	<link rel="stylesheet" href="/index.css">
	<script src="http://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
	<header>
		<div class="user_name">
			user：
			<% if(session.user){ %>
				 <%= session.user %>
			<% } %>
			<% if(!session.user){ %>
				未登录
			<% } %>
		</div>
		<div class="message">
			<div class="error"></div>
			<div class="success"></div>
		</div>
		<div class="user_right">
			<%  if(session.user){ %>
				<div class="has_user">
					<a href="/posts">全部文章</a>
					<a href="/create">发表文章</a>
					<span class="signout">登出</span>
				</div>
			<% } %>
			<% if(!session.user){ %>
				<div class="none_user">
					<a href="/posts">全部文章</a>
					<a  href="/signup">注册</a>
					<a href="/signin">登录</a>
				</div>
			<% } %>
		</div>
	</header>
	<script>
		function fade(data){
			if ($(data).css('display')!=='none') {
           		$(data).fadeOut(1500)
       		}
       		else{
       			$(data).show()
           		$(data).fadeOut(1500)
       		}
		}
		$('.signout').click(()=>{
			$.ajax({
	            url: "/signout",
	            type: "GET",
	            cache: false,
	            dataType: 'json',
	            success: function (msg) {
	               if (msg) {
	               		$('.success').text('登出成功')
	               		fade('.success')
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
```
增加点击登出后的ajax 的提交，成功之后回到posts页面

## 发表文章

修改router/posts
在后面增加
```js
// get '/create'
router.get('/create',async (ctx,next)=>{
	await ctx.render('create',{
		session:ctx.session,
	})
})

// psot '/create'
router.post('/create',async (ctx,next)=>{
	
	console.log(ctx.session.user)	
	var title=ctx.request.body.title
	var content=ctx.request.body.content
	var id=ctx.session.id
	var name=ctx.session.user
	var time=moment().format('YYYY-MM-DD HH:mm')
	console.log([name,title,content,id,time])
	// 这里我们向数据库插入用户名、标题、内容、发表文章用户的id、时间，成功返回true，失败为false
	await userModel.insertPost([name,title,content,id,time])
		.then(()=>{
			ctx.body='true'
		}).catch(()=>{
			ctx.body='false'
		})
})
```

修改 views/create.ejs

create.ejs

```html
<% include header %>
<div class="container">
	<form method="post" class="form create">
		<div>
			<label>标题：</label>
			<input placeholder="" type="text" name="title">
		</div>
		<div>
			<label>内容：</label>
			<textarea name="content" id="" cols="42" rows="10"></textarea>
		</div>
		<div class="submit">发表</div>
	</form>
</div>	
<script>
	$('.submit').click(()=>{
		$.ajax({
            url: "/create",
            data: $('.form').serialize(),
            type: "POST",
            cache: false,
            dataType: 'json',
            success: function (msg) {
               if (msg) {
               		$('.success').text('发表成功')
               		fade('.success')
               		setTimeout(()=>{
	               		window.location.href="/posts"
               		},1000)
               }else{
                  $('.success').text('发表失败')
                  fade('.success')
                  setTimeout(()=>{
                    window.location.reload()
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
现在看看能不能发表吧

即使我们发表了文章，但是当前我们的posts的页面没有显示，因为还没有获取到数据

接下来

修改 routers/posts.js

修改 get '/posts'

```js
router.get('/posts',async (ctx,next)=>{
	
	// 这里我们先通过查找有没有类似/posts?author=XXX 的连接跳转，如果有就执行下面这句话，把用户名取下来，由于用户名存在中文，所以我们进行解码
	if (ctx.request.querystring) {
		console.log('ctx.request.querystring',decodeURIComponent(ctx.request.querystring.split('=')[1]))
		await userModel.findDataByUser(decodeURIComponent(ctx.request.querystring.split('=')[1]))
			.then(result=>{
				res=JSON.parse(JSON.stringify(result))
				console.log(res)
			})
		await ctx.render('posts',{
				session:ctx.session,
				posts:res	
			})
	}else{
		// 如果连接是正常的 如 /posts 则我们获取的是全部文章的列表，所以通过findAllPost查找全部文章并向模板传递数据posts， posts的值为res
		await userModel.findAllPost()
			.then(result=>{
				console.log(result)
				res=JSON.parse(JSON.stringify(result)) 
				console.log('post',res)
			})
		await ctx.render('posts',{
			session:ctx.session,
			posts:res	
		})
	}
})

```
if (ctx.request.querystring) {}这部分我们先不用管，后面会说。只需要看else后面的代码我们查找我们发表的全部文章然后将获取到的值定义为posts，传给模板posts.ejs，这样就可以渲染出来了

修改 Views/posts.ejs

posts.ejs

```html
<% include header %>
	<ul class="posts">
		<% posts.forEach(function(res){ %>
			<li>
				<div class="post_3">
					<p class="post_user"><a href="/posts?author=<%= res['name'] %>">作者: <%= res['name'] %></a></p>
					<p class="post_comments">评论数：<%= res['comments'] %></p>
					<p class="post_pv">浏览数：<%= res['pv'] %></p>
				</div>
				<a href="/posts/<%= res['id'] %>">
					<div class="post_title">
						<h3>title</h3>
						<p><%= res['title'] %></p>
					</div>	
					<div class="post_content">
						<h3>content</h3>
						<p><%= res['content'] %></p>
					</div>
				</a>		
				<p class="post_time">发表时间：<%= res['moment'] %></p>
			</li>
		<% }) %>	
	</ul>
<% include footer %>
```
现在看看posts页面有没有文章出现了

我们看到是所有的文章，但是我需要点击单篇文章的时候，显示一篇文章怎么办呢？

修改 routers/posts.js

在posts.js后面增加

```js
router.get('/posts/:postId',async (ctx,next)=>{
	console.log(ctx.params.postId)
	// 通过文章id查找返回数据，然后增加pv 浏览 +1 
	await userModel.findDataById(ctx.params.postId)
		.then(result=>{
				res=JSON.parse(JSON.stringify(result))
				res_pv=parseInt(JSON.parse(JSON.stringify(result))[0]['pv'])
				res_pv+=1
				console.log(res)
			})
	
	// 渲染模板，并传递三个数据		
	await ctx.render('sPost',{
				session:ctx.session,
				posts:res
			})
})
```

现在的设计是，我们点进去出现的url是 /posts/1 这类的 1代表该篇文章的id，我们在数据库建表的时候就处理了，让id为主键，然后递增

我们通过userModel.findDataById 文章的id来查找数据库
我们通过userModel.findCommentById 文章的id来查找文章的评论，因为单篇文章里面有评论的功能

## 单篇文章页

修改 views/sPost.ejs

sPost.ejs

```html
<% include header %>	
	<div class="spost">
		<p class="spost_user">author: <a href="/posts?author=<%= posts[0]['name'] %>"><%= posts[0]['name'] %></a></p>
		<div class="post_title">
			<h3>title</h3>
			<p><a href="/posts/<%= posts[0]['id'] %>"><%= posts[0]['title'] %></a></p>
		</div>
		<div class="post_content">
			<h3>content</h3>
			<p><%= posts[0]['content'] %></p>
		</div>
		<div class="edit">
			<% if(session && session.user===  posts[0]['name']  ){ %>
			<p><a href="<%= posts[0]['id'] %>/edit">编辑</a></p>
			<p><a class="delete_post" >删除</a></p>
			<% } %>
			<script>
				$('.delete_post').click(()=>{
					$.ajax({
						url:"<%= posts[0]['id'] %>/remove",
						type:'GET',
						cache: false,
						success:function(msg){
							if (msg.data==1) {
								$('.success').text('删除文章成功')
               					fade('.success')
               					setTimeout(()=>{
					               		window.location.href="/posts"	
               					},1000)
							}else if(msg.data==2){
								$('.error').text('删除文章失败')
               					fade('.error');
               					setTimeout(()=>{
	               					window.location.reload()
               					},1000)
							}
						}
					})
				})
			</script>
		</div>
	</div>
	<div class="comment_wrap">
		<h3>comment</h3>
		<div class="comment_list">
			<% comments.forEach(function(res){ %>
				<div class="cmt_lists">
					<p></p>
					<p class="cmt_content">
						content: <%= res['content'] %>
						<span class="cmt_name">
							By: <%= res['name'] %>
							<% if(session && session.user ===  res['name']  ){ %>
								<a class="delete_comment"> 删除</a>
							<% } %>
						</span>
					</p>
				</div>
				<script>
					$('.delete_comment').click(()=>{
						$.ajax({
							url:"<%= posts[0]['id'] %>/comment/<%= res['id'] %>/remove",
							type:'GET',
							cache: false,
							success:function(msg){
								if (msg.data==1) {
									$('.success').text('删除留言成功')
	               					fade('.success')
	               					setTimeout(()=>{
		               					window.location.reload()
	               					},1000)
								}else if(msg.data==2){
									$('.error').text('删除留言失败')
	               					fade('.error');
	               					setTimeout(()=>{
		               					window.location.reload()
	               					},1000)
								}
							},
							error:function(){
								alert('异常')
							}
						})
					})
				</script>
			<% }) %>
		</div>	
		<% if(session.user){ %>
		<form class="form" method="post" action="/<%= posts[0]['id'] %>">
			<textarea name="content" id=""></textarea>
			<div class="submit">发表留言</div>
		</form>
		<% } %>
	</div>
	<script>
		$('.submit').click(function(){
			$.ajax({
	            url: '/'+document.URL.slice(document.URL.lastIndexOf('/')+1),
	            data:$('.form').serialize(),
	            type: "POST",
	            cache: false,
	            dataType: 'json',
	            success: function (msg) {
	               if (msg) {
	               		$('.success').text('发表留言成功')
	               		fade('.success')
	               		setTimeout(()=>{
		               		window.location.reload()
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
现在点击单篇文章试试，进入单篇文章页面，但是编辑、删除、评论都还没有做，点击无效，我们先不做，先实现每个用户发表的文章列表，我们之前在 get '/posts' 里面说先忽略if (ctx.request.querystring) {}里面的代码，这里是做了应该处理，假如用户点击了某个用户，该用户发表了几篇文章，我们需要只显示该用户发表的文章，那么进入的url应该是 /posts?author=xxx ,这个处理在posts.ejs 就已经加上了，就在文章的左下角，作者：xxx就是一个链接。我们通过判断用户来查找文章，继而有了`ctx.request.querystring` 获取到的是：`author=XXX`

注：这里我们处理了，通过判断 `session.user ===  res['name']` 如果不是该用户发的文章，不能编辑和删除，评论也是。这里面也可以注意一下包裹的`<a href=""></a>`标签


## 编辑文章、删除文章、评论、删除评论

> 评论

修改routers/posts.js 

在post.js 后面增加

```js
router.post('/:postId',async (ctx,next)=>{
	var name=ctx.session.user
	var content=ctx.request.body.content
	var postId=ctx.params.postId
	
	// 插入评论的用户名，内容和文章id
	await userModel.insertComment([name,content,postId])
	// 先通过文章id查找，然后评论数+1
	await userModel.findDataById(postId)
			.then(result=>{
				res_comments=parseInt(JSON.parse(JSON.stringify(result))[0]['comments'])
				res_comments+=1
			})
	// 更新评论数 res_comments
	await userModel.updatePostComment([res_comments,postId])
		.then(()=>{
			ctx.body='true'
		}).catch(()=>{
			ctx.body='false'
		})	
})
```
现在试试发表评论的功能吧，之所以这样简单，因为我们之前就在sPost.ejs做了好几个ajax的处理，删除文章和评论也是如此

> 删除评论

修改routers/posts.js 

继续在post.js 后面增加

```js
router.get('/posts/:postId/comment/:commentId/remove',async (ctx,next)=>{
	
	var postId=ctx.params.postId
	var commentId=ctx.params.commentId
	await userModel.findDataById(postId)
			.then(result=>{
				res_comments=parseInt(JSON.parse(JSON.stringify(result))[0]['comments'])
				console.log('res',res_comments)
				res_comments-=1
				console.log(res_comments)
			})
	await userModel.updatePostComment([res_comments,postId])
	await userModel.deleteComment(commentId)
		.then(()=>{
			 ctx.body={
			 	data:1
			 }
		}).catch(()=>{
			  ctx.body={
			 	data:2
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
router.get('/posts/:postId/remove',async (ctx,next)=>{
	
	var postId=ctx.params.postId
	
	await userModel.deleteAllPostComment(postId)
	await userModel.deletePost(postId)
		.then(()=>{
			 ctx.body={
			 	data:1
			 }	
		}).catch(()=>{
			ctx.body={
			 	data:2
			 }
		})
	
})
```
现在试试删除文章的功能吧

> 编辑文字

修改routers/posts.js 

继续在post.js 后面增加

```js
// get '/posts/:postId/edit'
router.get('/posts/:postId/edit',async (ctx,next)=>{
	var name=ctx.session.user
	var postId=ctx.params.postId
	
	await userModel.findDataById(postId)
		.then(result=>{
			res=JSON.parse(JSON.stringify(result))
			console.log('修改文章',res)
		})
	await ctx.render('edit',{
			session:ctx.session,
			posts:res
		})
})
// post '/posts/:postId/edit'
router.post('/posts/:postId/edit',async (ctx,next)=>{
	var title=ctx.request.body.title
	var content=ctx.request.body.content
	var id=ctx.session.id
	var postId=ctx.params.postId
		
	await userModel.updatePost([title,content,postId])
		.then(()=>{
			ctx.body='true'
		}).catch(()=>{
			ctx.body='false'
		})
})
```

修改views/edit.js 

```html
<% include header %>
<div class="container">
	<form class="form create" method="post">
		<div>
			<label>标题：</label>
			<input placeholder="标题" type="text" name="title" value="<%= posts[0]['title'] %>">
		</div>
		<div>
			<label>内容：</label>
			<textarea name="content" id="" cols="42" rows="10">
				<%= posts[0]['content'] %>
			</textarea>
		</div>
		<!-- <input type="submit" value="修改"> -->
		<div class="submit">修改</div>
	</form>
</div>
<script>
	$('.submit').click(()=>{
		$.ajax({
            url: document.URL,
            data: $('.form').serialize(),
            type: "POST",
            cache: false,
            dataType: 'json',
            success: function (msg) {
               if (msg) {
               		$('.success').text('修改成功')
               		fade('.success')
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