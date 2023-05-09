# Rust 课程笔记

## background
Rust 社区很给力各种渠道中,有各种教程,
只是, 每个教程都有自己的特点和盲区...


## goal
高速刷过时, 见到有趣/有用/有种的片段, 收集摘录在一起, 形成自己的小抄...

## trace

### init.
Recommended tools:

- [ ] cargo readme - to regenerate README.md based on template and lib.rs comments
- [ ] cargo insta - to review test snapshots
- [ ] cargo edit - to add/remove dependencies
- [ ] cargo fmt - to format code
- [ ] cargo clippy - for all insights and tips
    - 安装：rustup component add clippy
    - 参考: [Rustup Book学习笔记 | Rust学习笔记](https://skyao.io/learning-rust/docs/build/rustup/rustup-book.html)
    - 如果出问题:
        - [Fresh install on macos can't install rustfmt and clippy using rustup · Issue #1558 · rust-lang/rustup](https://github.com/rust-lang/rustup/issues/1558)
        - rustup toolchain remove stable && rustup toolchain install stable
        - ...
```
info: syncing channel updates for 'stable-x86_64-apple-darwin'
info: latest update on 2023-02-09, rust version 1.67.1 (d5a82bbd2 2023-02-07)
info: downloading component 'cargo'
info: downloading component 'clippy'
info: downloading component 'rust-docs'
info: downloading component 'rust-std'

...

  stable-x86_64-apple-darwin installed - rustc 1.67.1 (d5a82bbd2 2023-02-07)

info: checking for self-updates
```
- [ ] cargo fix - for fixing warnings

#### 检验和切换工具链
~ [Learn\-Rust\-by\-Building\-Real\-Applications/memory\_management at master · gavadinov/Learn\-Rust\-by\-Building\-Real\-Applications](https://github.com/gavadinov/Learn-Rust-by-Building-Real-Applications/tree/master/memory_management)

查实当前使用的工具链:
> rustup toolchain list

安装指定工具链:

> rustup toolchain install nightly-x86_64-unknown-linux-gnu

#### 宏查阅
~ [dtolnay/cargo\-expand: Subcommand to show result of macro expansion](https://github.com/dtolnay/cargo-expand)

使用:

> crago expand

在终端中展开宏并打印...如果工程大点儿, 就不可看了...


### project

#### CLI
~ [A command line app in 15 minutes - Command Line Applications in Rust](https://rust-cli.github.io/book/tutorial/index.html)

还是老习惯, CLI->RESTful->GUI-> ...




### debug

#### dbg!()

类似 ic 的工具, 可以随时插入代码, 并在运行时打印对应变量名和值...


### testting

### coding


## refer:
> Udemy

- [The Complete Rust Programming Course \| Udemy](https://www.udemy.com/course/rust-programming-the-complete-guide/)
- [Learn Rust by Building Real Applications \| Udemy](https://www.udemy.com/course/rust-fundamentals/)
    - 用了一半篇幅来介绍内存管理模型,以及 GDB 观察过程...


> Youtube

- 110+[Rust 编程语言入门教程 \[2021\] \- YouTube](https://www.youtube.com/playlist?list=PL3azK8C0kje1DUJbaOqce19j3R_-tIc4_)
    - 42+[RUST PROGRAMMING TUTORIALS \- YouTube](https://www.youtube.com/playlist?list=PLVvjrrRCBy2JSHf9tGxGKJ-bYAN_uDCUL)
    - 44+[Intro to Rust \- YouTube](https://www.youtube.com/playlist?list=PLJbE2Yu2zumDF6BX6_RdPisRVHgzV02NW)
    - 14+[Rust For Starters \- YouTube](https://www.youtube.com/playlist?list=PLKkEWK6xRmes17LQUEA5bNjYISuCEOTXx)
- 44+[The Rust Lang Book \- YouTube](https://www.youtube.com/playlist?list=PLai5B987bZ9CoVR-QEIN9foz4QCJ0H2Y8)
- 25+[Rust Projects \- YouTube](https://www.youtube.com/playlist?list=PLJbE2Yu2zumDD5vy2BuSHvFZU0a6RDmgb)
    - 24+[50 RUST Projects \- YouTube](https://www.youtube.com/playlist?list=PL5dTjWUk_cPYuhHm9_QImW7_u4lr5d6zO)
- [Jon Gjengset \- YouTube](https://www.youtube.com/@jonhoo)
    - [Rust live\-coding \- YouTube](https://www.youtube.com/playlist?list=PLqbS7AVVErFgY2faCIYjJZv_RluGkTlKt)
        - 都是几个小时的连续调试过程
    - [Crust of Rust \- YouTube](https://www.youtube.com/playlist?list=PLqbS7AVVErFiWDOAVrPt7aYmnuuOLYvOa)






```
      _~`|-~_
  \/ /  - =  \ \/
    '_   ⏝   _'
    ( '--~--' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```

