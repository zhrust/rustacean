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

嘦你能证明你的 API 是可靠的,
就接受 unsafe, 但是, 要避免逈你的消费者暴露 unsafe 函数,
除非是真正有保证的;
出于这个原因, 在 Rust 中,对你的包内部进行严格控制,
可以证明 unsafe 代码块是合理的了;

通常在性能绝对重要的情况下, 才使用 unsafe,
或者当你知道使用 unsafe 代码块是解决问题的简单方法,
并且可以证明代码的可靠性时;

(`是也乎:`

安全和可靠分离, 那么, 什么是可靠呢?

)


### 尽可能用 impl 类型作为参数而不是通用约束

这点来自 Golang, 我认为特征可以一直简单的作为函数参数来提供;
比如:

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

...但是,上述代码失败了,
因为, trait 对象在编译时没有 Rust 完成工作需要的内存尺寸;
我们可以通过添加 `&dyn Meower` 来告诉编译器这是动态调整大小来绕过,
但是, 很快我了解到这不是 `rusty`/锈范儿 解决方案;
相反,开发者倾向于衖受特征约束的通用参数,
例如:

```rust
fn do_the_meow<M: Meower>(meower: M) {
    meower.meow();
}
```

...现在能通过编译了;
然而,随着函数越来越复杂, 如果我们还包括其它通用参数,
就可能会有一个非常难以阅读的函数声明;
在此示例中,如果我们只想用一次 meow,
那么, 实际上并不需要动用泛型;
我们甚至于并不关心 meow 的结果,
所以, 可以改写为这样:


```rust
fn do_the_meow(meower: &impl Meower) {
    meower.meow();
}
```

这样告诉编译器:"我只想要实现 Meow 的东西";
当然,这正是我们需要的,
并且,首先不需要函数的通用返回类型时,
此模式会更加清晰;

### 用 iter() 过程中想借用时, iter mut() 用以独占 refs,而 into iter() 支持拥有

很多教程立即跳转到使用下面的 into_iter 方法来迭代 vectors/向量:

```rust
let items = vec![1, 2, 3, 4, 5];
for item in items.into_iter() {
    println!("{}", item);
}
```

然而,当我们刚刚开始在结构中使用这个迭代器方法时,
很多初学者(包括作者自己)都碰壁了,例如:


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

并立即提示:

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

作为菜鸟尝试了很多办法后, 才意识到 `.into_ter()` 取得了集合的所有权,
这不是我的目标所需要的;
相反, 在迭代器上还有另外两种有用的方法, 真希望当时能早点知道丫们;

第一个是 `.iter()` ,借用集合, 让你断言关于其值的东西,但是, 不拥有或是改变她们;
再有就是 `iter_mut()` 帮助你改变集合内部值,嘦你是唯一的exclusive reference/独占参考;

总之, 当你只需要借用时用 `.iter()`,
当你想要获得所有权时用 `.into_iter()`,
当你需要改变迭代对象的元素时用 `.iter_mut()`;

### Phantom 数据不仅仅用以处理指向类型的原始指针

当你第一次遇到 Phantom data/幻数据时,
一定感觉很奇怪,但是, 很快就会成为一种告诉编译器"拥有"某个值的好方式,
尽管只有一个指向她的原始指针;
例如:

```rust
use std::marker;

struct Foo<'a, T: 'a> {
    bar: *const T,
    _marker: marker::PhantomData<&'a T>,
}
```

这儿告诉编译器 Foo 拥有 T,
尽管只有一个指向她的原始指针;
这对于需要处理原始指针和使用 unsafe Rust 的应用程序很有帮助;

但是, 也可以是一种告诉编译器你的类型还没实现 Send 或是 Sync 特征的方法!
你可以使用 PhantomData 包装以下类型,并在你的结构中使用她们,
来作为一种方式告诉编译器你的结构即不是 Send 也不是 Sync;


```rust
pub type PhantomUnsync = PhantomData<Cell<()>>;
pub type PhantomUnsend = PhantomData<MutexGuard<'static, ()>>;
```

### 用 rayon 实现并行增量

有时, 你希望在遍历集会时并行化工作,
但是, 在处理线程和确保类型可以安全的跨线程发送时却碰壁了;
有时, 如果额外的样板文件令你的代码几乎不可读,那就已经不值得了;

相反, 有一个名为 Rayon 很赞的包, 已经提供了以无缝方式并行化计算的上好工具;
例如,假设我们有一个计算数组平方和的函数:

