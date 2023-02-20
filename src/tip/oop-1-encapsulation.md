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


### OOP Ideology
Look, I get it. I used to drink the OOP Kool-Aid myself. I remember how it was billed to us: not as just a set of code organization practices, but a revolution in programming. The OOP way was held up as more intuitive, especially to non-programmers, because it would align better with how we think of the natural world.

For an archetypical example of this marketing, here is an excerpt from the first public article about OOP in a popular magazine (Byte Magazine, in 1981):

------

> Many people who have no idea how a computer works find the idea of object-oriented programming quite natural. In contrast, many people who have experience with computers initially think there is something strange about object oriented systems.

------

It was pretty easy to buy into, as well. Of course, our everyday life doesn’t have anything like subroutines or variables – or, to the extent that it does, we don’t think about them explicitly! But it does have objects that we can interact with, each with its own capabilities. How could it not be more intuitive?

It’s very compelling pseudo-cognitive science, light on research, heavy on really persuasive rationales. The objects can be thought of as “agents,” almost as people, and so you could leverage your social skills towards it instead of just analytical thinking (never mind that objects act nothing like people, and actually substantially dumber in a way that still requires analytical thinking). Or, you can think of objects and classes as an almost-platonic representation of the world of forms itself, making it philosophically compelling.

And oh, how I bought in, especially in my wanton and reckless youth. I personally soaked up the connection between OOP and Platonic philosophy. I delved deep into meta-object protocols, and the fact that in Smalltalk every class had to have a metaclass. The concept of the Smalltalk code Metaclass class felt almost mystical to me, as the notion that any value could be organized in the same hierarchy, with Object at its root.

I remember reading in a book that OOP-style polymorphism made if-else statements redundant, and therefore we should strive to ultimately only use OOP-style polymorphism. Somehow, instead of putting me off, this excited me at the time. I was even more excited when I learned that Smalltalk in fact does this (if you ignored implementation details that optimize away some of this abstraction): In Smalltalk, the concept of if-then-else is implemented via methods like ifTrue: and ifFalse: and ifTrue:ifFalse: on the single-instance True and False classes, with their global objects, true and false.

As a more mature programmer, exposed to the less ideological OOP of C++ and the alternative of functional programming in Haskell, my positions softened, and then shifted dramatically, and now I am barely a fan of OOP at all, especially as its best ideas have been carried on to a newer synthesis in Haskell and Rust. I’ve realized that this hype about new programmers is typical for any paradigm; any new programming paradigm is more intuitive for a newbie than it is for someone who’s a veteran programmer in a different paradigm. The same thing is said for functional programming. The same thing is even said for Rust. It really doesn’t have that much to do with whether a paradigm is better.

As for if statements being fully replaceable by polymorphism, well, it’s easy to come up with a set of primitives that are Turing-complete. You can simulate if statements with polymorphism, true. You can also simulate while loops with recursion, or recursion with while loops and an explicit stack. You can simulate if statements with while loops.

None of these facts make such substitutions a good idea. Different features exist in a programming language for different situations, and making them distinct is actually a good thing, in moderation.

After all, the point of programming is to write programs, not to make proofs about Turing-completeness, do philosophy, or write conceptual poetry.

### Practicality
So, in this blog series, I intend to evaluate OOP in practical terms, as a programmer with experience in what makes programming languages cognitively more manageable or easy to do abstraction in. I will do it in terms of my experience solving actual programming problems – I see it as a bad sign that many examples of how OOP abstractions work only make sense in really advanced programs or with contrived examples about different types of shapes or animals in a zoo.

And unlike most introductions to OOP, I will not primarily be focusing on how OOP compares to pre-OOP programming languages. I will instead be comparing to Rust, which takes many of the good ideas from OOP, and perhaps also to functional programming languages like Haskell. These programming languages have taken some of OOP’s good ideas, but transformed them in a way that fixes some of their flaws and moves them beyond what can reasonably be called OOP.

I will organize this comparison according to the three traditional pillars of object-oriented programming: encapsulation, polymorphism, and inheritance, with this first article focusing on encapsulation. For each pillar, I will discuss how OOP defines it, what equivalents or substitutes exist outside of the OOP world, and how these compare for practical ease and power of programming.

But before I jump in, I want to talk a second about a use case that turns much of this on its head: graphical user interfaces or GUIs. Especially before the era of the browser, writing GUI programs to run directly on desktop (or laptop) computers was a huge part of what programmers did. A lot of early development of OOP was done in tandem with research into graphical user interfaces at Xerox PARC, and OOP is uniquely well-suited for that use case. For this reason, the GUI deserves special consideration.

For example, it is common for people to emulate OOP in other programming languages. Gtk+ is a huge example of this, implementing OOP as a series of macros and conventions in C. This is done for many reasons, including familiarity with OOP designs and a desire to create some kind of run-time polymorphism. But in my experience, this is most common when implementing a GUI framework.

