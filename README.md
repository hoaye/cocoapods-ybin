[![Gem Version](https://badge.fury.io/rb/cocoapods-ybin.svg)](https://badge.fury.io/rb/cocoapods-ybin)

# 一、背景

&emsp;&emsp;随着项目业务的不断迭代和新增，每个业务线负责不同的功能模块，组件化势必是需要进行的工作。业界内，无论是哪种组件化方案，目的是一样的，分离业务和功能。

&emsp;&emsp;组件化虽好，但是组件化只是将不同的业务分离或者不同的功能分离和分层，实际上还是在一个代码池里每次 **build** 需要进行编译、汇编、链接等过程。每次编译的占用的时间还是挺奢侈的，在编译速度上并没有提升。**pod install** 来回切换二进制和源码也更是一件可行不可取的开发模式。

&emsp;&emsp;**cocoapods-ybin** 解决二进制和源码之间的映射问题，无需来回切换源码，实现二进制断点可进入源码进行调试。实现原理是简单的，但区别于 **Android** 里的 **aar** 或 **jar** 内的 Class 文件。

**cocoapods-ybin** 满足以下几个诉求考虑实现：

- **小而好用、低成本接入**
- **与二进制库的制作和存储无关，只需二进制库和源码存储位置即可映射**
- **同时支持多项目并行开发**
- **只存储一份源码**
- **无需频繁的 clone 代码**

# 二、先睹为快

**cocoapods-ybin-demo** 示例效果视频，[示例代码地址](https://github.com/monetking/cocoapods-ybin-demo.git)

<video id="video" width="756" height="426" controls="" preload="none" poster="https://img.58cdn.com.cn/dist/rn/course/ybin_demo_cover.png">
      <source id="mp4" src="https://img.58cdn.com.cn/dist/rn/course/ybin_demo_small.mp4" type="video/mp4">
      </video>

# 三、安装

## 3.1 直接安装

```bash
$ sudo gem install cocoapods-ybin
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif1jwrswjj30v608owfm.jpg)

## 3.2 使用 Gemfile 管理 pod 版本

添加 **cocoapods-ybin** 到 Gemfile 文件

```ruby
gem 'cocoapods-ybin'
```

## 3.3 安装校验

执行命令 **pod --help** 查看当前 pod 版本 **ybin** 是否安装成功。

```bash
$ pod --help
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif1oynpxyj312e0u07bm.jpg)

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif1zrynuhj30s60f8gn8.jpg)

# 四、使用教程


打开示例项目 **ocoapods-ybin-demo** [示例代码](https://github.com/monetking/cocoapods-ybin-demo.git) 的 Podfile 目录。示例项目使用了 **Bundler** 对 pod 的版本进行了控制，实际项目根据所需选择是否采用，与本插件无关联，请酌情选择。

## 4.1 执行二进制和源码映射指令

```bash
$ pod ybin link 二进制库名称
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif1sqf7erj317r0u044q.jpg)

## 4.2 查看已映射列表

```bash
$ pod ybin link --list
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif21izjaxj30xq09k0uh.jpg)

## 4.3 删除某个或多个源码映射

```bash
$ pod ybin link --remove 二进制库名称1 二进制库名称2
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif22c9z9gj313a0dewgy.jpg)

## 4.4 删除所有源码映射

```bash
$ pod ybin link --remove-all
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif23vf5mzj30xq0fadhy.jpg)

## 4.5 查询项目使用 Pod 管理的版本

查询项目通过Pod管理的组件库版本号，一般都是 cat Podfile.lock 文件，目视解析版本及依赖版本。阅读起来非常不友好，使用插件 **--lib-version** 扩展即可快速查看 Pod 管理的版本。

```bash
$ pod ybin link --lib-version
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gif25icgfjj30xq0cmtay.jpg)

# 五、期待

- 如果在使用过程中遇到Bug，希望您能Issues我，谢谢(或者尝试下载使用最新版本看看Bug修复没有)
- 如果在使用过程中发现功能不够用，希望你能Issues我，非常想为这个工具增加更多好用的功能，谢谢
- 如果你想为cocoapods-ybin输出代码，请拼命Pull Requests我


