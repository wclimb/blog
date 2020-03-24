---
title: 撸一个简易Virtual DOM
date: 2020-03-19 10:47:52
tags:
- javascript
- vue
- 源码
- 原创
categories: [javascript, vue]
---

## 前言

[上一篇](http://www.wclimb.site/2020/03/17/vue-source-code-virtual-dom/)我们讲了一下 `Vue` 的 `虚拟DOM`，从创建到更新整个流程。今天带大家撸一个简易的`虚拟DOM`，本文的大部分借鉴 `Vue` 源码

## 浏览器渲染流程

> 摘自[浏览器工作原理与实践](https://time.geekbang.org/column/article/118826)

![](/img/virtual-dom/brower-dom-render.png)

1. 渲染进程将 `HTML` 内容转换为能够读懂的 `DOM` 树结构。
2. 渲染引擎将 `CSS` 样式表转化为浏览器可以理解的 `styleSheets`，计算出 `DOM` 节点的样式。
3. 创建布局树，并计算元素的布局信息。
4. 对布局树进行分层，并生成分层树。
5. 为每个图层生成绘制列表，并将其提交到合成线程。
6. 合成线程将图层分成图块，并在光栅化线程池中将图块转换成位图。
7. 合成线程发送绘制图块命令 `DrawQuad` 给浏览器进程。
8. 浏览器进程根据 `DrawQuad` 消息生成页面，并显示到显示器上。

## 准备

首先我们要明白什么是`虚拟DOM`，为什么要用到它，`虚拟DOM` 是使用 `javascript` 对象来描述 `DOM` 树，一切的更新修改都是在更改这个对象，然后反应到真实的 `DOM` 下。要说为什么要用到它，肯定是因为性能好，因为直接操作 `DOM` 的代价是很大的，比如，一次操作中有 `10` 次更新 `DOM` 的动作，`虚拟DOM` 不会立即操作 `DOM`，而是将这 `10` 次更新的 `diff` 内容保存到本地一个 `js` 对象中，最终将这个 `js` 对象一次性 反应到 `DOM` 树上，再进行后续操作，避免大量无谓的计算。也有人反驳说，使用 `虚拟DOM` 比起操作真实 `DOM` 要慢，的确如此，使用虚拟DOM确实没有原生操作快，但是既然使用了框架，优化框架都会帮你做，你不用自己去手动做DOM的优化，不用处处去考虑操作 `DOM` 带来的性能问题，使用 `虚拟DOM` 可以让性能得到有力的保证。

可以参考知乎问题 [网上都说操作真实 DOM 慢，但测试结果却比 React 更快，为什么？](https://www.zhihu.com/question/31809713)

## 实现

### 使用js对象模拟DOM树

这里我们不使用 `Vue` 的那种根据 `template` 生成 `虚拟DOM` 的方法，那样太复杂了，这里只讲简单的方法，我们直接使用 `js` 对象来描述 `DOM`

比如如下 的`html` 代码
```html
<div id="app">
  <h1 data-title="header">Virtual Dom</h1>
  <ul class="ul1">
    <li>1</li>
    <li>2</li>
    <li>3</li>
  </ul>
</div>
```
<!-- more -->
使用 `js` 对象表示
```js
function vnode(tag, data, children) {
  return {
    tag,
    data,
    children,
  };
}
function createElement(vNode) {
  let el;
  if (vNode.tag === 'textNode') {
    el = document.createTextNode(vNode.children[0]);
  } else {
    el = document.createElement(vNode.tag);
    for (const key in vNode.data) {
      if (vNode.data.hasOwnProperty(key)) {
        el.setAttribute(key, vNode.data[key]);
      }
    }
    if (Array.isArray(vNode.children) && vNode.children.length > 0) {
      vNode.children.forEach(val => {
        el.appendChild(createElement(val));
      });
    }
  }
  vNode.$el = el;
  return el;
}
```
- `tag`：表示当前元素的标签名，后面会看到有 `textNode` 的标签名，实际上没有，在这里特指文本节点
- `data`：表示当前元素上的 `attribute`
- `children`：表示当前元素的子元素

- `createElement`：使用该方法渲染到页面上

生成 `vNode`
```js
const vNode1 = vnode('div', { id: 'app' }, [
  vnode('h1', { 'data-title': 'header' }, [
    vnode('textNode', {}, ['Virtual Dom']),
  ]),
  vnode('ul', { class: 'ul1' }, [
    vnode('li', {}, [vnode('textNode', {}, ['1'])]),
    vnode('li', {}, [vnode('textNode', {}, ['2'])]),
    vnode('li', {}, [vnode('textNode', {}, ['3'])]),
  ]),
]);
```
![](/img/virtual-dom/vnode.png)

反应到页面上，把结果放到 `body` 下
```js
document.body.appendChild(createElement(vNode1))
```
效果
![](/img/virtual-dom/old.png)

### 更新Virtual Dom

更新之前我们把之前的旧的`虚拟DOM` `li`列表上的 `key`值加上

`oldVNode`
```js
const vNode1 = vnode('div', { id: 'app' }, [
  vnode('h1', { 'data-title': 'header' }, [
    vnode('textNode', {}, ['Virtual Dom']),
  ]),
  vnode('ul', { class: 'ul1' }, [
    vnode('li', {key: 1}, [vnode('textNode', {}, ['1'])]),
    vnode('li', {key: 2}, [vnode('textNode', {}, ['2'])]),
    vnode('li', {key: 3}, [vnode('textNode', {}, ['3'])]),
  ]),
]);
```
`newVNode`
```js
const vNode2 = vnode('div', { id: 'app' }, [
  vnode('h4', { id: 'header'}, [
    vnode('textNode', {}, ['元素标签改变了']),
  ]),
  vnode('ul', { class: 'ul2' }, [
    vnode('li', {key: 5}, [vnode('textNode', {}, ['5'])]),
    vnode('li', {key: 2}, [vnode('textNode', {}, ['2'])]),
    vnode('li', {key: 1}, [vnode('textNode', {}, ['1'])]),
    vnode('li', {key: 4}, [vnode('textNode', {}, ['4'])]),
  ]),
]);
```
你会发现为把 `h1` 标签改成了 `h4`,文本那样也改变了，在 `ul` 列表里，把他们的顺序改变了，并插入删除了部分元素。当然你也可以定制更复杂的结构


开始 `diff`，调用 `patchVnode` 方法
```js
patchVnode(vNode1, vNode2);
```

```js
function patchVnode(oldVnode, vnode) {
  // 1. 文本节点都一样
  if (oldVnode.tag === 'textNode' || vnode.tag === 'textNode') {
    if (oldVnode.children[0] !== vnode.children[0]) {
      oldVnode.$el.textContent = vnode.children[0];
    }
    return;
  }

  // 2. data是否被改变
  if (dataChanged(oldVnode.data, vnode.data)) {
    const oldData = oldVnode.data;
    const newData = vnode.data;
    const oldDataKeys = Object.keys(oldData);
    const newDataKeys = Object.keys(newData);
    if (oldDataKeys.length === 0) {
      for (let i = 0; i < oldDataKeys.length; i++) {
        oldVnode.$el.removeAttribute(oldData[i]);
      }
    } else {
      const filterKeys = new Set([...oldDataKeys, ...newDataKeys]);
      for (let key of filterKeys) {
        if (isUndef(newData[key])) {
          oldVnode.$el.removeAttribute(oldData[key]);
        } else if (newData[key] !== oldData[key]) {
          oldVnode.$el.setAttribute(key, newData[key]);
        }
      }
    }
  }
  var oldCh = oldVnode.children;
  var ch = vnode.children;
  // 如果新旧子节点仍然存在，则继续diff它的子节点
  if (oldCh.length || ch.length) {
    updateChildren(oldVnode.$el, oldCh, ch);
  }
}
```
上面先对最外层进行比较，
1. 如果是文本，说明已经是当前最后的一个元素了，后面不需要继续执行，发现不一样则改变他们
2. 判断 `data` 是否变更，如果变更则进行插入或者删除修改操作
3. 继续找它的子元素是否操作，如果存在进行子元素的 `diff`，使用 `updateChildren`

`updateChildren`
```js
function updateChildren(parentElm, oldCh, newCh) {
  if (oldCh) var oldStartIdx = 0;
  var newStartIdx = 0;
  var oldEndIdx = oldCh.length - 1;
  var oldStartVnode = oldCh[0];
  var oldEndVnode = oldCh[oldEndIdx];
  var newEndIdx = newCh.length - 1;
  var newStartVnode = newCh[0];
  var newEndVnode = newCh[newEndIdx];
  var oldKeyToIdx, idxInOld, vnodeToMove, refElm;
  while (oldStartIdx <= oldEndIdx && newStartIdx <= newEndIdx) {
    if (isUndef(oldStartVnode)) {
      oldStartVnode = oldCh[++oldStartIdx];
    } else if (isUndef(oldEndVnode)) {
      oldEndVnode = oldCh[--oldEndIdx];
    } else if (sameVnode(oldStartVnode, newStartVnode)) {
      patchVnode(oldStartVnode, newStartVnode);
      oldStartVnode = oldCh[++oldStartIdx];
      newStartVnode = newCh[++newStartIdx];
    } else if (sameVnode(oldEndVnode, newEndVnode)) {
      patchVnode(oldEndVnode, newEndVnode);
      oldEndVnode = oldCh[--oldEndIdx];
      newEndVnode = newCh[--newEndIdx];
    } else if (sameVnode(oldStartVnode, newEndVnode)) {
      patchVnode(oldStartVnode, newEndVnode);
      parentElm.insertBefore(oldStartVnode.$el, oldEndVnode.$el.nextSibling);
      oldStartVnode = oldCh[++oldStartIdx];
      newEndVnode = newCh[--newEndIdx];
    } else if (sameVnode(oldEndVnode, newStartVnode)) {
      patchVnode(oldEndVnode, newStartVnode);
      parentElm.insertBefore(oldEndVnode.$el, oldStartVnode.$el);
      oldEndVnode = oldCh[--oldEndIdx];
      newStartVnode = newCh[++newStartIdx];
    } else {
      if (isUndef(oldKeyToIdx)) {
        oldKeyToIdx = createKeyToOldIdx(oldCh, oldStartIdx, oldEndIdx);
      }
      idxInOld = isDef(newStartVnode.key)
        ? oldKeyToIdx[newStartVnode.key]
        : findIdxInOld(newStartVnode, oldCh, oldStartIdx, oldEndIdx);
      if (isUndef(idxInOld)) {
        parentElm.insertBefore(createElement(newStartVnode), oldStartVnode.$el);
      } else {
        vnodeToMove = oldCh[idxInOld];
        if (sameVnode(vnodeToMove, newStartVnode)) {
          patchVnode(vnodeToMove, newStartVnode);
          oldCh[idxInOld] = undefined;
          parentElm.insertBefore(vnodeToMove.$el, oldStartVnode.$el);
        } else {
          parentElm.insertBefore(
            createElement(newStartVnode),
            oldStartVnode.$el,
          );
        }
      }

      newStartVnode = newCh[++newStartIdx];
    }
  }
  if (oldStartIdx > oldEndIdx) {
    addVnodes(parentElm, newCh, newStartIdx, newEndIdx);
  } else if (newStartIdx > newEndIdx) {
    removeVnodes(parentElm, oldCh, oldStartIdx, oldEndIdx);
  }
}
```
上面代码基本参照 `Vue` 源码的方法，如果你阅读过我[之前发的文章](http://www.wclimb.site/2020/03/17/vue-source-code-virtual-dom/)，肯定有印象，代码内就不多作解释了，上一篇文章的注释说得很明白，感兴趣可以去翻阅一下。

看一下结果，一切都正常

![](/img/virtual-dom/new.png)

相关源码已经放在 `GitHub: ` https://github.com/wclimb/simple-virtual-dom

## 总结

本文带大家撸了一个 `虚拟DOM`，代码大部分参照 `Vue` 的源码改造，并没有过多的去阐述代码内的运行流程，因为上一篇已经大致讲过了，本文意在抛砖引玉，如有问题还望指出


本文地址 [撸一个简易Virtual Dom](http://www.wclimb.site/2020/03/19/simple-virtual-dom/)
