# BMP:最小bug模式
原文: [Rust Bug Minimization Patterns - The {pnk}f(eli)x Blog](http://blog.pnkfx.org/blog/2019/11/18/rust-bug-minimization-patterns/)

> Update 19 November 2019: fixed miscellaneous typos and a bug in the invariance example pointed out by readers both privately and on reddit thread. I also added a section near the beginning to draw attention to techniques that are somewhat Rust-specific and may not be broadly known.

> 快译:

Hey there again!

I have been pretty busy with Rust compiler tasks, so no there has not been a blog post for a few months. But now, here we are!

While I was working some particularly nasty bugs recently, I put a lot of effort into bug minimization: the process of taking a large test case and finding ways to remove code from the test while preserving the test’s ability to expose the same bug.

As I worked, I realized that I was following a somewhat mechanical process. I was using regular patterns for code transformation. At some point, I said “you know, I’m not sure if everyone is aware of these patterns. I only remember some of them while I am in the middle of a bug minimization session.”

Since the Rust compiler team always wants to help newcomers learn ways they can contribute to the project, I realized this could be the ideal subject for a blog post.

And, to try to keep things concrete, I’m going to try to drive the presentation by showing an actual bug being minimized. (Or rather, I’m going to recreate the minimization that I already did. So if it seems like I am rather conveniently picking transformations that always seem to work: You’re right! I’m cheating and not telling you about all the false paths I went down during my first minimization odyssey on this bug.

## The Rust specifics
Oh, and one other thing: A lot of the ideas here are applicable to many languages, and so its possible readers have already heard about them or discovered them independently.

However, a few of the techniques leverage features that are not universal to languages outside of Rust.

Specifically:

- “cfgmenting” makes use of Rust’s attribute system to remove items in a lightway fashion.
- “loopification” makes use of the fact that the Rust allows the divergent expression loop { } to be assigned any type.
- “loopification” via pretty-printer leverages the compiler’s (unstable) ability to inject loop { } for all function bodies.
- Bisecting the module tree makes use of Rust’s support for a mix of inline and out-of-line modules to allow one to quickly swap code in and out.

So, without further ado: here is the odyssey of my minimization of rust-lang/rust#65774

------
## Philosophical meandering
### What does “minimal” mean anyway?
The objective of a “minimal” test case could mean minimize lines of code; or the number of characters. It is also good to minimize the number of source files: one file, cut-and-pastable into play.rust-lang.org, is especially desirable.

> One could even argue that the number of nodes in the abstract syntax tree is a better metric to use than text-oriented metrics when minimizing.

Minimizing the source test in this way can yield a good candidate for a regression test to add to the compiler test suite when the bug is (hopefully) eventually fixed.

But those syntactic metrics of minimality overlook something: My own end goal when minimizing the code for a bug is a better understanding of the bug: a better understanding for myself, and for other developers who are reading the test case.

> I am writing this post from the viewpoint of a rustc developer. So I may have a slightly skewed view on what is useful or minimal.And for such understanding, there are other metrics to keep in mind:

- Minimize the amount of time the compiler runs before it hits the bug.

Minimizing the compiler’s execution time before failure serves two purposes:

1. It makes every future run of this test faster, which can accelerate your pace of minimization.
2. When the rustc developers themselves examine the behavior of the compiler on the test, they will be grateful to have a shorter execution trace of the compiler to analyze.

(Such time reduction often occurs anyway when you remove lines of code and/or dependencies; I just want to point out that it has value in its own right.)

> As a concrete example of how reducing imports may help expose a bug’s root cause: some people will have a bug that occurs with some combination of #[derive(Debug)] and a call to format! or write, and the test showing the problem may be only a few lines long. But it hides a lot of complexity behind those uses of derive, macros, and std::io trait machinery; a longer test that defines its own trait, a local impl of that trait, and a small function illustrating the same bug, may make the bug more immediately apparent to a rustc developer.

- Minimize dependencies: reduce the number of language features in use and the number of imports your test uses from other crates (including the std library!).

This can help expose the essential cause of the bug, potentially making it immediately apparent what is occurring.

- Minimize your jumping around in the source code.

If you can fit all the code needed to recreate the bug onto your monitor screen at once, by any means necessary, that is a serious accomplishment. Less time spent scrolling through a file or switching editor windows is more time you can spend thinking about the bug itself.

To be clear: Often a minimum amount of code needed for understanding does correlate with a minimum amount of code needed for reproduction. (This explains why using lines-of-code or the size of the syntax tree as a metric can be useful when reporting a bug.)

The over-arching goal in minification is to remove all distractions: to reduce the problematic input (in this case, Rust source code) to its essence: a minimal amount necessary to understand the problem.

### Why not build it up from scratch?
Its worth pointing out that at some point, maybe even at the outset, you may have a sufficiently rich understanding of the bug that you can go straight to building up a minimal example from scratch. And that’s great , go for it!

However, this post is dedicated to the problem of what you can do when you haven’t hit that level of understanding. When you’re looking at a set of files that make up over 90,000 lines of code, you want a set of semi-mechanical techniques to take that test input and strip it down to its essence.

To be honest, the most effective methodology is going to use a blend of build-up and tear-down. As you are tearing down the 90,000 lines of code, there should be a voice in the back of your head asking “can we now try what we’ve learned to try to build up a minimal example?”

------
## Assumptions and Conventions

> Some of the techniques may also be applicable to cases where the compiler is accepting code that it should be rejecting; but I am little wary of advertising these tools for use in that context, which is why you’re reading this in the margin and not the main text.

The tests I am talking about minimizing in this post are cases where the compiler itself fails in some way: an ICE, a link failure, or rejecting code that it should be accepting. Bugs that are witnessed by actually running the generated code are, for the most part, not covered by the patterns here. In particular: many of the patterns presented here rely on making semantic changes to the input: changing values, or replacing complex expressions with something trivial like loop { }.

I named each transformation, usually with absurd made-up words like “unusedification”. They are all in explicit quotation marks to try to make it clear that I am speaking nonsense, deliberately.

> I had originally planned to structure this post so that all transformations for a given theme would be present together, so that you’d see all the transformations for that theme at once. But as I wrote, it became clear over the course of actually doing a reduction, then we often bounce around between transformations, and it usually does not end up being nicely grouped with all transformations for one theme colocated in time. So rather than using that hierarchical presentation, I am instead just going to try to mention the grouping by marking each as transformation being part of a “theme”.Several of the transformations serve similar goals, like “delete the unnecessary”. I have attempted to categorize the different tranformations according to what purpose they serve in the minimization process. Over the course of documenting these transformations, I identified the following themes:

- Simplify Workflow: Make your own life easier.
    - Enable Incremental Steps
- Delete the Unnecessary: Remove items not related to bug!
- Identify the Unnecessary: Eliminate accidental necessity.
- Trivialize Content: Turn complex expressions to trivial ones.
- Eliminate Coupling: Break links between items.


## Notes on Notation
In this post, I follow typical notation by using ... as a placeholder for (possibly relevant) code that will be kept approximately the same (modulo mechanical updates like alpha-renaming) by a transformation. However, I also use the non-standard notation of ---- for irrelevant code that removed via a transformation. This is meant to draw attention to the distinct kinds of code, so that you can more easily tell which code is being removed by a particular transformation.

Sometimes I will show an explicit regexp that I am feeding to a tool to do the transformation, but usually I will stick to informal patterns with the aforementioned ... and ---- placeholders.

When a given item or expression can appear within the context of a middle of a sequence (e.g. consider { ... THING ... }), I often use the standard shorthand of just writing { THING ... } or { ... THING }, to simplify the textual presentation and focus attention on the transformation itself.

> theme: Simplify Workflow

## Record your steps
Before you do any reduction, move the test case into its own local git repository (or whatever versioning tool you prefer: SVN, RCS, etc). Being able to backtrack through previous reduction steps is an incredibly important option when doing this kind of of work.

> theme: Simplify Workflow

## Continuously test the test.
Finally: A crucial part of reduction is to continuously double-check that the bug still reproduces after every reduction step. I’ll show the command line invocation on occasion, but not every command line build invocation (the output is usually the same on every run, so it would just clog up the flow of the presentation here). But even though I don’t show every invocation, you can believe that I was doing the runs. (And in the cases where I tried to skip doing a run, I usually regretted it and had to backtrace my steps to the state before an attempted reduction.)

Make it easy to do your runs. Use your IDE. I use emacs, so I make a M-x compile invocation that runs the compiler with the right arguments, and then you can hit g in the *compilation* buffer to re-run the compile.

------
## The test case
As I mentioned at the start: The presentation here will be driven by referencing a concrete test case that I reduced recently: we have been given a crate graph, and we can observe a bug when we build as follows:

```

% ( cd tock/boards/arty-e21/ && \
    RUSTFLAGS="-C link-arg=-Tlayout.ld" \
    cargo build --target riscv32imac-unknown-none-elf )
   Compiling tock-registers v0.4.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-register-interface)
   Compiling tock-cells v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-cells)
   Compiling tock_rt0 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-rt0)
   Compiling enum_primitive v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/enum_primitive)
   Compiling kernel v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/kernel)
   Compiling riscv-csr v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/riscv-csr)
   Compiling rv32i v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/arch/rv32i)
   Compiling capsules v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/capsules)
   Compiling sifive v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/chips/sifive)
   Compiling arty_e21 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/chips/arty_e21)
   Compiling components v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/boards/components)
   Compiling arty-e21 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/boards/arty-e21)
error: internal compiler error: src/librustc/traits/codegen/mod.rs:127: Encountered errors `[FulfillmentError(Obligation(predicate=Binder(TraitPredicate(<() as core::fmt::Display>)), depth=1),Unimplemented)]` resolving bounds after type-checking
```

In reality the command line was a little more complicated:

```shell

% ( cd tock/boards/arty-e21/ && \
    RUSTFLAGS="-C link-arg=-Tlayout.ld -C linker=rust-lld -C linker-flavor=ld.lld -C relocation-model=dynamic-no-pic -C link-arg=-zmax-page-size=512" \
    cargo build --target riscv32imac-unknown-none-elf   )
...
error: internal compiler error: src/librustc/traits/codegen/mod.rs:127: Encountered errors `[FulfillmentError(Obligation(predicate=Binder(TraitPredicate(<() as core::fmt::Display>)), depth=1),Unimplemented)]` resolving bounds after type-checking
```

> An eagle-eyed reader might look at that ICE message and immediately consider grepping the source code, such as uses of the trait bound core::fmt::Display. A fine idea, but intuitive jumping to an answer is not what I’m focusing on here.

but for the purposes of the experiments presented in this blog post I will use the simplified invocation. (The difference only matters once we hit cases where the bug goes away.)

Remember that 90,000 lines of code number that I mentioned a few paragraphs ago? It didn’t come out of nowhere:

```shell
% find tock/ -name *.rs | xargs wc
...
   91958  317229 3150451 total

```
So this is an excellent example of an input that we really want to reduce down to something smaller.

------
> theme: Simplify Workflow

## Tactic: Reduce the driving code first
We have many input files, and they make up a crate graph with at least 13 crates in it.

We know from our command line invocation that it is the build of boards/arty-e21 that is exposing the ICE. It would be good to remove unnecessary crates from the crate graph for boards/arty-e21. But to do that most effectively, we need to first discard as many imports as possible from boards/arty-e21, and then work our way backwards through the dependency chain.

So, will start by reducing the boards/arty-e21 crate to the minimum necessary to reproduce the bug.

This single crate is a much easier thing to work with:


```shell
% find tock/boards/arty-e21/ -name '*.rs' | xargs wc
       4       6     124 tock/boards/arty-e21//build.rs
      27      68     565 tock/boards/arty-e21//src/timer_test.rs
      40     101     959 tock/boards/arty-e21//src/io.rs
     279     667    9135 tock/boards/arty-e21//src/main.rs
     350     842   10783 total

```

However, we still want to reduce it as much as we can: Every import we can remove from arty-e21 represents swaths of code that we might be able to remove in the rest of the crate graph.

------
> theme: Simplify Workflow

## Technique: “mod-inlining”
This technique may surprise some: I like to reduce the number of files involved early in the game, if I can. An easy way to do this is to replace the out-of-line mod foo; item with its inline counterpart: mod foo { ... }. Here the out-of-line module file content has been cut-and-pasted into an inline mod item.

Strictly speaking, moving from mod foo; to mod foo { ... }does not reduce the input: You still have all the same content that you started with, the compiler has to do the same amount of work, et cetera.

However, I still prefer to do it, because I find that it helps with later reduction steps if I can do my transformations on a single file.

There two techniques I use for “mod-inlining”:

1. Manually cut-and-paste: take each instance of mod foo; in the root file, and find that module’s contents. Then replace the ; with { and }, and finally paste the contents in between the curly brackets you just added. You don’t even have to re-indent it if you don’t want to.

> Its not like this is Python!

For a small module tree, such as we find in boards/arty-e21, manually cut-and-pasting is entirely reasonable. But if you have a large module tree, with many directories and files, it can become tedious and error-prone.


2. Alternative: use rustc to expand the module-tree. You can add --verbose to the cargo build invocation to see the actual rustc command line invocation cargo is using, and then you can add -Z unstable-options --pretty=expanded to that rustc invocation, piping the output to a new rust source

> Warning: this will not only expand the module tree: it will also expand all the macro invocations, including #[derive] attributes. This can be a bit overwhelming. (I am continually tempted to add a new unstable --pretty variant that just expands the module tree but does not expand the macros otherwise.)

I will show a concrete example of using rustc in this way later in the blog post. But for now I will just manually cut-and-paste the contents of boards/arty-e21/src/timer_test.rs and boards/arty-e21/src/io.rs into main.rs

After doing the inline, make sure the bug reproduces.

It is up to you whether you want to delete the out-of-line module files. Today, Rust does not treat their presence as some sort of conflict with the inline definition. You will see later in the post cases where keeping them around on the file-system can be useful. But for the case of boards/arty-e21, I will go ahead and delete them.

> Checking for unused out-of-line module files might be a nice lint for someone to add to rustc.

```shell
% find tock/boards/arty-e21/ -name *.rs | xargs wc
       4       6     124 tock/boards/arty-e21//build.rs
     348     840   10665 tock/boards/arty-e21//src/main.rs
     352     846   10789 total

```
As expected, this didn’t reduce the line count. But it did make it so we can work with a single file at the leaf. That simplifies my own workflow.

------
> theme: Delete the Unnecessary

## Tactic: “Decommentification”
This may be obvious, but it is a step that I often forget to do at the outset of test reduction, even though it is easy and pays off handsomely.

Comments in code are typically there to explain or justify some detail of the implementation. When diagnosing compiler bugs, the purpose of the original code is usually not relevant. You are better off increasing the number of lines of actual code that you can fit on your screen at once.

In short, the transformation looks like this:

```rust
^        //...$

```

to <empty-string>

In this case, I have used ^ and $ as markers for the beginning and end of lines (just like in regexps).

Or, as an Emacs M-x query-replace-regexp input: ^ *//.*^J* (and empty string as replacement text).

> The ^J there is a carriage-return inserted via M-x quoted-insert (aka C-q) in Emacs.

>> Why I use M-x query-replace-regexp: it previews the matches, I verify a few by eye, and then hit ! to do all the remaining replacements.

Another related transformation: get rid of the other blank lines that are not preceded by comments. I leave that regexp as an exercise for the reader.

In the case of boards/arty-e21, this got rid of 53 lines of comments (and blank lines succeeding them):

```shell
% wc tock/boards/arty-e21/src/main.rs
     295     575    8551 tock/boards/arty-e21/src/main.rs

```

------
> theme: Trivialize Content

## Tactic: “Body Loopification”
> see also: “none-defaulting”“Loopification” 

removes the body of a given function or method item, replacing it with loop { }.

Change:

```rust
fn foo(...) -> ReturnType { ---- }

```
to:

```rust
fn foo(...) -> ReturnType { loop { } }

```

> You might choose to use alternatives like unimplemented!(). I personally like loop { } because its something you almost never see in other people’s code, so its easy to search for and be pretty certain that it was introduced as part of reduction. Also loop { } relies on less machinery from the core library than unimplemented! does.


The use of loop { } is deliberate: since loop { } is known by the compiler to diverge, it can be assigned any type at all. So this transformation can be performed blindly.

- Note that this does not work for const fn; the compiler currently rejects const fn foo() { loop { } } as invaild syntax.
- Also, it generally will not work for impl Trait in return position: the compiler needs a concrete type to assign to the impl Trait, and loop { } will not suffice for that unless you ascribed it a non-! type in some manner.

When it comes to replacing a function body with loop { }, you may be able to get help from your IDE. In my own case, I have often used Emacs M-x kill-sexp to delete the { ---- } block in fn foo { ---- }

> More specifically, I have used Emacs to define a keyboard macro (via C-x () that: 1. searches for the next occurrence of fn, 2. searches forward from there for the first {, which often (but not always) corresponds to the start of the function’s body, 3. runs M-x kill-sexp to delete the { ---- } and 4. types in { loop { } }, replacing the method body. This is incredibly satisfying to watch in action.

If you want to take a risk, you can ask rustc to do the replacement of fn bodies with loop { } for you as part of pretty-printing via the -Z unpretty=everybody_loops flag. I’ll speak more on that later.

Once the body has been removed, you can optionally replace all of the formal parameters with _:

Change:

```rust
fn foo(a: A, b: B, ...) -> ReturnType { loop { } }

```

to:

```rust
fn foo(_: A, _: B, ...) -> ReturnType { loop { } }
```

> These explicit marks can be useful as hints for future reduction steps; see “genertrification”)

This is essentially a special case of “unusedification”; we do not delete the parameters outright yet (see “param-elimination” for that), but we mark them as completely useless by writing them as _: ParamType.

In the case of board/argy-e21/main.rs, there was one const fn, and you cannot “loopify” that. For the other fn’s, I was able to replace all but the last fn body with loop { }. (Replacing the last one made the bug go away.)

- In practice, the ICE diangostic often gives me some hint about which fn is the problem, and therefore I can blindly replace the other fn bodies with loop { }.
- But even without such a hint, once can often bisect over the set of fn’s to try to identify a maximal subset that can have their bodies replaced with loop { }. We will talk more about how to do such bisection later.


```rust
% wc tock/boards/arty-e21/src/main.rs
     262     523    7584 tock/boards/arty-e21/src/main.rs

```

(Okay, only removing 33 lines of code might not be very impressive. The technique will pay off more as we move further along.)

------
> theme: Trivialize Content

## Tactic: “Expr-elimination”
Even if you were not able to replace a whole fn body with loop { }, you can usually simplify the fn bodies that remain now.

> themes: Trivialize Content, Identify the Unnecessary

### Technique: Suffix-bisection
In this case, I recommend a form of bisection where you first comment out the bottom half of the original fn-body, and see if the problem reproduces.

- Why comment out the latter half? Well, if you comment out the top half, you’re almost certainly going to comment out let-bindings that the bottom half relies on. The top half very rarely relies on items in the bottom half.
- If the fn in question has a return type, then you can usually use a loop { } as a tail-expression at the end of the fn-body to satisfy the return-type; a natural variant of “loopification”.

If it does reproduce without the bottom half, then you can delete that half, and recursively process the top half.

If it doesn’t reproduce, then the bug relies on something in the bottom half. If you’re lucky, it only relies on stuff in the latter half, and you can try deleting the top half now. But even if you’re “unlucky” and the bottom half relies on stuff in the top half, you leave the top half in place (at least for now) and recursively process the bottom half, narrowing the code until you can identify a single statement whose presence or absence is the line between triggering the ICE or not.

If the fn is too large for fit on one screen, then I use M-x forward-sexp to identify the start and end of the fn-body. Then I jump to a line in the middle, and search around for the start of a statment in the body, and then comment out everything from that statement forward in /* ... */

In the case of boards/arty-e21/src/main.rs, this meant commenting out from line 191 through 263.


```rust
/*
    let gpio_pins = static_init!(
    ...

    board_kernel.kernel_loop(&artye21, chip, None, &main_loop_cap);
*/

```

And, “darn”: It didn’t work. The bug disappeared. But: This is okay! We still have learned something: Something in the latter half is causing the bug. So bisect that latter half (again, favoring commenting out second halves).

Eventually, by recursively processing the suffix statements, we identify that the bug does not reproduce with this code:

```rust
{
    ...
/*
    kernel::procs::load_processes(
        board_kernel,
        chip,
        &_sapps as *const u8,
        &mut APP_MEMORY,
        &mut PROCESSES,
        FAULT_RESPONSE,
        &process_mgmt_cap,
    );

    board_kernel.kernel_loop(&artye21, chip, None, &main_loop_cap);
*/
}

```
but does reproduce with this code:

```rust
{
    ...
    kernel::procs::load_processes(
        board_kernel,
        chip,
        &_sapps as *const u8,
        &mut APP_MEMORY,
        &mut PROCESSES,
        FAULT_RESPONSE,
        &process_mgmt_cap,
    );

/*
    board_kernel.kernel_loop(&artye21, chip, None, &main_loop_cap);
*/
}

```


So, now we have identified a function call to load_processes that seems to be intimately related to the bug.

Unfortunately, load_processes is an item defined in an external crate. (We will deal with that eventually.)

Now that we’ve identified this function call to load_processes as part of the cause of the bug, the new goal is to simplify the earlier part of the function to the bare minimum necessary to support this function call.

> In all of these cases, if an otherwise unused statement or expression influences the type-inference for the body, you may need to keep it around, or some variant of it.

- Get rid of all non-binding statements. (We should not need any side-effecting computations to reproduce the bug.)
- Initialize things to their default values (see “Defaultification” below).
- Eliminate unused lets (see “Unusedification” below).

After applying those steps repeatedly, and further “decommentification”, we are left with this:

```rust
#[no_mangle]
pub unsafe fn reset_handler() {
    let chip = static_init!(arty_e21::chip::ArtyExx, arty_e21::chip::ArtyExx::new());
    let process_mgmt_cap = create_capability!(capabilities::ProcessManagementCapability);
    let board_kernel = static_init!(kernel::Kernel, kernel::Kernel::new(&PROCESSES));

    kernel::procs::load_processes(
        board_kernel,
        chip,
        &0u8 as *const u8,
        &mut [0; 8192], // APP_MEMORY,
        &mut PROCESSES,
        kernel::procs::FaultResponse::Panic,
        &process_mgmt_cap,
    );

}

```

Just checking: the bug still reproduces, and we now have:

```shell
% wc tock/boards/arty-e21/src/main.rs
     111     289    2807 tock/boards/arty-e21/src/main.rs

```

Its not 100% minimized yet, but its about as far as we can go in changes to fn reset_handler without making changes to crates upstream in dependency graph.

------
> theme: Delete the Unnecessary

## Tactic: “Unusedification”
Another way to remove distractions: remove them.

```rust
non_pub_locally_unused_item(----) { ---- }

```

to <empty-string>

At this point, after our initial round of “loopification”, we should have a lot of unused stuff: variables, struct fields, imports, etc. And even better, the compiler is probably already telling you about all of them!

In the specific case of arty-e21, I am currently seeing 25 warnings: 13 unused import warnings, 4 unused variable warnings, 2 static item is never used warnings, 1 constant item is never used warning, and 5 field is never used warnings.

If you’re doing the compilation runs in your IDE, then you should be able to just jump to each unused item and remove it in some way.

- In the case of fn parameters, you can replace it with _ as previously discussed.
- ADT contents (struct and enum fields) may require more subtlety; see “ADT-reduction” below. For now, you can prefix their names with _.
- Warning: Items with attributes like #[no_mangle] or #[link_section] may also want special treatment: you may be able to remove them without causing the bug to go away, but once the bug does go away, their absence may cause a confusing linker error.


Make sure to check periodically that the bug still reproduces (Sometimes supposedly unused things still matter)!

This got boards/arty-e21 down to 95 lines:

```rust
% wc tock/boards/arty-e21/src/main.rs
      95     254    2382 tock/boards/arty-e21/src/main.rs
```

Again, not so impressive yet. But as with optimizations, sometimes the effect of these techniques only becomes apparent when they are combined together.

------
> theme: Delete the Unnecessary

## Technique: “Cfgments”
As a note: As a test run, you can easilly preview the effects of “unusedification” and “demodulification” (discussed below) transformations without actually deleting code. (After all, you may quickly discover that you need to put it back.) One classic approach for this is a comment block:

```rust
/*
non_pub_locally_unused_item(----) { ---- }
*/

```


But it not always easy to toggle such comments on and off, since you need add and remove the /* and matching */ each time you want to toggle it. Some IDEs help with this, but I still prefer to use more local changed if I can.

A less used option that is more specific to Rust (and that I use all the time), is to use a #[cfg] attribute to temporarily remove the code:

Change:

```rust
unused_or_little_used_item { ---- }

```

to:

```rust
#[cfg(not_now)]
unused_or_little_used_item { ---- }

```

> No, I do not know how to pronounce “cfgment”; I have only typed it, never uttered it. Iä! Sheol-Nugganoth!I call this “cfgmenting” out code (as opposed to “commenting out code”).

Whether or not you choose to use comments, “cfgments”, or just delete code outright is up to you, (though I do recommend you eventually delete the lines in question, as discussed in “decommentification”).


------
> theme: Delete the Unnecessary

## Tactic: “Demodulification”
In addition to “unusedifying” each identified unused item, you might try this: You may also be lucky enough to be able to just remove whole modules from this crate at this point. If the compiler is telling you that a lot of the items in a given module are unused, maybe you can get rid of the whole module. Go ahead and try it!

There can be a bit of guesswork involved here. For various reasons the compiler’s lints do not identify some definitions as unused even though it may seem obvious that they are not used.

- This can be a consequence of the impls in the source; see “Deimplification” below.
- Also some cases are only identified after doing “depublification” of the contents of such modules, which is also discussed below.

In the case of boards/arty-e21 I was able to identify mod timer_test as entirely unsed.

After “cfgmenting” it out and further “decommentification”, we have this:

```shell
% wc tock/boards/arty-e21/src/main.rs
      73     191    1967 tock/boards/arty-e21/src/main.rs
```

(For now we have to keep the mod io { ... }; it defines a panic-handler, and we won’t be able to get rid of that until we do more reduction elsewhere.)

------
> theme: Delete the Unnecessary

## Technique: “ADT-reduction”
What more is there to reduce here? Well, there is a struct ArtyE21 all of whose fields are unused:

```rust
struct ArtyE21 {
    _console: &'static capsules::console::Console<'static>,
    _gpio: &'static capsules::gpio::GPIO<'static>,
    _alarm: &'static capsules::alarm::AlarmDriver<
        'static,
        VirtualMuxAlarm<'static, rv32i::machine_timer::MachineTimer<'static>>,
    >,
    _led: &'static capsules::led::LED<'static>,
    _button: &'static capsules::button::Button<'static>,
}

```

We got lucky here: This struct has no lifetime or type parameters, so we can just do a trivial replacement, like so:

Change:

```rust
struct S { ---- }

```

to:


```rust
struct S { }

```
This, combined with “unusedification” of a now-unused import, leaves us with:


```shell
% wc tock/boards/arty-e21/src/main.rs
      63     170    1549 tock/boards/arty-e21/src/main.rs

```

### “ADT-reduction” in general
In the general case, if there is a generic parameter on the struct, you will need it to retain a field (to allow the compiler to compute the variance of the parameter).

Usually lifetime parameters are (co)variant, in which case this suffices:

Change:

```rust
struct S<'a>{ ---- }

```

to:

```rust
struct S<'a>{ _inner: &'a () }

```

> struct S<'a>(Cell<&'a ()) is another option for encoding invariance, note it imports std::cell::Cell.

If you need an invariant lifetime parameter to reproduce the bug, then you can do it this way:

Change:

```rust
struct S<'a>{ ---- }

```

to:

```rust
struct S<'a>{ _inner: &'a mut &'a () }

```

Likewise, type parameters can usually be encoded like so:

Change:

```rust
struct S<T> { ---- }

```

to:

```rust
struct S<T> { _inner: Option<T> }

```


If the type parameter has the ?Sized (anti)bound, then you can use this variant:

Change:

```rust
struct S<T: ?Sized> { ---- }

```

to:

```rust
struct S<T> { _inner: Option<Box<T>> }
```

Often if there is both a lifetime and a type parameter, then I will combine them into one field:

Change:

```rust
struct S<'a, T> { ---- }

```

to:

```rust
struct S<'a, T> { _inner: Option<&'a T> }

```


but in general that might not reflect the contentsfor example, it implicitly requires that T outlive 'a, which may not have been the case originaly of the original struct, and thus may cause the original bug to be masked. So in general you may have to do:

Change:

```rust
struct S<'a, T> { ---- }

```
to:

```rust
struct S<'a, T> { _inner1: &'a (), _inner2: Option<T> }

```

or some variation thereof.

Having said that, its pretty rare that struct S<'a, T> { _inner: Option<&'a T> } doesn’t suffice.

------
> themes: Delete the Unnecessary, Identify the Unnecessary

## Tactic: “Deimplificiation”
After “loopification”, often whole impl blocks can be eliminated.

In the case of arty-e21, we have this:

```rust
impl Write for Writer {
    fn write_str(&mut self, _: &str) -> ::core::fmt::Result { loop { } }
}

```

which is entirely unused.

So we can “cfgment” it out, and now the compiler identifies two unused imports (since this impl-block was their only use); more importantly, it now also identifies that the struct Writer is never constructed. (Which we already knew since we were able to revise its fields at will during “ADT-reduction”; but the point is that we couldn’t have removed its definition without first removing all of its associated impl blocks. Thus, “deimplification” is an important step in our reduction odysssey.

That, plus more “unusedification” gets us to 55 lines:

```shell
% wc tock/boards/arty-e21/src/main.rs
      55     146    1396 tock/boards/arty-e21/src/main.rs

```


### Fine-grained “deimplification”
In general you may not be able to remove the whole impl block. But you can still try to remove individual items from it, like so:

Change:

```rust
impl Foo {
   fn method(----) { ---- }
   ...
}

```

to:

```rust
impl Foo {
   ...
}

```


#### Technique: “split-impls”
> aka Regroup fn items in inherent impls.

I sometimes like to employ As a special technique to remove individual methods from an inherent impl: Rust lets you define multiple inherent impls for a given type. So rather than deleting code or using “cfgments” for each item, I will instead take an impl and break it into two, where one of them is “cfgmented” out:

Change:

```rust
impl Foo {
    fn method1(----) { ---- }
    fn method2(...) { ... }
    fn method3(...) { ... }
}

```


to:


```rust
#[cfg(not_now)]
impl Foo {
    fn method1(----) { ---- }
}
impl Foo {
    fn method2(...) { ... }
    fn method3(...) { ... }
}

```

Here, you can now move items freely between the “cfgmented”-out impl and the still present impl. It has a similar effect to “cfgmenting” out the individual items, but in practice it feels a lot more like an easy bisection process, at least for my fingers.

- Especially since you can start with the whole impl “cfgmented”-out, and let the compiler tell you which methods you need to put back (e.g. due to downstream uses.)


You can also sometimes do this impl as a way to make more fine-grained impl-blocks that have looser constraints, like so:

Change:


```rust
impl<X: Bound> Foo<X> {
    fn method1(...) { ... }
    fn method2(...) { ... }
    fn method3(...) { ... }
}

```

to:


```rust
impl<X: Bound> Foo {
    fn method1(...) { ... }
}
impl<X> Foo<X> {
    fn method2(...) { ... }
    fn method3(...) { ... }
}

```
(where here we assume method2 and method3 do not require the X: Bound).

------
## A pause
This is about as far as we can usefully get in reducing arty-e21 on its own.

To make further progress, we need to start making changes to upstream dependencies.

Lets look at the situation there.

------
> theme: Identify the Unnecessary

### Tactic: “dep-reduction”
>> aka “eliminate upstream dependencies”

We have not yet changed anything about the crate graph as a whole. Technicaly, building arty-e21 still builds 12 crates before starting on arty-e21. (Maybe cargo has some flag to inform you about unused dependencies?)

In any case, from inspecting arty-e21, we can see that it directly uses only two dependencies now: kernel and chips/arty_e21.

We can remove other dependencies from the Cargo.toml and see where it gets us:

```toml
[dependencies]
kernel = { path = "../../kernel" }
arty_e21 = { path = "../../chips/arty_e21" }

```


A build after a cargo clean now shows just nine crates being built before arty-e21


```shell
   Compiling tock-registers v0.4.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-register-interface)
   Compiling tock-cells v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-cells)
   Compiling tock_rt0 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/tock-rt0)
   Compiling arty-e21 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/boards/arty-e21)
   Compiling riscv-csr v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/libraries/riscv-csr)
   Compiling kernel v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/kernel)
   Compiling rv32i v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/arch/rv32i)
   Compiling sifive v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/chips/sifive)
   Compiling arty_e21 v0.1.0 (/Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/chips/arty_e21)
```

If we want to make more progress here, we’ll need to start working on upstream crates.

Looking at chips/arty_e21/Cargo.toml, we can see it also depends on the kernel crate:

```toml
[dependencies]
sifive = { path = "../sifive" }
rv32i = { path = "../../arch/rv32i" }
kernel = { path = "../../kernel" }

```

So this gives us a hint where to go next: Simplify chips/arty_e21 as much as we can, before we tackle trying to simplify the (hopefully root) kernel crate.

So lets see what we need from chips/arty_e21. It has a very small lib.rs file:

```rust
//! Drivers and chip support for the E21 soft core.

#![feature(asm, concat_idents, const_fn)]
#![feature(exclusive_range_pattern)]
#![no_std]
#![crate_name = "arty_e21"]
#![crate_type = "rlib"]

mod interrupts;

pub mod chip;
pub mod gpio;
pub mod uart;

```


Now I have a choice: do I go ahead and inline these module defintions like we did with boards/arty-e21? Well, lets figure out if we can first isolate its exports to a bare minimum before doing that.

------
> theme: Identify the Unnecessary

### Tactic: “Depublification”
As I already mentioned, the compiler is probably already tellling you about some of these (see “unusedification”).

But if you want to maximize the set of unused things that the compiler will identify for you, you might need to help it along the way by removing pub annotations, like so:

Change:

```rust
pub mod foo { ... }
```

to:

```rust
mod foo { ... }
```

or

Change:

```rust
pub use foo;
```

to:

```rust
use foo;
```

or struct, enum, type, trait, fn, etc; basically any pub item.

This can help compiler see that items or imports are in fact not used outside of the current crate, and thus can be eliminated.

For chips/arty_e21, I was able to successfully do this replacement:

Change:

```rust
pub mod chip;
pub mod gpio;
pub mod uart;

```
to:

```rust
pub mod chip;
mod gpio;
mod uart;

```

and everything still built.

After this point, I attempted blind “demodulification” each of mod interrupts, mod gpio, and mod uart (since its so easy to try when they are declared as out-of-line modules). Unfortunately, pub mod chip; currently depends on all of them being present.

So that’s when I went ahead and inlined the module definitions, leaving me with a 371-line lib.rs for chips/arty_e21:

```shell
% wc tock/chips/arty_e21/src/lib.rs
     371    1354   12137 tock/chips/arty_e21/src/lib.rs
```

>> Maybe this argues for a strategy where one should attempt targetted “loopification” on your reachable (pub) modules in the crate, and then do subsequent “demodulification” of the out-of-line modules before jumping into “mod-inlining”. I have not tried that workflow too seriously yet, though; its not that hard to “demodulify” a module, since its just a matter of “cfgmenting” out the mod declaration.

Then I “loopified” it; in this case, I was lucky and was able to loopify everything in chips/arty_e21, and the bug still reproduces.

After “loopification”, I was able to successfully “demodulify” all of mod interrupts, mod gpio, and mod uart.

Finally, I did some “deimplification”, and managed to remove everything except for a impl kernel::Chip for ArtyExx { ... } and one inherent method on struct ArtyExx.

Those steps, plus “decommentification”, removed about 320 lines.

```shell
% wc tock/chips/arty_e21/src/lib.rs
      52     163    1180 tock/chips/arty_e21/src/lib.rs
```

Perhaps most importantly, it got the source code to the point where it fits on a screen.

------
> themes: Enable Incremental Steps, Identify the Unnecessary

### Tactic: “simpl-impl”
>> aka use trait defaults

I did just mention that I had to keep an impl kernel::Chip for ArtyExx { ... }.

In general, the impl blocks we are trying to eliminate may be trait impls rather than inherent ones. In those cases, we cannot just remove methods from the impls willy-nilly, as that would cause the compiler to reject the trait implementation.

>> Did you see this coming?

So, you have to keep that impl entirely intact… unless you do some work up front …

Here’s the trick around that. First add a trait default implementation:

Change:

```rust
trait Tr { ... fn m(); }

```

to:

```rust
trait Tr { ... fn m() { loop { } } }

```

This enables the subsequent transformation:

Change:

```rust
impl Tr for C { ... fn m() { ---- } }

```
to:

```rust
impl Tr for C { ... }

```

Thats right, you can turn a non-default trait method into a “loopified” default trait method, and that enables you to freely remove instances of that method from all of that trait’s impls. You can do this transformation piecewise, or for the whole trait definition, as you like.

And (I think) you can do it pretty much as freely as you like: you should not need to worry about changing a trait method to a “loopified” default causing breakage elsewhere when compiling the crate graph (unless there is some potential interaction with specialization that I have not considered).

If you apply the transformation repeatedly, it can often result in

```rust
trait Tr { ---- } // all methods loopified
impl Tr for C { }

```
which is simply awesome.

In our specific case, the trait in question is upstream: impl kernel::Chip for ArtyExx { ... }

So we are going to make an exception to our earler rule about trying to work at the leaves first: Here, we are justified in jumping upstream, to kernel/src/platform/mod.rs, and changing the definition of kernel::Chip, doing M-x query-replace of ; with { loop { } } to easily jump through the fn-items and add a “loopified” body to each one.

(In my case, I’m going to decommentify the relevant file first too.)

After adding “loopified” default methods to the traits in kernel::platform, we can return to chips/arty_e21 and further simplify the impl there to this:


```rust
impl kernel::Chip for ArtyExx {
    type MPU = ();
    type UserspaceKernelBoundary = rv32i::syscall::SysCall;
    type SysTick = ();
}

```

Now we need to apply a bit of artistry.

----
> theme: Trivialize Content

### Tactic: “Type-trivialization”
This associated type in impl kernel::Chip for ArtyExx is forcing dependency on rv32i:

```rust
type UserspaceKernelBoundary = rv32i::syscall::SysCall;

```

But we have removed all the methods! Chances are actually quite good that there is no longer anyone that relies on that type defintion. (Its not a certainty, of course; clients of the trait might be extracting the type directly, and the associated may have trait bounds that will force us to use a non-trivial type there.)

But lets try it and see:

```rust
impl kernel::Chip for ArtyExx {
    type MPU = ();
    type UserspaceKernelBoundary = ();
    type SysTick = ();
}

```

yields:

```rust
error[E0277]: the trait bound `(): kernel::syscall::UserspaceKernelBoundary` is not satisfied
  --> /Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/chips/arty_e21/src/lib.rs:22:6
   |
22 | impl kernel::Chip for ArtyExx {
   |      ^^^^^^^^^^^^ the trait `kernel::syscall::UserspaceKernelBoundary` is not implemented for `()`

error: aborting due to previous error

```

So, what to do about this?

Honestly, I figure this is another case where we are justified in going upstream and removing the bound in question, just to see what happens:


```diff
diff --git a/tock/kernel/src/platform/mod.rs b/tock/kernel/src/platform/mod.rs
index 9544899..dd107dd 100644
--- a/tock/kernel/src/platform/mod.rs
+++ b/tock/kernel/src/platform/mod.rs
@@ -13,7 +13,7 @@ pub trait Platform {
 pub trait Chip {
     type MPU: mpu::MPU;

-    type UserspaceKernelBoundary: syscall::UserspaceKernelBoundary;
+    type UserspaceKernelBoundary;

     type SysTick: systick::SysTick;

```

And the answer is:


```
error[E0277]: the trait bound `<C as platform::Chip>::UserspaceKernelBoundary: syscall::UserspaceKernelBoundary` is not satisfied
   --> /Users/felixklock/Dev/Mozilla/issue65774/demo-minimization/tock/kernel/src/process.rs:468:5
    |
468 | /     stored_state:
469 | |         Cell<<<C as Chip>::UserspaceKernelBoundary as UserspaceKernelBoundary>::StoredState>,
    | |____________________________________________________________________________________________^ the trait `syscall::UserspaceKernelBoundary` is not implemented for `<C as platform::Chip>::UserspaceKernelBoundary`
    |
    = help: consider adding a `where <C as platform::Chip>::UserspaceKernelBoundary: syscall::UserspaceKernelBoundary` bound

error: aborting due to previous error

```

Darn. (We could take the compilers advice and add the aforementioned where clause, but that stands a good chance of just shifting the blame around without actually helping us make progress on reduction itself.)

You might think: “Lets try removing that field from the struct”; but note that the struct Process lives in the kernel crate, and that code has not yet been “loopified.” So there’s a good chance that there’s existing code that relies on that field being there, and we have to get rid of that code first.

Well, we did a good job getting chips/arty_e21 as small as we did. Let us take this as a sign that we should keep moving up, to now focus on reducing the kernel crate.

------
> theme: Simplify Workflow

### Technique: “mod-inlining” and “loopification” via pretty-printer
I want to simplify the kernel crate.

However, its module hierarchy is a bit larger than the other two crates we’ve looked at so far:



```
% find tock/kernel -name '*.rs'
tock/kernel/src/tbfheader.rs
tock/kernel/src/ipc.rs
tock/kernel/src/memop.rs
tock/kernel/src/lib.rs
tock/kernel/src/platform/mod.rs
tock/kernel/src/platform/systick.rs
tock/kernel/src/platform/mpu.rs
tock/kernel/src/callback.rs
tock/kernel/src/common/static_ref.rs
tock/kernel/src/common/list.rs
tock/kernel/src/common/peripherals.rs
tock/kernel/src/common/queue.rs
tock/kernel/src/common/ring_buffer.rs
tock/kernel/src/common/dynamic_deferred_call.rs
tock/kernel/src/common/mod.rs
tock/kernel/src/common/math.rs
tock/kernel/src/common/deferred_call.rs
tock/kernel/src/common/utils.rs
tock/kernel/src/hil/symmetric_encryption.rs
tock/kernel/src/hil/dac.rs
tock/kernel/src/hil/rng.rs
tock/kernel/src/hil/i2c.rs
tock/kernel/src/hil/pwm.rs
tock/kernel/src/hil/sensors.rs
tock/kernel/src/hil/watchdog.rs
tock/kernel/src/hil/led.rs
tock/kernel/src/hil/time.rs
tock/kernel/src/hil/crc.rs
tock/kernel/src/hil/ninedof.rs
tock/kernel/src/hil/entropy.rs
tock/kernel/src/hil/spi.rs
tock/kernel/src/hil/nonvolatile_storage.rs
tock/kernel/src/hil/mod.rs
tock/kernel/src/hil/usb.rs
tock/kernel/src/hil/adc.rs
tock/kernel/src/hil/gpio_async.rs
tock/kernel/src/hil/analog_comparator.rs
tock/kernel/src/hil/gpio.rs
tock/kernel/src/hil/radio.rs
tock/kernel/src/hil/eic.rs
tock/kernel/src/hil/flash.rs
tock/kernel/src/hil/uart.rs
tock/kernel/src/hil/ble_advertising.rs
tock/kernel/src/driver.rs
tock/kernel/src/component.rs
tock/kernel/src/sched.rs
tock/kernel/src/introspection.rs
tock/kernel/src/debug.rs
tock/kernel/src/process.rs
tock/kernel/src/syscall.rs
tock/kernel/src/returncode.rs
tock/kernel/src/grant.rs
tock/kernel/src/capabilities.rs
tock/kernel/src/mem.rs
```

I don’t want to manually-inline all those modules into kernel.

I’m also not too eager to manually “loopify” it (though that would be easier if the “mod-inlining” were done).

Luckily, we can leverage the compiler here.

------
>theme: Simplify Workflow

### “mod-inlining” via pretty-printer
As mentioned earlier, we can add -Z unstable-options --pretty=expanded to the relevant rustc invocation (in ths case, the one compiling kernel/src/lib.rs) to get the content of the crate as one module tree.

- (Unfortunately for our immediate purposes, the macros in it are also expanded. But since macros could expand into mod-declarations, this is tough to avoid in the general case for solving this problem.)

Pipe that output to a file, copy that file to tock/kernel/src/lib.rs, and you’re don- … well, no; you’re not done yet.

If you try to compile that as is, you get a slew of errors. Because some of the macros that expanded came from Rust’s core library, and make use of features that are not available in stable Rust. So you have to add feature-gates to enable each one. Luckily, the nightly compiler tells us which gates to add, so I was able to get away with adding this line to the top of the generated file:

```rust
#![feature(derive_clone_copy, compiler_builtins_lib, fmt_internals, core_panic, derive_eq)]

```
Then the compilation of this expanded kernel worked, and the downstream problem continued to reproduce. Success!

At least, success if your definition of success is this:

```
% wc tock/kernel/src/lib.rs
   10238   40254  540987 tock/kernel/src/lib.rs

```

Yikes, 10K lines.

------
> theme: Simplify Workflow

### “loopification” via pretty-printer
>> aka -Z everybody_loops


Well, that’s okay: There are some steps we haven’t taken yet. Specifically, we haven’t done “loopification.”

Now, its not so much fun to “loopify” a file like this by hand. The keyboard macro I described above isn’t tha robust; it can end up really messing up the code if you apply it blindly.

But luckily, we have another option:

rustc -Z unpretty=everybody_loops is your friend.

Basically, take the command line we used up above for macro-expanding pretty-printing, but replace the --pretty=expanded with -Zunpretty=everybody_loops.

As before, pipe the output to a temporary file, and then copy that over to kernel/src/lib.rs.

And then we build … and … oh. The bug didn’t replicate.

- This is okay. It is not a disaster.

It in fact motivates another technique: bisecting “loopification”.

### Bisecting the module tree
Warning: this technique may seem… strange. But I love it so.

The three steps are as follows:

1. Unify modules into a single source file (which we did up above, via the pretty-printer). But in particular, leave leave the original source files for the mod tree in place. (You’ll see why in a moment.)
2. Replace all function bodies with loop { }(which we just did, again via the pretty-printer).

>> If after doing this, you still get the same failure again, then congratulations: You have a single file (with a potentially huge module tree) and all of its function bodies are trivial loop { }. But of course, in our case of kernel, we know that we are not in this scenario. 

3. Finally, swap modules in and out via “cfgmenting”.

Remember up above when I suggested leaving the source files in place? This is where that comes into play.

A relatively tiny (and easily mechanized) change to the source code readily reverts individual modules back to their prior form:

Change:

```rust
mod child_mod_1 {
    use import::stuff;
    fn some_function() -> ReturnType {
        loop { }
    }

    mod even_more_inner {
       ...
    }
}

```

to:

```rust
mod child_mod_1;

#[cfg(commented_out_for_bisection)]
mod child_mod_1 {
    use import::stuff;
    fn some_function() -> ReturnType {
        loop { }
    }

    mod even_more_inner {
       ...
    }
}
```

This effectively puts back in the original code for child_mod_1.

You can search through your single lib.rs (or main.rs) file that holds the whole module tree (where function bodies are replaced with loop { }), and then choose a subset of these modules and apply the above transformation to point them at their original source file.

You can do this for, e.g., the first half the modules, and then re-run the compiler to see if the failure re-arises. If so, huzzah!

I successfully used this methodology to identify which mod in kernel we needed to keep in non-loopified form in order to reproduce the bug: mod process;.

And that gets us down to:


```
wc tock/kernel/src/lib.rs
    3253   11085  112858 tock/kernel/src/lib.rs

```

Yeah, still 3K lines. But that’s a lot better than 10K, and there’s plenty more stuff to remove.

First, lets see if we can further narrow down which methods in mod process are the ones that we need for replicating the bug. For this, we can do bisection over the fn items within the (still out-of-line) mod process.

------
### Reduction via Bisection
Sometimes you cannot simply remove all (or all but one) of the method bodies. For one reason or another (e.g. impl Trait in return position) you need to preserve the bodies of one or more methods that are not directly relevant to the bug at hand.

In this scenario, it can stil be useful to use the techniques above to eliminate irrelevant details in the other methods. But what is the best way to identify which methods are relevant and which aren’t? Well, that’s a fine segue to our original topic.

(… a significant amount of time has passed.)

Okay: after spending a lot of time doing pseudo-bisection, I managed to isolate three methods in process.rs that are necessary to reproduce the issue.

Part of my own process here (not process, ha ha) was to switch mindset away from trying to bisect to find the “one fn body” that causes the faiure. Instead, I had to focus on identifying a minimal subset of bodies that are necessary to cause it to arise.

That is, starting with N fn items, I’d “loopify” N/2 of them, and if the bug went away on that half, I’d put back in the previous bodies, cut that set in in half, and repeat until the bug came back. This tended to narrow things down to one fn item that, when “loopified”, made the bug go away.

Then I’d mark that one fn as strictly necessary, and repeat the process on the N-1 fn-items that still remained.

To be clear: this switch in mindset changes so-called “bisection” from a O(log n) process to an O(n log n) one: because you are going to do a separate O(log n) bisection step on O(n) fn-items. But on the plus side, its still a pretty mindless process (and probably could be mechanically automated).

Eventually, this led me to identify the three functions in process.rs whose non-“loopified” definitions are needed to witness the bug:

- load_processes
- <Process as ProcessType>::process_detail_fmt, and
- Process::create.

With that done, I redid the “mod-inlining” of mod process into kernel.

## Popping the stack
Now, as a reminder: the reason we dived into kernel was to see if we could remove the stored_state field from struct Process:

```
stored_state:
    Cell<<<C as Chip>::UserspaceKernelBoundary as UserspaceKernelBoundary>::StoredState>,
```

The answer is unfortuately still no: two of the three methods we kept from mod process refer to that field.

But we can do some directed editing to see if the bug repreoduces after removing those references:

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -3067,12 +3067,6 @@ impl<C: Chip> ProcessType for Process<'a, C> {
             flash_start
         ));

