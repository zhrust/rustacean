# 清晰解释Rust模块系统
> tips...重要也不重要

原文: [Clear explanation of Rust’s module system](https://www.sheshbabu.com/posts/rust-module-system/)

## 快译
Rust 的模块系统出奇的混乱,给初学者带来了很多挫败感;

在这篇文章中, 我将使用实际案例来解释模块系统,
以便清楚的了解其工作原理,
并可以立即开始在你的项目中应用起来;

由于 Rust 的模块系统非常独特,
我请求读者以开放的心态阅读这篇文章,
不要将其和其它语言的模块运作方式进行比较;

先使用这个文件结构来模拟一个真实世界的项目:


```
my_project
├── Cargo.toml
└─┬ src
  ├── main.rs
  ├── config.rs
  ├─┬ routes
  │ ├── health_route.rs
  │ └── user_route.rs
  └─┬ models
    └── user_model.rs
```

以下这些是我们想使用自己不同模块的不同方式:

- 同级引用
- 引用下级
- 跨目录引用兄弟目录/模块

![rust-module-system-1](https://www.sheshbabu.com/images/2020-rust-module-system/rust-module-system-1.png)


这三个例子足以营利 Rust 的模块系统是如何工作的;


(`译按`: 其实, 这只是最基础的, 
这种目录结构是人工创建, 还是工具创建, 其实也是个问题,
毕竟, Rust 还支持内部库, 工作空间 ...等等代码管理姿势...)


------


### 示例 1

先从第一个姿势开始 --- `importing config.rs in main.rs`

```rust
// main.rs
fn main() {
  println!("main");
}

// config.rs
fn print_config() {
  println!("config");
}
```


第一个最常犯的错误就是因为我们有了 config.rs, health_route.rs 
等等文件,
就以为文件就是模块,我们可以从其它文件导入;

这是我们看到的(文件系统树)和编译器实际看到的(模块树):

![system-2](https://www.sheshbabu.com/images/2020-rust-module-system/rust-module-system-2.png)

令人惊讶的是,
编译器只看到 crate 模块,
这就是我们的 main.rs 文件;
这是因为,我们需要在 Rust 中显式构建模块树 --- 文件树到模块树之间没有隐式映射;

(译按: 和 Ruby 们包含大量多模内隐式猜想相反, Rust 只相信代码, 不主动猜想开发者的任何可能;)


> 我们需要在 Rust 中显式构建模块树, 这儿没有隐式映射到文件系统

要将文件追加到模块树, 我们需要使用 mod 关键字将该文件声明为子模块;
接下来让入门感到困惑的是, 你可能假设我们在同一文件中将一个文件声明为模块;
但是,我们需要在不同的文件中声明!
由于我们在模块树中只有 main.rs,
所以,让我们将 config.rd 声明为 main.rs 中的子模块;


> mod 关键字用来声明一个子模块


mod 关键字的语法如下:

`mod my_module;`


在此,编译器在同一目录中查找 my_module.rs 或是 my_module/mod.rs ;

```
my_project
├── Cargo.toml
└─┬ src
  ├── main.rs
  └── my_module.rs
```

或是:

```
my_project
├── Cargo.toml
└─┬ src
  ├── main.rs
  └─┬ my_module
    └── mod.rs
```

由于 main.rs 和 config.rs 在同一目录中,
我们可以如下声明 config 模块:

```rust
// main.rs
+ mod config;

fn main() {
+ config::print_config();
  println!("main");
}

// config.rs
fn print_config() {
  println!("config");
}
```

我们使用 :: 语法访问对应 print_config 函数;

这是当前模块树的样子:

![system-3](https://www.sheshbabu.com/images/2020-rust-module-system/rust-module-system-3.png)

我们已经成功声明了 config 模块!
但是,这不足以调用 config.rs 中的 print_config 函数;
默认情况中, Rust 中的几乎所有内容都是私有的,
我们需要使用 pub 关键字令其公开:

> pub 关键字令自己公开

```rust
// main.rs
mod config;

fn main() {
  config::print_config();
  println!("main");
}

// config.rs
- fn print_config() {
+ pub fn print_config() {
  println!("config");
}
```

现在已经生效;
我们已经成功调用了一个在不同文件中定义的函数!

------

### 示例 2

让我们尝试从 main.rs 中调用 routes/health_route.rs 中定义的 print_health_route 函数;

```rust
// main.rs
mod config;

fn main() {
  config::print_config();
  println!("main");
}

// routes/health_route.rs
fn print_health_route() {
  println!("health_route");
}

```

正如我们之前讨论的,
我们只能同同一目录中的 my_module.rs 或是 my_module/mod.rs 使用 mod 关键字;

因此, 为了从 main.rs 中调用 routes/health_route.rs 中的函数,
我们需要作到以下:

- 创建一个名为 routes/mod.rs 的文件,
- 并在 main.rs 中声明 子模块路由,
- 然后,在 routes/mod.rs 中声明 health_route 子模块并公开;
- 最后, 在 health_route.rs 中公开对应函数;

```
my_project
├── Cargo.toml
└─┬ src
  ├── main.rs
  ├── config.rs
  ├─┬ routes
+ │ ├── mod.rs
  │ ├── health_route.rs
  │ └── user_route.rs
  └─┬ models
    └── user_model.rs
```

对应代码:

```rust
// main.rs
mod config;
+ mod routes;

fn main() {
+ routes::health_route::print_health_route();
  config::print_config();
  println!("main");
}

// routes/mod.rs
+ pub mod health_route;

// routes/health_route.rs
- fn print_health_route() {
+ pub fn print_health_route() {
  println!("health_route");
}
```
现在模块树应该如下:


![system-4](https://www.sheshbabu.com/images/2020-rust-module-system/rust-module-system-4.png)


我们现在可以调用一个目录中定义的函数了;


------


### 示例 3

现在尝试这个调用路径 `main.rs => routes/user_route.rs => models/user_model.rs`


```rust
// main.rs
mod config;
mod routes;

fn main() {
  routes::health_route::print_health_route();
  config::print_config();
  println!("main");
}

// routes/user_route.rs
fn print_user_route() {
  println!("user_route");
}

// models/user_model.rs
fn print_user_model() {
  println!("user_model");
}
```

我们想从 main 中调用来者 print_user_route 的 print_user_model 函数;

我们先进行和之前类似的增补:
声明子模块, 公开了函数, 并追加 mod.rs ...


```
my_project
├── Cargo.toml
└─┬ src
  ├── main.rs
  ├── config.rs
  ├─┬ routes
  │ ├── mod.rs
  │ ├── health_route.rs
  │ └── user_route.rs
  └─┬ models
+   ├── mod.rs
    └── user_model.rs
```

```rust
// main.rs
mod config;
mod routes;
+ mod models;

fn main() {
  routes::health_route::print_health_route();
+ routes::user_route::print_user_route();
  config::print_config();
  println!("main");
}

// routes/mod.rs
pub mod health_route;
+ pub mod user_route;

// routes/user_route.rs
- fn print_user_route() {
+ pub fn print_user_route() {
  println!("user_route");
}

// models/mod.rs
+ pub mod user_model;

// models/user_model.rs
- fn print_user_model() {
+ pub fn print_user_model() {
  println!("user_model");
}

```

现在模块树应该像变样:

![module-system-5.](https://www.sheshbabu.com/images/2020-rust-module-system/rust-module-system-5.png)


等等, 我们实际上并没有从 print_user_route 调用 print_user_model !
到目前为止, 我们只调用了 main.rs 中其它模块中定义的函数,
我们如何从其它文件中调用呢?

如果检阅当前模块树,
print_user_model 函数位于 crate::models::user_model 路径中;
因此,为了在不是 main.rs 的文件中使用模块,
我们应该考虑在模块树中触达该模块所需要的路径;

```rust
// routes/user_route.rs
pub fn print_user_route() {
+ crate::models::user_model::print_user_model();
  println!("user_route");
}

```

我们已经从一个不是 main.rs 的文件中成功的调用了一个文件中定义的函数;

(`译按:` 这是使用绝对路径形式, 另外还有相对路径形式...)


------


### super

如果我们的文件组织有很多目录深度,
则完全限定名将变得太长;
假设出于某种原因,
我们想从 print_user_route 调用 print_health_route;
分别位于 crate::routes::health_route 和 crate::routes::user_route 路径中;

我们可以使用完全限定名称
crate::routes::health_route::print_health_route() 来调用,
但是, 我们也可以使用查对路径 super::health_route::print_health_route();
注意, 我们使用 super 来引用父挖掘范围;


> 模块路径中的 super 关键字指的是父作用域

```rust
pub fn print_user_route() {
  crate::routes::health_route::print_health_route();
  // can also be called using
  super::health_route::print_health_route();

  println!("user_route");
}

```


------


### use

前述示例中智囊把完全限定名甚至相对名称都很乏味;
为了缩短名称,
我们可以使用 use 关键字将路径绑定到新名称或是别名;


> use 关键字用以缩短模块路径

```rust
pub fn print_user_route() {
  crate::models::user_model::print_user_model();
  println!("user_route");
}

```

上面的代码可以重构为:

```rust
use crate::models::user_model::print_user_model;

pub fn print_user_route() {
  print_user_model();
  println!("user_route");
}

```

除了使用原有名称 print_user_model,
我们也可以将其绑定为其它名称:


```rust
use crate::models::user_model::print_user_model as log_user_model;

pub fn print_user_route() {
  log_user_model();
  println!("user_route");
}

```


------

### 外部模块

更加时 Cargo.toml 的依赖项可以全局用于项目内所有模块;
我们不需要显式导入或是声明任何东西来启用;

> 外部依赖项对项目内所有模块全局可用


例如, 假设我们将 rand crate 追加到我们的项目中;
就可以直接在代码用使用:

```rust
pub fn print_health_route() {
  let random_number: u8 = rand::random();
  println!("{}", random_number);
  println!("health_route");
}

```
也可以使用 use 来缩短路径:


```rust
use rand::random;

pub fn print_health_route() {
  let random_number: u8 = random();
  println!("{}", random_number);
  println!("health_route");
}

```

------

### 小结

- 模块系统是显示的
    - 并没和文件系统 1:1 映射
- 我们在其父文件中又不能一个文件模块, 而不是在其自身中
- mod 关键字用以声明子模块
- 我们需要将函数/结构等等显式声明为公共的,以便可以在其它模块中引用
- pub 关键字令事务公开
- use 关键字用来缩短模块路径
- 我们不需要显式声明第3方模块


(译按: 没有提及新版本的子模块目录名同名文件约定, 这样不用形成太多 mod.rs 在不同目录中;
另外, 如何利用子 crate 或是子库, 以及 workspace 等等更多, 更加灵活, 
可以用来管理更大工程的模块约定, 也没有阐述...
这都值得继续探索...)


## refer.

[常见问题解答 · Rust 程序设计语言](https://prev.rust-lang.org/zh-CN/faq.html#modules-and-crates)

- [第九章 - 项目的结构和管理 - Rust 语言之旅 - Let's go on an adventure!](https://tourofrust.com/104_zh-cn.html)
- [使用包、Crate 和模块管理不断增长的项目 - Rust 程序设计语言 简体中文版](https://kaisery.github.io/trpl-zh-cn/ch07-01-packages-and-crates.html)
- [包和模块 - Rust语言圣经(Rust Course)](https://course.rs/basic/crate-module/intro.html)
- [文件分层 - 通过例子学 Rust 中文版](https://rustwiki.org/zh-CN/rust-by-example/mod/split.html)





```
         _~^*∽~_
     \/ /  # ◵  \ (/
       '_   ⩌   _'
       | '--+--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```