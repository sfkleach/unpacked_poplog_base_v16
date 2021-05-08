/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            $poplocal/local/auto/ved_doit.p
 > Purpose:         activate menus in /csunb/pop/poplocal/local/help/menu_menus
 > Author:          Aaron Sloman, Jul  7 1991
 > Documentation:
 > Related Files:
 */

/*
This is a temporary experimental mechanism for treating a VED
file as a menu of possible VED actions.

To try it, load this file, then do
	ENTER menu

Then use
	CTRL-X d to select a sub-menu or invoke an action
		(invokes ved_doit)
	CTRL-X q to do the above while quitting the menu files
		(invokes ved_qdoit)

	Also mouse button 3 with META invokes ved_doit

	See HELP VED_DOIT for a command to make it use button 3 without
		META

For examples of formats, see the menus directory
*/

compile_mode: pop11 +strict;
section;

include xved_constants.ph

;;; Utilities

define global menu_expose_window();
#_IF vedusewindows == "x"
	wved_set_input_focus(wvedwindow)
#_ENDIF
enddefine;


;;; lvars saved_line = false, saved_col, ;

;;; Default size for menu windows under XVED
global vars menuRows = 12, menuColumns = 45;

define lconstant point_to_screen(row, col);
	;;; Taken from lib vedxvedmouse, till it's exported
	lvars row, col;
	if  (2 fi_<= row and row fi_<= vedscreenlength)
	and (2 fi_<= col and col fi_<= vedscreenwidth)
	then
		vedjumpto(row fi_+ vedlineoffset fi_- 1,
				  col fi_+ vedcolumnoffset fi_- 1);
		true
	else
		false
	endif
enddefine;

define lconstant vedmouse__point(name, data) -> (name, data);
	;;; Taken from lib vedxvedmouse, till it's exported
	lvars name, data, row, col;
	data(XVM_ROW), data(XVM_COL) -> (row, col);
	if row == 1 then
		;;; User pointed at status line
		vederror('NO OPTIONS ON STATUS LINE');
	else
		if ved_on_status then vedstatusswitch(); endif;
		point_to_screen(row, col) -> ;
	endif;
	true -> xvedeventhandled;
enddefine;


define global menu_dired_command(word);
	;;; for running dired commands via ved_doit
	lvars word;
	dlocal vedcommand = nullstring;
	valof(word)()
enddefine;

;;; facilities for making and recognizing menu files
lconstant
	ved_menu_string = 'MENU FILE HEADER (Don\'t delete)',
	ved_menu_path_string = 'MENU FILE NAME: '
;

define lconstant ved_set_command(string);
	;;; Start command on status line, for user to finish
	lvars string;
	vedinput(
		procedure(string) with_props ved_set_command;
				lvars string;
			vedenter();
			vedinsertstring(string);
			vedputmessage('PRESS A KEY then COMPLETE COMMAND then PRESS RETURN');
			menu_expose_window();
			vedcurrentfile -> vedinputfocus;
			;;; When the bug in V14.05 is fixed the next line can be
			;;; uncommented
			;;; vedinascii() ->;
		endprocedure(%string%))
enddefine;


define ved_makemenu();
	;;; turn the current file into a Menu file
	vedtopfile();
	vedlineabove();
	0 -> vedlineoffset;
	vedinsertstring(ved_menu_string);
	vedlinebelow();
	vedinsertstring(ved_menu_path_string);
	vedinsertstring(vedpathname);
	vedrefresh();
enddefine;

define global is_ved_menu_file() /* -> boolean */;
	;;; Is current file a menu file?
	vvedbuffersize > 2
	and isstartstring(ved_menu_string, subscrv(1, vedbuffer))
	and isstartstring(ved_menu_path_string, subscrv(2, vedbuffer))
enddefine;

define global ved_clear_menu_files();
	repeat length(vedbufferlist) times
		if is_ved_menu_file() then ved_q() endif;
		ved_rb()
	endrepeat;
enddefine;

