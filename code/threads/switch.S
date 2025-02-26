/* switch.s
 *	Machine dependent context switch routines.  DO NOT MODIFY THESE!
 *
 *	Context switching is inherently machine dependent, since
 *	the registers to be saved, how to set up an initial
 *	call frame, etc, are all specific to a processor architecture.
 *
 *	This file currently supports the following architectures:
 *	    DEC MIPS
 *	    SUN SPARC
 *	    HP PA-RISC
 *	    Intel x86 (Linux + Solaris)
 *	    Mac OS X PowerPC
 *
 * We define two routines for each architecture:
 *
 * ThreadRoot(InitialPC, InitialArg, WhenDonePC, StartupPC)
 *	InitialPC  - The program counter of the procedure to run
 *			in this thread.
 *	InitialArg - The single argument to the thread.
 *	WhenDonePC - The routine to call when the thread returns.
 *	StartupPC  - Routine to call when the thread is started.
 *
 *	ThreadRoot is called from the SWITCH() routine to start
 *	a thread for the first time.
 *
 * SWITCH(oldThread, newThread)
 *	oldThread  - The current thread that was running, where the
 *		CPU register state is to be saved.
 *	newThread  - The new thread to be run, where the CPU register
 *		state is to be loaded from.
 */

/*
 Copyright (c) 1992-1993 The Regents of the University of California.
 All rights reserved.  See copyright.h for copyright notice and limitation
 of liability and disclaimer of warranty provisions.
 */

#include "copyright.h"
#include "switch.h"

#if defined(SOLARIS) || defined(MAC_OS)
/* Those systems prepend a _ to symbol names */
#define ThreadRoot _ThreadRoot
#define SWITCH _SWITCH
#endif

#ifdef HOST_MIPS

/* Symbolic register names */
#define z       $0      /* zero register */
#define a0      $4      /* argument registers */
#define a1      $5
#define s0      $16     /* callee saved */
#define s1      $17
#define s2      $18
#define s3      $19
#define s4      $20
#define s5      $21
#define s6      $22
#define s7      $23
#define sp      $29     /* stack pointer */
#define fp      $30     /* frame pointer */
#define ra      $31     /* return address */

        .text
        .align  2

        .globl ThreadRoot
        .ent        ThreadRoot,0
ThreadRoot:
        or        fp,z,z                # Clearing the frame pointer here
                                # makes gdb backtraces of thread stacks
                                # end here (I hope!)

        jal        StartupPC        # call startup procedure
        move        a0, InitialArg
        jal        InitialPC        # call main procedure
        jal         WhenDonePC        # when we re done, call clean up procedure

        # NEVER REACHED
        .end ThreadRoot

        # a0 -- pointer to old Thread
        # a1 -- pointer to new Thread
        .globl SWITCH
        .ent        SWITCH,0
SWITCH:
        sw        sp, SP(a0)                # save new stack pointer
        sw        s0, S0(a0)                # save all the callee-save registers
        sw        s1, S1(a0)
        sw        s2, S2(a0)
        sw        s3, S3(a0)
        sw        s4, S4(a0)
        sw        s5, S5(a0)
        sw        s6, S6(a0)
        sw        s7, S7(a0)
        sw        fp, FP(a0)                # save frame pointer
        sw        ra, PC(a0)                # save return address

        lw        sp, SP(a1)                # load the new stack pointer
        lw        s0, S0(a1)                # load the callee-save registers
        lw        s1, S1(a1)
        lw        s2, S2(a1)
        lw        s3, S3(a1)
        lw        s4, S4(a1)
        lw        s5, S5(a1)
        lw        s6, S6(a1)
        lw        s7, S7(a1)
        lw        fp, FP(a1)
        lw        ra, PC(a1)                # load the return address

        j        ra
        .end SWITCH
#endif /* HOST_MIPS */

#ifdef HOST_SPARC

/* NOTE!  These files appear not to exist on Solaris --
 *  you need to find where (the SPARC-specific) MINFRAME, ST_FLUSH_WINDOWS, ...
 *  are defined.  (I don't have a Solaris machine, so I have no way to tell.)
 */
#ifndef SOLARIS
#include <sun4/trap.h>
#include <sun4/asm_linkage.h>
#else
#include <sys/trap.h>
#define MINFRAME 256
#define STACK_ALIGN	32L

#endif

.seg    "text"

/* SPECIAL to the SPARC:
 *	The first two instruction of ThreadRoot are skipped because
 *	the address of ThreadRoot is made the return address of SWITCH()
 *	by the routine Thread::StackAllocate.  SWITCH() jumps here on the
 *	"ret" instruction which is really at "jmp %o7+8".  The 8 skips the
 *	two nops at the beginning of the routine.
 */
