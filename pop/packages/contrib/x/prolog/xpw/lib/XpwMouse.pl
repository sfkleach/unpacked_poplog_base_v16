/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:			C.all/x/prolog/lib/XpwMouse.pl
 > Purpose:			Provide useful mouse related predicates
 > Author:			Andreas Schoter, August 1990
 > Documentation:	REF * XpwMouse, PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xpwmouse.

:- import	xpw_current_window/1, xt_value/3, xpw_add_callback/4.

:- export	xpw_last_event/1, xpw_mouse_xy/3,
			on_button_event/3, on_motion_event/3, on_mouse_event/3,
			xpw_mouse_xy/2,
			on_button_event/2, on_motion_event/2, on_mouse_event/2.

% get the last event
% xpw_last_event(-Event)
xpw_last_event(Event):-
	prolog_val(plxt_last_event,Event),!.

% utility for adding mouse button callbacks
% on_button_event(+WidgetID,+Pred,+Mode)
on_button_event(WidgetID,Pred,Mode):-
	xpw_add_callback(WidgetID,Pred,button_event,Mode).

% utility for adding mouse motion callbacks
% on_motion_event(+WidgetID,+Pred,+Mode)
on_motion_event(WidgetID,Pred,Mode):-
	xpw_add_callback(WidgetID,Pred,motion_event,Mode).

% utility for adding enter/leave event callbacks
% on_mouse_event(+WidgetID,+Pred,+Mode):-
on_mouse_event(WidgetID,Pred,Mode):-
	xpw_add_callback(WidgetID,Pred,mouse_event,Mode).

% get the X,Y of the last mouse down
% xpw_mouse_xy(+WidgetID,-X,-Y)
xpw_mouse_xy(WidgetID,X,Y):-
	xt_value(WidgetID,mouse_x,X),
	xt_value(WidgetID,mouse_y,Y),!.

% current widget versions of predicates

on_button_event(Pred,Mode):-
	xpw_current_window(WidgetID),
	on_button_event(WidgetID,Pred,Mode).

on_motion_event(Pred,Mode):-
	xpw_current_window(WidgetID),
	on_motion_event(WidgetID,Pred,Mode).

on_mouse_event(Pred,Mode):-
	xpw_current_window(WidgetID),
	on_mouse_event(WidgetID,Pred,Mode).

xpw_mouse_xy(X,Y):-
	xpw_current_window(WidgetID),
	xpw_mouse_xy(WidgetID,X,Y).


:- endmodule xpwmouse.

'XpwMouse'.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Nov 8 1990
		Added current window versions of predicates
 */
