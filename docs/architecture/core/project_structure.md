---
title: Project Structure
parent: Core
---

# Project Structure

There is no single best way to structure your project or even simple rules on what to do. In general your
project should be structured in a way that closely resembles how you categorize it in your brain.

My rule of thumb is that given an idea of a particular feature, i.e. a specific page or service, you should be able to
find the file its in through auto completion alone.

If you are confused onto how you should organize a personal project initially, there is nothing wrong with just not
organizing at all until you have a working implementation. Pre-emotively creating folders tends to be counter-productive
unless you have a good idea of what to add beforehand.

---

## Folders

If you lack inspiration, here are some folder structures I use:

```
theme/buttons.dart
theme/text_input.dart
theme.dart
auth/auth_service.dart
auth/auth_impl.dart
utils/color_utils.dart
utils/state_utils.dart
utils.dart
common/potato_card.dart
common/foo_widget.dart
common.dart
profile/profile_service.dart
profile/profile.dart
profile/user.dart
profile/member.dart
profile/guild.dart
profile.dart
pages/home/home_page.dart
pages/home/cards/foo_card.dart
pages/home/cards/bar_card.dart
pages/home/foo_dialog.dart
pages/settings/settings_page.dart
```

Basically, keep it as flat as possible, avoid creating categories that don't add meaning to a particular file.

If a set dart files are used a lot, it may be helpful to create a dart file specifically for exporting them, in this
case `utils.dart`, `common.dart`, `profile.dart`.

Whether or not to split complex files up into separate smaller ones is up to preference, I personally don't have a
problem working with multi-thousand line files as long as its not cluttered. At the same time having trivial files is
fine if it improves visibility, even if its something like a single constant.