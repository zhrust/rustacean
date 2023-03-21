# 克服 "& 驱动开发"
原文: [Getting Past “Ampersand-Driven Development” in Rust - Blog](https://fiberplane.com/blog/getting-past-ampersand-driven-development-in-rust)

## background

[RR23W10 - 锈周刊 -> Weekly :: China<Rustaceans>](https://weekly.rs.101.so/abt/index.html) 中发现好文,
译来细读....

## 快译
> A little mental model for ownership and borrowing

所有权和借用的小小心智模型.

我是在一次 [Tad Lispy](https://www.youtube.com/watch?v=lsnksAMpUvM)
的演讲中听到 "& 符号驱动开发"这词儿的,
非常精确的捕捉到了很多 Rust 新人开发时,
下意识的随机插入 & 符号来安抚编译的行为.

此文, 描述了我想向 Rust 新手解释的一个心智模型，
涉及 &,&mut,所有权, Rcs 和 Arcs 之间的区别;
我希望你或是其它有抱负的 Rustacean 们对此感觉有用.

### 引用 (&variable)

让我们从 & 符号开始,
真是个可怕的符号;
在 Rust 中随处可见 --- 如果你首次尝试编写一些 Rust 代码,
可能不到 10 分钟,
Rust 编译器就会烦人的或是有用的告诉你,
在哪儿需要放置一个 &;

想象一下,我们有个计算字符串长度的简单函数;
此函数需要查阅字符串;
但是, 需要所有权进行修改嘛?不;
当长度函数完成时,我们应该从内存中删除字符串嘛? 也不需要;
这意味着长度函数嘦读取访问权,
只是要字符串的临时视图而不是永久版本;

这就是 &变量 符号在 Rust 中的含义;
想想一个小孩子将最喜欢的玩具借给另外一个孩子时说:
"你可以看, 但是, 不能摸; 当你看完后, 我想立即拿回来;"
这就是共享引用;

![Midjourney](https://framerusercontent.com/images/5LwiCYhw088dpelWzFCkp9MWSo.png)


> 图片由 Evan Schwartz 使用 Midjourney 创作


### 可变引 (&mut variable)

那么 &mut 变量又是怎么回事儿?

让我们想象一下在给定字符串前追加 "hello" 的函数,
而不是我们的字符串长度函数;
在这种情况中,
我们硬骨头希望函数修改给进来的数据;
这时,我们就需要 &mut 或说 可变引用;

想想我们的小孩子借一本涂色书给朋友,
让他在一页上色,说:"你可以看以及摸---但是,
当你完成后, 我仍然想要回来";


![Evan Schwartz](https://framerusercontent.com/images/0Y2RBZro7ESbqJzViLGIqfvccY.png)

> 图片由 Evan Schwartz 使用 Midjourney 创作


#### 可变引用是独占的

这里解释关于 Rust 微妙又非常聪明的设计最好的场景之一;

如果某人(或是你的代码的某部分)有一个对某个值的可变袭用,
Rust 编译器会确保绝对没有其它人可以再次引用;
为什么?
因为, 如果你正在查看某个你认为不可变的值,
当然不会在你使用其过程中又和维其它人意外的变更这个对象
(对于我们上面提及的字符串长度函数,
你就知道如果允许, 那得多令人困惑?)

另外一层含义是,
如果任何人对一个值有一个不可变袭用,
我们就不能更改它, 又或是给出另外一个可变引用;


### 值的拥有 (variable)

接下来,我们将讨论 值的拥有;

Rust 的另外一个聪明之处,
在于如何确定何时应该忘记或是从内存中删除一个值;
每当函数完成后, 其中声明的所有值都将被删除或是自动清除;

好吧, 这并不是真的;
如果我们再次考虑字符串长度函数,
就知道, 我们并不希望字符串在长度函数完成时就被完全遗忘/删除;
和追加 hello 函数相同;
在这些情况中, 只会清除对该值的引用,
但是,不会删除实际值;

那么, 将我们向 HashMap 中插入一些东西时又如何?
在这种场景中,
我们希望给定的字符串输入成为 HashMap 的一部分;
希望该值现在由 HashMap 拥有;

想象一个小孩赠送他们的玩具之一时说:
"给, 你可以拿来作任何你想作的事儿,我不需要拿回来了,
享受吧!"
(即便是想象中的孩子, 也需要相当成熟成千可能令此场景可信哪...)


### 引用计数指针 (Rc 和 Arc)

我们在 Rust 中还有另外两种值类型是 Rc 和 Arc;

对于 Rc, 想象孩子生日派对上的装饰品,
例如气球;
当所有人都取信在那里时,
我们希望每个人都看着, 但是不要触摸装饰品;
我们希望装饰品一直保持到最后一个孩子离开时;
但是, 嘦最后一个熊孩子离开,
我们就可以立即开始清理装饰品;
这就是一个 Rc 或是引用计数指针;

Rc 跟踪有多少人(或是代码的一部分)
正在查看, 并保持该值, 直到最后一个引用被删除的那一刻;

如果你正在使用异步或是多线程代码,
你将使用 Arc 或是原子引用计数指针,
但是, 和 Rc 的想法相同;

效果也是: 大家看看装饰品,
晚会一结束我们就收拾干净;

### 结论
作为最后的总结,
你可以根据以下问题, 来决策应该使用那种类型的值:

![Conclusion](https://framerusercontent.com/images/mH73ms5JxUOiNWhWMA8UKtAX7Y.jpg)



|                  |    &var\n(不可变引)     | &mut var\n(可变引用) |               var\n(拥有值)                |             Rc             |                          |
| \n(引用计数指针) | Arc\n(原子引用计数指针) |                      |                                            |                            |                          |
| ---------------- | ----------------------- | -------------------- | ------------------------------------------ | -------------------------- | ------------------------ |
| 可读?            | ✔︎                      | ✔︎                   | ✔︎                                         | ✔︎                         | ✔︎                       |
| 可写?            | ✘                       | ✔︎                   | ✔︎                                         | 仅当包装为 Cell/RefCell    | O仅当包装为 Mutex/RwLock |
| 函数结束时丢弃?  | ✘                       | ✘                    | ✔︎                                         | 仅在 Rc 最后的克隆被丢弃后 | 仅当 Arc 的克隆被丢弃后  |
| 多线程可用?      | ✘ 注1                   | ✘                    | 值可以在线程间移动\n但不同线程不可同时访问 | ✘                          | ✔︎                       |



> 注1: (除非有一个 'static 生命周期, 这意味着在所有线程中存在,或是在线程作用域中使用)


在从 Typescript 等高级语言转到 Rust 时,
& 符号是最可怕或是最不熟悉的部分之一;
但是, 能保证的是, 经过一些练习, 在编写代码时,
知道一个函数应该采用可变引用还是不可变引用,
又或是知道其它库的函数是否可能需要引用或是拥有值,
感觉会更加直观;
也就无需 `"& 驱动开发"` 了;

有关详情, 值得查阅 Rust 语言文档:
[References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)
以及:
 [What is Ownership?](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html)
 
还有 [Evan Schwartz](https://github.com/emschwartz)
是 Fiberplane 的首席 Rust 工程师;
也是 [Autometrics](https://github.com/autometrics-dev/autometrics-rs)
的创造者,
一个全新的 crate, 
可以让你轻松了解代码中任何函数的错误率/延迟和生产使用情况.

## refer.

... TBD



```
          _~`+∽~_
      \/ /  = ◶  \ (/
        '_   𝟂   _'
        | '-----' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```
