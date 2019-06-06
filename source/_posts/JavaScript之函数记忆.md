---
title: JavaScript之函数记忆
date: 2018-07-12 15:43:34
tags:
- javascript
- 原创
categories: [javascript]
---

最近在读语言精粹，读到函数记忆这块，觉得有必要记录一下

我们在开发过程中经常使用递归的方式调用函数，但是开发过程中很少有关心性能问题

我们看一下下面这段代码
```js
var count = 0
var f = function(n){
    count++
    return n < 2 ? n : f(n - 1) + f(n - 2);
}
for(var i = 0; i <= 10; i++){
    console.log(i,f(i))
}
console.log('执行次数', count)
```
结果
```js
0 0
1 1
2 1
3 2
4 3
5 5
6 8
7 13
8 21
9 34
10 55
'执行次数', 453
```
执行一遍发现，f这个函数被调用了453次，我们调用了11次，而它自身调用了442次去计算可能已经被刚计算过的值。如果我们让函数具备记忆功能，就可以显著减少运算量。

接下来，我们定义一个memo的数组来保存我们得储存结果，并把它隐藏在闭包中，让该函数能一直访问到这个数组，不被垃圾回收机制回收

```js
var count = 0
var f = function(){
    var memo = [0,1];
    var fib = function(n){
        count++
        var result = memo[n];
        if(typeof result !== 'number'){
            result = fib(n - 1) + fib(n - 2)
            memo[n] = result
        }
        return result
    }
    return fib
}()
for(var i = 0; i <= 10; i++){
    console.log(i,f(i))
}
console.log('执行次数', count)

```
执行结果
```js
0 0
1 1
2 1
3 2
4 3
5 5
6 8
7 13
8 21
9 34
10 55
执行次数 29
```
现在f函数只被调用了29次，我们调用了它11次，它调用了18次去取得之前储存的结果。

先就分享到这吧，关键拓宽思路

GitHub：[wclimb](https://github.com/wclimb)