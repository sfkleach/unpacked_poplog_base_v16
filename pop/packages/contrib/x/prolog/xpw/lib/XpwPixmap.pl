/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			contrib/x/prolog/xpw/lib/XpwPixmap.pl
 > Purpose:			Provide the functions of XpwPixmap.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * XpwPixmap PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xpwpixmap.

:- import xpw_current_window/1.

:- export	xpw_graphic_window/2, xpw_graphic_check/1, xpw_graphic_raster_op/2,
			xpw_clear_window/1, xpw_draw_point/2, xpw_draw_points/3,
			xpw_draw_line/2, xpw_draw_lines/3, xpw_draw_segments/2,
			xpw_draw_rectangle/2, xpw_draw_rectangles/2, xpw_draw_arc/3,
			xpw_draw_arcs/3, xpw_fill_arc/3, xpw_fill_arcs/3,
			xpw_fill_polygon/2, xpw_fill_rectangle/2, xpw_fill_rectangles/2,
			xpw_draw_string/4, xpw_draw_image_string/4,
			xpw_copy_to/4, xpw_copy_from/4, xpw_graphic_raster_op/1,
			xpw_clear_window/0, xpw_draw_point/1, xpw_draw_points/2,
			xpw_draw_line/1, xpw_draw_lines/2, xpw_draw_segments/1,
			xpw_draw_rectangle/1, xpw_draw_rectangles/1, xpw_draw_arc/2,
			xpw_draw_arcs/2, xpw_fill_arc/2, xpw_fill_arcs/2,
			xpw_fill_polygon/1, xpw_fill_rectangle/1, xpw_fill_rectangles/1,
			xpw_draw_string/3, xpw_draw_image_string/3.

:- prolog_language(pop11).

section $-xpwpixmap XptLiveTypeCheck, XptCheckWidgetClass fast_XptValue =>;

section;
;;; load Pop11 library
lconstant XpwPixmap = XptWidgetSet("Poplog")("PixmapWidget");
endsection;

;;; add Pixmap resources to the prolog environment
plxt_add_resources(
	[	private_gc		'privateGC\^@'
		pixmap_status   'pixmapStatus\^@'
		line_width		'lineWidth\^@'
		line_style		'lineStyle\^@'
		cap_style   	'capStyle\^@'
		join_style		'joinStyle\^@'
		subwindow_mode	'subwindowMode\^@'
	]);


;;; raster op function - adapted from Gareth Palmer's xt_graphic
lconstant plxt_raster_ops = newassoc([
	[^GXclear		  clear]
	[^GXand			  and]
	[^GXandReverse	  and_reverse]
	[^GXcopy		  copy]
	[^GXandInverted	  and_inverted]
	[^GXnoop		  noop]
	[^GXxor			  xor]
	[^GXor			  or]
	[^GXnor			  nor]
	[^GXequiv		  equiv]
	[^GXinvert		  invert]
	[^GXorReverse	  or_reverse]
	[^GXcopyInverted  copy_inverted]
	[^GXorInverted	  or_inverted]
	[^GXnand		  nand]
	[^GXset			  set]

	[clear		   ^GXclear]
	[and		   ^GXand]
	[and_reverse   ^GXandReverse]
	[copy		   ^GXcopy]
	[and_inverted   ^GXandInverted]
	[noop		   ^GXnoop]
	[xor		   ^GXxor]
	[or			   ^GXor]
	[nor		   ^GXnor]
	[equiv		   ^GXequiv]
	[invert		   ^GXinvert]
	[or_reverse	   ^GXorReverse]
	[copy_inverted ^GXcopyInverted]
	[or_inverted   ^GXorInverted]
	[nand		   ^GXnand]
	[set		   ^GXset]
]);

define plxt_set_graphic_raster_op(widget,op);
	lvars op widget;
	lvars value;
	unless plxt_raster_ops(op) ->> value then
		mishap(op, 1, 'Invalid raster operation');
	endunless;
	value -> fast_XptValue(widget,'function\^@');
enddefine;

define plxt_get_graphic_raster_op(widget); /* -> op */
	lvars widget;
	plxt_raster_ops(fast_XptValue(widget,'function\^@'));
enddefine;

define plxt_graphic_check(w);
	lvars w;
	XptLiveTypeCheck(w,"Widget");
	unless XptCheckWidgetClass(w) == "XpwGraphic" then
		mishap(w,1,'XpwGraphic widget needed');
	endunless;