-        self.chip.userspace_kernel_boundary().process_detail_fmt(
-            self.sp(),
-            &self.stored_state.get(),
-            writer,
-        );
-
         self.mpu_config.map(|config| {
             let _ = writer.write_fmt(format_args!("{}", config));
         });
@@ -3205,7 +3199,7 @@ impl<C: 'static + Chip> Process<'a, C> {

             process.flash = slice::from_raw_parts(app_flash_address, app_flash_size);

-            process.stored_state = Cell::new(Default::default());
+            // process.stored_state = Cell::new(Default::default());
             process.state = Cell::new(State::Unstarted);
             process.fault_response = fault_response;

@@ -3246,6 +3240,7 @@ impl<C: 'static + Chip> Process<'a, C> {
                 }));
             });

+            /*
             let mut stored_state = process.stored_state.get();
             match chip.userspace_kernel_boundary().initialize_new_process(
                 process.sp(),
@@ -3263,6 +3258,7 @@ impl<C: 'static + Chip> Process<'a, C> {
                     return (None, app_flash_size, 0);
                 }
             };
+             */
```


And the answer is: YES. The bug reproduces!

And now we can move forward with removing that field… YES, still reproduces:

```diff

--- a/tock/kernel/src/lib.rs
+++ b/tock/kernel/src/lib.rs
@@ -2809,9 +2809,6 @@ pub struct Process<'a, C: 'static + Chip> {

     header: tbfheader::TbfHeader,

-    stored_state:
-        Cell<<<C as Chip>::UserspaceKernelBoundary as UserspaceKernelBoundary>::StoredState>,
-
     state: Cell<State>,

     fault_response: FaultResponse,

```

And then see about removed the bound on the associated type that sent us on this path… YES

```diff
--- a/tock/kernel/src/lib.rs
+++ b/tock/kernel/src/lib.rs
@@ -2525,7 +2525,7 @@ mod platform {
         type
         MPU: mpu::MPU;
         type
-        UserspaceKernelBoundary: syscall::UserspaceKernelBoundary;
+        UserspaceKernelBoundary;
         type
         SysTick: systick::SysTick;
         fn service_pending_interrupts(&self) { loop  { } }

```


So now we can pop our stack: We can go back to chips/arty_e21, and apply “type-trivialization”:

```diff

--- a/tock/chips/arty_e21/src/lib.rs
+++ b/tock/chips/arty_e21/src/lib.rs
@@ -21,7 +21,7 @@ impl ArtyExx {

 impl kernel::Chip for ArtyExx {
     type MPU = ();
-    type UserspaceKernelBoundary = rv32i::syscall::SysCall;
+    type UserspaceKernelBoundary = ();
     type SysTick = ();
 }
```

We did it!

With that in place, we can do more “dep-reduction”, by removing the rv32i dependency from chips/arty_e21.

At this point, we could continue with the above transformations to further reduce kernel.

But I want to switch to showing a different kind of minimization transformation, one that will let us make further simplifications to boards/arty-e21.

------
### Simplfying the existing code

Looking again at boards/arty-e21, we have this method body:

```rust

#[no_mangle]
pub unsafe fn reset_handler() {
    let chip = static_init!(arty_e21::chip::ArtyExx, arty_e21::chip::ArtyExx::new());
    let process_mgmt_cap = create_capability!(capabilities::ProcessManagementCapability);
    let board_kernel = static_init!(kernel::Kernel, kernel::Kernel::new(&PROCESSES));

    kernel::procs::load_processes(
        board_kernel,
        chip,
        &0u8 as *const u8,
        &mut [0; 8192], // APP_MEMORY,
        &mut PROCESSES,
        kernel::procs::FaultResponse::Panic,
        &process_mgmt_cap,
    );
}
```

It would be nice to figure out which parts of this are actually relevant.

Unfortunately, kernel::procs::load_processes was one of the functions where we could not apply “loopification” without masking the rustc bug.

Let us see if we can at least simplfify the API of load_processes itself.

It currently looks like this:


```rust
pub fn load_processes<C: Chip>(
    kernel: &'static Kernel,
    chip: &'static C,
    start_of_flash: *const u8,
    app_memory: &mut [u8],
    procs: &'static mut [Option<&'static dyn ProcessType>],
    fault_response: FaultResponse,
    _capability: &dyn ProcessManagementCapability,
) {
    let mut apps_in_flash_ptr = start_of_flash;
    let mut app_memory_ptr = app_memory.as_mut_ptr();
    let mut app_memory_size = app_memory.len();
    for i in 0..procs.len() {
        unsafe {
            let (process, flash_offset, memory_offset) = Process::create(
                kernel,
                chip,
                apps_in_flash_ptr,
                app_memory_ptr,
                app_memory_size,
                fault_response,
                i,
            );

            if process.is_none() {
                if flash_offset == 0 && memory_offset == 0 {
                    break;
                }
            } else {
                procs[i] = process;
            }

            apps_in_flash_ptr = apps_in_flash_ptr.add(flash_offset);
            app_memory_ptr = app_memory_ptr.add(memory_offset);
            app_memory_size -= memory_offset;
        }
    }
}
```


The fact that Process::create was another function that we could not “loopify” gives us a hint has to how to simplfy this further: can we reduce this method body to just a Process::create call, and see if the bug persists?

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2586,31 +2586,17 @@ pub fn load_processes<C: Chip>(
     let mut apps_in_flash_ptr = start_of_flash;
     let mut app_memory_ptr = app_memory.as_mut_ptr();
     let mut app_memory_size = app_memory.len();
-    for i in 0..procs.len() {
         unsafe {
-            let (process, flash_offset, memory_offset) = Process::create(
+            Process::create(
                 kernel,
                 chip,
                 apps_in_flash_ptr,
                 app_memory_ptr,
                 app_memory_size,
                 fault_response,
-                i,
+                0,
             );
-
-            if process.is_none() {
-                if flash_offset == 0 && memory_offset == 0 {
-                    break;
-                }
-            } else {
-                procs[i] = process;
-            }
-
-            apps_in_flash_ptr = apps_in_flash_ptr.add(flash_offset);
-            app_memory_ptr = app_memory_ptr.add(memory_offset);
-            app_memory_size -= memory_offset;
         }
-    }
 }
```


And yes, the bug still reproduces.

------
> theme: Simplify Workflow

### Tactic: “RHS-inlining”
This is just the classic transformation of taking the right-hand side of a let or const and copying it into the usage sites for the variable defined by the let or const. Once all uses of the variable have been replaced, you can try removing the let or const itself (i.e. “unusedification”)

In our specific case, we can apply this to load_processes:

```diff
--- a/tock/kernel/src/lib.rs
+++ b/tock/kernel/src/lib.rs
@@ -2583,16 +2583,13 @@ pub fn load_processes<C: Chip>(
     fault_response: FaultResponse,
     _capability: &dyn ProcessManagementCapability,
 ) {
-    let mut apps_in_flash_ptr = start_of_flash;
-    let mut app_memory_ptr = app_memory.as_mut_ptr();
-    let mut app_memory_size = app_memory.len();
         unsafe {
             Process::create(
                 kernel,
                 chip,
-                apps_in_flash_ptr,
-                app_memory_ptr,
-                app_memory_size,
+                start_of_flash,
+                app_memory.as_mut_ptr(),
+                app_memory.len(),
                 fault_response,
                 0,
             );

```

However, this technique on its own does not tend to actually reduce the problem at hand, in terms of making it possible for us to remove imports or simplify fn API signatures.

------
> theme: Trivialize Content

### Tactic: “Defaultification”
>> aka “Scalars Gotta Scale”

If you really want to simplify, then you should replace the occurences of the variable with some “obvious” value based on its type.

(This is the obvious alternative to “loopification” when it comes to simplifying const fn.)

More specifically: frequently, the return type of a const fn (or the type of a const item) is some scalar type (like u32, f64, or bool). These all have “obvious” values that you can just plug in (respectively 0, 0.0, or false).

Change:

```rust
const fn cfoo(----) -> u32 { ---- }

```
to:

```rust
const fn cfoo(----) -> u32 { 0 }

```
In the case of load_processes, “defaultification” yields this:


```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2587,9 +2587,9 @@ pub fn load_processes<C: Chip>(
             Process::create(
                 kernel,
                 chip,
-                start_of_flash,
-                app_memory.as_mut_ptr(),
-                app_memory.len(),
+                0 as *const u8,
+                (&mut []).as_mut_ptr(),
+                0,
                 fault_response,
                 0,
             );
```

That means we’ve gotten rid of the uses of three fn parameters in the body of load_processes. Lets see what that can buy us for further reduction.

------
> theme: Trivialize Content

### Technique: “Genertrification”
>> aka “Type Freedom”

Once you remove all uses of parameter (which is readily identifiable via either lint diagnostics or if the parameter has just _: ParamType for its declaration), you can “genertrify” it to get rid of the use of ParamType.

Change:

```rust
fn foo(_: ParamType, ----) -> ReturnType { loop { } }

```
to:


```rust
fn foo<A>(_: A, ----) -> ReturnType { loop { } }

```
or even more simply (in terms of locality of the transformation):

```rust
fn foo(_: impl Sized, ----) -> ReturnType { loop { } }

```

The beauty of this is that it can almost always be applied even if there remain uses of foo elsewhere in the code.

Therefore, I tend to recommend it over “param-elimination”, described below.

- However, this transformation does not work if fn foo must not carry any generic type parameters; e.g., if fn foo needs to be object-safe, then you cannot add the type parameteter A.
- The other case where it cannot be applied is when an existing use is relying on the existing type for inference purposes. We will see an example of this below.

In the case of load_processes, “genertrification” allows this change:

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2577,11 +2577,11 @@ use core::cmp::max;
 pub fn load_processes<C: Chip>(
     kernel: &'static Kernel,
     chip: &'static C,
-    start_of_flash: *const u8,
-    app_memory: &mut [u8],
-    procs: &'static mut [Option<&'static dyn ProcessType>],
+    _: impl Sized,
+    _: impl Sized,
+    _: impl Sized,
     fault_response: FaultResponse,
-    _capability: &dyn ProcessManagementCapability,
+    _: impl Sized,
 ) {
         unsafe {
             Process::create(
```


And once we do that, we can revise any calls to load_processes and pass any value we like for the impl Sized arguments. So we’ve opened up new opportunities for “expr-elimination”:

```diff
--- INDEX/tock/boards/arty-e21/src/main.rs
+++ WORKDIR/tock/boards/arty-e21/src/main.rs
@@ -39,17 +39,16 @@ impl Platform for ArtyE21 {
 #[no_mangle]
 pub unsafe fn reset_handler() {
     let chip = static_init!(arty_e21::chip::ArtyExx, arty_e21::chip::ArtyExx::new());
-    let process_mgmt_cap = create_capability!(capabilities::ProcessManagementCapability);
     let board_kernel = static_init!(kernel::Kernel, kernel::Kernel::new(&PROCESSES));

     kernel::procs::load_processes(
         board_kernel,
         chip,
-        &0u8 as *const u8,
-        &mut [0; 8192], // APP_MEMORY,
-        &mut PROCESSES,
+        (),
+        (),
+        (),
         kernel::procs::FaultResponse::Panic,
-        &process_mgmt_cap,
+        (),
     );

 }
```

We would like to continue simplifying the APIs by applying “genertrification” elsewhere. For example, load_processes calls Process::create, so it would be useful to simplify its API.

The body of Process::create is currently over 150 lines of code. But after bisection-based “expr-elimination”, coupled with “RHS-inlining”, “defaultification”, and “unusedification”, we can get the body down to this far more managable 20 lines:

```rust
impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        kernel: &'static Kernel,
        chip: &'static C,
        app_flash_address: *const u8,
        remaining_app_memory: *mut u8,
        remaining_app_memory_size: usize,
        fault_response: FaultResponse,
        index: usize,
    ) -> (Option<&'static dyn ProcessType>, usize, usize) {
            let mut process: &mut Process<C> =
                &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

            process.debug = MapCell::new(ProcessDebug {
                app_heap_start_pointer: None,
                app_stack_start_pointer: None,
                min_stack_pointer: 0 as *const u8,
                syscall_count: 0,
                last_syscall: None,
                dropped_callback_count: 0,
                restart_count: 0,
                timeslice_expiration_count: 0,
            });

            return (
                Some(process),
                0usize,
                0usize,
            );
    }
    ...
}
```

And now we can apply “genertrification”:


```diff

--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -3065,13 +3065,13 @@ fn exceeded_check(size: usize, allocated: usize) -> &'static str { loop { } }
 impl<C: 'static + Chip> Process<'a, C> {
     #[allow(clippy::cast_ptr_alignment)]
     crate unsafe fn create(
-        kernel: &'static Kernel,
+        kernel: impl Sized,
         chip: &'static C,
-        app_flash_address: *const u8,
+        app_flash_address: impl Sized,
         remaining_app_memory: *mut u8,
-        remaining_app_memory_size: usize,
-        fault_response: FaultResponse,
-        index: usize,
+        remaining_app_memory_size: impl Sized,
+        fault_response: impl Sized,
+        index: impl Sized,
     ) -> (Option<&'static dyn ProcessType>, usize, usize) {
             let mut process: &mut Process<C> =
                 &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);
```

#### “you can’t always genertrify what you want”
Unfortunately, I was not able to “genertrify” the remaining_app_memory formal parameter, even though it is unused in the function body. Why is this? Because the current call-site is relying on the type of the formal parameter for inference purposes. So in this case, we need to update the API in tandem with the call site:

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2588,7 +2588,7 @@ pub fn load_processes<C: Chip>(
                 (),
                 chip,
                 (),
-                (&mut []).as_mut_ptr(),
+                (),
                 0,
                 (),
                 0,
@@ -3068,7 +3068,7 @@ impl<C: 'static + Chip> Process<'a, C> {
         kernel: impl Sized,
         chip: &'static C,
         app_flash_address: impl Sized,
-        remaining_app_memory: *mut u8,
+        remaining_app_memory: impl Sized,
         remaining_app_memory_size: impl Sized,
         fault_response: impl Sized,
         index: impl Sized,
```


This allows further “expr-elimination”:

```diff

--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -3076,17 +3076,6 @@ impl<C: 'static + Chip> Process<'a, C> {
             let mut process: &mut Process<C> =
                 &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

-            process.debug = MapCell::new(ProcessDebug {
-                app_heap_start_pointer: None,
-                app_stack_start_pointer: None,
-                min_stack_pointer: 0 as *const u8,
-                syscall_count: 0,
-                last_syscall: None,
-                dropped_callback_count: 0,
-                restart_count: 0,
-                timeslice_expiration_count: 0,
-            });
-
             return (
                 Some(process),
                 0usize,
```

and we bave gotten Process::create down to something that actually is close to minimal, at least with given the transformations we have covered so far:


```rust

impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        kernel: impl Sized,
        chip: &'static C,
        app_flash_address: impl Sized,
        remaining_app_memory: impl Sized,
        remaining_app_memory_size: impl Sized,
        fault_response: impl Sized,
        index: impl Sized,
    ) -> (Option<&'static dyn ProcessType>, usize, usize) {
            let mut process: &mut Process<C> =
                &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

            return (
                Some(process),
                0usize,
                0usize,
            );
    }
...
}
```

But of course, we can go further!

### Once all the code is gone …
The applicability of many of the remaining patterns depends on whether you have successfully trivialized all or most method bodies. That is, if you have gotten rid of most of the complex expressions in the program, then you can usually remove things like struct field declarations or any “interesting” types on formal parameters.

So, lets see if we can further reduce the complexity of our example by simplifying the APIs of the functions involved.

------
> theme: Trivialize Content

### Technique: “Param-elimination”
If you have successfully eliminated all uses of a method foo, then you can apply this transformation:

Change:

```rust
fn foo(_: ArgType, ----) -> ReturnType { loop { } }

```

to:

```rust
fn foo(----) -> ReturnType { loop { } }

```

In some rare cases, the compiler bug will requires a method signature to keep the same number of arguments; for that scenario, you can instead use “type-trivialization” for the parameter:

Change:

```rust
fn foo(_: ArgType, ----) -> ReturnType { loop { } }

```
to:

```rust
fn foo(_: (), ----) -> ReturnType { loop { } }

```

Either way, these transformations can only be applied if all uses of foo have been eliminated via trivialization of bodies as described above (or if you are willing to update them all accordingly). Thus, I tend to recommend applying “genertrification” instead: that transformation can be applied without concern about the usage sites.

Of course, if you have already applied “genertrification” and also updated all call sites to pass something trivial like (), then you can readily apply either “param-elimination” or “type-trivialization”: it really should be easy to update the call-sites in that scenario.

In our particular case of Process::create, we currently have a fn-signature that looks like:


```rust
crate unsafe fn create(
    kernel: impl Sized,
    chip: &'static C,
    app_flash_address: impl Sized,
    remaining_app_memory: impl Sized,
    remaining_app_memory_size: impl Sized,
    fault_response: impl Sized,
    index: impl Sized,
) -> (Option<&'static dyn ProcessType>, usize, usize) {
```

And we already updated the single call-site to pass () or 0 for each of the parameters of type impl Sized, so now we can just remove them entirely:

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2585,13 +2585,7 @@ pub fn load_processes<C: Chip>(
 ) {
         unsafe {
             Process::create(
-                (),
                 chip,
-                (),
-                (),
-                0,
-                (),
-                0,
             );
         }
 }
@@ -3065,13 +3059,7 @@ fn exceeded_check(size: usize, allocated: usize) -> &'static str { loop { } }
 impl<C: 'static + Chip> Process<'a, C> {
     #[allow(clippy::cast_ptr_alignment)]
     crate unsafe fn create(
-        kernel: impl Sized,
         chip: &'static C,
-        app_flash_address: impl Sized,
-        remaining_app_memory: impl Sized,
-        remaining_app_memory_size: impl Sized,
-        fault_response: impl Sized,
-        index: impl Sized,
     ) -> (Option<&'static dyn ProcessType>, usize, usize) {
             let mut process: &mut Process<C> =
                 &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

```

And compiling still hits the same ICE, so this “param-elimination” was a legitimate reduction of the problem.

Next we’ll consider a related transformation on the fn-signature.

------
> theme: Trivialize Content

### Technique: “Ret-elimination”
If you have successfully eliminated all uses of the value returned from calls to foo, then you can apply this transformation:

Change:

```rust
fn foo(----) -> ReturnType { loop { } }

```

to:

```rust
fn foo(----) { loop { } }

```

If fn foo still has a body, then you can just turn every return point in the body into a normal expression:

Change:

```rust
fn foo(----) -> ReturnType { if A { return B; } TailReturn }

```

to:

```rust
fn foo(----) { if A { B; } TailReturn; }

```
In our case, the sole call to Process::create now looks like this:

```rust
    unsafe {
        Process::create(
            chip,
        );
    }

```

So we can directly apply “ret-elimination” to the definition of Process::create:


```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -3060,11 +3060,11 @@ impl<C: 'static + Chip> Process<'a, C> {
     #[allow(clippy::cast_ptr_alignment)]
     crate unsafe fn create(
         chip: &'static C,
-    ) -> (Option<&'static dyn ProcessType>, usize, usize) {
+    ) {
             let mut process: &mut Process<C> =
                 &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

-            return (
+            (
                 Some(process),
                 0usize,
                 0usize,
```


But… Ah ha! Doing this causes the compilation error to disappear!

What happened?

Well, inspecting the return type, we can see that “Ret-elimination” in this case has gotten rid of the type: (Option<&'static dyn ProcessType>, usize, usize). Nested within that tuple, we see the type &'static dyn ProcessType. So, the attemtpt to return (Some(process), 0, 0) is causing the generated code to coerce the process: &mut Process<C> into a trait-object of type &dyn ProcessType. And apparently this is part of generating the bug!

So, do not look at this reduction-failure as a set-back: It in fact may serve as a clue as to the root cause of the bug.

------
### Final reduction touches on Process::create
For Process::create, we have:

```rust
impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        chip: &'static C,
    ) -> (Option<&'static dyn ProcessType>, usize, usize) {
            let mut process: &mut Process<C> =
                &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

            return (
                Some(process),
                0usize,
                0usize,
            );
    }
    ...
}
```

We can simplfy this API by reducing the return type to the core element that matters: the trait object:

```diff
--- a/tock/kernel/src/lib.rs
+++ b/tock/kernel/src/lib.rs
@@ -3045,15 +3045,11 @@ impl<C: 'static + Chip> Process<'a, C> {
     #[allow(clippy::cast_ptr_alignment)]
     crate unsafe fn create(
         chip: &'static C,
-    ) -> (Option<&'static dyn ProcessType>, usize, usize) {
+    ) -> &'static dyn ProcessType {
             let mut process: &mut Process<C> =
                 &mut *((&mut []).as_mut_ptr() as *mut Process<'static, C>);

-            return (
-                Some(process),
-                0usize,
-                0usize,
-            );
+            process
     }

     #[allow(clippy::cast_ptr_alignment)]
```

In fact, we can do even better. The initialization expression on the right-hand side of let mut process = ... is ugly, and its actually completely irrelevant.

In cases like these where we are hitting an ICE, we can use a special kind of “defaultification” to conjure up types without needing any knowledge of their expression.

------
> theme: Trivialize Content

### Technique: “None-defaulting”
>> This is yet another case where the fact that we are debugging a compile-time issue is crucial. You obviously cannot be tossing None.unwrap() into code you expect to run usefully.

The idea of “none-defaulting” is simple: You need the compiler to think you have a value of type T. But the steps to make an instance of T are not relevant to reproducing the bug. So just make a None::<T>, and unwrap it.

Change:

```rust
let x: T = ----;
```

to:

```rust
let x: T = None.unwrap();
```

In our case, applying this technique to Process::create yields this:


```rust
impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        chip: &'static C,
    ) -> &'static dyn ProcessType {
            let mut process: &mut Process<C> = None.unwrap();

            process
    }
    ...
}
```

And compiling this, the ICE still reproduces!

## So, where are we now
We’ve still got a set of three crates, one of which is over 3,000 lines long.

But we’ve also reduced the set of non-trival functions in that big crate to just three:

- Process::create,
- load_processes, and
- <Process as ProcessType>::process_detail_fmt.

If you think for a momeent, you can see how everything is tying together here: This ICE is occurring in the midst of some step of code-generation. We previously established that in order to observe the ICE, the compiler needs to handle code-generation for the coercion from &Process to a trait object &dyn ProcessType . A method like <Process as ProcessType>::process_detail_fmt is part of the virtual-methods that get their code generated as part of that coercion.

We already showed Process::create is now pretty trivial.

As for load_processes, after doing some additional “unusedification” and “param-elimination” we can get it down to this:

```rust
pub fn load_processes<C: Chip>(
    chip: &'static C,
) {
        unsafe {
            Process::create(
                chip,
            );
        }
}
```

which we might as well rewrite into the one-liner:

```rust
pub fn load_processes<C: Chip>(chip: &'static C) { unsafe { Process::create(chip); } }

```

That just leaves <Process as ProcessType>::process_detail_fmt, which we have not looked at yet.

As part of the earlier (undocumented) bisection process on the out-of-line mod process;, I already “simpl-impled” the ProcessType trait declaration, so it looks like this:


```rust
pub trait ProcessType {
    fn appid(&self) -> AppId { loop { } }
    ...
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) { loop { } }
    ...
}
```

This means we can remove all of the irrelevant methods from the impl<C: Chip> ProcessType for Process<'a, C>, leaving us with just the single method:

```rust
impl<C: Chip> ProcessType for Process<'a, C> {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) {
        ...
    }
}

```

And since this is now the only impl of ProcessType, we can also remove the other methods from the ProcessType trait itself:

```rust
pub trait ProcessType {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) { loop { } }
}

```

I cannot stress how satisfying it is to be able to retest the ICE in between each of these steps. It gives you excellent points to pause, get up from the keyboard and take a walk (which is another surprisingly effective debugging methodology).

But we still have the body of fn process_detail_fmt itself, which is about 175 lines of code. So lets try to winnow that down.

“Suffix-bisection” ends up revealing that the ICE is triggered by this bit of code in the method.

```rust
    self.mpu_config.map(|config| {
        let _ = writer.write_fmt(format_args!("{}", config));
    });

```

And so we can “expr-eliminate” all the rest, leaving this defintion of the method:

```rust
impl<C: Chip> ProcessType for Process<'a, C> {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) {
        self.mpu_config.map(|config| {
            let _ = writer.write_fmt(format_args!("{}", config));
        });
    }
}

```

That looks pretty simple (after all, its a a three line body). But its still doing some relatively interesting stuff: there’s that format_args! macro in there, and a closure being constructed.

We might try to simplify the body further: turn the closure body into the main body of process_detail_fmt itself.

The closure takes an input of type config; a quick inspect of the map method shows that should have the same type as is fed into the MapCell here:

```rust
mpu_config: MapCell<<<C as Chip>::MPU as MPU>::MpuConfig>,

```
Unfortunately, we quickly discover that just moving the closure body into the process_detail_fmt method is not a valid reduction. That is, I tried compiling with this definition instead:

```rust
impl<C: Chip> ProcessType for Process<'a, C> {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) {
        let config = None::<<<C as Chip>::MPU as MPU>::MpuConfig>.unwrap();
        let _ = writer.write_fmt(format_args!("{}", config));
    }
}

