---
title: Nesting async builders
parent: Architecture
---

# Nesting async builders

## Basic nesting

Sometimes you might want a widget to depend on the result of multiple asynchronous tasks, including having one request
depend on the result of another.

In this example we are calling `getUser` with a `userId` string to get a `User` object, then once that is complete we
call `user.searchFriends` to get a `Friends`, finally once that is complete we build a `Text` that uses them:

```dart
build(context) => InitBuilder.arg<Future<User>, String>(
  getter: getUser,
  arg: userId,
  builder: (context, future) => AsyncBuilder<User>(
    future: future,
    waiting: (context) => CircularProgressIndicator(),
    builder: (context, user) => InitBuilder.arg<Future<Friends>, String>(
      getter: user.searchFriends,
      arg: queryString,
      builder: (context, future) => AsyncBuilder<Friends>(
        future: future,
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, friends) =>
          Text('Name: ${user.name} Friends: $friends'),
      ),
    ),
  ),
);
```

Other than being ugly, this can also cause the progress indicator to look like its stuttering as it would get re-created
when the first future completes.

What you should do instead is make a function that completes with every value required by the UI at once:

```dart
static Tuple2<User, Friends> getUserAndFriends(
  String userId,
  String queryString,
) async {
  var user = await getUser(userId);
  var friends = await user.searchFriends(queryString);
  return Tuple2(user, friends);
}

build(context) =>
  InitBuilder.arg2<Future<Tuple2<User, Friends>>, String, String>(
    getter: getUserAndFriends,
    arg1: userId,
    arg2: queryString,
    builder: (context, future) => AsyncBuilder(
      future: future,
      builder: (context, tuple) =>
        Text('Name: ${tuple.item1.name} Friends: ${tuple.item2}'),
    ),
  );
```

In this case we're using a [Tuple2](https://pub.dev/documentation/tuple/latest/tuple/Tuple2-class.html) from
[package:tuple](https://pub.dev/packages/tuple) to return two values at the same time.

---

## Streams

Another common problem is when you build widgets from a stream, but then need to make another request to make depending
on the information from the stream.

In this example, we take a stream of `User`s rather than a future, but requests `Friends` in the same way:

```dart
build(context) => InitBuilder<Stream<User>, String>(
  getter: getUsers,
  builder: (context, stream) => AsyncBuilder(
    stream: stream,
    waiting: (context) => CircularProgressIndicator(),
    builder: (context, user) => InitBuilder.arg<String, Friends>(
      getter: user.searchFriends,
      arg: queryString,
      builder: (context, future) => AsyncBuilder(
        future: future,
        waiting: (context) => CircularProgressIndicator(),
        builder: (context, friends) =>
          Text('Name: ${user.name} Friends: $friends'),
      ),
    ),
  ),
);
```

What you can do instead is use `Stream.asyncMap` to add friends to the stream so that we only need a single builder:

```dart
static Stream<Tuple2<User, Friends>> getUsersAndFriends(
  String queryString,
) => getUsers().asyncMap((user) async =>
  Tuple2(user, await user.getFriends(queryString)));

build(context) => InitBuilder.arg<Stream<Tuple2<User, Friends>>, String>(
  getter: getUsersAndFriends,
  arg: queryString,
  builder: (context, stream) => AsyncBuilder(
    stream: stream,
    waiting: (context) => CircularProgressIndicator(),
    builder: (context, tuple) =>
      Text('Name: ${tuple.item1.name} Friends: ${tuple.item2}'),
  ),
);
```