.globl  ThreadRoot
ThreadRoot:
        nop  ; nop         /* These 2 nops are skipped because we are called
                            * with a jmp+8 instruction. */
        clr        %fp        /* Clearing the frame pointer makes gdb backtraces
                            * of thread stacks end here. */
                           /* Currently the arguments are in out registers we
                            * save them into local registers so they won't be
                            * trashed during the calls we make. */
        mov        InitialPC, %l0
        mov        InitialArg, %l1
        mov        WhenDonePC, %l2
                           /* Execute the code:
                           *        call StartupPC();
                           *        call InitialPC(InitialArg);
                           *        call WhenDonePC();
                           */
        call        StartupPC,0
        nop
        call        %l0, 1
        mov        %l1, %o0   /* Using delay slot to setup argument to InitialPC */
        call        %l2, 0
        nop
                           /* WhenDonePC call should never return.  If it does
                            * we execute a trap into the debugger.  */
        ta        ST_BREAKPOINT

.globl SWITCH
SWITCH:
        save        %sp, -MINFRAME, %sp
        st        %fp, [%i0]
        st        %i0, [%i0+I0]
        st        %i1, [%i0+I1]
        st        %i2, [%i0+I2]
        st        %i3, [%i0+I3]
        st        %i4, [%i0+I4]
        st        %i5, [%i0+I5]
        st        %i7, [%i0+I7]
        ta        ST_FLUSH_WINDOWS
        nop
        mov        %i1, %l0
        ld        [%l0+I0], %i0
        ld        [%l0+I1], %i1
        ld        [%l0+I2], %i2
        ld        [%l0+I3], %i3
        ld        [%l0+I4], %i4
        ld        [%l0+I5], %i5
        ld        [%l0+I7], %i7
        ld        [%l0], %i6
        ret
        restore

#endif /* HOST_SPARC */

#ifdef HOST_PPC

        .globl ThreadRoot
ThreadRoot:
        mr r30, r1

        stw r5, 128(r1)
        stw r6, 132(r1)
        stw r7, 136(r1)
#Call startupPC
        mtctr r8
        bctrl
        mr r2, r31
# Call InitialPC with InitialArg
        lwz r3, 132(r1)
        lwz r5, 128(r1)
        mtctr r5
        bctrl
# Call WhenDonePC
        lwz r7, 136(r1)
        mtctr r7
        bctrl

        mr r31, r2

        .globl SWITCH
SWITCH:
        mflr r0

        stw r0,4(r3)
        stw r1,0(r3)
        stw r2,8(r3)
        stw r3,12(r3)
        stw r5,20(r3)
        stw r6,24(r3)
        stw r7,28(r3)
        stw r8,32(r3)
        stw r9,36(r3)
        stw r10,40(r3)
        stw r11,44(r3)
        stw r12,48(r3)
        stw r13,52(r3)
        stw r14,56(r3)
        stw r15,60(r3)
        stw r16,64(r3)
        stw r17,68(r3)
        stw r18,72(r3)
        stw r19,76(r3)
        stw r20,80(r3)
        stw r21,84(r3)
        stw r22,88(r3)
        stw r23,92(r3)
        stw r24,96(r3)
        stw r25,100(r3)
        stw r26,104(r3)
        stw r27,108(r3)
        stw r28,112(r3)
        stw r29,116(r3)
        stw r30,120(r3)
        stw r31,124(r3)

        lwz r0,4(r4)
        lwz r1,0(r4)
        lwz r2,8(r4)
        lwz r3,12(r4)
        lwz r5,20(r4)
        lwz r6,24(r4)
        lwz r7,28(r4)
        lwz r8,32(r4)
        lwz r9,36(r4)
        lwz r10,40(r4)
        lwz r11,44(r4)
        lwz r12,48(r4)
        lwz r13,52(r4)
        lwz r14,56(r4)
        lwz r15,60(r4)
        lwz r16,64(r4)
        lwz r17,68(r4)
        lwz r18,72(r4)
        lwz r19,76(r4)
        lwz r20,80(r4)
        lwz r21,84(r4)
        lwz r22,88(r4)
        lwz r23,92(r4)
        lwz r24,96(r4)
        lwz r25,100(r4)
        lwz r26,104(r4)
        lwz r27,108(r4)
        lwz r28,112(r4)
        lwz r29,116(r4)
        lwz r30,120(r4)
        lwz r31,124(r4)

        mtlr r0
        blr