```
and got this ICE:

```
error: internal compiler error: src/librustc/traits/codegen/mod.rs:53: Encountered error `Unimplemented` selecting `Binder(<() as core::fmt::Display>)` during codegen

```

>> When reduction uncovers a different bug, it is of course good practice to record that distinct state of the test source code somewhere. E.g. you could make a separate git branch for it, and come back to later.

That is certainly a similar looking ICE. But if we want to be sure about our reduction, we really need to see the same error: if we don’t see [FulfillmentError(Obligation(...))], then we should not be satisifed.

So, we apparently have to keep more of the original code from process_detail_fmt.

At this point we must note that MapCell is a type that kernel is pulling in from another crate, tock-cells.

So we might need to go and modify code over in tock-cells if we want to fully reduce this code.

Or we might be able to get away with just copying its definition locally, avoiding the hassle of the full process of reducing the tock-cells crate itself.

------
> themes: Eliminate Coupling, Identify the Unnecessary

### Tactic: “Cut-spaghetti-imports”
This is pretty easy: If you’ve “loopified” most of your code, you can often do this replacement.

Change:

```rust
use ...::Type;
```

to:

```rust
struct Type;
```

or, if applicable:

```rust
type Type = ();
```

If you haven’t done full “loopification” everywhere (our situation), then you may need to do this.

```rust
struct Type { ... } // (adapt definition from elsewhere, potentially via cut-and-paste).
impl Type { ... }
```

Note: may need to add (potentially artificial) generic parameters, like so:

Change:

```rust
use ...::Type;
```

to:


```rust
struct<'a, T> Type(&'a (), Option<T>);
```

or

```rust
type Type<'a, T> = (&'a (), Option<T>);
```
In our case, we are going to make a local version of tock_cells::MapCell.


```rust
struct MapCell<T> {
    val: core::cell::UnsafeCell<core::mem::MaybeUninit<T>>,
    occupied: Cell<bool>,
}
impl<T> MapCell<T> {
    pub fn is_some(&self) -> bool {
        self.occupied.get()
    }
    pub fn map<F, R>(&self, closure: F) -> Option<R>
    where
        F: FnOnce(&mut T) -> R,
    {
        if self.is_some() {
            self.occupied.set(false);
            let valref = unsafe { &mut *self.val.get() };
            // TODO: change to valref.get_mut() once stabilized [#53491](https://github.com/rust-lang/rust/issues/53491)
            let res = closure(unsafe { &mut *valref.as_mut_ptr() });
            self.occupied.set(true);
            Some(res)
        } else {
            None
        }
    }
}

