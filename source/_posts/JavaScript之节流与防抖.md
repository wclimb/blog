---
title: JavaScript之节流与防抖
date: 2018-06-12 17:13:49
tags:
- javascript
- 原创
categories: [javascript]
---

# 背景

我们在开发的过程中会经常使用如scroll、resize、touchmove等事件，如果正常绑定事件处理函数的话，有可能在很短的时间内多次连续触发事件，十分影响性能。
因此针对这类事件要进行节流或者防抖处理

# 节流

节流的意思是，在规定的时间内只会触发一次函数，如我们设置函数`500ms`触发一次，之后你无论你触发了多少次函数，在这个时间内也只会有一次执行效果

先来看一个例子

<p data-height="373" data-theme-id="0" data-slug-hash="gKWLpO" data-default-tab="html,result" data-user="wclimb" data-embed-version="2" data-pen-title="gKWLpO" class="codepen">See the Pen <a href="https://codepen.io/wclimb/pen/gKWLpO/">gKWLpO</a> by wclimb (<a href="https://codepen.io/wclimb">@wclimb</a>) on <a href="https://codepen.io">CodePen</a>.</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

我们看到使用了节流的在`1000ms`内只触发了一次，而没有使用节流的则频繁触发了调用的函数

接下来看看代码实现
v1 第一次不触发，不传参实现
```js
function throttle(fn,interval){
    var timer;
    return function(){
        if(timer){
            return
        }
        timer = setTimeout(() => {
            clearTimeout(timer)
            timer = null
            fn()
        }, interval || 1000);
    }   
}
```
效果是实现了，但是我在尝试在执行函数里`console.log(this)`，结果发现`this`指向的是`window`，而且还发现我们不能传递参数，下面就来改进一下
<!-- more -->
v2 第一次触发函数，接收参数
```js
function throttle(fn,interval){
    var timer,
        isFirst = true;
    return function(){
        var args = arguments,
            that = this;
        if(isFirst){
            fn.apply(that,args)
            return isFirst = false
        }
        if(timer){
            return
        }
        timer = setTimeout(() => {
            clearTimeout(timer)
            timer = null
            fn.apply(that,args)
        }, interval || 1000);
    }   
}
```

# 防抖

防抖的意思是无论你触发多少次函数，只会触发最后一次函数。最常用的就是在表单提交的时候，用户可能会一段时间内点击很多次，这个时候可以增加防抖处理，我们只需要最后一次触发的事件

先来看一个例子

<p data-height="424" data-theme-id="0" data-slug-hash="pKPeyv" data-default-tab="js,result" data-user="wclimb" data-embed-version="2" data-pen-title="pKPeyv" class="codepen">See the Pen <a href="https://codepen.io/wclimb/pen/pKPeyv/">pKPeyv</a> by wclimb (<a href="https://codepen.io/wclimb">@wclimb</a>) on <a href="https://codepen.io">CodePen</a>.</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

我们看到使用了防抖的方框，无论你在里面触发了多少次函数，都只会触发最后的那一次函数，而没有使用防抖的则频繁触发了调用的函数

v1 第一次不触发函数

```js
function debounce(fn,interval){
    var timer;
    return function(){
        var args = arguments,
            that = this;
        if(timer){
            clearTimeout(timer)
            timer = null
        }
        timer = setTimeout(() => {
            fn.apply(null,args)
        }, interval || 1000);
    }
}
```
上面这段代码仍然可以正常执行，但是我们并没有指定他的`this`

v2 第一次就触发函数
```js
function debounce(fn,interval){
    var timer,
        isFirst  = true,
            can = false;
    return function(){
        var args = arguments,
            that = this;
        if(timer){
            clearTimeout(timer)
            timer = null
        }
        if(isFirst){
            fn.apply(that,args)
            isFirst = false
            setTimeout(() => {
                can = true
            }, interval || 1000);
        }else if(can){
            timer = setTimeout(() => {
                fn.apply(null,args)
            }, interval || 1000);
        }
    }
}
```

如有雷同，纯属抄我（开玩笑）

如有错误，还望指正，仅供参考

GitHub：[wclimb](https://github.com/wclimb)

## QQ群

有兴趣的同学可以加qq群: 725165362 [点击加入](http://shang.qq.com/wpa/qunwpa?idkey=e6c66b1ee584a90b52dec3545622e988afcf900144eff03cab6d473c50a31d59)

## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)

