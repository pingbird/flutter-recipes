---
title: Android Emulator on AMD CPUs
parent: FAQ
---

# Android Emulator on AMD CPUs

## Windows

* Do **NOT** install either HAXM or Hyper-V.
* Make sure you have Android Studio 3.2 Beta 1 or higher.
* Make sure virtualization is enabled in your BIOS, the option is sometimes labelled SVM.

### Install WHPX

1. Run `optionalfeatures` from the start menu, it should open the "Windows Features" dialog.
2. Check `Windows Hypervisor Platform`.
3. Click OK.
4. Reboot.

After WHPX is installed, the Android Emulator should 'just work'.

---

## Linux

* Install kvm, it works on AMD out of the box.

You can use the `-accel-check` option to check the status of virtualization:

```
#lint shell
ping@debian:~$ Android/sdk/emulator/emulator -accel-check
accel:
0
KVM (version 12) is installed and usable.
```