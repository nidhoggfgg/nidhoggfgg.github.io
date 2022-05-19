---
title: "Systemd快速上手"
date: 2022-05-18T23:59:44+08:00
draft: true
slug: 1c920dec
---

## 初识 systemd

用 linux，看各种文档，教程的时候，比如类似于在《linux 上运行 mysql》这种，往往会看到:
```bash
sudo systemctl start xxx
```
这个 systemctl 是何方神圣，为什么频繁的出现。

其实 systemctl 就是 systemd 主要的命令，用于管理系统，比如:
```bash
sudo systemctl reboot # 重启系统
```
这看起来有点愚蠢，毕竟`sudo reboot`就好了，为什么需要 systemctl。 \
这个倒是确实，但 systemctl 的功能可远不止这些。



## 后记 --个人对 systemd 的看法

说实在的，我接触 unix 系的时间并不算很长，大概也就 5 年吧，所以对于 init.d 了解非常浅。
因此，仅仅只是对 systemd 的看法，而非一些比较什么的。

首先是作为一个使用者，我可以算是完完全全的受益者，无需写任何的 unit 就能享受 systemd 带来的便利。
几乎主流的发行版都采用了 systemd，并且主要的使用的 mysql，postgresql 这种软件包里也已经带有了 unit。
可以说是，除了 enable 和 start 啥也不用管。
因此我对 systemd 是看好的，用起来很爽，非常爽。

但也有些不好的地方：
1. 生态太大了
2. unit 的编写真是一言难尽
3. 出问题的时候，日志是真垃圾

生态太大了有时候是一个很大的缺点，因为这会半强迫用户用他们的东西。\
甚至更盛，搜索的内容全是 systemd，想找点其他的都找不到。 \
systemd 用起来爽，但自己写 unit 是真的不爽，写个能用的 unit 当然容易，当有目录保护这样的需求的时候也还算好。
但有时候有些得深入了解才能搞定就显得很麻烦了。 \
日志很垃圾，这没得说，journalctl 是真不行，但也可能是我不会用，但我个人而言体验极差。
三四次服务挂掉的时候，都是自己去看 unit 才解决问题。

至于其他人所说的，作者写 systemd 初期的时候 bug 一大堆，经验不够丰富，全是抄袭什么的。\
但说实在的，有几个人能像 linus 那样呢，不必过于苛责。

总的来说，systemd 瑕不掩瑜，爽就完事了。
