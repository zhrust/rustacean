# BXMr
> rIME-Squirrel 表形码维护工具

## backgroung
作为一名程序猿, 总是要对输入法也要有全面控制

所以, 一直有折腾:
[ZqBXM/mac at master · ZoomQuiet/ZqBXM](https://github.com/ZoomQuiet/ZqBXM/tree/master/mac)

## goal

全面使用 Rust 重构原有 Python 版本的维护指令集


## trace

- 最早是 手工维护
- 后来用 Python 写了个脚本, 但是还是要人工复制到对应目录中再重新编译码表
- 又后来, 使用 invoke 框架拓展并增强了 BXM 码表的维护内部编辑
- 现在, 轮到 Rust 来重构了...


## refer.

- [clap::_derive::_cookbook::git_derive - Rust](https://docs.rs/clap/latest/clap/_derive/_cookbook/git_derive/index.html)
    - 简化官方示例,完成结构性探索
- [Building a CLI from scratch with Clapv3 | by Ukpai Ugochi | Medium](https://medium.com/javascript-in-plain-english/coding-wont-exist-in-5-years-this-is-why-6da748ba676c)
    - 很囧的案例, 看起来很美却根本编译不过...
- ...

## logging

- ...
- 230301 ZQ ...🦀
- 230227 ZQ mod/clap/tracing/... 项目结构厘定
- 230225 ZQ re-re-re-init.







