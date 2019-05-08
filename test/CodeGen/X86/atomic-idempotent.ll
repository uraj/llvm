; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-- -verify-machineinstrs | FileCheck %s --check-prefix=CHECK --check-prefix=X64
; RUN: llc < %s -mtriple=i686-- -mattr=+sse2 -verify-machineinstrs | FileCheck %s --check-prefix=CHECK --check-prefix=X32

; On x86, an atomic rmw operation that does not modify the value in memory
; (such as atomic add 0) can be replaced by an mfence followed by a mov.
; This is explained (with the motivation for such an optimization) in
; http://www.hpl.hp.com/techreports/2012/HPL-2012-68.pdf

define i8 @add8(i8* %p) {
; X64-LABEL: add8:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movb (%rdi), %al
; X64-NEXT:    retq
;
; X32-LABEL: add8:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movb (%eax), %al
; X32-NEXT:    retl
  %1 = atomicrmw add i8* %p, i8 0 monotonic
  ret i8 %1
}

define i16 @or16(i16* %p) {
; X64-LABEL: or16:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or16:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movzwl (%eax), %eax
; X32-NEXT:    retl
  %1 = atomicrmw or i16* %p, i16 0 acquire
  ret i16 %1
}

define i32 @xor32(i32* %p) {
; X64-LABEL: xor32:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: xor32:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  %1 = atomicrmw xor i32* %p, i32 0 release
  ret i32 %1
}

define i64 @sub64(i64* %p) {
; X64-LABEL: sub64:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    retq
;
; X32-LABEL: sub64:
; X32:       # %bb.0:
; X32-NEXT:    pushl %ebx
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    pushl %esi
; X32-NEXT:    .cfi_def_cfa_offset 12
; X32-NEXT:    .cfi_offset %esi, -12
; X32-NEXT:    .cfi_offset %ebx, -8
; X32-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X32-NEXT:    movl (%esi), %eax
; X32-NEXT:    movl 4(%esi), %edx
; X32-NEXT:    .p2align 4, 0x90
; X32-NEXT:  .LBB3_1: # %atomicrmw.start
; X32-NEXT:    # =>This Inner Loop Header: Depth=1
; X32-NEXT:    movl %edx, %ecx
; X32-NEXT:    movl %eax, %ebx
; X32-NEXT:    lock cmpxchg8b (%esi)
; X32-NEXT:    jne .LBB3_1
; X32-NEXT:  # %bb.2: # %atomicrmw.end
; X32-NEXT:    popl %esi
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    popl %ebx
; X32-NEXT:    .cfi_def_cfa_offset 4
; X32-NEXT:    retl
  %1 = atomicrmw sub i64* %p, i64 0 seq_cst
  ret i64 %1
}

define i128 @or128(i128* %p) {
; X64-LABEL: or128:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    .cfi_def_cfa_offset 16
; X64-NEXT:    xorl %esi, %esi
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    callq __sync_fetch_and_or_16
; X64-NEXT:    popq %rcx
; X64-NEXT:    .cfi_def_cfa_offset 8
; X64-NEXT:    retq
;
; X32-LABEL: or128:
; X32:       # %bb.0:
; X32-NEXT:    pushl %ebp
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    .cfi_offset %ebp, -8
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    .cfi_def_cfa_register %ebp
; X32-NEXT:    pushl %edi
; X32-NEXT:    pushl %esi
; X32-NEXT:    andl $-8, %esp
; X32-NEXT:    subl $16, %esp
; X32-NEXT:    .cfi_offset %esi, -16
; X32-NEXT:    .cfi_offset %edi, -12
; X32-NEXT:    movl 8(%ebp), %esi
; X32-NEXT:    movl %esp, %eax
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl 12(%ebp)
; X32-NEXT:    pushl %eax
; X32-NEXT:    calll __sync_fetch_and_or_16
; X32-NEXT:    addl $20, %esp
; X32-NEXT:    movl (%esp), %eax
; X32-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X32-NEXT:    movl {{[0-9]+}}(%esp), %edx
; X32-NEXT:    movl {{[0-9]+}}(%esp), %edi
; X32-NEXT:    movl %edi, 8(%esi)
; X32-NEXT:    movl %edx, 12(%esi)
; X32-NEXT:    movl %eax, (%esi)
; X32-NEXT:    movl %ecx, 4(%esi)
; X32-NEXT:    movl %esi, %eax
; X32-NEXT:    leal -8(%ebp), %esp
; X32-NEXT:    popl %esi
; X32-NEXT:    popl %edi
; X32-NEXT:    popl %ebp
; X32-NEXT:    .cfi_def_cfa %esp, 4
; X32-NEXT:    retl $4
  %1 = atomicrmw or i128* %p, i128 0 monotonic
  ret i128 %1
}

; For 'and', the idempotent value is (-1)
define i32 @and32 (i32* %p) {
; X64-LABEL: and32:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: and32:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  %1 = atomicrmw and i32* %p, i32 -1 acq_rel
  ret i32 %1
}

