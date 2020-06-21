---
title: Project Structure
parent: Architecture
---

# Project Structure

My rule of thumb is that given an idea of a particular feature, i.e. a specific page or service, you should be able to
find the file its in through auto completion alone.

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

I like to keep it as flat as possible, avoid creating categories that don't add meaning to a particular file.