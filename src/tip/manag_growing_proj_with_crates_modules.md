# Crate中合理划分目录
> tips...重要也不重要

## background

[Ferris艺术](/dev/cli_ferris_art.md) 中触发的灵魂问题...

## goal

比如当前 crate 目录:
```
foo/
├── Cargo.lock
├── Cargo.toml
├── src/
│   ├── bar1/
│   │   └── echo.rs
│   ├── bar1.rs
│   ├── bar2/
│   │   └── echo.rs
│   ├── bar2.rs
│   └── main.rs
...
```

在两个 echo.rs 中都有相同函数不过内容不同:

```rust
//src/bar1/echo.rs:
pub fn bang() {
    println!("src/bar1/echo.rs: {}", env!("CARGO_PKG_VERSION"));
}

//src/bar2/echo.rs:
pub fn bang() {
    println!("src/bar2/echo.rs: {}", env!("CARGO_PKG_VERSION"));
}
```

如何能自如的:

- 在 main.rs 中调用 bar1,bar2 中的对象?
- 在 bar1/echo.rs 中又如何调用 bar2/echo.rs 中的对象?
- ...以及为什么?


## trace

按照 Python 中的经验, 进行了尝试, 越调越乱;

直到搜索到: [Cargo Targets - The Cargo Book](https://doc.rust-lang.org/cargo/reference/cargo-targets.html#binaries)

才明从根儿上就忽略了一点:

    一个包可以包含多个二进制 crate 项和一个可选的 crate 库

就是那个 `一个` 可选....

所以,必须要从一开始先整理好目录结构, 才可能开展自由分组,
要追加唯一的 `lib.rs` 变成:

```
foo/
├── Cargo.lock
├── Cargo.toml
├── src/
│   ├── bar1/
│   │   └── echo.rs
│   ├── bar1.rs
│   ├── bar2/
│   │   └── echo.rs
│   ├── bar2.rs
│   ├── lib.rs       <=== 关键配置
│   └── main.rs
...
```

在 Cargo.toml 中追加配置:
```toml
[lib]
path = "src/lib.rs"
```

然后,关键技巧来了:

```rust
pub mod bar1;
pub mod bar2;

//  使用 pub use 重导出名称
pub mod echos{
    pub use super::bar1::echo::*;
    pub use super::bar2::echo::*;
}
```

也就是说在合法的 库文件中,
将不同目录中的模块通过在一个重新定义的模块中,
重新拉到名称空间中, 并 pub ,
这才, 才能让平行的不同目录中的各模块可见,

这时, 才能在 `src/bar1/echo.rs` 中通过 `super::super::bar2` 形式引用到隔壁的资源...

```rust
use super::super::bar2::echo::bang as bar2_echo_bang;

pub fn bang() {
    println!("src/bar1/echo.rs: {}", env!("CARGO_PKG_VERSION"));
    bar2_echo_bang();
}
```

当然, 如果两个 echo 中的 bang() 相互引用,就变成了经典的 OOP 中的菱形循环引用:

```
use super::super::bar2::echo::bang as bar2_echo_bang;
          ^                   +
         /                     \
        /                       V
src/bar1/echo.rs            src/bar2/echo.rs
-> bang()                   -> bang()
        ^                       /
         \                     /
          +                   V
use super::super::bar1::echo::bang as bar1_echo_bang;

```

在编译运行后将进入死循环, 直到 stack overflow 爆出:

```
...
src/bar2/echo.rs: 0.1.42
src/bar1/echo.rs: 0.1.42
src/bar2/echo.rs: 0.1.42
src/bar1/echo.rs: 0.1.42
src/bar2/echo.rs: 0.1.42
src/bar1/echo.rs: 0.1.42
src/bar2/echo.rs: 0.1.42
src/bar1/echo.rs: 0.1.42

thread 'main' has overflowed its stack
fatal runtime error: stack overflow
Abort trap: 6
```


综上, 在项目扩大时, 还是将关键组件都 crate 化,
变成标准的外部或是本地 crate ,再调教好 build 过程,
那么, 无论多大的工程, 最后都可以控制在一小组文件中, 
组合调用已经安全无忧编译好的 crate 们....


## refer.
> 关键参考

[使用 use 关键字将路径引入作用域 - Rust 程序设计语言 简体中文版](https://kaisery.github.io/trpl-zh-cn/ch07-04-bringing-paths-into-scope-with-the-use-keyword.html#%E4%BD%BF%E7%94%A8-pub-use-%E9%87%8D%E5%AF%BC%E5%87%BA%E5%90%8D%E7%A7%B0) -> 使用 pub use 重导出名称

- [Rust中的代码组织:package/crate/mod - 腾讯云开发者社区-腾讯云](https://cloud.tencent.com/developer/article/1899628)
- [模块和货物 - Rust 的绅士介绍](http://llever.com/gentle-intro/pain-points.zh.html)
- ...


```
          _~∽|^~_
      () /  - ♡  \ \/
        '_   ⌐   _'
        \ '--∽--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```