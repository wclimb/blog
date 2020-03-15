---
title: Vue源码之双向数据绑定
date: 2020-03-15 12:18:41
tags:
- javascript
- vue
- 源码
- 原创
categories: [javascript, vue]
---

## 前言

近一年多都在做小程序开发，`Vue` 感觉都有写些生疏了，从今天开始阅读一下 `Vue` 的源码，了解其内部的工作机制，本文涉及的 `Vue` 版本为 `2.6.11`，我已经提前 `fork` 了一份到 `github` 上

## 双向数据绑定

提到 `Vue`，自然会想到双向数据绑定，要说他的原理，你也能脱口而出，使用 `Object.defineProperty` 的 `get`、`set`来实现，但要把功能做更强大健壮，往往并不是这么简单

## 从入口开始

https://github.com/wclimb/vue/blob/dev/src/core/instance/init.js#L15
```js
export function initMixin (Vue: Class<Component>) {
  Vue.prototype._init = function (options?: Object) {
    ......

    // expose real self
    vm._self = vm
    initLifecycle(vm)
    initEvents(vm)
    initRender(vm)
    callHook(vm, 'beforeCreate')
    initInjections(vm) // resolve injections before data/props
    initState(vm)
    initProvide(vm) // resolve provide after data/props
    callHook(vm, 'created')

    ......

    if (vm.$options.el) {
      vm.$mount(vm.$options.el)
    }
  }
}
```
从上面可以看出初始化 `Vue` 会调用多个函数来做不同的事情，本文主要讲解双向数据绑定，所以其他的在这里都不重要，这里我们着重关注 `initState` 内部方法
<!-- more -->
### initState

https://github.com/wclimb/vue/blob/dev/src/core/instance/state.js#L42
```js
export function initState (vm: Component) {
  vm._watchers = []
  const opts = vm.$options
  // 如果存在props，初始化props
  if (opts.props) initProps(vm, opts.props)
  // 挂载定义的方法
  if (opts.methods) initMethods(vm, opts.methods)
  // 如果存在data，执行initData开始创建观察者
  if (opts.data) {
    initData(vm)
  } else {
    observe(vm._data = {}, true /* asRootData */)
  }
  // 以下同理，都是初始化定义的一些数据
  if (opts.computed) initComputed(vm, opts.computed)
  if (opts.watch) initWatch(vm, opts.watch)
}
```

### initData

https://github.com/wclimb/vue/blob/dev/src/core/instance/state.js#L102
```js
function initData (vm: Component) {
  ....
  // observe data
  observe(data, true /* asRootData */)
}
```

### observe

https://github.com/wclimb/vue/blob/dev/src/core/observer/index.js#L106
```js
export function observe (value: any, asRootData: ?boolean): Observer | void {
  if (!isObject(value) || value instanceof VNode) {
    return
  }
  let ob: Observer | void
  // 这里判断当前是否已经存在观察者，如果有就直接返回
  if (hasOwn(value, '__ob__') && value.__ob__ instanceof Observer) {
    ob = value.__ob__
  } else if (
    shouldObserve &&
    !isServerRendering() &&
    (Array.isArray(value) || isPlainObject(value)) &&
    Object.isExtensible(value) &&
    !value._isVue
  ) {
    // 这里是重点，创建一个观察者
    ob = new Observer(value)
  }
  if (asRootData && ob) {
    ob.vmCount++
  }
  return ob
}
```

### Observer 

```js
export class Observer {
  value: any;
  dep: Dep;
  vmCount: number; // number of vms that have this object as root $data

  constructor (value: any) {
    this.value = value
    this.dep = new Dep()
    this.vmCount = 0
    // def其实就是给当前对象定义一个key为__ob__，值为this
    def(value, '__ob__', this)
    // 判断当前值是否为数组，如果是数组需要单独处理
    // 因为我们知道vue主要原理是 Object.defineProperty，但是它监听不了数组的变化，所以3.0采用了proxy
    // 但是数组只能监听到部分方法的改动，感兴趣可以看 https://github.com/wclimb/vue/blob/dev/src/core/observer/array.js
    if (Array.isArray(value)) {
      if (hasProto) {
        protoAugment(value, arrayMethods)
      } else {
        copyAugment(value, arrayMethods, arrayKeys)
      }
      this.observeArray(value)
    } else {
      this.walk(value)
    }
  }

  // 除了数组，都会调用该方法来劫持数据
  walk (obj: Object) {
    const keys = Object.keys(obj)
    for (let i = 0; i < keys.length; i++) {
      defineReactive(obj, keys[i])
    }
  }

  /**
   * Observe a list of Array items.
   */
  observeArray (items: Array<any>) {
    for (let i = 0, l = items.length; i < l; i++) {
      observe(items[i])
    }
  }
}
```