```rust
fn sum_of_squares(input: &[i32]) -> i32 {
    input.iter()
            .map(|i| i * i)
            .sum()
}
```

由于乘法和加法的性质, 上述代码绝对可以并行化,
Rayon 通过让我们自动访问数组等集会的"并行迭代器",
使并行化变得微不足道;
这是几乎零样板的代码;
而且也完全不影响可读性:


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

(`是也乎`:

工程中如果自己要构造各种内部库,
也值得给出这种使用界面,
和以往使用内置库的代码完全兼容,
只是在关键节点处替换为自己魔改/加强过的...
)


### 开发 Rust 库时理解 拓展特征 的概念

那么 Rayon 是如何以如此干净的方式完成上述工作的呢?
答案在于"拓展特征",
这些特征可以定义为对其它特征的拓展,
例如 Iterator;
也就是说,我们可以逈通常实现 Itertor 特征的项追加其它有用的函数,
但是, 她们只有在特性范畴以内时才可用,
比如通过将其导入文件中;

这种方式非常好,因为,这些特征只有在你在项目中导入拓展特征时才可用,
并提供了一种使用干净的 API 拓展通用集合和类型的好方法,
开发者可以像使用普通 API 一样轻松的使用这些 API;
由于 Rayon 的拓展特征,
使用并行迭代器就像在 Rust 中使用普通迭代器一样简单;

事实上,这有一个信息量很大的演讲,解释了如何使用 拓展特征 来开发一个在迭代器上提供进度条的库;

