# 开发 & 运维建议


### 背景

```
1.还记得部署合规生产环境，居然花了一个dev一天的时间去帮忙部署
2.上周部署klg-activity，居然也要2 ~ 3小时才能部署完
3.我认为这样的部署效率太低了
```


### 反思为什么效率这么低？

```
1.用参数方式启动，增加了运维部署的复杂度，运维需要了解每个项目的要用到什么参数，然后逐个逐个填好，才能正常启动
2.项目的技术栈参差不齐，对于运维来说，不能有一个统一方法去处理，甚至是一个项目一个处理方案
```


### 解决方案

```
针对上面的问题，我想到了一个解决方案，可以让运维高效发布项目：

1.不采用参数的方式启动服务器，而是采用node production.js的方式启动，约定启动文件的文件是环境变量，一个环境一份配置文件

下面是必要的目录结构
klg-xxxx
|--app
|--bin
|   └──cli
|   |   └──xxx.js 
|   └──pm2 
|   |   └──production.json
|   |   └──dev.json
|   |   └──test.json
|--config
|   └──production.js
|   └──dev.js
|   └──test.js
|--src
|   └──xxx.ts
|--production.js
|--dev.js
|--test.js
|--package.json

说明：
a) 所有项目，包括nodejs和ts项目，都适用这样的结构，ts项目所有源文件写在src里面，编译后文件放到app里面；nodejs项目直接在app文件编写
b) 根目录下的production.js、dev.js、test.js均为项目启动文件，文件名即为环境名。如node production.js则以生产模式启动项目；node dev.js则以开发模式启动项目...不设置启动参数，所有该环境需要的配置，在config文件夹下对应的文件配置。
c) 项目中所有的依赖包均按照package.json的定义来安装，不单独为某个项目做特例安装全局
d) 用yarn代替npm
e) package.json必需实现以下几个npm命令：build，prod。如果是nodejs项目则build命令可以置为空，但一定要定义。
      └──为什么这么做呢？
	         e-1:为看让运维降低部署的学习成本，项目的技术栈对于运维来说是透明的，运维不需要关心项目用什么技术实现，每次发布只需要git pull、yarn、yarn build、yarn prod，就可以成功发布项目
		 e-2:解释一下为什么要用yarn。因为运维不再关心每次发布是否需要更新npm依赖了，所以每次发布，不需知道package.json文件是否有改动，只要用yarn安装一下即可。当package.json没有变化的情况下，yarn比npm i快10倍以上(yarn最多需要1秒)
f) 开发在发布之前，找运维拿到各个环境的配置，写入相应的配置文件中
g) pm2的配置文件去掉所有启动参数(即拿掉env这个key)

综上：改进之后，不管项目使用什么技术栈，运维部署项目永远只需要4步：
1. git pull
2. yarn
3. yarn build
4. pm2 start bin/pm2/production.json
```
