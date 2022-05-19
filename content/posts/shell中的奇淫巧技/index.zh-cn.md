---
title: "Shell中的奇淫巧技"
date: 2022-05-07T21:33:59+08:00
draft: false
slug: 8ca21edd
---

## 前言

本文所有内容均在 bash 下进行，并且所说的 shell 都是指 bash，可能有一部分内容在 zsh 不起作用(不起作用时会指出) \
文中所用到的 a 目录内容如下

```
a
├── test1
│   ├── test3.txt
│   └── test4.txt
├── test2
│   ├── test5.txt
│   └── test6.txt
├── .what
└── .why
    ├── .emmm
    └── emmm
```

并且其中尽可能是 shell 的功能，而非某一个软件包所实现的功能

## 奇淫巧技

### 模式扩展

不使用 `pwd` 该如何获取当前所在目录呢，方法很多

1. 使用 `$PWD` 变量[^1]
2. 使用 `dirname $(readlink -f $0)` 这样的神奇的指令[^2]
3. 使用 `readlink -f .` 等等[^3]

[^1]: $PWD 永远指向当前目录，但 pwd 指令并不是单纯的输出 $PWD 变量.
[^2]: $0 表示的是当前所使用的 shell 的可执行文件位置，但在 bash 中如果用 `readlink -f` 去读却会得到 `$PWD/bash`.
但在 zsh 中会指向类似于 `/usr/bin/zsh` 这样的位置，取决于所使用的操作系统。
[^3]: 每个目录都有两个特殊目录 . 和 ..，这也是为什么 `cd ..` 这样的指令能工作的原因.

但是更加罕见的是 `echo ~+` 这种形式 \
实际上这是 shell 的模式扩展（globbing），`~+` 默认扩展成当前目录，类似例子还有很多 \
`~username` 扩展成 username 用户的主目录. 为空则默认为当前用户，这就是为什么 `~` 表示当前用户的主目录了 \
众所周知 `*` 可以匹配除了点以外的任意字符多次，实际上开启一个参数后点也可以匹配到，比如

```
what@DESKTOP-EQ0RG58:~/a$ ls *
test1:
test3.txt  test4.txt

test2:
test5.txt  test6.txt
what@DESKTOP-EQ0RG58:~/a$ shopt -s dotglob
what@DESKTOP-EQ0RG58:~/a$ ls *
.what

test1:
test3.txt  test4.txt

test2:
test5.txt  test6.txt

.why:
emmm
```

`{} []` 这些东西可以匹配字符，实际上开启了 `extglob` 之后还可以设置匹配的次数

### $_ 与 :

bash圣经中的第一个代码示例如下:

```bash
trim_string() {
    # Usage: trim_string "   example   string    "
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}
```

好家伙，一大堆的符号，但细看之下除了 `:` 与 `$_`，其他的都是对字符串进行操作 \
`:` 表示的是不输出，将指令执行的结果不输出，存起来和`&`有点类似，不过它是完全不输出（stderr我不知道会不会输出），
而 `&` 还是会输出命令完成之类的 \
另外，`&` 准确来说是放到后台执行，而 `:` 就是直接执行 \
`$_` 和其他脚本语言（ python 之类的）类似，表示上一个指令执行的结果[^4] \
然后通过这两个东西就可以写出一些令人费解的代码，比如

[^4]: 在诸如 python 的脚本语言中，`$_` 实际上是上一个表达式的值

```bash
Ծ‸Ծ(){
    sleep 0.1
    printf '\e[15D'
    printf "\e[38;5;$2m"
    printf $1
    : "${_:0-1:1}""${_:0:14}"
    if [[ $2 -eq 256 ]]
    then Ծ‸Ծ $_ 1
    else Ծ‸Ծ $_ $[$2 + 1]
    fi
}
printf '\e[?25l'
: echo $(echo "4KLIDYUWQLRJNA7CS2COFFUF4KLINYUWQ7RJNCHCS2D6FFUG4KLILYUWQTRJNA7CS2BOFFUBBI======" | base32 -d)
Ծ‸Ծ $_ 1
```

实际上也比较好懂，就是类似于 `\e[?25l` 有些令人迷惑，这些是终端控制符.

### 终端控制符

终端控制符与 shell 无关，能否显示与所使用的终端. \
大部分终端控制符在 bash 中的转义字符如下:

