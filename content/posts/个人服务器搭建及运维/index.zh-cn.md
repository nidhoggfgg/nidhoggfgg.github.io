---
title: "个人服务器搭建及运维"
date: 2022-05-14T21:21:41+08:00
draft: true
slug: e23b41ce
---

作为一个计算机系的学生，拥有自己的服务器是一件很常见的事。 \
但服务器的性能，安全等等各方面都需要自己来考虑，非专业的情况下，道路总有些曲折。 \
以下便记录了我个人服务器(主机放在宿舍)的搭建

{{< notice tip >}}
购买的云主机的那些什么的大同小异。
{{< /notice >}}

## 系统选择

我个人选择的是 arch 作为服务器。arch 实际上并没有想象中那么容易挂，一不小心就滚挂这种。 \
实际上我个人从使用 arch 系的发行版开始就没有主用过其他的，其他发行版作为我个人使用的系统来说总是差点意思。\
并且至今没有哪怕一次滚挂过。

ubuntu server 也是一个不错的选择，并且购买的云主机基本上都可以选 ubuntu 作为系统。\
windows 作为服务器的话，只能说是下下策，麻烦不说，内存占用什么的也完全比不了。(arch 开机仅占用 100M 左右内存)

更关键的，我个人搭建的服务器不单单是生产服务器(有时候挂些好玩的给别人玩)，也是我开发用的服务器，这时候 arch 就非常好用了。

## 网络

主机放在宿舍，首要的解决的就是网络问题。 \
假如是买的云主机则就没这么多烦恼了，但同样的，云主机的带宽可就差远了(有钱买贵的当我没说) \
想要外网访问，方式多种多样: 内网穿透，问要到公网 ipv4，ipv6... \
我个人的选择自然是 ipv6。 \
内网穿透我没有自建的在公网的服务器，只能依赖他人，不行。 \
向运营商申请公网 ipv4，不想求人，不行。 \
于是最佳方案便是 ipv6 了。

实际上 ipv6 并没有那么糟，在我所在的地区，三大运营商的流量都可以走 ipv6。
这意味着我手机开着流量便可以随时随地连上我的服务器，其他人也可以用流量访问我的服务器。

## 防火墙

搭建服务器第一件事便是搞好防火墙，重中之重，安全摆在第一位。 \
尤其是使用 ipv6，这意味着主机完全暴露在公网之上，而不是类似于端口转发这种路由器已经过滤掉端口了。

防火墙，没选择 iptables，选择的是更加现代的 firewalld，虽然它们可以一起工作，但我认为 firewalld 已经足够了。

在 arch 上最舒心的莫过于，软件包能带上 systemd 的就带上了 systemd (关于 systemd 的介绍在下面) \
启用，激活:
```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

接着可以使用 `firewall-cmd` 操作了。

{{< notice tip >}}
`firewall-cmd` 必须要 root 权限执行，哪怕只是查看端口
{{< /notice >}}

firewalld 默认(public)禁用除了 ssh(22端口 tcp) 之外的所有端口。 \
这点其实是好评了，保证了安全，同时默认启用 22 端口，不会让使用者用 ssh 连接服务器安装一个防火墙导致自己被 ban 掉。 \
尤其是在开发环境下，开发环境经常跑各种各样的东西，很多都是不安全的，但有了防火墙，也变得足够安全了。

firewalld 是定义了几个规则集(zone)，像 public，work 等等，对应于不同网络环境 \
默认的是 public，禁用除 22/tcp 以外所有端口。\
可以使用 `firewall-cmd --list-all-zone` 查看所有 zone 的信息，后面有个(active)的就是当前在用的，比如:
```
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

在公网中不建议切换到其他的 zone，不安全。

管理端口更是简单，只是单单几条指令罢了:
```bash
# 查看所有允许的端口
firewall-cmd --list-port
# 比如
❯ sudo firewall-cmd --list-port
22/tcp 7777/tcp 8888/tcp
# 这里就启用了 22，7777，8888 的 tcp 出站流量

# 添加端口，立即生效，但 reload 之后失效
firewall-cmd --add-port=xxxx/xxx
# 比如
❯ sudo firewall-cmd --add-port=123/udp
success # success 表示成功了
❯ sudo firewall-cmd --list-port
22/tcp 7777/tcp 8888/tcp 123/udp # 成功添加了 123/udp

# 删除端口，立即生效，但 reload 之后失效
firewall-cmd --remove-port=xxxx/xxx
# 比如
❯ sudo firewall-cmd --remove-port=123/udp
success
❯ sudo firewall-cmd --list-port
22/tcp 7777/tcp 8888/tcp #成功删除了 123/udp

# 添加，删除端口，永久有效， reload 之后有效
firewall-cmd --add-port=xxxx/xxx --permanent
firewall-cmd --remove-port=xxxx/xxx --permanent

# reload
# 添加，删除永久有效的端口时，需要 reload 才能生效
firewall-cmd --reload
```

## systemd

systemd 只能说是太好用了，几乎无可挑剔。比起之前的 init.d 那玩意，简直是用了就绝不可能再回去了。

systemd 最简单的用法就是让一个服务开机自启了，比如开机自动启动一个 http 服务器。 \
而且足够好用，正常情况下都不用管。 \
更加舒心的是，像 mysql， postgre 这种数据库往往手动启动有点麻烦(为了保证安全，得用特定用户操作而不是 root 等等)。 \
固然，自己写一些 bash 脚本也可以做到，但谁来启动这些 bash 脚本，又怎么保证这些 bash 脚本正常工作呢。

