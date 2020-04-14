---
title: Nodejs之实现一个模版引擎
date: 2020-04-14 13:45:31
tags:
- javascript
- Node
- 原创
categories: [Node,模版引擎]
---

## 前言

最近看完了朴大的 《深入浅出nodejs》 这本书，在里面学到了许多，也推荐大家可以去看一下，看完感觉可以写几篇文章记录总结一下，提升一下印象，毕竟学到的东西感觉不记下来过不久就容易忘记，大家也要养成学习记录的习惯，方便以后重温，今天来实现一个 `node` 的模版引擎，当然这个模版引擎在前端也可以用。

## 借鉴ejs标签

标签借鉴 `ejs`，用过的同学肯定知道，例如使用 `<%= name %>` 这种标签来展示数据，使用 `<% if(name){ %>` 这种标签来做 `js` 操作，如 `if` 判断/ `for`循环，比如下面
```html
<% if (name) { %>
  <h1><%=name%></h1>
<% } else { %>
  <h1>请登陆</h1>
<% } %>
```

## 渲染方法

我们先来看个简单的渲染<!-- more -->
```js
let str = 'hello <%=name%>'
```
假如我们的有一个字段 `name = 'wclimb';`
```js
const name = 'wclimb';
let str = 'hello <%=name%>';
str.replace(/<%=([\S\s]+?)%>/g, function(match,value){
  return name
})
```
结果
```
hello wclimb
```
按照这个思路就很简单了，我们先来思考🤔一个问题，数据渲染简单，直接替换就可以来了，那么 `js` 的逻辑判断这种怎么处理呢，我们拿到的都是字符串，这里需要借助 `Function` 来实现，具体渲染成如下样式
```js
let tpl = '';
if (name){
  tpl += '<h1>' + name ' +</h1>'
}else{
  tpl += '<h1>请登陆</h1>'
}
```
然后使用 `new Function` , 
```js
const complied = new Function('name',tpl); 
const result = complied()
console.log(result)
```

直接上代码
```js
const render = function(str, data) {
  str = str
    .replace(/\n/g, "")
    .replace(/\s{2,}/g, "")
    .replace(/<%=([\S\s]+?)%>/g, function(match, val) {
      return `'+ ${val} +'`;
    })
    .replace(/<%([\S\s]+?)%>/g, function(match, val) {
      return `';\n${val}\ntpl +='`;
    });

  str = `let tpl = '${str}';return tpl;`;
  str = `with(option){${str};return tpl;}`;
  const complied = new Function("option", str);
  let result;
  try {
    result = complied(data);
  } catch (error) {
    console.log(error);
  }
  return result;
};
```
看着整个代码感觉没什么，等等，`with` 是什么？知道的同学可以忽略后面的，`with` 的作用就是通常我们取数据都是 `let people = obj.name +'-'+ obj.age` 这样，每次都需要拿 `obj`，为了简化我们可以这样写：
```js
const obj = {name:'wclimb', age: 26}
let people
with(obj){
  people = name +'-'+ age
}
```
但是不推荐用 `with`，容易引起作用域混乱，但是我看 `Vue` 源码也用到了，还是谨慎一点。比如如下：
```js
with (obj) { 
  foo = bar;
}
```
它的结果有可能是如下四种之一: `obj.foo = obj.bar;`、`obj.foo = bar;`、`foo = bar;`、`foo = obj.bar;`，这些结果取决于它的作用域。如果作用域链上没有导致冲突的变量存在，使用它则是 安全的。但在多人合作的项目中，这并不容易保证，所以要慎用 `with`

### xss攻击

我们需要时刻关注安全，在上面的模版上，如果 `name` 是 `<script>alert('xss攻击')</script`>，那么我们渲染到页面上100%会显示一个弹窗，很危险。因此我们需要对尖括号进行转义，我们单独写一个方法处理

```js
const escape = function(html) {
  return String(html)
    .replace(/&(?!\w+;)/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;"); // IE下不支持&apos;(单引号)转义
  };
```
当然，并不是所有的都需要转义，比如我就是想让他输出有格式的标签 `<h1>h1</h1>`，所以我们需要提供两种不同的标签，`ejs` 就提供了,如下
```
<%= name %> 会转义
<%- name %> 原始输出

如果输入<h1>h1</h1>，他们的对应结果是
<%= name %> <h1>h1</h1>
<%- name %> 有格式的 h1
```

然后完善一下
```diff
const render = function(str, data) {
+  const escape = function(html) {
+    return String(html)
+      .replace(/&(?!\w+;)/g, "&amp;")
+      .replace(/</g, "&lt;")
+      .replace(/>/g, "&gt;")
+      .replace(/"/g, "&quot;")
+      .replace(/'/g, "&#039;"); // IE下不支持&apos;(单引号)转义
+  };
  str = str
    .replace(/\n/g, "")
    .replace(/\s{2,}/g, "")
    .replace(/<%-([\S\s]+?)%>/g, function(match, val) {
      return `'+ ${val} +'`;
    })
+    .replace(/<%=([\S\s]+?)%>/g, function(match, val) {
+      return `'+ escape(${val}) +'`;
+    })
    .replace(/<%([\S\s]+?)%>/g, function(match, val) {
      return `';\n${val}\ntpl +='`;
    });

  str = `let tpl = '${str}';return tpl;`;
  str = `with(option){${str};return tpl;}`;
  const complied = new Function("option", str);
  let result;
  try {
    result = complied(data);
  } catch (error) {
    console.log(error);
  }
  return result;
};
```

## 测试

```js
const str = `
  <% for (var i = 0; i < users.length; i++) { %> 
    <% var item = users[i];%>
    <p><%= (i+1) %>、<%-item.name%></p>
  <% } %>`;
const result = render(str, {users: [{ name: "wclimb" }, { name: "other" }]});
```
结果
```
<p>1、wclimb</p><p>2、other</p>
```

上面可能不好复制，下面是完整代码
```js
const render = function(str, data) {
 const escape = function(html) {
   return String(html)
     .replace(/&(?!\w+;)/g, "&amp;")
     .replace(/</g, "&lt;")
     .replace(/>/g, "&gt;")
     .replace(/"/g, "&quot;")
     .replace(/'/g, "&#039;"); // IE下不支持&apos;(单引号)转义
 };
  str = str
    .replace(/\n/g, "")
    .replace(/\s{2,}/g, "")
    .replace(/<%-([\S\s]+?)%>/g, function(match, val) {
      return `'+ ${val} +'`;
    })
    .replace(/<%=([\S\s]+?)%>/g, function(match, val) {
      return `'+ escape(${val}) +'`;
    })
    .replace(/<%([\S\s]+?)%>/g, function(match, val) {
      return `';\n${val}\ntpl +='`;
    });

  str = `let tpl = '${str}';return tpl;`;
  str = `with(option){${str};return tpl;}`;
  const complied = new Function("option", str);
  let result;
  try {
    result = complied(data);
  } catch (error) {
    console.log(error);
  }
  return result;
};
```

### 使用文件模版

我们可以新建一个模版 `test.ejs` 文件，内容为之前的测试内容
```js
render(fs.readFileSync(`test.ejs`, "utf8") ,{users: [{ name: "wclimb" }, { name: "other" }]});
```

## 结尾

一个模版引擎就完成了，挺简单的，说得有点多了，下一篇带大家实现一个路由和中间件

## Reference

* [深入浅出nodejs](https://book.douban.com/subject/25768396/)

本文地址 [Nodejs之实现一个模版引擎](http://www.wclimb.site/2020/04/14/node-template/)