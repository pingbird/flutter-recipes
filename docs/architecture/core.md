---
title: Core
parent: Architecture
wip: true
---

# Core

These are a set of core state management patterns I use in Flutter, most of these patterns are inspired from the Flutter
framework itself.

---

## Simplicity

The biggest goal of this article is to provide patterns that make code simpler, and by extension your life easier.

Very often I see architectures that simply make your life harder without providing tangible value to a codebase, the
biggest example being MVC.

Flutter is one of a kind, what works well in other UI frameworks does not necessarily work well in Flutter, which is
why I encourage people to use the core patterns the framework instead of trying to shim idioms from other ecosystems
into it.

Many patterns revolve around separation of business logic and UI, in Flutter this is not an important goal because
the widget layer was designed explicitly to accommodate both business logic and UI, without impacting the performance
of rendering.

Reducers are also not something im a fan of, the primary reason I don't like reducers is not actually the concept itself
but because Dart lacks concise syntax for tagged unions. While it may be a little easier to reason around reducers, I
still feel like its too much work to write compared to an object oriented solution.

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