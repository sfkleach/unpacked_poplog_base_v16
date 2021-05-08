/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			/csuna/pop/master/contrib/x/prolog/xpw/lib/xt_value.pl
 > Purpose:			Provide the functions of XpwPixmap.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * xt_value PLOGHELP * xprolog
 > Related Files:	LIB * xresources * XpwBasics
*/

:- module xt_value.

:- export xt_value/3, xt_value_nocheck/3, xt_value/4, xt_value_nocheck/4.

:- prolog_language(pop11).

section $-xt_value fast_XptValue =>;

;;; translate a Prolog atom to a usable value
define plxt_value_translate(value); /* -> translation */
	lvars value;
	if isword(value) then
		value sys_>< '\^@';
	elseif isinteger(value) then
		value;
	else
		mishap(value,datakey(value),2,'Unrecognised Value Type');
	endif;
enddefine;

;;; set a resource value
define plxt_set_value(widget,resource,value,coerce);
	lvars widget,resource,value,coerce;
	plxt_value_translate(value) ->
		XptValue(widget,plxt_string_translation(resource),coerce);
enddefine;

;;; get a resource value
define plxt_get_value(widget,resource,coerce);
	lvars widget,resource,coerce;
	XptValue(widget,plxt_string_translation(resource),coerce);
enddefine;

endsection;

:- prolog_language(prolog).

% resource access predicate

% xt_value(+WidgetID,+ResourceName,?Value)
xt_value(WidgetID,ResourceName,Value):-
	var(Value),
	Value is plxt_get_value(plxt_id_to_widget(quote(WidgetID)),
						plxt_resource_name(quote(ResourceName)),int),!.
xt_value(WidgetID,ResourceName,Value):-
	nonvar(Value),
	prolog_eval(plxt_set_value(plxt_id_to_widget(quote(WidgetID)),
								plxt_resource_name(quote(ResourceName)),
								Value,int)),!.

% xt_value(+WidgetID,+ResourceName,+Coerce,?Value)
xt_value(WidgetID,ResourceName,Coerce,Value):-
	var(Value),
	Value is plxt_get_value(plxt_id_to_widget(quote(WidgetID)),
						plxt_resource_name(quote(ResourceName)),
							quote(Coerce)),!.
xt_value(WidgetID,ResourceName,Coerce,Value):-
	nonvar(Value),
	prolog_eval(plxt_set_value(plxt_id_to_widget(quote(WidgetID)),
								plxt_resource_name(quote(ResourceName)),
								Value,quote(Coerce))),!.

% xt_value_nocheck(+WidgetID,+ResourceName,?Value)
xt_value_nocheck(WidgetID,ResourceName,Value):-
	var(Value),
	Value is plxt_get_value(plxt_id_to_widget(quote(WidgetID)),
						quote(ResourceName),int),!.
xt_value_nocheck(WidgetID,ResourceName,Value):-
	nonvar(Value),
	prolog_eval(plxt_set_value(plxt_id_to_widget(WidgetID),
							quote(ResourceName),Value,int)),!.

% xt_value_nocheck(+WidgetID,+ResourceName,+Coerce,?Value)
xt_value_nocheck(WidgetID,ResourceName,Coerce,Value):-
	var(Value),
	Value is plxt_get_value(plxt_id_to_widget(quote(WidgetID)),
						quote(ResourceName),quote(Coerce)),!.
xt_value_nocheck(WidgetID,ResourceName,Coerce,Value):-
	nonvar(Value),
	prolog_eval(plxt_set_value(plxt_id_to_widget(WidgetID),
								quote(ResourceName),Value,quote(Coerce))),!.


:- endmodule xt_value.

% predicate for "uses"
xt_value.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		changed call to fast_XptValue to XptValue
--- Andreas Schoter, Jul 3 1991
		Added call to -plxt_string_translation- to -plxt_get_value- and
		-plxt_set_value- to ensure that resource names are in the correct
		format for -fast_XptValue-
 */
