# BXMr
> rIME-Squirrel 表形码维护工具

## backgroung
作为一名程序猿, 总是要对输入法也要有全面控制

所以, 一直有折腾:[ZqBXM/Rime-Squirrel at master · ZoomQuiet/ZqBXM](https://github.com/ZoomQuiet/ZqBXM/tree/master/Rime-Squirrel)

## goal

全面使用 Rust 重构原有 Python 版本的维护指令集;


## trace

- 最早是 手工维护
- 后来用 Python 写了个脚本, 但是还是要人工复制到对应目录中再重新编译码表
- 又后来, 使用 invoke 框架拓展并增强了 BXM 码表的维护内部编辑
- 现在, 轮到 Rust 来重构了...


### feeling
> 终于有感觉了...

知道 Rust 有年头了, 但是, 和 golang 类似, 一直没有认真上手,
golang 也开发过几个实用小工具/系统, 感觉和用 Python 差不多,
还是得靠 print 以及线上人眼观察...

Rust 开始进入 Linux 内核了, 感觉不一样了, 足够敦实了,
而且, 以往好象所有折腾过的开发语言都是有 GC 的...

在完成 [Ferris艺术](/dev/cli_ferris_art.md) 小工具后,
决定介入日常生活, 重制这个实用工具: `BXMr` ~ BXM 管理器;
以便替代原先 Python 版本的 -> [tasks.py](https://github.com/ZoomQuiet/ZqBXM/blob/master/Rime-Squirrel/tasks.py)


代码的增长, 要求必须对项目目录结构进行良好的规划/控制/演变/...

进一步的, 在代码调试过程中, 发现, 有了 rust-analyzer 的加持,
以往的循环:

```
    开发
    ^   \ 
    |    运行
    |     \
    |     观察 print()
    |    /
     调试
```

可以有质的提升, 现在可以完全信任编译器了,
现在的流程变成:

- 思考问题
- 撰写代码, 实时根据 RA(rust-analyzer) 提示, 进行修订
- 那么嘦在 IDE 中没有警告时 
    - 一般 cargo check 也不会有问题
    - 以及 cargo check 也不会有问题
    - 甚至 cargo build 也不会有问题
    - ...也就意味着此时, 代码包含的所有应用/系统行为就已经是可信/可用/坚不可摧的了
- 这种问题/目标/代码/理解/... all-in-one 的感觉太坚实了
    - 对比以往其它语言, 即便是 IDE/编译器 都没问题
    - 真正运行起来时, 照样有各种意外
    - ...那种感觉就象 屎莱姆 ...软卟卟的,想怎么折腾就怎么折腾, 可就是永远固定不到一个理想的状态
- 而 Rust 世界中,嘦编译器过了, 基本上就夯实了...
- 如果有问题, 基本上可以明确, 绝对不是代码问题
    - 只可能是自己对问题的理解有偏差
    - 以及代码表述的行为和我们的期待不同...


> 工作量:


```

༄  tokei
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 Markdown                2          218            0          152           66
 Rust                   13         1137          657          322          158
 TOML                    1           51           28           15            8
===============================================================================
 Total                  16         1406          685          489          232
===============================================================================
```

对比原有 Python 的版本:

```

༄  tokei tasks.py
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 Python                  1          248          157           22           69
===============================================================================
 Total                   1          248          157           22           69
===============================================================================
```

嗯哼? 没有主观感觉的10倍, 当然,过程中删除的不同版本,得有10倍了;


### verb
> 纠结所在....

原问题是这样的:

- 输入法的码表, 只是就是一批 键码和文字 的 K/V 值对
- 在 rIME-Squirrel 中则是要求组织为一个约定的 .yaml 文件
    - 数据结构为: "{文字}\t{键码}"
    - 键码相同指向多个文字时, 就对应复制出新行来
    - 行的前后顺序决定了输入时推荐的顺序
    - 比如现有定义码表行片段:
        - 敠    aaaa
        - 叕    aaaa
        - 敪    aaaa
        - 娺    aaaa
        - 啊啊啊啊    aaaa
    - 那么在使用 rIME 输入时自动弹出的推荐字列就应该是:

![aaaa](https://ipic.zoomquiet.top/2023-03-05-zshot%202023-03-05%2021.16.04.jpg)

难点在 `键/字` 条目行的次序是有要求的, 以后插入时要遵守:

- 短键码在前
- ASCII 字母顺序为先
- 长度从 1 到 4 个字符
- 不可能超过 4 个字符
- 例如:
    - a 在 b 之前
    - a 在 aa 之前
    - aa 在 ab 之前
    - az 在 aaa 之前
    - aaaa 在 b 之前
    - ...
- 如果对应键并没定制就不记录
- 例如:
    - 原有定义条目记录:
        - btk 是不并
        - btmd 悬而未决
    - 那么, 想追加一个 `btl 是也乎` 就应该插入为:
        - btk 是不并
        - btl 是也乎
        - btmd 悬而未决
- 这里就问题就在一个原本有具体排序要求的键码序列
    - 本身是残缺的
    - 要判定某个新增键码应该在哪里插入,要顾虑的条件很多
    - 以往都是人工观察插入的...还不得保证对, 那时 rIME 编译时就报错...


所以, Python 代码实现时, 用了一个反模式:

- 先根据 BXM 的编码规则, 构造出一个严格按照键码排序的编码表
- 然后, 再根据现行使用的 BXM 定义 `键/字` 填写入这个编码表
- 那么, 进行维护时就变成一个简单的查表过程:
    - 对原有 `键/字` 的条目, 追加同键不同字时, 追加字到对应的键后数组就好
    - 对原先没有的条目, 到对应键后空白数组中追加就好
    - ...
    - 最后需要更新 .yaml 时,  从这个全码全序的编码表对其中有效的条目进行转换输出就好
- 也就是说, 将原先 .yaml 中的 "{文字}\t{键码}" 定义记录条目文本
    - 先变成 "{"键":["字0","字1",,]}" 类字典/HashMap 记录
    - 而且,其中的键是吻合 BXM 规则的全部顺序可能键码

对应原有 Python 代码:

```python
BXMC = "abcdefghijklmnopqrstuvwxyz"

@task
def init2(c):
    print(f"init from\n\t{ORIG};\nAIM->\t{AIMP}")
    print(f"{AIMP} exists?\n\t",os.path.exists(f"{AIMP}"))
    _gbxm = {}

    def generate_strings(length, prefix=''):
        if length == 0:
            return
        for c in BXMC:
            key = prefix + c
            print(key)
            _gbxm[key] = []
            generate_strings(length-1, key)

    generate_strings(4)
    print(f"gen. all BXM code as {len(_gbxm.keys())}")
    return None
```

对应 Rust 版本是:

```rust
//  定义在: src/inv/util.rs
pub const BXMC: &str = "abcdefghijklmnopqrstuvwxyz";
pub const MBCL: usize = 4; // code len.

pub fn generate_strings(length: usize, 
            prefix: String, 
            gbxm: &mut BTreeMap<String, Vec<String>>
        ) {
        if length == 0 {
            return;
        }
        for c in BXMC.chars() {
            let key = prefix.clone() + &c.to_string();
            gbxm.insert(key.clone(), Vec::new());
            generate_strings(length - 1, key, gbxm);
        }
    }

pub fn init2(codelen:usize) -> Option<BTreeMap<String, Vec<String>>> {
    let mut gbxm = BTreeMap::new();
    generate_strings(codelen, String::new(), &mut gbxm);
    //println!("\n\t gen. all BXM code as {} ", gbxm.len());

    Some(gbxm)
}

//  具体调用形式:
use crate::inv::util;
...
    let gbxm = util::init2(util::MBCL).unwrap();
```

基本上和 Python 代码 1:1 转换, 当然, 代码的可信度要高很多;

接下来才是问题:

- 生成的全量键码有 475,254 个
    - 用 toml 记录时, 有4Mb
- 而对应 BXM 当前包含的所有键码仅 60,337 个
    - 用 yaml 记录时, 只有 700Kb
- 用 Python 加载/更新/回写/... IO 操作时,要3~4秒
- 而用 cargo run 进行试用时, 要10秒左右
    - 好在 cargo build --release 之后的二进制执行文件运行时, 快到了 2~3 秒
- 这样还是慢哪....
    - 尝试用异步 crate 加速, 效果不明显
    - 以字母表为基准切为26个文件? 太麻烦而且, 要在用户本地生成一组文件本身也是问题
    - 上 SQLite 内存数据库? 相同的数据量想加载到内存中一样有耗时要等待
    - ....


> 还能怎么加速呢?

- 以现行有效 `键/字` 定义为准, 只管理不到7万行数据,比将近50万行肯定要快
    - 但是, 这就得完成完备的插入次序判定算法
    - ...当然也行, 只是没必要, 如果 BXMr 想兼容所有输入法的话, 就不能特化支持特定码表...
- 回到问题源头:
    - 数据文件大, 所以加载慢
    - 而且没使用多核 CPU 来加速
    - ...
    - 也就是说, 值得折腾的是利用 Rust 的系统编程能力:
        - 构造 `键/字` 全量码表的二进制文件形式, 大幅减少要加载的文件尺寸
        - 动用异步/并发/并行/多线程/非阻塞/... 能力, 在数据加载以及处理上加速
    - 正好, 这也就能将以往看的资料中高级话题, 对应到具体问题需求上来了...


### .env
> 如何可以缓存各种常用配置?

和 Python 日常开发和部署使用不同, 以往:

- 一般使用个 _settings.py 文件,作为一个全局变量桶, 收集各种在所有模块中都要用的关键配置和数据
    - 反正一般 Python 小工具发行时, 并没有编译/打包的过程, 都是脚本和配置一起发布
    - 嘦注意加载的目录关系, 就可以无视操作系统, 在 Python 运行时的帮助下加载到需要的配置

但是, 在尝试用相似的行为套在 Rust 工程中才囧rz...

- 如果也是用 _stettings.rs 那么编译后, 位置就不知道了, 而且用户本地要现场配置的东西也不可能写回 _settings.rs 了
- 那么,使用一个外部的 .toml 配置文件呢? 进行 cargo build --release 后, 发行单一可执行二进制目标文件, 和对应内核系统配套的, 一般并没人拖一个 .toml 来到本地配置
- 尝试将客户的配置信息记录到环境变量中, 才发现, 想永远有效必须写对应 *rc 文件, 问题是现在 bash 如不是大一统, 还有其它流行 shell 版本, 对应的 *rc 文件格式和位置也是不可预见的...
- 要不, 嘦涉及到外部导入/导出的来源和发布目标文件, 要求每次指令用户自己通过附加参数给出来就好?
    - 回想自己使用就过程, 每次无论什么指令, 都要跟上 1~2 个, 或是更多路径参数....败退...
- ...突然想到还有个 `.env` 文件哪...算是应用系统的随身运行时环境变量,本身很简单可以视为简化版本的 .ini 文件
- 追查了一下果然有 [dotenv - crates.io: Rust Package Registry](https://crates.io/crates/dotenv/0.15.0)
    - 那么逻辑就简单了:
    - 无论用哪个指令, 先检验固定的和执行文件同目录的 .env 文件
    - 如果没有, 指引用户先用 `$ bxmr cfg ...` 指令来完成关键文件的指引
    - 然后, 写入 .env 文件中, 并自动加载到环境变量里
    - 这样, 嘦运行自己工具的发行版, 就可以从本身所在目录中加载到以往的关键配置, 用在具体指令响应过程中...



### async
> 只是想加速一个文件的读取...

-> [文件加速打开](/tip/open_big_file_speed.md)

然后就发现,这事儿没那么简单, 整体上:

> 需要明确的是，async函数在Rust中是一种特殊的函数类型，可以在其中使用await操作符等异步操作，而async函数的返回类型是一个实现了Future trait的类型，这个类型在编译时是不确定的，因为它表示一个异步计算的结果，需要等待执行完成才能得到具体的结果类型。因此，当你调用一个async函数时，你需要在一个async上下文中，例如在async函数中或者使用tokio等异步运行时库的Runtime来运行异步任务。

所以, 原有的调用栈:

- src/main.rs -> fn main() 
    - inv::run() -> src/inv.rs 
        - seek::echo() -> src/inv/seek.rs
            - util::toml2btmap() -> src/inv/util.rs
                - file.read_to_string(&mut contents).unwrap()
                    - let mut file = File::open(tfile).unwrap()
- 发现可以用 tokio 实现异步操作, 并加速文件读取?
    - 于是-> 
        - use tokio::fs::File as TokioFile;
        - use tokio::io::BufReader as TokioBufReader;
    - 然后-> 
        - let file = TokioFile::open(path).await?;
        - let reader = TokioBufReader::new(file);
    - 但是, 发现不行, await? 不能编译, 因为所在函数不是 async 的, 于是连锁反应
    - pub async fn async_read_lines().await <- 以便被调用
        - pub async fn async_toml2btmap() <- 以便被调用
            - util::async_toml2btmap().await <- src/inv/util.rs
                - async fn seek::echo().await <- src/inv/seek.rs
                    - async fn run() <- src/inv.rs 
                        - inv::run().await <- src/main.rs
                            - async fn main()


如果不是 rust-analyzer 一路提醒, 真会蒙圈儿的...



## refer.

- [clap::_derive::_cookbook::git_derive - Rust](https://docs.rs/clap/latest/clap/_derive/_cookbook/git_derive/index.html)
    - 简化官方示例,完成结构性探索
- [Building a CLI from scratch with Clapv3 | by Ukpai Ugochi | Medium](https://medium.com/javascript-in-plain-english/coding-wont-exist-in-5-years-this-is-why-6da748ba676c)
    - 很囧的案例, 看起来很美却根本编译不过...
- 尴尬了, 二进制发行版本的应用可没有那么简单的全局配置可以使用...
    - [Working with Environment Variables in Rust · Thorsten Hans' blog](https://www.thorsten-hans.com/working-with-environment-variables-in-rust/)
    - ...
- ...

## logging

- ...
- 230301 ZQ ...🦀
- 230227 ZQ mod/clap/tracing/... 项目结构厘定
- 230225 ZQ re-re-re-init.





```
        _~^|∽~_
    \) /  ◴ ☉  \ \/
      '_   ⎵   _'
      / '--∽--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```



