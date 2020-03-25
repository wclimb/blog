---
title: Vue源码之nextTick
date: 2020-03-25 17:49:01
tags:
- javascript
- vue
- 源码
- 原创
categories: [javascript, vue]
---

## 前言

今天我们开始讲一下 `Vue` 的 `nextTick` 方法的实现，无论是源码还是开发的过程中，经常需要使用到 `nextTick`，`Vue` 在更新 `DOM` 时是异步执行的，只要侦听到数据变化，`Vue` 将开启一个队列，并缓冲在同一事件循环中发生的所有数据变更。如果同一个 `watcher` 被多次触发，只会被推入到队列中一次。这种在缓冲时去除重复数据对于避免不必要的计算和 `DOM` 操作是非常重要的。然后，在下一个的事件循环 `“tick”` 中，`Vue` 刷新队列并执行实际 (已去重的) 工作。`Vue` 在内部对异步队列尝试使用原生的 `Promise.then`、`MutationObserver` 和 `setImmediate`，如果执行环境不支持，则会采用 `setTimeout(fn, 0)` 代替。

## 源码

https://github.com/wclimb/vue/blob/dev/src/core/util/next-tick.js
```js
export let isUsingMicroTask = false

// 储存回调
const callbacks = []
// 是否正在处理中
let pending = false
// 批量执行回调
function flushCallbacks () {
  // 恢复状态以便后续能正常使用
  pending = false
  const copies = callbacks.slice(0)
  // 执行之前先把回调清空，以便后续能正常调用
  callbacks.length = 0
  for (let i = 0; i < copies.length; i++) {
    copies[i]()
  }
}

let timerFunc
// 判断是否支持Promise，使用Promise的异步，属于微任务
if (typeof Promise !== 'undefined' && isNative(Promise)) {
  const p = Promise.resolve()
  timerFunc = () => {
    p.then(flushCallbacks)
    if (isIOS) setTimeout(noop)
  }
  isUsingMicroTask = true
  // 判断是否支持MutationObserver，属于微任务
} else if (!isIE && typeof MutationObserver !== 'undefined' && (
  isNative(MutationObserver) ||
  // iOS 7.x 平台处理的判断
  MutationObserver.toString() === '[object MutationObserverConstructor]'
)) {
  let counter = 1
  const observer = new MutationObserver(flushCallbacks)
  const textNode = document.createTextNode(String(counter))
  observer.observe(textNode, {
    characterData: true
  })
  timerFunc = () => {
    counter = (counter + 1) % 2
    textNode.data = String(counter)
  }
  isUsingMicroTask = true
  // 是否支持setImmediate，属于宏任务
} else if (typeof setImmediate !== 'undefined' && isNative(setImmediate)) {
  timerFunc = () => {
    setImmediate(flushCallbacks)
  }
} else {
  // 都不支持就直接使用宏任务 setTimeout
  timerFunc = () => {
    setTimeout(flushCallbacks, 0)
  }
}
// nextTick方法
export function nextTick (cb?: Function, ctx?: Object) {
  let _resolve
  // 收集回调函数
  callbacks.push(() => {
    if (cb) {
      try {
        cb.call(ctx)
      } catch (e) {
        handleError(e, ctx, 'nextTick')
      }
    } else if (_resolve) {
      // 如果没有传递回调函数会执行_resolve，执行的代码其实就是callback this.$nextTick().then(callback)
      _resolve(ctx)
    }
  })
  // 如果状态没有正在处理执行
  if (!pending) {
    // 置为处理中
    pending = true
    // 执行刚刚一系列判断下来获得的函数，最终会执行flushCallbacks方法
    timerFunc()
  }
  // 如果没有传递回调函数就会返回一个Promise，this.$nextTick().then(callback)，执行 _resolve(ctx) 之后会执行callback
  if (!cb && typeof Promise !== 'undefined') {
    return new Promise(resolve => {
      _resolve = resolve
    })
  }
}
```
我们可以看到 `Vue` 会借助 `timerFunc` 方法异步批量处理回调函数，`timerFunc` 可能是 `Promise.then`、`MutationObserver` 、 `setImmediate`、`setTimeout`。判断他们的支持程度，降级处理。
如果没有传递回调函数会返回一个Promise，并把 `resolve` 方法赋值给 `_resolve`，这样我们 `this.$nextTick().then(callback)`，`callback`就会被触发了。至于为什么要使用timerFunc这种方式，开头已经讲了，是因为Vue是异步更新队列，这样做的好处是去除重复数据对于避免不必要的计算和 `DOM` 操作，比如我们操作一个数据，并且重复多次给他赋不一样的值，`this.a = 1;this.a = 2; this.a = 3`，答案结果最后自然是3，但是 `Vue` 不会去更新三次 `DOM` 或者数据，这样会造成不必要的浪费，所以需要做异步处理去 `update` 他们，既然更新是异步的，我们如果想直接马上获取最新的数据自然是不行的，需要借助nextTick，在下一次事件循环中去获取，可以看下面👇的代码

## 实际代码

我们看下面的代码
```html
<div id="app" @click="fn">{{code}}</div>
```

```js
var vm = new Vue({
  el: '#app',
  data: {
    code: 0
  },
  methods:{
    fn(){
      this.code = 1
      console.log(this.$el.textConent); // 0
      this.$nextTick(()=>{
        console.log(this.$el.textConent) // 1
      })
    }
  }
})
```
你也可以这样

```diff
var vm = new Vue({
  el: '#app',
  data: {
    code: 0
  },
  methods:{
    async fn(){
      this.code = 1
      console.log(this.$el.textConent); // 0
-     this.$nextTick(()=>{
-       console.log(this.$el.textConent) // 1
-     })
+     await this.$nextTick()
+     console.log(this.$el.textConent) // 1
    }
  }
})
```

## 总结

今天带大家了解了一下 `nextTick` 的内部实现，虽然你也可以直接使用 `setTimeout` 去做，但是基于性能和执行顺序的问题(微任务执行快于宏任务)，推荐还是使用 `nextTick` 更好一点。


本文地址 [撸一个简易Virtual Dom](http://www.wclimb.site/2020/03/19/simple-virtual-dom/)