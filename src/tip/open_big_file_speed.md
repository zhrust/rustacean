# tracing
> 一步到位日志工具?

## background

一个 5M 左右的 toml 用 rust 加载时竟然比 Python 还要慢

## goal

- Rust 原生
- 合理加速
- 通用...

## trace

> Q: 

rust 中 File::open() 打开一个大的文本文件时很慢,
有什么加速的办法?

> A:

在 Rust 中，File::open() 用于打开文件并返回 std::fs::File 类型的对象。如果打开的文件非常大，打开过程可能会很慢，因为系统需要从硬盘中读取大量的数据。

以下是一些加速打开大型文本文件的方法：

1. 使用 BufReader
Rust 中的 BufReader 可以将文件读取到内存缓冲区中，并按需将其读取到程序中。使用 BufReader 可以加快读取速度。

```rust
use std::io::{BufReader, BufRead};
use std::fs::File;

fn main() {
    let file = File::open("file.txt").unwrap();
    let reader = BufReader::new(file);

    for line in reader.lines() {
        println!("{}", line.unwrap());
    }
}

```

1. 使用异步 I/O
Rust 中的异步 I/O 可以使程序在读取文件时不会被阻塞。异步 I/O 可以使用 tokio 库实现。

```rust
use tokio::fs::File;
use tokio::io::{self, AsyncBufReadExt};

#[tokio::main]
async fn main() -> io::Result<()> {
    let file = File::open("file.txt").await?;
    let reader = io::BufReader::new(file);

    let mut lines = reader.lines();

    while let Some(line) = lines.next_line().await? {
        println!("{}", line);
    }

    Ok(())
}

```

1. 使用多线程
使用多线程可以加速文件的读取和处理，特别是在处理大量数据时。可以使用 Rust 中的 rayon 库实现并行处理。

```rust
use std::fs::File;
use std::io::{BufRead, BufReader};
use rayon::prelude::*;

fn main() {
    let file = File::open("file.txt").unwrap();
    let reader = BufReader::new(file);
    let lines = reader.lines().collect::<Result<Vec<String>, _>>().unwrap();

    let result = lines.par_iter().map(|line| {
        // 处理每一行
        line.to_uppercase()
    }).collect::<Vec<String>>();

    // 处理结果
    println!("{:?}", result);
}

```



## refer.
> 各种参考

- [BufReader in std::io - Rust](https://doc.rust-lang.org/stable/std/io/struct.BufReader.html#examples)
- [tokio - crates.io: Rust Package Registry](https://crates.io/crates/tokio)
- [rayon - crates.io: Rust Package Registry](https://crates.io/crates/rayon)
- ...





```
        _~^~-~_
    () /  = →  \ ()
      '_   𝟂   _'
      / '--+--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```