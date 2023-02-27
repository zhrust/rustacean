# Rust 超越面向对象,第2部分
原文:[Rust Is Beyond Object-Oriented, Part 2: Polymorphism :: The Coded Message](https://www.thecodedmessage.com/posts/oop-2-polymorphism/)


## 快译

在这篇文章中, 通过讨论 OOP 三大传统支柱中的第二个: 多态,
继续系列文章:关于 Rust 和传统 OOP 范式的不同;

多态性是面向对象编程中的一个特别重要的话题，
也许是其三大支柱中最重要的一个;
关于多态性是什么, 各种编程语言如何实现(在 OOP 世界内外---是的,多态性也存在于 OOP 宇宙之外),
如何有效的使用, 以及更加关键的何时嫑使用;
可以写一些关于如何单独使用多态的 Rust 版本的书了;

不幸的是, 这只是一篇 blog,所以,
我无法像我想的那样详细或是多样性的介绍多态;
相反,我将特别关注 Rust 和 OOP 概念的不同之处;
我将从描述其在 OOP 中的工作方式开始,
然后, 讨论如何在 Rust 中实现相同的目标;

在 OOP 中,多态性就是一切;
试图采取所有决策(或是尽可能多的决策)并将其统一在一个通用的狭义机制中:
运行时多态;
但是, 不幸的是, 并不是任意运行时多态, 而是一种特定的/狭义的运行时多态形式,
受到 OOP 哲学和实现如何工作细节的限制:

- 间接需求: 每个对象通常都必须存储在堆上,才能使运行时多态生效, 因为,不同的"运行时类型"具有不同的尺寸; 这鼓励了可变对象的别名使用;不仅如此,要真正调用一个方法,必须穿过三层间接:
    - 解引用对象引用
    - 解引用类指针或是 “vtable” 指针
    - 最后完成间接函数调用
- 排斥优化: 除了间接函数调用的内在成本之外, 调用是间接的这一事实, 意味着内联是不可能的；通常,多态方法很小,甚至于微不足道,例如返回常量/设置字段或是重新排列参数并调用另一个方法, 因此, 内联会很有用; 内联对于允许优化跨内联边界也很重要;
- 仅能在单一参数上多态: 特殊的接收者参数,称为 self 或是 this, 是运行时多态也的并上通常可能通过的唯一参数; 其它参数的多态可以用那些类型中的辅助方式来模拟, 这就很尴尬, 而且, 返回类型的多态也是不可能的;
- 每个值都是独立多态的: 在运行时多态中, 通常没有办法说集合的所有元素都属于实现相同接口/interface 的某种类型 T,但是, 该类型是什么又应该在运行时能确定;
- 和其它 OOP 特性纠缠在一起: 在 C++ 中,运行时多态和继承紧密耦合；　在很多 OOP 语言中, 多态仅适用于类的类型, 正如我在上篇 blog 中讨论的那样, 类类型是一种受约束的模块形式;

其实我完全可以针对以上每条吐糟单独写一大篇文章 --- 也许有一天真的会;

不过,尽管有这么多限制, 多态仍然被视为使用 OOP 语言进行决策的首选方式,
并且, 特别直观且易于访问;
受过训练的程序员, 嘦可能就一定使用此工具,
无论是否是手上决策是最佳工具, 即便当前不需要用多态进行运行时决策;
有些编程语言,例如 Smalltalk 甚至折叠了 "if-then" 逻辑,
并循环到 this 这个奇怪的特定决策结构中,
通过多态方法(如: ifTrue:idFalse)最终实现,
这些方法将在 True 和 False 类中以不同方式再实现
(和 therefore 在 true 以及 false 对象上配套);

需要明确的是, 拥有基于 vtable 的运行时多态性机制本身并不是一件坏事儿 --- Rust 甚至有也一个
(和上述 OOP 版本相似,但是,并不完全对等);
但是, Rust 版本只用以相对罕见的情况, 在这种情况中,
该机制最适合整个儿 palette 机制;
在 OOP 中, 将这种严格约束且忾和用低下的决策制定形式提升到所有其它形式之上,
以及使用多态是表达程序注释和业务编辑的最佳方式以及最直观方式的哲学断言,
本身就是个问题;

事实证明,当你选择最适合手头情况的工具时, 编程更加吻合人体工程学 --- 而 OOP 运行时多态性,
只是偶尔才是最合适完成当前工作的实效工具;

因此, 让我们看看在 OOP 使用运行时多态性时, 可以使用的 Rust 版四种替代方案;




### 备选方案#0：枚举

不仅有其它形式的多态性, 而且具有更少的严格约束
(例如 Haskell 的类型类)或一组不同的权衡
(例如 Rust 的 trait,主要基于 Haskell 类型类),
Rust 中还有另外一个决策系统, 即:代数数据类型(ADTs, algebraic data types)
或曰求合/sum 类型,
也能接管 OOP 样式多态的很多应用程序;

在 Rust 中, 这些被称为 枚举/enums;
很多编程语言中的枚举是存储在整数尺寸类型中的常量列表,
有时以类型安全的方式实现(比如在 Java 中),
有时不是(比如在 C 中),
有时可以使用任何一种选项(比如,在 C++ 中枚举和枚举类之间就有区别);

Rust 枚举支持这种熟悉的用例, 而且具有类型安全:


```rust
pub enum Visibility {
    Visible,
    Invisible,
}
```

但是, 还支持和每个选项关联的附加字段,
创建类型理论中称为"总和类型"(sum type)的东西,
但在 C 或是 C++ 程序员中更加广为人知识的叫"联合标记"(tagged union)
--- 不同之处在于, Rust 中, 编译器知道并能强制执行标记;

以下是一些枚举声明的示例:


```rust
pub enum UserId {
    Username(String),
    Anonymous(IpAddress),
    // ^^ This isn't supposed to be a real network type,
    // just an example.
}

let user1 = User::Username("foo".to_string());
let user2 = User::Anonymous(parse_ip("127.0.0.1")?);

pub enum HostIdentifier {
    Dns(DomainName),
    Ipv4Addr(Ipv4Addr),
    Ipv6Addr(Ipv6Addr),
}

pub enum Location {
    Nowhere,
    Address(Address),
    Coordinates {
        lat: f64,
        long: f64,
    }
}

let loc1 = Location::Nowhere;
let loc2 = Location::Coordinates {
    lat: 80.0,
    long: 40.0,
};
```

你可能会问,这些`联合标记`和多态有什么关系?
好吧, 大多数 OOP 语言对于这些 求合类型/sum type 没什么好办法,
但是, 她们确实有强大的运行时多态机制,
所以, 你会看到运行时多态用 Rust 枚举实现也是一样的适合
(我可能进一步争辩: 更加合适):
每当有一些小关于如何协商会议值的选项, 但是,这些选项又包含不同细节时;

比如, 这是一种使用继承和运行时多态在 Java 中表示 UserId 类型的方法 --- 当我还是学生时, 
肯定会这么来(将每个类放在不同的文件中):


```java
class UserId {
}

class Username extends UserId {
    private String username;
    public Username(String username) {
        this.username = username;
    }

    // ... getters, setters, etc.
}

class AnonymousUser extends UserId {
    private Ipv4Address ipAddress;
    
    // ... constructor, getters, setters, etc.
}

UserId user1 = new Username("foo");
UserId user2 = new AnonymousUser(new Ipv4Address("127.0.0.1"));
```

重要的是, 就像在枚举示例中一样,
我们可以将 user1 和 user2 给定相同类型的变量,
并将她们得狮给相同类型的函数, 并通常对她们执行相同的操作;

现在这些 OOP 风格的类看起来轻飘到飞溅的程度,
但是, 这主要是因为我们没有为这种情况添加任何真正的操作代码 --- 只有数据和结构, 
以及一些变量定义和模板;
让我们考虑一下, 如果我们真的对用户 ID 尝试进行任何操作时会怎么样?

例如,我们可能想确认她们是否为管理员;
在我们的假设中, 假设匿名用户永远不是管理员,
而拥有用户名的用户只有在用户名以字符串 admin_ 开头时,才是位管理员;

理论上认可的 OOP 方法是添加一个方法,
比如: administrator;
为了让这个方法起作用, 我们必须将其追加到所有三个类: 基数以及两个子类:

```java
class UserId {
    // ...
    public abstract bool isAdministrator();
}

class Username extends UserId {
    // ...
    public bool isAdministrator() {
        return username.startsWith("admin_");
    }
}

class AnonymousUser extends UserId {
    // ...
    public bool isAdminstrator() {
        return false;
    }
}
```

因此, 为了在 Java 中为这种类型添加这种简单的操作,如此简单的能力,
我们却必须使用三个类,
而且必须存储在三个文件中;
丫们每个对象都包含一个方法来作一些简单的事儿,
但是, 在任何羌族都看不到谁是管理员, 又或者不是管理员的完整逻辑 --- 有人可能会很不合时宜的问出这个问题;

Rust 则为这种操作使用 match,
将有关所有信息放在一个地方完成判定:


```rust
fn is_administrator(user: &UserId) -> bool {
    match user {
        UserId::Username(name) => name.starts_with("admin_"),
        UserId::AnonymousUser(_) => false,
    }
}
```

诚然, 这将产生更加复杂的单个函数,
但是,具有明确的所有逻辑;
让编辑明显而不是隐含在继承屡次结构中, 
这就违反了 OOP 原则, 
在 OOP 宇宙中, 方法应该简单, 多态性用于隐含的表达逻辑;
但是,这并不能保证任何事儿, 只是将其扫到地毯下而已:
事实证明, 隐藏复杂性会令其更难应对, 而不是相反;

让的我们来看另外一个例子;
我们已经用了一段时间的 UserId 代码,
你的任务是为这个系统编写一个新的 Web 前端;
你需要某种方式, 以 HTML 格式显示用户信息,
要么是指向用户配置文件的链接(对于指定用户),
要么是将 IP 地址字符串化为红色(对于匿名用户);
因此, 你决定为这个小型类型追加一个新操作 toHTML,
将输出新前端的专用 DOM 类型;
(也许 Java 被编译为 WebAssembly 呢? 我也不确定,不过细节不重要;-)


你逈后端核心库深入的 UserId 类屡次结构的维护者提交了 pull request;
然后, 他们拒绝了;

事实上, 他们有很好的理由, 你必须勉强承认;
他们说:"这是一种荒谬的关注点分离";
此外, 公司也无法从你的前端获得此核心库处理类型;

所以, 你叹了口气, 写了个 Rust 匹配表达式的等价物, 但是用的是 Java
(请原谅我荒谬的假设有个 HTML 库):


```java
Html userIdToHtml(UserId userId) {
    if (userId instanceof Username) {
        Username username = (Username)userId;
        String usernameString = username.getUsername();
        Url url = ProfileHandler.getProfileForUsername(usernameString);
        return Link.createTextLink(url, username.getUsername());
    } else if (userId instanceof AnonymousUser) {
        AnonymousUser anonymousUser = (AnonymousUser)userId;
        return Span.createColoredText(anonymousUser.getIp().formatString(), "red");
    } else {
        throw new RuntimeException("IDK, man");
    }
}
```

你的老板们在代码审查时拒绝了这段代码,
你你使用了 instanceof 反模式,
但是, 后来在你让他们和不接受你的其它补丁的核心库维护者争论之后,
丫们勉强接受了这段代码;

但是, 看看那坨 instanceof 代码有多难看!
难怪 Java 程序员认为这是一种反模式!
但是, 在这种情况中, 已经是最合理的事儿了,
实际上, 是除了实施观察者东西方或是访问者模式又或是其它相当于基础设施的东西之外,
唯一可能的实现, 只是用来创造具有控制反转的实例而已;

当操作集有界(或是接近有限)并且该类的子类数量可能以意想不到的方式增长时,
通过向每个子类追加一个方法来实现操作是有意义的;
可是,通常情况中, 操作的数量又会以意想不到的方式增长,
而子类的数量总是有限的(又或是接近有限);

对于后一种情况, 这种情况比 OOP 拥护者想象的更加常见,
Rust 枚举 --- 以及一般的 求和类型 --- 是完美的;
一但你习惯了她们, 你就会发现自己一直在使用;

我要郑重声明,
在所有面向对象的编程语言中,都没有这么糟糕;
在某些情况中, 你可以按任何顺序编写任意类方法组合,
因此,如果你愿意, 可以将所有三个实现写在一个地方;
Smalltalk 传统上允许你在一个特殊的浏览器中游览代码库,
你可以在其中看到一个类实现的方法列表,
或者一个接受给定"消息"的类列表,
正如 Smalltalk 所说的那样,
这样你就可以随心所欲的操弄对象了;

(译按: 当然, 你必须在 Salltalk 对应解释器的 IDE 环境中, 一但出了这个对象镜像, 将失去一切观察能力, 这导致 Smalltalk 没办法使用其它传统 IDE)



### 备选方案 #1: 闭包
> Alternative #1: Closures

有时, 一个 OOP 接口或是多态决策只涉及一个实际操作;
在这种情况中,只能使用闭包;

我不想在这方面花太多时间,
因为, 大多数 OOP 程序员已经意识到这点,
并且, 自从他们的 OOP 语言已经赶上了函数式语言,
并获得了 lambda 语法 --- Java 中的 Java 8 ,
C++ 中的, C++11;
因此, 像 Java 的 Comparator 这种愚蠢的单一方法接口 ---
幸运的是 --- 基本上已经都感染过去式了;

此外, Rust 中的闭包在技术上涉及 traits,
因此,使用和接下来的两个替代方案相同的机制来竀,
所以,也有人可能会争辩说这在 Rust 中并不是真正的独立选项;
然而,在我看来 lambda/闭包和
FnMut/FnOnce/Fn 等 trait 们在美学上和情境上都非常特别,
值得花点时间掌握;

因此, 我将花些时时间来说明这点:
如果你发现自己只使用一种方法编写 trait 
(Java 接口或是 C++ 类),
请考虑你是否应该改用某种闭包或是 lambda 类型;
毕竟只有你自己才能防止过度设计;

### 备选方案#2: 具有Traits的多态

就像 Rust 有个比 OOP 类概念更加灵活/强大的封装版本,
正如在上篇文章中讨论的那样,
Rust 有一个比 OOP 假设更加强大的多态版本: trait;

trait 就像来自 Java 的接口
(又或是 C++ 中的全抽象超类),
但是,并没有我在文章开头指出的大部分限制;
trait 即没有语义约束, 也没有性能约束;
trait 在语义和原理方面深受 C++ 模板的启发;
C++ 程序员可以将其视为带有concepts/概念的模板
(除非设计的,从一开始就融入编程语言,
而且不必要处理所有不使用它的代码;)

让我们从语义开始:
你可以使用 trait 完成那些无法使用纯 OOP 完成的,
即便你将世界上所有的间接调用都丢给她?
好吧, 在纯粹的 OOP 术语中,
是无法编写像 Rust Eq 和 Ord 这样的接口,
这里给出了非常简单的定义
(Eq 和 Ord 的真正定义在于拓展了其它允许不同类型之间的部分等价和排序的类,
但是, 像这种简化定义,
非部分 Eq 和 Ord 的 Rust 标准库版本确定涵盖了相同类型值之间的等价和排序):


```rust
trait Eq {
    fn eq(self, other: &Self) -> bool;
}

pub enum Ordering {
    Less,
    Equal,
    Greater,
}

trait Ord: Eq {
    fn cmp(&self, other: &Self) -> Ordering;
}
```

看看发生了什么?
就像在 OOP 风格的接口中一样,
这些无法采用 Self 类型的“接受者”类型,
一个 self 秋粮 -- 也就是说,任何实现 trait 的具体类型
(技术上这里是对 Self 或 &Self 的引用);
但是, 和 OOP 风格的接口不同,
这里还能采用另外一个 &Self 类型的参数;
为了实现 Eq 和 Ord,
类型 T 提供了一个函数,
该函数接受对 T 的两个引用;
字面上的意思是: 对 T 的两个引用, 而不是对 T 的一个引用和对 T 或是任何子类的一个引用
(这样的事情在 Rust 中并不存在),
不是对 T 的一个引用和对实现 Eq 的任何其它值的一个引用,
而是对同一具体类型的两个真正的非异构引用,
然后，函数就可以比较她们是否相等(或是进行排序);

这点很就将要,因为,
我们想用这种能力来实现像排序这类方法:

```rust
impl Vec<T> {
    pub fn sort(&mut self) where T: Ord {
        // ...
    }
}
```


OOP-style polymorphism is ideal for heterogeneous containers, where each element has its own runtime type and its own implementation of the interfaces. But sort doesn’t work like that. You can’t sort a collection like [3, "Hello", true]; there’s no reasonable ordering across all types.

Instead, sort operates on homogeneous containers. All the elements have to match in type, so that they can be mutually compared. They don’t each need to have different implementations of the operations.

Nevertheless, sort is still polymorphic. A sorting algorithm is the same for integers or strings, but comparing integers is a completely different operation than comparing strings. The sorting algorithm needs a way of invoking an operation on its items – the comparison operation – differently for different types, while still having the same overall structure of code.

This can be done by injecting a comparison function, but many types have an intrinsic, default ordering, and sort should default to it. Thus, polymorphism – but not an OOP-friendly variety.

See the contrivance Java goes through to define sort:


```rust
static <T extends Comparable<? super T>> 
void sort(List<T> list)
```


There is no simple trait that can require T to be comparable to other Ts, for T to be ordered. Instead, as far as the programming language is concerned, the idea that T is comparable to itself, rather than to any other random type, is only articulated as an accident to this method. Nothing is stopping someone from implementing the Comparable interface in an inconsistent way, like having Integer implement Comparable<String>.

Additionally, when it actually looks up the implementation of Comparable, it decides what implementation to use based on the first argument of any comparison, not based on the type. Normally, they will all be the same type, but theoretically, this list could be heterogeneous, as long as all the objects “extend” T, and they could implement Comparable differently. The computer has to do extra work to indulge this possibility, even though it would certainly be a mistake.

As we’re now drifting outside of the realm of semantics, and into the realm of performance, let’s discuss the performance implementations of this fully.

The Java sort method, as we mentioned, requires every item in the collection to be a full object type, which means that instead of storing the values directly in the array, the values are stored in the heap, and references are stored in the array. This is unnecessary with a traits-based approach – the values can live directly in the array.

This means that different arrays will have different element sizes, so this has to be handled by a trait as well. And it is: The size of the values is also parameterized via the Sized trait. The size does have to be consistent among all the items of the array, but this is enforceable because we can express that all the elements are actually the exact same type – unlike Java’s List<T> which only expresses that they’re of type T or some subtype of T.

Rust’s sort method could have been implemented by passing the size information (from the Sized trait) and the ordering function (from the Ord trait) at runtime as an integer value and a function pointer. This is how typeclasses work in Haskell, which was the inspiration for Rust traits. This would still be more efficient than the Java, as there would be a single ordering function, rather than a different indirect lookup for every left side of the comparison, allowing indirect branch prediction to work in the processor.

But Rust goes even further than that, and implements its traits instead via monomorphization. This is similar to C++ template instantiation, but semantically better constrained. The premise is that while sort is only one method semantically, in the outputted, compiled code, a different version of sort is outputted for every type T that it is called with.

C++ templates create infamously bad error messages and are difficult to reason about, because they are essentially macros, and awkward ones. Even Rust cannot create great error messages with its macro system. But also, writing them requires expertise, and means that the programmer is forgoing many of the benefits of the type system – templates are often called, in my opinion rightly so, a form of compile time duck-typing. For these reasons, template programming in C++ is often considered more advanced (read as harder and less convenient rather than more powerful) than OOP-style polymorphism.

In Rust, however, traits provide an organized and more coherent way of accessing similar technology, getting the performance benefits of templates while still giving the structure of a solid type system.

### Alternative #3: Dynamic Trait Objects
Sometimes, however, you do need full run-time polymorphism. You have the opposite of the scenario with the enum: You have a closed set of operations that can be performed on a value, but what those operations actually do will change dynamically in a way that cannot be bounded ahead of time.

In such situations, Rust has you covered with the dyn keyword. Please don’t overuse it, though. In almost all situations where I’ve thought it might be appropriate, static polymorphism combined with other design elements have worked out better.

Legitimate use cases for dyn tend to come up in situations involving inversion of control, where a framework library takes on a main loop, and the client code says how to handle various events. In network programming, the framework library says how to juggle all the sockets and register them with the operating system, but the application needs to say what to actually do with the data. In GUI programming, the framework code can say what widget was being clicked on, but very different things happen if that widget is a button versus a text box versus a custom widget you invented for this particular app.

Now, you don’t strictly need run-time polymorphism for this. You could use closures (or even raw function pointers) instead, creating struct of closures (or function pointers) if multiple operations are called for – which amounts to basically doing what dyn does the hard way by hand. For example, I fully expected tokio to use Rust’s run-time polymorphism feature internally to handle this inversion of control in task scheduling. Instead, for what I imagine are performance reasons, tokio implements dyn by hand, even calling its struct of function pointers Vtable.

But dyn does all of this work for you, for your trait. The only requirement is that your trait be object-safe, and the list of requirements may seem familiar, especially when it comes to the requirements for an associated function (e.g. a method) to be “dispatchable”:

------

- Not have any type parameters (although lifetime parameters are allowed),
- Be a method that does not use Self except in the type of the receiver.
- Have a receiver with one of the following types:
    - &Self (i.e. &self)
    - &mut Self (i.e &mut self)
    - Box<Self>
    - Rc<Self>
    - Arc<Self>
    - Pin<P> where P is one of the types above
- Does not have a where Self: Sized bound (receiver type of Self (i.e. self) implies this).

------



That is to say, it can be polymorphic in exactly one parameter, and that parameter must be by reference – more or less the exact requirements for methods to support run-time polymorphism in OOP.

This is of course because dyn uses almost exactly the same mechanism as OOP to implement run-time polymorphism: the “vtable.” Box<dyn Foo> really contains two pointers rather than one, one to the object in question, and the pointer to the “vtable,” the automatically-generated structure of function pointers for that type. The one-parameter requirement is because that is the parameter whose vtable is used to look up which concrete implementation of a method to call, and the indirection requirement is because the concrete type might be different sizes, with the size only known at run-time.

To be clear, these are limitations on one particular implementation strategy for run-time polymorphism. Alternative strategies exist that fully decouple the vtable from individual values of the type, as in Haskell.

There are still a few advantages of Rust’s version of run-time polymorphism with traits as opposed to OOP-style interfaces.

Performance-wise, it’s something done alongside a type, rather than intrinsic to the type. Normal values don’t store a vtable, spreading the cost of this throughout the program, but rather, the vtables are only referenced when a dyn pointer is created. If you never create a dyn pointer to a value of a given type, that type’s vtable doesn’t even have to be created. Certainly, you don’t have 8 bytes of extra gunk in every allocation for all the vtable pointers! This also means there’s one fewer level of indirection.

Semantically, it’s also a good thing that it’s just one option among many, and that it’s not the strongly preferred option that the entire programming language is trying to push you towards. Often, even usually, static polymorphism, enums, or even just good old-fashioned closures more accurately represent the problem at hand, and should be used instead.

Finally, the fact that run-time and static polymorphism in Rust both use traits makes it easier to transition from one system to another. If you find yourself using dyn for a trait, you don’t have to use it everywhere that trait is used. You can use the mechanisms of static polymorphism (like type parameters and impl Trait) instead, freely mixing and matching with the same traits.

Unlike in C++, you don’t have to learn two completely different sets of syntax for concepts vs parent classes, and vastly different semantics. Really, in Rust, dynamic polymorphism is just a special case of static polymorphism, and the only differences are the things that actually are different.


## logging

- 230215 ZQ init.