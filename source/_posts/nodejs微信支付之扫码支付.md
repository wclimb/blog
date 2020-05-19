---
title: nodejs微信支付之扫码支付
date: 2018-02-14 19:23:17
tags:
- Node
- Egg
- javascript
- 原创

categories: [javascript,node,'微信支付',egg]
---
# 前言

本篇文章主要是记录本人在微信扫码支付过程中所遇到的问题，给大家一个借鉴作用，希望对你们有帮助

## 开发环境

- nodejs `v8.1.0`
- egg `v1.1.0`

## 准备工作

- 微信公众号-appid
- 微信商户号-mch_id
- key值(签名算法所需,其实就是一个32位的密码，可以用md5生成一个)(key设置路径：微信商户平台(pay.weixin.qq.com)-->账户设置-->API安全-->密钥设置)

## 扫码支付-统一下单
以下才用的是微信模式二，因为比较简单
<!-- more -->
```js
let MD5 = require('md5'),
  xml2js = require('xml2js'),
  url = "https://api.mch.weixin.qq.com/pay/unifiedorder",// 下单请求地址
  appid = '公众号id',
  mch_id = '微信商户号'；
  notify_url = '回调地址',
  out_trade_no = '自己设置的订单号',// 微信会有自己订单号、我们自己的系统需要设置自己的订单号
  total_fee = '订单金额',// 注意，单位为分
  body = '商品简单描述', 
  trade_type = 'NATIVE',// 交易类型，JSAPI--公众号支付、NATIVE--原生扫码支付、APP--app支付
  nonce_str = moment().format('YYYYMMDDHHmmssSSS'),// 随机字符串32位以下
  stringA = `appid=${公众号id}&body=${body}&mch_id=${微信商户号}&nonce_str=${nonce_str}&notify_url=${
  notify_url}&out_trade_no=${out_trade_no}&spbill_create_ip=${ctx.request.ip}&total_fee=${total_fee}&trade_type=${trade_type}`,
  stringSignTemp = stringA + "&key=xxxxxxxxxxxxxxxxx", //注：key为商户平台设置的密钥key
  sign = MD5(stringSignTemp).toUpperCase();  //注：MD5签名方式
	
```
以上就是我们所需要的一些参数
签名生成算法见[微信官方](https://pay.weixin.qq.com/wiki/doc/api/native.php?chapter=4_3)
spbill_create_ip 是 终端ip地址

下面把所有的参数拼接成xml
```js
let formData = "<xml>";
formData += "<appid>" + appid + "</appid>"; //appid
formData += "<body>" + body + "</body>"; //商品或支付单简要描述
formData += "<mch_id>" + mch_id + "</mch_id>"; //商户号
formData += "<nonce_str>" + nonce_str + "</nonce_str>"; //随机字符串，不长于32位
formData += "<notify_url>" + notify_url + "</notify_url>"; //支付成功后微信服务器通过POST请求通知这个地址
formData += "<out_trade_no>" + out_trade_no + "</out_trade_no>"; //订单号
formData += "<total_fee>" + total_fee + "</total_fee>"; //金额
formData += "<spbill_create_ip>" + ctx.request.ip + "</spbill_create_ip>"; //ip
formData += "<trade_type>NATIVE</trade_type>"; //NATIVE会返回code_url ，JSAPI不会返回
formData += "<sign>" + sign + "</sign>";
formData += "</xml>";
// 这里使用了egg里面请求的方式
const resultData = yield ctx.curl(url, {
  method: "POST",
  content: formData,
  headers: {
    "content-type": "text/html",
  },
});

// xml转json格式
xml2js.parseString(resultData.data, function (err, json) {
  if (err) {
    new Error("解析xml报错");
  } else {
    var result = formMessage(json.xml); // 转换成正常的json 数据
    console.log(result); //打印出返回的结果
  }
});
var formMessage = function (result) {
  var message = {};
  if (typeof result === "object") {
    var keys = Object.keys(result);
    for (var i = 0; i < keys.length; i++) {
      var item = result[keys[i]];
      var key = keys[i];
      if (!(item instanceof Array) || item.length === 0) {
        continue;
      }
      if (item.length === 1) {
        var val = item[0];
        if (typeof val === "object") {
          message[key] = formMessage(val);
        } else {
          message[key] = (val || "").trim();
        }
      } else {
        message[key] = [];
        for (var j = 0, k = item.length; j < k; j++) {
          message[key].push(formMessage(itemp[j]));
        }
      }
    }
  }
  return message;
};
```
上面使用了egg的请求方式，node可以使用request和axios
```js
var request = require('request');
request({
  url: url,
  method: "POST",
  body: formData
}, function(error, response, body) {
  if (!error && response.statusCode == 200) {
  }
}); 
```
如果请求成功会最终返回一个xml,然后我们进行解析成json的格式,里面会有一个`code_url`和`out_trade_no`,我们需要把这两个返回给前端，然后通过生成二维码展示给用户扫码，完成支付

## 监听支付是否成功

上面操作完成之后，我们需要知道用户是否完成支付，因为用户会停留在该页面，我们需要在用户付完款之后，通知用户支付成功。
首先，用户发起支付的时候我们会生成二维码，让用户完成扫码支付，我们还要做的是，开一个定时器，每隔一段时间去发送一个请求，这个时候，我们node后台就需要写一个查询订单的接口，之前我们拿到了`out_trade_no`，也就是我们系统内部的订单号，我们把这个数据发送给后台查询订单的接口，然后后台接收到之后会请求微信的查询接口地址`https://api.mch.weixin.qq.com/pay/orderquery`,流程跟上面一样，只是接口地址和微信返回的xml不一样而已，返回的字段会有一个状态即`SUCCESS`和`NOTPAY`，我们可以通过判断是否支付返回给前端，成功之后提示给用户支付成功，关闭定时器。

## 回调地址

这个是非常重要的一环，大部分的操作其实在上面就可以完成，但是有特殊的情况，比如用户电脑断网发送不了请求，但是手机付款了，这就会导致我们记录不到用户支付的信息。这个时候回调地址就很重要了

### 设置回调地址

微信商户中心->产品中心->开发配置->扫码支付

之后我们需要做的是后端用`post`来接收微信发送的异步回调信息，也是`xml`的格式，这里注意，如果不支持接收xml，可能会得到空的数据
这里还需要注意的是，我们在保存用户支付信息的同时，得先查改订单是否支付，以免重复操作，可能会插入多条记录的情况

## 总结

微信扫码支付坑还是有的，如果你是第一次摸索的话，下面罗列一下需要注意的地方

1. 签名算法要写正确，不然是不会成功的，要拼接正确才行
2. 微信返回的是xml格式的数据，我们得通过插件转成json，这样才方便获取数据
3. 返回的`code_url`要给前端生成二维码用，然后需要开一个定时器查询该订单是否完成支付，最终通知用户结果
4. 回调地址很重要，我们后端需要`post`接收微信返回的回调信息，然后保存信息，不过在保存用户支付信息的之前，我们得知道该订单是否已经保存过，以免重复添加。还有就是返回的是xml的数据，后端一定要保证能够接收得到，按照正常的方式是接收不了的，得额外设置。


## 个人小程序

![img](http://www.wclimb.site/cdn/xcx.jpeg)