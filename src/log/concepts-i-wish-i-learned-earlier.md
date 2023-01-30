# 希望一早知道的关键概念
原文: [rauljordan::blog](https://rauljordan.com/rust-concepts-i-wish-i-learned-earlier/)

## 快译

过去一个月里, 我被 Rust 语言彻底迷住了,
因为,她在编写内存安全的现代程序方面具有独特的优势.
多年以来, 有几种语言已经成为工程师编写弹性后端软件的首选语言.
潮流已经从 JAVA/C++ 转向 Go 和 Rust,
她们结合了数十年编程语言理论来构建我们这个时代最需要的工具.

Rust 的地位不言则明.
作为最受一欢迎的语言, 连续7年度在著名 `stack overflow` 调查中排名第一!
最近还作为 Linux 内核的一部分发布 -- 这是除 C 之外任何语言之前都无法作到的壮举.
对我而言, 这门语言令人兴奋的地方在于,
她在软件构建艺术方面提供了一些真正新颖的东西.

```rust
use std::thread;
use std::time::Duration;
use std::{collections::VecDeque, sync::Condvar, sync::Mutex};

fn main() {
    let queue = Mutex::new(VecDeque::new());

    thread::scope(|s| {
        let t = s.spawn(|| loop {
            let item = queue.lock().unwrap().pop_front();
            if let Some(item) = item {
                dbg!(item);
            } else {
                thread::park();
            }
        });

        for i in 0.. {
            queue.lock().unwrap().push_back(i);
            t.thread().unpark();
            thread::sleep(Duration::from_secs(1));
        }
    })
}
```

Rust 在整个系统编程中获得了令人难以置信的使用, 
也因难以学习而闻名. 尽管如此, 还是有很多优秀的 Rust 内容可以满足初学者和高级程序员的需求.
然而, 他们中太多人专注解释语言的核心机制和所有权概念, 而不是构建应用程序.

作为一名编写高并发程序并专注在系统编程的 Go 开发者, 
我在学习如何使用 Rust 构建真实程序的过程中遇到了很多障碍. 
也就是交织, 如果我将当前正在从事的工作移植到 Rust 中, 那么所有这些教程的效果如何呢?

此篇文章旨在介绍我进入 Rust 兔子洞的经历, 
以及我希望一些学习资源可以更好阐述的内容. 
对个人而言, 我无法通过简单的观看 youtube 视频来学习一门新语言, 
而是必须通过为自己寻找解决方案,犯错以及对过程感受谦卑来积累．



### 关于参考

Rust 中有两种引用, 共享引用(也称为 `借用`)和可变引用(也称为`独占引用`).
通常这些被视为变量 x 上的 &x 以及 &mut x . 
一旦我开始将后者称为"独家参考", 这两白间的区别就更有意义了.

Rust 的参考模型相当简单. 借款人可以根据需要拥有对某对象的尽可能多的共享引用, 
但是, 一次只能有一个独占引用. 
否则, 你可能会有很多调用者同时尝试对同一个值进行修改的囧境;
如果很多借用者也可以持有独占袭用, 
你将面临未定义行为风险, 
而安全的 Rust 则不允许这么折腾.

在学习 Rust 时, 都用 &mut 独家参考可以节省很多时间:

```rust
pub struct Foo {
    x: u64,
}

impl Foo {
    /// Any type that borrows an instance of Foo can
    /// call this method, as it only requires a reference to Foo.
    pub fn total(&self) -> u64 {
        self.x
    }
    /// Only exclusive references to instances of Foo
    /// can call this method, as it requires Foo to be mutable.
    pub fn increase(&mut self) {
        self.x += 1;
    }
}

let foo = Foo { x: 10 };
println!("{}", foo.total()) // WORKS.
foo.increase() // ERROR: Foo not declared as mut
```

### 双向引用是可以的
> Bidirectional references are possible

在其它具有垃圾收集功能的语言中, 很容易定义图形数据结构或其它包含对某些子项引用的类型, 
并且这些引用可以包含对其父项的引用;
在 Rust 中, 如果不完全理解借用规则, 这是很难作到的;
但是, 仍然可以使用标准库提供的正法.

假设我们有一个名为 Node 的结构, 
包含一组对子节点的引用, 以及一个对父节点的引用; 
通常, Rust 会抱怨, 但是, 我们可以通过将父引用包装在称为 `弱指针` 的东西中来满足借用检查器的要求;
这种类型告诉 Rust 一个节点消失, 或者其子节点消失, 不应该意味着父节点也应该被删除;

```rust
use std::cell::RefCell;
use std::rc::{Rc, Weak};

struct Node {
    value: i32,
    parent: RefCell<Weak<Node>>,
    children: RefCell<Vec<Rc<Node>>>,
}
```

这为我们提供了构建双向引用的便利原语; 
然而, 我很快发现在 Rust 中构建图形数据真的很难, 
除非你真的知道自己在作什么, 考虑到一个人需要围绕有效建模数据来作大量的 `book-keeping` 工作以满足编译器.

(是也乎: 编译器作为 Rust 生态中最大的 BOSS 必须优先满足.)


### 实施 Deref 令代码更清晰
> Implement Deref to make your code cleaner


有时我们希望将包装器类型视之为其包含的内容;
对于常见的数据结构(比如 vec),智能指针(例如 Box) 甚至引用计数类型(类似 Rc 和 Arc) 都是如此;
标准库包含称为 Deref 和 DerefMut 的特征, 
她们将报时你告诉 Rust 应该如何取消引用一个类型;

```rust
use std::ops::{Deref, DerefMut};

struct Example<T> {
    value: T
}

impl<T> Deref for Example<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

impl<T> DerefMut for Example<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.value
    }
}

let mut x = Example { value: 'a' };
*x = 'b';
assert_eq!('b', x.value);
```

上述示例代码中, 我们可以将 `*x` 视为其基础值 `"a"`, 
甚至可以改变它, 因为, 我们定义了应该如何在借用或可变引用中取消引用的规则;
这很强大, 也是你无需担心在 Box 等智能指针中包装类型的原因;

值被装箱的事实是一个实现细节, 可以通过这些特征抽象出来;

```rust
struct Foo {
    value: u64,
}
let mut foo = Box::new(Foo { value: 10 });

// Box implements DerefMut, so this will work fine!
*foo = Foo { value: 20 };
// Dot methods will work on foo because Box implements Deref.
// We do not have to worry about the implementation
// detail that Foo is boxed.
assert_eq!(20, foo.value);
```

### 小心实现 Deref 类型方法
> Be careful with methods on types that implement Deref

有没有想过, 为什么像 `Arc::clone` 这类方法的存在, 
而我们只能对 Arc 值执行 `.clone()`?
原因和类型如何实现 Deref 有关, 
这是开发者应该警惕的事儿;

考虑以下示例, 我们正在尝试从标准库中实现我们自己版本的
多生产者/单一消费者(mpsc)通道:

Ever wonder why methods such as Arc::clone exist when we could just do .clone() on an Arc value? The reason has to do with how types implement Deref and is something developers should be wary of. Consider the following example, where we are trying to implement our own version of multi-producer/single-consumer (mpsc) channels from the standard library:

```rust
use std::sync::{Arc, Mutex, Condvar};

pub struct Sender<T> {
    inner: Arc<Inner<T>>,
}

impl<T> Sender<T> {
    pub fn send(&mut self, t: T) {
        ...
    }
}

impl<T: Clone> Clone for Sender<T> {
    fn clone(&self) -> Self {
        Self {
            // ERROR: Does not know whether to clone Arc or inner!
            inner: self.inner.clone(),
        }
    }
}

struct Inner<T> {
    ...
}

impl<T: Clone> Clone for Inner<T> {
    fn clone(&self) -> Self {
        ...
    }
}
```

上述示例中, 我们有一个要在其上实现 Clone 特征的 Sender 类型;
该结构有一个名为 inner 的字段, 其类型为 `Arc<Inner<T>>` ;
回想一下 Arc 已经实现了 Clone 和 Deref ;
最重要的是, 我们的 Inner 还现实了 Clone ;
对于上面的代码, Rust 并不知道我们是要克隆 Arc 还是实际的内部值,
所以, 上面代码会失败;
在这种情况下, 我们可以使用 Arc 从 sync 包中提供的实际方法;

```rust
impl<T: Clone> Clone for Sender<T> {
    fn clone(&self) -> Self {
        Self {
            // Now Rust knows to use the Clone method of Arc instead of the
            // clone method of inner itself.
            inner: Arc::clone(&self.inner),
        }
    }
}
```

### 理解何时以及何时不用内部可变性
> Understand when and when not to use interior mutability


有时, 你需要在代码中使用 Rc 或是 Arc 等结构, 
又或者实现包装一些数据结构, 然后, 又想要改变被包装的数据;
很快, 编译器就会告诉你, 内部可变性是不允许的, 乍看起来这很棘手;
然而, 有一些方法允许 Rust 中的内部可变性, 
甚至是由标准库提供的;

最简单的一种是 Cell, 她为你提供数据的内可变性;
也就是说, 嘦数据复制成本低, 
你就可以在 Rc 中改变数据;
你可以通过将数据包装在 `Rc<Cell<T>>` 中来实现这一点;
她提供了 get 和 set 方法,
甚至不需要被 mut , 因为, 她们是在底层复制数据的:


```rust
// impl<T: Copy> Cell<T>
pub fn get(&self) -> T

// impl<T> Cell<T>
pub fn set(&self, val: T)
```

其它类型, 比如 RefCell 有助于将某些借用检查移至运行时, 并跳过一些编译器的严格过滤;
然而, 这是有风险的, 因为, 如果没有完成借用检查, 就可能在运行时触发 panic ;
将编译器当成朋友, 你会获得回报;
通过跳过编译器检查, 或是将她们推迟到运行时, 
等于告诉编译器"相信我 --- 我作的都是正确的";

而 std::cell 包甚至通过一个很有帮助的消息警告我们:

```

更常见的继承可变性, 其中必须具有唯一访问权限才能改变值,
这一语言元素是令 Rust 能强力推理指针别名, 静态防止崩溃错误的关键;
因此, 继续可变性是首选, 内部可变性是最后的手段;
由于 Cell 类型可以在不允许突变的地方启用突变, 
因此, 在某些情况中, 内部可变性也许是合适的, 甚至必须使用, 例如:

- 在不可变事物的"内部"引入可变性
- 逻辑不可变方法的实现细节
- 克隆的变异实现


The more common inherited mutability, where one must have unique access to mutate a value, is one of the key language elements that enables Rust to reason strongly about pointer aliasing, statically preventing crash bugs. Because of that, inherited mutability is preferred, and interior mutability is something of a last resort. Since cell types enable mutation where it would otherwise be disallowed though, there are occasions when interior mutability might be appropriate, or even must be used, e.g.

- Introducing mutability ‘inside’ of something immutable
- Implementation details of logically-immutable methods.
- Mutating implementations of Clone.

```

### get 和 get mut 方法是一回事儿
> Get and get mut methods are a thing


很多类型, 包含 vec 都实现了 get 与 get_mut 方法,
让你可以借用和改变结构中的元素
(前者只有在你有一个对集会的可变引用时才可能);
我花了一段时间, 才知道这些选项可用于许多数据结构,
她们通过更轻松的编写干净的代码, 帮助我的生活更轻松!


```rust
let x = &mut [0, 1, 2];

if let Some(elem) = x.get_mut(1) {
    *elem = 42;
}
assert_eq!(x, &[0, 42, 2]);
```


### 拥抱不安全但合理的代码
> Embrace unsafe but sound code


作为一名 Go 开发者, "unsafe" 包总是感觉很不靠谱,
而且我很少接触;
然而, Rust 中 “unsafe” 的概念是完全不同的;
事实上, 很多标准库都使用 `“unsafe”` 来取得巨大成功!

这怎么可能? 尽管 Rust 使未定义的行为成为不可能,
但是, 这不适用于标记为 “unsafe” 的代码块;
相反, 编写 “unsafe” Rust 的开发者嘦保证其使用合理,
即可获得所有好处;



As a Go developer, the “unsafe” package felt sacrilegeous and something I seldom touched. However, the notion of unsafety in Rust is very different. In fact, a lot of the standard library uses “unsafe” to great success! How is this possible? Although Rust’s makes undefined behavior impossible, this does not apply to code blocks that are marked as “unsafe”. Instead, a developer writing “unsafe” Rust simply needs to guarantee its usage is sound to reap all the benefits.

Take the example below, where we have a function that returns the item at a specified index in an array. To optimize this lookup, there is an unsafe function in Rust called get_unchecked which is available on the array type. This will panic and lead to undefined behavior if we attempt to get an index out of bounds. However, our function correctly asserts the unsafe call will only happen if the index is less than the array length. This means the code below is sound despite using an unsafe block.

```rust
/// Example taken from the Rustonomicon
fn item_at_index(idx: usize, arr: &[u8]) -> Option<u8> {
    if idx < arr.len() {
        unsafe {
            Some(*arr.get_unchecked(idx))
        }
    } else {
        None
    }
}
```

Embrace unsafe as long as you can prove the soundness of your API, but avoid exposing functions that are directly unsafe to your consumers unless it is truly warranted. For this reason, having tightly-controlled internals of your packages where you can prove unsafe blocks are sound is a normal practice in Rust.

Typically, unsafe is used where performance is of absolute importance, or when you know of an easy way to solve a problem using unsafe blocks and you can prove the soundness of your code.

### Use impl types as arguments rather than generic constraints when you can

Coming from Golang, I thought that traits could simply be provided as function parameters all the time. For example:

```rust
trait Meower {
    fn meow(&self);
}

struct Cat {}

impl Meower for Cat {
    fn meow(&self) {
        println!("meow");
    }
}

// ERROR: Meower cannot be used as it does not have
// a size at compile time!
fn do_the_meow(meower: Meower) {
    meower.meow();
}
```

…but the above fails, as trait objects do not have a size at compile time which Rust needs in order to get the job done. We could get around it by adding &dyn Meower and telling the compiler this is dynamically sized, but I soon learned this is not the “rusty” solution. Instead, developers tend to pass in generic parameters constrained by a trait. For example:

```rust
fn do_the_meow<M: Meower>(meower: M) {
    meower.meow();
}
```

…which compiles and passes. However, as functions get more complex, we might have a very hard-to-read function signature if we also include other generic parameters. In this example, we don’t really need a generic type if all we want is to meow once. We don’t even care about the results of the meow, so we can instead rewrite as

```rust
fn do_the_meow(meower: &impl Meower) {
    meower.meow();
}
```

which tells the compiler “I just want something that implements Meow”. This pattern is a lot cleaner when this is all you need, and there is no need for a generic return type of your function in the first place.

### iter() when you need to borrow, iter mut() for exclusive refs, and into iter() when you need to own
Many tutorials immediately jump to iterating over vectors using the into_iter method below:

```rust
let items = vec![1, 2, 3, 4, 5];
for item in items.into_iter() {
    println!("{}", item);
}
```

However, many beginners (myself included) hit a wall when we start using this iterator method within structs, such as:

```rust
struct Foo {
    bar: Vec<u32>,
}

impl Foo {
    fn all_zeros(&self) -> bool {
        // ERROR: Cannot move out of self.bar!
        self.bar.into_iter().all(|x| x == 0)
    }
}
```

and immediately hit:
```
    error[E0507]: cannot move out of `self.bar` which is behind a shared reference
       --> src/main.rs:9:9
        |
    9   |         self.bar.into_iter().all(|x| x == 0)
        |         ^^^^^^^^ ----------- `self.bar` moved due to this method call
        |         |
        |         move occurs because `self.bar` has
        |         type `Vec<u32>`, which does not implement the `Copy` trait

```
After trying all kinds of approaches as a noob, I realized that .into_iter() takes ownership of the collection, which is not what I needed for my purposes. Instead, there are two other useful methods on iterators that I wish I had learned about earlier. The first is .iter(), which borrows the collection, letting you assert things about its values but not own or mutate them, and also .iter_mut() which helps you mutate internal values of the collection as long as you have the only exclusive reference.

In summary, use .iter() when you just need to borrow, .into_iter() when you want take ownership, and .iter_mut() when you need to mutate elements of an iterator.

### Phantom data is more than just for working with raw pointers to types
Phantom data seems weird when you first encounter it, but it soon makes sense as a way of telling the compiler one “owns” a certain value despite just having a raw pointer to it. For example:

```rust
use std::marker;

struct Foo<'a, T: 'a> {
    bar: *const T,
    _marker: marker::PhantomData<&'a T>,
}
```

Tells the compiler that Foo owns T, despite only having a raw pointer to it. This is helpful for applications that need to deal with raw pointers and use unsafe Rust.

However, they can also be a way to tell the compiler that your type does not implement the Send or Sync traits! You can wrap the following types with PhantomData and use them in your structs as a way to tell the compiler that your struct is neither Send nor Sync.

```rust
pub type PhantomUnsync = PhantomData<Cell<()>>;
pub type PhantomUnsend = PhantomData<MutexGuard<'static, ()>>;
```

### Use rayon for incremental parallelism
Sometimes, you want to parallelize work when iterating through collections, but hit a brick wall when dealing with threading and making types safe to send across threads. Sometimes, the extra boilerplate just isn’t worth it if it makes your code almost unreadable.

Instead, there is an awesome package called Rayon which provides fantastic tools for parallelizing your computations in a seamless manner. For example, let’s say we have a function that computes the sum of squares of an array.

```rust
fn sum_of_squares(input: &[i32]) -> i32 {
    input.iter()
            .map(|i| i * i)
            .sum()
}
```

The above can absolutely be parallelized due to the nature of multiplication and addition, and Rayon makes it trivial to do so by giving us automatic access to “parallel iterators” on collections such as arrays. Here’s what it looks like with pretty much zero boilerplate. It also does not compromise readability at all.

```rust
// Importing rayon prelude is what gives us access to .par_iter on arrays.
use rayon::prelude::*;

fn sum_of_squares(input: &[i32]) -> i32 {
    // We can use par_iter on our array to let rayon
    // handle the parallelization and reconciliation of
    // results at the end.
    input.par_iter()
            .map(|i| i * i)
            .sum()
}
```

### Understand the concept of extension traits when developing Rust libraries
So how does Rayon accomplish the above in such a clean way? The answer lies in “extension traits”, which are traits that can be defined as extensions to other traits, such as Iterator. That is, we can add other helpful functions to items that normally implement the Iterator trait, but they will only be available if the trait is in scope, such as by importing it in a file.

This approach is excellent because these traits will only be available if you import the extension trait in your project, and provide a great way to extend common collections and types with clean APIs that developers can use just as easily as their normal counterparts. Using parallel iterators is as easy as using iterators in Rust thanks to Rayon’s extension traits.

In fact, there is a highly informative talk that explains how to use extension traits to develop a library that provides progress bars on iterators here

### Embrace the monadic nature of Option and Result types
After working with options and results, one will quickly see that `.unwrap()` moves values out of them, which will fail if the option or result is part of a shared reference such as a struct. However, sometimes all we want is to assert the option matches a value within or to obtain a reference to its internals. There are many ways to do this, but one way is to never leave the domain of options at all.

```rust
fn check_five(x: Option<i32>) -> bool {
    // Contains can just check if the Option has what we want.
    x.contains(&5)
}
```

Another example is one where we want to replace data inside of an option with the None value, perhaps when interacting with some struct. We could write this in an imperative programming manner, and do things verbosely as follows:

```rust
struct Foo {
    data: Option<T>,
}

impl<T> Foo<T> {
    // Takes the value of data and leaves None in its place.
    fn pop(&mut self) -> Option<T> {
        if self.data.is_none() {
            return None;
        }
        let value = self.data.unwrap();
        self.data = None;
        value
    }
}
```

However, Options have some really cool properties due to their fundamental nature that they have useful methods defined on them which can make our lives a lot easier.

```rust
// Takes the value of data and leaves None in its place.
fn pop(&mut self) -> Option<T> {
    self.data.take()
}
```

Options in Rust are modeled after the same paradigm in functional programming languages, belonging to a broader category of data types known as Monads. We won’t into what those are, but just think of them as wrappers around data that we can manipulate without needing to take things out of them. For example, picture a function which adds the inner values of two options together and returns an option.

```rust
fn add(x: Option<i32>, y: Option<i32>) -> Option<i32> {
    if x.is_none() || y.is_none() {
        return None;
    }
    return Some(x.unwrap() + y.unwrap());
}
```

The above looks kind of clunky because of the none checks it needs to perform, and it also sucks that we have to extract values out of both options and construct a new option out of that. However, we can much better than this thanks to Option’s special properties! Here’s what we could do

```rust
fn add(x: Option<i32>, y: Option<i32>) -> Option<i32> {
    x.zip(y).map(|(a, b)| a+b)
}
```

We can zip and map options just like we can over arrays and vectors. This property is also found in Result types, and even in things such as `Future` types. If you’re curious about why this works, learn more about Monads here.

Embrace the monadic nature of the Option and Result types and don’t just use unwrap and if x.is_none() {} else everywhere. They have so many useful methods defined which you can read about in the standard library.

### Understand Drop how it should be implemented for different data structures
The standard library describes the Drop trait as:

When a value is no longer needed, Rust will run a “destructor” on that value. The most common way that a value is no longer needed is when it goes out of scope.

```rust
pub trait Drop {
    fn drop(&mut self);
}
```

Drop is critical when writing data structures in Rust. One must have a sound approach towards how memory will be thrown away once you no longer need it. Using reference-counted types can help you get over these hurdles but it will not always be enough. For example, writing a custom linked list, or writing structs that use channels, would typically need to implement a custom version of Drop. Implementing drop is actually far easier than it seems, when you see how the standard lib actually does it:

```rust
// That's it!
fn drop<T>(t: T) {}
```

Using the clever rules of destruction upon losing scope, std::mem::drop has an empty function body! This is a trick you can use in your own custom Drop implementations as long as you cover all of your bases.

### Really annoyed by the borrow checker? Use immutable data structures
Functional programmers love to say that global, mutable state is the root of all evil, so why use it if you can avoid it? Thanks to Rust’s functional constructs, we are able to construct data structures that never need mutation the first place! This is especially helpful when you need to write pure code similar to that seen in Haskell, OCaml, or other languages.

With an example taken from a comprehensive tutorial on linked lists, we see how one could build an immutable list where nodes are reference counted:

```rust
use std::rc::Rc;

pub struct List<T> {
    head: Link<T>,
}

type Link<T> = Option<Rc<Node<T>>>;

struct Node<T> {
    elem: T,
    next: Link<T>,
}

impl<T> List<T> {
    pub fn new() -> Self {
        List { head: None }
    }

    pub fn prepend(&self, elem: T) -> List<T> {
        List { head: Some(Rc::new(Node {
            elem: elem,
            next: self.head.clone(),
        }))}
    }

    pub fn tail(&self) -> List<T> {
        List { head: self.head.as_ref().and_then(|node| node.next.clone()) }
    }
    ...
```

This is awesome because it acts similarly to functional data structures where one does not modify a list by prepending, but rather creates a list by constructing with the new element as its head and the existing list as the tail.

```rust
    [head] ++ tail
```

Note that none of the methods above need to be mut because our data structure is immutable! This is also efficient on memory because the structure is reference counted, meaning we won’t be wasting unnecessary resources duplicating the underlying memory of nodes if there are multiple callers on this data structure.

Pure, functional code in Rust is neat, but many times, one will need tail recursion to write code that is performant in this manner. However, be careful, as tail-call optimization is not guaranteed by the Rust compiler. See more on this here

### Blanket traits help reduce duplication
Sometimes, you might want to constrain a generic parameter by many different traits:

```rust
struct Foo<T: Copy + Clone + Ord + Bar + Baz + Nyan> {
    vals: Vec<T>,
}
```

However, this can quickly get out of hand as soon as you start writing impl statements, or when having multiple generic params. Instead, you can define a blanket trait that can make your code a more DRY.

```rust
trait Fooer: Copy + Clone + Ord + Bar + Baz + Nyan {}

struct Foo<F: Fooer> {
    vals: Vec<F>,
}

impl<F: Fooer> Foo<F> { ... }
```

Blanket traits can help reduce duplication, however, don’t let them get way too big. In many cases, having a type require so many constraints might be a code-smell, as you are creating too large of an abstraction. Instead, pass in concrete types if you notice your constraints get too large for no reason. Certain applications, however, might benefit from blanket traits, such as libraries that aim to provide as generic of an API as possible.

### Match statements are very flexible and structural in nature
Instead of nesting match statements, for example, one could bring values together as tuples and do the following:

```rust
fn player_outcome(player: &Move, opp: &Move) -> Outcome {
    use Move::*;
    use Outcome::*;
    match (player, opp) {
        // Rock moves.
        (Rock, Rock) => Draw,
        (Rock, Paper) => Lose,
        (Rock, Scissors) => Win,
        // Paper moves.
        (Paper, Rock) => Win,
        (Paper, Paper) => Draw,
        (Paper, Scissors) => Lose,
        // Scissor moves.
        (Scissors, Rock) => Lose,
        (Scissors, Paper) => Win,
        (Scissors, Scissors) => Draw,
    }
}
```

This is an example of why pattern matching is far more powerful than switch statements seen in imperative languages and it can do more much than that when it comes to deconstructing inner values!

### Avoid _ => clauses in match statements if your matchees are finite and known
For example, let’s say we have an enum:

```rust
enum Foo {
    Bar,
    Baz,
    Nyan,
    Zab,
    Azb,
    Bza,
}
```

When writing match statements, we should match every single type of the enum if we can and not resort to catch-all clauses

```rust
match f {
    Bar => { ... },
    Baz => { ... },
    Nyan => { ... },
    Zab => { ... },
    Azb => { ... },
    Bza => { ... },
}
```

This is really helpful for maintenance of code, because if the original writer of the enum adds more variants to it, the project won’t compile if we forget to handle the new variants in our match statements.

### Match guard clauses are powerful
Match guards are awesome when you have an unknown or potentially infinite number of matchees, such as ranges of numbers. However, they will force you to have a catch-all `_ =>` if your range cannot be fully encompassed by the guard, which can be a downside when writing maintainable code.

The canonical example from the Rust book is below:

```rust
enum Temperature {
    Celsius(i32),
    Fahrenheit(i32),
}

fn main() {
    let temperature = Temperature::Celsius(35);
    match temperature {
        Temperature::Celsius(t) if t > 30 => println!("{}C is above 30 Celsius", t),
        Temperature::Celsius(t) => println!("{}C is below 30 Celsius", t),
        Temperature::Fahrenheit(t) if t > 86 => println!("{}F is above 86 Fahrenheit", t),
        Temperature::Fahrenheit(t) => println!("{}F is below 86 Fahrenheit", t),
    }
}
```

### Need to mess with raw asm? There’s a macro for that!
Core asm provides a macro that lets you write inline assembly in Rust, which can help when doing fancy things such as directly intercepting the CPU’s stack, or wanting to implement advanced optimizations. Here’s an example where we use inline assembly to trick the processor’s stack to execute our function by simply moving the stack pointer to it!

```rust
use core::arch::asm;

const MAX_DEPTH: isize = 48;
const STACK_SIZE: usize = 1024 * 1024 * 2;

#[derive(Debug, Default)]
#[repr(C)]
struct StackContext {
    rsp: u64,
}

fn nyan() -> ! {
    println!("nyan nyan nyan");
    loop {}
}

pub fn move_to_nyan() {
    let mut ctx = StackContext::default();
    let mut stack = vec![0u8; MAX as usize];
    unsafe {
        let stack_bottom = stack.as_mut_ptr().offset(MAX_DEPTH);
        let aligned = (stack_bottom as usize & !15) as *mut u8;
        std::ptr::write(aligned.offset(-16) as *mut u64, nyan as u64);
        ctx.rsp = aligned.offset(-16) as u64;
        switch_stack_to_fn(&mut ctx);
    }
}

unsafe fn switch_stack_to_fn(new: *const StackContext) {
    asm!(
        "mov rsp, [{0} + 0x00]",
        "ret",
        in(reg) new,
    )
}
```

### Use Criterion to benchmark your code and its throughput
The Criterion package for benchmarking Rust code is a fantastic work of engineering. It gives you access to awesome benchmarking features with graphs, regression analysis, and other fancy tools. It can even be used to measure different dimensions of your functions such as time and throughput. For example, we can see how fast we can construct, take, and collect raw bytes using the standard library’s iterator methods at different histogram buckets.

```rust
use std::iter;

use criterion::BenchmarkId;
use criterion::Criterion;
use criterion::Throughput;
use criterion::{criterion_group, criterion_main};

fn from_elem(c: &mut Criterion) {
    static KB: usize = 1024;

    let mut group = c.benchmark_group("from_elem");
    for size in [KB, 2 * KB, 4 * KB, 8 * KB, 16 * KB].iter() {
        group.throughput(Throughput::Bytes(*size as u64));
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, &size| {
            b.iter(|| iter::repeat(0u8).take(size).collect::<Vec<_>>());
        });
    }
    group.finish();
}

criterion_group!(benches, from_elem);
criterion_main!(benches);
```

and after adding the following entries to the project’s Cargo.toml file, one can run it with `cargo bench`.

```toml
[dev-dependencies]
criterion = "0.3"

[[bench]]
name = "BENCH_NAME"
harness = false
```



Not only does criterion show you really awesome charts and descriptive info, but it can also remember prior results of benchmark runs, telling you of performance regressions. In this case, I was using my computer to do a lot of other things at the same time as I ran the benchmark, so it naturally regressed from the last time I measured it. Nonetheless, this is really cool!

```
    Found 11 outliers among 100 measurements (11.00%)
      2 (2.00%) low mild
      4 (4.00%) high mild
      5 (5.00%) high severe
    from_elem/8192          time:   [79.816 ns 79.866 ns 79.913 ns]
                            thrpt:  [95.471 GiB/s 95.528 GiB/s 95.587 GiB/s]
                     change:
                            time:   [+7.3168% +7.9223% +8.4362%] (p = 0.00 < 0.05)
                            thrpt:  [-7.7799% -7.3407% -6.8180%]
                            Performance has regressed.
    Found 3 outliers among 100 measurements (3.00%)
      2 (2.00%) high mild
      1 (1.00%) high severe
    from_elem/16384         time:   [107.22 ns 107.28 ns 107.34 ns]
                            thrpt:  [142.15 GiB/s 142.23 GiB/s 142.31 GiB/s]
                     change:
                            time:   [+3.1408% +3.4311% +3.7094%] (p = 0.00 < 0.05)
                            thrpt:  [-3.5767% -3.3173% -3.0451%]
                            Performance has regressed.
```

### Understand key concepts by reading the std lib!
I love to get lost in some of the standard library, especially std::rc, std::iter, and std::collections. Here are some awesome tidbits I learned from it on my own:

- How vec is actually implemented
- The ways in which interior mutability is achieved by different methods in std::cell and std::rc
- How channels are implemented in std::sync
- The magic of std::sync::Arc
- Hearing the thorough explanations of design decisions made while developing its libraries from Rust’s authors

I hope this post was informative for folks coming into Rust and hitting some of its obstacles. Expect more Rust content to come soon, especially on more advanced topics!

### Shoutout

Shoutout to my colleagues at Offchain Labs, Rachel and Lee Bousfield for their incredible breadth of knowledge of the language. Some of their tips inspired this post



## refer.
> 关键参考


## logging
> 版本记要

- ..
- 230120 ZQ init.

