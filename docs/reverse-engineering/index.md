---
title: Reverse Engineering
has_children: true
nav_order: 3
---

### Most of this section is part of my blog post, you can check it out [here](https://blog.tst.sh/reverse-engineering-flutter-apps-part-1/).

# Reverse Engineering

To start this journey I'll cover some backstory on the Flutter stack and how it works.

What you probably already know: Flutter was built from the ground up with its own render pipeline and widget library,
allowing it to be truly cross platform and have a consistent design and feel no matter what device its running on.

Unlike most platforms, all of the essential rendering components of the flutter framework (including animation, layout,
and painting) are fully exposed to you in [package:flutter](https://github.com/flutter/flutter/tree/master/packages/flutter).

You can see these components in the official architecture diagram from wiki/The-Engine-architecture:

![](https://blog.tst.sh/content/images/2020/02/framework.png)

From a reverse engineering perspective the most interesting part is is the Dart layer since that is where all of the app
logic sits.

But what does the Dart layer look like?

Flutter compiles your Dart to native assembly code and uses formats that have not been publicly documented in-depth let
alone fully decompiled and recompiled.

For comparison other platforms like React Native just bundle minified javascript which is trivial to inspect and modify,
additionally the bytecode for Java on Android is well documented and there are many free decompilers for it.

Despite the lack of obfuscation (by default) or encryption, Flutter apps are still extremely difficult to reverse
engineer at the moment since it requires in-depth knowledge of Dart internals to even scratch the surface.

This makes Flutter very good from an intellectual property perspective, your code is almost safe from prying eyes.
Next I'll show you the build process of Flutter applications and explain in detail how to reverse engineer the code that
it produces.