### defineReactive

下面代码是双向数据绑定额核心

https://github.com/wclimb/vue/blob/dev/src/core/observer/index.js#L131
```js
export function defineReactive (
  obj: Object,
  key: string,
  val: any,
  customSetter?: ?Function,
  shallow?: boolean
) {
  // 创建dep，主要做依赖收集
  const dep = new Dep()

  const property = Object.getOwnPropertyDescriptor(obj, key)
  // 判断当前对象是否可定义，不能的话后面执行也没有意义了，所以直接return
  if (property && property.configurable === false) {
    return
  }

  // 是否有自定义get set
  const getter = property && property.get
  const setter = property && property.set
  // 取当前的值
  if ((!getter || setter) && arguments.length === 2) {
    val = obj[key]
  }
  // shallow为undfined，因为上一步没有传，只有定义$attrs和$listeners使用true
  // 继续调用observe(val)劫持
  let childOb = !shallow && observe(val)
  // 重头戏，调用Object.defineProperty
  Object.defineProperty(obj, key, {
    enumerable: true,
    configurable: true,
    get: function reactiveGetter () {
      const value = getter ? getter.call(obj) : val
      // 此时的Dep.target是一个Watcher类，Dep.target全局只有一个
      if (Dep.target) {
        // 订阅
        dep.depend()
        // 如果数据是对象，继续
        if (childOb) {
          childOb.dep.depend()
          if (Array.isArray(value)) {
            dependArray(value)
          }
        }
      }
      return value
    },
    set: function reactiveSetter (newVal) {
      const value = getter ? getter.call(obj) : val
      if (newVal === value || (newVal !== newVal && value !== value)) {
        return
      }

      ...... 

      if (setter) {
        setter.call(obj, newVal)
      } else {
        // 把值更新为最新的
        val = newVal
      }
      // 把新值变成响应式的对象
      childOb = !shallow && observe(newVal)
      // 数据发生变化之后通知
      dep.notify()
    }
  })
}
```

## Dep

` Dep` 在 `Vue` 里面也是关键的一环，它负责依赖收集，从上面 `defineReactive` 内部方法有看到实例化了一个 `dep`，然后有使用到`Dep.target`、`dep.depend()`、`dep.notify()`，那么我们来看看 `Dep` 的实现

```js
let uid = 0

/**
 * A dep is an observable that can have multiple
 * directives subscribing to it.
 */
export default class Dep {
  static target: ?Watcher;
  id: number;
  subs: Array<Watcher>;

  constructor () {
    this.id = uid++
    this.subs = []
  }
  addSub (sub: Watcher) {
    this.subs.push(sub)
  }
  removeSub (sub: Watcher) {
    remove(this.subs, sub)
  }
  // 收集依赖
  depend () {
    if (Dep.target) {
      // Dep.target是一个Watcher类，所以Dep.target.addDep调用的是Watcher类里面的方法
      Dep.target.addDep(this)
    }
  }
  notify () {
    // stabilize the subscriber list first
    const subs = this.subs.slice()
    for (let i = 0, l = subs.length; i < l; i++) {
      subs[i].update()
    }
  }
}
// the current target watcher being evaluated.
// this is globally unique because there could be only one
// watcher being evaluated at any time.
Dep.target = null
const targetStack = []

// 该方法会用在Watcher内部
export function pushTarget (_target: Watcher) {
  if (Dep.target) targetStack.push(Dep.target)
  Dep.target = _target
}
// 和上面方法一样，调用完pushTarget之后接着会调用popTarget，删除当前目标watcher
export function popTarget () {
  Dep.target = targetStack.pop()
}
```

