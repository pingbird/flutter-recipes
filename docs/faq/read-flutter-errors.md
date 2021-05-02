# How to read Flutter errors

Contrary to popular belief, the red widgets displayed by Flutter when a widget
fails to render are not intended to be used to fix errors,
they are intended to see which error caused the failure of which widget.

Instead, you should **always** use your IDE's debug console,
it contains more information, and often shows you the exact line where your error happens.

## Debug Console

The debug console should automatically be displayed when you are debugging your flutter app.

If it is not visible, or you accidentally dismissed it:

On Android Studio, at the bottom of your screen, you should see a small bug icon next to "5: Debug". Click this button, and the debug panel will open.
If you do not see the debug console, but the debugger, look on the top left of the window that opened when you clicked "5: Debug", and select the "Console" tab.

On Visual Studio Code, press Ctrl+J to toggle the bottom panel. You may have to click on "Debug Console" in order to view the debug console.

## Anatomy of an error.

Here is an example of a Widget error:

```
======== Exception caught by widgets library =======================================================
The following NoSuchMethodError was thrown building MyHomePage(dirty):
The method 'something' was called on null.
Receiver: null
Tried calling: something()

The relevant error-causing widget was: 
  MyHomePage file:///home/user/your_project/lib/main.dart:17:13
When the exception was thrown, this was the stack: 
#0      Object.noSuchMethod (dart:core-patch/object_patch.dart:54:5)
#1      MyHomePage.build (package:your_project/main.dart:26:20)
#2      StatelessElement.build (package:flutter/src/widgets/framework.dart:4569:28)
#3      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4495:15)
#4      Element.rebuild (package:flutter/src/widgets/framework.dart:4189:5)
...
====================================================================================================
```

From the top to the bottom, here is what you can understand from this error:

* The type of the exception
  * `NoSuchMethodError`
* The widget which failed to build
  * `MyHomePage`
* The actual text of the error
    ```
    The method 'something' was called on null.
    Receiver: null
    Tried calling: something()
    ```
* The file,line, and character where the widget that failed to build is defined
  * `MyHomePage file:///home/user/your_project/lib/main.dart:17:13`
    * The file is `/home/user/your_project/lib/main.dart`
    * On the `17`th line of the file
    * At the `13`th character of the file
* The stack trace
    ```    When the exception was thrown, this was the stack: 
    #0      Object.noSuchMethod (dart:core-patch/object_patch.dart:54:5)
    #1      MyHomePage.build (package:your_project/main.dart:26:20)
    #2      StatelessElement.build (package:flutter/src/widgets/framework.dart:4569:28)
    #3      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4495:15)
    #4      Element.rebuild (package:flutter/src/widgets/framework.dart:4189:5)
    ...
    ```

Here, we will focus on the last part, the stack trace.

## Stack Trace

The stack is the current state of execution of the program, it contains the state of the functions which are currently being executed.
When an exception is thrown, the stack is summarized in a stack trace, which is sent to the nearest exception handler.

To read our stack trace, we will start at frame #0, the exact place where the error happened:

* `#0      Object.noSuchMethod (dart:core-patch/object_patch.dart:54:5)`

Here, the error happened inside of dart itself, it is very rare to stumble upon a bug inside of the built in core objects, so you can assume that your error did not happen there.

Let's move to the next frame, Frame #1:

* `#1      MyHomePage.build (package:your_project/main.dart:26:7)`

Now, we have a function we know (`build`) inside of a class we know (`MyHomePage`), but the most important part is:

* `package:provider_testbench/main.dart:26:20`
  * The error happened in our project, in our `main.dart` file
  * It happened at line `26`, at the `20`th character. (The character part might be hidden by your IDE)

Instead of navigating to the file ourselves, IDEs recognize that these elements are special, and can be clicked.

If you click on the link displayed by your IDE, it will open the file, and put your cursor on the exact position specified by the stack.

Here is the code that failed:

```
  Widget build(BuildContext context) {
    dynamic dangerousValue = null;
    dangerousValue.something();
```

In our case, our IDE will put the cursor between `dangerousValue` and `something()`, immediately highlighting the error.
