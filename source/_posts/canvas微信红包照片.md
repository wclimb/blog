---
title: canvas仿微信红包照片
date: 2017-06-28 21:27:33
tags:
- canvas
- 原创

categories: [javascript,canvas]
---

# canvas仿微信红包照片 By wclimb

## HTML

```
<canvas id="cav" width="500" height="500"></canvas>

```

## CSS

> 设置canvas的背景图

```css
canvas{
    background:url(https://b-ssl.duitang.com/uploads/item/201501/22/20150122203239_Cfr58.thumb.700_0.jpeg) no-repeat;
    background-size:100% 100%;
}

```

## JS	


```js
var canvas = document.querySelector("#cav")
var context = canvas.getContext("2d");

var randomX = Math.floor(Math.random()*440+30)
var randomY = Math.floor(Math.random()*440+30)

context.globalAlpha = 0.96;
context.fillStyle = '#333'
context.rect(0,0,canvas.width,canvas.height);
context.fill();

context.save()
context.beginPath()
context.arc(randomX,randomY,30,0,Math.PI*2,false);
context.clip();
context.clearRect(0,0,canvas.width,canvas.height)
context.restore();

var num = 30;
var time = null;
document.body.onclick = function(){
    function circle(){
        num += 5
        context.save()
        context.beginPath()
        context.arc(randomX,randomY,num,0,Math.PI*2,false);
        context.clip();
        context.clearRect(0,0,canvas.width,canvas.height)
        context.restore();
        console.log(num)

        if (num >= 677){
        	clearInterval(timer)
        }
    }
    timer = setInterval(circle,10)
}
```
<!-- more -->

## 解析

> 随机出现圆心的位置，因为canvas为500*500 圆心为30 所以圆心的范围为 X(30,470) Y(470,30)



```js
var randomX = Math.floor(Math.random()*440+30)
var randomY = Math.floor(Math.random()*440+30)
```

> 绘制矩形 透明度为0.96 填充颜色#333 宽高为canvas的宽高 最后用fill填充

```js
context.globalAlpha = 0.96;
context.fillStyle = '#333'
context.rect(0,0,canvas.width,canvas.height);
context.fill();
```

> 初始化圆心的位置，用arc绘制圆，默认半径为30，用clip剪切，只有被剪切区域内是可见的

```js
context.save()
context.beginPath()
context.arc(randomX,randomY,30,0,Math.PI*2,false);
context.clip();
context.clearRect(0,0,canvas.width,canvas.height)
context.restore();
```

> 点击body的时候，设置定时器，让圆的半径每隔10毫秒增加5，当num半径大于677关闭定时器，677为canvas对角的长度


```js
document.body.onclick = function(){}
```



## 效果预览

![img](/img/canvas6.gif)