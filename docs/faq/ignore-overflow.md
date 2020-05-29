---
title: Ignoring overflow
parent: FAQ
---

# Ignoring overflow

If you are here, you are probably looking for a parameter or configuration option to get rid of an annoying overflow
error. Of course if it were that simple, this post would not exist.

In the majority of cases this is due to a faulty layout plain and simple, I'm going to give the benefit of the doubt and
assume you have a legitimate reason for needing overflow.  

The only two widgets that throw this error are `Flex` (`Row` / `Column`) and `UnconstrainedBox`, the former is obviously
the most common.

The problem is not actually the fault of the Flex itself, rather the constraints given by its parent. In order to solve
this issue the main axis constraint needs to be *unbounded* i.e. have a maximum main axis size of `double.infinity`.

The simplest way to give your layout the desired constraints is to use OverflowBox:

```dart
OverflowBox(
  maxWidth: double.infinity,
  child: Row(children: [
    Some(), Long(), Widgets(),
  ]),
)
```

I've seen some people use `Wrap` to achieve a similar result, I highly discourage that because the fact that `Wrap`
doesn't check for overflow is probably an oversight and may be fixed in the future.