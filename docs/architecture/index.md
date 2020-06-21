---
title: Architecture
has_children: true
nav_order: 4
---

# Architecture

These are a set of core state management patterns I use in Flutter, most of these patterns are inspired from the Flutter
framework itself.

The biggest goal of this category is to provide patterns that make code simpler, and by extension your life easier.

I encourage people to use the core patterns the framework before trying to force idioms from other ecosystems into it,
it is very important to take your time and think critically.

---

## Dart

By far the most underrated tools for state management are core features in Dart itself, I highly recommend reading
through the following if you have not already:

* [Language Tour](https://dart.dev/guides/language/language-tour) - A tour of Dart's basic syntax.
* [dart:async](https://api.dart.dev/stable/2.8.4/dart-async/dart-async-library.html) - Documentation for the dart:async
  library
* [Iterable](https://api.dart.dev/stable/2.8.4/dart-core/Iterable-class.html) - The thing that make lists do the thing.

Clever usage of Streams and Iterables will save you an insane amount of work, reading and practicing them are well worth
the time.