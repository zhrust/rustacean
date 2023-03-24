# 用迭代简化嵌套循环
> 学伴ChatGPT, chatting for debugging ...

## background
> exercises 第81题?


[Rectangles in Rust on Exercism](https://exercism.org/tracks/rust/exercises/rectangles)

```
   +--+
  ++  |
+-++--+
|  |  |
+--+--+
```

要求完成代码, 可以从同类似上述 ASCII 字符串中数出6个矩形来

## goal

完成合理概念摸查...

## trace

好容易折腾出一个可以通过所有 test 的代码:

```rust

pub fn count(lines: &[&str]) -> u32 {
    let chars = lines
            .iter()
            .map(|l| l.as_bytes())
            .collect::<Vec<_>>();
    let width = lines
            .get(0)
            .map(|l| l.len())
            .unwrap_or_default();
    let height = lines.len();


    let mut count = 0;
    for top in 0..height
    {
        for left in 0..width
        {
            for bottom in top+1..height
            {
                for right in left+1..width
                {
                    if chars[top][left] == b'+'
                        && chars[top][right] == b'+'
                        && chars[bottom][left] == b'+'
                        && chars[bottom][right] == b'+'
                        && (top+1..bottom).all(|i| {
                            matches!(
                                (chars[i][left], chars[i][right]),
                                (b'|'| b'+', b'|'| b'+')
                            )})
                        && (left+1..right).all(|j| {
                            matches!(
                                (chars[top][j], chars[bottom][j]),
                                (b'-'| b'+', b'-'| b'+')
                            )})
                    {
                        count += 1;
                    }
                }
            }
        }
    }
    count 

}
```

一看就很JS, 圈复杂度不小, 应该 Rusty 一些,就开始尝试:

> Q:可以运行, 但是, 嵌套太多 for 循环了,如何改进?

> A: 这段 Rust 代码实现了一个计算 ASCII 图中矩形数量的函数。函数输入是一个字符串数组，每个字符串表示 ASCII 图的一行。函数通过检查每个可能的矩形来计算矩形数量。

原始代码中，函数使用了四层嵌套的循环来检查每个矩形。这种实现方式难以理解和维护，也可能不太高效。为了改进代码，可以使用 itertools 库中的 combinations 方法，将嵌套的循环转换为使用迭代器的方式进行迭代。

新的代码使用了迭代器和高阶函数，使得代码更加简洁和易于理解。首先，它使用 combinations 方法生成了所有行和列的索引的组合，然后使用 flat_map 将生成的嵌套迭代器展开为一个单一的元组迭代器。然后，使用 filter_map 过滤掉不是矩形的元组，最后使用 sum 方法统计矩形的数量。

这种实现方式相比原始代码减少了循环嵌套的层数，并且使用了更加高级的 Rust 特性，可以提高代码的可读性和性能。

```rust
use itertools::Itertools;

pub fn count(lines: &[&str]) -> u32 {
    let chars = lines
        .iter()
        .map(|l| l.as_bytes())
        .collect::<Vec<_>>();
    let width = lines.get(0).map(|l| l.len()).unwrap_or_default();
    let height = lines.len();

    (2..height)
        .combinations(2)
        .flat_map(|(top, bottom)| {
            (2..width)
                .combinations(2)
                .map(move |(left, right)| (top, bottom, left, right))
        })
        .filter_map(|(top, bottom, left, right)| {
            if chars[top][left] == b'+'
                && chars[top][right] == b'+'
                && chars[bottom][left] == b'+'
                && chars[bottom][right] == b'+'
                && (top + 1..bottom)
                    .all(|i| matches!((chars[i][left], chars[i][right]), (b'|' | b'+', b'|' | b'+')))
                && (left + 1..right)
                    .all(|j| matches!((chars[top][j], chars[bottom][j]), (b'-' | b'+', b'-' | b'+')))
            {
                Some(1)
            } else {
                None
            }
        })
        .sum()
}

```

> A: 报错: error[E0308]: mismatched types

```rust
  --> src/lib.rs:50:20
   |
50 |         .flat_map(|(top, bottom)| {
   |                    ^^^^^^^^^^^^-
   |                    |           |
   |                    |           expected due to this
   |                    expected struct `Vec`, found tuple
   |
   = note: expected struct `Vec<usize>`
               found tuple `(_, _)`

error[E0308]: mismatched types
  --> src/lib.rs:53:28
   |
53 |                 .map(move |(left, right)| (top, bottom, left, right))
   |                            ^^^^^^^^^^^^-
   |                            |           |
   |                            |           expected due to this
   |                            expected struct `Vec`, found tuple
   |
   = note: expected struct `Vec<usize>`
               found tuple `(_, _)`

For more information about this error, try `rustc --explain E0308`.
error: could not compile `rectangles` due to 2 previous errors
```

> A: 这个错误表明，你的代码在尝试使用一个包含元组的迭代器作为 flat_map 方法的输出，但是该方法期望的是一个包含整数的 Vec 结构体。类似的错误也出现在 map 方法的调用中。

这个错误可能是由于 flat_map 方法的输出类型和后续的调用期望的类型不匹配导致的。具体来说，由于 flat_map 方法返回的是一个元组的迭代器，而不是一个包含整数的 Vec，所以后续的调用无法使用该迭代器的元素。

要解决这个问题，你可以在 flat_map 和 map 方法中使用闭包来将元组转换为 Vec，或者在后续的调用中使用元组的解构方式来获取迭代器中的元素。例如，你可以修改 flat_map 和 map 方法的调用如下：

```rust
.flat_map(|(top, bottom)| {
    (0..width).combinations(2).map(move |c| (top, bottom, c[0], c[1])).collect::<Vec<_>>()
})
.filter_map(|(top, bottom, left, right)| {
    if chars[top][left] == b'+'
        && chars[top][right] == b'+'
        && chars[bottom][left] == b'+'
        && chars[bottom][right] == b'+'
        && (top+1..bottom).all(|i| {
            matches!(
                (chars[i][left], chars[i][right]),
                (b'|'| b'+', b'|'| b'+')
            )})
        && (left+1..right).all(|j| {
            matches!(
                (chars[top][j], chars[bottom][j]),
                (b'-'| b'+', b'-'| b'+')
            )})
    {
        Some(1)
    } else {
        None
    }
})
```

这些修改将确保 flat_map 和 map 方法返回的是一个包含整数的 Vec，这样就可以在后续的调用中使用了。

> A: 还是报错: error[E0308]: mismatched types

```rust
  --> src/lib.rs:50:20
   |
50 |         .flat_map(|(top, bottom)| {
   |                    ^^^^^^^^^^^^-
   |                    |           |
   |                    |           expected due to this
   |                    expected struct `Vec`, found tuple
   |
   = note: expected struct `Vec<usize>`
               found tuple `(_, _)`

For more information about this error, try `rustc --explain E0308`.
error: could not compile `rectangles` due to previous error

```

> A: 根据错误提示，似乎我们在flat_map操作中需要返回一个类型为Vec的对象，但我们返回的是一个元组。这个错误可能是由于我们尝试将元组（(usize, usize)）解构为两个参数而引起的。

我们可以尝试在flat_map中直接返回一个Vec，而不是一个元组。我们可以使用into_iter()方法将元组中的元素转换为迭代器，并使用collect()方法将它们收集到一个Vec中，如下所示：

```rust
let rects = (0..height - 1).into_iter()
        .flat_map(|top| {
            (top + 1..height).into_iter()
                .map(move |bottom| (top, bottom))
        })
        .flat_map(|(top, bottom)| {
            (0..width - 1).into_iter()
                .flat_map(move |left| {
                    (left + 1..width).into_iter()
                        .map(move |right| (top, bottom, left, right))
                })
        })
        .collect::<Vec<_>>();
```

这里，我们首先使用into_iter()将一个区间（0..height-1）转换为一个迭代器。然后，我们使用flat_map将每个元素（top）映射到一个迭代器，其中每个元素都是一个二元组，表示从当前top到最后一行的所有可能的矩形的底部行。我们将top传递给move闭包，以便在之后的操作中使用它。

接下来，我们使用into_iter()将一个区间（top+1..height）转换为另一个迭代器，并使用map将每个元素（bottom）映射到一个二元组，表示当前矩形的顶部行和底部行。我们使用move将top捕获到闭包中。

然后，我们使用into_iter()将一个区间（0..width-1）转换为另一个迭代器，并使用flat_map将每个元素（left）映射到一个迭代器，其中每个元素都是一个四元组，表示当前矩形的左上角和右下角的坐标。我们将top、bottom和left传递给move闭包，以便在之后的操作中使用它们。

最后，我们使用into_iter()将一个区间（left+1..width）转换为另一个迭代器，并使用map将每个元素（right）映射到一个四元组，表示当前矩形的左上角和右下角的坐标。我们将top、bottom、left和right传递给move闭包，以便在之后的操作中使用它们。

最后，我们使用collect()方法将所有四元组收集到一个Vec中。我们使用::<Vec<_>>来指定要收集

>> 接下来 ChatGPT 就开始轴了,死活绕不出修改一个不相关的地方,触发相同问题, 再次建议相同代码...

换了个模型, 重启对话获得不同回答:

> A: 该错误是因为代码尝试将一个由两个元素组成的元组映射成一个 Vec<usize>，这是不能直接转换的。

要解决这个问题，你需要使用 map 方法中的 unwrap 方法将元组解包，然后将两个元素放入 Vec 中。例如，你可以这样修改代码：

```rust
let pairs_of_rows = rows.windows(2);
let rectangles = pairs_of_rows.flat_map(|pair| {
    let (top, bottom) = pair.unwrap();  // 解构元组
    (0..columns).map(move |column| {
        (top[column], bottom[column])  // 返回一个元组
    })
}).filter(|&(top, bottom)| {
    top < bottom
}).map(|(top, bottom)| {
    vec![top, bottom]  // 在这里创建一个包含两个元素的 Vec
}).collect::<Vec<_>>();  // 将所有 Vec 组合成一个 Vec

```
这样就能避免类型不匹配的错误了。

> Q: 如果对应代码原先是这样的,应该如何修改? 

```rust
    (2..height)
        .combinations(2)
        .map(|(top, bottom)| vec![top, bottom])
```

> A: 原先的代码使用了 itertools::Itertools trait 中的 combinations 方法来选择两个不同的行，得到一个包含两个元素的元组 (top, bottom)，然后通过 map 将其转换为一个 Vec，其中 Vec 包含两个 usize 类型的元素 top 和 bottom。然而，combinations 方法返回的元组是不同于独立的元素的，所以不能直接将其转换为 Vec。

你可以通过使用 map 和 collect 方法来解决这个问题。具体来说，你可以在 map 中解构元组 (top, bottom)，并将它们插入新的 Vec 中，然后再将这些 Vec 收集到一个大的 Vec 中。例如：

```rust
let pairs_of_rows = (2..height)
    .combinations(2)
    .map(|pair| {
        let (top, bottom) = (pair[0], pair[1]); // 解构元组
        vec![top, bottom] // 返回一个包含两个元素的 Vec
    })
    .collect::<Vec<_>>(); // 将所有 Vec 组合成一个 Vec
```
这应该能帮助你将原来的代码转换为一个可以在 Rust 中正确运行的版本。


------
>> 终于打开了思路, 然后获得没有报错的代码:

```rust

    (2..height)
        .combinations(2)
        .map(|pair| {
            let (top, bottom) = (pair[0], pair[1]); // 解构元组
            vec![top, bottom].into_iter() // 返回一个包含两个元素的 Vec
        })
        .flat_map(|mut tb| {
            //let top = tb[0];
            //let bottom = tb[1];
            let top = tb.nth(0).unwrap();
            let bottom = tb.nth(0).unwrap();
            (0..width)
                .combinations(2)
                .map(move |c| (top, bottom, c[0], c[1]))
                .collect::<Vec<_>>()
                .into_iter()
        })
        .filter_map(|(top, bottom, left, right)| {
            if chars[top][left] == b'+'
                && chars[top][right] == b'+'
                && chars[bottom][left] == b'+'
                && chars[bottom][right] == b'+'
                && (top + 1..bottom).all(|i| {
                    matches!(
                        (chars[i][left], chars[i][right]),
                        (b'|' | b'+', b'|' | b'+')
                    )
                })
                && (left + 1..right).all(|j| {
                    matches!(
                        (chars[top][j], chars[bottom][j]),
                        (b'-' | b'+', b'-' | b'+')
                    )
                })
            {
                Some(1)
            } else {
                None
            }
        })
        .sum::<u32>()
```

可惜问题了,这个看起来非常 Rusty 的代码, 无法通过所有 test,
多数案例并没有清点明白所有矩形...

所以....代码复杂不怕, 就怕人看不明白, 难以调试...

## refer.
> 其实官方的文档吃透, 基本可以平趟 80% 的日常开发了...

以及将自己伪装成一个认真又很笨的学员,
GPT 们就可以无限耐心的反复回答所有问题, 当然, 得配套自行检验以及官方文档证实:


- [itertools - Rust](https://docs.rs/itertools/0.10.5/itertools/#crate-features)
    - [Combinations in itertools::structs - Rust](https://docs.rs/itertools/0.10.5/itertools/structs/struct.Combinations.html)
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