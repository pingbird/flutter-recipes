---
title: Dart defines
parent: FAQ
---

# Dart defines

If you are looking for a feature similar to environment variables, this is how you implement them.

In Dart code, defines can be accessed through the following methods:

```dart
print(int.fromEnvironment('someInt'));
print(bool.fromEnvironment('someBool'));
print(String.fromEnvironment('someString'));
```

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