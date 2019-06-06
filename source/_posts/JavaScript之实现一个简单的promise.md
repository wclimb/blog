---
title: JavaScript之实现一个简单的promise
date: 2018-09-09 22:04:26
tags:
- javascript
- 原创
categories: [javascript,promise]
---


我们在开发过程中大多会用到`promise`，想必大家对`promise`的使用都很熟练了，今天我们就来实现一个简单的`promise`，实现的效果如有出入还往指正。


## 整体结构

我们先来梳理一下整体的结果，以便后续好操作

```js
class MyPromise {
    constructor(fn){
        
    }
    resolve(){

    }
    then(){

    }
    reject(){

    }
    catch(){

    }
}
```
<!-- more -->
## Promise理论知识

> 摘抄至 http://es6.ruanyifeng.com/#docs/promise#Promise-all

`Promise`对象有以下两个特点。

（1）对象的状态不受外界影响。Promise对象代表一个异步操作，有三种状态：pending（进行中）、fulfilled（已成功）和rejected（已失败）。只有异步操作的结果，可以决定当前是哪一种状态，任何其他操作都无法改变这个状态。这也是Promise这个名字的由来，它的英语意思就是“承诺”，表示其他手段无法改变。

（2）一旦状态改变，就不会再变，任何时候都可以得到这个结果。Promise对象的状态改变，只有两种可能：从pending变为fulfilled和从pending变为rejected。只要这两种情况发生，状态就凝固了，不会再变了，会一直保持这个结果，这时就称为 resolved（已定型）。如果改变已经发生了，你再对Promise对象添加回调函数，也会立即得到这个结果。这与事件（Event）完全不同，事件的特点是，如果你错过了它，再去监听，是得不到结果的。

总结一下就是promise有三种状态：pending（进行中）、fulfilled（已成功）和rejected（已失败），还有就是状态的改变只能是pending -> fulfilled 或者 pending -> rejected，这些很重要

## 实现构造函数

现在我们开始实现构造函数

```js
class MyPromise {
    constructor(fn){
        if(typeof fn !== 'function') {
            throw new TypeError(`MyPromise fn ${fn} is not a function`)
        }
        this.state = 'pending';
        this.value = void 0;
        fn(this.resolve.bind(this),this.reject.bind(this))
    }
    ...
}
```
构造函数接收一个参数`fn`，且这个参数必须是一个函数，因为我们一般这样使用`new Promise((resolve,reject)=>{})`;
然后初始化一下promise的状态，默认开始为pending，初始化value的值。
`fn`接收两个参数，`resolve`、`reject`

## resolve
```js
class MyPromise {
    constructor(fn){
        if(typeof fn !== 'function') {
            throw new TypeError(`MyPromise fn ${fn} is not a function`)
        }
        this.state = 'pending';
        this.value = void 0;
        fn(this.resolve.bind(this),this.reject.bind(this))
    }
    resolve(value){
        if(this.state !== 'pending') return;
        this.state = 'fulfilled';
        this.value = value
    }
    ...
}
```
当`resolve`执行，接收到一个值之后；状态就由 `pending` -> `fulfilled`；当前的值为接收的值

## reject
```js
class MyPromise {
    constructor(fn){
        if(typeof fn !== 'function') {
            throw new TypeError(`MyPromise fn ${fn} is not a function`)
        }
        this.state = 'pending';
        this.value = void 0;
        fn(this.resolve.bind(this),this.reject.bind(this))
    }
    resolve(value){
        if(this.state !== 'pending') return;
        this.state = 'fulfilled';
        this.value = value
    }
    reject(reason){
        if(this.state !== 'pending') return;
        this.state = 'rejected';
        this.value = reason
    }
}
```
当`reject`执行，接收到一个值之后；状态就由 `pending` -> `rejected`；当前的值为接收的值

## then

