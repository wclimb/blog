---
title: JavaScript之原型与原型链
date: 2018-06-13 11:39:41
tags:
- javascript
- 原创
categories: [javascript]
---

# 万物皆对象

在JavaScript中除值类型之外，其他的都是对象，为了说明这点，我们举几个例子
我们可以使用`typeof`来做类型判断

```js
typeof a;             // undefined
typeof 1;             // number
typeof 'wclimb';      // string
typeof true;          // boolean

typeof function(){};  // function
typeof [];            // object
typeof null;          // object
typeof {};            // object
```
除了`undefined`、`number`、`string`、`boolean`属于值类型之外，其他都是对象。你可能要问了，不是还有一个是`function`吗？要校验他是不是应该对象可以这样做:
```js
var fn = function(){}
fn instanceof Object // true
```
由上面的例子所示，函数确实是对象，为什么呢？我们看一下下面的例子
```js
function Person(name){
    this.name = name; 
}
var person = new Person('wclimb');
console.log(person) // Person {name: "wclimb"}
```
由此我们可以得知，对象都是通过函数创建的，这么说你可能又会说不对，你看下面的就不是函数创建的
<!-- more -->
```js
var person = {name:'wclimb'}
```
你咋就这么飘呢？我竟无言以对，没错，这是个意外、意外、意外。但是归根结底他还是通过函数创建的
```js
    var person = new Object()
    person.name = 'wclimb'
```
so，现在你只要知道对象是通过函数创建的就可以了，来跟着我读：
第一遍 对象都是通过函数创建的
第二遍 对象都是通过函数创建的
第三遍 对象都是通过函数创建的

# 构造函数(constructor)

```js
function Person(name){
    this.name = name
}
var person1 = new Person('wclimb 1')
var person2 = new Person('wclimb 2')
```
上面`Person`就是一个构造函数，我们通过`new`的方式创建了一个实例对象`person`
我们来看看person1和person2的`constructor`(构造函数)是不是指向Person的
```js
person1.constructor === Person // true
person2.constructor === Person // true
```
# 原型(prototype)

在JavaScript中，每定义一个函数都会产生一个`prototype`(原型)属性，这个属性指向函数的原型对象
```js
function Person(){}
Person.prototype.name = 'wclimb'
Person.prototype.age = '24'
Person.prototype.sayAge = function(){
    console.log(this.age)
}
var person = new Person()
person.sayAge(); //  24
```
那么这个`prototype`到底是什么呢？跟构造函数有关系吗？

![](/img/prototype.png)

上图就可以反映出他们之间的关系

其实函数的`prototype`指向函数的原型对象，每个对象都会关联另外一个对象，也就是原型，上面的例子改成：
```js
Person.prototype = {
    name: 'wclimb',
    age: 24,
    satAge: function(){
        console.log(this.age)
    }
}
```
# 隐式原型(`__proto__`)

上面我们说到每定义一个函数都会产生一个原型，每个函数它不止有原型，还有一个`__proto__`(隐式原型)
每个对象都有一个`__proto__`属性，指向创建该对象函数的`prototype`，我们可以来试试，还是上面的例子：
```js
function Person(){}
var person = new Person()
person.__proto__ === Person.prototype // true
```
现在他们的关系图如下

![](/img/proto.png)

由上图我们可以知道：
```js
Person.prototype.constructor = Person
person.__proto__ = Person.prototype
person.constructor = Person
```
我们可以看到`person.__proto__`指向构造函数的原型，那么构造函数的原型即`Person`的`__proto__`指向哪里呢？
我们知道构造函数其实就是由`Function`来创建的，由此得出:
```js
Person.__proto__ === Function.prototype
```
那么构造函数的原型即`Person.prototype`的`__proto__`指向哪里呢？
原型对象其实是通过`Object`生成的，自然而然的得出:
```js
Person.prototype.__proto__ === Object.prototype
```

那么`Object.prototype`的`__proto__`指向哪里呢？答案是`null`，最终得到下面的图

![](/img/allProto.png)


抛开这张图，来看看下面几道题

1. `person.__proto__`
2. `Person.__proto__`
3. `Person.prototype.__proto__`
4. `Object.__proto__`
5. `Object.prototype.__proto__`

解：
1. 每个对象都有一个`__proto__`属性，指向创建该对象函数的`prototype`，因为Person是person的构造函数
`Person === person.constructor`为`true`,所以：`person.__proto__ === Person.prototype`
2. `Person`构造函数是由`Function`创建的，所以可以得出`Person.__proto__ === Fucntion.prototype`
3. 我们上面说过`Person.prototype`其实是一个对象，而对象是由`Object`创建的，所以 `Person.prototype.__proto__ === Object.prototype`
4. `Object`对象都是函数创建的，所以`Object.__proto__ === Function.prototype`
5. 虽然`Object.prototype`是一个对象但是他的`__proto__`为`null`


# 实例和原型

当我们要取一个值的时候，会先从实例中取，如果实例中存在，则取实例的值，如果实例不存在，则会顺着原型里找，直到找到

```js
function Person(){}
Person.prototype.name = '我来自原型'

var person = new Person()
person.name = '我来自实例'
console.log(person.name); // 我来自实例
delete person.name
console.log(person.name)); // 我来自原型
```
首先person实例中有这个属性，返回`我来自实例`,然后将它删除之后，会从原型中招，也就是`person.__proto__`，因为`Person.prototype === person.__proto__`，所以得到`我来自原型`


# 总结

原型和原型链基本已经讲解完，不过还有待完善，如有错误，还望指正

GitHub：[wclimb](https://github.com/wclimb)

# 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)


# QQ群

有兴趣的同学可以加qq群: 725165362 [点击加入](http://shang.qq.com/wpa/qunwpa?idkey=e6c66b1ee584a90b52dec3545622e988afcf900144eff03cab6d473c50a31d59)

