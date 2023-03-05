# 图形描述 Rust 中所有权和借用
原文: [Graphical depiction of ownership and borrowing in Rust - Rufflewind's Scratchpad](https://rufflewind.com/2017-02-15/rust-move-copy-borrow)

## 快译:

以下是 Rust 语言中 moving, copying, 和 borrowing 的图形描述;
这些概念中的大多数是 Rust 持有的,
因此, 也是很多学习者常见绊脚石;

为了避免图形混乱, 尽量减少了文字;
并不是要取代现有各种教程, 而是为喜欢直观理解概念的程序员提供不同的视角;
如果你正在学习 Rust 并发现这些图形有报时,
建议你使用这类图表注释自己的代码以便帮助巩固概念 ;-)

## Rust 中所有权和借用

![](https://rufflewind.com/img/rust-move-copy-borrow.png)

可以通过点击图像来放大, 也可以下载 [SVG](https://rufflewind.com/img/rust-move-copy-borrow.svg)
和 [PDF](https://rufflewind.com/img/rust-move-copy-borrow.pdf) 版本在本地放大;

上面的图形描述了你拥有数据的两种主要语义: 移动或是复制;

关于移动的解释(~>)看起来太简单了;
这里没有把戏: 移动语义本身就很奇怪,因为,大多数语言允许变量被程序员随意使用多次;
这和现实世界的大部分情况形成鲜明对比:
我不能把我的笔给别人,然后,仍然用它继续写字!
在 Rust 中,任何类型未实现 Copy trait 的变量都具有移动语义,
并且会像所示那样运行;

复制语义(⎘)是为实现 Copy trait 的类型保留的;
在这种情况中, 对象的每次使用都会产生一个副本, 正如所示分叉; 中间的两个数字描绘了你可以借用你拥有物品的两种方式,
以及每种方式提供的操作;

对于可变借用, 我使用了锁符号(🔒)来表示原始对象在借用期间被有效锁定,
令其无法使用;

相反,对于非可变备用, 我使用了雪花符号(❄)来表示原始对象只是被冻结了:
你仍然可以获取更多非可变引用, 但是, 你不能移动或是获取其可变引用;

在这两个图中, `'ρ` 是我为引用的生命周期选择的名称;
我故意使用希腊字母是因为目前 Rust 中还没有具体生命周期的语法;

最后两个图以图形和文本形式总结了两种引用之间的主要区别和相似之处;
在这种场景中"外部([exteriorly](https://doc.rust-lang.org/beta/book/mutability.html#interior-vs-exterior-mutability))"限定词很重要,
因为, 你仍然可以通过类似 [Cell](https://doc.rust-lang.org/std/cell/) 的东西拥有内部可变性;



## logging
> 版本记要

- ..
- 230220 ZQ init.




```
      _~-|`~_
  () /  * *  \ ()
    '_   ⎕   _'
    | '--∽--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```
