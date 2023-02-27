# 交叉编译
> 主要是懒...


## background

日常环境:

```
  neofetch
                    'c.          zoomq@ZQ160626rMBP
                 ,xNMM.          ------------------
               .OMMMMo           OS: macOS Big Sur 10.16 22D68 arm64
               OMMM0,            Host: MacBookPro18,4
     .;loddo:' loolloddol;.      Kernel: 22.3.0
   cKMMMMMMMMMMNWMMMMMMMMMM0:    Uptime: 5 days, 5 hours, 39 mins
 .KMMMMMMMMMMMMMMMMMMMMMMMWd.    Packages: 330 (brew)
 XMMMMMMMMMMMMMMMMMMMMMMMX.      Shell: bash 5.1.16
;MMMMMMMMMMMMMMMMMMMMMMMM:       Resolution: 2048x1280, 3200x1800
:MMMMMMMMMMMMMMMMMMMMMMMM:       DE: Aqua
.MMMMMMMMMMMMMMMMMMMMMMMMX.      WM: Spectacle
 kMMMMMMMMMMMMMMMMMMMMMMMMWd.    Terminal: iTerm2
 .XMMMMMMMMMMMMMMMMMMMMMMMMMMk   Terminal Font: FiraCode-Regular 18 (normal) / SarasaMonoSCNerd-regular 18 (non-ascii)
  .XMMMMMMMMMMMMMMMMMMMMMMMMK.   CPU: Apple M1 Max
    kMMMMMMMMMMMMMMMMMMMMMMd     GPU: Apple M1 Max
     ;KMMMMMMMWXXWMMMMMMMk.      Memory: 11065MiB / 65536MiB
       .cooc,.    .,coo:.
```


虽然有 linux 的 home server, 不过, 
一个小工具,能在本地编译出来发布二进制执行文件多好?


## goal

从本地同时可以 cargo build 出来两个主要场景的成品:


- macOS arm64 
- Ubuntu 18.04.6 LTS (GNU/Linux 4.15.0-175-generic x86_64) 类似 LTS 目标环境


## trace

没办法简单的成功, 还是用真机或是对应专用编译 Docker 来完成吧...

### abrew
> arm 版本 brew

    $ abrew install FiloSottile/musl-cross/musl-cross

引发一系列手工安装:

- abrew install --build-from-source gnu-sed
- abrew install --build-from-source lzip
- abrew install --build-from-source make
- ...

![](https://ipic.zoomquiet.top/2023-02-26-zshot%202023-02-26%2015.22.58.jpg)

```
...
==> /opt/homebrew/opt/make/bin/gmake install TARGET=x86_64-linux-musl
🍺  /opt/homebrew/Cellar/musl-cross/0.9.9_1: 1,851 files, 215.8MB, built in 5 minutes 35 seconds
==> Running `brew cleanup musl-cross`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
```

对应 Cargo.toml 中追加:
```
...
[target.x86_64-unknown-linux-musl]
linker = "/opt/homebrew/Cellar/musl-cross/0.9.9_1/bin/x86_64-linux-musl-gcc"

```

尝试编译:

    $ cargo build --target x86_64-unknown-linux-musl

然后:
```
...
Some errors have detailed explanations: E0405, E0408, E0412, E0416, E0425, E0433, E0463, E0531.
error: could not compile `regex-syntax` due to 990 previous errors
```

折腾出 900+ 错误...败退...




## refer.
> 关键参考

[Cross-compilation in Rust](https://kerkour.com/rust-cross-compilation)

- M1 macOS host:
    - [macos - How can I cross compile Rust code into Intel assembly on an ARM M1 Apple Silicon Mac? - Stack Overflow](https://stackoverflow.com/questions/68139162/how-can-i-cross-compile-rust-code-into-intel-assembly-on-an-arm-m1-apple-silicon)
    - [M1 Users - How are you Cross Compiling? : rust](https://www.reddit.com/topics/a-1/)
    - [Cross-compiling Rust From Mac to Linux | by Merlin Fuchs | Better Programming](https://levelup.gitconnected.com/bash-vs-python-for-modern-shell-scripting-c1d3d79c3622?source=read_next_recirc---two_column_layout_sidebar------3---------------------95f4769b_05fc_410f_a439_5b8e347b5325-------)
    - [Rust Development for the Raspberry Pi on Apple Silicon - Manuel Bernhardt](https://manuel.bernhardt.io/posts/2022-11-04-rust-development-for-the-raspberry-pi-on-apple-silicon/)
    - ...
- arm Linux host:
    - [Cross-compiling Rust from ARM to x86-64 | Bryan Burgers](https://burgers.io/cross-compile-rust-from-arm-to-x86-64)
    - ...
- [Cross Compiling Rust Code for Multiple Architectures | Docker](https://www.docker.com/blog/cross-compiling-rust-code-for-multiple-architectures/)


## logging
> 版本记要

- ..
- 230226 ZQ init.
