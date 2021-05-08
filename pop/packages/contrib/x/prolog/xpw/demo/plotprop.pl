/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			/csuna/pop/master/contrib/x/prolog/xpw/demo/plotprop.pl
 > Purpose:         Demonstration of some XProlog graphics facilities
 > Author:          Andreas Schoter, August 1990 (see revisions)
 > Documentation:   PLOGHELP * PLOTPROP
 > Related Files:
 */


% load 'are' library
:- library(are).

% declare the proposition calculus operators
:- op(800,xfx,<->).
:- op(700,xfy,->).
:- op(700,yfx,<-).
:- op(600,xfy,#).
:- op(500,xfy,&).
:- op(400,fy,~).

% some useful Pop11 procedures and control flag definitions
:- prolog_language(pop11).

;;; global flag for activity
vars propactive = false;

;;; default display mode
vars showupdate = "yes";

;;; default plotting scale
vars plot_scale = 2;

;;; default screen size constants (defined for Sun3/4 screen
constant screen_width = 1152;
constant screen_height = 900;

;;; procedure for scaling coordinates
define scale_dim(x); /* -> new_x */
	lvars x;
	round(x * plot_scale);
enddefine;

;;; procedure to ensure scale allows tree to fit on screen
;;; currently set up to work with a 1152x900 Sun3/4 screen size
;;; if the screen that you are running this program on is a different
;;; size it may be necessary to change the values of the constants
;;; -screen_width- and -screen_height-
define scale_check(w,d); /* -> width -> depth */
	lvars w,d;
	lvars flag = false;
	if w*plot_scale > screen_width then
		(screen_width-20)/w -> plot_scale;
		true -> flag;
	endif;
	if d*plot_scale > screen_height then
		(screen_height-20)/d -> plot_scale;
		true -> flag;
	endif;
	if flag then
		if plot_scale < 1 then
			mishap('Tree to big to fit on screen',[^plot_scale]);
		else
			warning('Scale set too large - automatically rescaled',
					[^plot_scale]);
		endif;
	endif;
	round(w*plot_scale);
	round(d*plot_scale);
enddefine;

:- prolog_language(prolog).

% -- The top-level user interface predicates --

/*	plot_proposition/2
mode	plot_proposition(Expression+, Model+)
read	Expression is an expression of propositional calculus using the
	syntax operators defined above.  Propositions are lowercase atoms.
	An example proposition is (p # q) <-> ~(~p & ~q).  Model is a list
	of the form [Proposition = TruthValue,...] where Proposition is as
	defined for Expression and TruthValue is one of the atoms 't' or 'f'
*/
plot_proposition(Expression,Model):-
	not(prolog_evaltrue(valof(propactive))),
	prolog_setq(propactive,valof(true)),
	retractall(prop_data(_,_,_,_)),
	graph_expression(Expression,Model,AGraph),
	prolog_setq(prop_graph,AGraph),
	interpret(AGraph).


/*	set_scale/1
mode	set_scale(Scale+)
read	set the scale factor used when plotting an expression tree to
		the value Scale > 0.
*/
set_scale(S):-
	nonvar(S),
	S >= 1,
	prolog_setq(plot_scale,S).


/*	set_show_update/1
mode	set_show_update(Flag+)
read	Set whether to show the tree being updated or to only show the
	finished product.
*/
set_show_update(yes):-
	prolog_setq(showupdate,yes).

set_show_update(no):-
	prolog_setq(showupdate,no).


/*	graph_expression/3
mode	graph_expression(Expression+, Model+, Graph-)
read	Expression is an expression of propositional calculus as defined
	for plot_proposition/2, Model is as defined for plot_proposition/2,
	Graph is a list, in prefix representation, of the Expression.
*/
graph_expression(Expression,Model,Graph):-
	expression_to_list(Expression,List),
	display_bin_tree(List,0,0,W,H,Graph),
	Ypos is H - scale_dim(15),
	Xpos is W - scale_dim(15),
	display_toggles(Model,1,Ypos),
	pix_place_node('!',Xpos,Ypos,black),
	assertz(exit_toggle(Xpos,Ypos)).


/*	display_toggles/3
mode	display_toggle(Model+, Count+, Ypos+)
read	Model is as defined for plot_proposition/2, Count is a counter used
	to keep track of the number of toggles so far drawn used to calculate
	the X coordinate, Ypos is the invarient Y coordinate.
*/
display_toggles([],_,_).

display_toggles([P = V|R],C,Y):-
	X is scale_dim(((C - 1) * 25) + 15),
	assertz(prop_data(P,V,X,Y)),
	colour(V,Colour),
	pix_place_node(P,X,Y,Colour),
	C1 is C + 1,
	display_toggles(R,C1,Y).


/*	expression_to_list/2
mode	expression_to_list(Expression+, List-)
read	Expression is a propositional expression, as defined for
	plot_proposition/2.  List is the result of translating Expression
	into prefix form
*/
expression_to_list(P,P):-
	atomic(P).

expression_to_list(P <-> Q,[<->,P1,Q1]):-
	expression_to_list(P,P1),
	expression_to_list(Q,Q1).

expression_to_list(P -> Q,[->,P1,Q1]):-
	expression_to_list(P,P1),
	expression_to_list(Q,Q1).

expression_to_list(P <- Q,[<-,P1,Q1]):-
	expression_to_list(P,P1),
	expression_to_list(Q,Q1).

expression_to_list(P # Q,[#,P1,Q1]):-
	expression_to_list(P,P1),
	expression_to_list(Q,Q1).

expression_to_list(P & Q,[&,P1,Q1]):-
	expression_to_list(P,P1),
	expression_to_list(Q,Q1).

expression_to_list(~P,[~,P1]):-
	expression_to_list(P,P1).


/*  display_bin_tree/6
mode	display_bin_tree(Graph+, Xpos+, Ypos+, Width-, Height-, AnnotatedG-)
read    Take the given Graph (a propositional expression in prefix list
	form) in the form of a list representing a binary tree and display it
	using the xprolog graphics interface, position the window at Xpos Ypos,
	the size of the window used is returned as Width (X) and Height (Y).
	AnnotatedG is the Graph, with each node annotated with its logical
	coordinates.
*/
display_bin_tree(Graph,X,Y,W,H,NotedGraph):-
	make_window_space(Graph,X,Y,W,H),
	xpw_set_color(black,_),
	xpw_draw_line([W,H - scale_dim(30),0,H - scale_dim(30)]),
	Lw is scale_dim(2),
	xt_value(current,line_width,Lw),
	traverse_and_notate(Graph,1,_,1,_,NotedGraph).


/*  make_window_space/5
mode    make_window_space(Graph+, Xpos+, Ypos+, Width-, Height-)
read    Take the given Graph and make a window ready to display it.
	Calculate the Width and Depth of the graph in terms of nodes, translate
	this into pixels, create the window, and make it the current graphic
	context.
*/
make_window_space(Graph,X,Y,WW,WD):-
	width_and_depth(Graph,W,D),
	window_size(D,W,WW,WD),
	xpw_graphic_window('PlotProp',[X,Y,WW,WD]),
	on_button_event('PlotProp',update_tree,append),
	select_font('PlotProp'),
	xpw_current_window('PlotProp').


/*  width_and_depth/3
mode    width_and_depth(Graph+, Width-, Depth-)
read    Calculate, for the given Graph, the Depth of the tree as a number
	of nodes, and the Width of the tree, allowing the width of one node
	between each leaf-node, so if the tree has 4 leaves the Width will be 7
*/
width_and_depth(Graph,W,D):-
	count_through(Graph,0,W1,0,D1),
	D is D1 + 1,
	W is W1 * 2 - 1.


/*  count_through/5
mode    count_through(SubGraph+, WidthIn+, WidthOut-, DepthIn+, DepthOut-)
read    Recurse through each SubGraph of the graph, count the total number
	of leaf nodes, and return the depth of the deepest branch
*/
count_through([Name,Branch],Win,Wout,Din,Dout):-
	atomic(Branch),
	Wout is Win + 1,
	Dout is Din + 1.

count_through([Name,Branch],Win,Wout,Din,Dout):-
	not(atomic(Branch)),
	count_through(Branch,Win,Wout,Din,D1),
	Dout is D1 + 1.

count_through([Name,Branch1,Branch2],Win,Wout,Din,Dout):-
	atomic(Branch1),
	atomic(Branch2),
	Wout is Win + 2,
	Dout is Din + 1.

count_through([Name,Branch1,Branch2],Win,Wout,Din,Dout):-
	atomic(Branch1),
	not(atomic(Branch2)),
	count_through(Branch2,Win,W1,Din,D1),
	Wout is W1 + 1,
	Dout is D1 + 1.

count_through([Name,Branch1,Branch2],Win,Wout,Din,Dout):-
	not(atomic(Branch1)),
	atomic(Branch2),
	count_through(Branch1,Win,W1,Din,D1),
	Wout is W1 + 1,
	Dout is D1 + 1.

count_through([Name,Branch1,Branch2],Win,Wout,Din,Dout):-
	not(atomic(Branch1)),
	not(atomic(Branch2)),
	count_through(Branch1,Win,W1,Din,D1),
	count_through(Branch2,W1,Wout,Din,D2),
	Dis is max(D1,D2),
	Dout is Dis + 1.


/*  traverse_and_notate/6
mode    traverse_and_notate(Graph+, DepthIn+, WidthOut-,
			LeafCountIn+, LeafCountOut-, AnnotatedGraph-)
read    Takes a prefix list propositional expression Graph and builds a new
	AnnotatedGraph, where each node is annotated with its logical coordinates
	DepthIn,  WidthOut, LeafCountIn and LeafCoutOut are used to calculate
	the logical coordinates of the current node.  As the AnnotatedGraph is
	being built it is being drawn to the window.
*/
traverse_and_notate([Name,Branch],Din,Lin,Lin,Lout,
					[[Name,Din,Lin],[Branch,D1,Lin]]):-
	atomic(Branch),
	D1 is Din + 1,
	Lout is Lin + 2,
	replace_node(Branch,D1,Lin,black),
	replace_node(Name,Din,Lin,black),
	connect_nodes(D1,Lin,Din,Lin).

traverse_and_notate([Name,Branch],Din,Wout,Lin,Lout,
					[[Name,Din,Wout],Rest]):-
	not(atomic(Branch)),
	D1 is Din + 1,
	traverse_and_notate(Branch,D1,Wout,Lin,Lout,Rest),
	replace_node(Name,Din,Wout,black),
	connect_nodes(Din,Wout,D1,Wout).

traverse_and_notate([Name,Branch1,Branch2],Din,Wout,Lin,Lout,
					[[Name,Din,Wout],[Branch1,D1,Lin],[Branch2,D1,L1]]):-
	atomic(Branch1),
	atomic(Branch2),
	D1 is Din + 1,
	L1 is Lin + 2,
	Lout is Lin + 4,
	replace_node(Branch1,D1,Lin,black),
	replace_node(Branch2,D1,L1,black),
	add_parent(Name,D1,Lin,D1,L1,Wout).

traverse_and_notate([Name,Branch1,Branch2],Din,Wout,Lin,Lout,
					[[Name,Din,Wout],[Branch1,D1,Lin],Rest]):-
	atomic(Branch1),
	not(atomic(Branch2)),
	D1 is Din + 1,
	L1 is Lin + 2,
	replace_node(Branch1,D1,Lin,black),
	traverse_and_notate(Branch2,D1,W1,L1,Lout,Rest),
	add_parent(Name,D1,Lin,D1,W1,Wout).

traverse_and_notate([Name,Branch1,Branch2],Din,Wout,Lin,Lout,
					[[Name,Din,Wout],Rest,[Branch2,D1,L1]]):-
	not(atomic(Branch1)),
	atomic(Branch2),
	D1 is Din + 1,
	traverse_and_notate(Branch1,D1,W1,Lin,L1,Rest),
	replace_node(Branch2,D1,L1,black),
	add_parent(Name,D1,W1,D1,L1,Wout),
	Lout is L1 + 2.

traverse_and_notate([Name,Branch1,Branch2],Din,Wout,Lin,Lout,
					[[Name,Din,Wout],R1,R2]):-
	not(atomic(Branch1)),
	not(atomic(Branch2)),
	D1 is Din + 1,
	traverse_and_notate(Branch1,D1,W1,Lin,L1,R1),
	traverse_and_notate(Branch2,D1,W2,L1,Lout,R2),
	add_parent(Name,D1,W1,D1,W2,Wout).


/*  window_size/4
mode    window_size(GDepth+, GWidth+, WWidth-, WDepth-)
read    Take the logical size of the graph expressing in terms of nodes
	and calculate the necessary window size expressed in terms of pixels
	this value is then checked against the current scale factor (which is
	modified if necessary)
*/
window_size(GDepth,GWidth,WWidth,WDepth):-
	WD is 70 + (GDepth - 1) * 60,
	WW is 20 + (GWidth) * 20,
	[WWidth,WDepth] are scale_check(WW,WD).


/*  pixpoint_x/2
mode    pixpoint_x(NodeCoord+, PixelCoord-)
read    Take the given logical NodeCoord and calculate the equivalent Pixel
	position in the window.  pixpoint_x is used to determine the x positions
	and pixpoint_y the y positions
*/
pixpoint_x(Depth,PixNum):-
	PixNum is round(scale_dim((Depth - 1) * 60 + 20)).

pixpoint_y(Width,PixNum):-
	PixNum is round(scale_dim((Width - 1) * 20 + 20)).


/*  place_node/4
mode    place_point(NodeName+, Depth+, Width+, Colour+)
read    Take the named Node and its logical coordinates expressed in terms
	of Depth into the graph and Width across the graph and display it on
	the current graphics window in the specified Colour
*/
place_node(Node,Depth,Width,Colour):-
	pixpoint_x(Depth,X),
	pixpoint_y(Width,Y),
	xpw_set_color(Colour,_),
	node(current,Node,Y,X).


/*	pix_place_node/4
mode	pix_place_node(Node+, Xpos+, Ypos+, Colour+)
read	Take the named Node and its physical coordinates expressed in terms
	of window pixel position Xpos,Ypos and displays it to the window in the
	specified Colour
*/
pix_place_node(Node,X,Y,Colour):-
	xpw_set_color(Colour,_),
	node(current,Node,X,Y).


/*  node/4
mode    node(WidgetID+, String+, XPos+, Ypos+)
read    Display a node on the window specified by the WidgetID number by
	drawing a circle centred on Xpos Ypos pixel coordinates and write the
	character string into the centre
*/
node(WidgetID,String,X,Y):-
	L is datalength(String),
	X1 is X - (scale_dim(10)+(L-1)*scale_dim(3)),
	X2 is scale_dim(20)+(L-1)*scale_dim(6),
	X3 is X - (scale_dim(3)+(L-1)*scale_dim(3)),
	xpw_draw_arc([X1,Y-scale_dim(10),X2,scale_dim(20),0,360],deg),
	xpw_draw_string(X3,Y+scale_dim(3),String).


/*  add_parent/6
mode    add_parent(NodeName+, D1+, W1+, D2+, W2+, Wout-)
read    Take the name of the node and the coordinates of its children
	specified in terms of logical node coordinates (D1,W1) and (D2,W2) and
	display the parent NodeName centred between them and connected by lines
*/
add_parent(Node,D1,W1,D1,W2,WN):-
	DN is D1 - 1,
	WN is (W1 + (W2 - W1) / 2),
	replace_node(Node,DN,WN,black),
	connect_nodes(D1,W1,DN,WN),
	connect_nodes(D1,W2,DN,WN).


/*  connect_nodes/4
mode    connect_nodes(D1+, W1+, D2+, W2+)
read    Connect the two nodes specified by node coordinates (D1,W1) and
	(D2,W2) and connect them with a line
*/
connect_nodes(IX1,IY1,IX2,IY2):-
	pixpoint_x(IX1,X1),
	pixpoint_x(IX2,X2),
	pixpoint_y(IY1,Y1),
	pixpoint_y(IY2,Y2),
	Len is sqrt((X1 - X2)*(X1 - X2) + (Y1 - Y2)*(Y1 - Y2)),
	Dx is (X1 - X2)/Len,
	Dy is (Y1 - Y2)/Len,
	xpw_draw_line(
		[round(Y1 - scale_dim(10)*Dy),round(X1 - scale_dim(10)*Dx),
		round(Y2 + scale_dim(10)*Dy),round(X2 + scale_dim(10)*Dx)]).


/*	interpret/1
mode	interpret(Graph+)
read	top level call to interpret/2 wrapped in auto_flush
*/
interpret(Graph):-
	set_on_update_flag,
	interpret(Graph,_),
	xt_value(current,pixmap_status,0).


/*	interpret/2
mode	interpret(Graph+, Value-)
read	Take the annotated graph of a prefix form propositional expression
	and interpret it according to the model currently in the database,
	returning the truth Value of the expression
*/
interpret([[Op,X1,Y1],[[Node,X2,Y2]|Branch]],Res):-
	atomic(Node),
	interpret([[Node,X2,Y2]|Branch],Value),
	tabulate(Op,Value,Res),
	finish_node([Op,X1,Y1],[Node,X2,Y2],Value,Res).

interpret([[Op,X1,Y1],[Node,X2,Y2]],Res):-
	atomic(Node),
	evaluate(Node,X2,Y2,Value),
	tabulate(Op,Value,Res),
	finish_node([Op,X1,Y1],[Node,X2,Y2],Value,Res).

interpret([[Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3]],Res):-
	atomic(Node1),
	atomic(Node2),
	evaluate(Node1,X2,Y2,Value1),
	evaluate(Node2,X3,Y3,Value2),
	tabulate(Op,Value1,Value2,Res),
	finish_node([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],Value1,Value2,Res).

interpret([[Op,X1,Y1],[Node1,X2,Y2],[[Node2,X3,Y3]|Branch]],Res):-
	atomic(Node1),
	evaluate(Node1,X2,Y2,Value1),
	interpret([[Node2,X3,Y3]|Branch],Value2),
	tabulate(Op,Value1,Value2,Res),
	finish_node([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],Value1,Value2,Res).

interpret([[Op,X1,Y1],[[Node1,X2,Y2]|Branch],[Node2,X3,Y3]],Res):-
	atomic(Node2),
	interpret([[Node1,X2,Y2]|Branch],Value1),
	evaluate(Node2,X3,Y3,Value2),
	tabulate(Op,Value1,Value2,Res),
	finish_node([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],Value1,Value2,Res).

interpret([[Op,X1,Y1],[[Node1,X2,Y2]|Branch1],[[Node2,X3,Y3]|Branch2]],Res):-
	interpret([[Node1,X2,Y2]|Branch1],Value1),
	interpret([[Node2,X3,Y3]|Branch2],Value2),
	tabulate(Op,Value1,Value2,Res),
	finish_node([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],Value1,Value2,Res).


/*	evaluate/4
mode	evaluate(Node+, X+, Y+, Value-)
read	evaluate the proposition represented by Node at logical position
	X,Y by redrawing the node with the corresponding truth Value
*/
evaluate(Node,X,Y,Value):-
	get_value_of(Node,Value),
	colour(Value,C),
	replace_node(Node,X,Y,C).


/*	get_value/2
mode	get_value(Proposition+, Value-)
read	determine the Value of the Proposition in the current model.
	Mishaps if the Proposition is not defined in the current model.
*/
get_value_of(Node,Value):-
	prop_data(Node,Value,_,_),!.

get_value_of(Node,_):-
	prolog_syserror('Proposition Not Defined In Model',[Node]).


/*	finish_node/4
mode	finish_node(Parent+, Child+, Value+, Result+)
read	take the subgraph described by Parent-Child and perform the graphics
	operations to colour the child's path with the colour for Value and
	replace the Parent with colour specified by Result
*/
finish_node([Op,X1,Y1],[Node,X2,Y2],Value,Res):-
	colour_paths([Op,X1,Y1],[Node,X2,Y2],Value),
	colour(Res,C),
	replace_node(Op,X1,Y1,C).


/*	finish_node/6
mode	finish_node(Parent+, Child1+, Child2+, Value1+, Value2+, Result+)
read	take the subgraph described by Parent-Child1/Child2 and perform the
	graphics operations to colour the children's paths with the colours for
	Value1 and Value2 and replace the Parent with colour specified by Result
*/
finish_node([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],V1,V2,Res):-
	colour_paths([Op,X1,Y1],[Node1,X2,Y2],[Node2,X3,Y3],V1,V2),
	colour(Res,C),
	replace_node(Op,X1,Y1,C).


/*	replace_node/4
mode	replace_node(Node+, X+, Y+, Colour+)
read	redraw the Node at logical position X,Y with the specified Colour
*/
replace_node(N1,X1,Y1,C):-
	xpw_graphic_raster_op(current,clear),
	pixpoint_x(X1,X),
	pixpoint_y(Y1,Y),
	L is datalength(N1),
	Y21 is Y-(scale_dim(11)+(L-1)*scale_dim(3)),
	Y22 is scale_dim(22)+(L-1)*scale_dim(6),
	xpw_fill_arc([Y21,X-scale_dim(11),Y22,scale_dim(22),0,360],deg),
	xpw_graphic_raster_op(current,copy),
	place_node(N1,X1,Y1,C).


/*	colour_paths/3
mode	colour_paths(Parent+, Child+, Value+)
read	colour the path described by Parent-Child with the colour for Value
*/
colour_paths([N1,X1,Y1],[N2,X2,Y2],Value):-
	L1 is datalength(N2),
	pixpoint_x(X2,X22),pixpoint_y(Y2,Y22),
	colour(Value,C),
	xpw_set_color(C,_),
	connect_nodes(X1,Y1,X2,Y2).


/*	colour_paths/5
mode	colour_paths(Parent+, Child1+, Child2+, Value1+, Value2+)
read	colour the path described by Parent-Child1/Child2 with the colours
	for Value1 and Value2
*/
colour_paths([N1,X1,Y1],[N2,X2,Y2],[N3,X3,Y3],V1,V2):-
	L1 is datalength(N2),
	L2 is datalength(N3),
	pixpoint_x(X2,X21),pixpoint_x(X3,X31),
	pixpoint_y(Y2,Y21),pixpoint_y(Y3,Y31),
	colour(V1,C1),colour(V2,C2),
	xpw_set_color(C1,_),
	connect_nodes(X2,Y2,X1,Y1),
	xpw_set_color(C2,_),
	connect_nodes(X3,Y3,X1,Y1).


/*	tabulate/3
mode	tabulate(Operator+, Value+, NewValue-)
read	NewValue is the result of apllying Operator to OldValue
*/
tabulate(~,t,f).
tabulate(~,f,t).


/*	tabulate/4
mode	tabulate(Operator+, OldVal1+, OldVal2+, NewValue-)
read	NewValue is the result of combining OldVal1 and OldVal2 using
	Operator
*/
tabulate(&,t,t,t).
tabulate(&,_,f,f):- !.
tabulate(&,f,_,f).
tabulate(#,f,f,f).
tabulate(#,_,t,t):- !.
tabulate(#,t,_,t).
tabulate(->,t,f,f):- !.
tabulate(->,_,_,t).
tabulate(<-,f,t,f):- !.
tabulate(<-,_,_,t).
tabulate(<->,X,X,t):- !.
tabulate(<->,_,_,f).


/*	colour/2
mode	colour(TruthValueSituation+, Colour-)
read	Colour is the colour to be used when drawing a portion of the
	graph with the specified TruthValue
*/
colour(t,'LimeGreen').
colour(f,'OrangeRed').
colour(path,'DeepSkyBlue').
colour(default,black).


/*	update_tree/1
mode	update_tree(WidgetID+)
read	update the tree for the propositional expression.  This is the
	code used by the callback mechanism to action a mouse event
*/
update_tree(W):-
	xpw_last_event(N),
	N > 0,
	xpw_mouse_xy(W,X,Y),
	in_button(X,Y,B),
	action_button(B),!.


/*	action_button/1
mode	action_button(ButtonName+)
read	peform the actions associated with ButtonName
*/
action_button('!'):-
	prolog_setq(propactive,valof(false)),
	xpw_destroy_window(current).

action_button(P):-
	retract(prop_data(P,V1,X,Y)),
	tabulate(~,V1,V2),
	assertz(prop_data(P,V2,X,Y)),
	colour(V2,C),
	pix_place_node(P,X,Y,C),
	prolog_val(prop_graph,AGraph),
	interpret(AGraph).


/*	in_button/3
mode	in_button(Xpos+, Ypos+, ButtonName-)
read	return the ButtonName of the mouse coordinates if Xpos,Ypos falls
	within the boundary of a button, otherwise fail
*/
in_button(X,Y,'!'):-
	exit_toggle(X1,Y1),
	in_range(X,Y,X1,Y1).

in_button(X,Y,B):-
	prop_data(B,_,X1,Y1),
	in_range(X,Y,X1,Y1).


/*	in_range/4
mode	in_range(X1+, Y1+, X2+, Y2+)
mode	{+ + + +}
read	determines whether the coordinate pairs X1,Y1 and X2,Y2 are within
	scale dimensioned 10 pixels of each other
*/
in_range(X1,Y1,X2,Y2):-
	Dx is (X1 - X2) * (X1 - X2),
	Dy is (Y1 - Y2) * (Y1 - Y2),
	scale_dim(11) > sqrt(Dx + Dy).


/*	select_font/1
mode	select_font(WidgetID+)
read	Selects the most suitable font for the plotting scale of the
	given window
*/
select_font(W):-
	prolog_val(plot_scale,S),
	suitable_font(W,S).


/*	suitable_font/2
mode	suitable_font(WidgetID+, Scale+)
read	Given a plotting Scale, set the font for WidgetID to a suitably
	sized font.
*/
suitable_font(W,S):-
	S < 2,
	xpw_set_font(W,'9x15',_).

suitable_font(W,S):-
	S >= 2,
	xpw_set_font(W,'lucidasans-bold-24',_).



/*	set_on_update_flag/0
read	If the showupdate flag is no then turn off pixmap screen updating
*/
set_on_update_flag:-
	prolog_val(showupdate,no),
	xt_value(current,pixmap_status,3).

set_on_update_flag.


/*	Demo Calls
?- set_show_update(no).
?- plot_proposition(t & p -> q & (~r # s),[t = t,p = f,q = f,r = t,s = t]).
?- plot_proposition(~(a & (b # ~c)) -> (b & d <-> (a -> (c # d))),[a=t,b=f,c=t,d=f]).
?- plot_proposition(~p # ~q <-> ~(p & q),[p = t,q = f]).
?- plot_proposition((p & (p -> q)) -> q,[p = f,q = t]).
?- plot_proposition(~q & (p -> q) -> ~p,[p = t,q = f]).
?- plot_proposition(p # (q & r) <-> (p # q) & (p # r),[p = t,q = f,r = t]).
?- plot_proposition(~(p # ~q) <-> ~p & q,[p = t,q = f]).
*/

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jun 10 1991 tidied up and removed some redundent
	predicates
 */