#endif /* HOST_PPC */

#ifdef HOST_SNAKE

    ;rp = r2,   sp = r30
    ;arg0 = r26,  arg1 = r25,  arg2 = r24,  arg3 = r23

        .SPACE  $TEXT$
        .SUBSPA $CODE$
ThreadRoot
        .PROC
        .CALLINFO CALLER,FRAME=0
        .ENTRY

        .CALL
        ble  0(%r6)                ;call StartupPC
        or   %r31, 0, %rp        ;put return address in proper register
        or   %r4, 0, %arg0        ;load InitialArg
        .CALL        ;in=26
        ble  0(%r3)                ;call InitialPC
        or   %r31, 0, %rp        ;put return address in proper register
        .CALL
        ble  0(%r5)                ;call WhenDonePC
        .EXIT
        or   %r31, 0, %rp        ;shouldn't really matter - doesn't return

        .PROCEND


SWITCH
        .PROC
        .CALLINFO CALLER,FRAME=0
        .ENTRY

    ; save process state of oldThread
        stw  %sp, SP(%arg0)        ;save stack pointer
        stw  %r3, S0(%arg0)        ;save callee-save registers
        stw  %r4, S1(%arg0)
        stw  %r5, S2(%arg0)
        stw  %r6, S3(%arg0)
        stw  %r7, S4(%arg0)
        stw  %r8, S5(%arg0)
        stw  %r9, S6(%arg0)
        stw  %r10, S7(%arg0)
        stw  %r11, S8(%arg0)
        stw  %r12, S9(%arg0)
        stw  %r13, S10(%arg0)
        stw  %r14, S11(%arg0)
        stw  %r15, S12(%arg0)
        stw  %r16, S13(%arg0)
        stw  %r17, S14(%arg0)
        stw  %r18, S15(%arg0)
        stw  %rp, PC(%arg0)        ;save program counter

    ; restore process state of nextThread
        ldw  SP(%arg1), %sp        ;restore stack pointer
        ldw  S0(%arg1), %r3        ;restore callee-save registers
        ldw  S1(%arg1), %r4
        ldw  S2(%arg1), %r5
        ldw  S3(%arg1), %r6
        ldw  S4(%arg1), %r7
        ldw  S5(%arg1), %r8
        ldw  S6(%arg1), %r9
        ldw  S7(%arg1), %r10
        ldw  S8(%arg1), %r11
        ldw  S9(%arg1), %r12
        ldw  S10(%arg1), %r13
        ldw  S11(%arg1), %r14
        ldw  S12(%arg1), %r15
        ldw  S13(%arg1), %r16
        ldw  S14(%arg1), %r17
        ldw  PC(%arg1), %rp        ;save program counter
        bv   0(%rp)
        .EXIT
        ldw  S15(%arg1), %r18

        .PROCEND

        .EXPORT SWITCH,ENTRY,PRIV_LEV=3,RTNVAL=GR
        .EXPORT ThreadRoot,ENTRY,PRIV_LEV=3,RTNVAL=GR

#endif

#ifdef HOST_i386

        .text
        .align  2

/* void ThreadRoot( void )
**
** expects the following registers to be initialized:
**      eax     points to startup function (interrupt enable)
**      edx     contains inital argument to thread function
**      esi     points to thread function
**      edi     point to Thread::Finish()
*/

        .globl  ThreadRoot
ThreadRoot:
        .cfi_startproc
        .cfi_undefined rip
        xorl    %ebp,%ebp
        pushl   InitialArg
        call    *StartupPC
        call    *InitialPC
        call    *WhenDonePC

        /* NOT REACHED*/
        movl    %ebp,%esp
        popl    %ebp
        ret
        .cfi_endproc



/* void SWITCH( thread *t1, thread *t2 )
**
** on entry, stack looks like this:
**      8(esp)  ->              thread *t2
**      4(esp)  ->              thread *t1
**       (esp)  ->              return address
**
** we push the current eax on the stack so that we can use it as
** a pointer to t1, this decrements esp by 4, so when we use it
** to reference stuff on the stack, we add 4 to the offset.
*/
        .comm   _eax_save,4

        .globl  SWITCH
