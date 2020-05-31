---
title: Strategy
parent: Performance
---

# Strategy

I always keep the following in mind when deciding whether to optimize a piece of code:

* Does the issue exist on a real device in release mode?
* Am I sure this piece of code impacts frame times?
* Are the changes simple or are they likely to cause other issues?
* Will the code still be maintainable after I do make changes?

The worst thing you can do is premature optimization, spend as much time as reasonable diagnosing and understanding
performance issues before hammering away.

If the problem is complex and only happens when special conditions are met i.e. "user visits page X and gets jank after
scrolling down for some time", it is very helpful to reproduce this issue in a more controlled scenario before making
changes.
