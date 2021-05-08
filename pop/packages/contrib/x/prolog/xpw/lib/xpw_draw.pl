/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $popcontrib/x/prolog/xpw/lib/xpw_draw.pl
 > Purpose:         Defines general purpose drawing predicate
 > Author:          Simon Nichols, Nov 27 1990
 > Documentation:	HELP * XPW_DRAW
 */

:- module xpw_draw.
:- export
	xpw_draw/1,
	xpw_draw/2,
	xpw_graphic_window/4,
	xpw_define_shape/2.

:- import
	xpw_graphic_window/2,
	xpw_draw_point/2,
	xpw_draw_line/2,
	xpw_draw_lines/3,
	xpw_draw_rectangle/2,
	xpw_draw_arc/2,
	xpw_draw_string/4,
	xpw_draw_image_string/4,
	xpw_fill_rectangle/2,
	xpw_fill_polygon/2,
	xpw_fill_arc/3,
	xpw_colour/2,
	xpw_set_font/3,
	xpw_free_font/2,
	xpw_graphic_raster_op/1.

:- dynamic xpw_define_shape/2.


% flatten_coordinates(+CoordinatePairs, -CoordinateList)

flatten_coordinates([(X,Y)|List1], [X,Y|List2]) :- !,
	flatten_coordinates(List1, List2).
flatten_coordinates([], []).


% xpw_graphic_window(+Title, (+X,+Y), +Width, +Height)

xpw_graphic_window(Title, (X,Y), Width, Height) :-
	xpw_graphic_window(Title, [X,Y,Width,Height]).


% xpw_draw(+Shape)
% xpw_draw(+Window, +Shape)

xpw_draw(Shape) :-
	xpw_draw(current, Shape).

xpw_draw(Window, [Shape|Shapes]) :- !,
	xpw_draw(Window, Shape),
	xpw_draw(Window, Shapes).
xpw_draw(_, []) :- !.

xpw_draw(Window, (X,Y)) :- !,
	xpw_draw_point(Window, [X,Y]).
xpw_draw(Window, line((X1,Y1),(X2,Y2))) :- !,
	xpw_draw_line(Window, [X1,Y1,X2,Y2]).
xpw_draw(Window, lines(CoordinatePairs)) :- !,
	xpw_draw(Window, lines(CoordinatePairs,origin)).
xpw_draw(Window, lines(CoordinatePairs,Mode)) :- !,
	flatten_coordinates(CoordinatePairs, CoordinateList),
	xpw_draw_lines(Window, CoordinateList, Mode).
xpw_draw(Window, rectangle((X,Y),Width,Height)) :- !,
	xpw_draw_rectangle(Window, [X,Y,Width,Height]).
xpw_draw(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr)) :- !,
	xpw_draw(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr,deg)).
xpw_draw(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr,Mode)) :- !,
	xpw_draw_arc(Window, [X,Y,Width,Height,StartAngle,AngleIncr], Mode).
xpw_draw(Window, text((X,Y),Text)) :- !,
	xpw_draw_string(Window, X, Y, Text).
xpw_draw(Window, image_text((X,Y),Text)) :- !,
	xpw_draw_image_string(Window, X, Y, Text).
xpw_draw(Window, colour(Colour,Shape)) :- !,
	xpw_colour(Window, OldColour),
	xpw_draw(Window, Shape),
	xpw_colour(Window, OldColour).
xpw_draw(Window, color(Colour,Shape)) :- !,
	xpw_draw(Window, colour(Colour,Shape)).
xpw_draw(Window, font(Font,Shape)) :- !,
	xpw_set_font(Window, Font, _),
	xpw_draw(Window, Shape),
	xpw_free_font(Window, Font).
xpw_draw(Window, raster_op(NewOp,Shape)) :- !,
	xpw_graphic_raster_op(OldOp),
	xpw_graphic_raster_op(NewOp),
	xpw_draw(Window, Shape),
	xpw_graphic_raster_op(OldOp).
xpw_draw(Window, fill(Shape)) :-
	xpw_fill(Window, Shape).
xpw_draw(Window, Shape1) :-
	xpw_drawing_method(Shape1,Shape2),
	xpw_draw(Window, Shape2).
xpw_draw(Window, fill(Shape1)) :-
	xpw_drawing_method(Shape1,Shape2),
	xpw_draw(Window, fill(Shape2)).


% xpw_fill(+Window, +Shape)

xpw_fill(Window, [Shape|Shapes]) :- !,
	xpw_fill(Window, Shape),
	xpw_fill(Window, Shapes).
xpw_fill(_, []) :- !.

xpw_fill(Window, rectangle((X,Y),Width,Height)) :- !,
	xpw_fill_rectangle(Window, [X,Y,Width,Height]).
xpw_fill(Window, polygon(CoordinatePairs)) :- !,
	flatten_coordinates(CoordinatesPairs, CoordinateList),
	xpw_fill_polygon(Window, CoordinateList).
xpw_fill(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr)) :- !,
	xpw_fill(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr,deg)).
xpw_fill(Window, arc((X,Y),Width,Height,StartAngle,AngleIncr,Mode)) :- !,
	xpw_fill_arc(Window, [X,Y,Width,Height,StartAngle,AngleIncr], Mode).
xpw_fill(Window, Shape) :-
	xpw_draw(Window, Shape).

:- endmodule xpw_draw.
