---
title: "Firewalld快速上手"
date: 2022-05-18T23:59:57+08:00
draft: false
slug: da968c3a
---

## 为什么要使用防火墙

不管是个人的电脑还是服务器，防火墙都是很重要的一个部分。 \
尤其是现在 ipv6 逐渐地是使用广泛，个人的电脑或许不能往内网一放，谁都不能直接从公网攻击到。

就我所在的位置而言，三大运营商的流量都是可以走 ipv6 的，甚至拨号的时候也是默认启用 ipv6 的，这意味着只需要路由器开启就万事具备了。 \
内网现在也不是安全的，个人开发用的 linux 也是很有必要上防火墙的，更别提服务器了。

linux 上防火墙主要是 iptables 和 firewalld。 \
他们底层的后端，我没用过，但很显然没必要了解，又不是开发防火墙。 \
iptables 我没用过，但越来越多的发行版推荐使用 firewalld，那么用 firewalld 就好了，而且 firewalld 使用起来非常简单。

再者，开启防火墙并没有什么坏处，为什么不用呢。

## 启用启动

启用(开机启动)的话，一般都会带有 unit 文件了，只需要:
```bash
sudo systemctl enable firewalld
```

启动:
```
sudo systemctl start firewalld
```

启动之后，firewalld 就已经在工作了！这意味着，除了 22 号端口的 tcp 链接(sshd 服务的端口，默认启用)以外的所有端口不被允许访问。 \
至此已经足够安全了，毕竟都禁止了。但如果要跑一个 ftp 服务器什么的那么就需要一番配置了。

## firewalld 使用

firewalld 主要使用的指令就是 firewall-cmd。 \
firewall-cmd 必须以 root 权限运行，下文非必要时则省略了 sudo 或者 root 下运行。

### 区域(zone)

firewalld 将网络划分为不同的区域(zone)，不同的区域对应不同的规则，这是为了快速修改防火墙配置。 \
比如在外面连着公共的网络，这很显然内网是不可信的，应该修改到某个非常严格的配置。 \
而回到家，连着家里的网络，那么这个就相对可信，可以切换到到不那么严格的配置，这个时候只用切换一下 zone 就好了。

使用 `firewall-cmd --lis-all-zones` 可以查看所有的区域的所有配置。

使用 `firewall-cmd --info-zone=xxx` 或者 `firewall-cmd --list-all --zone=xxx` 可以查看 xxx 区域下的的防火墙配置。 \
输出大致如下:
```
$ sudo firewall-cmd --info-zone=public
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: wlp3s0
  sources:
  services: dhcpv6-client ssh
  ports: 22/tcp 8888/tcp 7777/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```
有很多内容，但大多是用不上的。 \
`public (active)` 表示的是目前 public 区域处于激活状态。 \
`services: dhcpv6-client ssh` 这个是默认的，默认启用 ssh 服务。 \
`interfaces: wlp3s0` 表示的是防火墙在 wlp3s0 这个网卡上，多个网卡的话可能需要注意一下。 \
`ports: 22/tcp 8888/tcp 7777/tcp` 则是开放的端口，这里开放了 22，8888，7777 端口的 tcp 连接。 \
其他的默认值都不用在意也不太需要修改，一般情况下用不到。

使用 `firewall-cmd --set-default-zone=xxx` 可以设置默认的区域。

{{< notice warning >}}
在 [arch wiki](https://wiki.archlinux.org/title/Firewalld_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)) 上说此指令做出的改变是临时的，但我在 arch 上使用时其实是立即生效并且重启有效，也就是永久有效。 \
我尝试过 --reload 和重启服务两种重载，都是生效的，所以谨慎使用。
{{< /notice >}}

使用 `firewall-cmd --get-default-zone` 可以获取默认的区域。

使用 `firewall-cmd --zone=xxx --change-interface=xxx` 切换激活区域，立即生效，重启失效。

### 端口配置

用 firewalld 来配置端口是否允许进出是非常简单的。

添加端口:
```bash
firewall-cmd --add-port=a/b # 允许 a 端口 b 协议
```
其中 b 协议大多数时候是 tcp 或者 udp，毕竟很多常用的协议基于这两个。 \
比如http 基于 tcp，所以允许 http，允许 tcp 就好了

查看端口:
```bash
firewall-cmd --list-ports
```

删除端口:
```bash
firewall-cmd --remove-port=a/b
```

添加和删除都是立即执行的，重启失效，想要永久生效则加上 `--permanent`。 \
但加上 `--permanent` 之后是不会立即生效的，需要重新加载一下，使用 `firewall-cmd --reload`就好了。

另外，默认这些指令都是作用于默认区域而不是当前激活的区域，可以使用 `--zone=xxx` 指定作用的区域。

### 服务

服务就是预配置的一系列端口配置。比如 public 区域默认就启用了 ssh 服务。

查看所有可用的服务:
```bash
firewall-cmd --services
```

添加服务:
```bash
firewall-cmd --add-service=xxx
```

删除服务:
```bash
firewall-cmd --remove-service=xxx
```

其余的同上述端口部分内容。

### 其他

#### 应急

有时候会有突发情况，不能关机，但想拒绝所有流量，一个一个 remove 是很慢的，可能耽误了。 \
开启应急模式:
```bash
firewall-cmd --panic-on
```
此时会禁止所有流量，就连 ssh 也不例外，慎用。 \
关闭应急模式:
```bash
firewall-cmd --panic-off
```
