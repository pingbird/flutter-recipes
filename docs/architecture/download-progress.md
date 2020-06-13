---
title: Download Progress
parent: Architecture
---

# Download Progress

In this post we will build a simple file downloader that shows a visual indication of progress.

---

## Creating the UI

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var downloading = false;
  var done = false;
  double progress;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text('Downloader'),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {},
        )
      ],
    ),
    body: SizedBox.expand(child: Align(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (downloading)
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: progress,
            ),
          )
        else if (done) ...[
          Image.network('https://i.tst.sh/XaY4i.jpg'),
          Padding(
            padding: EdgeInsets.all(8),
            child: RaisedButton(
              child: Text('Reset'),
              onPressed: () {
                setState(() {
                  done = false;
                });
              },
            ),
          )
        ] else
          RaisedButton(
            child: Text('Start'),
            onPressed: () async {
              setState(() {
                downloading = true;
                progress = null;
              });

              for (int i = 0; i <= 100; i++) {
                setState(() {
                  progress = i / 100;
                });
                await Future.delayed(Duration(milliseconds: 25));
              }

              setState(() {
                downloading = false;
                done = true;
              });
            },
          ),
      ],
    ))),
  );
}
```

This is just a wireframe and does not actually download data.

<iframe width="360" height="780" src="https://i.tst.sh/n8X0N.mp4" frameborder="0" allowfullscreen></iframe>

---

## Download with progress

Using `package:http` we can do a streaming download rather than loading it all into memory, this is much more efficient
regardless since the data is just going into a file.

Here is a helper class which provides progress updates to a `StreamedResponse`:

```dart
class DownloadTask {
  /// The length of the download, or null if indeterminate.
  final int length;
  
  /// The current progress of the download, in bytes.
  final ValueListenable<int> progress;
  
  /// The resulting stream of data.
  final Stream<List<int>> stream;

  DownloadTask._({
    this.length,
    this.progress,
    this.stream,
  });

  factory DownloadTask(http.StreamedResponse response) {
    var progress = ValueNotifier(0);
    return DownloadTask._(
      length: response.contentLength < 0 ? null : response.contentLength,
      progress: progress,
      stream: response.stream.map((event) {
        progress.value += event.length;
        return event;
      }),
    );
  }

  Future<void> save(File file) async {
    var f = file.openWrite();
    await f.addStream(stream);
    await f.close();
  }
}
```

---

## Hooking up the UI

First, set up new fields in the page state:

```dart
  /// File path to where the download saves.
  String filePath;

  /// An in-progress download task.
  DownloadTask download;
  
  /// Whether or not the download has finished.
  var done = false;
```

Then update the progress bar so that it listens to the progress:

```dart
        if (download != null)
          SizedBox(
            width: 120,
            child: ValueListenableBuilder(
              valueListenable: download.progress,
              builder: (context, bytes, child) =>
                LinearProgressIndicator(
                  value: download.length == null
                    ? null : bytes / download.length,
                ),
            ),
          )
```

Make our image actually read from the file:

```dart
        else if (done) ...[
          Image.file(File(filePath)),
```

Finally, implement the download button:

```dart
          RaisedButton(
            child: Text('Start'),
            onPressed: () async {
              // Ignore button press if a download is already in progress.
              if (download != null) return;

              // The http client must be disposed after use, we use a
              // try/finally to make sure it gets disposed properly.
              http.Client client;
              try {
                client = http.Client();

                // Start the download task using client.send.
                download = await DownloadTask(await client.send(http.Request(
                  'GET', Uri.parse('https://i.tst.sh/XaY4i.jpg')
                )));

                // Safely notify the UI that we have a download in progress.
                if (mounted) setState(() {});
                
                // Compute the file path with package:path and package:path_provider.
                filePath = path.join(
                  (await getApplicationDocumentsDirectory()).path,
                  'birb.jpg',
                );

                // Pipe the download into a file at filePath.
                await download.save(File(filePath));

                // Safely notify the UI that the download is complete.
                if (mounted) setState(() {
                  download = null;
                  done = true;
                });
              } catch (e, bt) {
                print('Error: $e\n$bt');

                // An error has occurred, cancel the download.
                if (mounted) setState(() {
                  download = null;
                  done = false;
                });
              } finally {
                client?.close();
              }
            },
          ),
```

---

## Final result

This video shows the app downloading and displaying a real image:

<iframe width="360" height="780" src="https://i.tst.sh/yKUZr.mp4" frameborder="0" allowfullscreen></iframe>

Source code: [https://gist.github.com/PixelToast/a9d539511726fb445d272a13f1f2729d](https://gist.github.com/PixelToast/a9d539511726fb445d272a13f1f2729d)