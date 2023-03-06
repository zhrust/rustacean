# btm
[bottom - crates.io: Rust Package Registry](https://crates.io/crates/bottom)

## backgroung
作为一名工程师, 总是得时刻关注系统状况的...


## goal

用好用对好工具

## trace

### layout
> 没想到这么简单...

如果在 linux 中, 那么配置: 
`~/.config/bottom/bottom.toml`

如果追加声明:


```toml
[[row]]
  [[row.child]]
  type="cpu"
[[row]]
    ratio=3
    [[row.child]]
      ratio=4
      type="proc"
    [[row.child]]
      ratio=3
      [[row.child.child]]
        ratio=2
        type="mem"
      [[row.child.child]]
        ratio=2
        type="net"
      [[row.child.child]]
        ratio=1
        type="disk"
```

保存后, 再次调用 `btm` 则是这样的排版:

![btm](https://ipic.zoomquiet.top/2023-03-06-zshot%202023-03-06%2011.15.40.jpg)

对应解释很简洁:

- 第1行
    - 第1子行
    - CPU 版块
- 第2行
    - 和第1行是 1:3 比例
    - 第1列
        - 和第2列/右列比例为 4:3
        - 进程版块
    - 第2列
        - 和第1列/左列比例为 3:4
        - 第1行
            - 和其它子行比例为 2:2:1
            - 内存版块
        - 第2行
            - 和其它子行比例为 2:2:1
            - 网络版块
        - 第3行
            - 和其它子行比例为 2:2:1
            - 硬盘版块

因为一般都是虚拟机, 温度什么的根本没有, 所以, 值得定制并优化位置, 以便第一时间关注到,
相比 [nmon for Linux | Main / HomePage](https://nmon.sourceforge.net/pmwiki.php) 只能选择信息版块,无法定制具体排版来, btm 要自在的多;






## refer.

[Home - bottom](https://clementtsang.github.io/bottom/nightly/#contribution)

- [General Usage - bottom](https://clementtsang.github.io/bottom/nightly/usage/widgets/battery/)
- [Layout - bottom](https://clementtsang.github.io/bottom/nightly/configuration/config-file/data-filtering/)
- ...



```
        _~`&-~_
    \/ /  - ◕  \ \/
      '_   ⎵   _'
      \ '--.--' <

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```