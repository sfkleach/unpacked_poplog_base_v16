/* --- University of Sussex 1990.
 > File:            $popcontrib/ved/ved_auto_mins.p
 > Purpose:			Set VED to do procedures in vedautoprocs every N minutes
 > Author:          Aaron Sloman, May 18 1989 (see revisions)
 > Documentation: 	DRAFT HELP FILE IS below (for now)
 > Related Files:
 */

;;; NB. NB.
;;; Since Poplog V14.1 This file has been made redundant by LIB * VED_AUTOSAVE
;;; SEE HELP * VED_AUTOSAVE

/*
NB this may not be consistent with LIB VED_CLOCK

HELP VED_AUTO_MINS                            Aaron Sloman November 1990

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction
 -- Running ved_auto_mins
 -- Setting up your vedinit.p, and altering defaults
 -- autoproc_timeout_only
 -- Loading the program
 -- autoproc_minutes - time interval between activations
 -- pop_timeout_secs - changing timeout interval
 -- autproc_min_write - preventing writing files with few changes
 -- vedautowrite
 -- Putting it into a saved image
 -- WARNING this may interact with other programs


-- Introduction

This (DRAFT) library is intended as an improvement to the * VEDAUTOWRITE
mechanism which only saves a file when the number of changes on that
file exceeds the value of the variable vedautowrite.

This library uses a timing mechanism instead, and can save all current
VED files to disk at regular time intervals, coping with the situation
where you have made several changes to lots of files, none of them
exceeding vedautowrite. This library uses * POP_TIMEOUT.
(See also REF * TIMES)

LIB VED_AUTOMINS allows you to tell VED to call procedures in the list
of procedures (or procedure names) -vedautoprocs- at regular intervals
defined by the variable -autoproc_minutes-.

The default value of vedautoprocs is the list

	[vedautoproc_write]

The user-defineable procedure -vedautoproc_write- is a procedure that
writes all writeable and changed files.


-- Running ved_auto_mins

If this file is in an autoloadable library it can be invoked by
using the command:

<ENTER> auto_mins <number>

	Assigns <number> to autoproc_minutes, displays the current setting
	and tells you how much time is left. <number> can be integer or
	decimal.

<ENTER> auto_mins

	Shows the current setting and tells you how much time is left.

If autoproc_minutes is not set by user it defaults a default specified
below.


-- Setting up your vedinit.p, and altering defaults

If you want the mechanism to operate whenever you run VED, then
put the following into your vedinit.p to load the program:

	uses ved_auto_mins;

It can be tailored in various ways.

-- autoproc_minutes - time interval between activations

This defaults to 10 minutes. If you want to make it 5 do:

	5 -> autoproc_minutes;

in your vedinit.p

-- pop_timeout_secs - changing timeout interval

This determines how long you need to stop typing before it will
check to see if vedautoprocs should be run. The default is 5 seconds.

To make it 2 second do:

	2 -> pop_timeout_secs;


-- autoproc_timeout_only

This defaults to false. This means that whenever you type anything
to VED it checks whether it is time to run the vedautoprocs procedures.
(I.e. it alters -vedprocesstrap-). If you make the variable -true- then
it checks (and files will be written) ONLY if you have stopped typing
for pop_timeout_secs seconds

i.e.
	true -> autoproc_timeout_only;

will stop it writing while you are still typing. If you write non-stop
for long periods and set a long delay for pop_timeout_secs, this
could lose you work if the machine crashes!


-- autproc_min_write - preventing writing files with few changes

This is an integer, specifying the minimum value of -vedchanged-
below which the files should not be written.

So if you don't want changed files written unless they have more than 50
changes then do

	50 -> autoproc_min_write;

The default is 0 meaning that files with at least 1 change will be
written by vedautoproc_write.


-- vedautowrite

If you wish to disable the ordinary vedautowrite mechanism triggered
by number of changes in the current file do

	false -> vedautowrite;

Alternatively assign a largeish number as a precaution, e.g. 2000.


-- vedautoproc_start

This procedure initialises the program by setting up the procedures
-pop_timeout- and -vedprocesstrap-. It also sets the time from which to
measure the first time interval.

If you do '<ENTER> auto_mins' then you don't need to run
-vedautoproc_start-, as it is run when the file is loaded, if loaded in
an interactive process.


-- Putting it into a saved image

The library file concatenates -vedautoproc_start- with
-pop_after_restore- so that the timer is properly initialised when saved
images are started up.

In Poplog V.13.64 this was defeated if you call syssave or
sys_lock_system inside -vedprocess- owing to a bug in VED. So in that
case you must explicitly do something like:

	 vedautoproc_start <>  pop_after_restore ->  pop_after_restore;

I am not sure whether the bug has been fixed. But it won't be a problem
if you use a shell command file to create the saved image, or do it
yourself outside VED.

-- WARNING this may interact with other programs
It is possible that other programs that use vedprocesstrap and/or
pop_timeout will not cohabit sensibly with this one.

*/

