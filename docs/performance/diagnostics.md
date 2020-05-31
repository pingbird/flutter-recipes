---
title: Diagnostics
parent: Performance
---

# Diagnostics

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
  - Loading too many large assets
  - Leaks
  - 
- Power saving
  - Low battery

Keep in mind timelines can be skewed and make it seem like one component was at fault when its really a separate issue.
Its always good to double check by enabling performance overlays in the developer options.

Make sure to do this in profile mode, on IntelliJ that can be configured here:

![](https://i.tst.sh/XixC1.png)