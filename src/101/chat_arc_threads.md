# 使用Arc 在多线程中共享数据
> 学伴ChatGPT, chatting for debugging ...

## background
> rustlings 第78题:

smart_pointers/arc1.rs

```rust
#![forbid(unused_imports)] // Do not change this, (or the next) line.
use std::sync::Arc;
use std::thread;

fn main() {
    let numbers: Vec<_> = (0..100u32).collect();
    let shared_numbers = // TODO
    let mut joinhandles = Vec::new();

    for offset in 0..8 {
        let child_numbers = // TODO
        joinhandles.push(thread::spawn(move || {
            let sum: u32 = child_numbers.iter().filter(|n| *n % 8 == offset).sum();
            println!("Sum of offset {} is {}", offset, sum);
        }));
    }
    for handle in joinhandles.into_iter() {
        handle.join().unwrap();
    }
}

```

## goal

完成合理概念摸查...

## trace

> Q: 以上代码如何补全?

> A: 这段 Rust 代码中需要补全的是 shared_numbers 和 child_numbers 变量的定义，使得代码可以正确地计算每个偏移量下的数字和。可以通过使用 Arc 类型来创建共享数据并在每个线程之间共享它。

以下是一个可能的解决方案：

```rust
#![forbid(unused_imports)]
use std::sync::Arc;
use std::thread;

fn main() {
    let numbers: Vec<_> = (0..100u32).collect();
    let shared_numbers = Arc::new(numbers); // create shared data
    let mut joinhandles = Vec::new();

    for offset in 0..8 {
        let child_numbers = Arc::clone(&shared_numbers); // clone shared data for each thread
        joinhandles.push(thread::spawn(move || {
            let sum: u32 = child_numbers.iter().filter(|n| *n % 8 == offset).sum();
            println!("Sum of offset {} is {}", offset, sum);
        }));
    }
    for handle in joinhandles.into_iter() {
        handle.join().unwrap();
    }
}
```

在这个解决方案中，我们使用 Arc::new 函数来创建共享数据，然后使用 Arc::clone 函数来为每个线程创建一个共享数据的克隆。在线程内部，我们使用了 child_numbers 变量来访问共享数据，然后通过过滤器和求和来计算每个偏移量下的数字和。最后，我们使用 handle.join() 函数来等待每个线程完成，并使用 unwrap() 函数来处理可能的错误。

> Q: 不是说 clone 将消耗大量资源嘛? 这里有其它方案嘛? 不使用 clone 的话

> A: 是的，每次克隆 Arc 都会增加引用计数，这可能会导致性能问题。为了避免这种情况，我们可以考虑将数据划分成固定大小的块，并将每个块分配给不同的线程。这样可以避免克隆 Arc，同时保持数据的共享。

以下是一种可能的解决方案：

```rust
#![forbid(unused_imports)]
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let numbers: Vec<_> = (0..100u32).collect();
    let chunk_size = numbers.len() / 8;
    let shared_numbers = Arc::new(Mutex::new(numbers)); // create shared data
    let mut joinhandles = Vec::new();

    for offset in 0..8 {
        let start = offset * chunk_size;
        let end = start + chunk_size;
        let child_numbers = Arc::clone(&shared_numbers); // share the same Arc between threads
        joinhandles.push(thread::spawn(move || {
            let chunk = &child_numbers.lock().unwrap()[start..end]; // acquire lock and get the chunk
            let sum: u32 = chunk.iter().filter(|n| *n % 8 == offset).sum(); // compute the sum
            println!("Sum of offset {} is {}", offset, sum);
        }));
    }

    for handle in joinhandles.into_iter() {
        handle.join().unwrap();
    }
}

```

在这个解决方案中，我们首先计算每个块的大小，并使用 Arc::new(Mutex::new(numbers)) 来创建一个包装了 Vec 的 Mutex，以实现共享和线程安全。然后，我们使用 Arc::clone 来为每个线程分配同一个 Arc。在每个线程中，我们使用 lock() 函数获取锁来访问共享数据，并使用切片 &[T] 获取每个线程的块。接下来，我们可以像之前那样计算每个偏移量下的数字和，然后在完成后释放锁。

需要注意的是，Mutex 的使用可能会对性能产生一定的影响。如果共享数据不需要写入，那么可以使用 RwLock 来进行读取操作，因为它可以允许多个线程同时读取数据。

> Q: 不错, 看起来可以运行, 还有其它方案嘛?


> A: 是的，还有一种使用通道（Channel）的解决方案，它可以避免使用共享数据结构和锁，同时保持并发性。在这个方案中，我们将数据划分成固定大小的块，并将每个块发送到一个通道中，然后让每个线程从通道中接收自己的块，并计算每个偏移量下的数字和。