enddefine;

define plxt_check_name(name);
	lvars name;
	if name == "current" then
		mishap(name,1,'Illegal name for window');
	elseif not(isword(name)) then
		mishap(name,1,'Atom needed for window name');
	elseif plxt_check_id(name) then
		mishap(name,1,'Name already attached to a window');
	endif;
enddefine;

;;; procedures for translating between angle formats
define plxt_angle_translation(angle,mode); /* -> new_angle */
	lvars angle,mode;
	if mode = "raw" then
		round(angle);
	elseif mode = "deg" then
		round(angle * 64);
	elseif mode = "rad" then
		round(angle * #_< 64*360/2/pi >_#);
	else
		mishap(mode,1,'Incorrect mode for xpw_draw_arc');
		false;
	endif;
enddefine;

define plxt_block_angle_translate(argslist,mode); /* -> new_argslist */
	lvars argslist,mode;
	lvars item,count=1,tot;;
		[%
		for item in argslist do
			item(1);
			item(2);
			item(3);
			item(4);
			plxt_angle_translation(item(5),mode);
			plxt_angle_translation(item(6),mode);
		endfor;
		%];
enddefine;

;;; process a list of coordinate
define plxt_process_list(list);
	lvars list;
	lvars item;

	[%
		for item in list do
			explode(item);
		endfor;
	%];
enddefine


endsection;

:- prolog_language(prolog).


/* xpw_graphic_window(+WindowName,+SizeArgs)

	Creates a new graphic window, SizeArgs is a list [XPos,YPos,XSize,YSize]
	with the handle Windowname
*/
% mode {+ + -}
xpw_graphic_window(Name,[X,Y,W,H]) :-
	prolog_eval(plxt_check_name(quote(Name))),
	prolog_eval(
		plxt_create_widget_id(quote(Name),
			plxt_window(quote(Name),[W,H,X,Y]))),!.

/*	Similar to above predicate, but allows the user to generate windows
	and position them with the mouse
*/
xpw_graphic_window(Name,[W,H]) :-
	prolog_eval(plxt_check_name(quote(Name))),
	prolog_eval(
		plxt_create_widget_id(quote(Name),
			plxt_window(quote(Name),[W,H]))),!.

% check a widget is a graphic widget
% xpw_graphic_check(+WidgetID)
xpw_graphic_check(WidgetID):-
	prolog_eval(plxt_graphic_check(plxt_id_to_widget(quote(WidgetID)))),!.


% raster op stuff
% xpw_graphic_raster_op(+WidgetID,?Value)
xpw_graphic_raster_op(WidgetID,Value) :-
	var(Value),
	Value is plxt_get_graphic_raster_op(plxt_id_to_widget(quote(WidgetID))),!.
xpw_graphic_raster_op(WidgetID,Value) :-
	prolog_eval(plxt_set_graphic_raster_op(plxt_id_to_widget(quote(WidgetID)),
				Value)),!.


% graphics functions
% xpw_clear_window(+WidgetID)
xpw_clear_window(WidgetID) :-
	prolog_eval('XpwClearWindow'(
				plxt_id_to_widget(quote(WidgetID)))
				),!.

% xpw_draw_point(+WidgetID,+XYPair)
xpw_draw_point(WidgetID,[X,Y]) :-
	prolog_eval('XpwDrawPoint'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y)
				),!.

% xpw_draw_points(+WidgetID,+CoordList,+Mode)
xpw_draw_points(WidgetID,CoordList,origin) :-
	prolog_eval('XpwDrawPoints'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_process_list(CoordList),0)
				),!.
xpw_draw_points(WidgetID,CoordList,previous) :-
	prolog_eval('XpwDrawPoints'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_process_list(CoordList),1)
				),!.

% xpw_draw_line(+WidgetID,+LineSpec)
xpw_draw_line(WidgetID,[X1,Y1,X2,Y2]) :-
	prolog_eval('XpwDrawLine'(
				plxt_id_to_widget(quote(WidgetID)),
				X1,Y1,X2,Y2)
				),!.

% xpw_draw_lines(+WidgetID,+CoordList,+Mode)
xpw_draw_lines(WidgetID,CoordList,origin) :-
	prolog_eval('XpwDrawLines'(
				plxt_id_to_widget(quote(WidgetID)),
				CoordList,0)
				),!.
