# Use regular make for this Makefile
#
# Makefile for building user programs to run on top of Nachos
# Several things to be aware of: Nachos assumes that the location of
# the program startup routine (the location where the kernel jumps to
# when the program initially starts up) is location 0.  This means:
# start.o must be the first .o passed to ld, so that routine "Start"
# gets loaded at location 0
#
# if you are cross-compiling, you need to point to the right executables
# and change the flags to "ld" and the build procedure for "as".

SHELL=bash
NACHOS_ROOT = ../../
NACHOS_SYS := $(shell $(NACHOS_ROOT)/bin/nachos_sys)
NACHOS_ARCH := $(shell $(NACHOS_ROOT)/bin/nachos_arch)

## depuis chez vous, changer le chemin ci-dessous pour mettre votre chemin vers xgcc
ifneq ($(wildcard /net/npers/amguermouche/it201/xgcc/bin),)
# Enseirb 32bit
GCCDIR	= /net/npers/amguermouche/it201/xgcc/bin
GCC	:=	gcc
endif

ifneq ($(wildcard /opt/xgcc/decstation-ultrix/bin),)
# Maison 32bit
GCCDIR = /opt/xgcc/decstation-ultrix/bin
GCC	:=	xgcc
endif

ifneq ($(wildcard /opt/xgcc/mipsel/bin),)
# Maison 64bit
GCCDIR = /opt/xgcc/mipsel/bin
GCC	:=	gcc
endif

.PHONY: all

LDFLAGS = -T script -N
ASFLAGS =
CPPFLAGS = $(INCDIR) -DCHANGED


# If you aren't cross-compiling:
# GCCDIR =
# LDFLAGS = -N -T 0
# ASFLAGS =
# CPPFLAGS = -P $(INCDIR)


CC	:=	$(GCCDIR)/$(GCC)
AS	:=	$(GCCDIR)/as
LD	:=	$(GCCDIR)/ld
STRIP	:=	$(GCCDIR)/strip
OBJDUMP	:=	$(GCCDIR)/objdump
NM	:=	$(GCCDIR)/nm

CPP	:=	$(GCCDIR)/$(GCC) -E -P
INCDIR	:=	-I../userprog -I../threads
CFLAGS	:=	-G 0 -DIN_USER_MODE $(INCDIR) -Wall -O2 -DCHANGED -ffreestanding

SOURCES	:=	$(wildcard *.c)
PROGS	:=	$(patsubst %.c,%,$(SOURCES))

# We don't support native builds
ifeq ($(GCCDIR),)
$(warning *** WARNING *** When not running at CREMI, I need the cross compiler installed in /opt/xgcc)
all:
else
all: $(PROGS)
endif

start.o: start.S ../userprog/syscall.h
	$(CPP) $(CPPFLAGS) start.S > strt.s
	$(AS) $(ASFLAGS) -o start.o strt.s
	rm strt.s

%.o: %.c ../userprog/syscall.h
	$(CC) $(CFLAGS) -c $< 2>&1 | sed -e 's/\(\(warning:\|attention :\).*\)/'$$'\e''[33m\1'$$'\e''[0m/'

# LB: Caution! start.o should appear *before* $< for the load!

%.coff: %.o start.o
	$(LD) $(LDFLAGS) start.o $< -o $@

%.s: %.coff
	$(OBJDUMP) -d $< | sed -e 's/\<zero\>/r0/g;s/\<at\>/r1/g;s/\<v0\>/r2/g;s/\<v1\>/r3/g;s/\<a0\>/r4/g;s/\<a1\>/r5/g;s/\<a2\>/r6/g;s/\<a3\>/r7/g;s/\<t0\>/r8/g;s/\<gp\>/r28/g;s/\<sp\>/r29/g;s/\<s8\>/r30/g;s/\<ra\>/r31/g;' > $@

$(PROGS): %: %.coff
	../bin/coff2noff $< $@

# Cleaning rule
.PHONY: clean
clean:
	rm -f core *.coff *.o *.s $(PROGS)