为什么 `Dep.target` 会有值呢？因为实例化一个 `Watcher` 会调用 `pushTarget`，但是什么时候会实例化 `Watcher` 呢？1. 初始化 `initComputed`  2. 绑定 `$watch` 3. `mountComponent`。
实际上是来自 `mountComponent` 内部的实例化 `Watcher`，我们看看代码
https://github.com/wclimb/vue/blob/dev/src/core/instance/lifecycle.js#L137

## mountComponent
```js
export function mountComponent (
  vm: Component,
  el: ?Element,
  hydrating?: boolean
): Component {
  vm.$el = el
  if (!vm.$options.render) {
    .....
  }
  callHook(vm, 'beforeMount')

  let updateComponent
  /* istanbul ignore if */
  if (process.env.NODE_ENV !== 'production' && config.performance && mark) {
    updateComponent = () => {
     ......
    }
  } else {
    updateComponent = () => {
      vm._update(vm._render(), hydrating)
    }
  }

  // we set this to vm._watcher inside the watcher's constructor
  // since the watcher's initial patch may call $forceUpdate (e.g. inside child
  // component's mounted hook), which relies on vm._watcher being already defined
  new Watcher(vm, updateComponent, noop, {
    before () {
      if (vm._isMounted && !vm._isDestroyed) {
        callHook(vm, 'beforeUpdate')
      }
    }
  }, true /* isRenderWatcher */)
  hydrating = false

  // manually mounted instance, call mounted on self
  // mounted is called for render-created child components in its inserted hook
  if (vm.$vnode == null) {
    vm._isMounted = true
    callHook(vm, 'mounted')
  }
  return vm
}
```
上面代码很重要，主要是视图的初始化过程，我们还可以看到两个生命周期，`beforeMount`和`mounted`，实例化`Watcher`，传递了几个主要参数，分别是`vm`、`updateComponent`、和一个 `before` 方法，`vm` 就是当前 `Vue` 的`this`了，重点在 `updateComponent` 方法，内部是 `vm._update(vm._render(), hydrating)` ，既然是初始化渲染视图，那么它也没有调用呀，我们先说 `vm._render()`，它的作用是生成当前 `vnode`，也就是虚拟 `dom`，通过 `vm.__update` 来更新视图，这里其实就牵扯到了新旧虚拟 `dom` 的比较，也就是 `diff` 算法，我们知道现在是初始化，也就是说只有一个 `vnode`，直接渲染就可以了，关键是在这里它没有执行，所以接下来我们需要看看 `Watcher` 做了什么

