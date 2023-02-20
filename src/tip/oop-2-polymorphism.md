# Rust 超越面向对象,第2部分
原文:[Rust Is Beyond Object-Oriented, Part 2: Polymorphism :: The Coded Message](https://www.thecodedmessage.com/posts/oop-2-polymorphism/)


## 快译

在这篇文章中, 通过讨论 OOP 三大传统支柱中的第二个: 多态,
继续系列文章:关于 Rust 和传统 OOP 范式的不同;

In this post, I continue my series on how Rust differs from the traditional object-oriented programming paradigm by discussing the second of the three traditional pillars of OOP: polymorphism.

Polymorphism is an especially big topic in object-oriented programming, perhaps the most important of its three pillars. Several books could be (and have been) written on what polymorphism is, how various programming languages have implemented it (both within the OOP world and outside of it – yes, polymorphism exists outside of OOP), how to use it effectively, and when not to use it. Books could be written on how to use the Rust version of it alone.

Unfortunately this is just a blog post, so I cannot cover polymorphism in as much detail or variety as I want to. I shall instead focus specifically on how Rust differs from the OOP conceptualization. I will start by describing how it works in OOP, and then discuss how to accomplish the same goals in Rust.

In OOP, polymorphism is everything. It tries to take all decision-making (or as much decision-making as possible) and unite it in a common narrow mechanism: run-time polymorphism. But unfortunately, it’s not just any run-time polymorphism, but a specific, narrow form of run-time polymorphism, constrained by OOP philosophy and by details of how the implementations typically work:

- It requires indirection: Every object must typically be stored on the heap for run-time polymorphism to work, as the different “run-time types” have different sizes. This encourages the aliasing of mutable objects. Not only that, but to actually call a method, it must go through three layers of indirection: dereferencing the object reference, then dereferencing the class pointer or “vtable” pointer, and then doing an indirect function call.
- It precludes optimization: Beyond the intrinsic cost of an indirect function call, the fact that the call is indirect means that inlining is impossible. Often, the polymorphic methods are small or even trivial, such as returning a constant, setting a field, or re-arranging the parameters and calling another method, so inlining would be useful. Inlining is also important to allow optimizations to cross the inlining boundary.
- It is polymorphic in one parameter only: The special receiver parameter, called self or this, is the only parameter through which run-time polymorphism is typically possible. Polymorphism on other parameters can be simulated with helper methods in those types, which is awkward, and return-type polymorphism is impossible.
- Each value is independently polymorphic: In run-time polymorphism, there is often no way to say that all the elements of a collection are of some type T that all implement the same interface, or to say that two parameters to a function are the same type but what that type is should be determined at run-time.
- It is entangled with other OOP features: In C++, runtime polymorphism is tightly coupled with inheritance. In many OOP programming languages, it is only available for class types, which as I discussed in my previous post are a constrained form of modules.


I could write an entire blog post about each of these constraints – perhaps I will someday.

But in spite of all these constraints, it is seen as the preferred way of doing decision-making in OOP languages, and as especially intuitive and accesible. Programmers are trained to reach for this tool whenever feasible, whether or not it is the best tool for the decision at hand, even if there is no current need for it to be a run-time decision. Some programming languages, such as Smalltalk, even collapsed “if-then” logic and loops into this one oddly specific decision-making structure, implementing them via polymorphic methods like ifTrue:ifFalse that would be implemented differently in the True and False classes (and therefore on the true and false objects).

To be clear, having a mechanism of vtable-based runtime polymorphism isn’t a bad thing per se – Rust even has one (similar, but not quite identical, to the OOP version described above). But the Rust version is used in the relatively rare situations where that mechanism is the best fit, among a whole palette of mechanisms. In OOP, the elevation of this tightly constrained and unperformant form of decision making above all others, and the philosophical assertion that using it is the best way and most intuitive way to express program flow and business logic, is a problem.

It turns out that programming is much more ergonomic when you choose the tool most appropriate for the situation at hand – and OOP run-time polymorphism is only occasionally the actual tool for the jobs it is often asked to do.

So let’s look at 4 alternatives in Rust that can be used when OOP uses run-time polymorphism.

### Alternative #0: enum

Not only are there other forms of polymorphism that have strictly fewer constraints (such as Haskell’s typeclasses) or a different set of trade-offs (such as Rust’s traits, heavily based on Haskell typeclasses), there is another decision-making systems in Rust and Haskell, namely algebraic data types (ADTs), or sum types, that also take over many of the applications of OOP-style polymorphism.

In Rust, these are known as enums. enums in many programming language are lists of constants to be stored in integer-sized types, sometimes implemented in a typesafe fashion (like in Java), sometimes not (like in C), sometimes with either option available (like in C++ with the distinction between enum and enum class).

Rust enums support this familiar use case, with type-safety:

```rust
pub enum Visibility {
    Visible,
    Invisible,
}
```

But they also support additional fields associated with each option, creating what in type theory is known as a “sum type,” but it is better known among C or C++ programmers as a “tagged union” – the difference being that in Rust, the compiler is aware of and enforces the tag. Here’s some examples of some enum declarations:

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

What do these tagged unions have to do with polymorphism, you may ask? Well, most OOP languages don’t have good syntax for these sum types, but they do have powerful mechanisms for run-time polymorphism, and so you’ll see run-time polymorphism used for situations where Rust enums would actually be just as well-suited (and I will argue, better suited): when there’s a few options for how to store a value, but those options contain different details.

For example, here’s one way to represent the UserId type in Java using inheritance and run-time polymorphism – how I would’ve done it when I was a student (putting each class in a different file):

```rust
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


Importantly, just as in the enum example, we can put user1 and user2 in variables of the same type, and can pass them to the same kinds of functions, and in general do the same operations on them.

Now, these OOP-style classes look super-light to the point of being silly, but that’s mostly because we haven’t added any real operational code to this situation – just data and structure and a bit of variable definitions and boilerplate. Let’s consider what happens if we actually do anything with user IDs.

For example, we might want to determine whether they’re an administrator. In our hypothetical, let’s say anonymous users are never administrators, and users with usernames are only administrators if the username begins with the string admin_.

The doctrinally approved object-oriented way of doing that is to add a method, e.g. isAdministrator. In order for this method to work, we have to add it to all three classes, the base class and the two child classes:

```rust
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

So, in order to add this simple operation, this simple capability to this type in Java, we have to go to three classes, which will be stored in three files. Each of them contains a method that does something simple, but nowhere can the entire logic be seen of who is and isn’t an administrator – something that someone might naturally ask.

Rust would use match for such an operation, putting all the information about it in one place:

```rust
fn is_administrator(user: &UserId) -> bool {
    match user {
        UserId::Username(name) => name.starts_with("admin_"),
        UserId::AnonymousUser(_) => false,
    }
}
```

This yields a more complicated individual function, but it has all the logic explicitly right there. Having the logic be explicit, instead of implicit in an inheritance hierarchy, cuts against an OOP precept where methods should be simple and polymorphism used to express the logic implicitly. But that doesn’t help guarantee anything, just sweeps it under the rug: It turns out that hiding the complexity makes it harder to grapple with, not easier.

Let’s go through another example. We’ve had this UserId code for a while, and you’re tasked with writing a new web front-end for this system. You need some way of displaying the user information in HTML, either a link to a user profile (in the case of a named user) or a stringification of the IP address in red (in the case of an anonymous user). So you decide to add a new operation for this small family of types, toHTML, which outputs your new front-end’s specialized DOM type. (Maybe the Java’s compiled to WebAssembly, I’m not sure. The details don’t matter.)

You submit a pull request to the maintainer of the UserId class hierarchy, deep in a core library of the backend. And then they reject it.

They have pretty good reasons, actually, you grudgingly admit. They’re saying it’s an absurd separation of concerns. Besides, the company can’t have this core library handling types from your front-end.

So, you sigh, and write the equivalent of a Rust match expression, but in Java (please pardon my absurd hypothetical HTML library):

```rust
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

And this code your boss rejects upon code review, saying you used the instanceof anti-pattern, but then later they grudgingly accept it after you make them argue with the maintainer of the core library that wouldn’t accept your other patch.

But look at how ugly that instanceof code is! No wonder Java programmers consider it an anti-pattern! But in this situation, it’s the most reasonable thing, really the only possible thing besides implementing the observer pattern or the visitor pattern or something else that just amounts to infrastructure to fake an instanceof with inversion of control.

Having operations implemented by adding a method to every subclass makes sense when the set of operations is bounded (or close to it) and the number of subclasses of the class might grow in unanticipated ways. But just as often, the number of operations will grow in unanticipated ways, while the number of subclasses is bounded (or close to it).

For the latter situation, which is more common than OOP advocates would imagine, Rust enums – and sum types in general – are perfect. Once you’ve gotten used to them, you find yourself using them all the time.

I will say for the record that it isn’t this bad in all object-oriented programming languages. In some, you can write arbitrary class-method combinations in any order, and so you could write all three implementations in one place if you so chose. Smalltalk traditionally lets you navigate the codebase in a special browser, where you can see either a list of methods implemented by a class, or a list of classes that accept a given “message,” as Smalltalk calls it, so you can have your cake and eat it too.

### Alternative #1: Closures
Sometimes, an OOP interface or polymorphic decision only involves one actual operation. In such a situation, a closure can just be used instead.

I don’t want to spend too much time on this, because most OOP programmers are already aware of this, and have been since their OOP languages have caught up with functional languages and gotten syntax for lambdas – Java in Java 8, C++ in C++11. Silly one-method interfaces like Java’s Comparator are therefore – fortunately – mostly a thing of the past.

Also, closures in Rust technically involve traits, and so are implemented using the same mechanism as the next two alternatives, so one could also argue that this isn’t really a separate option in Rust. In my mind, however, lambdas, closures, and the FnMut/FnOnce/Fn traits are special enough aesthetically and situationally that it deserved a little bit of time.

And so I’ll take the little bit of time to just say this: If you find yourself writing a trait (or a Java interface or a C++ class) with exactly one method, please consider whether you should instead be using some sort of closure or lambda type. Only you can prevent overengineering.

### Alternative #2: Polymorphism with Traits
Just like Rust has a version of encapsulation more flexible and more powerful than the OOP notion of classes, as I discuss in the previous post, Rust has a more powerful version of polymorphism than OOP posits: traits.

Traits are like interfaces from Java (or an all-abstract superclass in C++), but without most of the constraints that I discuss at the beginning of the blog post. They have neither the semantic constraints or the performance constraints. Traits are heavily inspired in semantics and principle by Haskell’s typeclasses, and in syntax and implementation by C++’s templates. C++ programmers can think of them as templates with concepts (except done right, baked into the programming language from the get-go, and without having to deal with all the code that doesn’t use it).

Let’s start with the semantics: What can you do with traits that you can’t do with pure OOP, even if you throw all the indirection in the world at it? Well, in pure OOP terms, there’s no way you can write an interface like Rust Eq and Ord, given greatly oversimplified definitions here (the real definitions of Eq and Ord extend other classes that allow partial equivalence and orderings between different types, but like these simplified definitions, the Rust standard library version of non-partial Eq and Ord do cover equivalence and ordering between values of the same type):

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

See what’s happening? Like in an OOP-style interface, the methods take a “receiver” type, a self parameter, of the Self type – that is, of whatever concrete type implements the trait (technically here a reference to Self or &Self). But unlike in an OOP-style interface, they also take another argument of &Self type. In order to implement Eq and Ord, a type T provides a function that takes two references to T. That’s meant literally: two references to T, not one reference to T and one reference to T or any subclass (such a thing doesn’t exist in Rust), not one reference to T and one reference to any other value that implements Eq, but two bona-fide non-heterogeneous references to the same concrete type, that the function can then compare for equality (or ordering).

This is important, because we want to use this to implement methods like sort:

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