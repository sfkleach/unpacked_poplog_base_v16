#
#       for normal use, the variables should be given the following values:
# NB fsoft is the only f option used by sun4
# pwm does not use any floating point arith
# Do not use the -O flag as this causes menu selection to be offset by one.
#
COM        = cc -s -fsoft
PREFIX     = pw
OBJECT     = pwmtool
BINDIR     = $$usepwm/bin/$$ARCH
OBJDIR     = $$usepwm/obj/$$ARCH
SRCDIR     = $$usepwm/src
PWMID_MACH = "\"$$ARCH\""
#PWMID_DATE :sh `date | awk '{printf "%s %s %s %s", $1, $2, $3, $6}'`
PWMID_DATE = "\"`date '+%a %m %h 19%y'`\""
LIBS       = -lsuntool -lsunwindow -lpixrect

SUBS = $(PREFIX)boil.o $(PREFIX)colour.o $(PREFIX)command.o\
$(PREFIX)feedback.o $(PREFIX)gfxtext.o $(PREFIX)graster.o $(PREFIX)graphic.o\
$(PREFIX)input.o $(PREFIX)marktext.o $(PREFIX)menus.o $(PREFIX)misc.o\
$(PREFIX)parse.o $(PREFIX)pty.o $(PREFIX)report.o $(PREFIX)scrn.o\
$(PREFIX)selection.o $(PREFIX)setup.o $(PREFIX)tty.o $(PREFIX)v200.o\
$(PREFIX)main.o

.IGNORE:

all	: clean mvin $(OBJECT) mvout

clean	: ; rm -f $(OBJECT) $(SUBS)

mvin	: 
	(cd $(OBJDIR); mv -f $(SUBS) $(SRCDIR))
	mv -f $(BINDIR)/$(OBJECT) $(SRCDIR) 

$(OBJECT): $(SUBS)
	$(COM) $(SUBS) $(LIBS) -o $(OBJECT)

mvout	: $(OBJECT)
	mv $(SUBS) $(OBJDIR)
	mv $(OBJECT) $(BINDIR)

$(PREFIX)boil.o: $(PREFIX)boil.c
	$(COM) -c  $(PREFIX)boil.c

$(PREFIX)colour.o: $(PREFIX)colour.c
	$(COM) -c  $(PREFIX)colour.c

$(PREFIX)command.o: $(PREFIX)command.c
	$(COM) -c  $(PREFIX)command.c

$(PREFIX)feedback.o: $(PREFIX)feedback.c
	$(COM) -c  $(PREFIX)feedback.c

$(PREFIX)gfxtext.o: $(PREFIX)gfxtext.c
	$(COM) -c  $(PREFIX)gfxtext.c

$(PREFIX)graster.o: $(PREFIX)graster.c
	$(COM) -c  $(PREFIX)graster.c

$(PREFIX)graphic.o: $(PREFIX)graphic.c
	$(COM) -c  $(PREFIX)graphic.c

$(PREFIX)input.o: $(PREFIX)input.c
	$(COM) -c  $(PREFIX)input.c

$(PREFIX)main.o: $(PREFIX)main.c pwcom.c pwid.h
	$(COM) -c  $(PREFIX)main.c

$(PREFIX)marktext.o: $(PREFIX)marktext.c
	$(COM) -c  $(PREFIX)marktext.c

$(PREFIX)menus.o: $(PREFIX)menus.c
	$(COM) -c  $(PREFIX)menus.c

$(PREFIX)misc.o: $(PREFIX)misc.c
	$(COM) -c  $(PREFIX)misc.c

$(PREFIX)parse.o: $(PREFIX)parse.c pwcomseq.h
	$(COM) -c  $(PREFIX)parse.c

$(PREFIX)pty.o: $(PREFIX)pty.c
	$(COM) -c  $(PREFIX)pty.c

$(PREFIX)report.o: $(PREFIX)report.c pwrepseq.h pwid.h
	$(COM)   -DPWMID_machine=$(PWMID_MACH) \
		 -DPWMID_date=$(PWMID_DATE) -c  $(PREFIX)report.c

$(PREFIX)scrn.o: $(PREFIX)scrn.c
	$(COM) -c  $(PREFIX)scrn.c

$(PREFIX)selection.o: $(PREFIX)selection.c
	$(COM) -c  $(PREFIX)selection.c

$(PREFIX)setup.o: $(PREFIX)setup.c pwimages.h
	$(COM) -c  $(PREFIX)setup.c

$(PREFIX)tty.o: $(PREFIX)tty.c
	$(COM) -c  $(PREFIX)tty.c

$(PREFIX)v200.o: $(PREFIX)v200.c
	$(COM) -c  $(PREFIX)v200.c