|操作|说明|
|-----|------|
|\e[38;5;<0-255>m	       | 设置文字颜色，256色                         |
|\e[48;5;<0-255>m	       | 设置背景色，256色                           |
|\e[38;2;[R];[G];[B]m      | 设置文字颜色，RGB	                         |
|\e[48;2;[R];[G];[B]m      | 设置背景颜色，RGB	                         |
|\e[m	                   | 恢复默认的颜色                              |
|\e[1m	                   | 加粗                                      |
|\e[2m	                   | 亮度减半                                   |
|\e[3m	                   | 斜体                                      |
|\e[4m	                   | 带下划线                                   |
|\e[5m	                   | Blinking 看起来就是加粗，我不清楚，翻译是闪烁   |
|\e[7m	                   | 背景变白 (高亮)                             |
|\e[8m	                   | 隐形，所有输出都会隐形！                      |
|\e[9m	                   | 带删除线                                   |
|\e[[y];[x]H               | 将光标移动到指定行列，缺省为当前值             |
|\e[H	                   | 将光标移动到 (0，0)	                     |
|\e[xA	                   | 将光标上移 x 行，缺省为1                     |
|\e[xB	                   | 将光标下移 x 行，缺省为1                     |
|\e[xC	                   | 将光标右移 x 行，缺省为1                     |
|\e[xD	                   | 将光标左移 x 行，缺省为1                     |
|\e[s	                   | 保存光标位置	                             |
|\e[u	                   | 恢复光标位置	                             |
|\e[K	                   | 将光标到行尾的所有内容擦除                    |
|\e[1K	                   | 擦除光标到行首的全部内容                      |
|\e[2K	                   | 擦除光标所在行的全部内容                      |
|\e[J	                   | 擦除光标所在行到屏幕底端的全部内容              |
|\e[1J	                   | 擦除光标所在行到屏幕顶端的全部内容              |
|\e[2J	                   | 擦除屏幕                                    |
|\e[2J\e[H	               | 擦除屏幕并且将光标移动到 (0，0)                |
|\e7                       | 保存光标位置                                 |
|\e8                       | 恢复光标位置                                 |
|\e[6n                     | 获取光标位置                                 |
|\e[?25l                   | 隐藏光标                                    |
|\e[?25h                   | 让光标显示出来                               |
|\e[?7l                    | 开启不折行，即字符会出现在屏幕外                |
|\e[?7h                    | 开启折行，当前行放不下时会放到下一行             |
|\e[[a];[b]r               | 限制只能在 a 行到 b 行滚动（很好玩，自己去试试）  |
|\e[?1049h                 | 保存整个屏幕的所有字符                        |
|\e[?1049l                 | 恢复用上一条指令保存的东西                     |

{{< notice tip >}}
假如使用 echo 输出，那么需要开启 -e 参数，默认不会转义字符. \
使用 printf 输出，则不需要，默认会转义字符. \
其他的诸如 tput 需要自行测试
{{< /notice >}}

### !

! 可以算是相当冷门了，但这个东西相当好玩，不妨试试以下指令

```bash
echo !#
echo !!
```

不出所料的话，应该是这样的输出

```
what@DESKTOP-EQ0RG58:~/myblog$ echo !#
echo echo
echo
what@DESKTOP-EQ0RG58:~/myblog$ echo !!
echo echo echo
echo echo
```

是不是很神奇，这里包含了一个冷知识，也就是`!`开头的特殊变量（我把这东西称作变量应该是可以的）

```bash
# 摘抄自 https://github.com/skywind3000/awesome-cheatsheets/blob/master/languages/bash.sh
!!                  # 上一条命令
!^                  # 上一条命令的第一个单词
!:n                 # 上一条命令的第n个单词
!:n-$               # 上一条命令的第n个单词到最后一个单词
!$                  # 上一条命令的最后一个单词
!-n:$               # 上n条命令的最后一个单词
!string             # 最近一条包含string的命令
!^string1^string2   # 最近一条包含string1的命令， 快速替换string1为string2
!#                  # 本条命令之前所有的输入内容
!#:n                # 本条命令之前的第n个单词， 快速备份cp /etc/passwd !#:1.bak
```

### 转义

`echo -e` 可以开启输出转义，实际上另外一种方法却也是可以奏效的，那便是 `echo $'内容'` 这样的形式 \
举个例子 `echo -e "\e[38;5;50m what's this"` 等价于 `echo $'\e[38;5;50m what\'s this'` \
输出的都是一个蓝绿色的 `what's it`，显然后者写到脚本里更令人费解

{{< notice wraning >}}
不可以使用 $"s" 代替 $'s' ，此处单双引号不等价.
{{< /notice >}}

### trap

`trap` 在接收到指定的信号时，就会执行指定的指令 \
首先 `trap -l` 可以看到所有信号

```
what@DESKTOP-EQ0RG58 ~/myblog> trap --list-signals
HUP INT QUIT ILL TRAP ABRT BUS FPE KILL USR1 SEGV USR2 PIPE ALRM TERM STKFLT
CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM PROF WINCH POLL PWR SYS
```

其中 `INT` 表示 ctrl + c 时产生的信号，也可写成 SIGINT \
EXIT 不管怎么样，只要退出就会产生 \
那么搞事情的机会就来了，在脚本第一行加入如下指令，使用者不仅无法退出，还会在试图退出时看到"略略略":)

```bash
trap "echo '略略略';bash $0" EXIT
```

### LINENO

这个东西十分神奇，它的值为脚本执行时，该条指令所在的行号 \
比如一个脚本的内容如下:

```bash
a=123
b=456
echo $LINENO
```

不出所料输出为 3 \
另外，有趣的是，在 REPL 环境中，也就是平时使用的命令行中这个变量也是存在的

## 实用技巧

### 快速编辑指令

这个并不属于 bash 特有的，但也一并放在这里.

在敲指令的时候，有时候会发现忘记加 sudo 或者又是少了一个参数，但此时指令很长，按方向左键简直费时费力. \
那有没有好办法快速跳转到行首呢？ \
当然有，按 ctrl a 就可以直接将光标放到行首， ctrl e 到行尾. \
除此之外，还有很多快捷键可以使用，比如 ctrl 删除键 会以单词为单位删除. \
至于其他的，实在是不太常用，可能不同的终端程序支持也不同，但这三个基本上都是支持的.

### 目录记录

`cd -` 是个非常厉害的指令，它的作用是退回你之前所在的目录

{{< notice tip >}}
等价于 `cd $OLDPWD`，但对 $OLDPWD 赋值并不会影响 `cd -`
{{< /notice >}}

对于 `cd -` ，只能回到上一次所在的目录，想要 bash 记录更多目录，可以使用 `pushd` 和 `popd`.

### 快速文件操作

有时候文件位于很深层的目录，这时候想去重命名的时候就显得非常麻烦了，指令大概类似于这样:

```bash
mv content/post/abc/img/xyz.png content/post/abc/img/abc.png
```

需要敲两遍路径，费时又费力. \
利用 `cd -` 固然可以很快解决，但未免显得相当奇怪. \
更好的解决办法:

```bash
mv content/post/abc/img/{xyz,abc}.png
```

当然，同样的方法可以利用在复制文件，修改后缀等等这些操作上，非常快.

### 强制写入

有时会遇到这样奇怪的情况:

```
what@DESKTOP-EQ0RG58:~/myblog$ echo m > test.txt
bash: test.txt: cannot overwrite existing file
```

实际上这是因为开启了 noclobber 的缘故（默认是关闭的，但可能有些脚本开启了它） \
我们固然可以关掉它，实际上还有一种解决方法，即使用 >| \
它们之间唯一的区别就是你有权写入该文件的情况下， >| 一定会写入，不管设置了什么

### 读取 read 结果

写 bash 脚本时，read 是很常用的指令. \
但 read 有个极大的限制--会默认按照 $IFS 分割 \
实际上非常有用的是 $REPLY 这个环境变量，它默认是上一次 read 所读取到的所有东西 \
so，你可以按照你的想法来处理它而不是单一的靠 $IFS 之类的

### shift

写脚本时，处理参数有时候是件麻烦事，但所幸 shift 这个时候显得非常有用.

```bash
shift
echo $@
```

写入任意一个文件中，传入任意个参数，却只能得到除了第一个参数以外的所有参数，这是因为 `shift` 将原来的 $1 移除了，而原来的 $2 就成了 $1 \
这样就可以处理完一个参数，然后 `shift` 掉，接着处理子参数， `shift` 掉...

{{< notice tip >}}
shift 可以多次调用，每次都是移除一个参数，也可以传入一个数字，控制移除的参数个数.
{{< /notice >}}

### \>\>>

日常使用中，很多都只是一个字符串，而有时候某个指令的参数是文件名，这种情况下该怎么办？ \
将字符串写入文件再进行操作？这样好麻烦啊，实际上不用担心，因为有 <<< \
拿 md5sum 来说，它接受文件名作为参数，实际上使用 `md5sum <<< string` 即可

{{< notice tip >}}
`echo "string" | md5sum` 也是一样的，还更加实用一些(不用思考)
{{< /notice >}}

### 参数终止

当目录下有个名为 -l 的目录时应该如何输出 -l 目录下的文件？ \
直接 `ls -l` 肯定是不行的，-l 会被当成是参数而非目标目录，那么试试如下代码呢:

```bash
a='-l'
ls $a
```

事实上这种办法看起来没问题，但其实还是不行. 难道是没有办法输出 -l 目录下的文件的办法吗？ \
非也，这里有一种参数终止的方法，其实说是参数终止并不完全正确，毕竟目标目录也是参数，不深究的话也无所谓. \
使用 `ls -- -l` 就可以输出 -l 目录下的内容了.

{{< notice tip >}}
这个例子可能并不好，毕竟使用 `ls ./-l` 就好了. 但在其他情况下，会有用到的时候，比如目标不是一个文件. \
-\- 对 echo 无效
{{< /notice >}}

### 快速上一条指令

使用方向键来填充上一条指令是不错的选择。\
拥有同样效果的还有 !! 和 r，使用起来也很方便。 \
比如:
```bash
apt install vim # wrong! 非 root 用户无权执行
sudo !! # fine! 等价于 sudo apt install vim
```

{{< notice tip >}}
r 不可以在 sudo 下使用，这也很合理，避免误操作。 \
假如觉得方向键太远了可以使用。
{{< /notice >}}

### 清除屏幕

`clear` 是个不错的选择，但或许用快捷键 ctrl + l 会更快

### 不匹配文件

有时候操作文件，跳过一些文件而不是选择一些文件可能更好，比如:
```bash
rm !(*.md|*.jpeg|*.jpg|*.png)
```
删除所有除了以 md, jpeg, jpg, png 结尾以外的所有文件

## just for fun

这里收集了一些好玩的，只是非常非常非常小的一部分，很多惊艳到我的都没记录下来。\
这里记录的只是写此文时手机便签里留着的。

### 笑脸

输出所有的笑脸 [author: ichbins](https://www.commandlinefu.com/commands/by/ichbins)
```bash
printf "$(awk 'BEGIN{c=127;while(c++<191){printf("\xf0\x9f\x98\\%s",sprintf("%o",c));}}')"
```
原理是输出 "\xf0\x9f\x98\x80"(😀) 到 "\xf0\x9f\x98\xbe"(😾)。并用 awk 简化了一下，写成单行。

### 进度条

彩色进度条 [author: me](https://blog.nidhoggfgg.fun)
```bash
Ծ‸Ծ(){ sleep 0.1;printf '\e[15D';printf "\e[38;5;$2m";printf $1;: "${_:0-1:1}""${_:0:14}"; if [[ $2 -eq 256 ]]; then Ծ‸Ծ $_ 1; else Ծ‸Ծ $_ $[$2 + 1]; fi; }; printf '\e[?25l'; : echo  $(echo "4KLIDYUWQLRJNA7CS2COFFUF4KLINYUWQ7RJNCHCS2D6FFUG4KLILYUWQTRJNA7CS2BOFFUBBI======" | base32 -d);Ծ‸Ծ $_ 1
```
高中时无聊写的，逻辑上简单，但混淆上还是有一点功夫的。需要知道 [$_ 和 :]({{< ref "#_-与-" >}}) \
这个实现确实过长了，还有很多很多很短的好，好玩的

### 时钟

右上角时钟 [author: glaudiston](https://www.commandlinefu.com/commands/by/glaudiston)
```bash
while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-29));date;tput rc;done &
```
这个相当厉害了，在终端的右上角挂一个时钟，具体的什么样的，一试便知。同样的，还可以发挥想象挂些其他的东西上去！ \
但因为 UTC 的缘故，长度有变，更好的指令如下:
```bash
while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-36));date;tput rc;done &
```

### curl/telnet/ssh 合集

一般都是一些没事干的家伙，又有闲着的服务器(我也)跑了一些 http server 专供好玩

(awesome-console-services)[https://github.com/chubin/awesome-console-services] 收集了一大堆类似的，下面节选了一部分

#### 看天气

这个确实很惊艳了，主要是界面做得很好

```bash
curl wttr.in # 会自动获取地理位置
curl wttr.in/haikou # 指定城市，比如 haikou
curl v2.wttr.in # v2 版本，很像手机里的天气应用
```

#### 看动画

```bash
telnet towel.blinkenlights.nl # 星球大战
telnet rya.nc 1987 # 你被骗了
curl https://poptart.spinda.net # 彩虹猫
```

### 桌面环境

非常离谱了，主要是看起来不像是终端的低分辨率，以及居然有背景透明和背景模糊！
```bash
ssh vtm@netxs.online
```
ssh 连接之后可能会很卡，网络和服务器资源都占了点原因，可以去[仓库地址](https://github.com/netxs-group/VTM)看看，非常之惊艳