define void @or32_nouse_monotonic(i32* %p) {
; X64-LABEL: or32_nouse_monotonic:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or32_nouse_monotonic:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i32* %p, i32 0 monotonic
  ret void
}


define void @or32_nouse_acquire(i32* %p) {
; X64-LABEL: or32_nouse_acquire:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or32_nouse_acquire:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i32* %p, i32 0 acquire
  ret void
}

define void @or32_nouse_release(i32* %p) {
; X64-LABEL: or32_nouse_release:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or32_nouse_release:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i32* %p, i32 0 release
  ret void
}

define void @or32_nouse_acq_rel(i32* %p) {
; X64-LABEL: or32_nouse_acq_rel:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or32_nouse_acq_rel:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i32* %p, i32 0 acq_rel
  ret void
}

define void @or32_nouse_seq_cst(i32* %p) {
; X64-LABEL: or32_nouse_seq_cst:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or32_nouse_seq_cst:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i32* %p, i32 0 seq_cst
  ret void
}

; TODO: The value isn't used on 32 bit, so the cmpxchg8b is unneeded
define void @or64_nouse_seq_cst(i64* %p) {
; X64-LABEL: or64_nouse_seq_cst:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    retq
;
; X32-LABEL: or64_nouse_seq_cst:
; X32:       # %bb.0:
; X32-NEXT:    pushl %ebx
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    pushl %esi
; X32-NEXT:    .cfi_def_cfa_offset 12
; X32-NEXT:    .cfi_offset %esi, -12
; X32-NEXT:    .cfi_offset %ebx, -8
; X32-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X32-NEXT:    movl (%esi), %eax
; X32-NEXT:    movl 4(%esi), %edx
; X32-NEXT:    .p2align 4, 0x90
; X32-NEXT:  .LBB11_1: # %atomicrmw.start
; X32-NEXT:    # =>This Inner Loop Header: Depth=1
; X32-NEXT:    movl %edx, %ecx
; X32-NEXT:    movl %eax, %ebx
; X32-NEXT:    lock cmpxchg8b (%esi)
; X32-NEXT:    jne .LBB11_1
; X32-NEXT:  # %bb.2: # %atomicrmw.end
; X32-NEXT:    popl %esi
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    popl %ebx
; X32-NEXT:    .cfi_def_cfa_offset 4
; X32-NEXT:    retl
  atomicrmw or i64* %p, i64 0 seq_cst
  ret void
}

; TODO: Don't need to lower as sync_and_fetch call
define void @or128_nouse_seq_cst(i128* %p) {
; X64-LABEL: or128_nouse_seq_cst:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    .cfi_def_cfa_offset 16
; X64-NEXT:    xorl %esi, %esi
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    callq __sync_fetch_and_or_16
; X64-NEXT:    popq %rax
; X64-NEXT:    .cfi_def_cfa_offset 8
; X64-NEXT:    retq
;
; X32-LABEL: or128_nouse_seq_cst:
; X32:       # %bb.0:
; X32-NEXT:    pushl %ebp
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    .cfi_offset %ebp, -8
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    .cfi_def_cfa_register %ebp
; X32-NEXT:    andl $-8, %esp
; X32-NEXT:    subl $16, %esp
; X32-NEXT:    movl %esp, %eax
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl $0
; X32-NEXT:    pushl 8(%ebp)
; X32-NEXT:    pushl %eax
; X32-NEXT:    calll __sync_fetch_and_or_16
; X32-NEXT:    addl $20, %esp
; X32-NEXT:    movl %ebp, %esp
; X32-NEXT:    popl %ebp
; X32-NEXT:    .cfi_def_cfa %esp, 4
; X32-NEXT:    retl
; X128-LABEL: or128_nouse_seq_cst:
; X128:       # %bb.0:
; X128-NEXT:    lock orl $0, -{{[0-9]+}}(%esp)
; X128-NEXT:    retl
  atomicrmw or i128* %p, i128 0 seq_cst
  ret void
}


define void @or16_nouse_seq_cst(i16* %p) {
; X64-LABEL: or16_nouse_seq_cst:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    retq
;
; X32-LABEL: or16_nouse_seq_cst:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movzwl (%eax), %eax
; X32-NEXT:    retl
  atomicrmw or i16* %p, i16 0 seq_cst
  ret void
}

define void @or8_nouse_seq_cst(i8* %p) {
; X64-LABEL: or8_nouse_seq_cst:
; X64:       # %bb.0:
; X64-NEXT:    mfence
; X64-NEXT:    movb (%rdi), %al
; X64-NEXT:    retq
;
; X32-LABEL: or8_nouse_seq_cst:
; X32:       # %bb.0:
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    mfence
; X32-NEXT:    movb (%eax), %al
; X32-NEXT:    retl
  atomicrmw or i8* %p, i8 0 seq_cst
  ret void
}
