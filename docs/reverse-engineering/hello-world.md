---
title: Hello, World!
parent: Reverse Engineering
nav_order: 5
---

# Hello, World!

Cool, we can locate functions by name but how do we figure out what they actually do?

As expected reverse engineering from here on is a bit more difficult because we are digging through the assembly code
contained in `Instructions` objects.

Instead of using a modern compiler backend like clang, Dart actually uses its JIT compiler for code generation but with
a couple AOT specific optimizations.

If you have never worked with JIT code, it is a bit bloated in some places compared to what the equivalent C code would
produce. Not that Dart is doing a bad job though, it's designed to be generated quickly at runtime and the hand-written
assembly for common instructions often beats clang/gcc in terms of performance.

Generated code being less micro-optimized actually works heavily to our advantage since it closer resembles the higher
level IR used to generate it.

Most of the relevant code generation can be found in:

- `vm/compiler/backend/il_<arch>.cc`
- `vm/compiler/assembler/assembler_<arch>.cc`
- `vm/compiler/asm_intrinsifier_<arch>.cc`
- `vm/compiler/graph_intrinsifier_<arch>.cc`

Here is the register layout and calling conventions for dart's A64 assembler:

    #lint reg-tbl
           r0 |     | Returns
    r0  -  r7 |     | Arguments
    r0  - r14 |     | General purpose
          r15 | sp  | Dart stack pointer
          r16 | ip0 | Scratch register
          r17 | ip1 | Scratch register
          r18 |     | Platform register
    r19 - r25 |     | General purpose
    r19 - r28 |     | Callee saved registers
          r26 | thr | Current thread
          r27 | pp  | Object pool
          r28 | brm | Barrier mask
          r29 | fp  | Frame pointer
          r30 | lr  | Link register
          r31 | zr  | Zero / CSP