## Wachter
https://github.com/wclimb/vue/blob/dev/src/core/observer/watcher.js#L22
```js
export default class Watcher {

  constructor (
    vm: Component,
    expOrFn: string | Function,
    cb: Function,
    options?: ?Object,
    isRenderWatcher?: boolean
  ) {
    this.vm = vm
    if (isRenderWatcher) {
      vm._watcher = this
    }
    vm._watchers.push(this)
    // options
    if (options) {
      this.deep = !!options.deep
      this.user = !!options.user
      this.lazy = !!options.lazy
      this.sync = !!options.sync
      this.before = options.before
    } else {
      this.deep = this.user = this.lazy = this.sync = false
    }
    this.cb = cb
    this.id = ++uid // uid for batching
    this.active = true
    this.dirty = this.lazy // for lazy watchers
    this.deps = []
    this.newDeps = []
    this.depIds = new Set()
    this.newDepIds = new Set()
    this.expression = process.env.NODE_ENV !== 'production'
      ? expOrFn.toString()
      : ''
    // parse expression for getter
    if (typeof expOrFn === 'function') {
      this.getter = expOrFn
    } else {
      this.getter = parsePath(expOrFn)
      if (!this.getter) {
        this.getter = noop
        ...
      }
    }
    this.value = this.lazy
      ? undefined
      : this.get()
  }
  get () {
    pushTarget(this)
    let value
    const vm = this.vm
    try {
      value = this.getter.call(vm, vm)
    } catch (e) {
      .....
    } finally {
      // "touch" every property so they are all tracked as
      // dependencies for deep watching
      if (this.deep) {
        traverse(value)
      }
      popTarget()
      this.cleanupDeps()
    }
    return value
  }

  addDep (dep: Dep) {
    const id = dep.id
    if (!this.newDepIds.has(id)) {
      this.newDepIds.add(id)
      this.newDeps.push(dep)
      if (!this.depIds.has(id)) {
        dep.addSub(this)
      }
    }
  }
  ....
```
我们上一步实例化了 `Wathcer`，传入了一些参数，`Watcher` 内部构造函数最后执行了 `this.get()`，也就是内部 `get` 方法，重点来了
```js
get () {
    pushTarget(this)
    let value
    const vm = this.vm
    try {
      value = this.getter.call(vm, vm)
    } catch (e) {
      .....
    } finally {
      // "touch" every property so they are all tracked as
      // dependencies for deep watching
      if (this.deep) {
        traverse(value)
      }
      popTarget()
      this.cleanupDeps()
    }
    return value
  }
```
首先它会调用之前的方法 `pushTarget` 来赋值 `Dep.target`，所以我们会知道 `Dep.target` 一定是一个`Watcher`，紧接着调用了`this.getter`，`getter`是什么？`getter`实际就是传进来的第二个参数`expOrFn`，是一个方法。之前我们说的 `mountComponent` 方法内部传入的 `updateComponent` 方法，会在这里被调用，达到初始化视图的作用。
继续往下看，我们可以看到 `addDep` 方法，是不是很眼熟，之前我们说了 `Vue` 劫持数据，在 `get` 内会收集依赖，调用 `dep.depend()` 方法，然后 `depend` 方法执行了 `Dep.target.addDep(this)`，接着会调用这里我们说的 `addDep` 方法，传入的 `this` 就是 `Dep`
```js
addDep (dep: Dep) {
  const id = dep.id
  if (!this.newDepIds.has(id)) {
    this.newDepIds.add(id)
    this.newDeps.push(dep)
    if (!this.depIds.has(id)) {
      dep.addSub(this)
    }
  }
}
```
首先判断是否已经存在 `dep`，没有就往调用 `dep` 的方法 `addSub` 追加当前的 `Watcher`，调用 `addSub` 会存在 `dep` 内的 `subs`，`subs`是一个数组，整个流程是不是很绕，我们可以画个图来看看

## 派发更新
我们收集了依赖有什么用呢？我们修改值之后需要更新视图和数据，这个动作我们是可以预知的，因为会触发之前的`setter`，`setter`内部调用了 `dep.notify()`，这个时候就可以通知所有订阅者更新视图
setter
```js
set: function reactiveSetter (newVal) {
  var value = getter ? getter.call(obj) : val;
  /* eslint-disable no-self-compare */
  if (newVal === value || (newVal !== newVal && value !== value)) {
    return
  }
  /* eslint-enable no-self-compare */
  if (customSetter) {
    customSetter();
  }
  // #7981: for accessor properties without setter
  if (getter && !setter) { return }
  if (setter) {
    setter.call(obj, newVal);
  } else {
    val = newVal;
  }
  childOb = !shallow && observe(newVal);
  dep.notify();
}
```
`dep.notify()`会调用 `dep` 的 `notify` 方法，我们知道 `subs` 内部都是 `Watcher` 类的数组，需要更新全部就得其遍历他们，执行 `Watcher` 内部的 `update` 方法
```js
export default class Dep {

  constructor () {
    this.id = uid++
    this.subs = []
  }

  ....

  notify () {
    // stabilize the subscriber list first
    const subs = this.subs.slice()
    if (process.env.NODE_ENV !== 'production' && !config.async) {
      // subs aren't sorted in scheduler if not running async
      // we need to sort them now to make sure they fire in correct
      // order
      subs.sort((a, b) => a.id - b.id)
    }
    for (let i = 0, l = subs.length; i < l; i++) {
      subs[i].update()
    }
  }
}
```

### update
https://github.com/wclimb/vue/blob/dev/src/core/observer/watcher.js#L153
```js
update () {
  /* istanbul ignore else */
  if (this.lazy) {
    this.dirty = true
  } else if (this.sync) {
    this.run()
  } else {
    queueWatcher(this)
  }
}
```
实际上大部分情况都会直接执行 `queueWatcher` 方法