关于 systemd 不必过多赘述，简简单单使用几次之后就简单明了了。 \
常用指令如下:
```bash
systemctl enable xxxx # 使 xxxx 开机自启，但不马上启动，需 root 权限
systemctl start xxxx # 使 xxxx 马上启动，需 root 权限
systemctl stop xxxx # 使 xxxx 马上停止，需 root 权限
systemctl restart xxxx # 使 xxxx 重启，需 root 权限
systemctl status xxxx # 查看 xxxx 的状态
systemctl daemon-reload # 重新加载 unit(下面会说)，需 root 权限
```

## docker

对于一些大型的项目，想要跑起来往往要自己配置一大堆环境，麻烦不说，在日常使用的开发环境搞，把开发环境搞得一团混乱。 \
而 docker 则很好地解决了这个问题，把项目和所需的环境打包在一起，不污染工作空间，也不用为了环境而头疼。 \
在个人服务器上还有一点很关键，后端跑在 docker 里，即使因为安全问题导致被黑了之类的，也不是直接攻击到系统，可以起到很好的保护作用。

{{< notice warning >}}
请勿按照其他的 blog 或者教程中所述，将常用用户添加到 docker 组！ \
任何加入到 docker 组的用户都和 root 用户等价，因为他们可以通过`# docker run --privileged`来以 root 权限启动容器！ \
一时的方便，会带来极大的隐患 \
未加入 docker 组的用户使用 docker 时请加 sudo
{{< /notice >}}

docker 的参数众多，一言难以蔽之，但常用的实际上很少。 \
对于仅仅只是使用 docker 而不用自己打包容器来说，docker 再简单不过了。

### 镜像

首先需要了解的是镜像(images)，至于更下面的层(layer)，只是使用 docker 跑点小玩意根本不用知道。 \
镜像就可以认为是系统一样，一般情况下是不能修改的，而要获取一个镜像也很简单。
```bash
docker search xxxx # 搜索 xxxx，stars 和 official 可以作为一个是否使用的参考依据
docker pull a/b:c # 抓取 a 作者下 b 镜像的 c 版本，c 缺省为 latest(即最新)
```
出现诸如`Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`这种，
是因为没有启动 docker 的守护进程，用 systemd 启动一下就好了。

也可以在 docker-hub 上找，可能会更好一些，有说明文档和详细详细。 \
至于换源，感觉没有必要，国内源大部分都是些常用的镜像，而且默认的感觉已经够快了，网上教程也很多。

想要查看操作镜像也很简单:
```bash
docker images # 查看所有本地的镜像
docker rmi IMAGE_ID # 删除镜像，image_id 可以通过上条指令看到，不必打全
```
其他的指令我用不上，一般也用不上，毕竟是只读的，除了获取和删除，还需要干点其他的吗

### 容器

有了镜像就可以跑容器(contianer)了，但注意，容器与镜像是不同的概念。 \
在容器内，是可以修改文件或者文件系统了，但一般不会影响到镜像。 \
一个镜像可以对应多个容器，意思是多个容器可以用一个镜像作为“系统”，但这些容器互不干涉 \
也很好理解，就像是虚拟机多开一样，开一大堆 ubuntu，但他们都用 ubuntu-20.04.iso 作为镜像

#### 启动容器

创造一个容器再简单不过了，只要:
```bash
docker run xxxx # xxx 是 image_id 或者 a/b:c 这种
```
注意，run 并不是启动一个容器，而是创造一个容器，名字有一点迷惑性，
这意味着两次`docker run a/b`会创造两个以 b 作为镜像的容器。\
至于启动，下文有述。

run 指令参数众多，也是唯一需要记的了，常用的参数如下:
```bash
-i # 交互模式，常与 -t 一起使用
-t # 进入 tty，简单说就是命令行，常与 -i 一起使用
-d # 后台运行
-p 1111:2222 # 将容器中的 2222 端口映射到本机的 1111 端口
--name xxxx # 给容器一个名字，方便后续操作
--rm # 容器退出时自动清理文件系统
```
还有其他用得上的，要用的时候再说。\
以下是几个例子(其中使用 area39/pikachu 镜像会开一个 80 端口)

启动一个 ubuntu，并以前台交互模式运行 \
因为 ubuntu 的启动命令是 bash，所以会进入命令行 \
因为没有指定名字，会生成一个类似于 determined_grothendieck 的名字，两个随机单词组成
```bash
docker run -it ubuntu
```

启动一个 ubuntu，并在退出的时候清理文件系统 \
也就是说在这个容器里建了目录或者写入了文件什么的在退出之后就被删了，类似于影子系统 \
多用于随手用用的时候，生产环境不建议，毕竟数据丢光实在承受不起
```bash
docker run --rm -it ubtuntu
```

后台运行，并把容器里的 80 号端口映射到本机的 8888 端口
```bash
docker run -d -p 8888:80 area39/pikachu
```

请勿使用以下指令！
```bash
docker run --rm -itd ubtuntu
docker run ubtuntu
docker run -it area39/pikachu
```
第一条 --rm 在 -d 启用的时候是不起作用的 \
第二条，因为 ubtuntu 的启动命令是 bash，不以交互模式启动会直接退出 \
第三条，因为启动脚本是一个自动安装 mysql，自动配置漏洞环境的脚本，而不是 prompt，交互模式只能干瞪眼看着输出，用 ctrl c 退出还会杀死容器内正在运行的进程

可以看出，前台还是后台，取决于运行的容器，这一般很容易判断。 \
跑个 ubuntu 那不就是要进命令行用嘛，前台 \
跑个 http server 进前台干什么？看 log 吗，后台 \
也可以跑去看文档

### 容器管理

启动容器之后，并不是就一劳永逸了，

## 文件服务器

## 反向代理

## jupyter
