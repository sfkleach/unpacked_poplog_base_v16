/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			contrib/x/prolog/xpw/lib/XpwCore.pl
 > Purpose:			Provide the functions of XpwCore.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * XpwCore PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xpwcore.

:- import xpw_current_window/1.

:- export	xpw_set_font/3, xpw_set_color/3, xpw_set_cursor/3,
			xpw_free_font/2, xpw_free_color/2, xpw_free_cursor/2,
			xpw_set_font/2, xpw_set_color/2, xpw_set_cursor/2,
			xpw_free_font/1, xpw_free_color/1, xpw_free_cursor/1.

:- prolog_language(pop11).

section;
;;; load XpwCore
lconstant XpwCore = XptWidgetSet("Poplog")("CoreWidget");
endsection;

;;; add Core resources to prolog environment
plxt_add_resources(
	[	pointer_shape  	'pointerShape\^@'
		callback		'xpwCallback\^@'
		users_gc		'usersGC\^@'
		auto_flush		'autoFlush\^@'
		modifiers		'modifiers\^@'
	]);

:- prolog_language(prolog).

% shadow the XpwCore Pop11 procedures
% xpw_set_font(+WidgetID,+Font,-Value)
xpw_set_font(WidgetID,Font,Value) :-
	Value is 'XpwSetFont'(plxt_id_to_widget(quote(WidgetID)),
							plxt_string_translation(quote(Font))),
	!,prolog_evaltrue(Value).

% xpw_set_color(+WidgetID,+Color,-Value)
xpw_set_color(WidgetID,Color,Value) :-
	Value is 'XpwSetColor'(plxt_id_to_widget(quote(WidgetID)),
							plxt_string_translation(quote(Color))),
	!,prolog_evaltrue(Value).

% xpw_set_cursor(+WidgetID,+ShapeNum,-Value)
xpw_set_cursor(WidgetID,ShapeNum,Value) :-
	Value is 'XpwSetCursor'(plxt_id_to_widget(quote(WidgetID)),ShapeNum),
	!,prolog_evaltrue(Value).

% xpw_free_font(+WidgetID,+Font) :-
xpw_free_font(WidgetID,Font) :-
	prolog_eval('XpwFreeFont'(plxt_id_to_widget(quote(WidgetID)),
								plxt_string_translation(quote(Font)))),!.

% xpw_free_color(+WidgetID,+Color) :-
xpw_free_color(WidgetID,Color) :-
	prolog_eval('XpwFreeColor'(plxt_id_to_widget(quote(WidgetID)),
								plxt_string_translation(quote(Color)))),!.

% xpw_free_cursor(+WidgetID,+ShapeNum) :-
xpw_free_cursor(WidgetID,ShapeNum) :-
	prolog_eval('XpwFreeCursor'(plxt_id_to_widget(quote(WidgetID)),
								ShapeNum)),!.

% current widget versions of predicates
xpw_set_font(Font,Value) :-
	xpw_current_window(WidgetID),
	xpw_set_font(WidgetID,Font,Value).

xpw_set_color(Color,Value) :-
	xpw_current_window(WidgetID),
	xpw_set_color(WidgetID,Color,Value).

xpw_set_cursor(ShapeNum,Value) :-
	xpw_current_window(WidgetID),
	xpw_set_cursor(WidgetID,ShapeNum,Value).

xpw_free_font(Font) :-
	xpw_current_window(WidgetID),
	xpw_free_font(WidgetID,Font).

xpw_free_color(Color) :-
	xpw_current_window(WidgetID),
	xpw_free_color(WidgetID,Color).

xpw_free_cursor(ShapeNum) :-
	xpw_current_window(WidgetID),
	xpw_free_cursor(WidgetID,ShapeNum).


:- endmodule xpwcore.

% define a predicate so uses can recognise the library
'XpwCore'.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		Changed resource names to strings - some Xt functions check for a
		string argument
--- Andreas Schoter, Nov 8 1990
		Added current window versions of predicates
--- Jonathan Meyer, Sep 19 1990
		Changed resource strings to words
 */
