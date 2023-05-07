# idiom#5 平面一点

[Create a 2D Point data structure](https://programming-idioms.org/idiom/5/create-a-2d-point-data-structure#)

## Python

```python

@dataclass
class Point:
    x: float
    y: float

Point = namedtuple("Point", "x y")
```


## Rust
```rust

struct Point {
    x: f64,
    y: f64,
}

struct Point(f64, f64);
```


## Elixir

```elixir
p = [ x: 1.122, y: 7.45 ]

```

## Humm?

和 Python 基本相似;



- [Functions - The Rust Programming Language](https://doc.rust-lang.org/book/ch03-03-how-functions-work.html)
- ...





```
      _~∽-∽~_
  () /  ☉ #  \ \/
    '_   V   _'
    | '--.--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```