(`是也乎`:

["Type-Driven API Design in Rust" by Will Crichton - YouTube](https://www.youtube.com/watch?v=bnnacleqg6k)

配套看看 Rayon 官方对自己实现原理的嗯哼: [rayon/src/iter/plumbing at master · rayon-rs/rayon](https://github.com/rayon-rs/rayon/tree/master/src/iter/plumbing)
以及专门的解析文章: [How Rust supports Rayon's data parallelism | Red Hat Developer](https://developers.redhat.com/articles/2023/01/30/run-app-under-openshift-service-mesh)

大约可以感受到 Rust 世界的任性了...
)


### 拥抱 Option 和 Result 类型的一元性

使用 Option 和 Result 之后,
人们会很快看到`.unwrap()` 将值从她们移出,
如果 Option 和 Result 是共享引用(比如 struct)的一部分,
就将导致失败;
然而,有时我们想要的只是断言 Option 匹配内部的值或获取对其内部的引用;
有很多方法可以作到这点,
但是, 还有一种方式能不用离开 Option 领域:


```rust
fn check_five(x: Option<i32>) -> bool {
    // Contains can just check if the Option has what we want.
    x.contains(&5)
}
```

另一个示例是我们想要用 None 值替换 Option 内数据,
也就是和某些结构交互时;
我们可以用指令式编程的方式来编写,
并按照以下方式详细完成:


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

然而, Option 有一些非常酷的属性,
因为, 她们的基本性质是定义了有用的方法,
可以让我们的生源更加轻松;


```rust
// Takes the value of data and leaves None in its place.
fn pop(&mut self) -> Option<T> {
    self.data.take()
}
```

Rust 中的 Option 以函数式编程语言中相同的范例为模型,
属于更广泛的数据类型类别, 称为 Monad;
不用深入理解 Monad 是什么, 而嘦将其视为数据的包装器,
我们可以在不需要从中取出东西的情况下对其进行操作;
比如, 想象一个将两个 Option 内部值相加并返回一个 Option 的函数:


```rust
fn add(x: Option<i32>, y: Option<i32>) -> Option<i32> {
    if x.is_none() || y.is_none() {
        return None;
    }
    return Some(x.unwrap() + y.unwrap());
}
```

上述代码看起来有点点笨拙,因为,需要执行 none 检验,
而且我们必须从两个 Option 中提取值并从中构建一个新 Option 就很囧;
然而, 由于 Option 的特殊属性,
我们可以作的更好!
这是我们可以获得的:


```rust
fn add(x: Option<i32>, y: Option<i32>) -> Option<i32> {
    x.zip(y).map(|(a, b)| a+b)
}
```

可以对 option 使用 zip 和 map ,
就像我们可以处理数组和向量一样;
此属性也存在于 Result 类型中,
甚至存在于诸如 `Future` 类型之类事物中;
如果你对为什么这么作感到好奇,
请继续挖掘 Monad 的更多信息 -> [functional programming - Monad in plain English? (For the OOP programmer with no FP background) - Stack Overflow](https://stackoverflow.com/questions/2704652/monad-in-plain-english-for-the-oop-programmer-with-no-fp-background)

接受 Option 和 Result 类型的一元性质,
不要到处使用 unwrap 和 if x.is_none() {} else ;
本身就包含了很多有用的方法,
你可以在标准库中阅读这些方法;

(`是也乎:`

所以, 标准库的通读是一个基本功了,
不过, 相比 Python 等其它语言的官方文档,
docs.rs 实在太麻了点儿,还要习惯一下;

)


### 了解 Drop 应该如何针对不同数据结构实现

标准库将 Drop 特性描述为:

当不再需要某个值时, Rust 将对该值运行"析构函数";
不再需要某个值最常见方式是超出作用域;


```rust
pub trait Drop {
    fn drop(&mut self);
}
```


在 Rust 中编写数据结构时, Drop 是至关重要的;
人们必须有一种合理的方法来处理一旦不再需要内存时如何丢弃(安全的);
使用引用计数类型可以报时你克服这些障碍,
但是, 这并不总是足够的;
例如,编写自定义链表或是编写使用通道的结构时,通常要实现自定义版本的 Drop;
当你看到标准库实际如何执行时,
实现 Drop 比并看起来容易的多:

```rust
// That's it!
fn drop<T>(t: T) {}
```

巧妙利用失去作用域时销毁的规则,
`std::mem::drop` 有一个空函数体!

这是一个技巧, 你可以在自己的自定义 Drop 实现中使用,
嘦你涵盖所有基类?即可;



### 真的对借用检查员很气? 那就用不可变数据结构

函数式程序员喜欢说全局的/可变的状态是万恶之源,
如果可以避免,那毛还要使用呢?
多亏了 Rust 的函数式结构,
我们才能构建从一开始就不可能突变的结构结构!
当你需要编写类似在 Haskell/OCaml 或其它语言中看到的纯粹函数式代码时,
这尤其有用;

通过链接列表综合教程中的示例,
我们可以看到如何构建一个不可变列表,其中节点有引用计数:


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

这就很赞,因为,其行为类似于函数式数据结构,
在函数式数据结构中,
人们不会通过追加前缀来修改列表,
而是通过以新元素作为其头部和现有列表作为尾部来构建列表完成新构建;

```rust
    [head] ++ tail
```

请注意,上述方法都不需要 mut, 因为,我们的数据结构是不可变的!
这在内存上也是非常高效的,因为,该结构是引用计数的,
这意味着如果此数据结构上有多个调用者,
我们不会浪费不必要的资源来复制节点的底层内存;

Rust 中的纯函数代码很简洁,
但是,多数时候,需要尾递归来了把用我快这种方式实现的高性能代码；
而且，要小心，毕竟 Rust 编译器不保证尾调用优化；
值得进一步挖掘更多信息 -> [When is tail recursion guaranteed in Rust? - Stack Overflow](https://stackoverflow.com/questions/59257543/when-is-tail-recursion-guaranteed-in-rust)

(`是也乎:`

这就尴尬了, 只是个看起来很美的思路,
毕竟 Rust 不是纯函数语言,
递归并不是第一公民;

所以, 这种场景中,还是老实和 借用管理员 好好商量吧...

)

###  traits 篮有助减少重复

有时,可能希望通过很多不同的特征来约束泛型参数:


```rust
struct Foo<T: Copy + Clone + Ord + Bar + Baz + Nyan> {
    vals: Vec<T>,
}
```

但是,一旦你开始编写 impl 语句,
或是当你有多个通用参数时,
这很快就会失控;
相反你可溶性定义一个整体特征, 使代码更加 DRY;

```rust
trait Fooer: Copy + Clone + Ord + Bar + Baz + Nyan {}

struct Foo<F: Fooer> {
    vals: Vec<F>,
}

impl<F: Fooer> Foo<F> { ... }
```

traits 篮可以帮助减少重复，
但是，不要让其变得过大；
在很多情况中，
让一个类型需要如此多的约束可能会产生坏味道,
因为,你创建的抽象太大了;
相反,如果你发现约束无缘无故的变得太大,
请传入具体类型;
然而,某些应用和远又可能受益于 blanket traits/特征篮,
例如旨在提供尽可能通用的 API 库;


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


