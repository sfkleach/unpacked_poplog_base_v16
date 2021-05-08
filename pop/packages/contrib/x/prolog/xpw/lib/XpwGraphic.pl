/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			contrib/x/prolog/xpw/lib/XpwGraphic.pl
 > Purpose:			Provide the functions of XpwGraphic.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * XpwGraphic PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xpwgraphic.

:- import xpw_current_window/1.

:- export	xpw_alloc_color_range/9, xpw_free_color_range/2,
			xpw_create_colormap/1, xpw_free_colormap/1, xpw_alloc_color/5,
			xpw_change_color/5,
			xpw_alloc_color_range/8, xpw_free_color_range/1,
			xpw_create_colormap/0, xpw_free_colormap/0, xpw_alloc_color/4,
			xpw_change_color/4.

:- prolog_language(pop11).

section;
;;; load the Pop11 library
lconstant XpwGraphic = XptWidgetSet("Poplog")("GraphicWidget");
endsection;

;;; add Graphic resources to prolog environment
plxt_add_resources(
	[	button_event	'buttonEvent\^@'
		mouse_event		'mouseEvent\^@'
		keyboard_event	'keyboardEvent\^@'
		motion_event	'motionEvent\^@'
		resize_event	'resizeEvent\^@'
		mouse_x			'mouseX\^@'
		mouse_y			'mouseY\^@'
		switch_cmaps	'switchCmaps\^@'
		use_private_gc	'usePrivateGC\^@'
		my_gc			'myGC\^@'
	]
);

:- prolog_language(prolog).

% shadow the Pop11 procedures
% xpw_alloc_color_range(+WID, +NumCells, +R1,+G1,+B1, +R2,+G2,+B2, -Base)
xpw_alloc_color_range(WidgetID,NumCells,R1,G1,B1,R2,G2,B2,Base) :-
	Base is 'XpwAllocColorRange'(plxt_id_to_widget(quote(WidgetID)),
			NumCells,R1,G1,B1,R2,G2,B2),!.

% xpw_free_color_range(+WidgetID, +Range)
xpw_free_color_range(WidgetID,Range) :-
	prolog_eval('XpwFreeColorRange'(plxt_id_to_widget(quote(WidgetID)),
				Range)),!.

% xpw_create_colormap(+WidgetID) :-
xpw_create_colormap(WidgetID) :-
	prolog_eval('XpwCreateColormap'(plxt_id_to_widget(quote(WidgetID)))),!.

% xpw_free_colormap(+WidgetID) :-
xpw_free_colormap(WidgetID) :-
	prolog_eval('XpwFreeColormap'(plxt_id_to_widget(quote(WidgetID)))),!.

% xpw_alloc_color(+WidgetID,+R,+G,+B,-PixVal) :-
xpw_alloc_color(WidgetID,R,G,B,PixVal) :-
	PixVal is 'XpwAllocColor'(plxt_id_to_widget(quote(WidgetID)),
								R,G,B),!.

% xpw_change_color(+WidgetID,+P,+R,+G,+B) :-
xpw_change_color(WidgetID,P,R,G,B) :-
	prolog_eval('XpwChangeColor'(plxt_id_to_widget(quote(WidgetID)),
								P,R,G,B)),!.

% current widget versions of predicates
xpw_alloc_color_range(NumCells,R1,G1,B1,R2,G2,B2,Base) :-
	xpw_current_window(WidgetID),
	xpw_alloc_color_range(WidgetID,NumCells,R1,G1,B1,R2,G2,B2,Base).

xpw_free_color_range(Range) :-
	xpw_current_window(WidgetID),
	xpw_free_color_range(WidgetID,Range).

xpw_create_colormap :-
	xpw_current_window(WidgetID),
	xpw_create_colormap(WidgetID).

xpw_free_colormap :-
	xpw_current_window(WidgetID),
	xpw_free_colormap(WidgetID).

xpw_alloc_color(R,G,B,PixVal) :-
	xpw_current_window(WidgetID),
	xpw_alloc_color(WidgetID,R,G,B,PixVal).

xpw_change_color(P,R,G,B) :-
	xpw_current_window(WidgetID),
	xpw_change_color(WidgetID,P,R,G,B).

:- endmodule xpwgraphic.

% define predicate for uses
'XpwGraphic'.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		Changed resource names back to strings - most Xt functions check for
		a string.
--- Andreas Schoter, Nov 8 1990
		Added current widget versions of predicates
--- Jonathan Meyer, Sep 19 1990
		Changed resource strings to words (XptValue works with words).
 */
