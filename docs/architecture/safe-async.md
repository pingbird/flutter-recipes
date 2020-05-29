---
title: Safe Async
parent: Architecture
---

# Safe Async

## The most common mistake

Quite frequently I see code using `FutureBuilder` or `StreamBuilder` incorrectly:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: Firestore.instance.collection('foobar').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('${snapshot.data}');
    } else {
      return CircularProgressIndicator();
    }
  },
)
```

Despite looking quite innocent, this is problematic for a few reasons:

1. Errors from the AsyncSnapshot are silently ignored.
2. An async task is started during build, which will re-start when rebuilt.
3. Direct query instead of a request through state management or a network layer.

Thankfully these issues are easy to fix, the rest of this section provides in-depth suggestions for each.

---

### Error handling

FutureBuilder and StreamBuilder have flaws when it comes to error handling, the only way to know if an error has
occurred is to manually either:

{:type="a"}
1. Use `Future.catchError` or `Stream.handleError`, requiring an extra closure.
2. Print the error in the AsyncSnapshot without a stack trace, duplicating the message when it rebuilds.

This is far from ideal, thankfully I have a better solution and published it in a package called
[async_builder](https://pub.dev/packages/async_builder), this package allows you to rewrite the above code to the following:

```dart
AsyncBuilder<DocumentSnapshot>(
  stream: Firestore.instance.collection('foobar').snapshots(),
  waiting: (context) => CircularProgressIndicator(),
  builder: (context, data) => Text('$data'),
)
```

Which will properly handle errors emitted by the stream, including printing the stack trace and other debug information
like where the widget is located in the tree.

That solves error handling, but there are still issues in this example with how the stream is created.

---

### Avoiding build side-effects

So starting asynchronous tasks like `Firestore.instance.collection('foobar').snapshots()` during build is bad practice,
what do we do instead?

The two approaches I will cover are:

1. [The initState solution](#the-initstate-solution)
2. [The state management solution](#the-state-management-solution)

---

### The initState solution

```dart
class _MyWidetState extends State<MyWidet> {
  Stream<DocumentSnapshot> foobar;

  @override
  void initState() {
    super.initState();
    foobar = Firestore.instance.collection('foobar').snapshots();
  }

  @override
  Widget build(BuildContext context) => AsyncBuilder(
    stream: foobar,
    builder: (context, snapshot) => ...,
  );
}
```

Now our request will not restart every build, nice!

We can reduce the boilerplate quite a bit though, I've made a widget called `InitBuilder` which is published as
.

Instead of creating a whole new StatefulWidget, we can do this instead:

```dart
class MyWidget extends StatelessWidget {
  static Stream<DocumentSnapshot> getFoobar() =>
    Firestore.instance.collection('foobar').snapshots();
  
  @override
  Widget build(BuildContext context) => InitBuilder(
    getter: getFoobar,
    builder: (context, stream) => AsyncBuilder<DocumentSnapshot>(
      stream: stream,
      waiting: (context) => ...,
      builder: (context, snapshot) => ...,
    ),
  );
}
```

Making `getFoobar` static here is important, if we pass it an anonymous function directly it would be forced to make
the request every build because the closure instance would be different.

And you are done! The above example is safe to use.

---

### The state management solution

Using state management here has two benefits, first it allows you to avoid multiple widgets requesting snapshots at the
same time, second it allows you swap out the underlying supplier of information whether it be for tests or to migrate
away from firebase.

For a continuously updating resource, [RxDart](https://pub.dev/packages/rxdart) `BehaviorSubject`s are a very nice way
to hold a value while notifying listeners:

```dart
class MyServiceImpl {
  ...
  BehaviorSubject<Foobar> _foobar; // Don't forget to dispose!
  
  ValueStream<Foobar> get foobar => _foobar ??= BehaviorSubject<Foobar>()..addStream(
    Firestore.instance
      .collection('foobar').snapshots().map(Foobar.fromJson)
  );
  ...
}
```

This basically just creates a `BehaviorSubject` that wraps snapshots from the firestore, allowing listeners to have an
up to date Foobar without making any new requests.

The instance is also cached, which is very important to prevent side-effects.

```dart
AsyncBuilder<DocumentSnapshot>(
  stream: Service.of(context).foobar,
  waiting: (context) => CircularProgressIndicator(),
  builder: (context, data) => Text('$data'),
)
```

If you want something a bit lighter but more verbose consider using `ChangeNotifier` / `ValueNotifier` instead.

