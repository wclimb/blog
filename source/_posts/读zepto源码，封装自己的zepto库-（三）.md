---
title: 读zepto源码，封装自己的zepto库 （三）
date: 2017-07-18 09:55:40
tags:
- zepto
- javascript
- 原创
---

本篇着重讲选择器$()选择器
本例我们主要修改`wclimb.init=function(selector){}`里面的代码
将wclimb.init代码修改为：
```js
var dom
if (!selector) return wclimb.Z()
else if (typeof selector == 'string') {
	dom = wclimb.qsa(document, selector)
}
else if (typeof selector == 'function'){
	return wclimb.ready(selector)
}
else{
	if (isArray(selector)) {
		dom = compact(selector) 
	}
	else if (wclimb.isZ(selector)) return selector		
	else{
		if (isObject(selector)) dom = [selector], selector = null ;
		else dom=wclimb.qsa(document,selector)
	}

}
return wclimb.Z(dom, selector)

```
<!-- more -->
* 首先判断是否存在selector，如果不存在则直接return
* 然后判断是否是字符串类型，如`$('a b')`，将选择的元素保存起来
* 如果是函数则`return wclimb.ready(selector)`就是我们经常用的`$(function(){})`
* 后面判断是否是当前对象的实例（用了isZ方法）还有判断是否是数组或对象

我们先在函数顶部添加如下
```js
emptyArray = [], concat = emptyArray.concat, filter = emptyArray.filter
slice = emptyArray.slice
function compact(array) { return filter.call(array, function(item){ return item != null }) }
```
emptyArray = []，避免出现每次都重复创建的一个数组[]
然后拿到数组里面的方法
compact就是一个数组筛选，如果某个元素不存在$([1,2,,,4]);只会创建一个[1,2,4]的数组

## wclimb.qsa方法
```js
wclimb.qsa=function(element, selector){
	var found,
    maybeID = selector[0] == '#',
    maybeClass = !maybeID && selector[0] == '.',
    nameOnly = maybeID || maybeClass ? selector.slice(1) : selector, // Ensure that a 1 char tag name still gets checked
    isSimple = /^[\w-]*$/.test(nameOnly)

	return (element.getElementById && isSimple && maybeID) ? // Safari DocumentFragment doesn't have getElementById
	  ( (found = element.getElementById(nameOnly)) ? [found] : [] ) :
	  (element.nodeType !== 1 && element.nodeType !== 9 && element.nodeType !== 11) ? [] :
	  slice.call(
	    isSimple && !maybeID && element.getElementsByClassName ? // DocumentFragment doesn't have getElementsByClassName/TagName
	    maybeClass ? element.getElementsByClassName(nameOnly) : // If it's simple, it could be a class
	    element.getElementsByTagName(selector) : // Or a tag
	    element.querySelectorAll(selector) // Or it's not simple, and we need to query all
	)
}
```
这里我直接用了zepto的代码
`wclimb.init=function(selector){}`里的代码还使用了判断数据类型的代码`isArray``isObject`

## 判断数据类型

在函数外面添加如下代码来进行数据类型判断

```js
// 判断类型
var obj_i={};
['Boolean', 'Number','String', 'Function', 'Array' ,'Date', 'RegExp', 'Object' ,'Error'].forEach(function(el,idx){
	obj_i["[object " + el + "]"] = el.toLowerCase()
})
function type(obj) {
    return obj == null ? String(obj) :
    obj_i[Object.prototype.toString.call(obj)] || "object"
}
function isObject(obj) { return type(obj) == "object" }	
function isArray(obj) { return type(obj) == "array" }
function isString(obj) { return type(obj) == "string" }

```

## wclimb.ready函数
在外面设置如下函数
```js
wclimb.ready = function(fn) {
    document.addEventListener('DOMContentLoaded',function() {
        fn && fn();
    },false);
    document.removeEventListener('DOMContentLoaded',fn,true);
};
```
## wclimb.isZ函数

下面代码判断`object`是不是`wclimb.Z`的实例
```js
wclimb.isZ = function(object) {
    return object instanceof wclimb.Z
}
```
现在试试代码吧，我们顺便把addClass里判断hasClass代码注释去掉了

```js
<script>
	// ready
	$(function(){
		alert(1)
	})
	// addClass
	$('p').addClass('a b')
	// 实例
	console.log($(this))
	// 数组
	$([1,23,3,,4])
</script>
```

## 全部代码

```js
(function(){

	var wclimb = {},$
	emptyArray = [], concat = emptyArray.concat, filter = emptyArray.filter
	slice = emptyArray.slice
	function compact(array) { return filter.call(array, function(item){ return item != null }) }

	$ = function(selector){
		return wclimb.init(selector)
	}
	
	wclimb.init = function(selector){
		var dom
		if (!selector) return wclimb.Z()
		else if (typeof selector == 'string') {
			dom = wclimb.qsa(document, selector)
		}
		else if (typeof selector == 'function'){
			return wclimb.ready(selector)
		}
		else{
			if (isArray(selector)) {
				dom = compact(selector) 
			}
			else if (wclimb.isZ(selector)) return selector		
			else{
				if (isObject(selector)) dom = [selector], selector = null ;
				else dom=wclimb.qsa(document,selector)
			}

		}
		return wclimb.Z(dom, selector)

	}
	wclimb.Z = function(dom,selector){
		return new Z(dom,selector)
	}

	function className(node, value){
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

		          if (!$(this).hasClass(klass))
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
	wclimb.ready = function(fn) {
	    document.addEventListener('DOMContentLoaded',function() {
	        fn && fn();
	    },false);
	    document.removeEventListener('DOMContentLoaded',fn,true);
	};

	wclimb.qsa=function(element, selector){
		var found,
	    maybeID = selector[0] == '#',
	    maybeClass = !maybeID && selector[0] == '.',
	    nameOnly = maybeID || maybeClass ? selector.slice(1) : selector, // Ensure that a 1 char tag name still gets checked
	    isSimple = /^[\w-]*$/.test(nameOnly)

		return (element.getElementById && isSimple && maybeID) ? // Safari DocumentFragment doesn't have getElementById
		  ( (found = element.getElementById(nameOnly)) ? [found] : [] ) :
		  (element.nodeType !== 1 && element.nodeType !== 9 && element.nodeType !== 11) ? [] :
		  slice.call(
		    isSimple && !maybeID && element.getElementsByClassName ? // DocumentFragment doesn't have getElementsByClassName/TagName
		    maybeClass ? element.getElementsByClassName(nameOnly) : // If it's simple, it could be a class
		    element.getElementsByTagName(selector) : // Or a tag
		    element.querySelectorAll(selector) // Or it's not simple, and we need to query all
		)
	}

	function Z(dom,selector) {
		for (var i  =  0; i < dom.length; i++) {
			this[i] = dom[i]
		}
		this.selector = selector;
		this.length = dom.length
	}
	wclimb.isZ = function(object) {
	    return object instanceof wclimb.Z
	}
	// 判断类型
	var obj_i={};
	['Boolean', 'Number','String', 'Function', 'Array' ,'Date', 'RegExp', 'Object' ,'Error'].forEach(function(el,idx){
		obj_i["[object " + el + "]"] = el.toLowerCase()
	})
	function type(obj) {
	    return obj == null ? String(obj) :
	    obj_i[Object.prototype.toString.call(obj)] || "object"
	}
	function isObject(obj) { return type(obj) == "object" }	
	function isArray(obj) { return type(obj) == "array" }
	function isString(obj) { return type(obj) == "string" }

	window.$ = window.wclimb = $

})()
```




