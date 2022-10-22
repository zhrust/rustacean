+++
title = "zola with hook"
description = "用Zola+hook 快速发布静态网站"
date = 2022-10-23
+++

## 体验 ZOla
> 叕一个 SSG 引擎

### background

开始折腾 Rust, 第一要着就是可以每天都开始使用...

### goal

用 rust 组织一个新笔记网站, 开始记录关键折腾

### trace

- 快速明确 Zola 最流行 SSG 发布 blog
- 先尝试 [zola.386 | Zola](https://www.getzola.org/themes/zola-386/) 很 COOL 但是, 每次都有奇怪的编译失败
- 回到 [Hook | Zola](https://www.getzola.org/themes/hook/) 简洁的 hook
- 就追加 utteranc.es 完成评注, 其它的不折腾...


唯一技巧:

- 要在 Environments 中合理配置 TOKEN
- 神奇的是, 这事儿, 无论什么文章都说的简单无比, 可其实, 要在几个 settings 中折腾一下:
    - 首先:
    - 然后:
    - 其次:
    - 最后:
    - ...好吧, 这种关系也只能习惯就好...

### refer.

- SSG:[Static Site Generators - Top Open Source SSGs | Jamstack](https://jamstack.org/generators/)
    - [mdBook | Jamstack](https://jamstack.org/generators/mdbook/)
        - [rust-lang/mdBook: Create book from markdown files. Like Gitbook but implemented in Rust](https://github.com/rust-lang/mdBook)
        - [Creating a Book - mdBook Documentation](https://rust-lang.github.io/mdBook/guide/creating.html#anatomy-of-a-book)
    - [Zola | Jamstack](https://jamstack.org/generators/zola/)
        - [Zola](https://www.getzola.org/)
        - [Themes | Zola](https://www.getzola.org/themes/anatole-zola/)
            - [zola.386 | Zola](https://www.getzola.org/themes/zola-386/)
            - [InputUsername/zola-hook: A clean and simple personal site/blog theme for the Zola static site generator](https://github.com/InputUsername/zola-hook/network/members)
            - [apollo | Zola](https://www.getzola.org/themes/apollo/)
            - ...
        - [Rust製の静的サイトジェネレーターZolaを試す – ハコイリオヤジ](https://hakoirioyaji.com/blog/rust-ssg-zola/)
        - [Zola Tutorial: How to use Zola the Rust based static site generator for your next small project, and deploy it on Netlify - DEV Community 👩‍💻👨‍💻](https://dev.to/davidedelpapa)
        - ...
- ...