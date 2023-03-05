# idiom#325:构造队列
SEE: [Create a queue, in Rust](https://programming-idioms.org/idiom/325/create-a-queue/6291/rust)

## Python

```python
import queue

q = queue.Queue()
q.put(x)
q.put(y)
z = q.get()
```


## Rust
```rust
use std::collections::VecDeque;

fn main() {
    let mut q = VecDeque::new();
    q.push_back("zoom");
    q.push_back("quiet");
    let z = q.pop_front(); 
    println!("1st item ~> {}",z.unwrap());
}
```

## Humm?

- 内置模块
- 函数名/流程/...基本一致
- ..记住就好




```
          _~-+^~_
      \) /  + =  \ \/
        '_   △   _'
        ( '--∽--' <

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```
