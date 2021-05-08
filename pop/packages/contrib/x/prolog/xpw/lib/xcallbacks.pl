/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			/csuna/pop/master/contrib/x/prolog/xpw/lib/xcallbacks.pl
 > Purpose:			Provide the functions of XpwPixmap.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * xcallbacks PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/


%  :- module xcallbacks.

%  :- import xpw_current_window/1.

%  :- export	xpw_add_callback/4, xpw_remove_callbacks/2,
%			xpw_add_callback/3, xpw_remove_callbacks/1.

:- prolog_language(pop11).

;;; return to toplevel to declare globals
section;
global vars plxt_last_event = undef;
endsection;

;;; This is the "universal" callback.  The last two arguments are suitably
;;; frozen-in.
;;;     widget      - the Pop11 widget record
;;;     client_data - irrelevant
;;;     event_data  - the event data, which must be stashed in the_last_event_data
;;;     plxt_widget - prolog toolkit widget number
;;;     pred        - the goal to be invoked on a callback.
;;;
define invoke_callback(widget,client_data,event_data,plxt_widget,pred);
	lvars widget,event_data,client_data,plxt_widget,pred;
	lvars count;

	exacc ^int event_data -> plxt_last_event;

	prolog_maketerm(
		plxt_widget,
		cons_with identfn {% prolog_appargs_nd(pred,identfn) %} -> count,
		prolog_functor(pred),
		count + 1
	).prolog_invoke.erase;
	XptAppTryEvents(XptCurrentAppContext);
enddefine;

define plxt_add_callback(widget,pred,callback_list,flag);
	lvars widget,pred,callback_list,flag;
	lvars w_id = plxt_widget_to_id(widget);
	if flag="clear" then
		XtRemoveAllCallbacks(widget,callback_list);
	elseunless flag="append" then
		mishap(flag,1,'Incorrect Mode for xpw_add_callback');
	endif;
	XtAddCallback(
		widget,
		callback_list,
		invoke_callback(% w_id.prolog_deref,pred.prolog_full_deref %),
		prolog_functor(pred)
	);
enddefine;

:- prolog_language(prolog).

% add a callback to the widget's list -
% if flag is is clear then remove all callbacks first
% if flag is append then add it to the end of the callbacks list
% xpw_add_callback(+WidgetID,+Pred,+CallList,+Flag)
xpw_add_callback(WidgetID,Pred,CallList,Flag):-
	prolog_eval(plxt_add_callback(plxt_id_to_widget(quote(WidgetID)),
				Pred,plxt_resource_name(CallList),Flag)),!.

% remove all callbacks from the list
% xpw_remove_callbacks(+WidgetID,+CallList)
xpw_remove_callbacks(WidgetID,CallList):-
	prolog_eval('XtRemoveAllCallbacks'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_resource_name(CallList))),!.

% current widget versions of predicates

xpw_add_callback(Pred,CallList,Flag):-
	xpw_current_window(WidgetID),
	xpw_add_callback(WidgetID,Pred,CallList,Flag).

xpw_remove_callbacks(CallList):-
	xpw_current_window(WidgetID),
	xpw_remove_callbacks(WidgetID,CallList).


%   :- endmodule xcallbacks.


/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		Changed all calls to fast procedures to the typechecking slow versions
--- Andreas Schoter, Jul 7 1991
		Updated to work with new external data syntax -exacc-
--- Andreas Schoter, Nov 8 1990
		Added current window versions of predicates
 */