section;

global vars

autoproc_minutes,			;;; number of minutes between invocations

autoproc_timeout_only,		;;; if true, run only when you are not typing

autoproc_min_write,			;;; write files only if they have at least
							;;; this number of changes

vedautoprocs = [],			;;; procedures to run
;

unless isnumber(autoproc_minutes) then 10 -> autoproc_minutes endunless;

unless isboolean(autoproc_timeout_only) then
	false -> autoproc_timeout_only	;;; run even while user is typing
endunless;

unless isinteger(pop_timeout_secs) then 5 -> pop_timeout_secs endunless;

unless isinteger(autoproc_min_write) then
	0 -> autoproc_min_write		;;; write files with > 0 changes
endunless;

lvars last_time_run = 0;		;;; time last run

define global vars procedure vedautoproc_write;
	;;; This is user definable. Put its name in list vedautoprocs
	dlocal vedargument = nullstring;
	lvars belldone = false, wasonstatus = vedonstatus;

	;;; Check if there is anything to write
	vedappfiles(
		procedure;
			lvars onstatus = vedonstatus;
			if onstatus then vedswitchstatus() endif;
			if vedwriteable and vedchanged and vvedbuffersize fi_> 0
			and vedchanged > autoproc_min_write
			then
				unless belldone then vedscreenbell(); true -> belldone
				endunless;
				vedwriterange(1,max(vvedbuffersize,1), vedpathname);
				false -> vedchanged;
			endif;
			if onstatus /== vedonstatus then vedswitchstatus() endif;
		endprocedure);

		if belldone then vedputmessage('AUTO SAVE done') endif;
   		if wasonstatus /==vedonstatus then vedswitchstatus() endif;
enddefine;

"vedautoproc_write" :: vedautoprocs -> vedautoprocs;

define lconstant procedure check_autoproc;
	;;; Run every autoproc_minutes minute
	;;; This is assigned to pop_timeout (See HELP * POP_TIMEOUT)
	;;; And, if autoproc_timeout_only is FALSE then whenever
	;;; control returns to top level in vedprocess.
	lvars p;
	returnunless (iscaller(vededitor));
	if ispair(ved_char_in_stream) or sys_input_waiting(popdevraw) then
		return
	elseif (sys_real_time() - last_time_run) >=  autoproc_minutes * 60 then
		sys_real_time() -> last_time_run;
		;;; run the procedures
		for p in vedautoprocs do recursive_valof(p)() endfor;
		vedsetcursor();
	endif
enddefine;

define lconstant process_autoproc(oldprocesstrap);
	;;; closures of this assigned to vedprocesstrap
	lvars procedure oldprocesstrap;
	unless autoproc_timeout_only then
		check_autoproc()
	endunless;
	oldprocesstrap()
enddefine;


lvars
	auto_set = false,	;;; stops next procedure running twice
;

define global vedautoproc_start;
	sys_real_time() -> last_time_run;
	;;; The rest should be run only once.
	returnif(auto_set);
	process_autoproc(%vedprocesstrap%) ->  vedprocesstrap;
	check_autoproc -> pop_timeout;
	true -> auto_set;
enddefine;

lvars  warning_given = false;

define global ved_auto_mins;
	lvars time = strnumber(vedargument), mins, secs, pos = true;
	dlocal pop_pr_places = 2;
	unless auto_set then vedautoproc_start() endunless;
	if time then time -> autoproc_minutes endif;
	round(autoproc_minutes * 60) - (sys_real_time() - last_time_run) -> time;
	if time < 0 then false -> pos; -time -> time endif;
	time // 60 -> mins -> secs;
	unless warning_given then
		if pdpart(vedprocesstrap) /== process_autoproc
		or pop_timeout /== check_autoproc
		then
			vedscreenbell();
			vedputmessage('WARNING auto_mins trap procedures modified. Press any key');
			rawcharin() ->;
			true -> warning_given
		endif;
	endunless;

	vedputmessage('Set to ' sys_>< autoproc_minutes sys_>< ' Minutes. '
		sys_>< mins sys_>< ' minutes ' sys_>< secs sys_><
		if pos then ' seconds left.' else ' seconds LATE' endif);
enddefine;

;;; Initialise things if running interactively
if systrmdev(popdevin) then vedautoproc_start() endif;

;;; Ensure that saved images are initialised properly on startup
vedautoproc_start <> pop_after_restore -> pop_after_restore;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct 12 1990
	Made ved_auto_mins run vedautoproc_start if necessary.
	Made it give a warning if it's changing vedprocesstrap or
	poptimeout
--- Aaron Sloman, Sep 15 1990
	Put in check for whether in vededitor
--- Aaron Sloman, Jun  3 1989
	Changed to show seconds rather than decimal fractions of a minute.
--- Aaron Sloman, May 29 1989
	Changed so that autoproc_timeout_only can be changed AFTER the
	file has been loaded and vedautoproc_start has been run.
 */