以下是一种可能的解决方案：

```rust
#![forbid(unused_imports)]
use std::sync::mpsc;
use std::thread;

fn main() {
    let numbers: Vec<_> = (0..100u32).collect();
    let chunk_size = numbers.len() / 8;
    let (tx, rx) = mpsc::channel(); // create a channel
    let mut joinhandles = Vec::new();

    for offset in 0..8 {
        let start = offset * chunk_size;
        let end = start + chunk_size;
        let child_tx = tx.clone(); // clone the channel sender
        let chunk = &numbers[start..end].to_vec(); // create a new vector with a chunk of the data
        joinhandles.push(thread::spawn(move || {
            let sum: u32 = chunk.iter().filter(|n| *n % 8 == offset).sum(); // compute the sum
            child_tx.send(sum).unwrap(); // send the sum back to the main thread
        }));
    }

    drop(tx); // close the sender channel to signal the end of the transmission
    let total_sum: u32 = rx.iter().sum(); // receive the sums and compute the total sum
    println!("Total sum is {}", total_sum);

    for handle in joinhandles.into_iter() {
        handle.join().unwrap();
    }
}
```
在这个解决方案中，我们首先计算每个块的大小，并使用 mpsc::channel() 函数创建一个通道来传递数据。然后，我们使用 clone() 函数来克隆通道的发送器，以便每个线程都可以发送它们的结果。在每个线程中，我们使用 &numbers[start..end].to_vec() 来创建一个包含块的新向量，并计算每个偏移量下的数字和。接下来，我们使用 send() 函数将结果发送回主线程。在主线程中，我们通过使用 iter() 函数和 sum() 函数来接收所有结果，并计算它们的总和。最后，我们使用 drop() 函数关闭发送器通道，以通知所有接收器线程传输已经结束。

需要注意的是，通道的使用可能会对性能产生一定的影响，因为它涉及到了数据传输和线程间通信的开销。如果要处理大量的数据或者要求非常高的性能，那么可能需要使用其它的并发编程技术来优化程序。

> Q: 不错, 也是个办法, 还有其它方案嘛? 如果使用其它第三方 crate 的话, 有什么建议?


> A: 是的，还有一些第三方 crate 可以帮助我们更方便地编写高效的并发 Rust 代码。

一种常用的 crate 是 Rayon，它是一个基于数据并行性的库，可以轻松地将 Rust 代码转换为并行代码。在 Rayon 中，我们可以使用 par_iter() 函数来创建一个并行迭代器，并将迭代器上的操作并行化。以下是一种可能的解决方案：

```rust
#![forbid(unused_imports)]
use rayon::prelude::*;

fn main() {
    let numbers: Vec<_> = (0..100u32).collect();
    let joinhandles = (0..8).into_par_iter().map(|offset| {
        let sum: u32 = numbers.par_iter().filter(|n| *n % 8 == offset).sum();
        println!("Sum of offset {} is {}", offset, sum);
    }).collect::<Vec<_>>();
}
```

在这个解决方案中，我们首先使用 into_par_iter() 函数将 0..8 转换为一个并行迭代器，然后使用 map() 函数对每个偏移量进行操作。在每个操作中，我们使用 par_iter() 函数将 numbers 转换为一个并行迭代器，并使用 filter() 函数过滤出每个偏移量下的数字，然后使用 sum() 函数计算它们的总和。在计算完所有偏移量的和后，程序就可以退出了。

除了 Rayon，还有一些其它的并发库和框架，例如 Crossbeam 和 tokio 等，它们都提供了一些方便的工具和 API 来帮助我们编写高效的并发 Rust 代码。具体使用哪个库，可以根据具体的需求和场景进行选择。

> Q: 看起来都不错, 谢谢,我学习一下

> A: 不用谢，祝你学习愉快！如果你有任何其他问题或者需要进一步的帮助，随时可以问我哦！



## refer.
> 其实官方的文档吃透, 基本可以平趟 80% 的日常开发了...

以及将自己伪装成一个认真又很笨的学员,
GPT 们就可以无限耐心的反复回答所有问题, 当然, 得配套自行检验以及官方文档证实:

- [rayon - crates.io: Rust Package Registry](https://crates.io/crates/rayon)
- [crossbeam - crates.io: Rust Package Registry](https://crates.io/crates/crossbeam)
- [tokio - crates.io: Rust Package Registry](https://crates.io/crates/tokio)
- ...

所以, rust 是故意不折腾复杂的内建模块, 专注提高编译器能力,
其它的各种创新实用 crate 都给社区折腾了...?

```
     _~∽~-~_
 \/ /  - ◵  \ \/
   '_   V   _'
   / '--+--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```