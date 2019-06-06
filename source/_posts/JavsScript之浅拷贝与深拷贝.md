---
title: JavsScript之浅拷贝与深拷贝
date: 2018-07-29 16:04:57
tags:
- javascript
- 原创
categories: [javascript]

---
在开发的过程中，我们往往需要复制一个数据，在复制基本数据类型的时候不会出现问题，如`string`、`number`、`null`等。
但是我们复制一个引用类型的数据时，往往会出现问题，如`array`、`object`。


## 浅拷贝

看下面这段代码
```js
var arr1 = [1,2,3];
var arr2 = arr1;
arr2.push(4)
```
我们打印一下看看`arr1` `arr2`的结果
```js
arr1: [1, 2, 3, 4]
arr2: [1, 2, 3, 4]
```
我们发现，改变`arr2`的同时也改变了`arr1`，WTF？

接下来我们看看对象
```js
var obj1 = {
        name:'wclimb'
    };
var obj2 = obj1
obj2.age = 24
```
<!-- more -->
我们打印一下看看`arr1``arr2`的结果
```js
obj1: {name: "wclimb", age: 24}
obj2: {name: "wclimb", age: 24}
```
和预想的一样，都被影响了。
why?
因为引用类型的复制，两个引用类型的指针都指向同一个堆内存

网上偶尔会看到有人说`slice`、`concat`是深拷贝，其实这两个是浅复制，如下
```js
var arr1 = [1,2,3];
var arr2 = arr1.slice();
arr2.push(4)
```
结果：
```js
arr1 [1, 2, 3]
arr2 [1, 2, 3, 4]
```
数组元素只是基本数据类型不会有影响，那么我们看下面的
```js
var arr1 = [1,2,3,[4]];
var arr2 = arr1.slice();
arr2[3].push(5)
```
结果
```js
arr1: [1,2,3,[4,5]]   <-----  被影响了
arr2: [1,2,3,[4,5]]
```
即使使用了`slice`, 两个数组也相互影响了，类似方法除了`slice`、`concat`还有`Array.from`、`...`

**深拷贝和浅拷贝最根本的区别在于是否是真正获取了一个对象的拷贝实体，而不是引用**

## 深拷贝

### Object.assign

Object.assign可以进行一层的深度拷贝，也就是跟slice类型的效果
```js
var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
		test4: {}
    };
var obj2 = Object.assign({}, obj1)
obj2.age = 24

结果：
obj1: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
obj2: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {},
        age: 24
    };
```
但是我们看下面的例子
```js
var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
var obj2 = Object.assign({}, obj1)
obj2.age = 24
obj2.test4.val = '1';

结果： 

obj1: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {val: 1}   <-----  被影响了
    };
obj2: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {val: 1},
        age: 24
    };
```

### JSON.parse(JSON.stringify(obj))

说到深拷贝，你一定会想到`JSON.parse(JSON.stringify(obj))`;
没错，这样可以完成一个深拷贝，看下面的例子：

```js
var obj1 = {
        name: 'wclimb'
    };
var obj2 = JSON.parse(JSON.stringify(obj1))
obj2.age = 24
```
结果
```js
obj1: {name: "wclimb"}   <-----  没有被影响了
obj2: {name: "wclimb", age: 24}
```
perfect，但是这个方法会有一个问题，如下例：
```js
var var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
var obj2 = JSON.parse(JSON.stringify(obj1))
obj2.age = 24
```
结果
```js
obj1: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
obj2: {
        name: "wclimb",
        age: 24, 
        test1: null,
        test4: {}
    }
```
WTF，那两个个跑哪去了？所以这个方法不能够拷贝值为`undefined`、`function`

### 深拷贝实现
那么怎么进行深拷贝呢？我的方法是：
```js
function deepCopy(obj){
    var result;
    var toString = Object.prototype.toString
    if(toString.call(obj) === '[object Array]'){
        result = []
        for(var i = 0 ;i < obj.length; i++){
            result[i] = deepCopy(obj[i])
        }
    }else if(toString.call(obj) === '[object Object]'){
        result = {};
        for (var key in obj) {
            if (obj.hasOwnProperty(key)) {
                result[key] = deepCopy(obj[key])
            }
        }
    }else{
        return obj
    }
    return result
}


测试一下：

var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
var obj2 = deepCopy(obj1)
obj2.age = 24
obj2.test4.val = '1';

返回： 

obj1: {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}   <-----  没有被影响了
    };
obj2: {
        age: 24,
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {val: '1'}
    };
```

### jQuery的实现

```js
var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
var obj2 = $.extend(true, {}, obj1)
obj2.age = 24
```
### lodash的实现

```js
var obj1 = {
        name: 'wclimb',
        test1: null,
        test2: undefined,
        test3: function(){alert(1)},
        test4: {}
    };
var obj2 = _.cloneDeep(obj1)
obj2.age = 24
```

GitHub：[wclimb](https://github.com/wclimb)

## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)