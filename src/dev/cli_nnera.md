# NN 纪元
> CLI 小作品

## backgroung
作为一名程序猿总是要有一种特殊的时间点记录系统...

## goal
以女儿出生当天零时, 为类似 UNIX 时间戳的起点,
可以在各种系统中快速确定/反查:

- nn ~ 默认给出当天是女儿出生第几天
- nn -e 4200 ~ 给出指定 NNera 是公历 YYYY-mm-dd
- nn -d 230225 ~ 给出指定 yymmdd 日期是女儿出生第几天

## trace

- 最早是 每天日记时, 手工增量, 人工查询;
- 后来用 Python 写了个脚本, 但是, 环境部署是个麻烦事儿;
- 然后, 学习 Elixri 时写了个工具, 但是, 发现竟然没办法简单编译为 Linux 应用;
- 又后来, 学习 Golang 时写了个指令, 发现, 竟然超过 10M ...
- 最后用 bash 编了个 .sh 脚本反而兼容性最好
- 现在, 轮到 Rust 来重构了...

## refer.

- [clap - Rust](https://docs.rs/clap/latest/clap/index.html)
    - [Let's build a CLI in Rust 🦀](https://blog.ediri.io/lets-build-a-cli-in-rust)
    - [Building a CLI from scratch with Clapv3 | by Ukpai Ugochi | Medium](https://medium.com/javascript-in-plain-english/coding-wont-exist-in-5-years-this-is-why-6da748ba676c)
    - [Rustで手軽にCLIツールを作れるclapを軽く紹介する - Qiita](https://qiita.com/Tadahiro_Yamamura/items/4ae32347fb4be07ea642)
    - [RustのClapクレートがメチャクチャ良かった話](https://zenn.dev/shinobuy/articles/53aed032fe5977)
    - [如何用clap进行命令行解析 - 掘金](https://juejin.cn/post/7158808367233204261)
- [structopt - Rust](https://docs.rs/structopt/latest/structopt/trait.StructOpt.html)
    - [解析命令行参数 - Rust 中的命令行应用](https://suibianxiedianer.github.io/rust-cli-book-zh_CN/crates/README_zh.html)
    - ...
- ...

## logging

- ...
- 230228 ZQ ...🦀
- 230225 ZQ re-re-re-init.




```
          _~^+`~_
      \/ /  + ^  \ (/
        '_   ∧   _'
        ( '-----' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```