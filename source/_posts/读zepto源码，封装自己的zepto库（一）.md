---
title: 读zepto源码，封装自己的zepto库（一）
date: 2017-06-29 10:48:02
tags:
- zepto
- javascript
- 原创
---

## 写在前面

> 读zepto源码，封装自己的zepto库系列是自己在读zepto源码的一些理解，有错误的地方还望指出。如果觉得本系列对你有所帮助，还请持续关注wclimb，谢谢。

## zepto的整体架构

首先来看看整体代码结构

```js
(function(){

	var wclimb = {},$

	$ = function(selector){
		return wclimb.init(selector)
	}
	wclimb.init = function(selector){
		var dom;
		dom = document.querySelectorAll(selector);

		return wclimb.Z(dom,selector)

	}
	wclimb.Z = function(dom,selector){
		return new Z(dom,selector)
	}
	wclimb.Z.prototype  =  Z.prototype  =  {
		test:function(){
			alert(1)
		}
	}
	function Z(dom,selector) {
		for (var i  =  0; i < dom.length; i++) {
			this[i] = dom[i]
		}
		this.selector = selector;
		this.length = dom.length
	}

	window.$ = window.wclimb = $

})()

```

首先我们设置了一个闭包，避免产生全局变量
<!-- more -->
```js
(function(){
	...
})()

```

我们定义一个对象wclimb和$，以便后面使用

```js
var wclimb = {},$

```

$函数返回了wclimb.init(selector),我们知道使用zepto的时候，一般是$('p')，而selector就是p元素，当然不止这一种情况如$(function(){}),所以对选择器后面我们要做判断
```js
$ = function(selector){
	return wclimb.init(selector)
}

```

而wclimb.init首先定义了一个dom，通过选择器选取的元素赋值给dom，最后返回wclimb.init，传入dom和选择元素selector

```js
wclimb.init = function(selector){
	var dom;
	dom = document.querySelector(selector);
	return wclimb.Z(dom,selector)
}

```

我们可以看到之前我们定义了对象wclimb，而后我们就往里面添加了一些方法，就像：

```js
wclimb = {
	init：function(selector){
		var dom;
		dom = document.querySelector(selector);
		return wclimb.Z(dom,selector)
	},
	Z: function(dom,selector){
		return new Z(dom,selector)
	}
}

```
通过wclimb.Z，如果有看过zepto源码的同学应该对此有了解.每次用$调用的时候,将直接返回一个Z的实例.达到无new调用的效果,$('p')返回一个实例，然后$('p').test()调用他的原形方法，这里的方法是test

```js
wclimb.Z = function(dom,selector){
	return new Z(dom,selector)
}

function Z(dom,selector) {
	for (var i = 0; i < dom.length; i++) {
		this[i] = dom[i]
	}
	this.selector = selector;
	this.length = dom.length
}
```

由于我们是return new Z(dom,selector),那自然,我们需要手动的把wclimb.Z的prototype指向Z的prototype

```js
wclimb.Z.prototype = Z.prototype{}

我们可以在里面添加方法了，如addClass eq等，我们试试加一个test

wclimb.Z.prototype = Z.prototype{
	test: function(){
		console.log('test')
	}
}
```
Z函数是这样的，因为我们选择器选择的元素是一个数组（其实不是）我们把this指向选择的元素，然后添加两个元素selector和length，分别代表选择的元素名和元素的长度

```js
function Z(dom,selector) {
	for (var i = 0; i < dom.length; i++) {
		this[i] = dom[i]
	}
	this.selector = selector;
	this.length = dom.length
}


```

最后我们在window上对外暴露一个接口,我们就可以用 $('p') 或者wclimb('p') 即可调用.

```js
window.$ = window.wclimb = $
```

现在可以试试能不能运行

```js
html：<p>test</p>

js：$('p')  调用方法试试 $('p').test()
```

我们的zepto已经完成了，是不是很简单？骗你的，还差得远呢，后面会慢慢完善。待续。。。
如果你觉得该文章帮助到了你，不妨star一下https://github.com/wclimb/wclimb.github.io ，感谢
