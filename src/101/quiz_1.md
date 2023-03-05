# Rust Quiz #1

## background
What is the output of this Rust program?


```rust
macro_rules! m {
    ($($s:stmt)*) => {
        $(
            { stringify!($s); 1 }
        )<<*
    };
}

fn main() {
    print!(
        "{}{}{}",
        m! { return || true },
        m! { (return) || true },
        m! { {return} || true },
    );
}
```

## trace
> 具体推进

不是, 等等, 第一题就是宏展开嘛?

> Q:

运行结果为什么是 112 ?

> A:

代码的运行结果是112，原因是宏展开后生成的代码中有三个块表达式，每个块表达式内部包含了一个字符串字面量和数字1，然后将这个数字1左移一位，相当于乘以2，最后返回的是三个块表达式结果的和。

具体来说，宏 m 的作用是将传入的代码块中的每个语句转化为一个块表达式，其中每个块表达式包含了一个字符串字面量和数字1，即 { stringify!($s); 1 }。stringify!($s) 是 Rust 中的一个内置宏，用于将传入的代码转化为一个字符串字面量。

在 main 函数中，分别传入了三个不同的代码块：

- m! { return || true } 展开后生成的代码块是 { stringify!(return || true); 1 }，其中的 stringify!(return || true) 会将代码块转化为字符串 "return || true"，所以这个代码块的结果是 { "return || true"; 1 }。
- m! { (return) || true } 展开后生成的代码块是 { stringify!((return) || true); 1 }，其中的 stringify!((return) || true) 会将代码块转化为字符串 "(return) || true"，所以这个代码块的结果是 { "(return) || true"; 1 }。
- m! { {return} || true } 展开后生成的代码块是 { stringify!({return} || true); 1 }，其中的 stringify!({return} || true) 会将代码块转化为字符串 "{return} || true"，所以这个代码块的结果是 { "{return} || true"; 1 }。


由于每个块表达式内部都有数字1，因此最终的结果是将三个块表达式的结果相加，即 1 + 2 + 4 = 7，然后将结果左移一位，相当于乘以2，即 7 << 1 = 14。最后，这个结果会被传入 print! 宏中，因此输出的结果是 112。


对应展开后的代码:

```rust
// $ cargo expand 

#![feature(prelude_import)]
#[prelude_import]
use std::prelude::rust_2021::*;
#[macro_use]
extern crate std;
fn main() {
    {
        ::std::io::_print(
            format_args!(
                "{0}{1}{2}", 
                { "return (|| true);"; 1 }, 
                { "(return) || true;"; 1 }, 
                { "{ return }"; 1 } << { "|| true;"; 1 }
            ),
        );
    };
}
```



## refer.
> 关键参考

[学习 Rust - Rust 程序设计语言](https://github.com/rust-lang/rustlings/)

- [调试 - The Little Book of Rust Macros （Rust 宏小册）](https://zjp-cn.github.io/tlborm/syntax-extensions/debugging.html)
    - [dtolnay/cargo-expand: Subcommand to show result of macro expansion](https://github.com/dtolnay/cargo-expand)
        - 虽然内核有支持, 但是, 包装一下好使用
        - cargo install cargo-expand
        - rustup component add rustfmt
        - 就可随时用 $ cargo expand 来观察展开后的代码
        - 等同:
            - $ cargo rustc --profile=check -- -Zunpretty=expanded
    - [Rust Playground](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021)
- 


```
      _~^*∽~_
  \/ /  ◷ ☉  \ \/
    '_   ⎵   _'
    | '--~--' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```