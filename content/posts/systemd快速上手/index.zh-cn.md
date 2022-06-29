---
title: "Systemd 快速上手"
date: 2022-05-18T23:59:44+08:00
draft: true
lastmod: 2022-06-29
slug: 1c920dec
---

## 使用 systemd 的理由

随着 systemd 生态越来越大，越来越多的 linux 发行版将 systemd 作为服务管理器，学习和使用 systemd 显得非常有必要了。况且 systemd 确实非常好用。

对于一般人来说，systemd 主要是用来管理一些服务(service)。比如 mariadb 服务或者自己编写的 http server。同时还要保证这些服务在正确启动、失败重启等等。
可能守护进程这个词会更加的常见一些，但实际上没什么区别，都是保证程序一直运行，失败重启。

固然，对于简单的情况，比如一个简单的 python 脚本，利用诸如 tmux 之类的也可以做到类似的效果。 \
但对于 mariadb 这种要求稳定、开机自启[^6]等的，就不太合适了，况且还有 NetworkManager、ufw 等一大堆的程序有着同样的要求，那么一个强大的服务管理程序就非常必要了

[^1]: 当然有很多奇淫巧技同样可以只用 shell 做到，比如写到 .bashrc 里利用 `&` 或者 `：` 抑制输出，接着一直检测进程。但这同样有一大堆问题: 只有在启动 bash 之后才会启动、进程检测麻烦、输出并不会完全抑制、关闭重启等麻烦......

systemd 虽不能说完美，但已经相当不错了，假如只是使用，简直就是简单到了极点，几条指令罢了。

所以，使用 systemd 吧，有时候甚至是没有选择的，因为目前看来完全没有可以竞争的产品。

## systemctl 简单了解

systemd 最主要的指令是 `systemctl`，其他的我个人是不用的，官方的文档或者网上其他的文档对其他的指令会有介绍。 \
systemctl 用于管理系统，关机重启休眠管理 cpu 等等，当然最重要的还是管理我们的服务。

查看版本号:
```bash
$ systemctl --version
systemd 251 (251.2-3-manjaro)
+PAM +AUDIT -SELINUX -APPARMOR -IMA +SMACK +SECCOMP +GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 -PWQUALITY +P11KIT -QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD -BPF_FRAMEWORK +XKBCOMMON +UTMP -SYSVINIT default-hierarchy=unified
```
输出会有很多，但底下的应该是一些编译时启用或者没有启用的特性，类似于 neovim 的那些特性，不必在乎。正常的输出证明着 systemctl 是可用的。

## 服务

对于一般的使用者来说，用得最多的应该就是启动一个服务了。比如启动 docker 这种。 \
在安装了 docker 和 systemd 之后，一般就可以通过以下指令启动
