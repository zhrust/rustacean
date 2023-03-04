# dyn:动/静态多态初步
> 学伴ChatGPT, chatting for debugging ...

## background
> Rust 中文社区中的讨论...

![这种用if let就会报错，必须分开写吗](https://ipic.zoomquiet.top/2023-02-28-%E9%A3%9E%E4%B9%A620230228-150444.jpg)


## goal

合理完成调试...

## trace

有同学建议:
```rust
if let Ok(exists) = conn.exists::<bool, _>(key).await {
    unimplemented!()
}
```

于是开始探问:

> Q:

if let Ok(exists) = conn.exists::<bool, _>(key).await {
}
这句代码什么意思?

> A:

这句代码是Rust语言的代码，用于在Redis数据库中检查指定键是否存在，并异步地返回一个结果。

具体来说，这段代码首先调用一个Redis连接对象（conn）上的exists方法来检查给定的key是否存在。该方法返回一个Result<bool, _>类型的结果，其中Ok表示检查操作成功，exists表示指定的key存在，否则返回一个错误对象（_表示任意的错误类型）。

然后，这段代码使用if let语法，将返回的结果绑定到一个名为exists的变量上。如果exists是Ok类型，则意味着检查操作成功，并且可以继续执行if代码块中的逻辑来处理key存在的情况。反之，如果exists是Err类型，则意味着检查操作失败，并且需要在else代码块中处理错误情况。

> Q:

一般在 else 中如如何处理错误?
如果 exists 是 Ok , 这时 那个 key 是如何进入 if 代码块进行处理的?

> A:

在 else 中，一般会处理检查操作失败的情况，例如记录日志、返回错误信息等。具体如何处理错误，取决于代码的设计和业务需求。以下是一个简单的例子，展示了在 else 中如何记录错误信息：

```rust
if let Ok(exists) = conn.exists::<bool, _>(key).await {
    if exists {
        // 如果 key 存在，则执行相应的逻辑
    } else {
        // 如果 key 不存在，则执行相应的逻辑
    }
} else {
    // 如果检查操作失败，则记录错误信息并返回错误
    eprintln!("Failed to check if key exists: {:?}", key);
    return Err(MyError::RedisError);
}
```

> Q:

在上面的代码中，如果检查操作成功，则根据 exists 的值分别执行相应的逻辑。如果检查操作失败，则使用 else 代码块来记录错误信息，并返回一个自定义的错误类型（MyError::RedisError）。

如果 exists 是 Ok，则表示检查操作成功，exists 变量将包含一个布尔值，指示给定的 key 是否存在。在这种情况下，程序将进入 if 代码块，根据 exists 的值执行相应的逻辑。例如，如果 exists 为 true，则表示 key 存在，程序将执行相应的逻辑来处理 key 存在的情况。反之，如果 exists 为 false，则表示 key 不存在，程序将执行相应的逻辑来处理 key 不存在的情况。

> A:

是的，你是对的。在你提供的代码片段中，key 是在之前定义的。在这种情况下，我们可以假设在这段代码之前，已经定义了一个名为 key 的变量，用于指定要检查的 Redis 键名。

例如，以下是一个使用 Redis 进行键值存储的简单示例，其中使用了类似于你提供的代码片段：

```rust
use redis::AsyncCommands;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = redis::Client::open("redis://127.0.0.1/").unwrap();
    let mut conn = client.get_async_connection().await?;

    // 定义要检查的 Redis 键名
    let key = "my_key";

    // 检查指定的键是否存在
    if let Ok(exists) = conn.exists::<bool, _>(key).await {
        if exists {
            // 如果 key 存在，则执行相应的逻辑
            let value: String = conn.get(key).await?;
            println!("{}: {}", key, value);
        } else {
            // 如果 key 不存在，则执行相应的逻辑
            conn.set(key, "Hello, Redis!").await?;
            println!("Set {} successfully", key);
        }
    } else {
        // 如果检查操作失败，则记录错误信息并返回错误
        eprintln!("Failed to check if key exists: {:?}", key);
        return Err("RedisError".into());
    }

    Ok(())
}

```

在这个示例中，我们首先定义了一个名为 key 的变量，用于指定要检查的 Redis 键名。然后，我们使用 conn.exists 方法检查指定的键是否存在。如果检查操作成功，则根据检查结果的值（即变量 exists）执行相应的逻辑。如果检查操作失败，则记录错误信息并返回错误。在这个例子中，我们使用 eprintln 来记录错误信息，并使用 return Err(...) 返回一个字符串类型的错误信息。最后，我们使用 Ok(()) 返回一个表示成功的结果。

> Q:

这个函数的返回值 Result<(), Box<dyn std::error::Error>>
是什么含义, 应该如何理解?

> A:

这个函数的返回值是一个 Result 类型，其中 () 表示一个空元组（也称为 unit type）。在 Rust 中，() 用于表示没有值的情况，类似于其他语言中的 void 类型。在这个函数的上下文中，() 表示函数没有返回任何有用的值，只是执行了一些操作。因此，我们可以将这个函数的返回值解读为“表示函数执行是否成功的结果，如果成功则不返回任何值，否则返回一个实现了 std::error::Error trait 的错误类型”。

Box<dyn std::error::Error> 是一个 trait 对象，它表示一个可以作为错误类型的任何类型，只要该类型实现了 std::error::Error trait。在 Rust 中，std::error::Error trait 是一个通用的错误处理 trait，它定义了一些方法和属性，用于处理和显示错误信息。实现 std::error::Error trait 的类型可以是任何具体的类型，例如字符串、自定义结构体、枚举等等。但是，为了方便和通用性，我们通常会将实现了 std::error::Error trait 的类型封装在一个 Box 中，以实现动态分配和回收内存的效果。

因此，将 Box<dyn std::error::Error> 作为函数的返回值，表示该函数可能会返回一个实现了 std::error::Error trait 的错误类型。当函数执行成功时，它将返回一个 Ok(()) 值，表示函数执行成功且没有返回任何值。当函数执行失败时，它将返回一个 Err 值，其中包含一个实现了 std::error::Error trait 的错误类型，该错误类型可以提供有关错误的更多信息，例如错误消息、错误码、堆栈跟踪等等。在实际使用中，我们通常会根据错误类型来处理错误，例如记录错误日志、返回错误码、重试操作等等。

> Q:

这里的 dyn 是什么语法?为什么要包在一个 Box 中?

> A:

dyn 是 Rust 语言中的一个关键字，用于表示动态派发的类型。在 Rust 中，存在两种类型的多态：静态多态和动态多态。静态多态是通过泛型实现的，可以在编译时确定具体的类型，而动态多态是通过 trait 对象实现的，只有在运行时才能确定具体的类型。

在 Rust 中，Box 是一个智能指针类型，用于在堆上分配和管理动态分配的值。由于 trait 对象的大小和类型在编译时是不确定的，因此不能直接将 trait 对象放在栈上或者嵌入到其他类型中。为了方便和安全地使用 trait 对象，我们通常会将其封装在一个 Box 中，以实现动态分配和回收内存的效果。

因此，在 Result<(), Box<dyn std::error::Error>> 这个类型中，Box<dyn std::error::Error> 表示一个实现了 std::error::Error trait 的错误类型，它可能是任何具体的类型，例如字符串、自定义结构体、枚举等等。由于该类型是动态分配的，因此需要使用 Box 来管理其内存。最后，Result<(), Box<dyn std::error::Error>> 表示一个成功时不返回任何值，失败时返回一个实现了 std::error::Error trait 的错误类型的结果类型。

> Q:

对应 dyn 的静态多态是什么, 能举个例子嘛?

> A:

对应于 dyn 的静态多态是 Rust 中的泛型，用于在编译时确定具体的类型。在 Rust 中，泛型可以通过类型参数来表示，例如：

```rust
fn add<T>(x: T, y: T) -> T
where
    T: std::ops::Add<Output = T> + Copy,
{
    x + y
}

let x = 1;
let y = 2;
let z = add(x, y);

```

在上面的例子中，add 函数使用了泛型类型 T，它表示任意类型。函数签名中的 where 关键字表示泛型类型 T 需要满足的一些约束，例如实现了 std::ops::Add trait，并且该 trait 的 Output 关联类型为 T，同时还需要实现 Copy trait。这些约束保证了类型 T 支持加法操作，并且可以进行值的拷贝操作。最后，add 函数返回类型为 T，表示函数的返回值类型和参数类型相同。

在使用泛型的时候，可以在函数调用时指定具体的类型，例如：

```rust
let x = 1;
let y = 2;
let z = add::<i32>(x, y);
```

在上面的例子中，add::<i32> 表示调用 add 函数，并将类型参数 T 指定为 i32 类型。由于 i32 类型实现了 std::ops::Add trait 和 Copy trait，因此满足函数签名中的约束，可以成功调用函数并返回值。

总之，静态多态和动态多态是 Rust 中的两种多态方式，它们分别用于在编译时和运行时确定具体的类型。在 Rust 中，泛型用于静态多态，通过类型参数在编译时确定具体的类型，而 trait 对象用于动态多态，只有在运行时才能确定具体的类型。

> A:

也就是说静态多态用 T 来声明, 动态多态用 dyn 声明? 上述那个 add 的示例用 dyn 来定义应该如何写?

> Q:

不完全正确，静态多态和动态多态都可以使用泛型来实现，只不过它们使用方式和目的略有不同。具体来说，泛型主要用于静态多态，可以在编译时确定具体的类型，而 trait 对象主要用于动态多态，可以在运行时确定具体的类型。因此，泛型通常用于函数、结构体、枚举等静态类型的定义中，而 trait 对象通常用于函数参数、返回值、实现动态分发等需要动态类型的场景中。

对于你的问题，如果要将上面的 add 函数改写成使用 trait 对象实现的动态多态，可以将参数类型从泛型 T 改为 trait 对象 dyn std::ops::Add<Output = T>，如下所示：

```rust
fn add<T>(x: T, y: T) -> T
where
    T: Copy,
    dyn std::ops::Add<Output = T> + 'static,
{
    x + y
}

let x = 1;
let y = 2;
let z = add(x, y);

```

在上面的例子中，add 函数使用了 trait 对象 dyn std::ops::Add<Output = T>，它表示实现了 std::ops::Add trait，并且该 trait 的 Output 关联类型为 T 的任意类型。由于 trait 对象的大小和类型在编译时是不确定的，因此需要使用 dyn 关键字来表示动态类型。同时，为了使 trait 对象能够在函数内部被存储和使用，还需要使用 'static lifetime 来保证 trait 对象的生命周期至少和整个程序的生命周期一样长。

值得注意的是，在使用 trait 对象时，需要将 trait 对象的实现限制在编译时已知的范围内。例如，在上面的例子中，由于 add 函数需要使用 x + y 表达式，因此要求 trait 对象 dyn std::ops::Add<Output = T> 的实现类型必须实现了 Copy trait，以便进行值的拷贝操作。这样一来，即使 trait 对象的实现类型是在运行时动态确定的，也能够保证它们满足 Copy trait 的要求，从而避免出现运行时错误。



> A:

那么 trait 对象也能完成静态多态的任务嘛? 举行说明?

> Q:

Trait 对象主要用于实现动态多态，因为它允许在运行时根据具体类型来调用不同的方法实现。而泛型主要用于实现静态多态，因为它允许在编译时确定具体类型，并且可以根据具体类型来进行代码优化等操作。

虽然 trait 对象不能像泛型一样进行编译时优化，但是在某些情况下也可以完成一些静态多态的任务。例如，假设我们有一个函数 print，它可以打印不同类型的值。如果使用泛型来实现，可以定义如下：

```rust
fn print<T: std::fmt::Display>(value: T) {
    println!("{}", value);
}

```

在这个例子中，我们使用了泛型来实现静态多态，函数的参数类型 T 在编译时就已经确定，因此可以在函数内部使用 std::fmt::Display trait 来打印不同类型的值。

但是，如果我们希望在运行时动态确定参数类型，就可以使用 trait 对象来实现。例如：

```rust
fn print(value: &dyn std::fmt::Display) {
    println!("{}", value);
}

let s = "Hello, world!";
let n = 42;
print(&s);
print(&n);

```

在这个例子中，我们使用了 trait 对象 &dyn std::fmt::Display 来实现动态多态，函数的参数类型在运行时才确定。在函数内部，我们可以使用 std::fmt::Display trait 来打印不同类型的值，由于 trait 对象的大小和类型在编译时是不确定的，因此不能像泛型那样进行编译时优化，但是可以在运行时根据具体类型进行动态分发，从而完成类似于静态多态的任务。

总之，尽管 trait 对象和泛型都可以用于多态编程，但它们各自适用于不同的场景和任务，需要根据实际情况选择合适的方式。泛型适用于在编译时确定类型的场景，而 trait 对象适用于在运行时确定类型的场景，同时，两者也可以结合使用来实现更加灵活和高效的编程方式。

> A:

<T: std::fmt::Display> 是什么语法? 起什么作用? 如何理解? 有其它表述形式嘛?

> Q:

<T: std::fmt::Display> 是一个泛型参数声明，用于在函数中定义一个泛型类型 T，该类型必须实现 std::fmt::Display trait。它的作用是让函数能够处理不同类型的参数，同时要求这些参数必须实现 Display trait。

这个语法可以理解为：“定义一个名为 T 的泛型类型，它必须实现 std::fmt::Display trait。”

另外，还有一种等效的语法，可以使用 where 关键字来声明泛型类型的约束条件，例如：

```rust
fn print<T>(value: T)
where
    T: std::fmt::Display,
{
    println!("{}", value);
}
```

这个语法的意思和前面的语法是等价的，它表示：“定义一个名为 T 的泛型类型，在函数体内部使用它，并要求它必须实现 std::fmt::Display trait。”

在 Rust 中，这两种语法是等价的，选择哪种语法主要取决于个人的编码习惯和喜好。通常来说，第一种语法适用于简单的泛型函数，而第二种语法适用于更复杂的泛型函数，因为它可以将类型约束条件单独列出来，使得函数的声明更加清晰和易读。

> A:

明白了, 举例说明如何兼容没有实现 std::fmt::Display trait 的对象传入后, 如何安全响应?

> A:

如果我们需要在函数中处理可能没有实现 std::fmt::Display trait 的类型，一种常见的做法是使用 Rust 提供的 Option 或 Result 类型来表示这种情况，并在函数中进行处理。

例如，我们可以将 print 函数改为返回一个 Result<(), Box<dyn std::error::Error>> 类型的结果，这样就可以在函数中处理可能出现的错误：

```rust

fn print<T: std::fmt::Display>(value: T) -> Result<(), Box<dyn std::error::Error>> {
    println!("{}", value);
    Ok(())
}

```

在这个版本的 print 函数中，我们使用 Result 类型来表示函数执行的结果，并使用 Box<dyn std::error::Error> 类型来表示可能出现的错误。如果传入的参数没有实现 std::fmt::Display trait，则在执行 println! 时会抛出一个错误，这个错误会被捕获并返回一个 Err 值。

调用方可以根据 Result 类型的返回值来判断函数是否执行成功，如果返回了 Err 值，则说明函数执行过程中出现了错误。调用方可以选择忽略这个错误，或者将错误信息打印出来，以便于调试和排查问题。例如：

```rust
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let value = 42;
    print(value)?;
    Ok(())
}

```

在这个例子中，我们将一个整数类型的值 42 传给了 print 函数，由于整数类型没有实现 std::fmt::Display trait，因此在函数中会抛出一个错误，这个错误会被捕获并返回一个 Err 值。在 main 函数中，我们使用 ? 操作符来处理这个错误，这样如果 print 函数执行失败，main 函数也会返回一个 Err 值，程序会打印出错误信息。


> PS:进一步的, 综合之前介绍,可以用 where 进行外部声明,简化函数声明:

```rust
fn print<T>(value: T) -> Result<(), Box<dyn std::error::Error>>
where
    T: std::fmt::Display,
{
    println!("{}", value);
    Ok(())
}
```


> A:

我是说 Result<(), Box<dyn std::error::Error>> 这里也太长了, 有对应简洁形式嘛?

> Q:

在 Rust 中，可以使用 type 关键字来给某种类型起一个别名，从而在代码中使用这个别名来代替原始的类型。这样可以使得代码更加易读和易于维护。

对于 Result<(), Box<dyn std::error::Error>> 这样的类型，我们可以使用 type 关键字来为它起一个别名，例如：

```rust
type MyResult = Result<(), Box<dyn std::error::Error>>;

```

这个代码片段定义了一个名为 MyResult 的别名，它表示的类型和 Result<(), Box<dyn std::error::Error>> 是一样的。有了这个别名，我们可以在代码中使用 MyResult 来代替 Result<(), Box<dyn std::error::Error>>，从而使得代码更加易读。

例如，我们可以使用这个别名来定义 print 函数的返回类型：

```rust
fn print<T: std::fmt::Display>(value: T) -> MyResult {
    println!("{}", value);
    Ok(())
}

```

这个版本的 print 函数和之前的版本相比，唯一的区别就是使用了 MyResult 这个别名来代替了 Result<(), Box<dyn std::error::Error>>，这样可以使得函数声明更加简洁易读。

调用这个版本的 print 函数和之前的版本是一样的，例如：

```rust
fn main() -> MyResult {
    let value = 42;
    print(value)?;
    Ok(())
}

```

## refer.
> 其实官方的文档吃透, 基本可以平趟 80% 的日常开发了...

[Generic Types, Traits, and Lifetimes - The Rust Programming Language](https://doc.rust-lang.org/book/ch10-00-generics.html)

- [Generic Data Types - The Rust Programming Language](https://doc.rust-lang.org/book/ch10-01-syntax.html)
- [Traits: Defining Shared Behavior - The Rust Programming Language](https://doc.rust-lang.org/book/ch10-02-traits.html#defining-a-trait)

...这些链接对应的是 Rust 官方文档中的《Rust 程序设计语言》一书中的相关章节，包含了静态多态和动态多态的基本概念、使用方法和示例代码等内容，非常适合初学者阅读学习。除此之外，还可以参考 Rust 官方文档中的其他部分，如《Rust 标准库 API 参考》和《Rust 风格指南》等，来深入理解 Rust 中的泛型和 trait 等概念。





```
       _~~|-~_
   () /  ◕ -  \ (/
     '_   ⎵   _'
     | '-----' |

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```


