---
title: experiment_not_enabled
parent: FAQ
---

# experiment_not_enabled

You have gotten this warning, or something similar:

```
This requires the 'control-flow-collections' experiment to be enabled.
Try enabling this experiment by adding it to the command line when compiling and running.dart(experiment_not_enabled)
```

Do **NOT** modify analysis options to enable experiments like the message suggests.

The real issue is that your dart version constraint is too low, the solution is to upgrade it in your pubspec:

```yaml
environment:
  sdk: '>=2.7.0 <3.0.0'
```

After you raise the version constraint, don't forget to run `pub get` and restart your IDE.