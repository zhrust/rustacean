# Rust 和默认参数
原文: [Rust and Default Parameters :: The Coded Message](https://www.thecodedmessage.com/posts/default-params/)

> 快译


Rust 不支持函数声明中的默认参数;
而且和很多语言不同, 无法通过函数重载来模拟;
这让很多来自其它编程语言的 Rustacean 新人感到沮丧,
所以, 就想解释一下为什么这其实是件好事儿,
以及,如果使用默认 trait 和结构更新语法来实现类似的效果;


默认参数(和函数重载)不是面向对象编程的一部分,
但是,又是许多 Rustaceans 新人原先编程语言的共同特征;
因此, 这篇文章在某些方面和我正在进行的关于 Rust 如何不是面向对象的系列文章相吻合,
故而, 被标准为这个系列的文章;
还受到 Reddit 中对我第一篇 OOP 相关贴子回复的启发;


## 默认秋粮是如何工作咯(比如 C++)

在开始讨论为什么 Rust 没有默认参数以及我们可以折腾什么之前,
得先聊明白什么是默认参数以及在哪些情况下有用;


假设你有一个带有很多参数的函数,
比如(以 Reddit 回复中的示例)在 GUI 中创建一个窗口:

```C++
WindowHandle createWindow(int width, int height, bool visible)

auto handle = createWindow(10, 30, false); // Create invisible window
auto handle2 = createWindow(100, 500, true); // Create visible window
```

现在, 假设你准备创建的大多数窗口都是可见的,
并且,你不想让程序员负担必须指定窗口是否可见的担心 --- 甚至于不想明确的考虑这事儿 --- 在正常情况下,
在支持默认参数的编程语言中,你可以为可见性提供默认值:

```C++
WindowHandle createWindow(int width, int height, bool visible = true)

auto handle = createWindow(10, 30, false); // Create invisible window!

auto handle2 = createWindow(100, 500, true); // Create visible window!

auto handle3 = createWindow(100, 500); // Also create visible window!
auto handle4 = createWindow(100, 500); // Most of the time, that's what
auto handle5 = createWindow(100, 500); // you want, so why have to say it?
Default parameters can also be simulated with function overloading for programming languages where function overloading is available but default parameters are not:

WindowHandle createWindow(int width, int height, bool visible);

WindowHandle createWindow(int width, int height) {
    return createWindow(width, height, true);
}
```

Rust 也没有函数重载,这是个复杂的多的问题,
但是, 很多相同的论点都适用这个习惯用法的理解;

## 默认参数的好处(和坏处)

默认值很好,这种风格的默认参数是实现并从中获益的一种方式;

默认值是好的,因为,她们坚持 DRY 原则 --- 不要重复自己(Don’t Repeat Yourself);
如果我们没有默认值, 就不得不重复那些实际上对理解代码没有帮助的参数;
如果最佳默认秋粮的更改方式楼主更新代码的最佳方法是继续使用默认值--- 也许因为最佳实践发生了变化 ---
我们将不得不更新每个调用, 而不是只要更改一处, 定义了默认参数那里;

默认徝很好,因为,她们减少了程序员的认知负担;
程序员必须一次性在大脑中保留大量信息,
而默认设置通过不强迫在无关场景时要考虑额外的细节来帮助程序员---这是太多数默认设置的常见作用场景;

默认秋粮也使代码更加简洁,
因此, 很受欢迎;
但是,这不是专有的特殊价值;
我相信 DRY 原则很重要, 这通常意味着更加简洁的代码,
但是,考虑到现代编辑器和 IDE, 以及现代人劝为把不用又和阅读速度的期待,
适度的冗长以能换取其它好处(比如, 清晰度和明确性),
我还是完全可以接受的;
相信默认参数,因为这是在 C++ 和 Python 中实现的,
在清晰度和明确性方面付出了巨大的代价,
因此,简洁性并不是证明她们合理的充分理由;

在这种情况中, 让我特别困扰的是代码中的不清晰之处,
在于代码的读者不知道可能还有更多的参数;
没有暗示可能还有其它秋粮;
如果维护者想更改其中一个调用以便创建不可见的窗口,
领导作用可能没有意识到应该先检验 create_window 的文档:
毕竟, 似乎只接受两个参数,
而且也没有任何远程反应针对不可见窗口;

幸运的是, Rust 具有替代特性,
使我们能在不牺牲明确性和清晰性的情况下,
也获得认知负荷和 DRy 的好处;


## Rust 中的默认值: 默认 trait

Rust 不允许使用默认参数,
而是允许你使用 Default trait 有选择的为你的类型指定默认值;

是这样工作的:


```rust
enum Foo {
    Bar,
    Baz,
}

impl Default for Foo {
    fn default() -> Self {
        Foo::Bar
    }
}
```

或是, 使用更加简洁的 派生/derive 语法编写:


```rust
#[derive(Default)]
enum Foo {
    #[default]
    Bar,

    Baz,
}
```

一旦定义了这个默认值,
Foo::default() 或是(在类型明确的上下文中) Default::default() 就可以代表 Foo::Bar ;

如果你习惯为你的函数参数重用现有类型,
这可能看起来比不用更加糟糕;
毕竟, 我们默认的参数是 bool 类型的,
孤儿规则(在 Rust 的 trait 相关章节有解释) 禁止我们在 bool 上定义默认 trait ---
正如我在上面提及的, Default 允许你对类型定义默认值;
即便,我们可以为 bool 设置默认值也是一件过于强大的事儿,
无法仅仅为这个函数参数提供默认值!
毕竟, 其它一些函数也可能有一个具有不同默认值的 bool 类型参数;


但是,如果在 Rust 中考虑, 这更加有意义 --- 甚至是惯用的和首选的 --- 为配置和函数参数等等创建自定义类型;
毕竟, 如果你不查实文档, 可能不清楚 true 的含义;
甚至于不清楚和可见性有什么关系,
更不用说很容易将 true 当参数时意味着不可见窗口是可见的;

在 Rust 中,我们更加愿意为这一情况定义一个新类型, 一个列出可见性选项的枚举---如果创建一个新的可见性选项,
这才有所帮助;
在这个枚举上, 声明一个默认值才是合理的:


```rust
#[derive(Default)]
enum WindowVisibility {
    #[default]
    Visible,

    Invisible,
}
```

是的, 这比我们的原始代码有些冗长, 但更清晰,
而且不乏 DRY ;
简洁本身并不是一种价值;
明确的列出选项比隐式选项更可取;


然后, 当我们调用该函数时, 可以这么使用默认值:

```rust
fn create_window(width: u32, height: u32, visibility: WindowVisibility) -> WindowHandle;

let handle = create_window(10, 30, WindowVisibility::Invisible);
let handle2 = create_window(100, 500, WindowVisibility::Visible);

let handle3 = create_window(100, 500, WindowVisibility::default());
let handle4 = create_window(100, 500, WindowVisibility::default());
let handle5 = create_window(100, 500, Default::default()); // 也允许
```

正如承诺的那样, 这样冗长些, 同样 DRY,
但是, 更加明确和清晰; (无歧义)


注意: 我使用独立函数只是为了举例;
实际上, 这个特定函数很可能是类型内部方法的一部分,
例如 WindowHandle::new 或是 WindowHandle::create_window;


### Rust 中默认值缩放: 结构更新语法

所以, 这对于一个默认值来说形式上更好;
但是,拓展性并不好;
如果我们想在我们的窗口创建函数中追加另外3个参数怎么办?
在 C++ 中, 可以可以为她们提供默认值,
调用者甚至不需要更新(参数仅用来示例, 并不代表在创建窗口):


```C++
WindowHandle createWindow(int width, int height, bool visible = true,
                          WindowStyle windowStyle = WindowStyle::Standard,
                          int z_position = -1,
                          bool autoclose = false);

createWindow(100, 500); // Still works identically
createWindow(100, 500, false); // Also still works
createWindow(100, 500, false, WindowStyle::Standard, 2, true); // Specify everything
```

这是一个有用的功能;
在 Rust 中,使用目前讨论的技术,
无论参数有多少,我们都必须重复编写 Default::default() ;
这是 DRY 违规行为, 会干挠追加新参数的能力;

但是, 此功能也存在缺陷;
你现在已经限制自己在左侧指定参数,
以便在右侧追加参数;
在调用 createWindow 最后一个示例中, 我们通过显式指定一个值来违反 DRY,
当时我们可能想使用默认值,但是,该值不可用, 因为,我们想为以后的参数覆盖默认值;

幸运的是, Rust 也有这种版本;
正如我们只是为了这个函数调用而创建了一个枚举一样,
在 Rust 中为这种配置参数创建结构也是惯用的;
该结构看起来像这样:

```rust
pub struct WindowConfig {
    pub width: u32,
    pub height: u32,
    pub visibility: WindowVisibility,
    pub window_style: WindowStyle,
    pub z_position: i32,
    pub autoclose: AutoclosePolicy,
}
```

然后, 我们就可以为整个结构指定 Default:

```rust
impl Default for WindowConfig {
    fn default() -> Self {
        Self {
            width: 100,
            height: 100,
            visibility: WindowVisibility::Visible,
            window_style: WindowStyle::Standard,
            z_position: -1,
            autoclose: AutoclosePolicy::Disable,
        }
    }
}
```

现在, 似乎使用起来很乏味;
你可能想象得这么使用:

```rust
let mut config = WindowConfig::default();
config.width = 500;
config.z_position = 2;
config.autoclose = AutoclosePolicy::Enable;
let handle = create_window(config);
```

我认为即便是这样也比默认秋粮可取,
因为,这样是明确的;
然而, Rust 有一个专门为这种情况设计的语法结构:
struct update syntax ;
有了这,我们获得的东西和默认参数非常相似,
但是,更冗长/明确/灵活:


```rust
let handle = create_window(WindowConfig {
    width: 500,
    z_position: 2,
    autoclose: AutoclosePolicy::Enable,
    ..Default::default()
});
```

不像 C++ 风格的言论参数,
我们可以完全覆盖我们想要的默认值;
同样明确的是,
如果我们愿意, 甚至可以修改其它参数,
而不需强制维护开发者检查文档;

除此之外, 这样允许定义其它默认值集;
除了 WindowConfig::default 之渑, 可能还有另外一组用来创建对话框的配置参数,
例如: like WindowConfig::dialog() 或是 WindowConfig::default_dialog ;
程序员通常在创建不可见窗口, 或是高度相同的窗口应用,
可能会定义自己的默认设置, config::app_local_default_window_config();
这些不会通过 Default 特性来调解,
但是, Default 只是一个 trait ,
而 Default::default() 是一个方法调用;
你可以改为调用自己的方法,
并仍然使用此`结构更新语法`;

所以,现在我们在 Rust 中有一个习惯用语系统来替换默认参数;
这和 DRY 一样,
并且同样减少了认知负荷;
更加重要的是, 这样作并没有牺牲对到底发生了什么的明确性与清晰性 --- 一个给定的函数总是采用相同数量的参数,
这是 Rust 维护开发者可以(并且正在)依赖的不变量;


### 构建器模式

在这点上, Rustacean 老手们应该能注意到还没讨论一种通用的 Rust 方法来设计这些配置结构,
即:  `构建器模式` (Builder Pattern);

这是有原因的: 我不喜欢丫的;
(译按: 千金婎买我愿意, 没错...)
我个人更加喜欢使用 Default 和 struct update 语法,
其它人可能会使用  `构建器模式`  ;
我认为这种模型不够明确, 而且由于在非 OOP 编程语言方面有很多经验,
所以,我觉得这是一种没有问题的解决方案, 主要成果只是令代码看起来更加 OOP 而已;

不过, 这也是 Rust 中常用的模式, 一般使用 `构建器模式` 的 crate,
因而值得熟悉之;
这和以往的概念相同:
使用充满参数的结构, 将配置发送到 构建函数或是函数调用;
有时这种会被称为 WindowBuilder 而不是 WindowConfig;

但是, 不直接使用结构更新语法, 而是添加了一堆辅助方法来执行结构更新:


```rust
impl WindowBuilder {
    fn height(mut self, height: u32) -> Self {
        self.height = height;
        self
    }

    // ...
}
```

或者, 正如想指出的那样:

```rust
impl WindowBuilder {
    fn height(self, height: u32) -> Self {
        Self {
            height,
            ..self
        }
    }

    // ...
}
```

有时, 枚举被拆分为多个更新方法:


```rust
impl WindowBuilder {
    fn autoclose_enable(mut self) -> Self {
        self
        self.autoclose = AutoclosePolicy::Enable;
    }

    fn autoclose_disable(mut self) -> Self {
        self.autoclose = AutoclosePolicy::Disable;
        self
    }
}
```

然后, 通常并不是调用例如: window constructor,
你调用在构建器上定义的构建方法
(此时,已经对影响设计的无偿 OOP 哲学感到畏缩)


```rust
impl WindowBuilder {
    fn build(self) {
        window_create(self)
    }
}
```

其实,不用 struct update 语法,
而是将对这些方法调用链接在一起:


```rust
let handle = WindowBuilder::new()
    .width(500)
    .z_position(2)
    .autoclose_enable()
    .build();
```


我仍然更加喜欢这个, 而不是默认参数,
但是, 同时也感觉有点俗气;
我不喜欢被迫使用像 构建器 这样的抽象"对象"来思考,
也不喜欢这种风格中更直观的假设;
为什么 "构建器" 是作某件事儿的对象?
为什么它比"配置"结构更受欢迎?
OOP 程序员是否意识到在现实生活中, 绝大多数对象根本不作任何事儿,
当然, 也不会构建其它对象?

但是, 对于熟悉 OOP 习惯用法的人来说,
这可能更可取;
这是一个普通选择的选项, 因此, 至少识别这种模式很重要;



## 结论和应用

Rust 有很多不同于其它语言的习惯;
我经常看到新的 Rustacean 提议为 Rust 添加默认参数和其它类似的功能,
而这些新 Rustacean 感到困惑的是, 
领导作用感受到的强烈要求在更大的 Rust 社区中并没有被广泛感受到;

通常, 这和默认参数类似;
有实现相同目标的替代习语, 嘦这些目标符合 Rust 的价值观:
在此场景中, DRYness 并减少开发者认知负担;
根据 Rusty 的价值观, 她们在其它方面也是更好的解决方案: 额外的明确性值得多点冗长代码;


所以, 我希望这可以作为一个案例研究来报时大家理解,
通常总是有 Rusty 的方法来实现 OOP 领域流行功能目标,
以及, 为什么 Rustacean 更加喜欢这些方案而不是盲目的积累新功能;



## logging
> 版本记要

- ..
- 230220 ZQ v0 DONE
- 230212 ZQ init.