This ABI follows the standard AArch64 calling conventions [here](https://infocenter.arm.com/help/topic/com.arm.doc.ihi0055b/IHI0055B_aapcs64.pdf)
but with a few global registers:

- R26 / THR: Pointer to the running vm `Thread`, see [vm/thread.h](https://github.com/dart-lang/sdk/blob/7340a569caac6431d8698dc3788579b57ffcf0c6/runtime/vm/thread.h)
- R27 / PP: Pointer to the `ObjectPool` of the current context, see [vm/object.h](https://github.com/dart-lang/sdk/blob/7340a569caac6431d8698dc3788579b57ffcf0c6/runtime/vm/object.h#L4275)
- R28 / BRM: The barrier mask, used for incremental garbage collection

 Similarly, this is the register layout for A32:

    #lint reg-tbl
    r0 -  r1 |     | Returns
    r0 -  r9 |     | General purpose
    r4 - r10 |     | Callee saved registers
          r5 | pp  | Object pool
         r10 | thr | Current thread
         r11 | fp  | Frame pointer
         r12 | ip  | Scratch register
         r13 | sp  | Stack pointer
         r14 | lr  | Link register
         r15 | pc  | Program counter

While A64 is a more common target I'll mostly be covering A32 since its is simpler to read and disassemble.

You can view the IR along with the disassembly by passing `--disassemble-optimized` to `gen_snapshot`, but note this
only works on the debug/release targets and not product.

As an example, when compiling hello world:

    void hello() {
      print("Hello, World!");
    }

Scrolling down a bit in the disassembly you will find:

    #lint dartvm-dasm
    Code for optimized function 'package:dectest/hello_world.dart_::_hello' {
            ;; B0
            ;; B1
            ;; Enter frame
    0xf69ace60    e92d4800               stmdb sp!, {fp, lr}
    0xf69ace64    e28db000               add fp, sp, #0
            ;; CheckStackOverflow:8(stack=0, loop=0)
    0xf69ace68    e59ac024               ldr ip, [thr, #+36]
    0xf69ace6c    e15d000c               cmp sp, ip
    0xf69ace70    9bfffffe               blls +0 ; 0xf69ace70
            ;; PushArgument(v3)
    0xf69ace74    e285ca01               add ip, pp, #4096
    0xf69ace78    e59ccfa7               ldr ip, [ip, #+4007]
    0xf69ace7c    e52dc004               str ip, [sp, #-4]!
            ;; StaticCall:12( print<0> v3)
    0xf69ace80    ebfffffe               bl +0 ; 0xf69ace80
    0xf69ace84    e28dd004               add sp, sp, #4
            ;; ParallelMove r0 <- C
    0xf69ace88    e59a0060               ldr r0, [thr, #+96]
            ;; Return:16(v0)
    0xf69ace8c    e24bd000               sub sp, fp, #0
    0xf69ace90    e8bd8800               ldmia sp!, {fp, pc}
    0xf69ace94    e1200070               bkpt #0x0
    }

What is printed here is slightly different from a snapshot built in product but the important part is that we can see
the IR instructions alongside assembly.

Breaking it down:

    #lint dartvm-dasm
            ;; Enter frame
    0xf6a6ce60    e92d4800               stmdb sp!, {fp, lr}
    0xf6a6ce64    e28db000               add fp, sp, #0

This is a standard function prologue, the frame pointer of the caller and link register are pushed to the stack after
which the frame pointer is set to the bottom of the function stack frame.

As with the standard ARM ABI, this uses a full-descending stack meaning it grows backwards in memory.

    #lint dartvm-dasm
            ;; CheckStackOverflow:8(stack=0, loop=0)
    0xf6a6ce68    e59ac024               ldr ip, [thr, #+36]
    0xf6a6ce6c    e15d000c               cmp sp, ip
    0xf6a6ce70    9bfffffe               blls +0 ; 0xf6a6ce70

This is a simple routine which does what you probably guessed, checks if the stack overflowed.

Sadly their disassembler does not annotate either thread fields or branch targets so you have to do some digging.

A list of field offsets can be found in `vm/compiler/runtime_offsets_extracted.h`, which defines
`Thread_stack_limit_offset = 36` telling us that the field accessed is the threads stack limit.

After the stack pointer is compared, it calls the `stackOverflowStubWithoutFpuRegsStub` stub if it has overflowed. The
branch target in the disassembly appears to be un-patched but we can still inspect the binary afterwards to confirm.

    #lint dartvm-dasm
            ;; PushArgument(v3)
    0xf6a6ce74    e285ca01               add ip, pp, #4096
    0xf6a6ce78    e59ccfa7               ldr ip, [ip, #+4007]
    0xf6a6ce7c    e52dc004               str ip, [sp, #-4]!

Here an object from the object pool is pushed onto the stack. Since the offset is too big to fit in an ldr offset
encoding it uses an extra add instruction.

This object is in fact our "Hello, World!" string as a `RawOneByteString*` stored in the `globalObjectPool` of our
isolate at offset 8103.

You may have noticed that offsets are misaligned, this is because object pointers are tagged with `kHeapObjectTag` from
`vm/pointer_tagging.h`, in this case all of the pointers to `RawObject`s in compiled code are offset by 1.

    #lint dartvm-dasm
            ;; StaticCall:12( print<0> v3)
    0xf6a6ce80    ebfffffe               bl +0 ; 0xf6a6ce80
    0xf6a6ce84    e28dd004               add sp, sp, #4

Here print is called followed by the string argument being popped from the stack.

Like before the branch hasn't been resolved, it is a relative branch to the entry point for `print` in dart:core.

    #lint dartvm-dasm
            ;; ParallelMove r0 <- C
    0xf69ace88    e59a0060               ldr r0, [thr, #+96]

Null is loaded into the return register, 96 being the offset to the null object field in a `Thread`.

    #lint dartvm-dasm
            ;; Return:16(v0)
    0xf69ace8c    e24bd000               sub sp, fp, #0
    0xf69ace90    e8bd8800               ldmia sp!, {fp, pc}
    0xf69ace94    e1200070               bkpt #0x0

And finally the function epilogue, the stack frame is restored along with any callee-saved registers. Since lr was
pushed last, popping it into pc will cause the function to return.

From now on I'll be using snippets from my own disassembler which has less problems than the builtin one.