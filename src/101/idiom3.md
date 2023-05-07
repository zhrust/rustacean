# idiom#3 构造程序

[Create a procedure](https://programming-idioms.org/idiom/3/create-a-procedure)


## Python

```python

def finish(name):
    print(f'My job here is done. Goodbye {name}')

```


## Rust
```rust

fn finish(name: &str) {
    println!("My job here is done. Goodbye {}", name);
}

```

## Humm?

和 Python 基本相似复杂度;
就是多出类型相关的声明,
不过, Python 要上了类型注解就更加像了...


- [Functions - The Rust Programming Language](https://doc.rust-lang.org/book/ch03-03-how-functions-work.html)
- ...





```
       _~^+-~_
   () /  ← #  \ ()
     '_   ⩌   _'
     ( '-----' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```