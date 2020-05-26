---
title: HTTP缓存——304与200 from cache
date: 2018-03-06 14:04:29
tags:
- HTTP
- 缓存
- Mysql
- javascript
- 原创

categories: [HTTP]
---

# HTTP与缓存相关的字段

## 1. 通用字段

| 字段名称   | 释义    | 
| - |  --  | 
|   Cache-Control    |   控制缓存具体的行为    |  
|   Pragma    |   HTTP1.0时的遗留字段，当值为"no-cache"时强制验证缓存    |   
|   Date    |   创建报文的日期时间(启发式缓存阶段所用)    |   

## 2. response字段

| 字段名称   | 释义    | 
| -- |  --  | 
|   ETag    |   服务器生成资源的唯一标识    |  
|   Vary    |   代理服务器缓存的管理信息    |   
|   Age    |   资源在缓存代理中存贮的时长(取决于max-age和s-maxage的大小)    |   

## 3. request字段

| 字段名称   | 释义    | 
| -- |  --  | 
|   If-Match    |   条件请求，携带上一次请求中资源的ETag，服务器根据这个字段判断文件是否有新的修改    |  
|   If-None-Match    |   和If-Match作用相反，服务器根据这个字段判断文件是否有新的修改    |   
|   If-Modified-Since    |   比较资源前后两次访问最后的修改时间是否一致   | 
|   If-Unmodified-Since    |   比较资源前后两次访问最后的修改时间是否一致  | 

## 4. 实体字段

| 字段名称   | 释义    | 
| -- |  --  | 
|   Expires    |   告知客户端资源缓存失效的绝对时间|  
|   Last-Modified    |   资源最后一次修改的时间    |   


## 协商缓存（304）

> If-modified-Since/Last-Modified

- 浏览器在发送请求的时候服务器会检查请求头`request header`里面的`If-modified-Since`，如果最后修改时间相同则返回304，否则给返回头(`response header`)添加`last-Modified`并且返回数据(`response body`)。
```
if-modified-since:Wed, 31 May 2017 03:21:09 GMT
if-none-match:"42DD5684635105372FE7720E3B39B96A"
```
<!-- more -->

> If-None-Match/Etag

- 浏览器在发送请求的时候服务器会检查请求头(`request header`)里面的`if-none-match`的值与当前文件的内容通过hash算法（`例如 nodejs: cryto.createHash('sha1')`）生成的内容摘要字符对比，相同则直接返回`304`，否则给返回头(`response header`)添加`etag`属性为当前的内容摘要字符，并且返回内容。
```
etag:"42DD5684635105372FE7720E3B39B96A"
last-modified:Wed, 31 May 2017 03:21:09 GMT
```

请求头last-modified的日期与响应头的last-modified一致
请求头if-none-match的hash与响应头的etag一致
所用会返回`Status Code: 304 `

## 强缓存（200 from cache）


- 如果设置了`Expires`(XX时间过期)或者`Cache-Control（http1.0不支持）`(经历XX时间后过期)且没有过期，命中`cache`的情况下，`from cache`不去发出请求。如果强刷（如ctrl+r）会发起请求，但是如果没有修改会返回`304`内容未修改，如果已经改变则返回新内容。`max-age > Expires`。

- `expires/cache-control `虽然是强缓存，但用户主动触发的刷新行为，还是会采用缓存协商的策略，主动触发的刷新行为包括点击刷新按钮、右键刷新、f5刷新、ctrl+f5刷新等。

- 当然如果在控制台里面选中了`disable cahce`则无论如何都会请求最新内容(304协商缓存、强缓存都无效)，因为1.不会检查本地是否有缓存。2.请求头信息(request header)既没有If-Modified-Since也没有If-None-Match来让服务端判断。地址栏输入的地址按下回车键，该地址页面请求（仅仅是该url）的`request header`都会带上`cache-contro:max-age=0`，所以不会命中强缓存，但是通过链接点击的地址会命中缓存

- chrome下查看所有的from cache文件：chrome://view-http-cache/

## 区别

- 触发 200 from cache：

1. 直接点击链接访问
2. 输入网址按回车访问
3. 二维码扫描

- 触发 304：

1. 刷新页面时触发
2. 设置了长缓存、但Entity Tags没有移除时触发


## 流程图
![流程图](http://www.wclimb.site/cdn/cache.png)

GitHub：[wclimb](https://github.com/wclimb)


## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)