define lconstant menu_defaults();
	vedhelpdefaults();
	true -> vedstatic;
	false -> vedbreak;
enddefine;

define lconstant all_path_names -> (list, maxlen);
	lvars list, maxlen = 0;
	[%vedappfiles(
		procedure;
			lvars len;
			max(datalength(dup(vedpathname)),maxlen) -> maxlen;
		endprocedure)%] -> list
enddefine;

define global menu_all_files();
	;;; Avoid problemsof vedfileselect. Make a "menu" of files.
	lvars
		string,
		(list, width) = all_path_names(),
		file = systmpfile(false,'menu',nullstring);

#_IF vedusewindows == "x"
	;;; prepare to make menu windows menuRows by menuColumns
	dlocal
		%xved_value("defaultWindow", "numColumns")% = identfn(%width + 2%),
		%xved_value("defaultWindow", "numRows")% = identfn(%length(list) + 1%);
#_ENDIF
	vededitor(menu_defaults, file);
	for string in list do
		vedinsertstring(string);
		max(80, vedcolumn + 5)-> vedcolumn;
		vedinsertstring('!!	QUIT  \'ved ');
		vedinsertstring(string);
		vedcharinsert(`'`);
		vednextline();
	endfor;
	ved_makemenu();
	vedjumpto(3,1);
	2 -> vedlineoffset;
	vedrefresh();
enddefine;


define lconstant interpret_action(action, file, returning);
	lvars action, file, returning;
	vedsetonscreen(file, false);
	file ->> ved_current_file -> vedinputfocus;
	if hd(action) == "ENTER" then
		ved_set_command(action(2));
	else
		popval(action) -> action;
		if isword(action) then
			caller_valof(action, false)();
		elseif isstring(action) then
			veddo(action)
		elseif isprocedure(action) then
			action()
		else
			vederror('Unknown type of menu action')
		endif;
	endif;
	if returning then
		vedsetonscreen(returning, false);
		returning ->> ved_current_file -> vedinputfocus
	endif
enddefine;


define lconstant do_action(file, old_file, action, quitmenus);
	;;; Do the action specified, in the file
	lvars file, old_file, action, quitmenus, returning = false;
	unless islist(action) and not(null(action)) then
		vederror('System error in ved_doit')
	endunless;

	if hd(action) == "RETURNAFTER" then
		2 -> returning;
		tl(action) ->action;
	elseif hd(action) == "RETURNTHEN" then
		1 -> returning;
		tl(action) ->action;
	endif;

	if null(action) then vederror('MISSING MENU ACTION') endif;

	if quitmenus then false -> returning endif;

	if returning == 1 then
		;;; For things that cannot be done as callbacks, e.g. vedfileselect
		;;;menu_set_processtrap(interpret_action(%action, file, false%));
		vedinput(interpret_action(%action, file, false%));

	else
		if returning == 2 then old_file else false endif -> returning;
		interpret_action(action, file, returning);
	endif;
enddefine;

define lconstant shove_menu_files() -> file_found;
	;;; rebuild vebufferlist,with menu files at the back.
	;;; return first non_menu file found, or false if none.
	lvars file_found, menufiles = [] , others = [];
	vedappfiles(
		procedure();
			ved_current_file,
			if is_ved_menu_file() then
				:: menufiles -> menufiles;
			else
				:: others -> others
			endif;
		endprocedure);
	ncrev(others) -> others;
	others nc_<> ncrev(menufiles) -> vedbufferlist;
	if others /== [] then front(others)
	else false
	endif -> file_found
enddefine;

define lconstant find_non_menu_file(action, quitmenus);
	;;; Invoked in a menu file, with an action on current line
	;;; Find a non-menu file in vedbuffer list, then do the action
	;;; specified
	lvars action,
		old_file 	= ved_current_file,
		file_found,
		quitmenus;    ;;; if true, quit the menus currently in VED


	if hd(action) == "QUIT" then
		tl(action)-> action;
		ved_q();
	endif;
	if quitmenus and back(vedbufferlist) /== [] then
		repeat
			;;; get rid of menu files
		quitunless(is_ved_menu_file());
			ved_q();
		endrepeat;
	endif;

	shove_menu_files() -> file_found;		;;; get them after vedbufferlist
	unless file_found then
		ved_current_file -> file_found;
	endunless;
	do_action(file_found, old_file, action, quitmenus)
