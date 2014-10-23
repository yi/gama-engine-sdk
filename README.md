# THis project has been deprecated. Please refer to [gama.lua](https://github.com/GamaLabs/gama.lua)

# Gama 客户端渲染引擎 ActionScript 版本

## 目录结构和安排

```
 [src]  ---   源文件目录
 [lib]  ---   开发阶段 gama.swc 的存在目录。这个目录已经被忽略(git ignored)，所以不应该被提交到 git 
 [bin]  ---   可发布版本的 gama.swc 的存在目录
```

## Gama 客户端渲染引擎的设计思路

### 一个入口类

对 SDK 的方法的调用全部在 Gama 这一个类中提供。

### 一个接口 Interface

IRenderableRect 接口是用户和SDK之间进行沟通的唯一基础接口。 Gama 所做的是全就是负责载入和渲染各类 IRenderableRect 的实现。而用户所做的事情就是根据开发需求实现各种各样的 IRenderableRect。

这样的设计目的是让 SDK 和 用户 之间有一个泾渭分明的责任线，避免SDK的过度开发。

### 扁平的代码结构

源代码的类的组织采用完全扁平的结构，这是为了：

 * 支持一个入口类
 * 利于 swc 的混淆和发布。在一个包内，互相采用 internal 方法，而不把内部实现方法外露
