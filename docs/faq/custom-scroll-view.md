---
title: CustomScrollView
parent: FAQ
---

# CustomScrollView

CustomScrollView is a widget that allows you to do create layouts that are dependent on the scroll offset, this is the
same mechanism behind widgets like `ListView.builder`.

Another helpful resource on slivers can be found here: https://flutter.dev/docs/development/ui/advanced/slivers

---

## ListView.builder

So, you want to make a list like this:

```dart
ListView(children: [
  Text('🔥'),
  ListView.builder(
    itemCount: 100,
    itemBuilder: (context, i) => ListTile(
      title: Text('Foo $i'),
    ),
  ),
])
```

But this causes an error because the inner ListView was given an unbounded height.

The best way to solve this is to convert this into a CustomScrollView:

```dart
CustomScrollView(slivers: [
  SliverToBoxAdapter(
    child: Text('🔥'),
  ),
  SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, i) => ListTile(
        title: Text('Foo $i'),
      ),
      childCount: 100,
    ),
  ),
])
```

---

## Going deeper

Sometimes you might want to put your lazily building list inside of something like a card, for example:

```dart
CustomScrollView(slivers: [
  SliverToBoxAdapter(
    child: Text('🔥'),
  ),
  Card(
    child: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => ListTile(
          title: Text('Foo $i'),
        ),
        childCount: 100,
      ),
    ),
  ),
])
```

Unfortunately, putting a sliver widget inside of a card like this isn't possible with core Flutter widgets, thankfully I
wrote a package that does exactly that: https://pub.dev/packages/boxy

With this package, we can just replace `Card` with `SliverCard`:

```dart
CustomScrollView(slivers: [
  SliverToBoxAdapter(
    child: Text('🔥'),
  ),
  SliverCard(
    child: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => ListTile(
          title: Text('Foo $i'),
        ),
        childCount: 100,
      ),
    ),
  ),
])
```

This gives us an effect like the following demo, where the children of the SliverList are still dynamically created and
destroyed:

![](https://i.tst.sh/ua72L.gif)