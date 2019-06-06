---
title: gulp基础教程
date: 2017-06-27 15:49:53
tags:

- gulp
- 原创

categories: [javascript,gulp]

---

## 入门指南--引用gulp官网示例 

> 全局安装 gulp：

```js
$ npm install --global gulp
```
> 作为项目的开发依赖（devDependencies）安装：

```js
$ npm install --save-dev gulp

```

> 在项目根目录下创建一个名为 gulpfile.js 的文件：

<!-- more -->

```js
var gulp = require('gulp');

gulp.task('default', function() {
  // 将你的默认的任务代码放在这
});

```

> 运行 gulp

```
$ gulp  //默认的名为 default 的任务（task）将会被运行，在这里，这个任务并未做任何事情。

```

至此，一个简单的gulp已经完成，接下来让我们来完善部分功能

##  gulp功能完善

### 生成package.json文件

```
$ npm init //一直回车，有需要的可以设置
```

### 安装所需包

> 使用淘宝镜像

```js
$ npm install -g cnpm --registry=https://registry.npm.taobao.org
示例 $ cnpm install [name]

```
接着
```js
$ cnpm i browser-sync gulp gulp-clean-css gulp-imagemin gulp-rename  gulp-sass gulp-uglify gulp.spritesmith gulp-autoprefixer --save
```
### 新建gulpfile.js文件

添加
```js
var gulp         = require('gulp'); 
var browserSync  = require('browser-sync').create(); //通过流的方式创建任务流程, 这样您就可以在您的任务完成后调用reload，所有的浏览器将被告知的变化并实时更新
var sass         = require('gulp-sass'); //sass转css
var reload       = browserSync.reload; 
var minifyCSS    = require('gulp-clean-css')  //css压缩
var uglify       = require('gulp-uglify') //js压缩
var imagemin     = require('gulp-imagemin') //图片压缩
var rename       = require('gulp-rename') //文件重命名
var autoprefixer = require('gulp-autoprefixer') //自动添加前缀

```


### 设置默认文件地址

```js
code为文件夹，里面存放html css js文件
var src = {
    scss: 'code/scss/*.scss',
    css:  'code/css/*.css',
    html: 'code/*.html',
    js:   'code/js/*.js',
    images: 'code/images/*.{png,jpg,gif,ico}'
};

```

### gulp.task(name[, deps], fn)  

```js
name: 任务的名字
deps: 一个包含任务列表的数组，这些任务会在你当前任务运行之前完成。
fn: 该函数定义任务所要执行的一些操作。通常来说，它会是这种形式：gulp.src().pipe(someplugin())。

// 静态服务器 + 监听 scss/html 文件
 gulp.task('serve', ['sass'], function() {
    browserSync.init({
        server: "./code"
    });

    gulp.watch(src.scss, ['sass']);
    gulp.watch(src.css, ['css']);
    gulp.watch(src.images, ['images'])
    gulp.watch(src.js, ['js']);
    gulp.watch(src.html).on('change', reload);

});

```
###  scss编译后的css将注入到浏览器里实现更新

```js
gulp.task('sass', function() {
    return gulp.src(src.scss)
        .pipe(sass())
        .pipe(minifyCSS({
            advanced: false,//类型：Boolean 默认：true [是否开启高级优化（合并选择器等）]
            compatibility: 'ie7',//保留ie7及以下兼容写法 类型：String 默认：''or'*' [启用兼容模式； 'ie7'：IE7兼容模式，'ie8'：IE8兼容模式，'*'：IE9+兼容模式]
            keepBreaks: true,//类型：Boolean 默认：false [是否保留换行]
            keepSpecialComments: '*'
            //保留所有特殊前缀 当你用autoprefixer生成的浏览器前缀，如果不加这个参数，有可能将会删除你的部分前缀
        }))
        .pipe(autoprefixer())
        .pipe(rename({suffix: '.min'}))
        .pipe(gulp.dest("code/css"))
        .pipe(reload({stream: true}));
});

```

### 雪碧图（有需要可以尝试）

```js
var spritesmith = require('gulp.spritesmith');
 
 gulp.task('sprite', function () {
      return gulp.src('code/images/*.png')
         .pipe(spritesmith({
             imgName:'images/sprite20161010.png',  //保存合并后图片的地址
             cssName:'css/sprite.css',   //保存合并后对于css样式的地址
             padding:20,
             algorithm:'binary-tree',
         }))
         .pipe(gulp.dest('code/scss'));
 });

```

### 监听css文件

```js
gulp.task('css', function() {
    return gulp.src(src.css)
        .pipe(minifyCSS())
        .pipe(rename({suffix: '.min'}))
        .pipe(gulp.dest("code/css"))
        .pipe(reload({stream: true}));
});

```

### 监听js文件

```js
gulp.task('js', function() {
    // 1. 找到文件
    return  gulp.src(src.js)
        //2. 压缩文件
        .pipe(uglify())
        .pipe(rename({suffix: '.min'}))
        //3. 另存压缩后的文件
        .pipe(gulp.dest('code/dest'))
        .pipe(reload({stream: true}));
})


```
### 压缩图片任务

