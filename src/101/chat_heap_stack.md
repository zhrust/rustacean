# 可变/不可变引用态度
> 学伴ChatGPT, chatting for debugging ...

## background
> 李明 coding到灯火阑珊 2023-03-24 06:00

[Rust开发人员经常犯的5个常见错误](https://mp.weixin.qq.com/s/KXfCHeFuLvK8PHAkA5QJmA)

## goal

完成合理概念摸查...

## trace

> Q: rust 代码:

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("long string is long");
    let result;
    {
        let string2 = String::from("xyz");
        // 这一行将导致编译错误
        result = longest(string1.as_str(), string2.as_str());
    }
    println!("The longest string is {}", result);
}

```

为什么出错?如何修改? 以及如何理解?

> A:该程序出错是因为 string2 的生命周期比 result 的生命周期短，而 result 是一个指向 string2 中的引用，因此在 string2 离开作用域后，result 指向的内存已经被释放，这会导致未定义的行为。

为了解决这个问题，我们需要让 result 的生命周期比 string2 的生命周期更长。有多种方法可以实现这一点，以下是其中的一种：

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("long string is long");
    let result;
    let string2 = String::from("xyz");
    result = longest(string1.as_str(), string2.as_str());
    println!("The longest string is {}", result);
}
```
在这个修改后的程序中，我们将 string2 的声明移到了 result 的声明之前，并且不再使用一个代码块来限制 string2 的作用域。这意味着 string2 和 result 的生命周期相同，因此 result 仍然有效。

该程序的代码使用了 Rust 的生命周期注释 'a 来告诉编译器 longest 函数的返回值的生命周期应该与 x 和 y 的生命周期相同。

简单地说，程序中的修改让 string2 和 result 具有相同的生命周期，从而解决了问题。

> Q: let string2 = "xyz"; 是否也可以解决相同的问题? 为什么?

> A:是的，如果将 string2 的类型从 String 改为字符串字面量 &str，则程序就可以正确编译和运行。修改后的程序如下：

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("long string is long");
    let string2 = "xyz";
    let result = longest(string1.as_str(), string2);
    println!("The longest string is {}", result);
}
```

字符串字面量在编译时就已经存在于程序的二进制文件中，因此它们的生命周期与程序的生命周期相同，而不需要在堆上分配内存。这意味着它们的生命周期与其他在程序中定义的变量的生命周期相同，因此在使用字符串字面量时不需要担心生命周期的问题。

所以使用字符串字面量作为参数传递给 longest 函数是安全的，因为它们的生命周期已经在编译时确定了，并且与函数中的其他变量的生命周期相同。

> Q: 那么, 为什么 longest() 一定要指定参数的生命周期? 没有其它更加简洁的形式了嘛?

> A: 在 Rust 中，str 是一个字符串 slice 类型，它是一个不可变的、固定长度的引用类型。由于 str 引用的是存储在堆上的字符串数据，因此它的生命周期必须是由该字符串的所有权来决定的。

在 longest() 函数中，x 和 y 的类型是 &'a str，这表示它们是指向某个字符串数据的引用，它们的生命周期被限制为 'a，即函数的生命周期。这是必要的，因为函数的返回值也是一个对字符串数据的引用，它的生命周期必须是在函数返回后才能开始的，而且必须与参数的生命周期相关联，以避免悬垂引用的问题。

如果我们将参数类型改为 str，那么就无法控制它们引用的字符串的生命周期，因为它们不是引用类型。如果我们试图通过将 string1 和 string2 的值进行 clone 来传递它们的副本，这样可能会导致堆分配的额外开销和性能问题，因为这需要为每个字符串分配一个新的内存块，并在函数调用结束后释放这些内存块。

因此，在 longest() 函数中，最好使用字符串 slice 类型 &str，并在调用函数时传递指向原始字符串的引用，以确保在不需要分配额外内存的情况下正确处理字符串。

> Q: 明白了, 如果不考虑性能, 使用 clone 也是可以的

> A: 是的，如果不考虑性能问题，你可以通过使用 clone() 方法来创建传递给 longest() 函数的字符串的拷贝。这将使每个字符串都在堆上分配新的内存，并使 longest() 函数能够接受 String 类型的参数。

例如，可以使用下面的代码来调用 longest() 函数，使用 clone() 方法创建了 string1 和 string2 的副本：

```rust

fn longest(x: &str, y: &str) -> &str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("long string is long");
    let string2 = String::from("xyz");
    let result = longest(string1.as_str(), string2.as_str());
    println!("The longest string is {}", result);

    // Create clones of the strings and pass them to longest()
    let string3 = string1.clone();
    let string4 = string2.clone();
    let result2 = longest(string3.as_str(), string4.as_str());
    println!("The longest string is {}", result2);
}

