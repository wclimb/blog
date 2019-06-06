---
title: 读zepto源码，封装自己的zepto库（二）
date: 2017-07-17 22:01:36
tags:
- zepto
- javascript
- 原创
---

距离上一篇zepto源码分析已经过去大半个月，想想自己都过意不去，不过之前分享了一篇node博客教程，还算干了点正事。接下来我们继续封装自己的库吧


## 上节代码概览

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

## each方法
<!-- more -->
在`wclimb.Z.prototype=Z.prototype=`里面添加方法each

```js
wclimb.Z.prototype  =  Z.prototype  =  {
	each:function(callback){
		[].every.call(this, function(el, idx){
        return callback.call(el, idx, el) !== false
      })
      return this;
	}
}
```
通过数组的`every`方法进行遍历，然后看看每次`callback`是不是都不是`false`，如果是则结束遍历

最后通过 `return this` 来达到链式调用的效果

## addClass方法

继续在里面添加addClass方法

```js
addClass:function(name){
	if (!name) return this
      return this.each(function(el,idx){
        if (!('className' in this)) return
        classList = [];

        var cls = className(this) 
        // newName = funcArg(this, name, idx, cls)
        name.split(/\s+/g).forEach(function(klass){

          // if (!$(this).hasClass(klass)) 
          	classList.push(klass)
          
        }, this)
      
        classList.length && className(this, cls + (cls ? " " : "") + classList.join(" "))
     })
}
```
* 我们先判断`name`存在与否，没有就直接`return this`，支持链式调用
* 新建一个数组，存放我们要添加的`class`，因为可能要同时添加多个
* 通过调用`className`方法来获取之前的`class`，并保存起来。`clasName`方法在下面
* 我们添加`class`一般是这样`addClass('a b c')`，所以我们通过正则表达式把他们用空格分开`/\s+/g`,用`+`的原因是，可能会有多个空格的存在，接着对他们进行循环
* 通过hasClass判断之前是否已经存在需要添加的class，如果有就push到`classList`数组里面。我们先注释掉hasClass这段代码，因为其中用到了$(this) ,querySelector是不支持的哟，所以后面我们得作判断，判断$()这里面放的是元素、函数、类数组等等。
* 最后通过函数`className`方法把他们用空格连接起来


发现里面有一个没有声明的`className`方法
所以我们在`wclimb.Z.prototype=Z.prototype=`上面声明该函数
```js
//获取或者设置class
function className(node, value){
	var klass = node.className || ''	

if (value === undefined) return klass
	node.className = value
}
```
该方法主要是获取class和设置class的作用

## hasClass方法
```js
hasClass : function(cls) {
    var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
    for (var i = 0; i < this.length; i++) {
        if (this[i].className.match(reg)) return true;
            return false;
    }
    return this;
}
```
通过正则匹配，如果存在则返回`true`，否则返回`false`，最后`return this`支持链式调用


现在来试试效果吧
```js
html:
	<p class="a"></p>
js:
	$('p').addClass('test other') // <p class="a test other"></p>
	console.log($('p').hasClass('a')) // true
```
## 代码
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

	 function className(node, value){//获取或者设置class
	    var klass = node.className || ''	 

	    if (value === undefined) return klass
	    node.className = value

	  }

	wclimb.Z.prototype  =  Z.prototype  =  {
		each:function(callback){
			[].every.call(this, function(el, idx){
	        return callback.call(el, idx, el) !== false
	      })
	      return this;
		},
		addClass:function(name){
			if (!name) return this
	      	return this.each(function(el,idx){
		        if (!('className' in this)) return
		        classList = [];

		        var cls = className(this) 
		       
		        name.split(/\s+/g).forEach(function(klass){

		          // if (!$(this).hasClass(klass))
		           classList.push(klass)

		        }, this)
		       
		        classList.length && className(this, cls + (cls ? " " : "") + classList.join(" "))

		    })
		},
		hasClass : function(cls) {
		    var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
		    for (var i = 0; i < this.length; i++) {
		        if (this[i].className.match(reg)) return true;
		            return false;
		    }
		    return this;
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