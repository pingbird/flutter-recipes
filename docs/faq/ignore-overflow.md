---
title: Ignoring overflow
parent: FAQ
---

# Ignoring overflow

The only two widgets that throw this error are `Flex` (`Row` / `Column`) and `UnconstrainedBox`, the former is obviously
the most common.

The problem is not actually the fault of the Flex itself, rather the constraints given by its parent. In order to solve
this issue the main axis constraint needs to either be *unbounded* i.e. have a maximum main axis size of
`double.infinity` or have a `clipBehavior` of `Clip.none`.

The simplest way to ignore overflow is to use `Flex` instead set the clip:

```dart
Flex(
  direction: Axis.horizontal,
  clipBehavior: Clip.none,
  children: [
    Some(), Long(), Widgets(),
  ],
)
```

Or using OverflowBox:

```dart
OverflowBox(
  maxWidth: double.infinity,
  child: Row(children: [
    Some(), Long(), Widgets(),
  ]),
)
```

I've seen some people use `Wrap` to achieve a similar result, I highly discourage that because the fact that `Wrap`
doesn't check for overflow is probably an oversight and may change in the future.