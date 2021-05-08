 /* --- University of Sussex 1990. ----------
 > File:            $popcontrib/ved/ved_so.p
 > Purpose:			Treat a file or range as "source" for VED enter commands
 > Author:          Aaron Sloman, Sept 17 1990
 > Documentation: DRAFT REF entries below
 > Related Files:
 */


/*
Entries for REF VEDCOMMS

ved_so [ FILENAME ]                                          [procedure]
        Treat a file as source for VED commands, terminated with a  line
        containing only a single character ".", or end of file.

        The file is read from a VED buffer, if present, otherwise from a
        disk file. Each line is obeyed  in turn as a VED ENTER  command,
        using -veddo-.  If FILENAME  is not given then the  current  VED
        buffer is used (which will rarely be useful). See also ved_somr.

		If an error occurs, the normal error message is printed followed
		by ":-" and the command line causing the error.



ved_somr                                                     [procedure]
        Treat the marked range as source for VED ENTER commands.

        The marked range is  read in from the  current VED buffer.  Each
        line is treated as a VED  enter command using -veddo-. See  also
        ved_so

*/

uses line_repeater;

compile_mode: pop11 +strict;


section;

define global ved_so;
	lvars string, filename = vedargument, file, olderror = vederror;

	define dlocal vederror(message);
		lvars message;
		olderror(message sys_>< ' :- ' sys_>< string)

	enddefine;

	if filename = nullstring then vedpathname -> filename endif;

	if vedpresent(filename) ->> file then
		lblock lvars buff, len, linenum;

			file(3) -> buff;	;;; "3" depends on $popsrc/vddeclare.ph
			datalength(buff) -> len;
			0 -> linenum;
			repeat
				linenum fi_+ 1 -> linenum;
			returnif(linenum > len);
				subscrv(linenum, buff) -> string;
			returnif(string = '.');
				;;; update vedline for the file
				linenum -> file(4);	;;; "4" depends on $popsrc/vddeclare.ph
				unless string = nullstring then veddo(string) endunless;
			endrepeat;

		endlblock;
	else
		lblock lvars repeater;

			line_repeater(filename, 256) -> repeater;
			repeat
          		repeater() -> string;
			returnif(string == termin or string = '.');
				veddo(string)
			endrepeat;

		endlblock
	endif
enddefine;

endsection;


section;

define global ved_somr;
	lvars len = vvedmarkhi, string, line;

	dlocal vedpositionstack;

	vedpositionpush();
	vedmarkfind();	;;; check there's a marked range
	min(vvedmarkhi, vvedbuffersize) -> len;

	vvedmarklo fi_- 1 -> line;
	repeat
		line fi_+ 1 -> line;
	returnif(line > len);
		subscrv(line, vedbuffer) -> string;
	returnif(string = '.');
		vedtrimline();
		line -> vedline;	;;; in case there's an error
		vedsetlinesize();
		unless string = nullstring then veddo(string) endunless;
	endrepeat;

	vedpositionpop();

enddefine;

endsection;
