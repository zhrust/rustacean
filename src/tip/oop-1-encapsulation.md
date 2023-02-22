# Rust 超越面向对象,第1部分
原文: [Rust Is Beyond Object-Oriented, Part 1: Intro and Encapsulation :: The Coded Message](https://www.thecodedmessage.com/posts/oop-1-encapsulation/)


## 快译

是的, Rust 不是一种 OOP 编程语言;

Rust 可能看起来像一种 OOP 编程语言:
类型可以和 "“methods" 关联,
可以是 "intrinsic" 的或是通过 "traits";
通常可以使用 C++ 或是 Java 风格的 OOP 语法调用方式:
map.insert(key, value) 或 foo.clone();
就像在 OOP 语言中一样,
此语法涉及放置在调用者的 `.` 中, 而在被调用者中称为 self;


但请不要误会: 尽管 Rust 可能借用了一些技巧/术语和语法,
但是, Rust 并不是一种面向对象的编程语言;
面向对象编程的三大支柱理念: 封装/多态/继承;
其中, Rust 完全否决了 继承,
因此, 永远不可能成为"真正的" OOP 语言;
不过, 即便对于封装和多态, Rust 实现的方式也和 OOP 语言不同 --- 稍后将对此进行更加详细的介绍;

这一切都让很多程序员感到惊讶以及无措;
我在 Reddit 上看到 Rust 新手询问如何按字面意思实现 OOP 设计模式,
试图获得像“shapes” 或是 “vehicles”这种"类层次结构",
使用作为"Rust 版本继承"的 traits --- 换句话说, 
试图解决他们想象中的问题, 
因为, 他们致力于 OOP 方法, 并通过构建人为的 OOP 示例来尝试了解他们期待的应该存在的另外一个版本 Rust;

这对很多人来说是一个绊脚石;
我经常看到 Rust 新手和怀疑论者在互联网上提到"缺乏OOP",
这是 Rust 难以适应/不合适他们的关键原因,
甚至是 Rust 永远不会流行的原因;
对于那些在 OOP 的高度来学习编程的人来说 --- 当像 C 和 ML 那样完美的语言都必须变成 Object-C 和 OCaML 这种面向对象的语言 --- 
对非 OOP 语言的大量炒作感觉就不太香了;


这也不是一个容易的调整;
如此多的程序猿以明确的面向对象的方式学习软件设计和体系结构;
我看到一个又一个问题,
一个初级或中级 Rust 程序员想要作一个面向对象的事儿,
并想要一个字面上的 Rust 等价物;
通常, 这些都是经典的 "XY 问题" (原文:[XY problem](https://xyproblem.info/), 酷壳有精采的翻译:[X-Y Problem | 酷 壳 - CoolShell](https://coolshell.cn/articles/10804.html))案例, 他们很难调头用更 Rusty 的方式解决问题;

这其实都不是 Rust 的错;
答案还是要我们去调整,
虽然不容易;
我们要成为更好的程序员, 不仅精通多种语言,
而且要精通不同的编程范式;

而且, 作为一种范式, OOP 实际上非常平庸 --- 以至于我写了一整篇文章来解释为什么,
以及为什么 Rust 的方法更好;


### 面向对象思想
> OOP Ideology

嗯哼,好象明白了;
我曾经是自己主动变成 OOP 信徒的;
还记得当年是如何向我们收费的:
不仅仅是一套代码组织实践,更加是编程方面的一场革命;
OOP 方法被认为更直观,尤其对非程序员而言, 因为更加符合我们对自然世界的看法;

对于这种营销的典型示例, 以下是流行杂志(Byte Magazine, 1981年)中关于 OOP 第一篇公开文章的摘录:


------

> 许多不知道计算机如何工作的人发现 OOP 想法很自然;
> 相比之下, 反而是很多有计算机经验的人最初认为 OOP 系统有些奇怪...

------


为 OOP 买帐很容易;
当然, 我们的日常生源没有任何子程序或是变量之类的东西 --- 或者,
即便有, 我们也没有明确的考虑它们!
但是, 生活中确实有我们可以与之交互的对象, 每个对象都有自己的功能;
怎么可能不直观呢?

这是非常引人注目的伪认知科学,轻研究,重说服力;
这些 object/对象 可以认为是 "agents", 几乎象人一样,
所以, 你可以利用你的社交技能来处理它,
而不仅仅是分析性思维
(嫑介意 object/对象 的行为一点儿也不像人,而且,实际上在某种程序上更加笨,
这时仍然需要分析思维);
或是, 你可以将对象和类视为形式世界本身的近乎柏拉图式的表达, 使其在哲学上引人注目;


哦, 当年我是如何接受的? 尤其是在肆意鲁莽的青年时期；
我个人吸收了 OOP 和柏拉图之间的联系;
深入研究了元对象协议, 
以及在 Smalltalk 中每个类都必须有一个元类的事实;
Smalltalk 代码元类的概念对我来说几乎是神秘的,
因为, 任何值都可以组织在同一层次结构中,
对象反而位于其根部;

我赢得在一本书中读到 OOP 风格的多态使得 if-else 语句变得多余,
因此,我们应该努力最终只使用 OOP 风格的多态;
不知何故, 这没让我失望, 这让我当时很兴奋;
而且,当我了解到 Smalltalk 实际正是这样作的,
就更加兴奋了
(如果你忽略优化掉某些抽象的实现细节):
在 Smalltalk 中, if-than-else 的概念是通过 ifTrue: 和 ifElse: 以及 ifTrue:ifFalse: 等方法实现的,
还得配套单实例的 True 和 False 类,以及其全局对象 true 和 false;

(译按: 光是听起来就非常,嗯哼? 这不是一样的东西嘛?)

作为一名更成熟的程序员,接触到意识形态较少的 C++ OOP 以及 Haskell 中的函数式编程替代方案后,
我的立场就软化了, 然后, 发生了巨大转变, 现在我几乎不再是 OOP 的脑残粉,
尤其是当其最佳思想已经在 Haskell 和 Rust 中进行了更新综合;
我已意识到这种对新程序员的炒作对于任何范式都是典型的(FUD ~ Fear/Uncertainty/Doubt, 意为:懼、惑、疑, 现在统称为 PUA 技术);
对于新手来说, 任何新编程范式都来了使用不同范式的资深程序员更加直观;
函数式编程也是如此;
甚至对于 Rust 也有同样的说法;
其实和范式是否更好并无太大的关系;


至于 if-else 语句完全用多态来替换,
好吧, 很容易想出一组图灵完备的元语;
你不邕为用多态来模拟 if 语句以及 true;
你还可以模拟带有递归的 shile 循环,
又或是带有 while 循环和堆栈的递归；
你可以使用 while 循环模拟 if 语句;

这些事实都不能使用这种替代成为一个好主意;
对于不同的情况, 编程语言中存在不同的特性,
适度的对应使用, 实际上原本就是一件好事情;

毕竟,编程的目的是编写程序, 而不是证明图灵完备性/哲学研究又或是写概念诗;

(译按: 不过, 现实中的确有这类研究僧, 主要社会贡献就是制造新概念哪...)

### 实用性
> Practicality

因此, 在这个系列文章中, 我打算从实际角度评估 OOP,
作为一名程序猿, 在使编程语言在认知上更易于管理或是更容易进行抽象方面具有经验;
我将根据我解决实际编程问题的经验来进行评估 --- 我认为这是种不好的迹象,
很多 OOP 抽象如何工作的案例只有在真正高级的程序中才有意义,
或是关于动物园中不同类型的形状或是动物的人为例子才有意义;

和大多数 OOP 介绍不同, 我不会关注 OOP 和 OOP　之前的编程语言的比较；
相反, 我将主要和 Rust 进行比较,
Rust 从 OOP 中汲取了很多好想法,
也许还会和函数式编程语言(比如 Haskell)进行比较;
这些编程语言采纳了 OOP 的一些好想法,
但是, 都以一种修复缺陷并进一步超越的姿态, 对合理的 OOP 进行了改造;

我将根据面向对象编程的三个传统支柱: 封装/多态和继承来组织这种比较,
第一篇将重点放在封装上;
对于每个支柱, 将讨论 OOP 如何定义, 以及在 OOP 世界之外存在哪些等价物或是替代品,
以及这些在实际易用性和编程能力方面进行对比;

不过,在开始之前,想先谈谈一个用例, 这个用例曾颠覆过大部分内容: 图形用户界面或是说 GUI;
尤其是在浏览器时代之前,
编写 GUI 程序以便直接在台式机(或笔记本电脑)上运行,
是程序员工作的主要部分;
OOP 的许多早期开发是和 Xerox PARC 的图形用户界面研究一起完成的,
OOP 非常适合该用例;
因此, 值得优先考虑 GUI;

例如, 人们通常会在其它编程语言中模拟 OOP;
GTK+ 就是一个很好的例子,
将 OOP 实现为 C 中一系列宏和约定;
这样作的原因有很多,包括熟悉 OOP 设计和希望创建某种运行时的多态;
但是,根据我的经验, 这在实现 GUI 框架时最为常见;

在本系列文章中, 主要关注将 OOP 应用在其它用途的场景,
但是,也会酌情讨论 GUI;
在这个介绍性部, 我仅指出 GUI 框架在传统 OOP 设计和编程语言之外显然是可能的,
甚至于在 Rust 中也是如此;
有时, GUI 可以通过完全不同的机制工作,
例如主要在 Haskell 中开创性的功能响应式了渔的哪, 我个人更加喜欢传统的基于 OOP 的编程,
而传统的 OOP 功能对此却并没有什么帮助;

现在, 事不宜迟, 让我们从实用角度, 逐一比较 OOP 和 Rust 以及其后各种 OOP 编程语言;
对于首篇文章, 其余部分将重点关注封装;


### 第一支柱: 封装/ Encapsulation

在面向对象编程中, 封装和类的概念密切相关,
类是面向对象编程中的基本抽象层;
每个类都包含一些记录数据的格式/布局,
即, 每个实例包含一定数量字段的数据结构;
记录类型的单个实例称为"对象";
每个类还包含和该记录类型紧密配对的代码,
组织成称为方法的过程;
核心想法是, 所有字段都只能从方法内部访问,
无论是通过 OOP 意识形态的约定还是通过编程语言的强制规则;

这里的基本好处是 接口/interface ,也就是代码如何和其它代码交互,
或者说你必须知道什么才能使用代码,
比 实现/implementation 要简单的多, 实现/implementation 是代码如何实际完成 的更加流畅变化的细节, 其原本的工作;

但是, 虽然许多编程语言都有这样的抽象;
任何超过十几行的程序就有太多的部分, 无法一次全部反映到你的大脑中,
因此,所有现代编程语言都有将程序划分为更小组件的方法,
作为管理复杂性的一种方式,
接口/interface 总是比 实现/implementation 更加简单,
无论是由编程语言强制执行, 还是"荣誉系统"的问题;
因此, 从广义上玛, 所有现代编程语言都有某种版本的封装;

一种简单的封装形式 --- 太多数面向对象的编程语言将其作为类中的一层来维护 --- 就是过程,
也称为函数/子例程或是(OOP 中的称呼)方法;
现代编程语言不允许任何代码行直接跳转到任何其它代码行,
而是倾向将代码块组合为过程,
然后, 你可以在不影响外部代码的情况下,
更改过程的内容, 并更改外部代码, 同样在不影响程序的情况下,
嘦都遵循相同的 接口/interface 和 契约/contract;

契约/contract 通常至少部分是人类层面的约定;
一般没有什么可以阻止你采用一个应该处理一些数据的过程,
而是让其无限循环或是令程序崩溃;
但是, 其中的一些, 例如过程和程序其余部分的分离, 
以及在许多情况中, 允许在调用中接受和返回的值的数量和类型,
将由编程语言强制执行;

例如,在过程内部声明的变量通常是局部的,
而且没有办法在过程外部引用;
输入和输出通常姴在过程顶部的签名中;
通常, 外部代码只能在第一行进入过程, 而不能在中途的任意一行进入;
某些编程语言(包括 Rust)中, 过程甚至于可以包含其它过程,
这些过程只能在外部过程中调用;

但是,当然现代程序通常比少数用锥程序更复杂;
因此,现代编程语言(再次强调: **"现代"** 一词在这里的使用非常宽松)具有另一层封装抽象:模块;

模块通常包含一组过程,有些可以从外部访问, 有些则不能;
在非 duck 类型语言中, 通常要定义很多聚合类型, 同样是有些可以从外部访问,有些不行;
通常甚至于可以抽象的公开这些类型,因此,程序的其余部分可以访问类型的实在,但是不能访问记录字段,
甚至于不能访问是记录类型的事实;
甚至于 C 在其模块系统中也有这种能力 --- 反而是 C++ 没有引入这点, 只是追加了一个额外的/正交级别的逐字段访问控制;

从务实的角度来看,基于类的封装并不是 OOP 的某个特殊见解,
而是一种专门的---或是更确切的说, 严格限制的---模块形式;
在 OOP 编程语言中, 我们有类的概念, 是一种特殊形式的模块
(有时是唯一受支持的形式, 有时甚至于在完全不同的/更加传统的模块概念下分层,以便增加概念上的混淆);
只是,对于一个"类",通常只能定义一个主要类型, 和模块本身共享一个名称,
而且,该类型的字段被给予特殊保护, 以便防止类外代码的访问;

当然, 类和模块之间还有其它区别,但是,这些和其支柱有关, 我们稍后将论及;
现在我们只讨论和封装相关的 "类" 概念 --- 其中, 类只是具有一种特权抽象类型的特殊模块;

这是一种编写模块的合理方式,但是, 并不像面向对象编程思想所表明的那样特别
(特别是当我们讨论其它支柱的替代方案时,但是,同样稍后再讨论);
在某些情况中,模块没有定义任何记录类型,这在 Java 等编程语言中很尴尬,
无论如何你都必须定义一个空记录类型, 并仍然创建一个 "类";
在某些情况中, 一个模块定义了多个可以公开访问的类型,
这些类型紧密的纠缠在一起 --- 并且 OOP 风格鼓励你在这些类型之间进行封装, 这样一来更多的阻碍而不是帮助;

从根本上说, 能够对其它模块隐藏记录的字段很重要, 这就是为什么 C 也支持;
甚至对于在 Rust 中实现对不安全特性的安全抽象是必不可少的,
例如集合/collections, 其中原始指针和一同记录的其它字段相结合具有不变量;
但是, 这对 OOP 来说并不陌生,而且, 这并不是每种可能类型的最佳选择;

作为这点的证据,在 Java 和 Smalltalk 中,
在较小程度上甚至在 C++ 或是 Python 中,
坚持每一种类型的封装风格意味着你可以获得这些样板方法,
比如说 setFoo 和 getFoo;
这些方法什么都不作,只是充当一些本质上是哑记录类型的字段访问器;
从理论上说, 如果你想更改设置或是读取这些字段时发生的事情,
这会有所帮助,得是不是, 实际上, 这只是原始字段访问器, 本质上就是 契约/contract 的一部分;
例如, 如果她们改为进行网络调用而不是仅仅返回一个值,
那么对于这种简单命名的方法, 将强烈触发惊喜原则:

说起来要简单的多:

```rust
pub struct Point {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}
```

… than the Java idiomatic “JavaBean” equivalent from when I was a Java programmer (Java has apparently changed since then, but this is representative of many OOP programming languages including Smalltalk and many books on how to program):

```rust
class Point {
    private double x;
    private double y;
    private double z;

    double getX() {
        return x;
    }

    double setX(double x) {
        this.x = x;
    }

    double getY() {
        return y;
    }

    double setY(double y) {
        this.y = y;
    }

    double getZ() {
        return z;
    }

    double setZ(double z) {
        this.z = z;
    }
}
```

Such data types generally don’t use any of the other features that OOP classes get, such as polymorphism or inheritance. To use such features in such “JavaBean” classes would also violate the principle of least surprise. The “class” concept is overkill for these record types.

And of course, a Java developer (or Smalltalk, or C#) will say that by accessing the fields indirectly through these getter and setter methods, that they are future-proofing the class, in case the design changes (and in fact I was reminded to add this paragraph when someone on Reddit made exactly this point). But I find this disingenuous, or at least misguided – it is often used for structures internal to a portion of the program, where the far more reasonable thing to do would be to change the fields openly to all users of the structure. It is also extremely difficult to think of an unsurprising thing for these methods to do besides literally set or get a field, as the method name implies – making a network call, for example, would be a shocking surprise for a get or set method and therefore a violation of at least the implicit contract. In my time programming object-oriented programming languages, I never once saw a situation where it was appropriate for a getter or setter to do anything but literally get or set the field.

If code does change to require the getter or setter to do something else, I would rather change the name of the method to reflect what else it does, rather than pretend that’s somehow not a breaking change. fetchZFromNetwork or setAndValidateZ seem more appropriate than a getZ or setZ that does something more than the simple field access that we assume a setter or getter does. OOP’s insistence that every type should be its own code abstraction boundary is often absurd when applied to these lightweight aggregate types. These sorts of getters and setters are used to protect an abstraction boundary that shouldn’t exist and just gets in the way, and future-proof against implementation changes that shouldn’t be made without also changing the interface.

Setters and getters, in short, are an anti-pattern. If you intend to create an abstraction besides “data structure,” where validation or network calls or anything else beyond raw field accesses would be appropriate, then these get and set names are the wrong names for that abstraction.

Edit 2023-02-13 to add this paragraph: To be clear, these objections apply to properties as well. It’s not the syntactic inconvenience that I object to, but the entire notion that replacing field accesses with code transparently is a good thing to strive for, or an important possibility to leave open. I should hope that foo.bar = 3 would never make a network call in Rust! And what if it had to be async? It should be clear if I’m calling a function. Rust is about explicitness.

The get and set functions, in reality, are only used as wrappers to satisfy the constraints of object-oriented ideology. The future-proofing they purportedly provide is an illusion. If you provide “JavaBean” style types, or types with properties, over an abstraction boundary, you are in practice just as locked in as if you’d provided raw field access – the changes you are most likely to want to make to those structures would not allow shifting the getters and setters to maintain compatibility. Leveraging this future-proofing is likely to be completely impossible for the changes you’d want to make, and at best it would involve a horrendous hack.

Rust might seem to be the same as OOP languages in all of this; it superficially looks like it has something very similar to classes. You can define functions associated with a given type – and they are even called methods! Like OOP methods, they syntactically privilege taking values of that type (or references to those values) as the first argument, called the special name self. You even mark fields of a record type (called struct in Rust) as public or (by default) private, encouraging private fields just like in an object-oriented programming language.

According to this pillar, Rust seems pretty close to being OOP. And that’s a fair assessment, for this pillar, and an intentional choice to make Rust programming more comfortable to people used to the everyday syntax of OOP programming in C++ (or Java, or JavaScript).

But the similarity is only skin-deep. Encapsulation is the least distinct pillar of OOP (after all, all modern programming languages have some form of it), and the implementation in Rust is not bound with the type. When you declare a field private in Rust (by not specifying pub), that doesn’t mean private to its methods, that means private to the module. A module can provide multiple types, and any function in that module, whether a “method” of that type or not, can access all of the fields defined in that type. Passing around records is encouraged when appropriate, rather than discouraged to the point that accessors are forced instead, even in tightly-bound related code.

This is the first sign we see that Rust, in spite of its superficial syntax, is not an OOP programming language.

### Future Posts
And at this point I’m going to have to pause for today.

Of course, encapsulation isn’t the only fancy thing OOP-style classes can do. If it were, classes wouldn’t have enamored so many people: it would simply be obvious to everyone that classes were nothing more than glorified modules, and methods nothing more than glorified procedures.

In the next posts of this series, we will discuss the other features associated with OOP, the two remaining traditional pillars of OOP, polymorphism and inheritance, analyze them from a practical point of view, and see how Rust compares with OOP as it comes to those pillars.

Next up will be polymorphism!


## logging

- 230220 ZQ re-start
- 230215 ZQ init.


