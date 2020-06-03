---
title: Dart defines
parent: FAQ
---

# Dart defines

If you are looking for a feature similar to environment variables, this is how you implement them.

In Dart code, defines can be accessed through the following methods:

```dart
const someInt = int.fromEnvironment('someInt');
const someBool = bool.fromEnvironment('someBool');
const someString = String.fromEnvironment('someString');
```

When using the front-end separately, fromEnvironment should only be called in a const expression because it won't be
available at runtime, this includes Flutter apps.

## Flutter

Defines in flutter can be passed to run and build:

```sh
flutter run --dart-define=someString=foo
```

```sh
flutter build apk --dart-define=someString=foo
```

## Dart

Defines can be passed to the regular dart command through the undocumented `-D` argument:

```sh
dart -DsomeString=foo bin/main.dart
```

## Secret keys

This is not a solution to providing "secret" keys to a Flutter application, if a key is secret then it should not be
included at all.

It's perfectly fine to include public keys in dart code and push them to git, e.g. a token for the Google Maps API.