---
title: 2020年7月前端面试总结
date: 2020-07-28 11:00:52
tags:
- 面试
- 原创
categories: [面试]
---

## 写在前面
&emsp;&emsp;感觉很久没有更新博客了，这段时间我也没闲着。整个七月感觉就沉浸在面试的海洋里，让人不敢去回想，因为真的是太累了。大概统计了一下，在这个月内总共面试了28轮，面试的公司有58同城、米可世界、CSDN、自如、京东、Boss直聘、美团、字节跳动、百度等（排名按面试时间排），有的面试流程没结束，拒绝了杭州阿里和滴滴的面试机会，因为时间实在来不及，到最后拿了几个Offer，具体哪些就不说了。
&emsp;&emsp;面试大体就这些，现在说一下上家公司，上东家可以说是我任职最久的一家公司，也是技术成长最快的一段时间，涉及到各个方面，这也是我选择来LOOK的原因，非常感谢LOOK的培养。在LOOK我主要负责小程序的开发（H5和Node也写），2C的业务压力也是挺大的，修改就意味了会直接影响用户的体验，即使是通过了测试这一关我也会自己多自测多模拟不同场景、不同用户操作习惯去测试，尽可能做到上线产品高可用。开发小程序也是很苦恼的，小程序做久了感觉就被套牢了，很多在小程序实践的经验并不能放到H5和PC上，费了很大的功夫解决或者hack的一个问题往往也就局限于微信小程序了，对自己技术的提升往往并不大，很大问题也是开发人员解决不了的，受限于微信，太难了😂 😂

## 面试题


遇到的面试题还不少，以下面试题是所有面试杂糅在一起的，就不分公司了，部分是有的是有重复的哈。

1. 虚拟Dom好处
2. 怎么判断数据类型
3. vue怎么强制更新视图
4. for of和for in的区别
5. let const var
6. 说一说bfc
7. rem和em区别
8. 说一下垃圾回收机制
9.  输入url发生了什么
10. vue生命周期
11. vue2.0和3.0实现区别
12. 对象和map的区别
13. 跨域
14. 有哪些数组方法
15. 性能优化
16. 海报图怎么优化
<!-- more -->
17. ssr遇到的问题
18. vue路由钩子用途
19. 错误监控
20. 性能监控
21. 301和302的区别
22. async await原理
23. 说一说cdn
24. cdn的回源机制
25. 搜索框联想如何优化
26. vue双向数据绑定原理
27. 结合lodash说下柯里化函数？（以下有几道题看样子都是如何通过饿了么Node面试的题）
28. 闭包应用的场景？class、symbol是否可以实现私有？闭包中的数据/私有化的数据的内存什么时候释放？
29. promise实现原理？async/await的区别？
30. 标准的 JavaScript 错误常见有哪些？Node.js 中错误处理几种方法？怎么处理未预料的出错? 用 try/catch , 还是其它什么?
31. 现在要你完成一个公用的Dialog组件，说说你封装的思路
32. Vue3.0/React Hooks 了解么简单说下？
33. Require 原理？
34. Es6如何转Es5? 除了babel还有其他方法吗
35. 说下渐进式框架的理解？以及曾开发过的组件库/工具库/脚手架的架构设计方案？
36. 性能调优？webpack对项目进行优化？
37. react和vue的区别
38. cors跨域，简单请求和非简单请求，请求发生到服务器了没有
39. webpack的优化chunk类型的区别
40. vue父子组件生命周期执行顺序
41. http缓存
42. promise链式调用原理
43. webpack写过插件没有
44. 知不知道tree shaking和原理
45. 箭头函数能不能当构造函数，可以使用call绑定吗
46. let变量会不会到window下
47. vue的keep-alive
48. computed和methods的区别
49. async await，错误处理
50. 白屏问题排查
51. 栈和堆的区别
52. toString和toNumber方法
53. 有哪些全局对象
54. 工厂模式
55. 知道垃圾回收机制吗
56. 怎么理解闭包
57. 最近一年的成长
58. cookie、session、localstorage
59. http2.0和1.1比较，多路复用的原理
60. 双向数据绑定的原理
61. 职业规划
62. node怎么创建进程，怎么解决端口冲突问题
63. 宏任务和微任务
64. 小程序印象最深刻的问题
65. 小程序首屏优化
66. 小程序版本更新如何控制
67. 小程序页面值传递
68. css动画用的多吗，有什么觉得做得特别好的
69. 长列表实现虚拟滚动
70. 重排和重绘
71. https原理
72. http1.1和2.0
73. 性能优化
74. 前端加密
75. vue响应式原理
76. vuex原理
77. vue2.0和3.0比较
78. vue包懒加载的原理  babel-plugin-component  
79. 使用过自动化部署吗
80. 前端怎么控制25%跳转到一个页面75%跳转到另外一个
81. 组件通信，父子，组件与组件
82. react的hooks好处，为什么要用他
83. 高阶组件
84. http缓存
85. Node怎么解决多进程端口冲突的问题
86. IPC
87. pm2原理
88. event loop和实际应用
89. node服务高可用
90. koa洋葱模型
91. 为什么要设计成洋葱模型
92. rsp
93. 函数式组件
94. 阅读源码的思路
95. 最近在关注哪些技术
96. 跨域CORS以及简单请求和非简单请求
97. 跨域预检请求会每次都发送吗
98. 跨域怎么自动携带cookie
99.  promise.race原理
100. webpack性能优化
101. webpack的loader执行顺序以及为什么？
102. 说一说loader和plugin
103. 写过loader和plugin吗
104. 进程和线程的关系
105. js是单线程的，node为什么选择
106. 说一下mixin
107. nuxt渲染原理
108. nuxt渲染会重新生成虚拟dom吗
109. nuxt的QPS
110. nuxt渲染时间
111. vue的computed原理
112. vue组件通信
113. 怎么做性能监控的
114. 怎么做错误处理和上报的
115. 知道公司具体用户数据吗
116. 怎么发现某些bug影响到了用户使用，然后如何解决的
117. 后端如果空指针你怎么处理的
118. 白屏问题怎么解决的
119. 你是如何禁止滚动条的
120. 怎么判断两个对象是否一样
121. webpack熟悉吗？loader和plugin你怎么理解的
122. 怎么做到产品高可用
123. 任何衡量用户体验指标
124. 你在公司印象最深刻的问题或者自豪的地方
125. 你有什么想问我的？
126. 说一说继承
127. 如何设计下拉框
128. 如何提高首屏效率
129. webpack优化
130. git merge和git rebase区别
131. git怎么回滚代码
132. 流式布局
133. rem原理