```js
// 在命令行输入 gulp images 启动此任务
gulp.task('images', function () {
        // 1. 找到图片
        gulp.src(src.images)
        // 2. 压缩图片
        .pipe($.imagemin())
        // 3. 另存图片
        .pipe(gulp.dest('images'))
        .pipe(reload({stream: true}));
});

```

### 最后控制台输入gulp执行

```js
gulp.task('default', ['serve']);

```
---

如果觉得帮助到了你，欢迎star -> https://github.com/wclimb/wclimb.github.io

---

## 完整代码


### 文件目录

```
-code
    -imgage
       1.png
    -css
       default.css
    -scss
       default.scss
    -js
       default.js
    index.html
gulpfile.js
package.json

```
### package.json

```js
{
  "name": "gulp-test",
  "version": "1.0.0",
  "description": "Gulp & SASS",
  "main": "gulpfile.js",
  "scripts": {
    "start": "gulp"
  },
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "browser-sync": "^2.2.0",
    "gulp": "^3.9.1",
    "gulp-clean-css": "^3.0.3",
    "gulp-imagemin": "^3.1.1",
    "gulp-rename": "^1.2.2",
    "gulp-sass": "^3.1.0",
    "gulp-uglify": "^2.0.1",
    "gulp.spritesmith": "^6.4.0",
    "gulp-autoprefixer": "^4.0.0"
  },
  "dependencies": {
    
  }
}

```

### gulpfile.js

```js
var gulp         = require('gulp'); 
var browserSync  = require('browser-sync').create(); //通过流的方式创建任务流程, 这样您就可以在您的任务完成后调用reload，所有的浏览器将被告知的变化并实时更新
var sass         = require('gulp-sass'); //sass转css
var reload       = browserSync.reload; 
var minifyCSS    = require('gulp-clean-css')  //css压缩
var uglify       = require('gulp-uglify') //js压缩
var imagemin     = require('gulp-imagemin') //图片压缩
var rename       = require('gulp-rename') //文件重命名
var autoprefixer = require('gulp-autoprefixer') //自动添加前缀


var src = {
    scss: 'code/scss/*.scss',
    css:  'code/css/*.css',
    html: 'code/*.html',
    js:   'code/js/*.js',
    images: 'code/images/*.{png,jpg,gif,ico}'
};

// 静态服务器 + 监听 scss/html 文件
 gulp.task('serve', ['sass'], function() {
    browserSync.init({
        server: "./code"
    });

    gulp.watch(src.scss, ['sass']);
    gulp.watch(src.css, ['css']);
    gulp.watch(src.images, ['images'])
    gulp.watch(src.js, ['js']);
    gulp.watch(src.html).on('change', reload);

});


// scss编译后的css将注入到浏览器里实现更新
gulp.task('sass', function() {
    return gulp.src(src.scss)
        .pipe(sass())
        .pipe(minifyCSS({
            advanced: false,//类型：Boolean 默认：true [是否开启高级优化（合并选择器等）]
            compatibility: 'ie7',//保留ie7及以下兼容写法 类型：String 默认：''or'*' [启用兼容模式； 'ie7'：IE7兼容模式，'ie8'：IE8兼容模式，'*'：IE9+兼容模式]
            keepBreaks: true,//类型：Boolean 默认：false [是否保留换行]
            keepSpecialComments: '*'
            //保留所有特殊前缀 当你用autoprefixer生成的浏览器前缀，如果不加这个参数，有可能将会删除你的部分前缀
        }))
        .pipe(autoprefixer())
        .pipe(rename({suffix: '.min'}))
        .pipe(gulp.dest("code/css")) //重新输出数据到某个文件夹，如果没有就会自动创建
        .pipe(reload({stream: true}));
});


// 雪碧图（有需要可以尝试）
//var spritesmith = require('gulp.spritesmith');
 
// gulp.task('sprite', function () {
//     return gulp.src('code/images/*.png')
//         .pipe(spritesmith({
//             imgName:'images/sprite20161010.png',  //保存合并后图片的地址
//             cssName:'css/sprite.css',   //保存合并后对于css样式的地址
//             padding:20,
//             algorithm:'binary-tree',
//         }))
//         .pipe(gulp.dest('code/scss'));
// });


gulp.task('css', function() {
    return gulp.src(src.css)
        .pipe(minifyCSS())
        .pipe(rename({suffix: '.min'}))
        .pipe(gulp.dest("code/css"))
        .pipe(reload({stream: true}));
});


gulp.task('js', function() {
    // 1. 找到文件
    return  gulp.src(src.js)
        //2. 压缩文件
        .pipe(uglify())
        .pipe(rename({suffix: '.min'}))
        //3. 另存压缩后的文件
        .pipe(gulp.dest('code/dest'))
        .pipe(reload({stream: true}));
})



// 压缩图片任务
// 在命令行输入 gulp images 启动此任务
gulp.task('images', function () {
        // 1. 找到图片
        gulp.src(src.images)
        // 2. 压缩图片
        .pipe($.imagemin())
        // 3. 另存图片
        .pipe(gulp.dest('images'))
        .pipe(reload({stream: true}));
});


gulp.task('default', ['serve']);

```