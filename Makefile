# Makefile for the Husky build environment

# include Husky-Makefile-Config
ifeq ($(DEBIAN), 1)
# Every Debian-Source-Paket has one included.
include /usr/share/husky/huskymak.cfg
else
include ../huskymak.cfg
endif

ifeq ($(OSTYPE), UNIX)
  LIBPREFIX=lib
  DLLPREFIX=lib
endif

include make/makefile.inc

ifeq ($(DEBUG), 1)
  CFLAGS=$(WARNFLAGS) $(DEBCFLAGS)
else
  CFLAGS=$(WARNFLAGS) $(OPTCFLAGS)
endif

CDEFS=-D$(OSTYPE) $(ADDCDEFS) -Ih

ifeq ($(DYNLIBS), 1)
all: $(TARGETLIB) $(TARGETDLL).$(VER)
else
all: $(TARGETLIB)
endif

SRC_DIR = src/
H_DIR   = h/

%$(_OBJ): $(SRC_DIR)%.c
	$(CC) $(CFLAGS) $(CDEFS) $(SRC_DIR)$*.c

$(TARGETLIB): $(OBJS)
	$(AR) $(AR_R) $(TARGETLIB) $?
ifdef RANLIB
	$(RANLIB) $(TARGETLIB)
endif

ifeq ($(DYNLIBS), 1)
  ifeq (~$(MKSHARED)~,~ld~)
$(TARGETDLL).$(VER): $(OBJS)
	$(LD) $(OPTLFLAGS) -o $(TARGETDLL).$(VER) $(OBJS)
  else
$(TARGETDLL).$(VER): $(OBJS)
	$(CC) -shared -Wl,-soname,$(TARGETDLL).$(VERH) \
          -o $(TARGETDLL).$(VER) $(OBJS)
  endif

instdyn: $(TARGETLIB) $(TARGETDLL).$(VER)
	-$(MKDIR) $(MKDIROPT) $(LIBDIR)
	$(INSTALL) $(ILOPT) $(TARGETDLL).$(VER) $(LIBDIR)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETDLL).$(VERH)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETDLL)
# Changed the symlinks from symlinks with full path to just symlinks.
# Better so :)
	cd $(LIBDIR) ;\
	$(LN) $(LNOPT) $(TARGETDLL).$(VER) $(TARGETDLL).$(VERH) ;\
	$(LN) $(LNOPT) $(TARGETDLL).$(VER) $(TARGETDLL)
ifneq (~$(LDCONFIG)~, ~~)
	$(LDCONFIG)
endif

else
instdyn: $(TARGETLIB)

endif

FORCE:

install-h-dir: FORCE
	-$(MKDIR) $(MKDIROPT) $(INCDIR)
	-$(MKDIR) $(MKDIROPT) $(INCDIR)$(DIRSEP)huskylib

%.h: FORCE
	$(INSTALL) $(IIOPT) $(H_DIR)$@ $(INCDIR)$(DIRSEP)huskylib

install-h: install-h-dir $(HEADERS)

install: install-h instdyn
	-$(MKDIR) $(MKDIROPT) $(LIBDIR)
	$(INSTALL) $(ISLOPT) $(TARGETLIB) $(LIBDIR)

uninstall:
	-cd $(INCDIR)$(DIRSEP)huskylib$(DIRSEP) ;\
	$(RM) $(RMOPT) $(HEADERS)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETLIB)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETDLL).$(VER)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETDLL).$(VERH)
	-$(RM) $(RMOPT) $(LIBDIR)$(DIRSEP)$(TARGETDLL)

clean:
	-$(RM) $(RMOPT) *$(_OBJ)

distclean: clean
	-$(RM) $(RMOPT) $(TARGETLIB)
	-$(RM) $(RMOPT) $(TARGETDLL).$(VER)
