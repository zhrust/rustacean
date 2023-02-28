# 开发
> projects ...


## background
> 无奈背景

开发语言学习, 不用来开发真实项目, 基本是表演学习行为了...

## goal
> 必要目标

一组日常要用工具, 原创/再制/...

关键是积累一组可用作品, 打底儿.

## trace
> 具体推进

MVP ~ 最小可行工程能力?

- [ ] 工程结构管理
    - [ ] crate/library/pakage/workspace/project 划分和使用
        - [x] package ~ cargo new 出来的东西
        - [x] crate ~ src/*.rs 
            - 二进制包
                - `src/main.rs` 
                - `src/bin/*.rs` 
        - [x] library ~ src/lib.rs
        - [x] module ~ mod 圈定的代码块
                - 绝对/相对引用路径
                - self/super/crate/... ~> [super 和 self - 通过例子学 Rust 中文版](https://rustwiki.org/zh-CN/rust-by-example/mod/split.html)
                - rustc 1.30+ 要求:
                    - 同级目录创建 mod 名同名目录
                    - 在其中创建子模块.rs 文件
                    - 此时才能在 mod 名同名 .rs 中使用 mod 来引用
                - lib.rs ~ 检索更方便
                - crates.rs ~ 下载最稳定
        - [x] use 和可见性...
            - 结构体和枚举的可见性...[结构体的可见性 - 通过例子学 Rust 中文版](https://rustwiki.org/zh-CN/rust-by-example/mod/struct_visibility.html#%E5%8F%82%E8%A7%81)
            - 优先使用最细粒度(引入函数、结构体等)的引用方式，如果引起了某种麻烦(例如前面两种情况)，再使用引入模块的方式
            - 不同模块同名 as 别名引用
            - use xxx::{self, yyy}; ~ 集成引用
            - use std::collections::*; ~ 只用来引入 tests
            - pub use ~ 引入后再导出(所有权无处不在...)
            - pub(in crate::a) ... 限制可见性语法
                - pub 意味着可见性无任何限制
                - pub(crate) 表示在当前包可见
                - pub(self) 在当前模块可见
                - pub(super) 在父模块可见
                - pub(in <path>) 表示在某个路径代表的模块中可见，其中 `path` 必须是父模块或者祖先模块
              - ~> [使用 use 引入模块及受限可见性 - Rust语言圣经(Rust Course)](https://course.rs/basic/crate-module/use.html#%E9%99%90%E5%88%B6%E5%8F%AF%E8%A7%81%E6%80%A7%E8%AF%AD%E6%B3%95)
        - [ ] workspace
        - [ ] project
    - [ ] 模块切分/命名..艺术?
- [ ] 基本应用
    - [x] 基本调试循环 ~ 配合 tracing 和 log 目录...
    - [ ] 基本单元测试
    - [x] 基本编译发行 ~ cargo build
- [ ] 分布式系统
    - [ ] 调试/追踪
    - [ ] CI/CD
    - [ ] ...
- [ ] 核心概念/技能
    - [ ] 内建数据类型
    - [ ] 智能指针
    - [ ] 所有权和借用
    - [ ] 泛型
    - [ ] trait
    - [ ] 生命周期
- [ ] 高级工程技巧
    - [ ] 宏
    - [ ] GDB
    - [ ] ...

## refer.
> 关键参考

- [介绍 - Rust 的绅士介绍](https://llever.com/gentle-intro/readme.zh.html)
- ...

## logging
> 版本记要

- ..
- 221023 ZQ init.
