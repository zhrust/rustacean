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

### async
> 只是想加速一个文件的读取...

-> [文件加速打开](/tip/open_big_file_speed.md)

然后就发现,这事儿没那么简单, 整体上:

> 需要明确的是，async函数在Rust中是一种特殊的函数类型，可以在其中使用await操作符等异步操作，而async函数的返回类型是一个实现了Future trait的类型，这个类型在编译时是不确定的，因为它表示一个异步计算的结果，需要等待执行完成才能得到具体的结果类型。因此，当你调用一个async函数时，你需要在一个async上下文中，例如在async函数中或者使用tokio等异步运行时库的Runtime来运行异步任务。

所以, 原有的调用栈:

- src/main.rs -> fn main() 
    - inv::run() -> src/inv.rs 
        - seek::echo() -> src/inv/seek.rs
            - util::toml2btmap() -> src/inv/util.rs
                - file.read_to_string(&mut contents).unwrap()
                    - let mut file = File::open(tfile).unwrap()
- 发现可以用 tokio 实现异步操作, 并加速文件读取?
    - 于是-> 
        - use tokio::fs::File as TokioFile;
        - use tokio::io::BufReader as TokioBufReader;
    - 然后-> 
        - let file = TokioFile::open(path).await?;
        - let reader = TokioBufReader::new(file);
    - 但是, 发现不行, await? 不能编译, 因为所在函数不是 async 的, 于是连锁反应
    - pub async fn async_read_lines().await <- 以便被调用
        - pub async fn async_toml2btmap() <- 以便被调用
            - util::async_toml2btmap().await <- src/inv/util.rs
                - async fn seek::echo().await <- src/inv/seek.rs
                    - async fn run() <- src/inv.rs 
                        - inv::run().await <- src/main.rs
                            - async fn main()


如果不是 rust-analyzer 一路提醒, 真会蒙圈儿的...


## refer.

- [clap::_derive::_cookbook::git_derive - Rust](https://docs.rs/clap/latest/clap/_derive/_cookbook/git_derive/index.html)
    - 简化官方示例,完成结构性探索
- [Building a CLI from scratch with Clapv3 | by Ukpai Ugochi | Medium](https://medium.com/javascript-in-plain-english/coding-wont-exist-in-5-years-this-is-why-6da748ba676c)
    - 很囧的案例, 看起来很美却根本编译不过...
- 尴尬了, 二进制发行版本的应用可没有那么简单的全局配置可以使用...
    - [Working with Environment Variables in Rust · Thorsten Hans' blog](https://www.thorsten-hans.com/working-with-environment-variables-in-rust/)
    - ...
- ...

## logging

- ...
- 230301 ZQ ...🦀
- 230227 ZQ mod/clap/tracing/... 项目结构厘定
- 230225 ZQ re-re-re-init.





```
        _~^|∽~_
    \) /  ◴ ☉  \ \/
      '_   ⎵   _'
      / '--∽--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```



