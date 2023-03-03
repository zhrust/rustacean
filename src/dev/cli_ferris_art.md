# Ferris-Actor
> Freeis ASCII-art actor and CLI animation/tools
> 叕在终端中起舞动的 Ferris, 这次可以随机生成一个 pose 以供 Markdown 使用

首个 crate 发布:
**[ferris-actor - crates.io: Rust Package Registry](https://crates.io/crates/ferris-actor)**

## backgroung
作为一名程序猿, 终端几乎就是生存空间, 在这这里发生什么, 都不奇怪

## goal

完成最早在网页中看到的 ASCII-art 版本 STAR WAR MOIVE....

### installation

...TBD

### usage
...TBD

## tracing
> 问题是这么来的...

- 如何打印多行?
    - println! 就行
- 如何刷新多行?
    - print!("\x1B[{}A", frames.len()); // move the cursor up
    - 问题是怎么计算每一帧的行数?
        - 好吧, 制作终端 ASCII-art 动画原本就是有专用 crate 的
        - 上: termion
- 如何使用多行打印模板?
    - format!() 中第一个参数就好
    - 另外,用 indoc 可以简化定义形式
- 如何多行打印模板从另外文件引用?
    - 不行,必须是: 字符串字面量（string literal）,在编译时要是已知的
    - 这已经不是简单的 format!() 函数了,完全是标准的模板引擎了
    - 这种当然也是有专用 crate 的
        - 上:handlebars
- 如何将 `Result<std::string::String, RenderError>` 兼容提取为 String?
    - map_err/unwrap_or_else/... 堆上, 总之, 不能放任何一个问题跑掉
- 如何将 HTML 转义字符打印回原本的样子?
    - LOOK: [Introduction | Handlebars](https://handlebarsjs.com/guide/hooks.html)
    - 原来, Handlebars 根本就是个模板语言, 人家有完备的功能语法
    - 只是 [handlebars - crates.io: Rust Package Registry](https://crates.io/crates/handlebars/0.6.14) 完成了全部支持
    - 而且, 人家是将近10年的老工程了,一直在完善
- ...


> Cargo.toml 编译发行

开始找到办法, 可以将 Carogo.toml 中的关键信息拿到程序代码中使用, 
比如说:

```rust
    let version = env::var("CARGO_PKG_VERSION").unwrap();
```

可惜, 编译发行后, 使用二进制执行文件出错:

```shell
cd ./target/release/ferris-actor snap
Snap a randomly Ferris ASCII-art pose as Markdown:

thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: NotPresent', src/act/snap.rs:99:49
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

毕竟没有对应环境变量了, 得使用编译前文本提取的办法来静态化;
参考: [exa/build.rs at master · ogham/exa](https://github.com/ogham/exa/commits/master/build.rs?author=ogham)

才发现, Rust 中使用一个静态配置, 这么复杂...

思路有一些:

- 使用 build.rs 定制不同编译过程中自动生成的辅助文件:
    - 参考: [exa/build.rs at master · ogham/exa](https://github.com/ogham/exa/blob/master/build.rs#enroll-beta)
    - 比如, 区分不同的编译目标时, 在对应编译路径中动态插入一个 version.rs
    - 包含从 Cargo.toml 中提取的版本信息, 并声明为静态常量:
    - `write!(&mut f, "pub const VERSION: &str = \"{}\";\n", version).unwrap();`
    - 然后, 在想引用的文件中引用
    - ... Hummm, 问题在这就象个编译宏, 每次生成的东西根本是不可见的
- 使用 workspaces 将对应工具组的模块放到专用辅助库中...
    - 然后, 发现这就涉及多多个 Crate 的编译, 改变了整个儿日常开发流程
    - ... Hummm, 放弃
- 使用 本地库, 在当前工程目录中再来一发 `cargo new utils --lib`
    - 形成一个根目录中的 `utils` 文件夹/库
    - 然后,在原有 Cargo.toml 中追加本地依赖, 类似:

```toml
[dependencies.utils]
path = "utils"
version = "0.1.0"
```

> 然后, 发现, `found to be present in multiple build targets:...` 和 workspaces 一样的毛病, Humm 放弃

- 使用普通的同级辅助模块 `src/act/version.rs` , 基于标准的 toml 模块解析 Cargo.toml 中的版本信息;
    - 通过 `env::current_dir()` 获得当前系统绝对路径
    - 使用 `std::path::PathBuf` 合理操作, 拼出 Cargo.toml 的绝对路径
    - 就可以进行正常的配置文件解析和使用而已...
    - ...是的, 通了.

可惜是假的:

```shell
$ /opt/bin/ferris-actor snap
Snap a randomly Ferris ASCII-art pose as Markdown:

thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: Os { code: 2, kind: NotFound, message: "No such file or directory" }', src/act/version.rs:22:51
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

和以往一样...

- 冷静了一下,捋一下思路:
    - 目的: 可以从 Cargo.toml 中拿到版本信息, 然后可以自动生成当前编译的时间戳
    - 然后: 其它功能代码中, 可以安全获得这个动态信息, 通过一种静态数据定量的形式
    - 发现: built.rs 是种常用辅助工具, 就是介入 cargo 各种编译行为中, 事先完成对应定制
    - 那么: 为了兼容开发调试和编译发行时两种状态对 `编译+版本` 信息的使用和管理
    - 自然:
        - 还是使用 version.rs
        - 不过内容不是自动获得信息, 而是一个定量声明语句
        - 可以在调试时先完成对应 use 和检验, 当然内容是徦的
        - 在 built.rs 
            - 中使用 cargo_metadata 支持, 动态从 Cargo.toml 中拿到版本信息
            - 再基于 chrono 自由生成需要格式的时间戳
            - 将 version.rs 中整个儿定量声明语句在整体拼好写回去
    - 以上, 果然达成目标:
        - 参考:[ferris-actor/build.rs at main · zhrust/ferris-actor](https://github.com/zhrust/ferris-actor/blob/main/build.rs)

>> PS:
只是这样一来, 仓库中永远有一个内容在动态变化的文件,
导致 `cargo publish` 时总是失败, 要使用对应参数, 无视之...

```shell
$  cargo publish --registry crates-io --allow-dirty --no-verify
```


### build --verbose
> cargo 真的是个全能工具箱

经过挖掘, 才知道, 进行 build 时, 当然可以公开所有行为,
可以清晰的看到 rustc 到底在干什么, 每个步骤使用的参数...

>> 要知道这些参数当年都是人工逐一输入的...


```
$  cargo build --release --verbose
...

       Fresh indoc v2.0.0
     Running `/Users/zoomq/Exercism/proj/ferris-actor/target/release/build/libc-44b1e034f3f26ee4/build-script-build`
     Running `rustc --crate-name core_foundation_sys /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/core-foundation-sys-0.8.3/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off -C metadata=f09e1a3332d57a02 -C extra-filename=-f09e1a3332d57a02 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --cap-lints allow -l framework=CoreFoundation`
   Compiling iana-time-zone v0.1.53
     Running `rustc --crate-name iana_time_zone --edition=2018 /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/iana-time-zone-0.1.53/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off --cfg 'feature="fallback"' -C metadata=2aca5692396caa43 -C extra-filename=-2aca5692396caa43 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern core_foundation_sys=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libcore_foundation_sys-f09e1a3332d57a02.rmeta --cap-lints allow`
     Running `rustc --crate-name num_traits /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/num-traits-0.2.15/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off -C metadata=b04e009ff1e9804c -C extra-filename=-b04e009ff1e9804c --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --cap-lints allow --cfg has_i128 --cfg has_to_int_unchecked --cfg has_reverse_bits --cfg has_leading_trailing_ones --cfg has_int_assignop_ref --cfg has_div_euclid`
     Running `rustc --crate-name libc /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/libc-0.2.139/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off --cfg 'feature="default"' --cfg 'feature="std"' -C metadata=992234b65e6ba903 -C extra-filename=-992234b65e6ba903 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --cap-lints allow --cfg freebsd11 --cfg libc_priv_mod_use --cfg libc_union --cfg libc_const_size_of --cfg libc_align --cfg libc_int128 --cfg libc_core_cvoid --cfg libc_packedN --cfg libc_cfg_target_vendor --cfg libc_non_exhaustive --cfg libc_ptr_addr_of --cfg libc_underscore_const_names --cfg libc_const_extern_fn`
   Compiling time v0.1.45
     Running `rustc --crate-name time /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/time-0.1.45/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off -C metadata=7bfae04e9962e5d8 -C extra-filename=-7bfae04e9962e5d8 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern libc=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/liblibc-992234b65e6ba903.rmeta --cap-lints allow`
     Running `rustc --crate-name num_integer /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/num-integer-0.1.45/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off -C metadata=184fc31131d60eab -C extra-filename=-184fc31131d60eab --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern num_traits=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libnum_traits-b04e009ff1e9804c.rmeta --cap-lints allow --cfg has_i128`
   Compiling chrono v0.4.23
     Running `rustc --crate-name chrono --edition=2018 /Users/zoomq/.cargo/registry/src/mirrors.tuna.tsinghua.edu.cn-df7c3c540f42cdbd/chrono-0.4.23/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type lib --emit=dep-info,metadata,link -C embed-bitcode=no -C debug-assertions=off --cfg 'feature="clock"' --cfg 'feature="default"' --cfg 'feature="iana-time-zone"' --cfg 'feature="js-sys"' --cfg 'feature="oldtime"' --cfg 'feature="std"' --cfg 'feature="time"' --cfg 'feature="wasm-bindgen"' --cfg 'feature="wasmbind"' --cfg 'feature="winapi"' -C metadata=d3c20a3ba0fbfc72 -C extra-filename=-d3c20a3ba0fbfc72 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern iana_time_zone=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libiana_time_zone-2aca5692396caa43.rmeta --extern num_integer=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libnum_integer-184fc31131d60eab.rmeta --extern num_traits=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libnum_traits-b04e009ff1e9804c.rmeta --extern time=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libtime-7bfae04e9962e5d8.rmeta --cap-lints allow`
   Compiling ferris-actor v0.2.4 (/Users/zoomq/Exercism/proj/ferris-actor)
     Running `rustc --crate-name build_script_build --edition=2021 build.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type bin --emit=dep-info,link -C embed-bitcode=no -C debug-assertions=off -C metadata=59b650788a6d6b7f -C extra-filename=-59b650788a6d6b7f --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/build/ferris-actor-59b650788a6d6b7f -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern cargo_metadata=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libcargo_metadata-86d30a0408a5a2b1.rlib --extern chrono=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libchrono-d3c20a3ba0fbfc72.rlib`
     Running `/Users/zoomq/Exercism/proj/ferris-actor/target/release/build/ferris-actor-59b650788a6d6b7f/build-script-build`
     Running `rustc --crate-name ferris_actor --edition=2021 src/main.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --crate-type bin --emit=dep-info,link -C opt-level=3 -C embed-bitcode=no -C metadata=a20b677d4d0c20d7 -C extra-filename=-a20b677d4d0c20d7 --out-dir /Users/zoomq/Exercism/proj/ferris-actor/target/release/deps -L dependency=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps --extern clap=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libclap-fd5df38d2b65208f.rlib --extern clia_tracing_config=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libclia_tracing_config-e0e4f4192befb03f.rlib --extern handlebars=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libhandlebars-54715fbcc7488164.rlib --extern indoc=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libindoc-1fa0458745c98152.dylib --extern log=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/liblog-c2586173bc1389d4.rlib --extern rand=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/librand-cf3e2775330e5826.rlib --extern serde_json=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libserde_json-ed5e928c653c8e39.rlib --extern termion=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libtermion-e1080b4cecde7e2b.rlib --extern toml=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libtoml-db505b4d1c897e14.rlib --extern tracing=/Users/zoomq/Exercism/proj/ferris-actor/target/release/deps/libtracing-42c6c9622152d235.rlib`
    Finished release [optimized] target(s) in 6.08s
```


## TOD:
> 为毛 Rust 中想引用兄弟目录的模块就这么难呢?

```
foobar/
    +- Cargo.toml
    +- Cargo.lock
    +- README.md
    +- ...
    +- src/
        +- main.rs
        +- act.rs
        +- act/
        |   + ...
        |   + snap.rs
        +- misc.rs
        `- misc/
            + version.rs
```

以上结构是一个简单的 bin 工程目录,
只是, main.rs 要调用的各种函数, 分布到不同子目录中了,
问题在:

- src/act/snap.rs 中引用同级的其它模块, 都可以, 
    - 嘦在 src/mod.rs 中有对应进行声明;
- 可是 src/act/snap.rs 中想引用 `src/misc/version.rs` 中的模块/对象/函数/...
    - 怎么折腾就是不行...?

--> 参考:[Crate中合理划分目录](/tip/manag_growing_proj_with_crates_modules.md)


### refer.

- [ferris-says - crates.io: Rust Package Registry](https://crates.io/crates/ferris-says)
- [ferris-say - crates.io: Rust Package Registry](https://crates.io/crates/ferris-say)
    - [spaghettidev 🦀 — I'm a Software engineering student and Typescript & Rust developer.](https://spaghettidev.tech/posts/creating-a-cli-with-rust/)
- [Rustacean.net: Home of Ferris the Crab](https://rustacean.net/)
    - [Animated Ferris - JSFiddle](https://jsfiddle.net/Diggsey/3pdgh52r/embedded/result/)
- [Tokens - The Rust Reference](https://doc.rust-lang.org/reference/tokens.html#raw-string-literals)
    - ...

```
          _~^~`~_
      \) /  ☉ ☉  \ (/
        '_   V   _'
        / '-----' |

...act by ferris-actor v0.2.2
```

## logging

- ...
- 230301 ZQ ...🦀
- 230225 ZQ re-re-re-init.


```
           _~`|`~_
       \/ /  > ◕  \ ()
         '_   𝟂   _'
         > '--~--' /

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```

