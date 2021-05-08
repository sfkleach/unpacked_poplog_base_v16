/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			/csuna/pop/master/contrib/x/prolog/xpw/lib/xwidgets.pl
 > Purpose:			Provide basic widget access function for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * xwidgets PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xwidgets.

:- export	xpw_current_window/1, xpw_active_windows/1, xpw_destroy_window/1,
			xpw_set_window_name/2.

:- prolog_language(pop11).

;;; return to top level to declare globals
section;
global vars plxt_id_to_widget plxt_widget_to_id plxt_create_widget_id
			plxt_window plxt_string_translation plxt_check_id;
global constant XpwGraphic = XptWidgetSet("Poplog")("GraphicWidget");
endsection;

section $-xwidgets XptLiveTypeCheck, XptNewWindow, XptDestroyWindow,XtParent =>;

lconstant plxt_widget_ids = newassoc(nil);

lvars plxt_current_window = false;

define plxt_check_id(name);
	lvars name;
	if plxt_widget_ids(name) then
		true;
	else
		false;
	endif;
enddefine;


;;; Form an association between given widget and an id
define plxt_create_widget_id(id,widget);
	lvars widget id;
	widget -> plxt_widget_ids(id);
	id -> plxt_widget_ids(widget);
enddefine;

;;; Destroy the mapping between id and widget
define plxt_destroy_widget_id(widget);
	lvars widget;
	lvars id;
	plxt_widget_ids(widget) -> id;
	false -> plxt_widget_ids(widget);
	false -> plxt_widget_ids(id);
enddefine;

;;; Return the id associated with given widget
define plxt_widget_to_id(widget) -> id;
	lvars widget id;
	unless widget then
		false -> id;
	else
		unless plxt_widget_ids(widget) ->> id then
			mishap(widget, 1, 'Unrecognised Widget Identifier ');
		endunless;
	endunless;
enddefine;

;;; procedure defined below
vars plxt_get_current_widget;

;;; Return widget associated with given id.
;;; returns the current widget if passed the word "current"
define plxt_id_to_widget(id) -> widget;
	lvars id widget;
	if class_dataword(datakey(id)) == "prologvar" then
		mishap(id,1,'Uninstantiated Widget ID');
	elseif id = "current" then
		if (plxt_get_current_widget('foo') ->> id) = false then
			mishap(id,1,'Current Graphic Widget Not Set');
		endif;
	endif;
	unless isword(id) then
		mishap(id, 1, 'Atom Widget Identifier Needed');
	endunless;
	if id then
		unless plxt_widget_ids(id) ->> widget then
			mishap(id, 1, 'Unrecognised Widget Identifier');
		endunless;
	else
		false -> widget;
	endif;
enddefine;

;;; access/update current widget
define active plxt_current_widget;
	plxt_current_window;
enddefine;

define updaterof active plxt_current_widget(new);
	lvars new;
	if new then XptLiveTypeCheck(new,"Widget") ->; endif;
	new -> plxt_current_window;
enddefine;

define plxt_get_current_widget(ignore) -> id;
	lvars ignore, id;
	unless plxt_widget_ids(plxt_current_widget) ->> id then
		false -> id;
	endunless;
enddefine;

define plxt_set_current_widget(id);
	lvars id;
	plxt_id_to_widget(id) -> plxt_current_widget;
enddefine;

;;; procedure for finding all active widgets
define plxt_fetch_all_actives(dummy); /* -> active_list */
	lvars dummy;

	define lconstant add_active(item,value);
		lvars item,value;
		if isword(item) then item endif;
	enddefine;

	[% appproperty(plxt_widget_ids,add_active) %];
enddefine;

;;;Roger Evans' stuff modified to take lists instead of vectors
define plxt_window(name,size) -> child;
	lvars name,size,class,child;
	XptNewWindow(plxt_string_translation(name),size,[],XpwGraphic) -> child;
enddefine;

define plxt_destroy_window(w);
	lvars w;
	XptDestroyWindow(w);
enddefine;

/*	procedure for translating string formats:
	Prolog strings are lists of characters, Prolog atoms are Pop words
	- both are translated into null terminated strings
*/
define plxt_string_translation(string); /* -> new_string */
	lvars string;
	lvars count;
	if islist(string) then
		destlist(string) -> count;
		0;
		consstring(count + 1);
	elseif isword(string) or isstring(string) then
		string sys_>< '\^@';
	else
		mishap(string,1,'Incorrect Argument for Translation');
	endif;
enddefine;

;;; change a widget name
define plxt_set_widget_name(widget,name);
	lvars widget,name;
	fast_XtSetValues(XtParent(widget),
					{'title\^@' ^name 'iconName\^@' ^name 0}, 2);
	fast_XptAppTryEvents(XptCurrentAppContext);
enddefine;

endsection;

:- prolog_language(prolog).

% current widget stuff
% xpw_current_window(?WidgetID)
xpw_current_window(WidgetID) :-
	var(WidgetID), !,
	WidgetID is plxt_get_current_widget(foo),
	prolog_evaltrue(quote(WidgetID)).
xpw_current_window(WidgetID) :-
	nonvar(WidgetID),
	prolog_eval(plxt_set_current_widget(quote(WidgetID))).


/* xpw_destroy_window(+WidgetID)
	Destroys the widget refered to by the ID number and removes it from
	the table
*/
xpw_destroy_window(WidgetID) :-
	Widget is plxt_id_to_widget(quote(WidgetID)),
	prolog_eval(plxt_destroy_widget_id(Widget)),
	prolog_eval(plxt_destroy_window(Widget)),!.

% find all curently active widgets
% xpw_active_windows(-List)
xpw_active_windows(List) :-
	List is plxt_fetch_all_actives(foo),!.

% set the title bar and icon manager name for a widget
% xpw_set_window_name(+WidgetID,+Name)
xpw_set_window_name(WidgetID,Name):-
	prolog_eval(plxt_set_widget_name(plxt_id_to_widget(quote(WidgetID)),
										plxt_string_translation(Name))),!.

:- endmodule xwidgets.

xwidgets.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 3 1991
		Changed -plxt_window- to use -XptNewWindow-
--- Simon Nichols, Nov 12 1990
		Changed xpw_current_window/1 to fail when there is no current window.
--- Andreas Schoter, Nov 8 1990
		Added current window versions of predicates
 */