https://github.com/wclimb/vue/blob/dev/src/core/observer/scheduler.js#L98

`queueWatcher`
```js
export function queueWatcher (watcher: Watcher) {
  const id = watcher.id
  if (has[id] == null) {
    has[id] = true
    if (!flushing) {
      queue.push(watcher)
    } else {
      // 如果已经刷新，则根据其ID拼接观察者
      // 如果已经超过其ID，它将立即运行
      let i = queue.length - 1
      while (i > index && queue[i].id > watcher.id) {
        i--
      }
      queue.splice(i + 1, 0, watcher)
    }
    // queue the flush
    if (!waiting) {
      waiting = true
      // 开发环境并且不是异步的就直接执行
      if (process.env.NODE_ENV !== 'production' && !config.async) {
        flushSchedulerQueue()
        return
      }
      // 这里其实就是执行了个异步操作，可以了解一些nextTick的实现
      // https://github.com/wclimb/vue/blob/dev/src/core/util/env.js#L51
      nextTick(flushSchedulerQueue)
    }
  }
}
```
https://github.com/wclimb/vue/blob/dev/src/core/observer/scheduler.js#L34

`flushSchedulerQueue`
```js
function flushSchedulerQueue () {
  currentFlushTimestamp = getNow()
  flushing = true
  let watcher, id

  //在刷新之前对队列进行排序。
  //这样可以确保：
  //1.组件从父级更新为子级。 （因为父母总是在子级之前创建）
  //2.组件的用户监视程序先于其呈现监视程序运行（因为用户观察者先于渲染观察者创建）
  //3.如果在父组件的观察者运行期间破坏了某个组件，可以跳过其观察者
  queue.sort((a, b) => a.id - b.id)

  // do not cache length because more watchers might be pushed
  // as we run existing watchers
  for (index = 0; index < queue.length; index++) {
    watcher = queue[index]
    // 调用之前执行一下before，目的是可以触发beforeUpdate生命周期
    if (watcher.before) {
      watcher.before()
    }
    id = watcher.id
    has[id] = null
    watcher.run()
    // in dev build, check and stop circular updates.
    if (process.env.NODE_ENV !== 'production' && has[id] != null) {
      circular[id] = (circular[id] || 0) + 1
      // 判断是否死循环了
      if (circular[id] > MAX_UPDATE_COUNT) {
        ....
        break
      }
    }
  }
  ....
}
```
上面代码主要是对 `queue` 内的数据根据 `watcher` 的 `id` 来排序，确保数据是从父级更新到子级，因为是有先后顺序的，先有父后有子。接着就是批量去更新他们，可以看到先执行了`before`方法，然后调用了 `watcher` 的 `run` 方法，我们来看看 `run` 方法的代码
`run`
```js
run () {
  if (this.active) {
    const value = this.get()
    if (
      value !== this.value ||
      // Deep watchers and watchers on Object/Arrays should fire even
      // when the value is the same, because the value may
      // have mutated.
      isObject(value) ||
      this.deep
    ) {
      // set new value
      const oldValue = this.value
      this.value = value
      if (this.user) {
        try {
          this.cb.call(this.vm, value, oldValue)
        } catch (e) {
          handleError(e, this.vm, `callback for watcher "${this.expression}"`)
        }
      } else {
        this.cb.call(this.vm, value, oldValue)
      }
    }
  }
}
```
我们主要关注`const value = this.get()`这段代码，其实`this.get`我们之前就说过了，初始化的时候它就会调用，实际上执行的是以下代码
```js
updateComponent = () => {
  vm._update(vm._render(), hydrating)
}
```
自此整个流程已经讲完，以上流程可以通过下面一张图来表达
![](/img/vue-data-bind-process.png)

## 总结

至此双向数据绑定的全部流程已经全部讲完，你会发现主要是通过`Observer`、`Dep`、`Watcher`来串起来整个流程，其中当然还有很多可以单独提取出来讲的，本文还会继续完善补充

本文地址 [Vue源码之双向数据绑定](http://www.wclimb.site/2020/03/15/vue-source-code-data-bind/)