In this series of articles, we will primarily focus on applying OOP to other use cases, but we will also discuss GUIs as appropriate. In this introductory section, I will just point out that GUI frameworks are clearly possible outside traditional OOP designs and programming languages, and even in Rust. Sometimes, they work by completely different mechanisms, like the functional-reactive programming mostly pioneered in Haskell, which I personally prefer to traditional OOP-based programming and for which traditional OOP features would not be helpful.

Now, without further ado, let us compare OOP to Rust and other post-OOP programming languages, pillar by pillar, from a pragmatic perspective. For the rest of this first post, we will focus on encapsulation.

### First Pillar: Encapsulation
In object-oriented programming, encapsulation is bound up with the idea of a class, the fundamental layer of abstraction in object-oriented programming. Each class contains a layout for some data in a record format, that is, a data structure where each instance contains a set number of fields. Individual instances of the record type are known as “objects.” Each class also contains code that is tightly paired to that record type, organized into procedures called methods. The idea is then that all of the fields will only be accessible from inside the methods, either by the conventions of OOP ideology or by the enforced rules of the programming language.

The fundamental benefit here is that the interface, which is how the code interacts with other code, or what you have to understand to use the code, is much simpler than the implementation, which are the more fluidly changing details of how the code actually accomplishes its job.

But of course, lots of programming languages have abstractions like this. Any program longer than a dozen lines has too many parts to keep in your brain all at once, and so all remotely modern programming languages have ways of dividing a program into smaller components, as a way to manage the complexity, so that the interface is simpler than the implementation, whether enforced by the programming language or a matter of the “honor system.” So in a broader sense of the word, all modern programming languages have some version of encapsulation.

One simple form of encapsulation – one that most object-oriented programming languages maintain as a layer within the class – is procedures, also known as functions, subroutines, or (as OOP calls them) methods. Rather than allow any line of code to jump to any other line of code, modern programming languages tend to group blocks of code together into procedures, and you can then change the contents of the procedure without affecting the outside code, and change the outside code without affecting the procedure, as long as they follow the same interface and contract.

The contract is usually at least partially a human-level convention. There’s not usually much stopping you from taking a procedure that is supposed to process some data and instead making it instead loop indefinitely or crash the program. But some of it, like the separation of the procedure from the rest of the program, and in many cases the number and types of values it is allowed to accept and return in an invocation, will be enforced by the programming language.

For example, variables declared inside the procedure are usually local, and there’s generally no way to reference them outside the procedure. The inputs and outputs are usually listed in a signature at the top of the procedure. Normally, outside code can only enter the procedure on its first line, rather than on an arbitrary line half-way through. In some programming languages – including Rust – procedures can even contain other procedures, which can only be called within the outer procedure.

But of course, modern programs are often more complicated than a mere handful of procedures. And so, modern programming languages (and again, the word “modern” here is being used in a very loose way) have another layer of encapsulated abstraction: modules.

Modules will generally contain a group of procedures, some externally accessible, and some not. And in non-duck typed languages, they will generally define a number of aggregate types, again some externally accessible, and some not. It is generally even possible to expose these types abstractly, so the existence of a type is accessible to the rest of the program, but not the record fields, or even the fact that it is a record type. Even C has this ability in its module system – C++ did not introduce it, just added an additional, orthogonal level of field-by-field access controls.

Seen from my pragmatic point of view, class-based encapsulation is not some special insight of OOP, but a specialized – or rather, tightly restricted – form of module. In an OOP programming language, we have this notion of a class, which is a special form of module (sometimes the only supported form, or sometimes even layered underneath a completely different, more traditional notion of module, for extra confusion). It’s just that, for a “class,” there can only generally be one primary type defined, which shares a name with the module itself, and where the fields of that type are given special protection against access by code outside the class.

Of course, there are other differences between a class and a module, but these have to do with the other pillars, and we will get to them later. For right now, we will just discuss the idea of a “class” as it relates to encapsulation – where a class is just a special module with one privileged, abstracted type.

And this is a reasonable way to write a module, but it’s not as special as object-oriented programming makes it out to be (especially once we discuss alternative approaches to the other pillars, but again, more later). There are some situations where a module doesn’t have any record type that it defines, which is awkward in programming languages like Java, where you have to define an empty record type anyway and still make a “class.” There are also situations in which a module defines multiple publically accessible types that are tightly entangled – and where the encapsulation between those types that OOP style would encourage you to do is more of a hinderance than a help.

Fundamentally, being able to hide the fields of a record from other modules is important, which is why even C supports it. It is even essential for implementing safe abstractions over unsafe features in Rust, such as for collections, where raw pointers have invariants in combination with other fields in the same record. But it is not new to OOP, and it is simply not the best choice for every possible type.

As evidence of this, in Java and Smalltalk, and to a lesser extent even in C++ or Python, the insistence on a one-type-per-class style of encapsulation means that you get these boilerplate methods like setFoo and getFoo. These methods do nothing but serve as field accessors for something that is fundamentally a dumb record type. In theory, this helps you if you want to change what happens when these fields are set or read, but in practice, the fact that they are raw field accessors is part of the contract. If they, for example, instead made a network call rather than just returning a value, that would strongly value the principle of surprise for such simply named methods.

It is far simpler to say:

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


