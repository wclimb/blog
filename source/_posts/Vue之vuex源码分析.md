---
title: Vue之vuex源码分析
date: 2019-10-14 09:27:53
tags:
- javascript
- vue
- 源码
- 原创
categories: [javascript,vue]
---


## vuex使用

```js
import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);
const state = {
  test: 1
}
const actions = {
  changeTest({ commit }, payload){
    commit('setTestValue', payload)
  }
}
const mutations = {
  setTestValue(state, payload){
    state.test = payload
  }
}
export default new Vuex.Store({
  state,
  actions,
  mutations,
})
```

```js
import Vue from 'vue';
import store from './store';

new Vue({
  el: '#app',
  store,
  template: '<App/>',
  components: { App }
});
```
首先我们先注册`vuex`，然后设置一些`state/mutation/actions` 实例化出来，最后交给 `Vue` 处理
<!-- more -->


对 `API` 不熟悉的同学可以移步 [vuex](https://vuex.vuejs.org/zh/)


## 注册

用法我们知道了，那么问题来了，`Vuex`是怎样把store注入到Vue实例中去的呢？

我们知道使用插件一般都需要`vue.use()`，传入的参数内部必须要提供一个`install`的方法，上面我们使用`vue.use(vuex)`去安装，那么vuex内部肯定是暴露了应该`install`的方法得

vuex install的实现

vuex/index.js  [源码地址](https://github.com/vuejs/vuex/blob/665455f8da/src/index.js)
```js
import { Store, install } from './store'
import { mapState, mapMutations, mapGetters, mapActions, createNamespacedHelpers } from './helpers'

export default {
  Store,
  install,
  version: '__VERSION__',
  mapState,
  mapMutations,
  mapGetters,
  mapActions,
  createNamespacedHelpers
}
```
install方法
```js
export function install (_Vue) {
  // 首先判断vuex是否已经注册过了
  if (Vue && _Vue === Vue) {
    if (process.env.NODE_ENV !== 'production') {
      console.error(
        '[vuex] already installed. Vue.use(Vuex) should be called only once.'
      )
    }
    return
  }
  Vue = _Vue
  // 调用全局混入方法
  applyMixin(Vue)
}
```
首先判断`vuex`是否被重复安装，安装完成之后调用`applyMixin`方法，内部方法见下文

`applyMixin` [源码地址](https://github.com/vuejs/vuex/blob/665455f8da/src/mixin.js)
```js
export default function (Vue) {
  const version = Number(Vue.version.split('.')[0])
  // 如果vue版本大于2 则调用全局混淆方法，混淆进beforeCreate钩子
  if (version >= 2) {
    Vue.mixin({ beforeCreate: vuexInit })
  } else {
    // 如果vue小于2版本，把vuexInit放入Vue的_init方法中执行
    const _init = Vue.prototype._init
    Vue.prototype._init = function (options = {}) {
      options.init = options.init
        ? [vuexInit].concat(options.init)
        : vuexInit
      _init.call(this, options)
    }
  }

  // Vuex的init钩子，会存入每一个Vue实例等钩子列表
  function vuexInit () {
    const options = this.$options
    // store injection
    if (options.store) {
      this.$store = typeof options.store === 'function'
        ? options.store()
        : options.store
    } else if (options.parent && options.parent.$store) {
      this.$store = options.parent.$store
    }
  }
}
```
首先判断当前`Vue`的版本选择执行，大于`2.0`的版本直接把`vuexInit`混淆进`beforeCreate`，否则把`vuexInit`放入`Vue`的`_init`方法中执行。
`vuexInit`会先从`options`中取`store`，如果当前组件为跟组件，那么`options.store`肯定会存在，把`store`挂载在`vue`的`$store`内，如果是非根组件，则获取`options`的`parent`，也就是父组件的`$store`，这样就实现了，所有的组件都获取到同一份地址的`Store`，那么现在我们来看看`Store`的实现

## Store构造函数

```js
export class Store {
  constructor (options = {}) {
    // 首先先安装Vue
    if (!Vue && typeof window !== 'undefined' && window.Vue) {
      install(window.Vue)
    }
    
    if (process.env.NODE_ENV !== 'production') {
      // 判断vue是否安装
      assert(Vue, `must call Vue.use(Vuex) before creating a store instance.`)
      // promise是否支持
      assert(typeof Promise !== 'undefined', `vuex requires a Promise polyfill in this browser.`)
      // 判断this是否是Store的实例
      assert(this instanceof Store, `store must be called with the new operator.`)
    }

    // 一般options传入的是
    /**
     * {
     *  state,
     *  mutations,
     *  actions,
     *  modules
     * }
     **/
    const {
      // store 上的插件方法
      plugins = [],
      // 标记是否是严格模式，如果是严格模式，不允许直接修改state，一定要通过mutations
      strict = false
    } = options

    // store internal state
    // 用来判断是否是mutations来修改的state
    this._committing = false
    // 存放action
    this._actions = Object.create(null)
    this._actionSubscribers = []
    // 存放mutations
    this._mutations = Object.create(null)
    // 存放getter
    this._wrappedGetters = Object.create(null)
    // 存放module
    this._modules = new ModuleCollection(options)
    // 跟进命名空间存放module
    this._modulesNamespaceMap = Object.create(null)
    // 存放订阅者
    this._subscribers = []
    // 实现Vue的watch
    this._watcherVM = new Vue()

    // bind commit and dispatch to self
    const store = this
    const { dispatch, commit } = this
    // 把dispatch的this绑定到Store
    this.dispatch = function boundDispatch (type, payload) {
      return dispatch.call(store, type, payload)
    }
    // 把commit的this绑定到Store
    this.commit = function boundCommit (type, payload, options) {
      return commit.call(store, type, payload, options)
    }

    // strict mode
    // 是否为严格模式
    this.strict = strict

    // 获取根模块的state
    const state = this._modules.root.state

    // init root module.
    // this also recursively registers all sub-modules
    // and collects all module getters inside this._wrappedGetters
    // 递归地注册传入的module
    installModule(this, state, [], this._modules.root)

    // initialize the store vm, which is responsible for the reactivity
    // (also registers _wrappedGetters as computed properties)
    // 通过vm重新设置store，等会看它的内部实现，原理是借助Vue的响应式来注册state和getter
    resetStoreVM(this, state)

    // apply plugins
    // 调用插件
    plugins.forEach(plugin => plugin(this))

    // devtool插件调用
    const useDevtools = options.devtools !== undefined ? options.devtools : Vue.config.devtools
    if (useDevtools) {
      devtoolPlugin(this)
    }
  }
}
```

## dispatch（action）

我们知道如果我们需要改变`state`，需要先调用`this.$store.dispatch()`，来触发`action`，然后再调用`commit`来触发`mutation`，最终更改`state`，那么`dispatch`是怎么实现的呢？

```js
dispatch (_type, _payload) {
  // check object-style dispatch
  // 校验参数
  const {
    type,
    payload
  } = unifyObjectStyle(_type, _payload)

  const action = { type, payload }
  // 获取当前需要触发action的函数集合，注意，这里entry是一个数组集合，一般来说是只会存在一个方法，type: function，至于为什么后面讲到
  const entry = this._actions[type]
  if (!entry) {
    if (process.env.NODE_ENV !== 'production') {
      console.error(`[vuex] unknown action type: ${type}`)
    }
    return
  }

  try {
    // action 执行前，先调用订阅 action 变化的回调函数
    this._actionSubscribers
      .filter(sub => sub.before)
      .forEach(sub => sub.before(action, this.state))
  } catch (e) {
    if (process.env.NODE_ENV !== 'production') {
      console.warn(`[vuex] error in before action subscribers: `)
      console.error(e)
    }
  }
  // 如果集合大于1则调用Promise.all，全部resolve之后得到result，也是个promise对象，最后直接执行.then()方法返回执行的结果res
  const result = entry.length > 1
    ? Promise.all(entry.map(handler => handler(payload)))
    : entry[0](payload)

  return result.then(res => {
    try {
      // action 执行后，先调用订阅 action 变化的回调函数
      this._actionSubscribers
        .filter(sub => sub.after)
        .forEach(sub => sub.after(action, this.state))
    } catch (e) {
      if (process.env.NODE_ENV !== 'production') {
        console.warn(`[vuex] error in after action subscribers: `)
        console.error(e)
      }
    }
    return res
  })
}
```
上面代码可以看到我们使用`Promise.all`来执行`entry`，执行每个`handle`函数，全部执行完成后再`.then()`返回结果。那么这个`handle`是什么呢？

### installModule

`installModule`内安装`action`
```js
function installModule (store, rootState, path, module, hot) {

  ...

  module.forEachAction((action, key) => {
    const type = action.root ? key : namespace + key
    const handler = action.handler || action
    registerAction(store, type, handler, local)
  })

  ...

}

```
### registerAction

在`Store`构造函数内执行安装模块，内部会循环注册传入的`action`，调用`registerAction`方法

```js
function registerAction (store, type, handler, local) {
  // 首先获取当前需要传入的action名字，如果没有则赋值为一个空对象，如果找到赋值给entry
  const entry = store._actions[type] || (store._actions[type] = [])
  // 往entry增加一个方法，也就是上面dispatch执行的handle
  // handle的this指向store，传入三个参数，{dispatch,commit...} (触发mutation需要使用，大部分只需要用到commit)，payload(外部传递进来的参数) cb（回调函数）
  entry.push(function wrappedActionHandler (payload, cb) {
    let res = handler.call(store, {
      dispatch: local.dispatch,
      commit: local.commit,
      getters: local.getters,
      state: local.state,
      rootGetters: store.getters,
      rootState: store.state
    }, payload, cb)
    // 如果不是个promise，用promise包装一下返回
    if (!isPromise(res)) {
      res = Promise.resolve(res)
    }
    // devtool插件相关
    if (store._devtoolHook) {
      return res.catch(err => {
        store._devtoolHook.emit('vuex:error', err)
        throw err
      })
    } else {
      return res
    }
  })
}
```

我们一般是这么使用`dispath`的，👇
```js
this.$store.dispatch('actionName',{
  test: 123
}).then((res=>{
  ...
}))
```
再来想想`dispatch`的执行机制，是不是变得很清晰了？首先调用`dispatch`方法，获取需要调用的`action`，也是就`actionName`，然后把`payload`传入，也就是`{test:1}`，然后完成之后调用`.then()`异步执行所需操作


## commit （mutation）

先来看看实际应用是这么触发`commit`的
```js
const actions = {
  changeTest({ commit }, payload){
    commit('setTestValue', payload)
  }
}
const mutations = {
  setTestValue(state, payload){
    state.test = payload
  }
}
```
在触发`action`的时候，调用`commit`，至于为什么会有`commit`方法，是因为上面`registerAction` push的方法第一个传输传入了一个对象`{dispatch,commit...}`，然后把`dispatch`传入的`payload`再代入`commit`方法捏

```js
commit (_type, _payload, _options) {
  // check object-style commit
  // 校验参数
  const {
    type,
    payload,
    options
  } = unifyObjectStyle(_type, _payload, _options)

  const mutation = { type, payload }
  // 获取当前对应的mutation方法集合
  const entry = this._mutations[type]
  if (!entry) {
    if (process.env.NODE_ENV !== 'production') {
      console.error(`[vuex] unknown mutation type: ${type}`)
    }
    return
  }
  // 遍历调用集合内的方法，最后把payload参数传入集合的方法，等会介绍handle函数
  // _withCommit方法是判断当前操作是否是通过commit提交来修改state的
  this._withCommit(() => {
    entry.forEach(function commitIterator (handler) {
      handler(payload)
    })
  })
  // 通知所有订阅者
  this._subscribers.forEach(sub => sub(mutation, this.state))

  if (
    process.env.NODE_ENV !== 'production' &&
    options && options.silent
  ) {
    console.warn(
      `[vuex] mutation type: ${type}. Silent option has been removed. ` +
      'Use the filter functionality in the vue-devtools'
    )
  }
}
``` 
### installModule

```js
function installModule (store, rootState, path, module, hot) {

  ...

  module.forEachMutation((mutation, key) => {
    const namespacedType = namespace + key
    registerMutation(store, namespacedType, mutation, local)
  })

  ...
}

```
和`action`同理，注册所有的`mutation`，调用`registerMutation`方法

### registerMutation

```js
function registerMutation (store, type, handler, local) {
  const entry = store._mutations[type] || (store._mutations[type] = [])
  entry.push(function wrappedMutationHandler (payload) {
    handler.call(store, local.state, payload)
  })
}
```
`registerMutation`方法比较简单，直接把`state`、`payload`传入`handler`函数


再来看看实际使用
```js
const actions = {
  changeTest({ commit }, payload){
    commit('setTestValue', payload)
  }
}
const mutations = {
  setTestValue(state, payload){
    state.test = payload
  }
}
```
`commit`调用之后，获取到对应需要触发的`mutation`，也就是`setTestValue`，然后实际执行的是`registerMutation`处理赋值给 `store._mutations['setTestValue]`的方法集合，也就是`entry`，内部会传入两个参数，`state`、`payload`,这就是我们可以直接使用 `state.test = payload` 的原因

## mapState/mapAction/mapGetter等工具函数

开发中我们经常会使用到`mapState`来获取数据
[工具函数源码地址](https://github.com/vuejs/vuex/blob/665455f8da/src/helpers.js)

### mapState

先来看看我们在实际项目怎么使用
```js
// 在单独构建的版本中辅助函数为 Vuex.mapState
import { mapState } from 'vuex'

export default {
  // ...
  computed: mapState({
    // 箭头函数可使代码更简练
    count: state => state.count,

    // 传字符串参数 'count' 等同于 `state => state.count`
    countAlias: 'count',

    // 为了能够使用 `this` 获取局部状态，必须使用常规函数
    countPlusLocalState (state) {
      return state.count + this.localCount
    }
  })
  // 或者带命名空间的使用，这就是下面normalizeNamespace得作用
  computed: {
  ...mapState('some/nested/module', {
    a: state => state.a, // 如果不使用则需要通过 state.some.nested.module.a
    b: state => state.b
  })
},
}
```
 [mapState 源码地址](https://github.com/vuejs/vuex/blob/665455f8da/src/helpers.js#L7)
```js
// 首先是判断是否使用了命名空间，如果没有的话namespace会被赋值为空，normalizeNamespace实现见代码底部
export const mapState = normalizeNamespace((namespace, states) => {
  const res = {}
  // 先把传入的states转换一下，转换例子如下，转换成数组对象的形式，都有key和val
  normalizeMap(states).forEach(({ key, val }) => {
    res[key] = function mappedState () {
      // 获取state
      let state = this.$store.state
      let getters = this.$store.getters
      // 如果有命名则解析完成之后重新赋值state和getter
      if (namespace) {
        // 通过模块来解析访问路径 some/nested/module =>  store._modulesNamespaceMap['some/nested/module/] = { // 当前模块 }
        // 关于如何实现的，源码地址 https://github.com/vuejs/vuex/blob/665455f8da/src/store.js#L301
        const module = getModuleByNamespace(this.$store, 'mapState', namespace)
        if (!module) {
          return
        }
        state = module.context.state
        getters = module.context.getters
      }
      // 如果传入的函数，则把state和getter传入到函数内
      // 否则如果传入的是字符串，则直接取出返回数据，也就是上面使用 countAlias: 'count',
      return typeof val === 'function'
        ? val.call(this, state, getters)
        : state[val]
    }
    // mark vuex getter for devtools
    res[key].vuex = true
  })
  // 最终把处理好的对象返回处理，所以可知mapState返回的是一个对象
  return res
})

/**
 * Normalize the map
 * normalizeMap([1, 2, 3]) => [ { key: 1, val: 1 }, { key: 2, val: 2 }, { key: 3, val: 3 } ]
 * normalizeMap({a: 1, b: 2, c: 3}) => [ { key: 'a', val: 1 }, { key: 'b', val: 2 }, { key: 'c', val: 3 } ]
 * @param {Array|Object} map
 * @return {Object}
 */
function normalizeMap (map) {
  return Array.isArray(map)
    ? map.map(key => ({ key, val: key }))
    : Object.keys(map).map(key => ({ key, val: map[key] }))
}

/**
 * Return a function expect two param contains namespace and map. it will normalize the namespace and then the param's function will handle the new namespace and the map.
 * @param {Function} fn
 * @return {Function}
 */
function normalizeNamespace (fn) {
  return (namespace, map) => {
    // 首先判断第一个参数是否为字符串，因为我们大部分情况都是传递的是对象，只有使用命名空间的时候第一个参数会是字符串
    // 如果不是字符串的话，把第一个参数也就是namespace赋值为map，自己置为空，这样就达到了第一个参数传入对象也是可以的
    if (typeof namespace !== 'string') {
      map = namespace
      namespace = ''
    // 如果传入的是对象，如果最后一个字符不是/，则自动拼接，因为 store._modulesNamespaceMap 下都是这样的key 'some/nested/module'
    // 具体怎么实现这种路径的见源码 getNamespace 方法 https://github.com/vuejs/vuex/blob/665455f8da/src/module/module-collection.js#L16
    } else if (namespace.charAt(namespace.length - 1) !== '/') {
      namespace += '/'
    }
    return fn(namespace, map)
  }
}

```
这里只讲`mapState`，其他的实现大同小异，都差不太多

## vuex响应式原理

为什么我们通过修改`state`，模板里的视图也一起更新了呢？

```js
function resetStoreVM (store, state, hot) {
  const oldVm = store._vm

  // bind store public getters
  // 初始化store的getter
  store.getters = {}
  // 获取registerGetter方法注册的getter
  const wrappedGetters = store._wrappedGetters
  const computed = {}
  forEachValue(wrappedGetters, (fn, key) => {
    // use computed to leverage its lazy-caching mechanism
    // 因为getter的value都是函数，相当于vue的computed，这里直接执行获取结果
    computed[key] = () => fn(store)
    // 通过Object.defineProperty为给个getter设置get方法，改变getter获取值方式，如this.$store.getter.a会直接获取store._vm.a
    Object.defineProperty(store.getters, key, {
      get: () => store._vm[key],
      enumerable: true // for local getters
    })
  })

  // use a Vue instance to store the state tree
  // suppress warnings just in case the user has added
  // some funky global mixins
  // 先获取当前警告的配置
  const silent = Vue.config.silent
  // 将他置为true，意思是new Vue的时候不会抛出警告
  Vue.config.silent = true
  // 这里是关键，借助Vue的响应式来实现，这样state和getter的修改都会有响应式
  store._vm = new Vue({
    data: {
      $$state: state
    },
    computed
  })
  // new完之后恢复之前的配置
  Vue.config.silent = silent

  // enable strict mode for new vm
  // 保证修改值一定是通过mutation的
  if (store.strict) {
    enableStrictMode(store)
  }
  // 注销旧的state的引用，销毁旧的Vue对象
  if (oldVm) {
    if (hot) {
      // dispatch changes in all subscribed watchers
      // to force getter re-evaluation for hot reloading.
      store._withCommit(() => {
        oldVm._data.$$state = null
      })
    }
    Vue.nextTick(() => oldVm.$destroy())
  }
}
```
从上面我们可以看到，`vuex`实现响应式，借助的是`Vue`的响应式，通过把`store.state`赋值给`store._vm.$$state`，这样修改`state`，同样`store._vm.$$state也`会被修改
`getter`通过`Object.defineProperty`定义的`get`方法，访问的是`store._vm.computed`，让`getter`成为`vue`的计算实现，因此`getter`既拥有监听`store._vm.$$state`改变（并重新计算出自身的新值）的能力，又拥有在自身值改变之后通知外部`watcher`的能力

## 命名空间的副作用

我们之前提到`action`和`mutation`对应的名称的值是一个数组，而不是直接的一个方法，正常应该下面这样👇
```js
const actionCollect = {
  changeValue: ({ commit }, payload))=>{
    ...
  }
}
```
但是看源码我们知道，他是一个数组
```js
const actionCollect = {
    changeValue: [
      ({ commit }, payload)=>{
          ...
        }
      }
      ,function(){}
      ...
    ]
  } 
```
难道`action`还有`mutaion`会有同名的吗？答案肯定是的，这就要讲到命名空间了`namespace`

```js
new Vuex.Store({
  state: {
    a: 1
  },
  modules: {
    test1: {
      namespaced: true,
      state: {
        a: '2'
      },
      mutations: {
        changeValue: (state, payload) => {
          console.log('1')
          state.a = payload
        }
      }
    },
    test2: {
      namespaced: false,
      state: {
        a: '2'
      },
      modules: {
        test1: {
          namespaced: true,
          state: {
            a: 3
          },
          mutations: {
            changeValue: (state, payload) => {
              console.log('2')
              state.a = payload
            }
          }
        }
      }
    }
  }
})
```
```js
export default {
  name: 'App',
  mounted () {
    this.$store.commit('test1/changeValue', 'the same value')
}
// 输出：1
// 输出：2
```
你会发现你`commit`了一次缺触发了两个不同模块的`mutation`，这就是命名空间的副作用，具体内部是如何处理`namespace`之前也讲到了，[源码地址](https://github.com/vuejs/vuex/blob/665455f8da/src/module/module-collection.js#L16)

```js
getNamespace (path) {
  let module = this.root
  return path.reduce((namespace, key) => {
    module = module.getChild(key)
    return namespace + (module.namespaced ? key + '/' : '')
  }, '')
}
```
通过模块的`key`来拼接，如之前代码设置的`namespace`，`namespace`就是`test1/changeValue`

所以使用`namespace`一定要注意路径名问题，还是就是避免名称相同，除非你就想这么干

## 总结

`vuex`源码就先讲这么多，其实还有好几个点没讲，例如各种工具方法和`vue-devtools`的实现，总体多读几遍还是可以看明白的，这就是`debugger`的过程了

原文地址 http://www.wclimb.site/2019/10/14/Vue之vuex源码分析/