# idiom#6+7 迭代列表

[Initialize a new map (associative array)](https://en.wikipedia.org/wiki/Associative_array)


## Python

```python
x = {"one" : 1, "two" : 2}

```


## Rust
```rust
use std::collections::HashMap;

let x: HashMap<&str, i32> = [
    ("one", 1),
    ("two", 2),
].into_iter().collect();


use std::collections::BTreeMap;

let mut x = BTreeMap::new();
x.insert("one", 1);
x.insert("two", 2);


```

## Elixir

```elixir
x = %{"one" => 1, "two" => 2}

x = %{one: 1, two: 2}

```


## Humm?

和 Python 基本相似;
不过, Rust 明显有更多内建模块支持各种姿势的嗯哼...


- [HashMap in std::collections - Rust](https://doc.rust-lang.org/std/collections/struct.HashMap.html)
- [BTreeMap in std::collections - Rust](https://doc.rust-lang.org/std/collections/struct.BTreeMap.html#examples-2)
- ...






```
          _~∽~∽~_
      \/ /  = ◴  \ \/
        '_   ⎵   _'
        ( '-----' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```
