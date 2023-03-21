# 两种'Assert'构建清晰代码
> tips...重要也不重要

原文: [Laurence Tratt: Rust's Two Kinds of 'Assert' Make for Better Code](https://tratt.net/laurie/blog/2023/rusts_two_kinds_of_assert_make_for_better_code.html)


## 快译



Daniel Lemire's recent post "runtime asserts are not free" looks at the run-time cost of assert statements in C and shows that a simple assert in a frequently executed loop can cause significant overhead.
My own opinion on assertions has shifted over the years, from "I don't see the point" to "use them sparingly" to "use them as much as possible". That last shift is largely due to Rust having two kinds of "assert" statement – assert and debug_assert – which has allowed me to accurately express two different kinds of assertions, largely freeing me from performance worries. If you come from a language that only has one kind of assert statement, this distinction can seem pointless, so in this post I want to briefly explain why it helped shift my thinking.

Background
Let me quickly define what I mean by an "assert": it's a programming language statement that checks a property and causes a crash if that property does not hold (conventionally called a "failing assert"). For example, if I have a Python program with a list of people's ages and calculate the minimum age, I might want to check that the youngest person doesn't have a negative age:

ages = [...]
youngest = min(ages)
assert(youngest >= 0)
If ages contains a negative value – or if min doesn't work correctly! – the assert will fail and cause a run-time exception:
Traceback (most recent call last):
  File "/tmp/t.py", line 3, in 
    assert(youngest >= 0)
AssertionError
In other words, writing assert is roughly equivalent to:
ages = [...]
youngest = min(ages)
if not (youngest >= 0):
  raise AssertionError
In practise, asserts are mostly used to check assumptions about a program's state — in this case, that at no point has a negative age entered into the system.
There are two major reasons why I might want to check this particular assumption. First, I might have written subsequent code which will only execute correctly with non-negative youngest values: I want to prevent that subsequent code from executing if that property is violated. Second, the assert both documents and checks the property. In other words, I could just have written a comment:

ages = [...]
youngest = min(ages)
# youngest must be non-negative or bad things will happen below
...
That comment accurately describes the program's assumption, but if the assumption is incorrect – perhaps because another part of the program uses -1 to mean "we don't know how old this person is" – the threatened "bad things" will occur. If I'm lucky, the effects will be relatively benign, and perhaps even invisible. But, if I'm unlucky, genuinely bad things will occur, ranging from odd output to security vulnerabilities.
Debugging incorrect assumptions of this sort is hard, because the effect of the assumption's violation is generally only noticed long after the violation occurred. It's not unusual for some poor programmer to spend a day or more hunting down a problem only to find that it was caused by the violation of a simple assumption. In contrast, the assert causes my program to crash predictably, with a clear report, and at the earliest possible opportunity. In general, fixing the causes of failing asserts tends to be relatively simple.

Why asserts are used less often than one might think
As I've described them above, asserts sound like a clear win — but most programs use many fewer asserts than one might hope.
The most obvious reason for this is that programmers often don't realise the assumptions they're embedding in their programs, or don't consider the consequences of their assumptions. This tends to be particularly true for junior programmers, who have not yet built up scar tissue from multi-day debugging sessions that were necessary only because they didn't think to use asserts. It took me many years of programming before I realised how much time I was wasting by not thinking about, and checking with asserts, my assumptions about a program's properties.

Sometimes it's also very difficult to work out how to assert the property one cares about. This is particularly true in languages like C where there is no built-in help to express properties such as "no element in the list can be negative". The lengthier, and more difficult, an assert needs to be – particularly if it needs a helper function – the less likely it is to be written down.

Inevitably, some asserts are plain wrong, either expressing an incorrect property, or expressing correct property incorrectly. I think most of us expect such mistakes. However, what many people don't realise is that asserts can change a program's behaviour if they have side effects. I have shot myself in the foot more than once by copying and pasting code such as l[i++] into an assert, causing the program to execute differently depending on whether the assert is compiled in or not. I view this as inevitable stupidity on my part, rather than a flaw in the concept of asserts, but I have heard of at least one organisation that bans (or, at least, banned) asserts because of this issue.

Performance issues
Daniel pointed out a very different reason for avoiding asserts: they can cause serious performance issues when used in the "wrong" places. An assert introduces a branch (i.e. an "if") which must be executed at run-time [1]. The existence of an assert can also cause a compiler to miss compile-time optimisation opportunities [2]. There is a general fear in the programming community about the performance costs of asserts, even though none of us can know how they impact a given program without actually measuring it.
To avoid performance issues, most software is compiled in either "debug" (sometimes called "testing") or "release" modes: in debug mode, asserts are compiled in and checked at run-time; but in release mode, the asserts are not compiled in, and thus not checked at run-time. In languages like C, there isn't a standard concept of "debug" and "release" modes, but many people consider "release" mode to imply adding a flag -DNDEBUG, which causes assert to become a no-op. Rust's standard Cargo build system defaults to debug mode, with --release performing a release build.

Two kinds of asserts
While not compiling (and thus not checking) asserts in release mode removes performance problems, it also weakens the guarantees we have about a program's correctness — just because a test suite doesn't violate an assumption doesn't mean that real users won't use the program in a way which does.
These days I thus view asserts as falling into two categories:

Checking problem domain assumptions.
Checking internal assumptions.
That distinction might seem artificial, perhaps even non-existent, so let me give examples of what I mean.
The first category contains assumptions about the "real world" problem my program is trying to help solve. For example, if I'm writing a warehouse stock system, parts of my program might assume properties such as "an item's barcode is never empty".

The second category contains assumptions about the way I've structured my program. For example, I might have written a function which runs much faster if I assume the input integer is greater than 1. It's probable that, at the time I write that function, I won't call it in a way that violates that property: but later programmers (including me!) will quite possibly forget, or not notice, that property. An assertion is thus particularly helpful for future programmers, especially when they're refactoring code, to give them greater confidence that they haven't broken the program in subtle ways.

What it took me years to realise is that I have very different confidence levels about my assumptions in each category. I have high confidence that violations of my assumptions in the second category will be caught during normal testing. However, I have much lower confidence that violations of my assumptions in the first category will be caught during testing.

My differing confidence levels shouldn't be surprising — after all, I've been hired because I can program, not because I know much about warehouse stock systems or barcodes! However, since "normal testing" implies "debug mode" and "user is running the program" implies "release mode", it means that the assumptions I am least confident are not exercised when they're most needed.

Two kinds of assert statement
The problem that I've just expressed ultimately occurs because languages like C force us to encode both kinds of assumption with a single assert statement: either all asserts are compiled in or none are.
I long considered this inevitable, but when I moved to Rust several years back, I slowly realised that I now had access to two kinds of assert statement. debug_assert is rather like assert in C, in the sense that the assumptions it expresses are only checked in debug mode. In contrast, assert is "always checked in both debug and release builds, and cannot be disabled."

This might seem like a small difference, but for me it completely unlocked the power of assertions. If you look at a lot of the code I now write, you'll see liberal use of debug_assert, often checking quite minor assumptions, including those I never think likely to be violated. I never even think, let alone worry, about the performance impact of debug_assert. But occasionally you'll spot an assert, sometimes even in fairly frequently executed code — those are where I'm checking particularly important assumptions, or assumptions in which I have particularly low confidence. Each time I write assert I think about the possible performance impact, and also about whether there's a way I can increase my confidence in the assumption to the point that I can downgrade it to a debug_assert. Similarly, when it comes to debugging, I often check assert statements quite carefully as they indicate my low confidence in a particular assumption: it's more likely that I have to reconsider an assert than a debug_assert.

Of course, there's no reason why you can't write your own equivalents of assert and debug_assert in C, or any other language, but having them built into a language (or standard library), where their differing motivations are clearly documented and widely understood, makes it much easier to use them freely. I hope languages other than Rust will continue to make this difference in assertions — though I would prefer a shorter name than "debug_assert"!






```
          _~`|`~_
      \) /  ← ◷  \ \/
        '_   V   _'
        \ '--∽--' )

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```