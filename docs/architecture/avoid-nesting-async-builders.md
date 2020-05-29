---
title: Avoid nesting async builders
parent: Architecture
---

# Avoid nesting async builders

Sometimes you might want to nest asynchronous builders, like so:

```dart
build(context) => InitBuilder.arg2<User, String>(
  getter: getUser,
  arg: userId,
  builder: (context, future) => AsyncBuilder(
    future: future,
    builder: (context, user) => InitBuilder.arg<String, Friends>(
      getter: user.searchFriends,
      arg: queryString,
      builder: (context, future) => AsyncBuilder(
        future: future,
        builder: (context, friends) => Text('Name: ${user.name} Friends: $friends'),
      ),
    ),
  ),
);
```

Other than being ugly, this can also cause the progress indicator to look like its stuttering as it would get re-created
when the first future completes.

What you should do instead is make a function that completes with both the values at once:

```dart
static Tuple2<User, Friends> getUserAndFriends(String userId, String queryString) async {
  var user = await getUser(userId);
  var friends = await user.searchFriends(queryString);
  return Tuple2(user, friends);
}

build(context) => InitBuilder.arg2<Tuple2<User, Friends>, String, String>(
  getter: getUserAndFriends,
  arg1: userId,
  arg2: queryString,
  builder: (context, future) => AsyncBuilder(
    future: future,
    builder: (context, tuple) => Text('Name: ${tuple.item1.name} Friends: ${tuple.item2}'),
  ),
);
```

In this case I'm using a [Tuple2](https://pub.dev/documentation/tuple/latest/tuple/Tuple2-class.html) from
[package:tuple](https://pub.dev/packages/tuple) to return two values at the same time.