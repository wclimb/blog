---
title: redis简易教程以及使用nodejs连接redis
date: 2019-04-19 15:38:40
tags:
- redis
- Node

categories: [javascript,redis,node,教程]
---

## 前言

一直没机会学习`redis`，最近抽空学了一下，因为知道`reids`还是比较重要的，经常看到有人开发公众号因为没有对`access_token`进行缓存，判断是否过期，导致`access_token`的调用`api`次数超过限制而影响业务的情况，熟悉的人都知道使用`redis`基本上都是做缓存，因为他简单、速度快，可以说是个"快男"。使用`reids`做抽奖也很普遍，有空可以试试。本篇本章暂时只讲`key`、`hash`、`list`

## redis简介

- Redis 是完全开源免费的，遵守BSD协议，是一个高性能的key-value数据库。
- Redis 与其他 key - value 缓存产品有以下三个特点：
  1. Redis支持数据的持久化，可以将内存中的数据保存在磁盘中，重启的时候可以再次加载进行使用。
  2. Redis不仅仅支持简单的key-value类型的数据，同时还提供list，set，zset，hash等数据结构的存储。
  3. Redis支持数据的备份，即master-slave模式的数据备份。

## 为什么要用redis（优势）

1. 性能极高 – Redis能读的速度是110000次/s,写的速度是81000次/s 。
2. 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
3. 原子 – Redis的所有操作都是原子性的，意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过MULTI和EXEC指令包起来。
4. 丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性。

## 安装运行及调试（这里以mac为例）

1. 先去官网下载安装包：http://www.redis.net.cn/download/
2. 解压安装

```
> tar xzf redis-3.0.6.tar.gz
> make
> sudo make install
> cd /usr/local/bin && redis-server // 开启redis服务
> cd /usr/local/bin && redis-cli // 开启redis调试服务
```
开启调试会显示下面的界面，现在你就可以开始使用redis的api了
```
> cd /usr/local/bin && redis-cli
127.0.0.1:6379>
```
<!-- more -->
## 全局api

### 查询键

```
127.0.0.1:6379> keys *
1) "wclimb"
2) "key"
3) "me"
4) "user"
5) "user1"
```

### 键的总数

```
127.0.0.1:6379> dbsize 
(integer) 5
```

### 检查键是否存在

存在返回 1 ，不存在返回 0
```
127.0.0.1:6379> exists wclimb 
(integer) 1
127.0.0.1:6379> exists wclimb1 
(integer) 0
```

### 删除键

返回结果为成功删除键的个数
```
127.0.0.1:6379> del user1 
(integer) 1
```

### 键过期

expire key seconds 当超过过期时间，会自动删除，key在seconds秒后过期
expireat key timestamp 键在秒级时间戳timestamp后过期
pexpire key milliseconds 当超过过期时间，会自动删除，key在milliseconds毫秒后过期
pexpireat key milliseconds-timestamp key在毫秒级时间戳timestamp后过期

```
127.0.0.1:6379> expire user 10   // 10秒后user会被删除
(integer) 1
```

### randomkey 随机返回一个键

```
127.0.0.1:6379> randomkey 
"wclimb"
127.0.0.1:6379> randomkey 
"me"
```

## redis 键（key）

```
set key value [ex] [px] [nx|xx]
ex为键值设置秒级过期时间
px为键值设置毫秒级过期时间
nx键必须不存在，才可以设置成功，用于添加
xx与nx相反，键必须存在，才可以设置成功，用于更新
setnx、setex 与上面的nx、ex作用相同
```

### 设置key(O(1))
```
127.0.0.1:6379> set name 25 
OK
127.0.0.1:6379> keys * 
1) "wclimb"
2) "key"
3) "me"
4) "name"
```

### 获取key(O(1))
```
127.0.0.1:6379> get name 
"25"
```

### 批量设置key

mset key value [key value ......]

```
127.0.0.1:6379> mset test1 1 test2 2
OK
127.0.0.1:6379> get test2
"2"
```

### 追加值(O(1))

```
127.0.0.1:6379> append test2 apend
(integer) 6
127.0.0.1:6379> get test2 
"2apend"
```
### 字符串长度

```
127.0.0.1:6379> strlen test2
(integer) 6
```

## 哈希（hash）