enddefine;


global vars procedure ved_menu; ;;; defined below

define lconstant veddomenuoption(quitmenus);
	;;; get menu action from current line of current menu file and do it.
	;;; Assumes current line is of the form
	;;;     /*<description>*/ <action>
	;;; Where the action is one of
	;;;     (1) ENTER <string>  (2) <A string>
	;;;     (3) "<a word>"      (4) <procedure expression>

	lvars quitmenus;

	define lconstant get_string() -> string;
		lvars col, string = vedthisline();
		issubstring('!!', string) -> col;
		if col then
			allbutfirst(col + 2, string)-> string
		else
			vederror('NOT PROPER MENU FORMAT')
		endif;
	enddefine;

	if ved_on_status then vedswitchstatus() endif;

	unless is_ved_menu_file() then
		chain(ved_menu)
	endunless;

	find_non_menu_file(pdtolist(incharitem(stringin(get_string()))), quitmenus);

enddefine;

define ved_doit = veddomenuoption(%false%)
enddefine;

define ved_qdoit = veddomenuoption(%true%)
enddefine;

vedsetkey('\^Xd', "ved_doit");      ;;; do it
vedsetkey('\^Xq', "ved_clear_menu_files");     ;;; quit menus and do it

vars xvedeventhandled;

define global vedmouse__doit;
	if ved_on_status then vedswitchstatus() endif;
	if is_ved_menu_file() then
		vedmouse__point();
		ved_doit()
	else
		veddo('menu')
	endif;
	true -> xvedeventhandled;
enddefine;

define global vedmouse__clearmenus;
	ved_clear_menu_files();
	true -> xvedeventhandled;
enddefine;

define global menu_fileselect();
	;;; like vedfileselect,but make sure the window is visible.
	menu_expose_window();
	vedfileselect()
enddefine;

;;; Define ved_menu command

global vars
	vedmenulist=
	;;; temporary
		[['$popcontrib/x/xved/doit_menus' MENU]],
	vedmenuname = 'menu_menu';

lvars menu_setup = false;

define lconstant setup_mouse();
#_IF vedusewindows == "x"
		unless menu_setup then
			vedset mouse (at front)
				doit = click btn3 with meta
				clearmenus    = click btn3 2 times with meta
			endvedset;
			true -> menu_setup;
		endunless;
#_ENDIF
enddefine;

define global ved_menu();
	vedsetup();	;;; ensure vedinit.p compiled

	unless menu_setup then setup_mouse() endunless;

	if vedargument = nullstring then 'menu_menu' -> vedargument endif;

	;;; append '_menu' to argument if necessary
	unless strmember(`_`, vedargument) then
		vedargument sys_>< '_menu' -> vedargument
	endunless;

#_IF vedusewindows == "x"
	;;; prepare to make menu windows menuRows by menuColumns
	dlocal
		%xved_value("defaultWindow", "numColumns")% = identfn(%menuColumns%),
		%xved_value("defaultWindow", "numRows")% = identfn(%menuRows%);
#_ENDIF
	vedsysfile("vedmenuname", vedmenulist, menu_defaults);
	if vedlineoffset == 0 then
		vedjumpto(3,1);
		vedscrollup();vedscrollup();
		vedputmessage('CHOOSE OPTION')
	endif;
	menu_expose_window();
enddefine;


if vedsetupdone then
	setup_mouse()
else
	procedure(oldtrap, newtrap);
		lvars oldtrap, newtrap;
		newtrap();
		oldtrap();
		oldtrap -> vedprocesstrap
	endprocedure(%vedprocesstrap, setup_mouse%) -> vedprocesstrap
endif;

endsection;
