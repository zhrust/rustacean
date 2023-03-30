# rustlings:94

## background
> conversions/as_ref_mut.rs

AsRef and AsMut allow for cheap reference-to-reference conversions.

Read more about them at https://doc.rust-lang.org/std/convert/trait.AsRef.html

and https://doc.rust-lang.org/std/convert/trait.AsMut.html, respectively.


## goal
> 必要目标

快速通过

## trace
> 具体推进

还是要在 GPT 的辅助下掠过:

核心问题是完成函数:

```rust
fn num_sq<T>(arg: &mut T) {
    // TODO: Implement the function body.
    ???
}

// 对应的测试

    #[test]
    fn mult_box() {
        let mut num: Box<u32> = Box::new(3);
        num_sq(&mut num);
        assert_eq!(*num, 9);
    }

```

看起来就是对 arg 进行自乘而已

但是照猫画虎才发现:

```rust
fn num_sq<T>(arg: &mut T)
    where T: std::ops::Mul<Output = T> + std::ops::MulAssign + Copy
{
    let square = *arg * *arg;
    *arg *= *arg;
    *arg = square;
}
```

这样触发一系列问题:
```

error[E0277]: cannot multiply `Box<u32>` by `Box<u32>`
  --> exercises/conversions/as_ref_mut.rs:86:16
   |
86 |         num_sq(&mut num);
   |         ------ ^^^^^^^^ no implementation for `Box<u32> * Box<u32>`
   |         |
   |         required by a bound introduced by this call
   |
   = help: the trait `Mul` is not implemented for `Box<u32>`
note: required by a bound in `num_sq`
  --> exercises/conversions/as_ref_mut.rs:47:14
   |
46 | fn num_sq<T>(arg: &mut T)
   |    ------ required by a bound in this
47 |     where T: std::ops::Mul<Output = T> + std::ops::MulAssign + Copy
   |              ^^^^^^^^^^^^^^^^^^^^^^^^^ required by this bound in `num_sq`

error[E0277]: cannot multiply-assign `Box<u32>` by `Box<u32>`
  --> exercises/conversions/as_ref_mut.rs:86:16
   |
86 |         num_sq(&mut num);
   |         ------ ^^^^^^^^ no implementation for `Box<u32> *= Box<u32>`
   |         |
   |         required by a bound introduced by this call
   |
   = help: the trait `MulAssign` is not implemented for `Box<u32>`
note: required by a bound in `num_sq`
  --> exercises/conversions/as_ref_mut.rs:47:42
   |
46 | fn num_sq<T>(arg: &mut T)
   |    ------ required by a bound in this
47 |     where T: std::ops::Mul<Output = T> + std::ops::MulAssign + Copy
   |                                          ^^^^^^^^^^^^^^^^^^^ required by this bound in `num_sq`

error[E0277]: the trait bound `Box<u32>: Copy` is not satisfied
  --> exercises/conversions/as_ref_mut.rs:86:16
   |
86 |         num_sq(&mut num);
   |         ------ ^^^^^^^^ the trait `Copy` is not implemented for `Box<u32>`
   |         |
   |         required by a bound introduced by this call
   |
note: required by a bound in `num_sq`
  --> exercises/conversions/as_ref_mut.rs:47:64
   |
46 | fn num_sq<T>(arg: &mut T)
   |    ------ required by a bound in this
47 |     where T: std::ops::Mul<Output = T> + std::ops::MulAssign + Copy
   |                                                                ^^^^ required by this bound in `num_sq`

error: aborting due to 3 previous errors

```

因为 Box<T> 类型没有实现 std::ops::Mul 和 std::ops::MulAssign trait。你可以使用 Deref trait 来解引用 Box<T> 类型的值，然后再对值进行乘法运算和赋值操作。

建议修改后的代码:

```rust
fn num_sq<T>(arg: &mut T)
where
    T: std::ops::Deref<Target = u32> + std::ops::DerefMut,
{
    let square = **arg * **arg;
    **arg = square;
}
```

在这个版本的代码中，T 类型必须实现 std::ops::Deref 和 std::ops::DerefMut trait，这样就可以使用解引用操作符 * 来获取 Box<T> 类型内部的值，并进行乘法运算和赋值操作了。

值得注意的是，在这个版本的代码中，我们不需要显式地实现 Copy trait，因为 u32 类型已经实现了 Copy trait，而 T 类型需要实现 Deref<Target = u32> trait，所以也就具有了 Copy trait 的能力。

而以上提示是换了3种姿势, 才诱使 GPT 给出的,
之前绕的方向更加无解...


所以, 这也只能是一个特殊场景,
如果是自己实现的话, 一定要使用对应合理的内置类型, 不折腾.


## refer.
> 关键参考

[学习 Rust - Rust 程序设计语言](https://github.com/rust-lang/rustlings/)


## logging
> 版本记要

- ..
- 230330 ZQ init.



```
          _~--^~_
      \) /  ◴ ◵  \ ()
        '_   ▽   _'
        | '--#--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```

