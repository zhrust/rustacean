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

## Benefits (and Detriments) of Default Parameters
Defaults are good, and default parameters in this style are one way to implement them and reap their benefits.

Defaults are good because they uphold the DRY principle – Don’t Repeat Yourself. If we didn’t have defaults, we’d have to repeat parameters that don’t actually contribute to understanding of the goals of the code. And if the best default parameters changed in such a way that the best way to update the code was to continue using the default – perhaps because of a change of best practices – we’d have to update every call rather than just changing it once, where the default parameter is defined.

Defaults are also good because they decrease the programmer’s cognitive load. Programmers have to keep a lot of information in their brain at a time, and defaults help programmers by not forcing them to think about extra details when they don’t matter – which is the usual situation for most defaults.

Default parameters also make the code more concise, and are popular for that reason. But this isn’t a particular value that I have. I believe the DRY principle is important, and that often amounts to more concise code, but given modern editors and IDE, and modern expectations of typing and reading speed, a moderate amount of verbosity in exchange for other benefits (such as clarity and explicitness) is completely acceptable to me. I believe that default parameters, as they are implemented in C++ and Python, have a substantial cost in clarity and explicitness, and therefore conciseness isn’t a good enough reason to justify them.

In this case, what particularly bothers me about the lack of clarity is that the reader of the code doesn’t know that there are potentially more parameters; there is no hint that there might be other parameters. If a maintenance programmer wants to change one of these calls to make invisible windows instead, they might not realize they should check the documentation for create_window: after all, it only seems to take two parameters, and neither of them have anything remotely to do with invisible windows.

Fortunately, Rust has alternative features that allow us to reap the benefits for cognitive load and DRY without sacrificing explicitness and clarity.

## Defaults in Rust: the Default trait
Rather than allowing default parameters, Rust allows you to optionally specify default values for your types using the Default trait. Here’s how it works:

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


Or, written using the more concise derive syntax:

```rust
#[derive(Default)]
enum Foo {
    #[default]
    Bar,

    Baz,
}
```


Once this default is defined, Foo::default() or even (in a context where the type is clear) Default::default() can stand in for Foo::Bar.

If you are used to re-using existing types for your function parameters, this might seem worse than useless. After all, the parameter we defaulted was of type bool, and the orphan rule (explained in the Rust book’s chapter on traits) forbids us from defining the Default trait on bool – as I alluded to above, Default allows you to define default values for your types. And even if we could, setting a default on booleans is way too overpowered a thing to do just to give this one function parameter have a default! After all, some other function might also have a boolean parameter with a different default.

But this makes more sense if you consider that in Rust, it is common – even idiomatic and preferred – to create custom types for things like configuration and function parameters. After all, if you’re not looking at the documentation, it can be unclear what true means. It’s not even clear that it has anything to do with visibility, let alone that true means that the window is to be visible when the parameter could just as easily be called invisible.

In Rust, we would prefer to define a new type for this situation, an enum listing the visibility options – which will also help if a new visibility option is created. And on this enum, it would be reasonable to declare a default:

```rust
#[derive(Default)]
enum WindowVisibility {
    #[default]
    Visible,

    Invisible,
}
```


Yes, this is more verbosity, but it is more clear, and no less DRY, than our original code. Conciseness is again not a value in and of itself. Explicitly listing the options is preferred to leaving them implicit.

Then, when we call the function, we can use this default:

```rust
fn create_window(width: u32, height: u32, visibility: WindowVisibility) -> WindowHandle;

let handle = create_window(10, 30, WindowVisibility::Invisible);
let handle2 = create_window(100, 500, WindowVisibility::Visible);

let handle3 = create_window(100, 500, WindowVisibility::default());
let handle4 = create_window(100, 500, WindowVisibility::default());
let handle5 = create_window(100, 500, Default::default()); // Also permitted
```


This is, as promised, more verbose, but equally DRY, and much more explicit and clear.

NB: I’m using free-standing functions for example purposes only. In reality, this particular function is just as likely to be part of a type’s intrinsic methods, something like WindowHandle::new or WindowHandle::create_window.

### Scaling defaults in Rust: Struct update syntax
So this is all well and good for one default. But it doesn’t scale that well. What if we want to add another 3 parameters to our window creation function? In a language like C++, we can give them defaults, and the callers don’t even need to be updated (parameters are for example purposes only and do not represent a well-thought out list of what you might want to specify in creating a window):

```rust
WindowHandle createWindow(int width, int height, bool visible = true,
                          WindowStyle windowStyle = WindowStyle::Standard,
                          int z_position = -1,
                          bool autoclose = false);

createWindow(100, 500); // Still works identically
createWindow(100, 500, false); // Also still works
createWindow(100, 500, false, WindowStyle::Standard, 2, true); // Specify everything
```


This is a useful feature. In Rust, with the techniques we’ve discussed so far, we’d have to write Default::default() repeatedly for however many parameters there are. This is a DRY violation, and interferes with the ability to add new parameters.

