# Raspberry Pi Zero 2 w
> 最便宜的开发板了...

## background

Why not?

## goal

作为上位机和 Pico 连接起来折腾点儿事儿。。。

## trace

### HX1838
> ... 接入标准 HX1838 红外接收器的需求。需要使用 Rust 语言提供的 GPIO 库来控制 Raspberry Pi 的 GPIO 引脚，以及使用 Rust 的外部库来读取红外信号。具体的实现步骤如下：

1. 配置环境

首先需要安装 Rust 工具链，可以在 Raspberry Pi zero 2w 上使用以下命令进行安装：

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装完成后，需要安装对应的交叉编译工具链，以便于在 Raspberry Pi zero 2w 上编译 ARM 版本的代码。可以使用以下命令进行安装：

```
rustup target add armv7-unknown-linux-gnueabihf
```

2. 连接硬件

将 HX1838 红外接收器连接到 Raspberry Pi 的 GPIO 引脚上。可以参考 HX1838 的数据手册来确定连接方式。

3. 编写代码

首先需要导入 GPIO 库和外部库，可以在项目的 Cargo.toml 文件中添加以下依赖：

```
[dependencies]
rppal = "0.12.2"
rust-hx711 = "0.1.0"
```

然后编写 Rust 代码，示例代码如下：

```rust
use rppal::gpio::{Gpio, Level, Mode};
use rust_hx711::HX711;

fn main() {
    let gpio = Gpio::new().unwrap();
    let mut pin = gpio.get(17).unwrap().into_input_pullup();
    let mut hx711 = HX711::new(18, 27).unwrap();

    loop {
        if pin.read() == Level::Low {
            let reading = hx711.read().unwrap();
            println!("Reading: {}", reading);
        }
    }
}
```

代码中的 `gpio.get(17)` 表示通过 GPIO 引脚编号来获取 GPIO 对象，然后将其设置为输入模式，并开启上拉电阻。`HX711::new(18, 27)` 表示创建一个 HX711 对象，其中 18 和 27 分别表示 HX711 的 SCK 和 DT 引脚对应 Raspberry Pi 的 GPIO 引脚编号。

运行代码后，可以通过红外遥控器发送信号，然后在终端中可以看到将红外信号转换为数字的输出。

4. 编译代码

使用以下命令来编译代码：

```
cargo build --target=armv7-unknown-linux-gnueabihf
```

编译完成后，可以将生成的二进制文件拷贝到 Raspberry Pi zero 2w 上，然后在终端中运行即可。

## refer.
> 关键参考