xpw_draw_lines(WidgetID,CoordList,previous) :-
	prolog_eval('XpwDrawLines'(
				plxt_id_to_widget(quote(WidgetID)),
				CoordList,1)
				),!.

% xpw_draw_segments(+WidgetID,+CoordList)
xpw_draw_segments(WidgetID,CoordList) :-
	prolog_eval('XpwDrawSegments'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_process_list(CoordList))
				),!.

% xpw_draw_rectangle(+WidgetID,+RectangleSpec)
xpw_draw_rectangle(WidgetID,[X,Y,Width,Height]) :-
	prolog_eval('XpwDrawRectangle'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,Width,Height)
				),!.

% xpw_draw_rectangles(+WidgetID,+CoordList)
xpw_draw_rectangles(WidgetID,CoordList) :-
	prolog_eval('XpwDrawRectangles'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_process_list(CoordList))
				),!.

% argument Mode is one of 'deg', 'rad' or 'raw'
% specifying how the numbers for the angles are to be interpreted
% xpw_draw_arc(+WidgetID,+ArcSpecification,+Mode)
xpw_draw_arc(WidgetID,[X,Y,Width,Height,StartAngle,AngleIncr],Mode) :-
	prolog_eval('XpwDrawArc'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,Width,Height,
				plxt_angle_translation(StartAngle,Mode),
				plxt_angle_translation(AngleIncr,Mode))
				),!.

% xpw_draw_arcs(+WidgetID,+ArcsList,+Mode) :-
xpw_draw_arcs(WidgetID,ArcsList,Mode) :-
	prolog_eval('XpwDrawArcs'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_block_angle_translate(ArcsList,Mode))
				),!.

% xpw_fill_arc(+WidgetID,+ArcSpec,+Mode)
xpw_fill_arc(WidgetID,[X,Y,Width,Height,StartAngle,AngleIncr],Mode) :-
	prolog_eval('XpwFillArc'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,Width,Height,
				plxt_angle_translation(StartAngle,Mode),
				plxt_angle_translation(AngleIncr,Mode))
				),!.

% xpw_fill_arcs(+WidgetID,+ArcsList,+Mode)
xpw_fill_arcs(WidgetID,ArcsList,Mode) :-
	prolog_eval('XpwFillArcs'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_block_angle_translate(ArcsList,Mode))
				),!.

% assumes shape -Complex- and mode -CoordModeOrigin-
% xpw_fill_polygon(+WidgetID,+CoordList)
xpw_fill_polygon(WidgetID,CoordList) :-
	prolog_eval('XpwFillPolygon'(
				plxt_id_to_widget(quote(WidgetID)),
				CoordList,quote(1,0))
				),!.

% xpw_fill_rectangle(+WidgetID,+RectSpec)
xpw_fill_rectangle(WidgetID,[X,Y,Width,Height]) :-
	prolog_eval('XpwFillRectangle'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,Width,Height)
				),!.

% xpw_fill_rectangles(+WidgetID,+CoordList)
xpw_fill_rectangles(WidgetID,CoordList) :-
	prolog_eval('XpwFillRectangles'(
				plxt_id_to_widget(quote(WidgetID)),
				plxt_process_list(CoordList))
				),!.

% String is a prolog atom or a list of characters
% xpw_draw_string(+WidgetID,+X,+Y,+String)
xpw_draw_string(WidgetID,X,Y,String) :-
	prolog_eval('XpwDrawString'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,
				plxt_string_translation(String))
				),!.

% xpw_draw_image_string(+WidgetID,+X,+Y,+String)
xpw_draw_image_string(WidgetID,X,Y,String) :-
	prolog_eval('XpwDrawImageString'(
				plxt_id_to_widget(quote(WidgetID)),
				X,Y,
				plxt_string_translation(String))
				),!.

% xpw_copy_to(+WidgetID1,+WidgetID2,+SourceRectx,+DestPoint)
xpw_copy_to(WidgetID1,WidgetID2,[X,Y,DX,DY],[EX,EY]) :-
	prolog_eval('XpwCopyTo'(
				plxt_id_to_widget(quote(WidgetID1)),
				plxt_id_to_widget(quote(WidgetID2)),
				X,Y,DX,DY,EX,EY)
				),!.

