---
title: Type System
parent: FAQ
---

# Type System

## What are types

A type is an abstract identifier used to describe the interface an instance has, here are a few ways to declare them:

```dart
// Foo is now an interface type.
class Foo {}

// FooFn is now an alias of the `Foo Function()` type.
typedef FooFn = Foo Function();

// You can now create interface types of Bar with any subtype of Foo as the type argument.
class Bar<T extends Foo> {
  // T is a subtype of Foo in this context.
}
```

At the highest level, there are only a handful kinds of types:

{:type="a"}
1. `dynamic`
2. `void`
3. interface types
4. function types
5. parameter types

The most common is interface types, which describe a class with its resolved type arguments.

`dart:core` contains a bunch of classes with special type properties, I'll cover those below.

## Instances

Throughout an object's lifetime, it has a single type, this type is determined when constructed and can never be changed:

```dart
int x = 2;
num y = x;
print(x is int); // true
print(y is int); // true
int z = y as int; // works
```

The type used to declare a variable is only the interface, it can store any assignable instance that implements said
interface.

## Methods

When you call a method on an instance, the type the instance was created with always determines the implementation of
that method, for example:

```dart
class Foo {
  void hi() => print("i am foo");
}

class Bar implements Foo {
  void hi() => print("i am bar");
}

void callHi(Foo foo) => foo.hi();

void main() {
  callHi(Bar()); // prints "i am bar"
}
```

Here, `Bar`'s implementation of `hi` will always override calls from its instances, regardless of what context its in.

All types visible to dart code are a subtype of `Object` and inherit the default implementation of its interface.

Dart is strongly typed, that means the compiler can make strong guarantees about the type a value will have at runtime.

Strong typing does not mean methods are guaranteed to exist though, if a method is missing when called, dart
calls the `noSuchMethod` method which will throw a `NoSuchMethodError` by default.

```dart
(42 as dynamic).foo(); // throws NoSuchMethodError
```

All field access on instances is done through calls to setter and getter methods.

When you declare a field inside of a class, it implicitly declares setter and getter methods that read and write to an
internal variable.
This is different from C# for example, where setters / getters and fields are incompatible declarations.

```
class Foo {
  int a; // This declares both set:a and get:a
}

class Bar extends Foo {
  int get a => super.a * 2; // This overrides get:a without touching set:a
}

main() {
  var foo = Bar();
  foo.a = 2;
  print(foo.a); // prints 4
}
```

## Assignability

A variable can contain values that are not actual subtypes of its declared type, specifically null:

```dart
int x;
print(x is int); // false
```

This prints false because the `is` operator is a subtype check, not an assignability check.

The `as` operator on the other hand does do an assignability check:

```dart
int x;
print(x as int); // null, works
```

This is because a value `x` is assignable to `T` if either:

{:type="a"}
1. `x`'s runtime type is a subtype of `T`.
2. x is null and `T` is nullable.

## Null vs void vs dynamic vs Object

The `Null` class is special, it throws a formatted `NoSuchMethodError` when methods other than `get:hashCode`,
`get:runtimeType`, and `operator==` are called.

The `dynamic` and `void` types are both effectively an alias for `Object`, but change how visible methods are:

* With `Object`, you can only access methods from the `Object` interface (just like a regular class), i.e. `hashCode`.
* With `void`, you can store and cast, but not access any methods.
* With `dynamic`, you can access any methods and call it with any arguments, those return values are also treated as
`dynamic`.

## Closures

Extraction is the process of taking an instance method and turning it into a closure, this is commonly called a tear-off.

Methods can be extracted by calling the getter with their name:

```dart
typedef ToStringFn = String Function();
ToStringFn getToString(Object x) => x.toString;
```

In this example we extract the `toString` method from an arbitrary object `x`, giving us a closure that can be called
as if it was a regular instance call on `x`.

The above code is effectively the same thing as:

```dart
typedef ToStringFn = String Function();
ToStringFn getToString(Object x) => () => x.toString();
```

Except the former is a bit more efficient.

`Function`s are very special, they can actually refer to two different things:

{:type="a"}
1. Function types declared with arguments and return type, i.e. `void Function() foo;`.
2. The `Function` class as an interface type, which is a super type of any function.

Function types are similar to generic interface types, but can describe parameter names and types.

All function types are subtypes of `Function`, regardless of their return type and arguments:

```dart
print(print is Function); // true
```

## Callable classes

Classes can be callable... kinda.

```dart
class Foo {
  void call() => print('hi');
}

void main() {
  Foo()(); // prints "hi"
}
```

This is actually a little deceiving, `Foo` instances themselves are not actually callable, what's happening is that
the `call` method is being implicitly extracted.

Implicit tear-offs have some caveats, for example:

```dart
void callFoo(void Function() x) {
  print(x is Foo); // false
  print(x is Function); // true
  x();
}

void main() {
  var x = Foo();
  print(x is Foo); // true
  print(x is Function); // false
  callFoo(x);
}
```

