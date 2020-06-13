---
title: Single Child Render Objects
parent: Framework
wip: true
---

# Single Child Render Objects

In this post, we will implement a basic single-child render box from scratch.

## SingleChildRenderObjectWidget

To keep it simple, all this widget will do is lay itself out like a square:

```dart
/// A container that sizes itself as a square depending on the largest dimension
/// of the child, centering it.
class Square extends SingleChildRenderObjectWidget {
  Square({
    Key key,
    Widget child,
  }) : super(
    key: key,
    child: child,
  );

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSquare();
}
```

## RenderBox

First, create the `RenderBox` implementation and mixin `RenderObjectWithChildMixin` for convenience:

```dart
class RenderSquare extends RenderBox
  with RenderObjectWithChildMixin<RenderBox> {
  ...
```

The core of the render layer is layout and paint, `RenderObject`s implement their layout logic in the `performLayout`
method:

```dart
  @override
  void performLayout() {
    if (child == null) {
      // RenderObjects must have a size after layout, and that size
      // be within the constraints provided to it.
      //
      // Since there is no child, just use the smallest allowed.
      size = constraints.smallest;
    } else {
      // If a RenderObject has a child, it must be layed out at
      // least once.
      //
      // The constraints parameter tells the child what the upper
      // and lower bounds of its size can be, just like how we
      // handle incoming constraints to RenderSquare. The child's
      // size is forced to fit these constraints, even if it leads
      // to overpainting or other layout problems.
      //
      // A child's size can only be used by us if it has been
      // layed out AND parentUsesSize is true. In situations where
      // our layout does not depend on the size of the child, the
      // parentUsesSize argument can be false.
      child.layout(constraints, parentUsesSize: true);

      // Now that the child has been layed out, we can grab its size.
      final childSize = child.size;

      // Calculate the width of our square by taking the maximum of
      // the child's width and height.
      final width = max(childSize.width, childSize.height);

      // Size ourselves to the closest size that still fits within
      // the constraints given by our parent.
      size = constraints.constrain(Size.square(width));

      // Each RenderObject has a `parentData` field that is managed
      // by its parent, this is initialized when the child is mounted
      // with our `setupParentData` method. The default implementation
      // for `RenderBox.setupParentData` initializes the child's
      // parentData field with a BoxParentData.
      //
      // In this case, we use BoxParentData to give the child a
      // paint offset, this offset can then read by other methods
      // like `paint` and `applyPaintTransform`.
      final parentData = child.parentData as BoxParentData;

      // Center the child vertically and horizontally into our size.
      parentData.offset = Offset(
        (size.width - childSize.width) / 2,
        (size.height - childSize.height) / 2,
      );
    }
  }
```

Finally, implement the paint method:

```dart
  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      // Paint always happens after the layout phase is complete,
      // so we can safely access the parentData from before.
      final parentData = child.parentData as BoxParentData;

      // We call PaintingContext.paintChild to paint the child,
      // you can paint a specific child either once or not at all
      // per frame.
      context.paintChild(child, parentData.offset + offset);
    }
  }
```

## Result

When combined with ClipOval and Container, this creates a perfectly circular bubble that matches the size of its
child:

![](https://i.tst.sh/DgBDX.gif)