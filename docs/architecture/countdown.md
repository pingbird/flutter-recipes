---
title: Countdown
parent: Architecture
---

# Countdown

In this post we will build a simple countdown that:

1. Is consistent and accurate.
2. Continues counting in the background, but not when closed or killed.
3. Does not rebuild when out of view.

## Creating the UI

```dart
class CountdownPage extends StatefulWidget {
  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  /// Formats a duration to 'mm:ss'.
  static String formatDuration(Duration d) =>
    '${'${d.inMinutes}'.padLeft(2, '0')}:'
    '${'${d.inSeconds % 60}'.padLeft(2, '0')}';
  
  /// Whether or not the widget is counting down.
  var running = false;

  /// How long the countdown should be.
  final duration = Duration(minutes: 5);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text('Countdown'),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).pushNamed('settings');
          },
        )
      ],
    ),
    body: SizedBox.expand(child: Align(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          child: Text(formatDuration(duration), style: TextStyle(
            fontSize: 60,
            fontFamily: "monospace",
          )),
          padding: EdgeInsets.only(bottom: 50),
        ),
        RaisedButton(
          child: Text(running ? "Stop" : "Start"),
          onPressed: () => setState(() {
            running = !running;
          }),
          color: running ? Colors.red : Colors.blue,
        ),
      ],
    ))),
  );
}
```

![](https://i.tst.sh/TAGUK.png)

## Counting down

The core of this countdown is `timer` and `endTime`, these can tell us when the UI should update and how much time is
remaining.

Notice that we aren't actually counting down, instead we have a specific end time. The remaining time is calculated by
subtracting the current and end time, effectively enabling it to continue in the background.

```dart
  /// How long the countdown should be.
  var duration = Duration(minutes: 5);

  /// When the running timer will hit zero.
  DateTime endTime;

  /// A timer that periodically fires to update the UI.
  Timer timer;

  /// The remaining time before the countdown stops.
  Duration remainingTime;

  /// How long until the next tick should fire, i.e. the next time the seconds
  /// remaining will change.
  Duration get nextTick =>
    remainingTime - Duration(seconds: remainingTime.inSeconds);

  /// Updates the UI and schedules the next tick.
  void tick() {
    setState(() {});
    remainingTime = endTime.difference(DateTime.now());
    if (remainingTime > Duration.zero) {
      timer = Timer(nextTick, tick);
    } else {
      // Countdown is finished!
      stopCountdown();
    }
  }

  /// Starts [timer], if not running already.
  void startTimer() {
    if (timer != null || !running) return;
    tick();
  }

  /// Stops [timer], if not stopped already.
  void stopTimer() {
    if (timer == null) return;
    timer.cancel();
    timer = null;
  }

  /// Starts the countdown
  void startCountdown() {
    running = true;
    endTime = DateTime.now().add(duration);
    startTimer();
  }

  /// Stops the countdown
  void stopCountdown() {
    running = false;
    stopTimer();
    remainingTime = duration;
    setState(() {});
  }
```

## TickerMode

When a page is not visible, the navigator will disable the TickerMode for its subtree.

This is the same mechanism that pauses animations, you can use `TickerMode.of(context)` to check its state:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (TickerMode.of(context)) {
      startTimer();
    } else {
      stopTimer();
    }
  }
```

This will start and stop our timer when the ticker mode changes, preventing the widget from consuming cpu while another
page is above it.

## Hooking up the UI

The only thing left to do is hook up the UI, first update the countdown text:

```dart
          child: Text(formatDuration(remainingTime ?? duration), style: TextStyle(
            fontSize: 60,
            fontFamily: "monospace",
          )),
```

Then make the button below it call startCountdown / stopCountdown:

```dart
        RaisedButton(
          child: Text(running ? "Stop" : "Start"),
          onPressed: running ? stopCountdown : startCountdown,
          color: running ? Colors.red : Colors.blue,
        ),
```

## Final result

Here is a video of the app:

<iframe width="360" height="780" src="https://i.tst.sh/ELNIY.mp4" frameborder="0" allowfullscreen></iframe>

As you can see, the stopwatch continues running when paused.

With debug prints you can confirm that the timer pauses while the settings menu is open.

## Live demo

Here is a link to a live demo on dartpad:
[https://dartpad.dartlang.org/0d3b02d838120eb57e0c3ad47eb76aad](https://dartpad.dartlang.org/0d3b02d838120eb57e0c3ad47eb76aad)