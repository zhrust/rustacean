# idiom#6+7 迭代列表

- [Iterate over list values](https://programming-idioms.org/idiom/6/iterate-over-list-values)
- [Iterate over list indexes and values](https://programming-idioms.org/idiom/7/iterate-over-list-indexes-and-values)

## Python

```python
[do_something(x) for x in items]

for x in items:
        doSomething( x )

for i, x in enumerate(items):
    print i, x

```


## Rust
```rust

items.into_iter().for_each(|x| do_something(x));

for x in items {
	do_something(x);
}

for (i, x) in items.iter().enumerate() {
    println!("Item {} = {}", i, x);
}

items.iter().enumerate().for_each(|(i, x)| {
    println!("Item {} = {}", i, x);
})

```



## Humm?

和 Python 基本相似;
不过, Rust 明显有更多内建函数支持各种姿势的嗯哼...


- [Iterator in std::iter - Rust](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.enumerate)
- ...






```
          _~∽~∽~_
      \/ /  = ◴  \ \/
        '_   ⎵   _'
        ( '-----' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```
