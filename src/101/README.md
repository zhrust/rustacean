# 学习
> learnning ...


## background
> 可能背景

和其它语言不同, Rust 有太多公开的秘密,如果不能快速先习惯一批,
很难写出可以运行的软件来...

## goal
> 必要目标

最常用的那 20% Rust 常识...以便解决 80% 应用场景

## trace
> 具体推进

- [ ] 基本概念
    - [x] 所有权/借用/作用域
    - [x] Option
    - [x] Box
    - [ ] ...
- [ ] 核心数据结构,及其常用操作
- [ ] 推荐工程结构 ~> [Clear explanation of Rust’s module system](https://www.sheshbabu.com/posts/rust-module-system/)
    - [ ] crate 以及内部模块管理
    - [x] logging
        - tracing = "0.1"
        - clia-tracing-config = "0.2"
- [ ] 实用开发/调试流程
    - [x] MVP/ CLI 工程
    - [ ] MVP/ web 工程
    - [ ] MVP/ 微服务
    - [ ] MVP/ 系统服务
    - [ ] ...
- [ ] 实效 TDD 流程
- [ ] 底层调试技巧: gdb ...



## refer.
> 各种参考


必刷练习:

- [GitHub - rust-lang/rustlings: Small exercises to get you used to reading and writing Rust code!](https://github.com/rust-lang/rustlings) ~ 官方大佬亲自编撰的...形式上也充分利用了 Cargo 工具链, 非常的锈...
- [Rust Quiz #1](https://dtolnay.github.io/rust-quiz/1)
- [Rust on Exercism](https://exercism.org/tracks/rust)
- ...


### 自锈路径

- [Resources - Rust Edu](https://rust-edu.org/resources/)
    - [I wanna be a crab. : rust](https://www.reddit.com/r/rust/comments/11dofu8/i_wanna_be_a_crab/)
    - [Learn Rust\!](https://gist.github.com/noxasaxon/7bf5ebf930e281529161e51cd221cf8a)
    - [Learn Rust Programming Course – Interactive Rust Language Tutorial on Replit](https://www.freecodecamp.org/news/author/shaun/)
    - [Learn Rust in a Month of Lunches](https://www.manning.com/books/learn-rust-in-a-month-of-lunches)
    - ...
- [How not to learn Rust](https://dystroy.org/blog/how-not-to-learn-rust/ "How not to learn Rust") .. 初学者常犯错误...
- [Michael Yuan - 袁钧涛](https://www.freecodecamp.org/news/edge-cloud-microservices-with-wasmedge-and-rust/) ~ 天体物理学博士, 早期 JBoss 成员, WEB3 专家...
    - [The Top 8 Things I Learned From 4000 Rust Developers](https://www.freecodecamp.org/news/author/michael/)
    - [How to Learn Rust Without Installing Any Software](https://www.freecodecamp.org/news/learn-rust-with-github-actions/) ~ 白嫖专家...
        - [GitHub Codespaces – How to Code Right in Your Browser with Your Own Cloud Dev Environment](https://www.freecodecamp.org/news/learn-programming-in-your-browser-the-right-way/)
    - [How to Create a Serverless Meme-as-a-Service](https://www.freecodecamp.org/news/create-a-serverless-meme-as-a-service/)
    - [Edge Cloud Microservices – How to Build High Performance & Secure Apps with WasmEdge and Rust](https://www.freecodecamp.org/news/edge-cloud-microservices-with-wasmedge-and-rust/)
    - WASM/
        - [How to use Rust + WebAssembly to Perform Serverless Machine Learning and Data Visualization in the Cloud](https://www.freecodecamp.org/news/rust-webassembly-serverless-tencent-cloud/)
        - [How to Build a Personal Dev Server on a $5 Raspberry Pi](https://www.freecodecamp.org/news/build-a-personal-dev-server-on-a-5-dollar-raspberry-pi/)
- ...

### rustCC
> 中文社区:

- [程序设计训练（Rust）](https://lab.cs.tsinghua.edu.cn/rust/) ~2021-2022 年夏季学期起清华大学计算机系开设的《程序设计训练（Rust）》
- [Rust 语言文档 · Rust 程序设计语言](https://prev.rust-lang.org/zh-CN/documentation.html)
    - [Rust 中文文档 | Rust 文档网](https://rustwiki.org/docs/)
    - [Rust 文档翻译指引 | Rust 文档网](https://rustwiki.org/wiki/translate/rust-translation-guide/#tong-yi-fan-yi-zhu-yu-he-gu-ding-yong-yu)
    - [常见问题解答 · Rust 程序设计语言](https://prev.rust-lang.org/zh-CN/faq.html#lifetimes)
    - ...
- [张汉东|半小时弄懂-Rust基本语法及语言特性_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV15U4y177oh/)
    - [左耳朵耗子|以 Rust 为例，带你搞懂编程语言本质_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1cA411877u/)
    - ...
- ...


### Youtube
> 真的是什么都有

- 各种劝解:
    - [Rust Linz, June 2021 - Tim McNamara - How to learn Rust - YouTube](https://www.youtube.com/watch?v=sDtQaO5_SOw)
- 110+[Rust 编程语言入门教程 \[2021\] \- YouTube](https://www.youtube.com/playlist?list=PL3azK8C0kje1DUJbaOqce19j3R_-tIc4_)
    - 94+ [Rust - YouTube](https://www.youtube.com/playlist?list=PLVhhUNGAUIQScqB26DdUq4n1Y2n3auM7X)
        - 专题:[rusqlite - YouTube](https://www.youtube.com/watch?v=xhU8KDzL0vA&list=PLVhhUNGAUIQRR7JheZsDaxF_Cd5Pf5slw)
        - [SQL Cheat Sheet | Crazcalm](http://ogcrazcalm.blogspot.com/2015/11/sql-cheat-sheet.html)
        - [SQLite - Rust Cookbook](https://rust-lang-nursery.github.io/rust-cookbook/database/sqlite.html#insert-and-select-data)
        - [rusqlite - crates.io: Rust Package Registry](https://crates.io/crates/rusqlite)
        - [File in std::fs - Rust](https://doc.rust-lang.org/std/fs/struct.File.html#examples)
    - 42+[RUST PROGRAMMING TUTORIALS \- YouTube](https://www.youtube.com/playlist?list=PLVvjrrRCBy2JSHf9tGxGKJ-bYAN_uDCUL)
    - 44+[Intro to Rust \- YouTube](https://www.youtube.com/playlist?list=PLJbE2Yu2zumDF6BX6_RdPisRVHgzV02NW)
    - 14+[Rust For Starters \- YouTube](https://www.youtube.com/playlist?list=PLKkEWK6xRmes17LQUEA5bNjYISuCEOTXx)
- 44+[The Rust Lang Book \- YouTube](https://www.youtube.com/playlist?list=PLai5B987bZ9CoVR-QEIN9foz4QCJ0H2Y8)
- 25+[Rust Projects \- YouTube](https://www.youtube.com/playlist?list=PLJbE2Yu2zumDD5vy2BuSHvFZU0a6RDmgb)
    - 24+[50 RUST Projects \- YouTube](https://www.youtube.com/playlist?list=PL5dTjWUk_cPYuhHm9_QImW7_u4lr5d6zO)
- [Jon Gjengset - YouTube](https://www.youtube.com/@jonhoo)
    - 14+ [Crust of Rust - YouTube](https://www.youtube.com/playlist?list=PLqbS7AVVErFiWDOAVrPt7aYmnuuOLYvOa)
    - 14+ [Rust live-coding - YouTube](https://www.youtube.com/playlist?list=PLqbS7AVVErFgY2faCIYjJZv_RluGkTlKt)
- [Rust Talks \- YouTube](https://www.youtube.com/playlist?list=PLZaoyhMXgBzoM9bfb5pyUOT3zjnaDdSEP)
    - 各种畅想...
    - [Contributing to Rustc \- YouTube](https://www.youtube.com/playlist?list=PLnhCUtqrIE-zgfmf6hn6fLwhfR_hDSG9T) ~ 牛人直播如何为 Rust 编译器贡献特性...
- [Rust - YouTube](https://www.youtube.com/watch?v=_jMSrMex6R0&list=PLFjq8z-aGyQ6t_LGp7wqHsHTYO-pDDx84)
    - 各种前景分析
    - [WebAssembly - YouTube](https://www.youtube.com/watch?v=qjwWF6K-7uE&list=PLFjq8z-aGyQ78CQu1G3C5CT9ieiNpsnbJ) ~ 各种实现应用
- [Idiomatic Rust \- YouTube](https://www.youtube.com/playlist?list=PLai5B987bZ9A5MO1oY8uihDWFC5DsdJZq)
- ...


### free Books
> 这个世界上免费好资源太多了...

[free-programming-books/free-programming-books-langs.md at main · EbookFoundation/free-programming-books](https://github.com/EbookFoundation/free-programming-books/blob/main/books/free-programming-books-langs.md#rust)

- [Rust 语言文档 · Rust 程序设计语言](https://prev.rust-lang.org/zh-CN/documentation.html)
- [Rust 中文文档 | Rust 文档网](https://github.com/rust-lang-cn/rustdoc-cn/fork)
- [Rust 语言之旅 - Let's go on an adventure!](https://tourofrust.com/11_zh-cn.html)
- [Y分钟速成X ~ 其中 X=Rust](https://learnxinyminutes.com/docs/zh-cn/rust-cn/)
    - [Rust 备忘清单 & rust cheatsheet & Quick Reference](https://wangchujiang.com/rust-cn-document-for-docker/quick-reference/docs/rust.html)
- [sger/RustBooks: List of Rust books](https://github.com/sger/RustBooks#advanced-books)
    - [ctjhoa/rust-learning: A bunch of links to blog posts, articles, videos, etc for learning Rust](http://llogiq.github.io/2015/07/15/profiling.html)
    - [Introduction - Learning Rust With Entirely Too Many Linked Lists](https://rust-unofficial.github.io/too-many-lists/first.html)
    - ...
- ...

### 面试向...
> 也就是 Leetcode 之类的东西, 要死记的...


- 44+ [Leetcode - YouTube](https://www.youtube.com/watch?v=L93kxEn2sEA&list=PLib6-zlkjfXnl7Qyy9QzOt5BAphdAwmHm&pp=iAQB)
- 8+ [Rust Leetcode Solutions - YouTube](https://www.youtube.com/watch?v=dK5jUHRbyCA&list=PLvePk7bSSZhe5C8NNaxDhABkjg5F70wdE&pp=iAQB)
- ...



## logging
> 版本记要

- ..
- 221214 ZQ init.


```
            _~`|-~_
        \) /  O =  \ ()
          '_   ⏡   _'
          | '-----' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```