There is a flaw with this feature, however. You’ve now constrained yourself to specifying parameters to the left in order to specify parameters on the right. In the last example call to createWindow, we violate DRY by explicitly specifying a value when we probably wanted to use the default, but that wasn’t available because we wanted to override the default for a later parameter.

Fortunately, Rust has a version of this too. Just as we created an enum just for the purposes of this function call, it is idiomatic in Rust to create structures for configuration parameters like this. The structure would look something like this:

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


Then, we can implement Default for that entire struct:

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

Now, this might seem to be extremely tedious to use. You might imagine using it something like this:

```rust
let mut config = WindowConfig::default();
config.width = 500;
config.z_position = 2;
config.autoclose = AutoclosePolicy::Enable;
let handle = create_window(config);
```

I would argue that even this is preferable to default parameters, because again, it is explicit. However, Rust has a syntactic construct designed exactly for situations like this, struct update syntax. With it, we get something very similar to default parameters, but a little more verbose, a lot more explicit, and a lot more flexible:

```rust
let handle = create_window(WindowConfig {
    width: 500,
    z_position: 2,
    autoclose: AutoclosePolicy::Enable,
    ..Default::default()
});
```


Unlike C++-style default parameters, we can override exactly the defaults we want to. It is also explicitly clear that there are other parameters we could modify if we wanted to, without forcing the maintenance programmer to check the documentation.

But beyond that, this allows there to be other sets of defaults defined. In addition to WindowConfig::default, there might be another set of configuration parameters for creating dialog boxes, like WindowConfig::dialog() or WindowConfig::default_dialog. An app where the programmer usually creates invisible windows, or windows all of the same height, might define its own default set, config::app_local_default_window_config(). These wouldn’t be mediated through the Default trait, but Default is just a trait, and Default::default() is just a method call. You can call your own methods instead, and still use this struct update syntax.

So now, we have a system of idioms in Rust to replace default parameters. It’s just as DRY, and decreases the cognitive load just as much. More importantly, it does so without sacrificing explicitness and clarity as to exactly what’s going on – a given function always takes the same number of parameters, which is an invariant that Rust maintenance programmers can (and do) rely on.

### The Builder Pattern
At this point, the old-hand Rustaceans in the audience will note that I haven’t discussed one common Rust approach to designing these configuration structs, the builder pattern.

That’s for a reason: I don’t like it. I personally prefer to use Default and struct update syntax where others might reach for the builder pattern. I think it’s less explicit, and since I have a lot of experience in non-OOP programming languages, it feels to me like a solution without a problem, the primary upshot of which is to make the code look more object-oriented.

But it is a commonly used pattern in Rust, and you will use crates that use the builder pattern, so it’s worth being familiar with it. It’s the same concept as before: using a struct full of parameters to send configuration to a constructor or to a function call. It’s probably going to be called something like WindowBuilder instead of WindowConfig.

However, instead of using the struct update syntax directly, a bunch of helper methods are added to do the struct update:

```rust
impl WindowBuilder {
    fn height(mut self, height: u32) -> Self {
        self.height = height;
        self
    }

    // ...
}
```


Or, as I would notate it:

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

Sometimes, enumerations are split into multiple update methods:

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

Then, normally, instead of calling e.g. the window constructor, you call a build method defined on the builder (and at this point I cringe at the gratuitous OOP philosophy influencing the design):

```rust
impl WindowBuilder {
    fn build(self) {
        window_create(self)
    }
}
```
Then, instead of using struct update syntax, you chain together calls to these methods:

```rust
let handle = WindowBuilder::new()
    .width(500)
    .z_position(2)
    .autoclose_enable()
    .build();
```

I still prefer this to default parameters, but I also find it tacky. I don’t like being forced to think in terms of abstract “objects” like builders, and I don’t like the presumption that this style is more intuitive. Why is a “builder” an object that does something? Why is that prefered to a structure that is “configuration”? Are OOP programmers aware that in real life, the vast majority of objects literally don’t do things, and certainly don’t build other objects?

But for people familiar with the idioms of object-oriented programming, this might be preferable. It is a commonly chosen option, so it’s important at least to recognize it.

## Conclusion and Application
Rust has a lot of idioms that are different from those in other programming languages. I often see proposals from new Rustaceans to add default parameters – and other similar features – to Rust, and these new Rustaceans are confused that the strong demand they feel is not as widely felt in the greater Rust community.

And normally, it’s similar to this situation with default parameters. There are alternative idioms that accomplish the same goals, to the extent that those goals are in line with Rust’s values: in this case, DRYness, and reducing developers' cognitive loads. They are also better solutions in some other ways, according to Rusty values: the additional explicitness is worth a little more verbosity.

But often, the new Rustaceans making these proposals are unaware of the Rusty way of doing things. And if they are aware of it, they are approaching it from the goals of other programming languages, and don’t see how the solution measures up.

So I hope this can serve as a case study to help people understand that there often are Rusty ways of accomplishing the goals of popular features from OOP land, and why Rustaceans prefer these solutions to blind accumulation of features.



## logging
> 版本记要

- ..
- 230212 ZQ init.


