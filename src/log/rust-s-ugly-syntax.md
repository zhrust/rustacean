# Rust 丑句法
原文: [Rust's Ugly Syntax](https://matklad.github.io/2023/01/26/rusts-ugly-syntax.html#Rust-s-Ugly-Syntax)


## 快译

大家抱怨 Rust 的语法;
不过,俺想大多数时候,
当人们认为在对 Rust 语法有疑问时,
实际上在反抗对应语义;
在这篇有点儿异想天开的文章中,
俺将尝试理清这两点;

先从一个丑陋的语法示例开始:


```rust
pub fn read<P: AsRef<Path>>(path: P) -> io::Result<Vec<u8>> {
  fn inner(path: &Path) -> io::Result<Vec<u8>> {
    let mut file = File::open(path)?;
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes)?;
    Ok(bytes)
  }
  inner(path.as_ref())
}
```

此函数读取给定二进制文件内容;
这是直接从标准库中提取的, 所以, 不算是稻草人式无用示例;
而且,至少对俺来说, 这绝对不算漂亮;

让我们想象一下,如果 Rust 有更好的语法, 这个函数应该是什么样儿;
如果和真正的编程语言有任何相似之处, 无论真假, 纯属试合!

从 Rs++ 开始:

```c++
template<std::HasConstReference<std::Path> P>
std::io::outcome<std::vector<uint8_t>>
std::read(P path) {
    return read_(path.as_reference());
}

static
std::io::outcome<std::vector<uint8_t>>
read_(&auto const std::Path path) {
    auto file = try std::File::open(path);
    std::vector bytes;
    try file.read_to_end(&bytes);
    return okey(bytes);
}
```

Rhodes 变体:

```ruby
public io.Result<ArrayList<Byte>> read<P extends ReferencingFinal<Path>>(
        P path) {
    return myRead(path.get_final_reference());
}

private io.Result<ArrayList<Byte>> myRead(
        final reference lifetime var Path path) {
    var file = try File.open(path);
    ArrayList<Byte> bytes = ArrayList.new();
    try file.readToEnd(borrow bytes);
    return Success(bytes);
}
```

经典 RhodesScript:

```js
public function read<P extends IncludingRef<Path>>(
    path: P,
): io.Result<Array<byte>> {
    return myRead(path.included_ref());
}

private function myRead(
    path: &const Path,
): io.Result<Array<byte>> {
    let file = try File.open(path);
    Array<byte> bytes = Array.new()
    try file.readToEnd(&bytes)
    return Ok(bytes);
}
```

响尾蛇/Rattlesnake:

```python
def read[P: Refing[Path]](path: P): io.Result[List[byte]]:
    def inner(path: @Path): io.Result[List[byte]]:
        file := try File.open(path)
        bytes := List.new()
        try file.read_to_end(@: bytes)
        return Ok(bytes)
    return inner(path.ref)
```

以及, CrabML:

```rust
read :: 'p  ref_of => 'p -> u8 vec io.either.t
let read p =
  let
    inner :: &path -> u8 vec.t io.either.t
    inner p =
      let mut file = try (File.open p) in
      let mut bytes = vec.new () in
      try (file.read_to_end (&mut bytes)); Right bytes
  in
    ref_op p |> inner
;;
```

作为一个稍微严肃和有用的练习,
让我们作相反的尝试--保留 Rust 语法,
但是, 尝试简化语义直到最终结果, 看会是什么样儿;

这是我们的起点:


```rust
pub fn read<P: AsRef<Path>>(path: P) -> io::Result<Vec<u8>> {
  fn inner(path: &Path) -> io::Result<Vec<u8>> {
    let mut file = File::open(path)?;
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes)?;
    Ok(bytes)
  }
  inner(path.as_ref())
}
```

这时, 最大的噪音源是嵌套函数;
动机有点儿深奥;
外部函数是通用的,而内部不是;
使用编译模式,这意味着外部函数和用户代码一起编译,
而嵌的将优化;
相比之下, 内部函数是在编译 std 本身时编译的,
从而节省了编译用户代码的时间;
简化这一点(损失一些性能)的一种方法,
说是泛型函数总是单独编译,
但是,能在幕后接受一个额外的运行时秋粮, 可以描述物理维度上的输入参数;

这样我们获得:

```rust
pub fn read<P: AsRef<Path>>(path: P) -> io::Result<Vec<u8>> {
  let mut file = File::open(path.as_ref())?;
  let mut bytes = Vec::new();
  file.read_to_end(&mut bytes)?;
  Ok(bytes)
}
```

下个噪音元素是 `<P: AsRef<Path>>` 约束;
这是必需的,因为 Rust 喜欢将内存中字节的物理布局作为接口公开,
特别是对可以带来性能的情况;
特殊的, Path 的含义并不是文件路径的某种抽象,
这里只是字面意义上内存中的一堆连续字节;
所以, 我们需要 AsRef 来将其和任何能够表示这种字节片的抽象一起工作;
但是, 如果我们不关心性能,
就可以要求所有接口都相当抽象,并通过虚函数调用进行调解,
而不是直接访问内存;
那么, 我们就不需要 AsRef 这堆东西了:


```rust
pub fn read(path: &Path) -> io::Result<Vec<u8>> {
  let mut file = File::open(path)?;
  let mut bytes = Vec::new();
  file.read_to_end(&mut bytes)?;
  Ok(bytes)
}
```

这样简化后,我们实际上也可以摆脱 `Vec<u8>` -- 如果我们不再使用泛型来表达语言本身的高效可增长字节数组;
我们必须使用运行时提供的一些不透明字节类型:


```rust
pub fn read(path: &Path) -> io::Result<Bytes> {
  let mut file = File::open(path)?;
  let mut bytes = Bytes::new();
  file.read_to_end(&mut bytes)?;
  Ok(bytes)
}
```

从技术上讲,我们仍然随身携带所有权和备用系统,
但是,由于无法直接控制类型的内存布局,
就无法带来巨大的性能优势;
仍然有助于避免 GC,防止迭代器失效,
并静态检验非线程安全代码是否实际上没有跨线程使用;
不过, 如果我们只切换到 GC, 我们可以轻松摆脱那些 &指针;
我们甚至于不需要太担心并发性--因为,我们的对象是单独分配的,而且总是在指针后面,
我们可以通过注意到指针大小,
无论是否在 x86 系统上都是原子操作来消除数据竞争;

```rust
pub fn read(path: Path) -> io::Result<Bytes> {
  let file = File::open(path)?;
  let bytes = Bytes::new();
  file.read_to_end(bytes)?;
  Ok(bytes)
}
```

最后,我们在这对错误的处理过于迂腐 -- 我们并仅要关注返回类型失败的可能,
甚至于要用 ? 来突出指示任何可能失败的特定表达式;
完全不考虑错误处理,
让一些顶层处理程序来处理:
(比如: try { } catch (...) { /* intentionally empty */ })



```rust
pub fn read(path: Path) -> Bytes {
  let file = File::open(path);
  let bytes = Bytes::new();
  file.read_to_end(bytes);
  bytes
}
```

现在是否好多了?

## PS:

的确是篇奇想, 这样简化后, 几乎就是 多了一些控制符号的 Python 了,
又或是根本可以视为 TypeScript 了;
当然, 如果有这种低效版 Rust 多数程序员还是愿意使用的;
就象当年 CoffeeScript 的尝试;


## logging
> 版本记要

- ..
- 230206 ZQ init.


```
       _~^*`~_
   \) /  > #  \ (/
     '_   ⏝   _'
     | '-----' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```


