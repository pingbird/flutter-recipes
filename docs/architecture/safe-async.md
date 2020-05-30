---
title: Safe Async
parent: Architecture
---

# Safe Async

## Common mistake

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

Thankfully these issues are easy to fix, the rest of this post provides in-depth suggestions for each.

---

## Error handling

FutureBuilder and StreamBuilder have flaws when it comes to error handling, the only way to know if an error has
occurred is to manually either:

{:type="a"}
1. Use `Future.catchError` or `Stream.handleError`, requiring an extra closure.
2. Print the error in the AsyncSnapshot without a stack trace, duplicating the message when it rebuilds.

This is far from ideal, thankfully there is a better solution in [package:async_builder](https://pub.dev/packages/async_builder).
This package provides the [AsyncBuilder](https://pub.dev/documentation/async_builder/latest/async_builder/AsyncBuilder-class.html)
Widget which allows you to rewrite the above code to the following:

```dart
AsyncBuilder<DocumentSnapshot>(
  stream: Firestore.instance.collection('foobar').snapshots(),
  waiting: (context) => CircularProgressIndicator(),
  builder: (context, data) => Text('$data'),
)
```

This will properly handle errors emitted by the stream or future, including printing the stack trace and other debug
information like where the widget is located in the tree.

That solves error handling, but this sample code still has another flaw which is that building it has side effects.

---

## Avoiding build side effects

If you call a function directly to start an asynchronous task during build, that task will restart whenever the widget
re-builds, potentially causing loss of state, infinite loops, and annoying flashes.

So starting asynchronous tasks like `Firestore.instance.collection('foobar').snapshots()` during build is bad practice,
what should we do instead?

The two approaches I will cover are:

1. [The widget solution](#the-widget-solution)
2. [The state management solution](#the-state-management-solution)

---

## The Widget solution

The most basic solution is to create a new StatefulWidget and start the asynchronous task inside of initState.

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

We can do better though, [package:async_builder](https://pub.dev/packages/async_builder) also includes
[InitBuilder](https://pub.dev/documentation/async_builder/latest/init_builder/InitBuilder-class.html) which is a widget
that can initialize and cache our stream safely.

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

But what if your getter takes arguments, like requesting from an http api for example?

With StatefulWidget, this is a bit involved because you have to check if the key changed after being rebuilt:

```dart
class MyWidget extends StatefulWidget {
  MyWidget({this.keyName});

  final String keyName;

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidetState extends State<MyWidet> {
  Future<String> future;

  void updateFuture() {
    future = api.getString(widget.keyName);
  }

  @override
  void initState() {
    super.initState();
    updateFuture();
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    if (widget.keyName != oldWidget.keyName) {
      updateFuture();
    }
  }
  
  @override
  Widget build(BuildContext context) => AsyncBuilder(
    stream: future,
    builder: (context, value) => Text('$value'),
  );
}
```

With the `InitBuilder.arg` constructor this can be rewritten as:

```dart
class MyWidget extends StatelessWidget {
  MyWidget({this.keyName});

  final String keyName;

  @override
  Widget build(BuildContext context) => InitBuilder.arg<String, String>(
    getter: api.getString,
    arg: keyName,
    builder: (context, future) => AsyncBuilder(
      future: future,
      builder: (context, value) => Text('$value'),
    ),
  );
}
```

And you are done! The last four examples are safe to use.

---

## The state management solution

Using state management here has two benefits, first it allows you to avoid multiple widgets requesting snapshots at the
same time, second it allows you swap out the underlying supplier of information whether it be for tests or to migrate
away from firebase.

For a continuously updating resource, [package:rxdart](https://pub.dev/packages/rxdart) [BehaviorSubject](https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html)s
are a very nice way to hold a value and notify listeners at the same time:

```dart
class MyService {
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

The important part is that the instance is cached, which is very important to prevent side effects.

```dart
AsyncBuilder<DocumentSnapshot>(
  stream: MyService.of(context).foobar,
  waiting: (context) => CircularProgressIndicator(),
  builder: (context, data) => Text('$data'),
)
```

With [AsyncBuilder](https://pub.dev/documentation/async_builder/latest/async_builder/AsyncBuilder-class.html), the builder
can use the current value of our `BehaviorSubject` on first build, avoiding the single-frame loading indicator that
`StreamBuilder` would show.

If you want something a bit lighter consider using `ValueNotifier` / `ValueListenableBuilder` instead.

But what if you are requesting something based on its key like in the last two StatefulWidget examples?

What I typically do in this case is cache the futures or streams in a map:

```dart
class MyService {
  ...
  final MyApi api;

  var _foobars = <String, Future<Foobar>>{};

  Future<Foobar> getFoo(String key) =>
    _foobars[key] ??=
      api.getFoobar(key)
        ..then((value) => _foobars[key] = SynchronousFuture(value));
  ...
}
```

Like before, any tasks created by the service are cached to ensure work isn't being duplicated.

I'm assigning `SynchronousFuture` because it allows the value to be available on first build if cached, similar to the
`ValueStream` example.

```dart
class MyWidget extends StatelessWidget {
  MyWidget({this.keyName});

  final String keyName;

  @override
  Widget build(BuildContext context) => AsyncBuilder<Foobar>(
    future: MyService.of(context).getFoo(keyName),
    waiting: (context) => CircularProgressIndicator(),
    builder: (context, data) => Text('$data'),
  );
}
```

These are some basic patterns that may or may not apply to your use case, if there is anything missing or if you have
questions please don't hesitate to ping me on Discord.

---