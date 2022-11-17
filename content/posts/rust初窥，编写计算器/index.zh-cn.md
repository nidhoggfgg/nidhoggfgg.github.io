---
title: "Rust初窥，编写计算器"
date: 2022-10-13T10:08:58+08:00
draft: true
lastmod: 2022-10-13
slug: 948a5a4b
---

## 起因及前置知识

### 起因

看了一遍[《Rust 程序设计语言 中文版》](https://rustwiki.org/zh-CN/book/)，以及[《通过例子学 Rust 中文版》](https://rustwiki.org/zh-CN/rust-by-example/)之后，总想着写点小玩意。于是乎就写了相当多的小玩意，支持函数的计算器、终端绘图、密码生成器、盲水印、jpg/png 解析器等等[^1]。

[^1]: 绝大多数可以在 https://github.com/nidhoggfgg/for-beginners 找到

但都是相当早期的作品，随着我编写的 rust 代码越来越多，我对于各种情况的处理也越来越熟练。到了现在我已经没有什么所有权的概念，也能完成我想写的绝大多数程序。再回看以前那些代码，居然觉得还不错，每一个在设计上都极为简单，但很容易扩展。而我现在主手的项目[^2]，一开始我便抱有野心，设计上一开始便是要求尽善尽美，导致了处处受束。于是乎就重新开始了解以前的那些小项目，并扩充他们。

[^2]: https://github.com/fpig-lang/fpig

### 前置知识

1. 对 rust 有过了解即可，编写这些代码本就是练手
2. 有基本的查找资料的能力，方法函数等众多，不可能都解释一遍

在文章的第一部分会实现双栈求值，总代码不过 50 行，算法也极为简单。 \
第二部分，不得不涉及编译原理，但只会涉及两个最简单实用的算法 (诸如 GCC 也在使用！) \
并且会以好玩的方式介绍这些编译原理的内容

### 工作区

通过 `cargo new calculator` 创建项目，再在 src/ 下添加 lib.rs

编辑器建议 vscode+ra+lldb 或者 clion

## 初步了解计算器

计算器的概念比较广泛，从手机电脑自带的计算器应用到 Matlab、Wolfram Mathematica 等都可以叫做计算器，甚至一些其他领域，都有一些类似的概念。但这里所指的是可以计算数学表达式的计算器。

先从最简单的只支持四则运算计算器开始，想要实现能够计算加减乘除的计算器，还不算太难。

### 最直接简单地实现计算器

最简单的想法:

1. 将表达式按照 +-*/ 分割为一个只包含一个个值数组，以及将符号放入表中
2. 遍历符号表中的 */，相应地取出值数组中的值计算，再填回值数组相应的位置
3. 重复 2 步骤直到符号数组中没有 */
4. 遍历符号表中的 +-，相应地取出值数组中的值计算，再填回值数组相应的位置
5. 重复 2 步骤直到符号数组中没有 +-

对于这样简单的想法，但实现起来却有诸多难题，其中很容易发现:

以 6 * 7 + 8 为例，分割为 \
值数组: [6, 7, 8] \
符号表: { "\*": (0, 1), "+": (1, 2) } \
其中符号表中的 (0, 1)，(1, 2) 指的是操作的两个值在值数组中的位置 \
处理 "*" 之后: \
值数组: [42, 8] \
符号表: { "+": (1, 2) } \
可以发现，符号表已经和值数组不匹配了，"+" 应当是 (0, 1) \
当然，解决办法非常多，不增加时间复杂度也不难，亦或者稍微修改原算法。

但有一个致命缺陷，以符号划分对于 () 这种符号就难以处理，并且随着符号的增多，复杂度将会极大提升。于是只能另辟蹊径。

### 第一个可用的计算器，双栈求值

#### 双栈求值原理

学过最基本的算法的家伙可能会想到双栈求值，这确实也是一个不错的想法，也很值得实现。顺便说一下双栈求值。

双栈求值是 E.W.Dijkstra 发明的算法，Dijkstra 这个名字当然是如雷贯耳，但因为我不知道怎么念这个名字，所以我一直将 Dijkstra 双栈求值算法叫做双栈求值算法。 \
这个算法也极为简单，只有 4 条规则:

1. 将操作数压入操作数栈
2. 将运算符压入运算符栈
3. 忽略左括号
4. 遇到右括号时，弹出一个运算符，弹出所需数量的操作数，并将运算符和操作数的运算符结果压入操作数栈

比如 (1 + (2 * 3)) 计算过程如下:

1. 忽略 (
2. 将 1 压入操作数栈
3. 将 + 压入运算符栈
4. 忽略 (
5. 将 2 压入操作数栈
6. 将 * 压入运算符栈
7. 将 3 压入操作数栈
8. 弹出 2，3 以及 * 并计算 2 * 3 也就是 6，压入操作数栈
9. 弹出 6，1 以及 + 并计算 6 * 1 也就是 6，压入操作数栈

最终栈中只剩的 6 就是结果。

但不难看出，这个算法虽然是绝顶聪明的人创造的，但仍然有巨大缺陷:

1. 依靠 () 来确定运算顺序，所以 () 不可以省略
2. 读时计算

考虑到这个算法的重要性，以及这是一个相当不错的起点，下面会实现这个算法，之后便会提出一种尽善尽美的解决办法。

#### 双栈求值实现

在项目的根目录的 src 下新建 dj.rs 作为双栈求值的实现。并在 lib.rs 中写入如下一行以将 dj.rs 纳入模块树中:
```rust
pub mod dj;
```

接着在 dj.rs 中写入:
```rust
pub type Value = f64;

#[allow(unused)]
pub fn calc(expr: &str) -> Value {
    let values: Vec<Value> = Vec::new();
    let ops: Vec<char> = Vec::new();

    todo!()
}
```
还没有任何的逻辑，但稍后会逐步完善。 \
其中`#[allow(unused)]`是为了阻止编译器对于未使用`expr`的警告 \
`todo!()`则是一个宏，执行到这个宏会直接 panic 并且输出未实现的xxx的字样。同时也保证了虽然返回值是`Value`类型，但没有返回结果也不会报错。 \
`values` 和 `ops` 的类型说明，现在必须需要，但完成后面的代码之后就可以自动推导了，也就不需要了。

这里有几个设计上的选择:

1. 使用一个函数直接计算，而不是创建一个结构体并将计算的函数作为一个方法。一方面是因为读时计算，创建的结构体并没有什么大用，计算一个表达式便要重置或者新建结构体。另一方面是因为这是一个极小的程序，一个小的函数更为简单。
2. 创建了一个`f64`的别名，这其实算是对未来的一个打算，未来添加其他数据支持时，上层的应用仍然可用使用`Value`，只需要修改下层的代码即可。
3. `ops`中用的是`char`而非`String`，意味着只能存储单个字符，也就是说对于双阶乘这种符号是不行的，但这个程序只是一个开始并不是最终的算法。

还有一个 rust 上选择: \
参数类型选用`&str`而非`String`，这是初学者很容易疑惑的地方，尤其是这种情况，表达式计算完即可以丢弃，完全可以传入带有所有权的`String`。对于这个问题的讨论已经超过了本文的内容，但这里有两个最主要的点: 1.大家都这样写[^3] 2.`String`可以借用为`&str`，`str`也可以借用为`&str`，就算是自己实现的字符串类型也会第一时间支持引用为`&str`。于是`&str`可以兼容所有字符串类型。

[^3]: 这听起来或许有点荒谬，但不得不说，诸如左花括号的位置等这些问题都是类似的。看所在的社区，公司或者其他什么的规范。

接着实现对 (+-*/ 的逻辑代码。

```rust { hl_lines=["5-11"] }
pub fn calc(expr: &str) -> Value {
    let mut values: Vec<Value> = Vec::new();
    let mut ops: Vec<char> = Vec::new();

    for c in expr.chars() {
        match c {
            '(' => continue,
            a @ ('+' | '-' | '*' | '/') => ops.push(a),
            _ => todo!()
        }
    }

    todo!()
}
```

其中高亮行是新增内容，下文不再赘述。 \
其中`c @ ...`完全可以删掉`c @`，但这里其实只是说明 rust 有这个，体现 match 的强大。后文将会删去 \
由于是按照字符遍历，那么数值的处理，就稍微有点麻烦了:
```rust { hl_lines=[4, "7-9", 14] }
pub fn calc(expr: &str) -> Value {
    let mut values: Vec<Value> = Vec::new();
    let mut ops: Vec<char> = Vec::new();
    let mut tmp = String::new();

    for c in expr.chars() {
        if !matches!(c , '0'..='9' | '.') && !tmp.is_empty() {
            values.push(tmp.parse().unwrap());
            tmp.clear();
        }

        match c {
            '(' => continue,
            '+' | '-' | '*' | '/' => ops.push(c),
            '0'..='9' | '.' => tmp.push(c),
            _ => todo!()
        }
    }

    todo!()
}
```
非常值得一提的是这里使用了 unwrap 。假如说有什么在 rust 里被绝对的讨厌，那么大概只有 unsafe 和 unwrap 。
时至今日，我依然不知道为什么大家会如此讨厌 unwrap ，以至于写一个 unwrap 就好像是耻辱一样。
绝大多数的文章会反复不断地说 unwrap 是邪恶的，会使你的程序脆弱地如同纸一般，写了一个 unwrap 就等着别人嘲笑你吧。 \
但是，我个人来看，unwrap 在可以掌控的情况下是完全可以使用的！
甚至在研究 rust 本身的源代码时，也发现了相当多的 unwrap (大多在测试中，但也有一部分在编译器中)

但此处的代码并不完全可控，至少对于出现多个 '.' 的情况没有处理而导致 panic。
不过这只是一个简单的小小的双栈求值，这是可以允许的，在随后的最终实现中会消除这点。

最后，开始处理 )，也就是最终的求值过程:

```rust { hl_lines=["12-24", 29] }
// ...
    for c in expr.chars() {
        if !matches!(c , '0'..='9' | '.') && !tmp.is_empty() {
            values.push(tmp.parse().unwrap());
            tmp.clear();
        }

        match c {
            '(' => continue,
            '+' | '-' | '*' | '/' => ops.push(c),
            '0'..='9' | '.' => tmp.push(c),
            ')' => {
                let op = ops.pop().unwrap();
                let b = values.pop().unwrap();
                let a = values.pop().unwrap();
                let result = match op {
                    '+' => a + b,
                    '-' => a - b,
                    '*' => a * b,
                    '/' => a / b,
                    _ => panic!("can't resolve the op! internal error!")
                };
                values.push(result);
            }
            _ => todo!()
        }
    }

    values.pop().unwrap()
// ...
```

至此，双栈求值已经全部完成了。但是等等，输入中往往含有空格，tab或者换行等等。
手动过滤这些不是难事，不过可以从 rust 编译器的源代码中抄出一个所需的函数。

```rust { hl_lines=[3, "8-37"] }
// ...
        match c {
            c if is_whitespace(c) => continue,
            '(' => continue,
        // ...
        }
// ...

// copied from https://github.com/rust-lang/rust/compiler/rustc_lexer/src/lib.rs
fn is_whitespace(c: char) -> bool {
    // This is Pattern_White_Space.
    //
    // Note that this set is stable (ie, it doesn't change with different
    // Unicode versions), so it's ok to just hard-code the values.

    matches!(
        c,
        // Usual ASCII suspects
        '\u{0009}'   // \t
        | '\u{000A}' // \n
        | '\u{000B}' // vertical tab
        | '\u{000C}' // form feed
        | '\u{000D}' // \r
        | '\u{0020}' // space

        // NEXT LINE from latin1
        | '\u{0085}'

        // Bidi markers
        | '\u{200E}' // LEFT-TO-RIGHT MARK
        | '\u{200F}' // RIGHT-TO-LEFT MARK

        // Dedicated whitespace characters from Unicode
        | '\u{2028}' // LINE SEPARATOR
        | '\u{2029}' // PARAGRAPH SEPARATOR
    )
}
```

接着可以在 main.rs 中添加代码，调用此函数。替换 main.rs 的代码为:

```rust
use std::io::{self, Write};

use calculator::dj::calc;

fn main() {
    loop {
        // prompt
        print!(">>> ");
        io::stdout().flush().expect("flush error");

        let mut line = String::with_capacity(8);
        io::stdin().read_line(&mut line).expect("fail to read input");

        println!("{}", calc(&line));
    }
}
```

之后遍可以尝试允许我们的第一个计算器了。

```
$ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.01s
     Running `target/debug/calculator`
>>> 1.2 + 3.2) / 6.3) +4.1)*100.42)
481.85660317460315
>>>
```

非常顺利！结果也是对的，虽然还有诸多问题，也没有扩充四则运算之外的内容。
但这只是一个小小的 demo，一个很好的开始，接下来就是真正的强大的计算器了。

## ”完美“的计算器

之前实现的双栈求值的计算器，可以算是只有寥寥数行代码，能够计算四则运算甚至更多。 \
但是缺点也太过于明显：右括号无法省略。想要支持函数也是不可能（读时计算）。 \
我们想要编写的计算器可不是这么简单的，于是就需要更加强大的算法去应对更为复杂的问题

### 解析表达式的难题及编译器

想要执行表达式，最难的地方就在于解析表达式，一旦将表达式转化为某种易于计算的结构，那么求值变得无比简单 \
但是解析表达式有两个大的难题:

1. 正确地将字符组合成一个个有意义的”符号“。比如 "5+11"，"5" 是一个单独的符号，而不是 "5+" 是一个符号。同样的 "11" 是一个符号，而不是 "1" "1" 两个符号[^4]
2. 正确地处理优先级，比如 * 就比 + 优先级高，并正确组合起来[^5]

[^4]: 在编译器领域，一般叫做词法分析。顾名思义，就是将”字母“划分为”单词“
[^5]: 在编译器领域，一般叫做句法分析，也就是将”单词“组合成正确句子

这是两个难题，也是解析表达式的步骤。但似乎还找不到解决办法。
在几十年前，没有编译器的时代，那些试图解析表达式的家伙也遇到了这些问题。所幸，通过他们不断地思考，现在这两个问题已经相当好解决了。就像`E=mc²`这样简单，但想要发现却很难。

#### 贪吃小怪兽

为了解决第一个问题，那些聪明的家伙找到了许多聪明的算法，但其中我认为最简单也好用的就是用 DFA 来完成。 \
DFA 是 deterministic finite automaton 的简称，也就是确定有限状态机。 \
常规的关于状态机的文章，无一不充斥着专业术语，那未免太无趣了。 \
其实 DFA 根本不用去了解什么转换表啊什么的，正相反，了解 DFA 就像是在玩游戏一样。

现在有一个小游戏，游戏内容就是操作一只小怪兽去吃东西，但这个小怪兽有点奇怪:

1. 它只会吃一部分食物，并且根据之前吃过的食物决定
2. 假如吃到了不合适的食物，那么就会吐出之前吃过的食物

说是操作，其实也没有操作可言，就是看着这个小怪兽吃掉一个又一个食物

比如现在就有一个小怪兽，它吃了苹果之后只能吃香蕉，吃了香蕉之后只能吃梨子，吃了梨子之后什么都不能吃，吃了西瓜之后什么都不能吃。

现在有一堆食物，"西瓜-苹果-香蕉-梨子-苹果"。 \
假如来玩这个游戏的话，小怪兽会在吃了西瓜之后，吃苹果，吐出 "西瓜" \
吃了苹果香蕉梨子之后再吃苹果会吐出 "苹果香蕉梨子" \
最后吃下 "苹果"

这个小怪兽就可以算是一个 DFA，不严谨，但在此处已经足够说明它的能力了。 \
可以看出，小怪兽就是用来组合食物的，而在第一个难题中，就是组合字符为单词，两者是一样的 \
于是乎，只需要建立小怪兽的一个吃东西的规则，就能组合字符为单词了。

以数值为例，小怪兽首先可以吃"1-9"，接着可以无限制吃"0-9"，一旦途中遇到任何的其他字符，都会吐出 \
这就是一个可以解析数值的规则，当然，浮点数会复杂一些，也是可以解决的。 \
再以自定义标识符和关键字为例，这两者具有相似性，但其实不难。 \
首先建立一个关键字的表，然后建立小怪兽吃东西的规则: 首先可以吃 '_' 或者字母，接着可以吃数字、'\_'、字母，一旦吃到其他字符，就吐出。 \
最后在关键字表中查询是否是关键字就好了。

现在再看 rust 代码，就比如现在已经完成了的双栈求值计算器，想象自己就是小怪兽，去吃字符，接着吐出单词。 \
第一个难题就这样解决了

### 语法规则与抽象语法树

在上一节中，利用小怪兽，很轻易地解决了第一个问题，但对于第二个问题，就显得力不从心了。 \
最为简单的四则运算，利用小怪兽建立规则虽然可以得到一个长的正确的“句子”，但却没有正确地处理优先级。 \
于是就需要更加强大的小怪兽和更加强大的规则，能够生成类似于树之类的可以表示“深度”的结构 \
对于写一门语言或者计算器这种，建立规则并不难。

#### 语法规则

现在游戏开始变得复杂，游戏规则也需要以正式的形式书写一下了。小怪兽也升级为大怪兽了 \
对于吃食物的规则，以一些例子来说明:

1."规则名字" = 吃食物的顺序;
```
eat_ab = "a" "b";
```
即大怪兽吃了可以根据 eat_ab 这条规则，吃了 "a" 之后吃 "b"， ';' 代表终止，即接下来吃什么都会吐

2."a|b" 可以代表吃 a 也可以，吃 b 也可以
```
eat_aorb = "a" | "b";
```
吃 a 或者吃 b，接着终止

3."()" 代表优先处理
```
eat_aborc = "a" ("b" | "c");
```
可以吃 "ab" 也可以吃 "ac"，但不能吃 "abc" 或者 "bc"

4."*" 代表可以吃任意次
```
eat_ab = "a"* "b";
```
可以吃 "ab"，也可以吃 "aaaaaab"，也可以吃 "b"

5."?" 代表可选的（吃 0 次或者 1 次）
```
eat_ab = "a" "b"? "c"?;
```
可以吃 "a"，也可以吃 "ab"，也可以吃 "abc"，还可以吃 "ac"，但不可以没有 "a"

6.可以组合多条规则
```
eat = eat_ab eat_xy;
eat_ab = "a" "b"?;
eat_xy = "x"? "y";
```
其中的 eat 等价于 `eat = "a" "b"? "x"? "y";`

至此，就能够解析绝大多数语法了，以 rust 的 if 语句为例（不包含 if let）
```
if_stmt = "if" expr "{"
        stmt*
        expr?
    "}"
    elif*
    else?
elif = "else" "if" expr "{"
        stmt*
        expr?
    "}"
else = "else" "{"
        stmt*
        expr?
    "}"
stmt = ... 省略，即 rust 中的任何语句，稍微复杂，后文给出
expr = ... 省略，即 rust 中的任何表达式，稍微复杂，后文给出
```
这个并不固定，还可以写出其他的可以生成同样语法的语法规则。 \
另外，由于空格等空白符在 rust 中是无意义的，就忽略了。 \
这些语法规则能够正确地将“单词”组合成“句子”了，但是还不够，生成的”句子“中没有包含优先级。 \
于是大怪兽的输出也要做出相应的变化，树就是相当不错的结构。

#### 抽象语法树

对于四则运算，很容易建立如下打怪兽吃食物的规则:
```
expr = binary
    | group;
binary = number ("+" | "-" | "*" | "/") expr;
group = "(" expr ")";
number = ... 第一步中解析出来的包含数值的单词
```
可以处理无限的四则运算的组合以及括号，但是不能处理优先级。于是乎就需要能够表达“深度”的数据结构。 \
这个数据结构便是抽象语法树，“抽象”一词其实表达的是类似于最简化的意思，不是什么高大上的东西。 \
仍然是举例说明，比如对于 2 + 3 * 4 来说，对应的抽象语法树就是:
```
   +
  / \
 /   \
2     *
     / \
    /   \
   3     4
```
除了最简单的信息其他的都没有，就是抽象语法树。 \
至于如何从根据语法规则得到这样一颗抽象语法树，后文会说明

### 递归下降分析

由于在上述的 expr 语法规则中，四则运算一起处理，导致了不可能解析出优先级，所以第一步就是拆分规则:

```
expr = binary
    | group;
binary = binary1;
binary1 = binary2 ("+" | "-") binary2;
binary2 = number ("*" | "/") number;
group = "(" expr ")";
number = ... 第一步中解析出来的包含数值的单词
```

在解析 binary1 是会生成:

```
      + | -
      /   \
     /     \
    /       \
   /         \
binary2    binary2
```

这样就保证了 binary2 作为 "+-" 的子节点，从而保证优先级。 \
因为每条规则都只包含下一级的规则、自身以及运算符，故而名为递归下降 \
具体的细节会在实现计算器的时候给出。

### 计算抽象语法树

其实计算抽象语法树的过程就是后序遍历一颗树的过程——先访问左节点，再访问右节点，最后访问根节点。 \
假如完全不了解后序遍历，计算上述 2 + 3 * 4 的抽象语法树的过程如下:

首先访问顶层的左节点 2，接着访问右节点，右节点是如下一颗树:

```
   *
  / \
 /   \
3     4
```

所以开始后序遍历这棵树，访问 3，接着访问 4，最后访问 \*，运算 3*4=12，于是乎原来的树就等价于:

```
   +
  / \
 /   \
2    12
```

访问 12，访问 +，运算 12+2=14 就是最终结果

在稍后的实现中，会以一种优雅的方式来完成这个遍历，和计算

## 实现”完美“的计算器

在上一节，从解析表达式到执行表达式都给出了理论山可行的方法。接下来就可以实现了。

### Scanner

第一步就是组合字符为单词，这一步一般称之为 lex 或者词法分析。 \
而我们要写的能够做一般叫做扫描器(Scanner) \
现在已经有许多能够自动生成扫描器的工具，但既然是练习写 rust 代码，那么一切从零开始。 \
此外， rust 本身的代码可以作为参考，但由于 rust 本身比较复杂，假如全部照抄照搬，反而适得其反。

新增 lexer.rs 并在 lib.rs 中写入:

```rust { hl_lines=[2] }
pub mod dj;
pub mod lexer;
```

lexer.rs:

```rust
type Num = f64;

#[derive(Debug)]
pub enum Token {
    LeftParen, // (
    RightParen, // )
    Plus, // +
    Minus, // -
    Star, // *
    Slash, // /
    Number(Num), // number
    Unknown, // bad token
    Eof, // end of file
}

#[allow(unused)]
pub struct Scanner<T: Iterator<Item = char>> {
    source: T,
    next: Option<char>,
}
```

此处的 Token 类型就是构成源代码的单词，这是一个惯用的单词，使用其他名字容易产生误解，这个名字接触过的人一看就知。 \
Scanner 的设计上使用了泛型参数，这里是为了说明 rust 的语言特性，自己实现的时候可以用 String 或者 Chars 等自认为方便的类型。 \
至于只有 next 字段，没有吃过的字符的，是把那部分放在了函数之中会更加方便一些(因为 rust 的所有权，后面会看到) \
接着添加方法:

```rust
impl<T: Iterator<Item = char>> Scanner<T> {
    pub fn new(source: T) -> Self {
        let mut scanner = Scanner {
            source,
            next: None,
        };
        scanner.eat();
        scanner
    }

    fn eat(&mut self) {
        self.next = self.source.next();
    }
}
```

最关键的是 eat 方法，这个方法就是模拟小怪兽吃掉一个字符。 \
而在 new 函数中首先先 eat 一次是为了把第一个字符放入 next 字段中。 \
这是必须的，因为要依据 next 字段来判断是否可以组成一个单词

接着是最主要的函数:

```rust { hl_lines=["4-15"] }
impl<T: Iterator<Item = char>> Scanner<T> {
    // ...

    pub fn scan(&mut self) -> Vec<Token> {
        let mut tokens = Vec::with_capacity(16);
        while let Some(t) = self.scan_token() {
            tokens.push(t);
        }
        tokens.push(Token::Eof);
        tokens
    }

    fn scan_token(&mut self) -> Option<Token> {
        todo!()
    }

    // ...
}
```

scan 函数是不必要的，实现上也不好。 \
在后续的步骤中，不需要直到全部的 Token 而是按需获取 Token，将 Token 放入内存中是浪费内存的。 \
返回迭代器是一个不错的实现，返回 Vec 是为了简单，对于小小的计算器，无伤大雅。

开始实现词法分析的细节:

```rust { hl_lines=["5-20", "25-32"] }
impl<T: Iterator<Item = char>> Scanner<T> {
    // ...

    fn scan_token(&mut self) -> Option<Token> {
        self.skip_space();
        let c = self.next.take()?;
        self.eat();

        let token = match c {
            '(' => Token::LeftParen,
            ')' => Token::RightParen,
            '+' => Token::Plus,
            '-' => Token::Minus,
            '*' => Token::Star,
            '/' => Token::Slash,
            '0'..='9' => todo!(),
            _ => Token::Unknown,
        };

        Some(token)
    }

    // ...

    fn skip_space(&mut self) {
        while let Some(c) = self.next {
            match c {
                ' ' | '\t' | '\r' | '\n' => self.eat(),
                _ => break,
            }
        }
    }

    // ...
}

```

在空白符的处理上，并没有使用 rust 源代码中的那个函数，那是因为将 unicode 的支持放到后面。 \
`let c = self.next.take()?;` 是为了在读完了所有字符之后返回 None 结束词法分析。 \
将 next 字段的值取出后最好立马用 eat 补进去，使得 next 永远指向下一个待处理的字符。

这寥寥几行代码已经可以正确地进行一部分词法分析了，不信的话可以在 main.rs 写入:

```rust
use std::io::{self, Write};

use calculator::lexer::Scanner;

fn main() {
    loop {
        // prompt
        print!(">>> ");
        io::stdout().flush().expect("flush error");

        let mut line = String::with_capacity(8);
        io::stdin().read_line(&mut line).expect("fail to read input");

        let mut scanner = Scanner::new(line.chars());
        let tokens = scanner.scan();
        println!("{:?}", tokens);
    }
}
```

执行输出:

```
$ cargo run
   Compiling calculator v0.1.0 (/home/ajoker/projects/tmp/calculator)
    Finished dev [unoptimized + debuginfo] target(s) in 0.59s
     Running `target/debug/calculator`
>>> ()+-*/
[LeftParen, RightParen, Plus, Minus, Star, Slash, Eof]
>>>
```

接着就是比较麻烦的数值的处理了。 \






