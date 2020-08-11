---
title: Efficient painter
parent: Architecture
wip: true
---

# Efficient painter

So, you are building a simple drawing app but are struggling to make it performant.

---

## What is painting?

Painting is simply the process of recording commands to a canvas.

More specifically, when you call methods like `Canvas.drawLine` all that happens is a small command is written to a list
somewhere internally, it is not actually rasterized by the GPU.

Because of this, persisting paints across multiple frames is not as simple as using the same canvas, you are always
going to pay O(n) each frame (where n is the number of features).

---

## A basic example

Here is a very simple example where we collect a list of points using a GestureDetector and paint them as circles with
a CustomPainter:

```dart
class _HomePageState extends State<HomePage> {
  var points = <Offset>[];

  void clear() {
    setState(() {
      points.clear();
    });
  }

  build(context) => Scaffold(
    appBar: AppBar(
      title: Text("Painter"),
      actions: [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: clear,
        ),
      ],
    ),
    body: LayoutBuilder(builder: (context, constraints) {
      var size = constraints.constrain(Size.infinite);
      return GestureDetector(
        child: CustomPaint(
          painter: DrawingPainter(points),
          size: size,
          willChange: true,
        ),
        onPanUpdate: (drag) {
          setState(() {
            points.add(drag.localPosition);
          });
        }
      );
    }),
  );
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter(this.points);

  paint(canvas, size) {
    for (var pt in points) {
      canvas.drawCircle(pt, 8, Paint()..color = Colors.blue);
    }
  }

  shouldRepaint(DrawingPainter old) => true;
}
```

<iframe width="360" height="780" src="http://i.tst.sh/rvPCC.mp4" frameborder="0" allowfullscreen></iframe>

And this feels pretty smooth, at least until we reach a few thousand points or so.

By graphing how long it takes each frame to render, we can see that every call to drawCircle costs us around 2
microseconds on the raster thread:

![](http://i.tst.sh/FVheWTZHWM.png)

The goal is to make the frame time constant instead of linear, and to do that we can use PictureRecorder.

---

## PictureRecorder

Using PictureRecorder is quite simple, we just pass it to a Canvas, call `endRecording` and then finally turn the
picture into an `Image`:

```dart
Future<ui.Image> bakeCircle() {
  var recorder = ui.PictureRecorder();
  var canvas = ui.Canvas(recorder);
  canvas.drawCircle(Offset(16, 16), 8, Paint()..color = Colors.blue);
  var picture = recorder.endRecording();
  return picture.toImage(32, 23);
}
```

Using this, we can paint our circles to a raw image instead of to the CustomPainter directly:

```dart
class _HomePageState extends State<HomePage> {
  ui.Image image;
  var points = <Offset>[];
  var baking = false;

  void clear() {
    setState(() {
      baking = false;
      image = null;
      points = [];
    });
  }

  Size size;
  double scale;

  void bake() async {
    if (baking) return;

    baking = true;

    var points = this.points;

    var numPoints = points.length;

    var recorder = ui.PictureRecorder();
    var canvas = ui.Canvas(recorder);

    canvas.scale(scale);

    DrawingPainter(image).paint(canvas, size);

    for (var pt in points) {
      canvas.drawCircle(pt, 8, Paint()..color = Colors.blue);
    }

    var picture = recorder.endRecording();
    var newImage = await picture.toImage(
      (size.width * scale).ceil(),
      (size.height * scale).ceil(),
    );

    if (points == this.points) {
      image?.dispose();

      setState(() {
        image = newImage;
      });

      points.removeRange(0, numPoints);

      baking = false;

      if (points.isNotEmpty) {
        return bake();
      }
    }
  }

  build(context) => Scaffold(
    appBar: AppBar(
      title: Text("Painter"),
      actions: [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: clear,
        ),
      ],
    ),

    body: LayoutBuilder(builder: (context, constraints) {
      size = constraints.biggest;
      scale = MediaQuery.of(context).devicePixelRatio;
      return GestureDetector(
        child: CustomPaint(
          painter: DrawingPainter(image),
          size: size,
          willChange: true,
        ),
        onPanUpdate: (drag) {
          points.add(drag.localPosition);
          bake();
        },
      );
    }),
  );
}

class DrawingPainter extends CustomPainter {
  final ui.Image image;

  DrawingPainter(this.image);

  paint(canvas, size) {
    if (image != null) {
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        Paint(),
      );
    }
  }

  shouldRepaint(DrawingPainter old) => true;
}
```

Because we paint to an image, this example does not degrade in performance over time.

But there is another problem, the time it takes to call toImage is so long that the image lags behind your actual touch
(indicated by the red dot):

<iframe width="360" height="780" src="http://i.tst.sh/RDKht.mp4" frameborder="0" allowfullscreen></iframe>

This problem can be mitigated by combining both of the above approaches, where we paint points in out CustomPainter but
render them to an image periodically.

---

## An efficient example

With a relatively simple heuristic, mixing both PictureRecorder and a regular CustomPainter gives us an efficient
solution:

```dart
class _HomePageState extends State<HomePage> {
  // The raw pixels of the canvas we create with Picture.toImage, or null.
  ui.Image image;

  // The queue of points that we should paint to the canvas.
  var points = <Offset>[];

  // Whether or not we are currently converting the canvas to an image.
  var baking = false;

  void clear() {
    setState(() {
      baking = false;
      image = null;
      points = [];
    });
  }

  // The size of the current widget, in logical pixels.
  Size size;

  // The ratio of physical pixels to logical pixels.
  double scale;

  void bake() async {
    // When the points reach a certain point, we record and render the
    // canvas to an image.
    if (points.length > 50 && !baking) {
      // Make sure we are only rendering one image at a time.
      baking = true;

      // The points instance will change if the clear button is pressed,
      // keep a copy around just in case.
      var points = this.points;

      // New points can be added while we wait for toImage to complete, so
      // we need to keep track of how many points are rendered.
      var numPoints = points.length;

      var recorder = ui.PictureRecorder();
      var canvas = ui.Canvas(recorder);

      // Use the same logical pixel scaling as our widget.
      canvas.scale(scale);

      // Invoke our CustomPainter.
      DrawingPainter(image, points).paint(canvas, size);

      // Finally render the image, this can take about 8 to 25 milliseconds.
      var picture = recorder.endRecording();
      var newImage = await picture.toImage(
        (size.width * scale).ceil(),
        (size.height * scale).ceil(),
      );

      // The clear button might have been pressed before toImage completes,
      // only apply the new image if the points instance matches what we
      // started with.
      if (points == this.points) {
        // Always dispose image objects when we don't need them anymore,
        // this should allow us to re-use the same buffers as the previous
        // frames.
        image?.dispose();

        // We don't need to setState here because the next paint would look
        // identical.
        image = newImage;

        // Remove the points we have already rendered, shifting down any
        // that were added after the toImage started.
        points.removeRange(0, numPoints);

        baking = false;
      }
    }
  }

  build(context) => Scaffold(
    appBar: AppBar(
      title: Text("Painter"),
      actions: [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: clear,
        ),
      ],
    ),

    body: LayoutBuilder(builder: (context, constraints) {
      size = constraints.biggest;
      scale = MediaQuery.of(context).devicePixelRatio;

      // Use GesutreDetector's onPanUpdate to detect taps, same as the previous
      // example.
      return GestureDetector(
        child: CustomPaint(
          painter: DrawingPainter(image, points),
          size: size,
          willChange: true,
        ),
        onPanUpdate: (drag) {
          setState(() {
            points.add(drag.localPosition);
          });
          bake();
        },
      );
    }),
  );
}

class DrawingPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;

  DrawingPainter(this.image, this.points);

  paint(canvas, size) {
    if (image != null) {
      // Draw our baked image, scaling it down with drawImageRect.
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        Paint(),
      );
    }

    // Paint any unbaked points.
    for (var pt in points) {
      canvas.drawCircle(pt, 8, Paint()..color = Colors.blue);
    }
  }

  shouldRepaint(DrawingPainter old) => true;
}
```

And finally, we have the same performance as our first example but without degrading over time.