```

I got this by cut-and-pasting the definiton for struct MapCell<T> (and then fixing its types so I could avoid adding use statements elsewhere), and then cut-and-pasting its fn map method, and finally cut-and-pasting its fn is_some method after a compilation attempt said that was missing.

With that done, compilation continues to show the ICE.

If you “loopify” the body of MapCell::map, the ICE goes away. There is something relevant inside there.

Some intelligent (as in, non-mechanical) “expr-elimination” and “none-defaulting” gets MapCell::map down to this:

```rust
impl<T> MapCell<T> {
    pub fn map<F, R>(&self, closure: F) -> Option<R>
    where
        F: FnOnce(&mut T) -> R,
    {
            closure(None::<&mut T>.unwrap());
            loop { }
    }
}

```
Compilation still shows the same ICE here, so we haven’t lost anything yet.

And yet, this version of map does not use self at all!

This brings us to another kind of simplification: going from object methods to top-level functions.

------
> themes: Identify the Unnecessary, Trivialize Content

### Tactic: “Deobjectification”
The goal of “deobjectification” is to replace a method defined in an impl with a top-level function. Moving some necessary component for reproducing the bug out of the impl can make the impl itself unnecessary, and thus removable.

Change:

```rust
impl<X> Type<X> {
    pub fn foo<T>(&self, args: ---) -> ReturnType { --- } // where `---` does not use `Self`/`self`
}