HGET KEY_NAME FIELD_NAME 
类似javscript里的对象 {}

### 设置hash
```
127.0.0.1:6379> HMSET hash name wclimb age 25
OK
```

### 获取hash
```
127.0.0.1:6379> hmget hash name
1) "wclimb"
```
### 删除hash

hdel key field [field ......] 会删除一个或多个field，返回结果为成功删除fiel的个数

```
127.0.0.1:6379> hdel hash name
(integer) 1
127.0.0.1:6379> hmget hash name  // 再获取就返回nil
1) (nil)
```

### 获取所有field

```
127.0.0.1:6379> hkeys hash
1) "age"
127.0.0.1:6379> HMSET hash name wclimb from jiangxi
OK
127.0.0.1:6379> hkeys hash
1) "age"
2) "name"
3) "from"
```

### 获取所有value
```
127.0.0.1:6379> hvals hash
1) "25"
2) "wclimb"
3) "jiangxi"
```

## 列表（list）

| 操作类型   | 操作    | 
| - |  --  | 
|  添加    |   rpush 、lpush、linsert    |  
|   查	    |   lrange、lindex、llen  |   
|  删除    |   lpop 、rpop、 lrem、ltrim   |   
|   修改	    |   lset   |   
|   阻塞操作	    |   blpop、brpop  |   

### 添加

（1）从左边插入元素
lpush key value [value......]
```
127.0.0.1:6379> LPUSH list redis
(integer) 1
```
（1）从右边插入元素
rpush key value [value......]
```
127.0.0.1:6379> RPUSH list test
(integer) 2
```

### 查找

lrange key start end 索引下标从左到右分别是0到N-1，从右到左分别是-1到-N；end选项包含了自身
lrange key 0 -1 可以从左到右获取列表的所有元素
lrange mylist 1 3 获取列表中第2个到第4个元素

```
127.0.0.1:6379> lrange list 0 1
1) "redis"
2) "test"
```

### 长度

```
127.0.0.1:6379> llen key
(integer) 2
```

### 删除

我们先添加几个

```
127.0.0.1:6379> LPUSH list a b c
(integer) 5
```

（1）从列表右侧弹出元素 rpop key

 
（2）从列表左侧弹出元素 lpop key

先看看现在的列表
```
127.0.0.1:6379> lrange list 0 -1
1) "c"
2) "b"
3) "a"
4) "redis"
5) "test"
```

删除
```
127.0.0.1:6379> rpop list 
"test"
```
我们发现test被删除了，现在看看我们的列表
```
127.0.0.1:6379> lrange list 0 -1
1) "c"
2) "b"
3) "a"
4) "redis"
```

### 修改

lset key index newValue 修改指定索引下标的元素

```
127.0.0.1:6379> lset list 0 newValue
OK
127.0.0.1:6379> lrange list 0 -1
1) "newValue"
2) "b"
3) "a"
4) "redis"

```
第0个下标的元素被替换成最新的值

## 使用node连接redis

```
> npm init
> cnpm i reids -S
> touch index.js
> vim index.js
```

### 连接redis

redis npm包链接 https://www.npmjs.com/package/redis

```js
var redis = require('redis');

var client = redis.createClient(6379, '127.0.0.1');
client.on('error', function(err) {
  console.log('Error ' + err);
});
```

### 设置获取key

```js
client.set('user', JSON.stringify({ name: 'wclimb', age: '18' }), redis.print);
client.get('user', function(err, value) {
  if (err) throw err;
  console.log('Got: ' + value);
  client.quit();
});
```
控制台打印

```
> node index.js
Reply: OK
Got: {"name":"wclimb","age":"18"}
```


### 设置获取hash

```js
client.hmset("hosts", "mjr", "1", "another", "23", "home", "1234");
client.hgetall("hosts", function (err, obj) {
  console.dir(obj);
});
```
控制台打印
```
> node index.js
{ mjr: '1', another: '23', home: '1234' }
```

### 设置获取list

```js
client.LPUSH('list', [1, 2, 3, 4], redis.print);
client.lrange('list', '0', '-1', redis.print);
```
控制台打印
```
> node index.js
Reply: 8
Reply: 4,3,2,1,newValue,b,a,redis
```

基本用法和上面讲的都差不多，直接上去一顿写就完事了，完全可以不带脑子的使用各种api