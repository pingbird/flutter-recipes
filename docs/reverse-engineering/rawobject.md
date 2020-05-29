---
title: RawObject
parent: Reverse Engineering
nav_order: 4
---

# RawObject

Under the hood all managed objects in DartVM are called `RawObject`s, in true DartVM fashion these classes are all
defined in a single 3,000 line file found at `vm/raw_object.h`.

In generated code you can access and move around `RawObject*`s however you want as long as you yield according to an
incremental write barrier mask, the GC appears to be able to track references through passive scanning alone.

Here is the class tree:

![](https://blog.tst.sh/content/images/2020/02/classTree-1.png)

`RawInstance`s are the traditional `Object`s you pass around Dart code and invoke methods on, all of them have an
equivalent type in dart land. Non-instance objects however are internal and only exist to leverage reference tracking
and garbage collection, they do not have equivalent dart types.

Each object starts with a uint32_t containing the following tags:

![](https://blog.tst.sh/content/images/2020/02/objtags-1.png)

Class IDs here are the same as before with cluster serialization, they are defined in `vm/class_id.h`
but also include user-defined starting at `kNumPredefinedCids`.

Size and GC data tags are used for garbage collection, most of the time they can be ignored.

If the canonical bit is set that means that this object is unique and no other object is equal to it, like with
`Symbol`s and `Type`s.

Objects are very light and the size of `RawInstance` is usually only 4 bytes, they surprisingly do not use virtual
methods at all either.

All of this means allocating an object and filling in its fields can be done virtually for free, something we do quite
lot in Flutter.