总结一下：
1. HTTP的必问，但是三次握手这种没问过，会问HTTP缓存、HTTPS、1.0 1.1 2.0区别和部分原理
2. webpack必问，不仅限 理解和写loader和plugin、webpack优化
3. 如果你是Vue技术栈，那双向数据绑定的原理、虚拟DOM、Diff算法、组件通信、conputed原理、封装组件大概率都会问
4. promise出场率也很高，有可能需要你手写
5. 浏览器渲染原理建议多看看，经常问输入URL发生了什么
6. 如果提到Node，那建议你去看看Node深入浅出Node.js，可能涉及到错误处理、require原理、pm2原理、怎么开多进程、多进程端口冲突问题
7. 如果提到Koa，那必然会说到洋葱模型，执行顺序

## 实操题


1. 编写代码：手写一个重试函数，retry(fnPromise,count);count重试次数，并返回一个新的promise
2. 手写es5、es6继承
3. 手写深拷贝
4. 手写防抖
5. 手写promise
6. flex布局，有三个div，1靠左 3 靠最右 2 在1的下面
7. 手写封装Vue组件
8. css实现环形进度条
9. 提取query参数并解析

还有好几个有点忘记了
  
    
## 算法题

1. 50个人，30个会java 40个会前端，38个会app，问存在三个都会的情况吗？
2. 100个球，两个人拿，最多一次拿1-5个，你先拿，怎么控制你最后拿
3. 算法题，abc acb 判断是否一样，可以交换位置，复杂度分析
4. 链表反转
5. 求链表的倒数第K个值
6. 大数相加
7. 用递归实现数组反转，不能使用额外参数和变量

额，感觉自己刷了一段时间的`Leetcode`基本没用上啊，二叉树一个没考哈哈😄😄，剑指offer和动态规划也刷了不少。
总结一下链表可能会考的：
1. 反转链表
2. 求链表的倒数第K个值
3. 删除链表的倒数第K个值
4. 判断链表是否有环

## 吐槽和思考

### 吐槽

&emsp;&emsp;美团一二面都面了快一个半小时，聊得也很愉快，面试官的反馈也不错，美团三面只面试了20-30分钟，聊得不是很愉快，感觉面试官有点先入为主，可能因为我不是科班出身吧，问了几个问题感觉像走过场，有点为难人，后面还跟我说前端入门容易，吧啦吧啦。。。这我不反驳，主要是给我的感觉就像有点瞧不起人？说完问我`JS`最大值是多少，我说2^53-1，他说为什么，我解释了因为`IEEE754`浮点数二进制表示法，使用的是双精度，然后继续问我这些知识是从哪学的，啊这，阿sir不是吧，感觉我给人感觉就应该不知道呗，面完给我的感觉真的很差劲！！！

### 思考

&emsp;&emsp;前端算法题考的还是比较少的，面试除了考基础之外，更加关心你怎么处理错误，怎么收集这个过程，怎么衡量指标对产品的影响，另外数据很重要，需要有数据来支撑你的结论，而不是肉眼感官的。另外面试已经开始问`Vue3.0`了，一方面面试官考察你是否热衷技术，追求新技术，另一方面考察你的理解能力，为什么要用它，解决了什么问题。
&emsp;&emsp;简历上尽可能写你会的，不要学了一点运行了一下`Demo`就往上写，面试官不了解你，只能从简历上去深挖你的技术能力，最好不要把没有做的事情说自己做了，到时候问到你大家都很尴尬，尽可能把面试官引导到你擅长的地方，比如你看了`Vue`的源码，那你可以秀一下。尽可能的多说，一个小的问题你看得比别人远，这就是你的优势，比如面试官问你：如果判断一个变量的类型，额🤔，直接 `Object.prototype.toString.call()` ，好像没什么问题，但是你可以接着说，如果想判断数组可以使用`Array.isArray()`，还有就是之前判断类型是不准的，使用`Object.prototype.toString.call`通常可以获取到特定的类型标签，为什么能访问，是因为`js`内置了`toStringTag`（`Symbol.toStringTag`），即便没有 `toStringTag` 属性，也能被 `toString()` 方法识别并返回特定的类型标签，我们可以通过伪造：
```js
 let obj = {[Symbol.toStringTag]: 'foo', a: 1}
 Object.prototype.toString.call(obj); // [object foo]
```
然后你可以继续说你是通过看`Koa`的源码学习到的，里面依赖了一个包 [is-generator-function](https://github.com/inspect-js/is-generator-function) 做了特殊的处理，你看这样回答下来这个问题是不是更好一点？（当然这是我的经历）虽然占用一点时间，但是让面试官觉得你是一个好学的人，能做得更好不是？

## 最后

最后拾人牙慧一波，要有敬畏之心，要把自己卑微到尘埃，广积粮、高筑墙、缓称王。选择一个方向，冲就完事了！！！
