# 实践作品

## background
学习一门新语言, 最高效的姿势就是拿来使用了

## goal
将当前日常要用的各种工具, 转化为 rust 版本的...

## plan
进展图例: 

- 🌚 ~ 萌动
- 🌘 ~ 开搞
- 🌗 ~ 折腾
- 🌖 ~ 可用
- 🌝 ~ 发布


- [ ] 🌖NNera ~ 牛妞纪元
    - [x] CLI
    - [ ] 发布
- [x] 🌝bxmr ~ BXM 输入码表维护器
    - [x] CLI
    - [x] 发布
- [x] 🌝 ferris ~ 吉祥物ASCII-art 生成器
    - [x] CLI
    - [x] crate
- [ ] 🌚[RSS4mdbook](/dev/cli_rss4mdbook.md) 自制 RSS 生成器
- [ ] 🌚 yuzu ~ 柚子, 简陋的私用短址生成器
    - [x] SUUID ~ 短 UUID 生成器; 组合标准的 UUID+Md5 就好
        - [ ] 自制, 参考: [shortuuid/main.py at master · skorokithakis/shortuuid](https://github.com/skorokithakis/shortuuid/blob/master/shortuuid/main.py)
        - [ ] crate
    - [ ] CLI
    - [ ] 发布
        - [ ] RESTful ... etc
- [ ] 🌚 Yazi ~ 睚眦 git 仓库行为分析器
    - [ ] CLI
    - [ ] 发布

## trace
> 追踪笔记

掌握 rust 到什么程度就能给自己开始小工具了?

- 目测嘦会用 RA 就可以了...呗?
- ...

### crate.io

> cargo login 
首先偶到的问题:

```
$ cargo login [自己的 crate.io token]
error: crates-io is replaced with non-remote-registry source registry `tuna`;
include `--registry crates-io` to use crates.io
```

意味着你的 Rust 包管理器 Cargo 正在使用一个名为 tuna 的本地 Rust 包源，而不是默认的远程源 crates.io。

根据提示首次使用官方源:

```
$ cargo login [自己的 crate.io token] --registry crates-io -v
    Updating crates.io index
     Running `git fetch --force --update-head-ok 'https://github.com/rust-lang/crates.io-index' '+HEAD:refs/remotes/origin/HEAD'`
       Login token for `crates-io` saved
```

追加上目标仓库 `--registry crates-io` 就可以完成了...
(大约3分钟后)

> cargo package

```
$ cargo package
...
   Compiling proc-macro2 v1.0.51
   Compiling quote v1.0.23
   Compiling unicode-ident v1.0.6
   Compiling libc v0.2.139
    ...
   Compiling ferris-actor v0.1.42 (/path/2/../ferris-actor/target/package/ferris-actor-0.1.42)
    Finished dev [unoptimized + debuginfo] target(s) in 20.85s
    Packaged 12 files, 40.8KiB (13.1KiB compressed)
```

不错, 自动化完成所有

> cargo publish --registry crates-io

```
$ cargo publish --registry crates-io
    Updating crates.io index
...
   Compiling proc-macro2 v1.0.51
   Compiling unicode-ident v1.0.6
   Compiling quote v1.0.23
   ...

```
同样, 必须追加上 `--registry crates-io` 目标仓库参数

> LICENSES

```
...
    Packaged 12 files, 40.9KiB (13.1KiB compressed)
   Uploading ferris-actor v0.1.42 (/Users/zoomq/Exercism/proj/ferris-actor)
error: failed to publish to registry at https://crates.io

```
无法完成发布, 原因竟然是 Caused by:

-  the remote server responded with an error: unknown or invalid license expression; 
   -  see http://opensource.org/licenses for options, 
   -  and http://spdx.org/licenses/ for their identifiers

对比其它 crate 修订 Cargo.toml 中的关键配置项目为:

> license = "BSD-2-Clause"

是的, 就少了 github 自动创建时后面的一个 `License` 就通过了:

```
$   cargo publish --registry crates-io
    Updating crates.io index
...
     Waiting on `ferris-actor` to propagate to crates.io index (ctrl-c to wait asynchronously)
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
    Updating crates.io index
```

完成发布;-)


## refer.
> 各种相关参考...

- [Command-Line Rust \[Book\]](https://www.oreilly.com/library/view/command-line-rust/9781098109424/)
    - [Introducing the Determinate Nix Installer — Determinate Systems](https://determinate.systems/posts/determinate-nix-installer) ~ 实战案例, 从 bash 迁移为 rust...
- [Rustacean.net: Home of Ferris the Crab](https://rustacean.net/)
- ...


### +Pg

[From Zero to PostgreSQL extension in 3 hours with Rust - Postgres Conference](https://postgresconf.org/blog/posts/from-zero-to-postgresql-extension-in-3-hours-with-rust)

- +Tokio ~ [How to Write a REST API Using Rust and Axum Framework | by Shanmukh Sista | Medium](https://shanmukhsista.com/real-world-rest-api-using-rust-axum-framework-with-request-validations-and-error-handling-75d4175cef96)
- + SQLx ~ [Rust - Build a CRUD API with SQLX and PostgreSQL 2023](https://codevoweb.com/rust-build-a-crud-api-with-sqlx-and-postgresql/)
    - [Axum と SQLx で Todo アプリを作る（DB は PostgreSQL）](https://zenn.dev/codemountains/articles/159a8a0323a56f)
    - ...
- [Creating a REST API in Rust with Persistence: Rust, Rocket and Diesel | by Gene Kuo | Medium](https://genekuo.medium.com/creating-a-rest-api-in-rust-with-persistence-rust-rocket-and-diesel-a4117d400104)
- +actix ~ [Rust Web Development Tutorial: REST API | Cloudmaker](https://cloudmaker.dev/how-to-create-a-rest-api-in-rust/)
- 


## logging
> 版本记要

- ...
- 230122 ZQ init.


```
       _~∽*^~_
   () /  ◴ =  \ \/
     '_   ⌄   _'
     ( '--#--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```