```js
class MyPromise {
    constructor(fn){
        if(typeof fn !== 'function') {
            throw new TypeError(`MyPromise fn ${fn} is not a function`)
        }
        this.state = 'pending';
        this.value = void 0;
        fn(this.resolve.bind(this),this.reject.bind(this))
    }
    resolve(value){
        if(this.state !== 'pending') return;
        this.state = 'fulfilled';
        this.value = value
    }
    reject(reason){
        if(this.state !== 'pending') return;
        this.state = 'rejected';
        this.value = reason
    }
    then(fulfilled,rejected){
        if (typeof fulfilled !== 'function' && typeof rejected !== 'function' ) {
            return this;
        }
        if (typeof fulfilled !== 'function' && this.state === 'fulfilled' ||
            typeof rejected !== 'function' && this.state === 'rejected') {
            return this;
        }
        return new MyPromise((resolve,reject)=>{
            if(fulfilled && typeof fulfilled === 'function' && this.state === 'fulfilled'){
                let result = fulfilled(this.value);
                if(result && typeof result.then === 'function'){
                    return result.then(resolve,reject)
                }else{
                    resolve(result)
                }
            }
            if(rejected && typeof rejected === 'function' && this.state === 'rejected'){
                let result = rejected(this.value);
                if(result && typeof result.then === 'function'){
                    return result.then(resolve,reject)
                }else{
                    resolve(result)
                }
            }
        })
    }
}
```
`then`的实现比较关键，首先有两个判断，第一个判断传的两个参数是否都是函数，如果部不是`return this`执行下一步操作。
第二个判断的作用是，比如，现在状态从`pending` -> `rejected`;但是中间代码中有许多个`.then`的操作，我们需要跳过这些操作执行`.catch`的代码。如下面的代码，执行结果只会打印`1`
```
new Promise((resolve,reject)=>{
    reject(1)
}).then(()=>{
    console.log(2)
}).then(()=>{
    console.log(3)
}).catch((e)=>{
    console.log(e)
})
```
我们继续，接下来看到的是返回了一个新的`promise`，真正`then`的实现的确都是返回一个`promise`实例。这里不多说

下面有两个判断，作用是判断是`rejected`还是`fulfilled`,首先看`fulfilled`，如果是`fulfilled`的话，首先执行`fulfilled`函数，并把当前的`value`值传过去，也就是下面这步操作,`res`就是传过去的`value`值，并执行了`(res)=>{console.log(res)}`这段代码;执行完成之后我们得到了`result`；也就是`2`这个结果，下面就是判断当前结果是否是一个`promise`实例了，也就是下面注释了的情况，现在我们直接执行`resolve(result)`;
```
new Promise((resolve,reject)=>{
    resolve(1)
}).then((res)=>{
    console.log(res)
    return 2
    //return new Promise(resolve=>{})
})
```
剩下的就不多说了，可以`debugger`看看执行结果

## catch
```js
class MyPromise {
    ...
    catch(rejected){
        return this.then(null,rejected)
    }
}
```

## 完整代码

```js
class MyPromise {
    constructor(fn){
        if(typeof fn !== 'function') {
            throw new TypeError(`MyPromise fn ${fn} is not a function`)
        }
        this.state = 'pending';
        this.value = void 0;
        fn(this.resolve.bind(this),this.reject.bind(this))
    }
    resolve(value){
        if(this.state !== 'pending') return;
        this.state = 'fulfilled';
        this.value = value
    }
    reject(reason){
        if(this.state !== 'pending') return;
        this.state = 'rejected';
        this.value = reason
    }
    then(fulfilled,rejected){
        if (typeof fulfilled !== 'function' && typeof rejected !== 'function' ) {
            return this;
        }
        if (typeof fulfilled !== 'function' && this.state === 'fulfilled' ||
            typeof rejected !== 'function' && this.state === 'rejected') {
            return this;
        }
        return new MyPromise((resolve,reject)=>{
            if(fulfilled && typeof fulfilled === 'function' && this.state === 'fulfilled'){
                let result = fulfilled(this.value);
                if(result && typeof result.then === 'function'){
                    return result.then(resolve,reject)
                }else{
                    resolve(result)
                }
            }
            if(rejected && typeof rejected === 'function' && this.state === 'rejected'){
                let result = rejected(this.value);
                if(result && typeof result.then === 'function'){
                    return result.then(resolve,reject)
                }else{
                    resolve(result)
                }
            }
        })
    }
    catch(rejected){
        return this.then(null,rejected)
    }
}
```

## 测试

```js
new MyPromise((resolve,reject)=>{
	console.log(1);
	//reject(2)
	resolve(2)
	console.log(3)
	setTimeout(()=>{console.log(4)},0)
}).then(res=>{
	console.log(res)
	return new MyPromise((resolve,reject)=>{
		resolve(5)
	}).then(res=>{
		return res
	})
}).then(res=>{
	console.log(res)
}).catch(e=>{
	console.log('e',e)
})
执行结果：
> 1
> 3
> 2
> 5
> 4
```

原生promise
```js
new Promise((resolve,reject)=>{
	console.log(1);
	//reject(2)
	resolve(2)
	console.log(3)
	setTimeout(()=>{console.log(4)},0)
}).then(res=>{
	console.log(res)
	return new Promise((resolve,reject)=>{
		resolve(5)
	}).then(res=>{
		return res
	})
}).then(res=>{
	console.log(res)
}).catch(e=>{
	console.log('e',e)
})
执行结果：
> 1
> 3
> 2
> 5
> 4
```