SWITCH:

        movl    %eax,_eax_save          /* save the value of eax */
        movl    4(%esp),%eax            /* move pointer to t1 into eax */
        movl    %ebx,_EBX(%eax)         /* save registers */
        movl    %ecx,_ECX(%eax)
        movl    %edx,_EDX(%eax)
        movl    %esi,_ESI(%eax)
        movl    %edi,_EDI(%eax)
        movl    %ebp,_EBP(%eax)
        movl    %esp,_ESP(%eax)         /* save stack pointer */
        movl    _eax_save,%ebx          /* get the saved value of eax */
        movl    %ebx,_EAX(%eax)         /* store it */
        movl    0(%esp),%ebx            /* get return address from stack into ebx */
        movl    %ebx,_PC(%eax)          /* save it into the pc storage */

        movl    8(%esp),%eax            /* move pointer to t2 into eax */

        movl    _EAX(%eax),%ebx         /* get new value for eax into ebx */
        movl    %ebx,_eax_save          /* save it */
        movl    _EBX(%eax),%ebx         /* retore old registers */
        movl    _ECX(%eax),%ecx
        movl    _EDX(%eax),%edx
        movl    _ESI(%eax),%esi
        movl    _EDI(%eax),%edi
        movl    _EBP(%eax),%ebp
        movl    _ESP(%eax),%esp         /* restore stack pointer */
        movl    _PC(%eax),%eax          /* restore return address into eax */
        movl    %eax,0(%esp)            /* copy over the ret address on the stack */
        movl    _eax_save,%eax

        ret

#endif

#ifdef HOST_x86_64

        .text
        .align  2

/* void ThreadRoot( void )
**
** expects the following registers to be initialized:
**      rcx     points to startup function (interrupt enable)
**      rdx     contains inital argument to thread function
**      rsi     points to thread function
**      rdi     point to Thread::Finish()
*/

        .globl  ThreadRoot
ThreadRoot:
        .cfi_startproc
        .cfi_undefined rip
        xorq    %rbp,%rbp
        pushq   WhenDonePC
        pushq   InitialPC
        pushq   InitialArg
        call    *StartupPC
        movq    (%rsp),%rdi
        movq    8(%rsp),InitialPC
        call    *InitialPC
        movq    16(%rsp),WhenDonePC
        call    *WhenDonePC

        /* NOT REACHED*/
        popq    InitialArg
        popq    InitialPC
        popq    WhenDonePC
        movq    %rbp,%rsp
        popq    %rbp
        ret
        .cfi_endproc



/* void SWITCH( thread *t1, thread *t2 )
**
** on entry, stack looks like this:
**       (rsp)  ->              return address
**
**        rdi   contains        thread *t1
**        rsi   contains        thread *t2
**
** we push the current rax on the stack so that we can use it as
** a pointer to t1, this decrements rsp by 8, so when we use it
** to reference stuff on the stack, we add 8 to the offset.
*/
        .comm   _rax_save,8

        .globl  SWITCH
SWITCH:

        movq    %rax,_rax_save(%rip)    /* save the value of rax */
        movq    %rdi,%rax               /* move pointer to t1 into rax */
        movq    %rbx,_RBX(%rax)         /* save registers */
        movq    %rcx,_RCX(%rax)
        movq    %rdx,_RDX(%rax)
        movq    %rsi,_RSI(%rax)
        movq    %rdi,_RDI(%rax)
        movq    %r12,_R12(%rax)
        movq    %r13,_R13(%rax)
        movq    %r14,_R14(%rax)
        movq    %r15,_R15(%rax)
        movq    %rbp,_RBP(%rax)
        movq    %rsp,_RSP(%rax)         /* save stack pointer */
        movq    _rax_save(%rip),%rbx          /* get the saved value of rax */
        movq    %rbx,_RAX(%rax)         /* store it */
        movq    0(%rsp),%rbx            /* get return address from stack into rbx */
        movq    %rbx,_PC(%rax)          /* save it into the pc storage */

        movq    %rsi,%rax               /* move pointer to t2 into rax */

        movq    _RAX(%rax),%rbx         /* get new value for rax into rbx */
        movq    %rbx,_rax_save(%rip)    /* save it */
        movq    _RBX(%rax),%rbx         /* retore old registers */
        movq    _RCX(%rax),%rcx
        movq    _RDX(%rax),%rdx
        movq    _RSI(%rax),%rsi
        movq    _RDI(%rax),%rdi
        movq    _R12(%rax),%r12
        movq    _R13(%rax),%r13
        movq    _R14(%rax),%r14
        movq    _R15(%rax),%r15
        movq    _RBP(%rax),%rbp
        movq    _RSP(%rax),%rsp         /* restore stack pointer */
        movq    _PC(%rax),%rax          /* restore return address into rax */
        movq    %rax,0(%rsp)            /* copy over the ret address on the stack */
        movq    _rax_save(%rip),%rax

        ret

#endif
	.section	.note.GNU-stack,"",@progbits