```
注意，这种方法可能会产生性能问题，因为每次调用 clone() 方法都会分配新的内存并复制字符串的内容。因此，如果性能是一个问题，最好避免使用 clone() 方法来创建字符串的副本。


> Q: 明白了, 那么 堆与栈的本质区别是什么? 为什么 rust 对栈这么信任, 对堆却很警惕?

> A: 在计算机科学中，堆和栈都是内存中用于存储程序数据的数据结构。它们之间的本质区别在于它们的内存分配方式和数据存储的生命周期。

栈是一种先进后出的数据结构，它使用固定大小的内存块来存储程序数据。当一个函数被调用时，该函数的参数、局部变量和返回地址等数据将被存储在栈帧中。当函数返回时，该栈帧将被弹出，其中存储的数据也将被销毁。由于栈内存的分配和释放是由程序自动进行的，因此它们的效率非常高。

堆是一种动态的数据结构，它使用不连续的内存块来存储程序数据。堆内存的分配和释放是由程序员手动管理的，它们的效率相对较低。由于堆内存的生命周期不像栈那样易于确定，因此在使用堆内存时需要注意内存泄漏和悬垂指针等问题。

在 Rust 中，栈上的数据是可以直接在栈帧中进行分配和释放的，因此 Rust 对栈的管理非常信任。但是，由于堆上的数据需要手动管理，因此在 Rust 中对堆的管理要更加警惕，以避免内存泄漏和悬垂指针等问题。因此，在 Rust 中使用堆内存时，必须遵循所有权规则，以确保每个值都有且只有一个所有者，并在所有者超出作用域时自动释放其内存。这也是 Rust 中所有权系统的核心概念。


> Q: 那么, rust 内建数据类型中, 哪些是栈, 哪些是堆?

> A: 在 Rust 中，内建数据类型可以分为两类：栈上分配的值和堆上分配的值。

以下是一些常见的栈上分配的值：

- 所有基本数据类型（例如整数、布尔值和浮点数）
- 数组和元组（当它们包含栈上分配的值时）
- 函数和闭包

以下是一些常见的堆上分配的值：

- 所有标准库集合类型，例如 Vec、String 和 HashMap 等
- Box 智能指针和 Rc 引用计数指针
- 闭包（如果它们捕获了堆上分配的值）


需要注意的是，Rust 中的**所有类型都可以在堆上分配，只要使用堆分配器**（如 Box、Vec 或者 String）即可。但是，所有权系统确保这些堆上分配的值仍然遵循所有权规则，以确保内存安全。


> Q: 明白了, 也就是说 String::from("xyz") 是堆上内存, 但是, "xyz" 是栈上内存,
那么, 为什么都是生成不可变字符串, 为什么 Rust 要构建出堆上字符串 String::from("xyz") ?
问题是 String::from("xyz")  有什么比 "xyz" 的好处?


> A: 是的，您的理解是正确的。"xyz" 是一个编译时常量，分配在程序的栈上，它是一个静态分配的不可变字符串。而 String::from("xyz") 是在运行时动态分配的堆上的一个不可变字符串。

Rust 之所以提供 String 类型，是因为它具有以下一些优点：

- 动态长度：在堆上分配一个字符串，它的长度可以在运行时根据需要动态增加或减少，这是栈上分配的静态字符串所不能做到的。
- 丰富的字符串处理功能：String 类型提供了各种字符串处理功能，例如拼接、切割、查找、替换等。
- UTF-8 编码：Rust 中的字符串类型都是基于 UTF-8 编码的，这意味着它们可以表示世界上几乎所有语言中的字符，包括非拉丁字符集，而不会出现编码问题。


但是，由于动态分配内存涉及到堆的使用，这会带来一些额外的开销和复杂性。因此，在编写 Rust 代码时，应该尽可能地使用栈上分配的数据类型来避免堆分配的开销。仅当需要动态长度或其他特殊功能时，才应该使用堆上分配的类型。


## refer.
> 其实官方的文档吃透, 基本可以平趟 80% 的日常开发了...

以及将自己伪装成一个认真又很笨的学员,
GPT 们就可以无限耐心的反复回答所有问题, 当然, 得配套自行检验以及官方文档证实:


- [什么是所有权？ - Rust 程序设计语言 简体中文版](https://kaisery.github.io/trpl-zh-cn/ch04-01-what-is-ownership.html#%E6%A0%88stack%E4%B8%8E%E5%A0%86heap)
- [生命周期基础 - Rust By Practice( Rust 练习实践 )](https://zh.practice.rs/lifetime/basic.html)
- [字符串：str和String - Rust入门秘籍](https://rust-book.junmajinlong.com/ch3/04_str_string.html#%E5%AD%97%E7%AC%A6%E4%B8%B2%E5%AD%97%E9%9D%A2%E9%87%8F)
- [理解Rust内存管理 - Rust入门秘籍](https://rust-book.junmajinlong.com/ch5/01_heap_stack.html)
    - [堆空间和栈空间 - Rust入门秘籍](https://rust-book.junmajinlong.com/ch5/01_heap_stack.html)
    - ...
- [使用Box<T> 指向堆上数据 - Rust 程序设计语言 简体中文版](https://kaisery.github.io/trpl-zh-cn/ch15-01-box.html#%E4%BD%BF%E7%94%A8-boxt-%E5%9C%A8%E5%A0%86%E4%B8%8A%E5%82%A8%E5%AD%98%E6%95%B0%E6%8D%AE)


```
     _~`|~~_
 \/ /  = →  \ ()
   '_   ∧   _'
   / '--~--' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```