选择困难? [Best Linux Operating Systems for the Raspberry Pi](https://www.electromaker.io/blog/article/12-best-linux-operating-systems-for-the-raspberry-pi)

-	[树莓派及其他硬件平台国内外Linux镜像站全汇总-阿里云开发者社区](http://segmentfault.com/a/1190000000503041)
    -	[Alpine Linux 安装到 Raspberry Pi - openthings的个人空间 - OSCHINA - 中文开源技术交流社区](https://my.oschina.net/u/2306127/blog/1587585)
-	Raspbian 派 ... 官方的总是有问题...虽然文档多, 毕竟不是专业 OS 发行商...
		53+ [ラズベリーパイ - YouTube](https://www.youtube.com/playlist?list=PLolGQZF-26atBkbYgFDm7z1o_B_eFy6eK) 系列
    + 	[Raspberry Pi Zero 2 W を使ってみる！セットアップ〜デスクトップとして使えるのかチェック - YouTube](https://www.youtube.com/watch?v=wSvMPMdJjXI)
+ ArchLinux 流... ..
    + [Arch compared to other distributions - ArchWiki](https://wiki.archlinux.org/title/arch_compared_to_other_distributions#See_also)
    + 	以往真没用过, 值得学...关键看镜像:
        + [镜像源 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/zh-hans/%E9%95%9C%E5%83%8F%E6%BA%90#%E5%8F%82%E8%A7%81)
        + 这里使用 `-n 6` 参数来实现只获取 6 个最快的镜像：
			    
```
    # rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
```

- [Arch Linux 更换国内镜像源](https://www.zzxworld.com/posts/change-cn-mirror-for-arch-linux)
    - [Arch Linux - Mirror Overview](https://archlinux.org/mirrors/)
    - [Arch Linux - aliyun.com - Mirror Details](https://archlinux.org/mirrors/aliyun.com/)
    - [archlinuxcn镜像_archlinuxcn下载地址_archlinuxcn安装教程-阿里巴巴开源镜像站](https://developer.aliyun.com/mirror/archlinuxcn/)
    - 好吧还是大厂的错误少...
- [Pacman — Cloud Atlas 0.1 文档](https://cloud-atlas.readthedocs.io/zh_CN/latest/linux/arch_linux/pacman.html)
    - 关键工具, 平替 apt
        - [pacman使用代理服务器 — Cloud Atlas 0.1 文档](https://cloud-atlas.readthedocs.io/zh_CN/latest/linux/arch_linux/pacman_proxy.html)
			...
安装指南:

- 官方: [Raspberry Pi Zero 2 | Arch Linux ARM](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-zero-2)
    - 全指令... fdisk 开始...
    - [在树莓派 Zero W 上安装 Arch Linux | 子飞的网络日志](https://chirsz.cc/blog/2020-09/install-archlinux-rp0w.html)
    - 关键笔记:
        - [Installing Arch Linux on Raspberry Pi with WiFi-only networking | Dollz'n'Codez](https://figuregeek.eu/linux/1732)
        - [Install Arch Linux ARM for Raspberry Pi Zero W on SD Card (with commands to configure WiFi before first boot).](https://gist.github.com/larsch/4a320f8ee5586fe6170af8051fcd9f85)
        - [Installing Arch Linux on Raspberry Pi with Immediate WiFi Access –](https://ladvien.com/installing-arch-linux-raspberry-pi-zero-w/)
        - [How To Install Arch Linux On A Raspberry Pi Zero W In Just A Few Minutes – Systran Box](https://www.systranbox.com/how-to-install-arch-linux-on-raspberry-pi-zero-w/)
        - [How to install Arch Linux ARM on a Raspberry Pi - YouTube](https://www.youtube.com/watch?v=TCfMr3vk6FU)
    - 相同过程...
        - 2022: [Installing Arch Linux On Raspberry Pi ProxMox - YouTube](https://www.youtube.com/watch?v=GvwD9pXYJi4)
            - 文字: [piprox-arch | Install notes for installing arch linux on pi proxmox](https://novaspirit.github.io/piprox-arch/)
        - ...
        - 2017: [Arch Linux for Raspberry Pi - YouTube](https://www.youtube.com/watch?v=28-oPIuz-G0)
            - 文字: [Installing Arch Linux on Raspberry Pi - Novaspirit](https://www.novaspirit.com/2017/04/25/installing-arch-linux-raspberry-pi/)
        - ...
        - 200+ [Raspberry Pi - YouTube](https://www.youtube.com/watch?v=qhe6KUw3D78&list=PL846hFPMqg3iTKbgQryS6UNXM4Nf3KVFw&pp=iAQB) 系列...
        - ...文字版: [Installing Arch Linux On Raspberry Pi ProxMox - Raspberry Pi Projects](https://raspberrypiprojects.com/installing-arch-linux-on-raspberry-pi-proxmox/)
        - 	...
        - ~~[How to Install Manjaro on Raspberry Pi? – RaspberryTips](https://raspberrytips.com/install-manjaro-raspberry-pi/)~~
            - 更加友好的界面...不过, 这个要先插好屏幕和键盘...
            - ...
- Manjaro ARM 版,专门适配有 #RaspberryPi
    - [The best 64 bit OS for Raspberry Pi: Manjaro KDE / XFCE (Full install guide / tutorial / review) - YouTube](https://www.youtube.com/watch?v=HwlM1Ws6KC8)
    - [How To Install Manjaro Arm On The Raspberry pi 1 2 3 Or Zero - YouTube](https://www.youtube.com/watch?v=u8vricJXVWQ)
        - ...只是省不掉人工配置过程?
- Ubuntu 派 ... 方便是方便...就太慢了...而且 IoT 相关文档还没 #RaspberryPi 全...
    - [Raspberry Pi OS vs Ubuntu](https://linuxhint.com/category/raspberry-pi/)
- BSD 派...否决, 驱动实在难
- ...



```
          _~∽--~_
      \/ /  ◶ ?  \ \/
        '_   ⌐   _'
        \ '--+--' |

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```