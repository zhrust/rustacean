# tracing
> 一步到位日志工具?

## background

无论哪种级别的开发,
一个日志工具是必要的,
否则,发生点儿什么事儿, 一点儿数据/配置/...的残影都没有那是真一点儿办法也没有...


## goal

- Rust 原生
- 成熟
- 支持多种格式/配置/定制/...
- 文档完备, 安装流畅, 没有急转弯....

## trace

### install

Cargo.toml 中追加:

    [dependencies]
    log = "0.4"
    tracing = "0.1"
    clia-tracing-config = "0.2"

> $ cargo check 

自动安装对应 crate

```rust
fn main() -> Result<()>{

    let _guard = clia_tracing_config::build()
        .filter_level("debug")//fatal,error,warn,info,debug
        .with_ansi(true)
        .to_stdout(false)
        .directory("./log")
        .file_name("debug.log")
        .rolling("daily")
        .init();

/// ...

    Ok(())

}
```

在需要的场景中定义个 `_guard` 就完成了所有关键配置,
这是由 `clia-tracing-config` 实现的,

现在, 就可以在开发过程中使用

```rust
log::debug!("{}", foobar);
log::info!("{}", foobar);
log::warn!("{}", foobar);
log::error!("{}", foobar);
```

进行日志输出, 而且每天自动活动, 但是, 有自动 link ,
可以使用 `tail -f ` 一直追踪观察;

```
项目/
    +- Cargo.toml
    +- README.md
    +- src/
    |   +- main.rs
    +- tests/
    |   +- cli.rs
    +- log/
    |   +- debug.log -> debug.log.2023-02-25
    |   +- ...
    |   +- debug.log.2023-02-23
    |   `- debug.log.2023-02-25
    ...
```






## refer.
> 各种参考

- [Awesome Rank for rust-unofficial/awesome-rust](https://awesomerank.github.io/lists/rust-unofficial/awesome-rust.html#cryptocurrencies)
    - [rust-unofficial/awesome-rust: A curated list of Rust code and resources.](https://github.com/rust-unofficial/awesome-rust)
    - 先从社区知道 logging 模块的大约范畴
- [Comparing logging and tracing in Rust - LogRocket Blog](https://blog.logrocket.com/comparing-logging-tracing-rust/)
    - [log4rs-Rust-log库 - 夜雨秋灯录](https://privaterookie.github.io/posts/2020-02-03-log4rs-Rust-log%E5%BA%93.html)
    - [在 Rust 中使用 log： log / slog / tracing - iT 邦幫忙](https://ithelp.ithome.com.tw/articles/10252834)
    - 再从对比中定位目标
- [tracing - crates.io: Rust Package Registry](https://choosealicense.com/licenses/mit)
    - [使用 tracing 记录日志 - Rust语言圣经(Rust Course)](https://course.rs/logs/tracing.html)
    - [clia-tracing-config - crates.io: Rust Package Registry](https://crates.io/crates/clia-tracing-config)
- ...

