---
title: 编写一个较为强大的Vue
date: 2020-05-26 15:07:58
tags:
- javascript
- 原创
- vue
- 源码
categories: [javascript,vue]
---

**编写一个较为强大的Vue，支持虚拟DOM、diff更新以及基本的API，项目地址：https://github.com/wclimb/euv**
**demo地址：http://www.wclimb.site/euv/**
## euv

why euv? because:  
```js
'vue'.split('').sort().join('') // euv
```
source:
```js
'node'.split('').sort().join('') // deno
```

## Quick Start

安装
```
git clone https://github.com/wclimb/euv.git
cd euv
npm install
```
运行
```
npm run dev
```


## 目前支持功能

- ✅ `虚拟DOM`
- ✅ `Diff更新`
- ✅ `{% raw %}{{data}}{% endraw %}` or `{% raw %}{{data + 'test'}}{% endraw %}` or `{% raw %}{{fn(a)}}{% endraw %}`
- ✅ `v-for` // `v-for="(item, index) in list"` or `v-for="(item, index) in 10"` or `v-for="(item, index) in 'string'"`
- ✅ `v-if` `v-else-if` `v-else`
- ✅ `v-show`
- ✅ `v-html`
- ✅ `v-model`
- ✅  `@click` `v-on:click` 事件(支持绑定其他事件) `@click="fn('a',$event)"` `@click="fn"` `@click="show = false"` `@click="function(){console.log(1)}"`
- ✅ `methods` 方法
- ✅ `computed` 计算属性
- ✅ `watch` 监听
- ✅ `beforeCreate`、`created`、`beforeMount`、`mounted`、`beforeUpdate`、`updated`
- ✅ `:class`
- ✅ `:style`
- ✅ `$nextTick`

## 补充

`虚拟dom` 不懂的可以看看我之前发的文章(相关代码相比现在有部分改动)：http://www.wclimb.site/2020/03/19/simple-virtual-dom/