% xpw_copy_from(+WidgetID1,+WidgetID2,+SourceRectX,+DestPoint)
xpw_copy_from(WidgetID1,WidgetID2,[X,Y,DX,DY],[EX,EY]) :-
	prolog_eval('XpwCopyFrom'(
				plxt_id_to_widget(quote(WidgetID1)),
				plxt_id_to_widget(quote(WidgetID2)),
				X,Y,DX,DY,EX,EY)
				),!.

% current window versions of predicates

xpw_graphic_raster_op(Value) :-
	xpw_current_window(WidgetID),
	xpw_graphic_raster_op(WidgetID,Value).

xpw_clear_window :-
	xpw_current_window(WidgetID),
	xpw_clear_window(WidgetID).

xpw_draw_point([X,Y]) :-
	xpw_current_window(WidgetID),
	xpw_draw_point(WidgetID,[X,Y]).

xpw_draw_points(CoordList,Mode) :-
	xpw_current_window(WidgetID),
	xpw_draw_points(WidgetID,CoordList,Mode).

xpw_draw_line([X1,Y1,X2,Y2]) :-
	xpw_current_window(WidgetID),
	xpw_draw_line(WidgetID,[X1,Y1,X2,Y2]).

xpw_draw_lines(CoordList,Mode) :-
	xpw_current_window(WidgetID),
	xpw_draw_lines(WidgetID,CoordList,Mode).

xpw_draw_segments(CoordList) :-
	xpw_current_window(WidgetID),
	xpw_draw_segments(WidgetID,CoordList).

xpw_draw_rectangle([X,Y,Width,Height]) :-
	xpw_current_window(WidgetID),
	xpw_draw_rectangle(WidgetID,[X,Y,Width,Height]).

xpw_draw_rectangles(CoordList) :-
	xpw_current_window(WidgetID),
	xpw_draw_rectangles(WidgetID,CoordList).

xpw_draw_arc([X,Y,Width,Height,StartAngle,AngleIncr],Mode) :-
	xpw_current_window(WidgetID),
	xpw_draw_arc(WidgetID,[X,Y,Width,Height,StartAngle,AngleIncr],Mode).

xpw_draw_arcs(ArcsList,Mode) :-
	xpw_current_window(WidgetID),
	xpw_draw_arcs(WidgetID,ArcsList,Mode).

xpw_fill_arc([X,Y,Width,Height,StartAngle,AngleIncr],Mode) :-
	xpw_current_window(WidgetID),
	xpw_fill_arc(WidgetID,[X,Y,Width,Height,StartAngle,AngleIncr],Mode).

xpw_fill_arcs(ArcsList,Mode) :-
	xpw_current_window(WidgetID),
	xpw_fill_arcs(WidgetID,ArcsList,Mode).

xpw_fill_polygon(CoordList) :-
	xpw_current_window(WidgetID),
	xpw_fill_polygon(WidgetID,CoordList).

xpw_fill_rectangle([X,Y,Width,Height]) :-
	xpw_current_window(WidgetID),
	xpw_fill_rectangle(WidgetID,[X,Y,Width,Height]).

xpw_fill_rectangles(CoordList) :-
	xpw_current_window(WidgetID),
	xpw_fill_rectangles(WidgetID,CoordList).

xpw_draw_string(X,Y,String) :-
	xpw_current_window(WidgetID),
	xpw_draw_string(WidgetID,X,Y,String).

xpw_draw_image_string(X,Y,String) :-
	xpw_current_window(WidgetID),
	xpw_draw_image_string(WidgetID,X,Y,String).

:- endmodule xpwpixmap.

% define a predicate so uses can recognise the library
'XpwPixmap'.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		Changed resource names back to strings - some Xt functions check
		for a string argument
--- Andreas Schoter, Jun 13 1991
		Fixed syntax error (missing comment mark) in line 188
--- Andreas Schoter, Jun 11 1991
		Added a clause to -xpw_graphic_window- to allow for the generation
		of windows positioned by mouse
--- Simon Nichols, Nov 12 1990
		Fixed -plxt_check_name- to check that the name is an atom.
		Changed text of mishap messages to lower case in -plxt_check_name-
		and -plxt_graphic_check-.
--- Andreas Schoter, Nov 8 1990
		Added current window versions of predicates
--- Jonathan Meyer, Sep 19 1990
		Changed resource strings to words
 */