```
to:

```rust
fn top_foo<X, T>(args: ---) -> ReturnType { --- }

```

In our case, lets try to pull MapCell::map out of MapCell:


```diff
--- a/tock/kernel/src/lib.rs
+++ b/tock/kernel/src/lib.rs
@@ -2577,6 +2577,13 @@ impl<T> MapCell<T> {
             loop { }
     }
 }
+
+fn mapcell_map<T, F, R>(closure: F) -> Option<R> where F: FnOnce(&mut T) -> R
+{
+    closure(None::<&mut T>.unwrap());
+    loop { }
+}
+
 use crate::common::{Queue, RingBuffer};
 use crate::mem::{AppSlice, Shared};
 use crate::platform::mpu::{self, MPU};
@@ -2719,7 +2726,7 @@ pub struct Process<'a, C: 'static + Chip> {

 impl<C: Chip> ProcessType for Process<'a, C> {
     unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) {
-        self.mpu_config.map(|config| {
+        mapcell_map(|config: &mut <<C as Chip>::MPU as MPU>::MpuConfig| {
             let _ = writer.write_fmt(format_args!("{}", config));
         });
     }
```

Success: compilation still ICE’s in the same way.

And now that we’ve remove the last uses of fields in self for Process, we can simplify its definition considerably:


```rust
pub struct Process<'a, C: 'static + Chip> {
    chip: &'static C,
    tasks: &'a (),
}

```
(And that simplification lets us remove the struct MapCell we added a few steps ago, since we no longer need it for the now-eliminated mpu_config field.)

So now we’ve reduced all three methods to pretty simple bodies; we had to add a fourth method (mapcell_map) in the process; but that method was always there all along as part of the puzzle. It had just been waiting for us in the upstream tock-cells crate.

Furthermore, we can apply “ret-elimination” to mapcell_map, both on the fn mapcell_map itself, and on its closure argument:

```diff
--- INDEX/tock/kernel/src/lib.rs
+++ WORKDIR/tock/kernel/src/lib.rs
@@ -2564,10 +2564,9 @@ use core::{mem, ptr, slice, str};

 use crate::callback::{AppId, CallbackId};
 use crate::capabilities::ProcessManagementCapability;
-fn mapcell_map<T, F, R>(closure: F) -> Option<R> where F: FnOnce(&mut T) -> R
+fn mapcell_map<T, F>(closure: F) where F: FnOnce(&mut T)
 {
     closure(None::<&mut T>.unwrap());
-    loop { }
 }

 use crate::common::{Queue, RingBuffer};

```

We have now gotten ourself down to the following core set of methods:


```rust

fn mapcell_map<T, F>(closure: F) where F: FnOnce(&mut T)
{
    closure(None::<&mut T>.unwrap());
}

...

pub fn load_processes<C: Chip>(chip: &'static C) { unsafe { Process::create(chip); } }

pub struct Process<'a, C: 'static + Chip> {
    chip: &'static C,
    tasks: &'a (),
}

pub trait ProcessType {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) { loop { } }
}

...

impl<C: Chip> ProcessType for Process<'a, C> {
    unsafe fn process_detail_fmt(&self, writer: &mut dyn Write) {
        mapcell_map(|config: &mut <<C as Chip>::MPU as MPU>::MpuConfig| {
            let _ = writer.write_fmt(format_args!("{}", config));
        });
    }
}

...

impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        chip: &'static C,
    ) -> &'static dyn ProcessType {
            let mut process: &mut Process<C> = None.unwrap();

            process
    }
}
```

------
> theme: Eliminate Coupling

### Technique: “Ret-ascription”
We could further reduce Process::create a tiny bit: We can remove its return type, as long as we ensure that the coercion implied by the return type still happens in the code.

This is a variant on “ret-elimination”: we again want to remove the return type from the fn signature, but this time we will also ensure that any coercions implied by the return type still occur:

Change:

```rust
fn foo(----) -> ReturnType { if A { return B; } TailReturn }
```

to:

```rust
fn foo(----) { if A { let _: ReturnType = B; } let _: ReturnType = TailReturn; }
```

For Process::create, this looks like this:

```rust
impl<C: 'static + Chip> Process<'a, C> {
    #[allow(clippy::cast_ptr_alignment)]
    crate unsafe fn create(
        chip: &'static C,
    ) {
        let mut process: &mut Process<C> = None.unwrap();

        let _: &'static dyn ProcessType = process;
    }
}
```
And furthermore, we can apply “deobjectification” and “param-elimination” here; this method doesn’t even have a self parameter.

That gets us here:

```rust
pub fn load_processes<C: Chip>(_: &'static C) { process_create::<C>(); }

fn process_create<C: 'static + Chip>() {
    let _: &'static dyn ProcessType = None::<&mut Process<C>>.unwrap();
}
```

## Take a breath
Now that all of the involved methods seem relatively small, this seems like a good time to take a breath.

At this point, we could try to take these pieces and build-up a new example from scratch, preserving the core elements identified above. That’s not a bad idea at all, at this point; it could be worth spending a half-hour or so on. Either building up an example from scratch will work, or it won’t. Let’s assume for now that we are not able to jump to a minimal example, even with the pieces we have identified as core to the problem up above?

What now?

We could attempt to remove large swaths of code from the example as it stands: After all, we know we just need these methods; can we just comment everything else out?

Well, no. You can’t just comment random things out. The interdependencies in the crate graph will frustrate attempts to do so.

For example, I tried commenting out most of the code after the mod process { ... }, in the lib.rs, and got a slew of “unresolved import” errors. So, if you want to continue reducing this exmaple, we need to do it in a more directed fashion.

In the interest of trying to follow a semi-mindless process here, lets look at what we need to do in order to really minimize kernel to its core:

1. We have to finish minimizing the leaves. There are crates unrelated to the ICE still being pulled into the build here, and they rely on things in kernel that we will not be able to remove until those crates are themselves reduced or otherwise eliminated from the crate graph.

For us, we can apply some of the other techniques we have learned about to the leaf crates, such as using “none-defaulting” to create an instance of arty_e21::chip::ArtyExx in board/argy-e21/main.rs.

2. We have to reducing the coupling within kernel itself. It can be maddening trying to comment out modules at random. When that madness becomes too much for me, I force myself to adopt a more disciplined approach: I use the “cut-spaghetti-imports” tactic to replace the existing use imports with local definitions. (Remember: since most fn-items in every module are “loopified”, the “cut-spaghetti-imports” tactic will work fairly often.
3. This goes hand-in-hand with the general point above about reducing coupling within kernel: We have to finish mimimizing mod process { ... } itself within kernel. All of the interesting functions for reproducing the bug live there, so we know we cannot “cfgment” out that module for now. But if we have to keep mod process, we won’t be able to remove the other modules until we remove the dependencies that it has on those modules.

I hope to return to this richly-documented minimization of rust-lang/rust#65774 the future; and when I do, I hope to cover all three of the points above.

But for now, I hope this was a helpful tour of various minimization technique that you can employ for reducing ICEs and other static analysis bugs in rustc.



## refer.
> 关键参考

- ...

## logging
> 版本记要

- ..
- 230228 ZQ init.

```
     _~^*~~_
 \/ /  * ◷  \ \/
   '_   ⏡   _'
   \ '--+--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```




