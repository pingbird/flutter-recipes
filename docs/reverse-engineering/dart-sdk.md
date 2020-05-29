---
title: The Dart SDK
parent: Reverse Engineering
nav_order: 2
---

# The Dart SDK

Thankfully Dart is completely open source so we don't have to fly blind when reverse engineering the snapshot format.

Before creating a testbed for generating and disassembling snapshots you have to set up the Dart SDK, there is
documentation on how to build it here: [https://github.com/dart-lang/sdk/wiki/Building](https://github.com/dart-lang/sdk/wiki/Building).

You want to generate libapp.so files typically orchestrated by the flutter tool, but there doesn't seem to be any
documentation on how to do that yourself.

The flutter sdk ships binaries for `gen_snapshot` which is not part of the standard `create_sdk` build target you
usually use when building dart.

It does exist as a separate target in the SDK though, you can build the `gen_snapshot` tool for arm with this command:

    ./tools/build.py -m product -a simarm gen_snapshot

Normally you can only generate snapshots for the architecture you are running on, to work around that they have created
sim targets which simulate snapshot generation for the target platform. This has some limitations such as not being able
to make aarch64 or x86_64 snapshots on a 32 bit system.

Before making a shared object you have to compile a dill file using the front-end:

    ~/flutter/bin/cache/dart-sdk/bin/dart ~/flutter/bin/cache/artifacts/engine/linux-x64/frontend_server.dart.snapshot --sdk-root ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/ --strong --target=flutter --aot --tfa -Ddart.vm.product=true --packages .packages --output-dill app.dill package:foo/main.dart

Dill files are actually the same format as kernel snapshots, their format is specified here: [https://github.com/dart-lang/sdk/blob/master/pkg/kernel/binary.md](https://github.com/dart-lang/sdk/blob/master/pkg/kernel/binary.md)

This is the format used as a common representation of dart code between tools, including `gen_snapshot` and `analyzer`. 

With the app.dill we can finally generate a libapp.so using this command:

    gen_snapshot --causal_async_stacks --deterministic --snapshot_kind=app-aot-elf --elf=libapp.so --strip app.dill

Once you are able to manually generate the libapp.so, it is easy to modify the SDK to print out all of the debug
information needed to reverse engineer the AOT snapshot format.

As a side note, Dart was actually designed by some of the people who created JavaScript's V8 which is arguably the most
advanced interpreter ever made. DartVM is incredibly well engineered and I don't think people give its creators enough
credit.