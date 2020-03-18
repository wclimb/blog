---
title: Vue源码之虚拟DOM
date: 2020-03-17 15:50:20
tags:
- javascript
- vue
- 源码
- 原创
categories: [javascript, vue]
---

## 前言

[上一篇](http://www.wclimb.site/2020/03/15/vue-source-code-data-bind/)我们讲了一下 `Vue` 的双向数据绑定原理，今天我们开始讲一下 `Vue` 的 `虚拟DOM`。
本文会先分析一下 `Vue` 的 `虚拟DOM`，然后下一篇文章会带大家撸一个简易的 `虚拟DOM`


## Vue虚拟DOM

### 创建虚拟DOM

https://github.com/wclimb/vue/blob/dev/src/core/vdom/vnode.js
```js
export default class VNode {
  tag: string | void;
  data: VNodeData | void;
  children: ?Array<VNode>;
  text: string | void;
  elm: Node | void;
  ns: string | void;
  context: Component | void; // rendered in this component's scope
  functionalContext: Component | void; // only for functional component root nodes
  key: string | number | void;
  componentOptions: VNodeComponentOptions | void;
  componentInstance: Component | void; // component instance
  parent: VNode | void; // component placeholder node
  raw: boolean; // contains raw HTML? (server only)
  isStatic: boolean; // hoisted static node
  isRootInsert: boolean; // necessary for enter transition check
  isComment: boolean; // empty comment placeholder?
  isCloned: boolean; // is a cloned node?
  isOnce: boolean; // is a v-once node?

  constructor (
    tag?: string,
    data?: VNodeData,
    children?: ?Array<VNode>,
    text?: string,
    elm?: Node,
    context?: Component,
    componentOptions?: VNodeComponentOptions
  ) {
    this.tag = tag
    this.data = data
    this.children = children
    this.text = text
    this.elm = elm
    this.ns = undefined
    this.context = context
    this.functionalContext = undefined
    this.key = data && data.key
    this.componentOptions = componentOptions
    this.componentInstance = undefined
    this.parent = undefined
    this.raw = false
    this.isStatic = false
    this.isRootInsert = true
    this.isComment = false
    this.isCloned = false
    this.isOnce = false
  }

  // DEPRECATED: alias for componentInstance for backwards compat.
  /* istanbul ignore next */
  get child (): Component | void {
    return this.componentInstance
  }
}
```
以上代码是`Vue`创建 `虚拟DOM` 的类，一眼看过去是不是感觉东西太多了？其实我们主要关注主要的几个参数就可以了，`tag` 、`data`、`children`、`text`、`elm`、`key`

- `tag` 表示当前 `vnode` 的标签类型，比如 `div` `ul` 
- `data` 表示当前 `vnode` 标签上的 `attribute`，可能是`class`、`id`、`key`
- `children` 表示当前 `vnode` 的子节点
- `text` 表示文本内容
- `elm` 表示当前 `vnode` 的真实 `DOM` 节点
- `key` `diff算法` 需要用到，就是我们开发中写的 `:key`

<!-- more -->
### 从入口开始

我们从入口开始，看一下 `Vue` 实现 `虚拟DOM` 的流程是怎么样的，
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
上面这段代码在[上一篇](http://www.wclimb.site/2020/03/15/vue-source-code-data-bind/)文章有讲过，我们在这里只需要关心 `vm.$mount(vm.$options.el)` 这段代码，从这里开始挂载`DOM`

### $mount

https://github.com/wclimb/vue/blob/dev/src/platforms/web/entry-runtime-with-compiler.js#L17

```js
var mount = Vue.prototype.$mount;
Vue.prototype.$mount = function (
  el,
  hydrating
) {
  el = el && query(el);

  /* istanbul ignore if */
  if (el === document.body || el === document.documentElement) {
    warn(
      "Do not mount Vue to <html> or <body> - mount to normal elements instead."
    );
    return this
  }

  var options = this.$options;
  // resolve template/el and convert to render function
  if (!options.render) {
      ...
    } else if (el) {
      template = getOuterHTML(el);
    }
    if (template) {
      var ref = compileToFunctions(template, {
        outputSourceRange: "development" !== 'production',
        shouldDecodeNewlines: shouldDecodeNewlines,
        shouldDecodeNewlinesForHref: shouldDecodeNewlinesForHref,
        delimiters: options.delimiters,
        comments: options.comments
      }, this);
      var render = ref.render;
      var staticRenderFns = ref.staticRenderFns;
      options.render = render;
      options.staticRenderFns = staticRenderFns;

      /* istanbul ignore if */
      if (config.performance && mark) {
        mark('compile end');
        measure(("vue " + (this._name) + " compile"), 'compile', 'compile end');
      }
    }
  }
  return mount.call(this, el, hydrating)
};
```
我们先看上面 `template` 是什么，`template` 其实是我们写的模版的 `html` 比如 `<div id="app"></div>`，然后把模版给 `compileToFunctions` 方法去解析，这过程就是生成`ast` `html`树。得到 `ref` 对象，
内部有一个`render`方法，它的方法就是类似下面代码一样,比如 `_c` 其实就是我们后面要讲的创建生成 `vnode` 元素方法

```js
with(this){return _c('div',{attrs:{"id":"div1"}},_l((arr),function(item,idx){return _c('span',{key:item},[_v(_s(item))])}),0)}
```

以下就是对应的方法 `_v`指创建文本`vnode`
```js
function installRenderHelpers (target) {
  target._o = markOnce;
  target._n = toNumber;
  target._s = toString;
  target._l = renderList;
  target._t = renderSlot;
  target._q = looseEqual;
  target._i = looseIndexOf;
  target._m = renderStatic;
  target._f = resolveFilter;
  target._k = checkKeyCodes;
  target._b = bindObjectProps;
  target._v = createTextVNode;
  target._e = createEmptyVNode;
  target._u = resolveScopedSlots;
  target._g = bindObjectListeners;
  target._d = bindDynamicKeys;
  target._p = prependModifier;
}
```

我们接着往下看最后代码会执行 `return mount.call(this, el, hydrating)`，`mount`代码就是之前第一行代码提前获取了

https://github.com/wclimb/vue/blob/dev/src/platforms/web/runtime/index.js#L37
```js
Vue.prototype.$mount = function (
  el?: string | Element,
  hydrating?: boolean
): Component {
  el = el && inBrowser ? query(el) : undefined
  return mountComponent(this, el, hydrating)
}
```
上面代码继续调用了 `mountComponent` 方法，继续往下看

### mountComponent

https://github.com/wclimb/vue/blob/dev/src/core/instance/lifecycle.js#L141
```js
export function mountComponent (
  vm: Component,
  el: ?Element,
  hydrating?: boolean
): Component {
  vm.$el = el
  if (!vm.$options.render) {
    vm.$options.render = createEmptyVNode
    ....
  }
  callHook(vm, 'beforeMount')

  let updateComponent
  /* istanbul ignore if */
  if (process.env.NODE_ENV !== 'production' && config.performance && mark) {
    updateComponent = () => {
      const name = vm._name
      const id = vm._uid
      const startTag = `vue-perf-start:${id}`
      const endTag = `vue-perf-end:${id}`

      mark(startTag)
      const vnode = vm._render()
      mark(endTag)
      measure(`vue ${name} render`, startTag, endTag)

      mark(startTag)
      vm._update(vnode, hydrating)
      mark(endTag)
      measure(`vue ${name} patch`, startTag, endTag)
    }
  } else {
    updateComponent = () => {
      vm._update(vm._render(), hydrating)
    }
  }

  new Watcher(vm, updateComponent, noop, {
    before () {
      if (vm._isMounted && !vm._isDestroyed) {
        callHook(vm, 'beforeUpdate')
      }
    }
  }, true )
  hydrating = false

  if (vm.$vnode == null) {
    vm._isMounted = true
    callHook(vm, 'mounted')
  }
  return vm
}
```
这段代码是重点，看过[上一篇](http://www.wclimb.site/2020/03/15/vue-source-code-data-bind/)文章的可能有印象，主要实例化了一个订阅者`Watcher`，内部会执行`updateComponent`方法，内容如下
```js
updateComponent = () => {
  vm._update(vm._render(), hydrating)
}
```
Vue会调用 `_render` 方法去生成`虚拟DOM`，调用`_update`去更新视图，`_update`方法后面讲`diff`算法会讲，很重要。不过这里我们先看看`_render`函数

### _render

https://github.com/wclimb/vue/blob/dev/src/core/instance/render.js#L69
```js
Vue.prototype._render = function (): VNode {
    const vm: Component = this
    const { render, _parentVnode } = vm.$options

    ....
    
    vm.$vnode = _parentVnode
    // render self
    let vnode
    try {
      currentRenderingInstance = vm
      vnode = render.call(vm._renderProxy, vm.$createElement)
    } catch (e) {
      handleError(e, vm, `render`)
    } finally {
      currentRenderingInstance = null
    }

    ...

    // set parent
    vnode.parent = _parentVnode
    return vnode
  }
```
我们主要看这一段代码 `vnode = render.call(vm._renderProxy, vm.$createElement)`，生成 `虚拟DOM`，之前会把 `vm.$createElement` 方法传入，其实就是创建 `vnode` 元素的方法，最后会执行render方法，`render` 方法就是我们之前 `compileToFunctions` 函数生成对象的方法，

### $createElement

https://github.com/wclimb/vue/blob/dev/src/core/instance/render.js#L34
```js
export function initRender (vm: Component) {
  ...
  vm.$createElement = (a, b, c, d) => createElement(vm, a, b, c, d, true)
  ...
}
```
继续调用了`createElement`方法

### createElement

https://github.com/wclimb/vue/blob/dev/src/core/vdom/create-element.js#L28
```js
export function createElement (
  context: Component,
  tag: any,
  data: any,
  children: any,
  normalizationType: any,
  alwaysNormalize: boolean
): VNode | Array<VNode> {
  if (Array.isArray(data) || isPrimitive(data)) {
    normalizationType = children
    children = data
    data = undefined
  }
  if (isTrue(alwaysNormalize)) {
    normalizationType = ALWAYS_NORMALIZE
  }
  return _createElement(context, tag, data, children, normalizationType)
}
```
不用多说了？ 继续找`_createElement`，往下看下面几行代码就是了

### _createElement

https://github.com/wclimb/vue/blob/dev/src/core/vdom/create-element.js#L47
```js
export function _createElement (
  context: Component,
  tag?: string | Class<Component> | Function | Object,
  data?: VNodeData,
  children?: any,
  normalizationType?: number
): VNode | Array<VNode> {

  ....

  if (normalizationType === ALWAYS_NORMALIZE) {
    children = normalizeChildren(children)
  } else if (normalizationType === SIMPLE_NORMALIZE) {
    children = simpleNormalizeChildren(children)
  }
  let vnode, ns
  if (typeof tag === 'string') {
    let Ctor
    ns = (context.$vnode && context.$vnode.ns) || config.getTagNamespace(tag)
    if (config.isReservedTag(tag)) {
      ...
      vnode = new VNode(
        config.parsePlatformTagName(tag), data, children,
        undefined, undefined, context
      )
    } else if ((!data || !data.pre) && isDef(Ctor = resolveAsset(context.$options, 'components', tag))) {
      // component
      vnode = createComponent(Ctor, data, context, children, tag)
    } else {
      vnode = new VNode(
        tag, data, children,
        undefined, undefined, context
      )
    }
  } else {
    vnode = createComponent(tag, data, context, children)
  }
  if (Array.isArray(vnode)) {
    return vnode
  } else if (isDef(vnode)) {
    if (isDef(ns)) applyNS(vnode, ns)
    if (isDef(data)) registerDeepBindings(data)
    return vnode
  } else {
    return createEmptyVNode()
  }
}
```
到目前为止创建`虚拟DOM`的过程就结束了

## diff更新虚拟DOM

之前我们又说到用`_render`来生成`vnode`树，用`_update`来更新视图

### _update

https://github.com/wclimb/vue/blob/dev/src/core/instance/lifecycle.js#L59
```js
Vue.prototype._update = function (vnode: VNode, hydrating?: boolean) {
  const vm: Component = this
  const prevEl = vm.$el
  const prevVnode = vm._vnode
  const restoreActiveInstance = setActiveInstance(vm)
  vm._vnode = vnode
  // 如果之前不存在虚拟DOM
  if (!prevVnode) {
    // initial render
    vm.$el = vm.__patch__(vm.$el, vnode, hydrating, false /* removeOnly */)
  } else {
    // 如果存在旧的虚拟DOM，就传递到__patch__去进行新旧的比较
    vm.$el = vm.__patch__(prevVnode, vnode)
  }
  .....
}
```
上面第一个参数传递的就是`虚拟DOM`，也就是本文之前说的 `_render()` 返回的 `vnode` ，我们需要继续看 `__patch__` 方法

### __patch__

```js
return function patch (oldVnode, vnode, hydrating, removeOnly) {

  .....
  
  let isInitialPatch = false
  const insertedVnodeQueue = []
  // 不存在旧的就会重新创建一个
  if (isUndef(oldVnode)) {
    isInitialPatch = true
    createElm(vnode, insertedVnodeQueue)
  } else {
    const isRealElement = isDef(oldVnode.nodeType)
    if (!isRealElement && sameVnode(oldVnode, vnode)) {
      patchVnode(oldVnode, vnode, insertedVnodeQueue, null, null, removeOnly)
    } else {
      
      .....
      
    }
  }
  return vnode.elm
}
```
`patch`方法主要做了两件事情，如果没有旧的 `虚拟DOM`，旧会重新创建一个根节点。否则的话使用`sameVnode`判断 `oldVnode`和`vnode`是否是相同的节点(这个相同不是完全都相同)，`sameVnode`的作用主要是判断是否只需要作局部刷新，来看看具体的代码
```js
function sameVnode (a, b) {
  return (
    a.key === b.key && (
      (
        a.tag === b.tag &&
        a.isComment === b.isComment &&
        isDef(a.data) === isDef(b.data) &&
        sameInputType(a, b)
      ) || (
        isTrue(a.isAsyncPlaceholder) &&
        a.asyncFactory === b.asyncFactory &&
        isUndef(b.asyncFactory.error)
      )
    )
  )
}
```
主要判断`key` `tag`，如果 `key` 并且 `tag` 相同我们旧可以判定作局部刷新，如果不相同那么就会直接跳过 `diff`，进而依据 `vnode` 新建一个真实的 `DOM`，删除旧的 `DOM` 节点。我们看看`Vue`是怎么`diff`的，继续看 `patchVnode` 代码

### patchVnode

https://github.com/wclimb/vue/blob/dev/src/core/vdom/patch.js#L501
```js
function patchVnode (
  oldVnode,
  vnode,
  insertedVnodeQueue,
  ownerArray,
  index,
  removeOnly
) {
  if (oldVnode === vnode) {
    return
  }

  ....

  let i
  const data = vnode.data
  if (isDef(data) && isDef(i = data.hook) && isDef(i = i.prepatch)) {
    i(oldVnode, vnode)
  }

  const oldCh = oldVnode.children
  const ch = vnode.children
  if (isDef(data) && isPatchable(vnode)) {
    for (i = 0; i < cbs.update.length; ++i) cbs.update[i](oldVnode, vnode)
    if (isDef(i = data.hook) && isDef(i = i.update)) i(oldVnode, vnode)
  }
  // 判断当前节点是否为文本节点
  if (isUndef(vnode.text)) {
    // 如果虚拟DOM的新旧children都存在，也就是子节点
    if (isDef(oldCh) && isDef(ch)) {
      // 如果都存在，但是二者不相等，则需要对他们的children进行diff
      if (oldCh !== ch) updateChildren(elm, oldCh, ch, insertedVnodeQueue, removeOnly)
    } else if (isDef(ch)) {
      // 新的子节点如果存在但是旧的不存在，则需要把向旧的添加
      if (process.env.NODE_ENV !== 'production') {
        checkDuplicateKeys(ch)
      }
      if (isDef(oldVnode.text)) nodeOps.setTextContent(elm, '')
      addVnodes(elm, null, ch, 0, ch.length - 1, insertedVnodeQueue)
    } else if (isDef(oldCh)) {
      // 旧的子节点如果存在但是新的不存在，则需要把旧虚拟DOM原有的children删除
      removeVnodes(oldCh, 0, oldCh.length - 1)
    } else if (isDef(oldVnode.text)) {
      nodeOps.setTextContent(elm, '')
    }
  } else if (oldVnode.text !== vnode.text) {
    // 文本不相同则替换新的文本
    nodeOps.setTextContent(elm, vnode.text)
  }
}
```
`patchVnode` 相当于只能做到一层的判断，如果当前 `diff` 的虚拟DOM还存在 `children` 的话，需要进一步 `diff`，也就是使用 `updateChildren`

### updateChildren

https://github.com/wclimb/vue/blob/dev/src/core/vdom/patch.js#L404
```js
function updateChildren (parentElm, oldCh, newCh, insertedVnodeQueue, removeOnly) {
  let oldStartIdx = 0
  let newStartIdx = 0
  let oldEndIdx = oldCh.length - 1
  let oldStartVnode = oldCh[0]
  let oldEndVnode = oldCh[oldEndIdx]
  let newEndIdx = newCh.length - 1
  let newStartVnode = newCh[0]
  let newEndVnode = newCh[newEndIdx]
  let oldKeyToIdx, idxInOld, vnodeToMove, refElm

  const canMove = !removeOnly

  if (process.env.NODE_ENV !== 'production') {
    checkDuplicateKeys(newCh)
  }

  while (oldStartIdx <= oldEndIdx && newStartIdx <= newEndIdx) {
    // 如果oldStartVnode不存在，因为可能是undefined，后面处理可能会置为undefined
    if (isUndef(oldStartVnode)) {
      oldStartVnode = oldCh[++oldStartIdx] // Vnode has been moved left
    } else if (isUndef(oldEndVnode)) {
    // 如果oldEndVnode不存在，跟上面情况类似，如果没有就收缩diff区间
      oldEndVnode = oldCh[--oldEndIdx]
    } else if (sameVnode(oldStartVnode, newStartVnode)) {
      // 新旧第一位的虚拟DOM相同，则可以局部渲染，diff区间都进一位，继续patch比较子节点(如果有children的话,如果没有就比较文本节点就可以了)
      patchVnode(oldStartVnode, newStartVnode, insertedVnodeQueue, newCh, newStartIdx)
      oldStartVnode = oldCh[++oldStartIdx]
      newStartVnode = newCh[++newStartIdx]
    } else if (sameVnode(oldEndVnode, newEndVnode)) {
      // 新旧结尾的虚拟DOM相同，diff区间最后一位都向前进一位，继续patch比较子节点
      patchVnode(oldEndVnode, newEndVnode, insertedVnodeQueue, newCh, newEndIdx)
      oldEndVnode = oldCh[--oldEndIdx]
      newEndVnode = newCh[--newEndIdx]
    } else if (sameVnode(oldStartVnode, newEndVnode)) { // Vnode moved right
      // 旧的开头和新的结尾判断是否一样，如果一样的话就的开头放到最后去，我们看它调用了insertBefore，按理不管怎样都不会在最后，因为它又使用了nextSibling，
      // nodeOps.nextSibling(oldEndVnode.elm)返回的就是null了，调用insertBefore就会把它放到parentElm的最后
      patchVnode(oldStartVnode, newEndVnode, insertedVnodeQueue, newCh, newEndIdx)
      canMove && nodeOps.insertBefore(parentElm, oldStartVnode.elm, nodeOps.nextSibling(oldEndVnode.elm))
      oldStartVnode = oldCh[++oldStartIdx]
      newEndVnode = newCh[--newEndIdx]
    } else if (sameVnode(oldEndVnode, newStartVnode)) { // Vnode moved left
      // 同理上面
      patchVnode(oldEndVnode, newStartVnode, insertedVnodeQueue, newCh, newStartIdx)
      canMove && nodeOps.insertBefore(parentElm, oldEndVnode.elm, oldStartVnode.elm)
      oldEndVnode = oldCh[--oldEndIdx]
      newStartVnode = newCh[++newStartIdx]
    } else {
      // 这里会判断oldKeyToIdx是否定义，初次都是undefined，如果没有就会去通过key生成一个对象，比如你的key为 abc，当前下标为0，那么oldKeyToIdx = {abc: 0,xxx: 1} 
      if (isUndef(oldKeyToIdx)) oldKeyToIdx = createKeyToOldIdx(oldCh, oldStartIdx, oldEndIdx)
      idxInOld = isDef(newStartVnode.key)
        ? oldKeyToIdx[newStartVnode.key]
        : findIdxInOld(newStartVnode, oldCh, oldStartIdx, oldEndIdx)
      // 看看当前的key是否在里面，得到当前的idxInOld
      if (isUndef(idxInOld)) { // New element
        // 如果没找到相应的key就证明当前是新元素。则直接创建
        createElm(newStartVnode, insertedVnodeQueue, parentElm, oldStartVnode.elm, false, newCh, newStartIdx)
      } else {
        // 如果找到
        vnodeToMove = oldCh[idxInOld]
        // 并且是同类型的虚拟DOM，则先把当前置为undefined，证明当前已经处理了，然后把相应的元素插入到对应的位置
        if (sameVnode(vnodeToMove, newStartVnode)) {
          patchVnode(vnodeToMove, newStartVnode, insertedVnodeQueue, newCh, newStartIdx)
          oldCh[idxInOld] = undefined
          canMove && nodeOps.insertBefore(parentElm, vnodeToMove.elm, oldStartVnode.elm)
        } else {
          // 相同的key但是不同的元素就直接创建元素
          createElm(newStartVnode, insertedVnodeQueue, parentElm, oldStartVnode.elm, false, newCh, newStartIdx)
        }
      }
      // 处理完当前新的虚拟DOM就进一位
      newStartVnode = newCh[++newStartIdx]
    }
  }
  // 如果旧的开始 > 旧的结尾下标，证明当前旧的虚拟DOM不够比较了，证明新的虚拟DOM明显比旧的元素多，就可以直接插入剩下的元素了
  if (oldStartIdx > oldEndIdx) {
    refElm = isUndef(newCh[newEndIdx + 1]) ? null : newCh[newEndIdx + 1].elm
    addVnodes(parentElm, refElm, newCh, newStartIdx, newEndIdx, insertedVnodeQueue)
  } else if (newStartIdx > newEndIdx) {
  // 如果新的开始 > 新的结尾下标，证明当前新的虚拟DOM不够比较了，证明新的虚拟DOM明显比旧的元素少，则需要把剩下的旧虚拟DOM移除掉
    removeVnodes(oldCh, oldStartIdx, oldEndIdx)
  }
}
```
上面就是完整的`diff`算法了，可以直接看代码内的注释，你会发现进行最简单的判断，判断开始结尾是否相互一样，再通过`key`来查找元素，提高效率。

## 图解diff过程

比如我们现在我们有`data` `[A, B, C, D]`，我们把他们改为 `[B, C, A, D]`

```html
<div v-for="item in arr" :key="item">item</div>
```
```js
new Vue({
  data:{
    arr: ['A', 'B', 'C', 'D']
  },
  mounted(){
    setTimeout(()=>{
      this.arr = ['B', 'C', 'A', 'D', 'F']
    },1000)
  }
})
```
### 有key的情况

![](/img/diff/1.jpg)
解析👆：最开始的 `startIdx` 都是`0`，都会从最开始比对，第一位是 `A` 和 `B`，发现不一样，整个判断下来，发现前后都没有一样的元素，那么就会走第7个判断，通过`key`值来查找，他会去旧的`虚拟DOM`里找`B`元素，发现找了，先把他置为 `undefined` ，然后把他插入到A的前面，然后`newStartIdx`进一位，此轮`diff`完成

![](/img/diff/2.jpg)
解析👆：现在`newStartIdx`来到了 `C` 这里，同样先看看有没有前后一样的，发现没有，又走到第7个判断里，通过 `key` 值来查找，找到 `C` 之后，把旧的`C`置为`undefined`，然后把`C`插入到`A`前面，然后`newStartIdx`进一位，此轮 `diff` 完成

![](/img/diff/3.jpg)
解析👆：现在`newStartIdx`来到了 `A` 这里，同样先看看有没有前后一样的，发现旧的开始和新的开始位置一样，此时就不用改变位置了，直接`oldStartIdx`和`newStartIdx`都进一位，此轮`diff`完成

![](/img/diff/4.jpg)
解析👆：我们发现`oldStartIdx`来到了`B`这里，但是B是已经是`undefined`的，此轮会走 `if(isUndef(oldStartVnode)){}`，直接`oldStartIdx`进一位。进一位之后发现又是`undefined`，继续+1，来到来`D`这里
此时的`oldStartIdx`和`oldEndIdx`是一样的，此时的`newStartIdx`也是`D`，发现开始都相同，那么位置不用变，新旧的`startIdx`都进一位，你会发现此时的`oldStartIdx > oldEndIdx`，大于的话就满足上面源码里
`if (oldStartIdx > oldEndIdx) {}`

![](/img/diff/5.jpg)
解析👆：满足 `if (oldStartIdx > oldEndIdx) {}` 我们需要把剩下的新的 `虚拟DOM` 插入到后面，也就是把`F`插入到最后

### 无key的情况

![](/img/diff/diff-no-key.png)
👆看下来你会发现，为啥不带 `key` 貌似反而更快，因为咱们这里比较的都是文本节点，最简单的示例。为什么会直接赋值修改，你应该可以回过头看`sameVnode`的判断规则
```js
function sameVnode (a, b) {
  return (
    a.key === b.key && (
      (
        a.tag === b.tag &&
        a.isComment === b.isComment &&
        isDef(a.data) === isDef(b.data) &&
        sameInputType(a, b)
      ) || (
        isTrue(a.isAsyncPlaceholder) &&
        a.asyncFactory === b.asyncFactory &&
        isUndef(b.asyncFactory.error)
      )
    )
  )
}
```
不写 `key`，也满足第一个条件，然后 `tag`又都是 `span`，所以每次比较都会走 `sameVnode(oldStartVnode, newStartVnode)`，然后他们就会直接去修改 `textContent`。

所以在复杂的 `DOM` 中，我们还是要通过写 `key` 来提升渲染效率

## 总结

本文讲解了`Vue` `虚拟DOM` 的原理，带大家看了一下他的运行流程，以及关键的 `diff` 算法，也比较了有 `key` 和无 `key` 的 `diff` 过程，本文的示例比较简单，不能覆盖所有 `diff` 判断的条件，感兴趣可以自己去尝试。下一篇会带大家撸一个自己的 `虚拟DOM`，加深理解

本文地址 [Vue源码之虚拟DOM](http://www.wclimb.site/2020/03/17/vue-source-code-virtual-dom/)
