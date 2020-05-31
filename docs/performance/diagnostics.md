---
title: Diagnostics
parent: Performance
nav_order: 1
---

# Diagnostics

## Strategy

Always keep the following in mind when deciding whether to do optimizations:

* Does the issue exist on a real device in release mode?
* Am I sure this piece of code impacts frame times?
* Are the changes simple or are they likely to cause other issues?
* Will the code still be maintainable after I do make changes?

The worst thing you can do is premature optimization, spend as much time as possible diagnosing and understanding
performance issues before hammering away.

If the problem is complex and only happens when special conditions are met i.e. "user visits page X and gets jank after
scrolling down for some time", it is very helpful to reproduce this issue in a more controlled scenario before making
changes.

---

## Jank

The most noticeable performance issue is Jank, which is when a small number of frames take much longer than they are
supposed to.

The symptoms of jank are quite similar, but the underlying issue can vary significantly:

- CPU
  - Dart
    - Expensive tasks e.g. parsing markdown
    - Excessive widget building
    - Garbage Collection
  - Native code
    - Android APIs
    - Native views
- GPU
  - dart:ui
    - Too many paint features
    - Poor handling of `Image` objects
  - Native code
- Low memory
  - Loading too many large assets e.g. images
  - Leaks
- Power saving
  - Low battery
  
Sometimes multiple of these factors can impact frames at the same time, remember that if you think you have isolated one.

Performance testing should always be done in profile or release, on IntelliJ that can be configured like this:

![](https://i.tst.sh/XixC1.png)