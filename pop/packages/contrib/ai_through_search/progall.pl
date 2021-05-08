/* --- Copyright Chris Thornton and Benedict du Boulay 1992.  All rights reserved. ---------
 > File:           progall.pl
 > Purpose:        Prolog code from book - below
 > Author:         Chris Thornton & Benedict du Boulay
 > Documentation:  AI Through Search, Oxford: Intellect, 1992.
 > Related Files:  progall.p
 > Version: 1.0
 */

/* ------------------ PROGRAMS FROM CHAPTER 2 ------------------------- */

/* successor(+Here, -Next)
   Successor embodies the relation between a location and its successor. */

successor(seven_dials, preston_circus).
successor(seven_dials, station).
successor(seven_dials, west_pier).
successor(preston_circus, seven_dials).
successor(preston_circus, the_level).
successor(preston_circus, the_parallels).
successor(the_level, preston_circus).
successor(the_level, the_parallels).
successor(the_level, old_steine).
successor(old_steine, the_level).
successor(old_steine, the_parallels).
successor(old_steine, palace_pier).
successor(palace_pier, clocktower).
successor(palace_pier, old_steine).
successor(palace_pier, west_pier).
successor(west_pier, palace_pier).
successor(west_pier, clocktower).
successor(west_pier, seven_dials).
successor(station, seven_dials).
successor(station, clocktower).
successor(the_parallels, preston_circus).
successor(the_parallels, the_level).
successor(the_parallels, old_steine).
successor(the_parallels, clocktower).
successor(clocktower, station).
successor(clocktower, the_parallels).
successor(clocktower, palace_pier).
successor(clocktower, west_pier).

/* search_path(+Path_so_far, +Goal, -Solution_path)
   Given a Path_so_far and a Goal, search_path succeeds
   with a Solution_path that extends the Path_so_far to the Goal. */

search_path(Path_so_far, Goal, Solution_path) :-
    last(Path_so_far, Current_location),
    is_goal(Current_location, Goal), !,
    Path_so_far = Solution_path.

search_path(Path_so_far, Goal, Solution_path) :-
    last(Path_so_far, Current_location),
    successor(Current_location, Successor),
    not(member(Successor, Path_so_far)),
    append(Path_so_far, [Successor], New_path),
    search_path(New_path, Goal, Solution_path).

/* is_goal(+Location, +Goal)
   is_goal succeeds if the Location is equal to the Goal. */

is_goal(Goal, Goal).

/* last(+List, -Element)
   last succeeds if Element is the final element of List. */

last([X], X) :- !.
last([_ | L], X) :- last(L, X).

/* append(+List1, +list2, -List3)
   append succeeds if List1 and list2 together form List3. */

append([], L, L).
append([X | L1], L2, [X | L3]) :- append(L1, L2, L3).

/* member(+Element, +list)
   member succeeds if Element is a member of List. */

member(X, [X | _]).
member(X, [_ | L]) :- member(X, L).

/* successor(+Location, -Successor)
   The toytown map. */

successor(a, b).
successor(a, c).
successor(c, f).
successor(b, e).
successor(b, d).
successor(d, x).
successor(e, x).
successor(x, z).
successor(z, y).

/* successors(+Location, -Successors)
   successors succeeds when Successors is a list of the successors
   of Location, or is an empty list when there are none. */

successors(Location, Successors) :-
    bagof(Successor, successor(Location, Successor), Successors), !.

successors(_, []).

/* search_tree(+Path_so_far, +Goal, -Tree)
   Given a Path_so_far and a Goal, search_tree succeeds if Tree is the search
   tree starting from the path so far which either reaches the goal or reaches
   a dead ends.  */

search_tree(Path_so_far, Goal, Tree) :-
    last(Path_so_far, Current_location),
    is_goal(Current_location, Goal), !,
    [Current_location] = Tree.

search_tree(Path_so_far, Goal, Tree) :-
    last(Path_so_far, Current_location),
    successors(Current_location, Successors),
    sub_trees(Path_so_far, Successors, Goal, Subtrees),
    [Current_location | Subtrees] = Tree.

/* sub_trees(+Path_so_far, +Successors, +Goal, -Subtrees)
   sub_trees takes a Path_so_far, a list of immediate Successors
   and a Goal, and succeeds with a list of Subtrees corresponding to
   the list of Successors. */

sub_trees(_, [], _, []).

sub_trees(Path_so_far, [Succ | Succs], Goal, Subtrees) :-
    member(Succ, Path_so_far),
    sub_trees(Path_so_far, Succs, Goal, Subtrees).

sub_trees(Path_so_far, [Succ | Succs], Goal, [Subtree | Subtrees]) :-
    append(Path_so_far, [Succ], New_path_so_far),
    search_tree(New_path_so_far, Goal, Subtree),
    sub_trees(Path_so_far, Succs, Goal, Subtrees).

/* ------------------ PROGRAMS FROM CHAPTER 3 ------------------------- */

/* successor(+This_state, -Next_state)
   successor succeeds with This_state of the water jugs problem if
   Next_state is a succeeding state. */

successor([X,Y],[4,Z]) :- not(Y=0), not(X=4), X+Y > 4, Z is X+Y-4.
successor([X,Y],[Z,0]) :- not(Y=0), not(X=4), X+Y =< 4, Z is X+Y.
successor([X,Y],[Z,3]) :- not(X=0), not(Y=3), X+Y > 3, Z is X+Y-3.
successor([X,Y],[0,Z]) :- not(X=0), not(Y=3), X+Y =< 3, Z is X+Y.
successor([X,Y],[0,Y]) :- not(X=0).
successor([X,Y],[X,0]) :- not(Y=0).
successor([X,Y],[4,Y]) :- not(X=4).
successor([X,Y],[X,3]) :- not(Y=3).

/* agenda_search(+Agenda, +Goal, +Search_type, +Depth, -Solution)
   agenda_search takes an Agenda of paths, a Goal, a Search_type,
   either depth or breadth, and a maximum Depth, and succeeds
   when path is a Solution path. */

agenda_search([Path | _], Goal, _, _, Solution) :-
    Path = [Current_location | _],
    is_goal(Current_location, Goal), !,
    rev(Path, [], Solution),
    chatty_print(Path).

agenda_search([Path | Paths], Goal, Search_type, Depth, Solution) :-
    length(Path, Length),
    Length > Depth, !,
    chatty_print(Path),
    agenda_search(Paths, Goal, Search_type, Depth, Solution).

agenda_search([Path | Paths], Goal, Search_type, Depth, Solution) :-
    chatty_print(Path),
    Path = [Current_location | _],
    successors(Current_location, Successors),
    new_paths(Path, Successors, New_paths),
    extend_agenda(Paths, New_paths, Search_type, New_agenda),
    agenda_search(New_agenda, Goal, Search_type, Depth, Solution).

/* chatty_print(+Path)
   chatty_print prints a path for tracing purposes. */

chatty_print(Path) :-
   chatty, !,
   rev(Path, [], Reversed_path),
   write(Reversed_path), nl.

chatty_print(_).

/* rev(+List, +Sofar, -Reversed_list)
   rev is true when Reversed_list is the reverse of List */

rev([], Sofar, Sofar).

rev([H | T], Sofar, Reversed_list) :-
   rev(T, [H | Sofar], Reversed_list).

/* extend_agenda(+Agenda, +New_paths, +Search_type, -New_agenda)
   extend_agenda takes an Agenda of paths, and New paths, a search type
   and succeeds with a new agenda containing the new paths
   in a position according to the search type. */

extend_agenda(Agenda, New_paths, depth, New_agenda) :-
   append(New_paths, Agenda, New_agenda).

extend_agenda(Agenda, New_paths, breadth, New_agenda) :-
   append(Agenda, New_paths, New_agenda).

/* new_paths(+Path, +Successors, -New_paths)
   new_paths succeeds with New_paths made from an existing Path and a
   list of Successors, omitting any new path that contains the same
   state twice. */

new_paths(_, [], []).

new_paths(Path, [Succ | Succs], New_paths) :-
    member(Succ, Path), !,
    new_paths(Path, Succs,  New_paths).

new_paths(Path, [Succ | Succs], [[Succ | Path] | New_paths]) :-
    new_paths(Path, Succs, New_paths).

/* iterative_deepening_search(+Initial_state, +Goal, +Depth, +Maxdepth, -S)
   iterative deepening search succeeds with a solution S, given an
   Initial_state, a Goal, a Depth and an overall Maxdepth. */

iterative_deepening_search(_, _, Depth, Maxdepth, _) :-
   Depth > Maxdepth,
   !, fail.

iterative_deepening_search(Initial_state, Goal, Depth, Maxdepth, S) :-
   agenda_search([[Initial_state]], Goal, depth, Depth, S), !.

iterative_deepening_search(Initial_state, Goal, Depth, Maxdepth, S) :-
   New_depth is Depth + 1,
   iterative_deepening_search(Initial_state, Goal, New_depth, Maxdepth, S).

/* ------------------ PROGRAMS FROM CHAPTER 4 ------------------------- */

/* successor(+Current_state, -Next_state)
   Given a Current_state, successor succeeds with the Next_state first by
   columns and then by rows. */

successor([A,B,C,D,E,F,G,H,I],[A1,B1,C1,D1,E1,F1,G1,H1,I1]) :-
  slide([[A,D,G],[B,E,H],[C,F,I]],[[A1,D1,G1],[B1,E1,H1],[C1,F1,I1]]).

successor([A,B,C,D,E,F,G,H,I],[A1,B1,C1,D1,E1,F1,G1,H1,I1]) :-
  slide([[A,B,C],[D,E,F],[G,H,I]],[[A1,B1,C1],[D1,E1,F1],[G1,H1,I1]]).

/* deal with each column or row. X, Y and Z are bound to either whole rows
   or whole columns. */

slide([X,Y,Z],[X1,Y,Z]) :- move_tile(X,X1).
slide([X,Y,Z],[X,Y1,Z]) :- move_tile(Y,Y1).
slide([X,Y,Z],[X,Y,Z1]) :- move_tile(Z,Z1).

/* deal with a column or row, downs and rights before ups and lefts.
   C1 and C2 are bound to either a whole row or a whole column. */

move_tile(C1,C2) :- down(C1,C2).
move_tile(C1,C2) :- up(C1,C2).

/* move tile down or to the right. X and Y are bound to individual tiles. */

down([X,Y,hole],[X,hole,Y]).
down([X,hole,Y],[hole,X,Y]).

/* move tile up or to the left. X and Y are bound to individual tiles.  */

up([hole,X,Y],[X,hole,Y]).
up([X,hole,Y],[X,Y,hole]).

/* position(+Tile, +State, -Position)
   position, given a Tile and a State, succeeds with the tile's position
   in that state. */

position(Tile, [Tile | _], 1) :- !.

position(Tile, [ _ | Rest], N) :-
    position(Tile, Rest, M),
    N is M + 1.

/* abs(+Number, -Absolute_value)
   Absolute_value is the absolute value of number. */

abs(D, D) :- D >= 0, !.

abs(D, NewD) :- NewD is -D.

/* columndist(+Tile, +State, -Distance)
   columndist computes the minimum number of moves to get a Tile to its
   home column in the given state. */

columndist(Tile, State, Dist) :-
    position(Tile, State, Pos),
    D is ((Tile - 1) mod 3) - ((Pos - 1) mod 3),
    abs(D, Dist).

/* rowdist(+Tile, +State, -Distance)
   rowdist computes the minimum number of moves to get a Tile to its
   home row in the given state. */

rowdist(Tile, State, Dist) :-
    position(Tile, State, Pos),
    D is ((Tile - 1) div 3) - ((Pos - 1) div 3),
    abs(D, Dist).

/* distance_to_goal(+State, -Distance)
   distance_to_goal computes the minimum manhattan cost of getting all the
   tiles in the given state to their correct positions. */

distance_to_goal(State, N) :-
    count_tiles(State, State, N).

/* count_tiles(+State, +State, -Distance)
   count_tiles computes the total minimum number of moves to get all
   the tiles back to their correct locations in the given state. */

count_tiles([], _, 0).

count_tiles([hole | Rest], State, N) :-
    count_tiles(Rest, State, N).

count_tiles([Tile | Rest], State, N) :-
    rowdist(Tile, State, D1),
    columndist(Tile, State, D2),
    count_tiles(Rest, State, M),
    N is D1 + D2 + M.

/* closeness_to_goal(+State, -Value)
   closeness_to_goal computes the inverse value, 100 max, of
   getting the tiles in the given state to their goal positions. */

closeness_to_goal(State, Value) :-
    distance_to_goal(State, N), !, Value is 100 - N.

/* closer_to_goal(+State1, +State2)
   closer_to_goal succeeds if state1 is nearer the goal than state2. */

closer_to_goal(State1, State2) :-
   distance_to_goal(State1, M), distance_to_goal(State2, N), !,
   M =< N.

/* better_path_h(+Path1, +Path2)
   better_path_h succeeds if Path1 is nearer the goal than Path2. */

better_path_h(Path1, Path2) :-
   Path1 = [State1 | _], Path2 = [State2 | _], !,
   closer_to_goal(State1, State2).

/* better_path_g_h(+Path1, +Path2)
   better_path_g_h compares Path1 and Path2 taking into account
   both their lengths plus the closeness to the goal of their most
   recent states.  It succeeds if Path1 is closer or as close as
   Path2. */

better_path_g_h(Path1, Path2) :-
   length(Path1, G1), Path1 = [State1 | _],
   distance_to_goal(State1, H1),
   length(Path2, G2), Path2 = [State2 | _],
   distance_to_goal(State2, H2),
   F1 is G1 - 1 + H1,
   F2 is G2 - 1 + H2, !,
   F1 =< F2.

/* agenda_search(+Agenda, +Goal, +Search_type, +Visited, +Depth, -Path)
   agenda_search takes an Agenda of paths, a Goal, a Search type, a list of nodes
   already Visited and a maximum Depth, and succeeds with a Solution path. */

agenda_search([Path | _], Goal, _, _, _, Solution) :-
    Path = [Current_location | _],
    is_goal(Current_location, Goal), !,
    chatty_print(Path),
    rev(Path, [], Solution).

agenda_search([Path | Paths], Goal, Search_type, Visited, Depth, Solution) :-
    length(Path, Length), Length > Depth, !,
    chatty_print(Path),
    agenda_search(Paths, Goal, Search_type, Visited, Depth, Solution).

agenda_search([Path | Paths], Goal, Search_type, Visited, Depth, Solution) :-
    chatty_print(Path),
    Path = [Current_location | _],
    successors(Current_location, Successors),
    new_paths(Path, Successors, Extended_paths),
    extend_agenda(Paths, Path, Extended_paths, Search_type, [Path | Visited],
                                                      New_visited, New_agenda),
    agenda_search(New_agenda, Goal, Search_type, New_visited, Depth, Solution).

/* extend_agenda(+Paths, +Path, +Extended_paths, +Search_type, +Visited, -New_visited, -New_agenda)
   extend_agenda takes an Agenda, a Path, a list of Extended paths, a Search type
   and a list of nodes already Visited and succeeds with a New agenda containing
   the new paths and with a possibly augmented list of Visited nodes. */

extend_agenda(Agenda, _, Extended_paths, depth, _, _, New_agenda) :-
    append(Extended_paths, Agenda, New_agenda).

extend_agenda(Agenda, _, Extended_paths, breadth, _, _, New_agenda) :-
    append(Agenda, Extended_paths, New_agenda).

extend_agenda(Agenda, Path, Extended_paths, hill_climbing, _, _, New_agenda) :-
    sort(Extended_paths, [Best_new_path | _], better_path_h),
    better_path_h(Best_new_path, Path),
    append([Best_new_path], Agenda, New_agenda).

extend_agenda(Agenda, _, Extended_paths, best_first, _, _, New_agenda) :-
    append(Agenda, Extended_paths, Unsorted_agenda),
    sort(Unsorted_agenda, New_agenda, better_path_h).

extend_agenda(Agenda, _, Extended_paths, a_star, Visited, New_visited, New_agenda) :-
    prune(Extended_paths, New_extended_paths, Visited, New_visited, Agenda, New_paths),
    append(New_paths, New_extended_paths, Unsorted_agenda),
    sort(Unsorted_agenda, New_agenda, better_path_g_h).

/* prune(+Extended_paths, -New_extended_paths, +Visited, -New_visited, +Paths,
          -New_paths)
   prune takes a list of extended paths, a list of already visited nodes
   and an agenda (Paths), and succeeds with new versions of all of these
   according to the ordered state space search algorithm. */

prune([], [], Visited, Visited, Paths, Paths).

prune([New_path | Extended_paths], [New_path | New_extended_paths], Visited,
       New_visited, Paths, New_paths)
    :-
    not(path_member(New_path, _, Visited, _)),
    not(path_member(New_path, _, Paths, _)),
    prune(Extended_paths, New_extended_paths, Visited, New_visited, Paths,
          New_paths).

prune([New_path | Extended_paths], [New_path | New_extended_paths],
      Visited, New_new_visited, Paths, New_paths)
    :-
    path_member(New_path, Expanded_path, Visited, New_visited), !,
    better_path_g_h(New_path, Expanded_path),
    prune(Extended_paths, New_extended_paths, New_visited, New_new_visited,
          Paths, New_paths).

prune([New_path | Extended_paths], [New_path | New_extended_paths],
      Visited, New_visited, Paths, New_new_paths)
    :-
    path_member(New_path, Unexpanded_path, Paths, New_paths), !,
    better_path_g_h(New_path, Unexpanded_path),
    prune(Extended_paths, New_extended_paths, Visited, New_visited,
          New_paths, New_new_paths).

prune([New_path | Extended_paths], New_extended_paths, Visited, New_visited,
      Paths, New_paths)
    :-
    prune(Extended_paths, New_extended_paths, Visited, New_visited, Paths,
          New_paths).

/* path_member(+Path, -Found_path, +Path_list, -New_Path_list)
   path_member takes a path and a list of paths and succeeds with a Found_path
   which ends with the same node as the given Path and a New_Path_list
   which omits the Found_Path. */

path_member(Path, Found, [Found | Path_list], Path_list) :-
   Path = [Node | _],
   Found = [Node | _].

path_member(Path, Found, [Other | Path_list], [Other | New_path_list]) :-
   path_member(Path, Found, Path_list, New_path_list).

/* sort(+Unsorted_list, -Sorted_list, +Comparison_method)
   sort sorts its first argument to give its second argument
   using the comparison method in its third argument. */

sort([], [], Pred).

sort([Item | Items], Sorted, Pred) :-
    sort(Items, New_Items, Pred),
    insert(Item, New_Items, Sorted, Pred).

/* insert(+Item, +List, -Extended_list, +Comparison_method)
   insert Item in List to give Extended_list as per the
   Comparison_method. */

insert(Item, [], [Item], _).

insert(Item, [First | Rest], [Item, First | Rest], Pred) :-
    Check =.. [Pred, Item, First],
    call(Check).

insert(Item, [First | Rest], [First | New_Rest], Pred) :-
    insert(Item, Rest, New_Rest, Pred).

/* ------------------ PROGRAMS FROM CHAPTER 5 ------------------------- */

/* distance_to_goal(+Node, -Distance)

distance to goal computes the distance of Node to the goal. */
distance_to_goal([1], 9) :- !.
distance_to_goal([2], 0) :- !.
distance_to_goal([3], 0) :- !.
distance_to_goal([Sticks],Dist) :-
  Dist is Sticks - 2.

/* static_value(+Node, -Proximity)
  static value computes the proximity to the goal with 9 the highest,
  i.e. from MAX's point of view. */

static_value(Sticks, Proximity) :-
  distance_to_goal(Sticks, Distance),
  Proximity is 9 - Distance.

/* successor(+Node, -Successor)
  successor computes the Successor of Node. */

successor([2],[1]) :- !.
successor([Sticks],[Next]) :-
   not(Sticks = 1),
   Next is Sticks - 2.
successor([Sticks],[Next]) :-
   not(Sticks = 1),
   Next is Sticks - 1.

/* maxs_go(+Depth)
  maxs_go succeeds if the depth is an even number. */

maxs_go(Depth) :-
   0 is Depth mod 2.
/* minimax_search(+Node, +Depth, +Lookahead, -Value)
  minimax_search succeeds with the Value of a Node given its Depth and
  a Lookahead value. */

minimax_search(Node, Depth, Lookahead, Value) :-
   Depth >= Lookahead, !,
   static_value(Node, Value).
minimax_search(Node, Depth, Lookahead, Value) :-
   successors(Node, Successors),
   find_best(Successors, Depth, Lookahead, Value).

/* find_best(+Successors, +Depth, +Lookahead, -Value)
  find_best works through the list of successors and returns in
  value the best value produced by minimaxing on each one in turn. */

find_best(Successors, Depth, Lookahead, Value) :-
  maxs_go(Depth), !,
  find_best1(Successors, Depth, Lookahead, -1000, Value).
find_best(Successors, Depth, Lookahead, Value) :-
  find_best1(Successors, Depth, Lookahead, 1000, Value).

/* find_best1(+Successors, +Depth, +Lookahead, +So_far, +Value)
  find_best1 succeeds with the maximum Value from minimaxing on each of the
  successors.  So_far holds the best value gained at any particular
  point in the cycle. */

find_best1([], _, _, So_far, So_far).
find_best1([Successor | Successors], Depth, Lookahead, So_far, Value) :-
  New_depth is Depth + 1,
  minimax_search(Successor, New_depth, Lookahead, This_value),
  compare1(Depth, This_value, So_far, Better),
  find_best1(Successors, Depth, Lookahead, Better, Value).

/* compare1(+Depth, +This_value, +Best_so_far, -Better_one)
  According to the depth Better_one will hold the better of the
  current value being considered and the best one found so far.
  compare1 maximises at MAX's depth and minimises otherwise. */

compare1(Depth, This_value, So_far, This_value) :-
  maxs_go(Depth),
  This_value > So_far, !.
compare1(Depth, This_value, So_far, This_value) :-
  not(maxs_go(Depth)),
  This_value < So_far, !.
compare1(_, This_value, So_far, So_far).

/* alphabeta(Node,Depth,Alpha Value,Beta Value,Lookahead,Resultant Value) */

alphabeta_search(Node, Depth, Lookahead, Lower, Upper, Value) :-
   Depth >= Lookahead, !,
   static_value(Node, Value).
alphabeta_search(Node, Depth, Lookahead, Lower, Upper, Value) :-
   successors(Node, Successors),
   find_best2(Successors, Depth, Lookahead, Lower, Upper, Value).

/* find_best2(+Successors, +Depth, +Lookahead, +Lower, +Upper, -Value)
  find_best2 cycles through Successors checking the values of Lower and
  Upper.  If Lower exceeds Upper, pruning takes place. */

find_best2([], Depth, _, Lower, _, Lower) :-
  maxs_go(Depth).
find_best2([], Depth, _, _, Upper, Upper) :-
  not(maxs_go(Depth)).
find_best2( _, Depth, _, Lower, Upper, Value) :-
   Lower >= Upper, !,
   chatty_print([pruning]),
   find_best2([], Depth, _, Lower, Upper, Value).
find_best2([Succ | Succs], Depth, Lookahead, Lower, Upper, Value) :-
   New_Depth is Depth + 1,
   alphabeta_search(Succ, New_Depth, Lookahead, Lower, Upper, This_value),
   compare2(Depth, This_value, Lower, New_lower, Upper, New_upper),
   find_best2(Succs, Depth, Lookahead, New_lower, New_upper, Value).

/* compare2(+Depth, +This_value, +Lower, -New_lower, +Upper, -New_upper)
  compare uses the depth to compare This_value with either the existing
  lower or existing upper bound.  One bound is modified if appropriate. */

compare2(Depth, This_value, Lower, This_value, Upper, Upper) :-
   maxs_go(Depth),
   This_value > Lower, !.
compare2(Depth, This_value, Lower, Lower, Upper, This_value) :-
   not(maxs_go(Depth)),
   This_value < Upper, !.
compare2(_, _, Lower, Lower, Upper, Upper).

/* ------------------ PROGRAMS FROM CHAPTER 6 ------------------------- */

/* rule(+[<SUCCESSOR>,<predecessor(s)>]) */

rule([[have,smarties]]).  /* FACTS */
rule([[have,eggs]]).
rule([[have,flour]]).
rule([[have,money]]).
rule([[have,car]]).
rule([[in,kitchen]]).
rule([[decorate,cake],[have,cake],[have,icing]]).   /* RULES */
rule([[decorate,cake],[have,cake],[have,smarties]]).
rule([[have,money],[in,bank]]).
rule([[have,cake],[have,money],[in,store]]).
rule([[have,cake],[in,kitchen],[have,phone]]).
rule([[in,store],[have,car]]).
rule([[in,bank],[have,car]]).

/* backwards_search(+List_of_goals_to_be_satisfied)
  backwards_search succeeds if the list of goals can be proved. */

backwards_search([]).
backwards_search([Goal | Goals]) :-
   rule([Goal | Subgoals]),
   backwards_search(Subgoals),
   backwards_search(Goals).

/* backwards_search_tree(+List_of_goals_to_be_satisfied, -Resultant_AND-tree)
  backwards_search_tree takes a list of goals and returns the proof tree
  without checking for loops */

backwards_search_tree([], []).
backwards_search_tree([Goal | Goals], [[Goal | Tree] | Trees]) :-
   rule([Goal | Subgoals]),
   backwards_search_tree(Subgoals, Tree),
   backwards_search_tree(Goals, Trees).

/* backwards_search_tree(+List_of_goals_to_be_satisfied, +Depth,  -Tree)
  backwards_search succeeds with Tree if the list of goals can
  be proved without exceeding the Depth-limit */

backwards_search_tree([], _, []).
backwards_search_tree([Goal | Goals], Depth, [[Goal | Tree] | Trees])
   :-
   Depth > 0,
   rule([Goal | Subgoals]),
   New_depth is Depth - 1,
   backwards_search_tree(Subgoals, New_depth, Tree),
   backwards_search_tree(Goals, Depth, Trees).

/* SOME RULES FOR TESTING LOOP CHECKING */

rule([[stop1]]).
rule([[stop2]]).
rule([[go],[next]]).      /* MUTUALLY RECURSIVE */
rule([[next],[stop1],[go]]).      /* RULES */
rule([[next],[stop1],[stop2]]).

/* iterative_deepening_backwards_search(+Goals, +Depth, +Depth_limit, -Tree)
  iterative deepening succeeds with the search Tree for the given Goals,
  if backwards_search_tree succeeds within the overall Depth_limit. */

iterative_deepening_backwards_search(Goals, Depth, Depth_limit, Tree) :-
   backwards_search_tree(Goals, Depth, Tree).
iterative_deepening_backwards_search(Goals, Depth, Depth_limit, Tree) :-
   Depth < Depth_limit,
   New_depth is Depth + 1,
   iterative_deepening_backwards_search(Goals, New_depth, Depth_limit, Tree).

/* ------------------ PROGRAMS FROM CHAPTER 7 ------------------------- */

/* operator(-[[operator, Operator_Name]
             [preconditions, Preconditions]
             [additions, Additions]
             [deletions, Deletions]]).   */

operator([[operator, stand_back],
         [preconditions, near_box],
         [additions, safe],
         [deletions, near_box]]).
operator([[operator, go_forward],
         [preconditions, safe],
         [additions, near_box],
         [deletions, safe]]).
operator([[operator, light_firework_safely],
         [preconditions, near_box, box_open, have_fire, firework_out],
         [additions, firework_alight],
         [deletions, firework_out]]).
operator([[operator, open_box],
         [preconditions, near_box, box_closed],
         [additions, box_open],
         [deletions, box_closed]]).
operator([[operator, close_box],
         [preconditions, near_box, box_open],
         [additions, box_closed],
         [deletions, box_open]]).
operator([[operator, use_lighter],
         [preconditions, have_lighter],
         [additions, have_fire],
         [deletions]]).
operator([[operator, strike_match],
         [preconditions, have_matches],
         [additions, have_fire],
         [deletions]]).
operator([[operator, enjoy_firework],
         [preconditions, firework_alight, box_closed, safe],
         [additions, happy],
         [deletions]]).

/* achieve1(+Goals, +Initial_state, +Depth, -Plan, -Final_state)
  achieve1 takes a list of Goals and an Initial state of the world and a
  Depth and succeeds with a Plan and a Final state of the world. */

achieve1([], Initial, _, [], Final) :-
   Initial = Final.
achieve1([Goal | Goals], Initial, Depth, Plan, Final) :-
   Depth > 0,
   member(Goal, Initial), !,
   achieve1(Goals, Initial, Depth, Plan, Final),
   allpresent([Goal | Goals], Final).
achieve1([Goal | Goals], Initial, Depth, Plan, Final) :-
   Depth > 0,
   operator([[operator | Operator],
             [preconditions | Preconds],
             [additions | Adds],
             [deletions | Dels]]),
   member(Goal, Adds),
   New_depth is Depth - 1,
   achieve1(Preconds, Initial, New_depth, Pre_plan, Intermediate1),
   append(Pre_plan, Operator, Sub_plan),
   allremove(Dels, Intermediate1, Intermediate2),
   append(Adds, Intermediate2, Intermediate3),
   achieve1(Goals, Intermediate3, Depth, Plans, Final),
   allpresent([Goal | Goals], Final),
   append(Sub_plan, Plans, Plan).

/* find_plan(+Starting State, +Goal State, -Resultant Plan)
  find_plan succeeds if achieve1 succeeds with a depth limit of 10 */

find_plan(Start_state, Goals, Plan) :-
   achieve1(Goals, Start_state, 10, Plan, _).

/* allremove(+Items to be Removed, +From this List, -Resultant List)
  allremove removes each item in its first list from its second list
  to give its third list. */

allremove([], World, World).
allremove([Item | Items], World, Result_World) :-
  remove(Item, World, New_World),
  allremove(Items, New_World, Result_World).

/* remove(+an Item, +From this List, -Resultant List)
  remove removes only the first instance of the Item,
  and fails if there is no instance to remove. */

remove(Item, [Item | Rest], Rest).
remove(Item, [First | Rest], [First | New_Rest]) :-
  remove(Item, Rest, New_Rest).

/* allpresent(+Given Items, +List which should contain given Items)
  allpresent succeeds if it can remove each one of the given items.  */

allpresent(Items, List) :-
  allremove(Items, List, _).

/* operator(-[[operator, Operator_Name]
             [preconditions, Preconditions]
             [additions, Additions]
             [deletions, Deletions]]).   */

operator([[operator, [pick_up, X]],
         [preconditions, [on_table, X],[clear, X],[empty_hand]],
         [additions, [holding, X]],
         [deletions, [on_table, X],[clear, X],[empty_hand]]]).
operator([[operator, [put_down, X]],
         [preconditions, [holding, X]],
         [additions, [on_table, X],[clear, X],[empty_hand]],
         [deletions, [holding, X]]]).
operator([[operator, [stack, X, on, Y]],
         [preconditions, [holding, X],[clear, Y]],
         [additions, [on, X, Y],[clear, X],[empty_hand]],
         [deletions, [holding, X],[clear, Y]]]).
operator([[operator, [unstack, X, from, Y]],
         [preconditions, [on, X, Y],[clear, X],[empty_hand]],
         [additions, [holding, X],[clear, Y]],
         [deletions, [on, X, Y],[clear, X],[empty_hand]]]).

/* achieve2(+Goals, +Initial_state, +Depth, -Plan, -Final_state)
  achieve2 takes a list of Goals and an Initial state of the world
  and a Depth and succeeds with a Plan and a Final state of the world. */

achieve2([], Initial, _, [], Final) :-
   Initial = Final.
achieve2([Goal | Goals], Initial, Depth, Plan, Final) :-
   Depth > 0,
   member(Goal, Initial), !,
   achieve2(Goals, Initial, Depth, Plan1, Final1),
 ( allpresent([Goal | Goals], Final1), !,
   Final = Final1,
   Plan = Plan1
 ; New_depth is Depth -1,
   achieve2([Goal | Goals], Final1, New_depth, Plan2, Final2),
   append(Plan1, Plan2, Plan),
   Final = Final2 ).
achieve2([Goal | Goals], Initial, Depth, Plan, Final) :-
   Depth > 0,
   operator([[operator | Operator],
             [preconditions | Preconds],
             [additions | Adds],
             [deletions | Dels]]),
   member(Goal, Adds),
   New_depth is Depth - 1,
   achieve2(Preconds, Initial, New_depth, Pre_plan, Intermediate1),
   append(Pre_plan, Operator, Sub_plan),
   allremove(Dels, Intermediate1, Intermediate2),
   append(Adds, Intermediate2, Intermediate3),
   achieve2(Goals, Intermediate3, Depth, Plans, Final1),
   append(Sub_plan, Plans, Plan1),
 ( allpresent([Goal | Goals], Final1), !,
   Final = Final1,
   Plan = Plan1
 ; New_depth is Depth -1,
   achieve2([Goal | Goals], Final1, New_depth, Plan2, Final2),
   append(Plan1, Plan2, Plan),
   Final = Final2 ).

/* find_plan2(+Starting State, +Goal State, -Resultant Plan)
  find_plan2 succeeds if achieve2 succeeds with a depth limit of 5 */

find_plan2(Start_state, Goals, Plan) :-
   achieve2(Goals, Start_state, 5, Plan, _).

/* ------------------ PROGRAMS FROM CHAPTER 8 ------------------------- */

/* rule(-grammar_rule)
  each rule predicate has as its argument a list containing either a syntactic
  or lexical rule */

rule([s, np, vp]).
rule([np, snp]).
rule([np, snp, pp]).
rule([snp, det, noun]).
rule([pp, prep, snp]).
rule([vp, verb, np]).
rule([noun, man]).
rule([noun, flies]).
rule([noun, girl]).
rule([noun, plane]).
rule([noun, computer]).
rule([verb, hated]).
rule([verb, kissed]).
rule([verb, flies]).
rule([det, the]).
rule([det, a]).
rule([prep, with]).

/* backwards_parse_tree(+Goals, +Sequence, +Depth, -Remainder, -Trees)
  backwards_parse_tree takes a list of Goals and a sequence of words
  and returns the corresponding parse-trees and any words left unused at
  the end of the sequence */

backwards_parse_tree([], Rem, _, Rem, []).
backwards_parse_tree([Word | Goals], [Word | Words], Depth, Remainder,
                                                        [Word | Trees]) :-
   backwards_parse_tree(Goals, Words, Depth, Remainder, Trees), !.
backwards_parse_tree([Goal | Goals], Sequence, Depth, Remainder,
                                               [[Goal | Tree] | Trees]) :-
   Depth > 0,
   rule([Goal|Subgoals]),
   New_depth is Depth - 1,
   backwards_parse_tree(Subgoals, Sequence, New_depth, Intermediate, Tree),
   backwards_parse_tree(Goals, Intermediate, Depth, Remainder, Trees).

/* forwards_parse_goals(+Goals, +Sequence, +Depth)
  forwards_parse_goals takes a sequence of words and succeeds if it can
  reduce this sequence to the given Goals by repeatedly replacing
  subsequences using the grammar rules */

forwards_parse_goals(Goals, Goals, _) :- !.
forwards_parse_goals(Goals, Sequence, Depth) :-
  Depth > 0,
  rule([Cat | Subcats]),
  sublist(Start, Subcats, Rest, Sequence),
  replace(Start, [Cat], Rest, Intermediate),
  New_depth is Depth - 1,
  forwards_parse_goals(Goals, Intermediate, New_depth).

/* sublist(-Start, +Subcats, -Rest, +Description)
  sublist isolates Subcats within Description and returns the words
  preceding and following it */

sublist(Start, Subcats, Rest, Description) :-
  append(L2, Rest, Description),
  append(Start, Subcats, L2).

/* replace(+Start, +Replacement, +Rest, -Description)
  replace links Start, Replacement and Rest into a single list which it
  returns in Description */

replace(Start, Replacement, Rest, Description) :-
  append(Start, Replacement, L2),
  append(L2, Rest, Description).

/* forwards_parse_trees(+Goals, +Sequence, +Depth, Trees)
  forwards_parse_goals takes a sequence of words and succeeds with Trees
  if it can reduce this sequence to the given Goals by repeatedly replacing
  subsequences by pieces of tree using the grammar rules */

forwards_parse_trees(Goals, Sequence, _, Trees) :-
  topcats(Sequence, Goals), !,
  Sequence = Trees.
forwards_parse_trees(Goals, Sequence, Depth, Trees) :-
  Depth > 0,
  rule([Cat | Subcats]),
  sublist(Start, Subtrees, Rest, Sequence),
  topcats(Subtrees, Subcats),
  replace(Start, [[Cat | Subtrees]], Rest, Intermediate),
  New_depth is Depth - 1,
  forwards_parse_trees(Goals, Intermediate, New_depth, Trees).

/* topcats(+Trees, +Cats)
  topcats succeeds if Trees and Cats are both flat lists equal.
  It also succeeds if Trees is a list of trees and Cats is a list
  of the major categories of these trees. */

topcats([], []).
topcats([Word | Trees], [Word | Cats]) :-
  topcats(Trees, Cats).
topcats([[Cat | _] | Trees], [Cat | Cats]) :-
  topcats(Trees, Cats).

/* fact(Relation, Value, Object_name) */

fact(isa, block, objR).              fact(colour, red, objR).
fact(size, large, objR).             fact(isa, block, objr).
fact(colour, red, objr).             fact(size, small, objr).
fact(isa, block, objG).              fact(colour, green, objG).
fact(size, large, objG).             fact(isa, block, objg).
fact(colour, green, objg).           fact(size, small, objg).
fact(isa, block, objB).              fact(colour, blue, objB).
fact(size, large, objB).             fact(isa, block, objb).
fact(colour, blue, objb).            fact(size, small, objb).
fact(objb, ison, objG).              fact(objG, ison, objR).
fact(objR, ison, table).             fact(objg, ison, table).
fact(objr, ison, objB).              fact(objB, ison, table).

/* meaning(+Tree, -Meaning, -Variable)
  meaning takes a parse-tree and succeeds with a meaning containing match
  patterns and the variable used in the match patterns.  The meaning
  consists of either where(f1, f2...fn) or what(f1, f2...fn) where f1...fn
  are match patterns based on fact(<relation>, <value>, X) and X is the
  match variable. */

meaning([noun, Word], fact(isa, Word, X), X).
meaning([adj, Word], fact(_, Word, X), X).
meaning([snp, Noun], Meaning, X) :-
  meaning(Noun, Meaning, X).
meaning([ap, Adj], Meaning, X) :-
  meaning(Adj, Meaning, X).
meaning([ap, Adj, Ap], (M1, M2), X) :-
  meaning(Adj, M1, X),
  meaning(Ap, M2, X).
meaning([snp, Ap, Noun], (M1, M2), X) :-
  meaning(Ap, M1, X),
  meaning(Noun, M2, X).
meaning([np, [det, _], Snp], Meaning, X) :-
  meaning(Snp, Meaning, X).
meaning([pp, [prep, _], Np], Meaning, X) :-
  meaning(Np, Meaning, X).
meaning([s, [wh1, where], [vbe, is], Np], where(Meaning), X) :-
  meaning(Np, Meaning, X).
meaning([s, [wh2, what], [vbe, is], Pp], what(Meaning), X) :-
  meaning(Pp, Meaning, X).
meaning(_, [], _).

/* rule(+grammar_rule) */

rule([s, v, np, pp]).            rule([s, wh1, vbe, np]).
rule([s, wh2, vbe, pp]).         rule([np, pn]).
rule([np, det, snp]).            rule([np, det, snp, pp]).
rule([snp, noun]).               rule([snp, ap, noun]).
rule([ap, adj]).                 rule([ap, adj, ap]).
rule([pp, prep, np]).            rule([noun, block]).
rule([noun, box]).               rule([noun, table]).
rule([noun, one]).               rule([wh1, where]).
rule([wh2, what]).               rule([pn, it]).
rule([v, put]).                  rule([v, move]).
rule([v, pickup]).               rule([v, putdown]).
rule([vbe, is]).                 rule([adj, white]).
rule([adj, red]).                rule([adj, blue]).
rule([adj, green]).              rule([adj, big]).
rule([adj, small]).              rule([adj, large]).
rule([adj, little]).             rule([prep, over]).
rule([prep, to]).                rule([prep, on]).
rule([prep, onto]).              rule([prep, in]).
rule([prep, at]).                rule([prep, under]).
rule([prep, above]).             rule([prep, by]).
rule([det, each]).               rule([det, every]).
rule([det, the]).                rule([det, a]).
rule([det, some]).
:- library(readline).

/* converse drives the program. */

converse :-
  write('Hello'), nl,
  one_line(Input),
  possibly_more(Input).

/* one_line(-Input)

  one_line reads in and deals with a line from the user. */
one_line(Input) :-
  readline(Input),
  analyse(Input).

/* possibly_more(+Input)

  possibly_more enables further input to be collected. */
possibly_more([bye]) :-
  write('Bye'), nl.
possibly_more(_) :-
  one_line(Input),
  possibly_more(Input).

/* analyse(+Input)
  analyse parses, extracts the meaning from and responds to
  the user's input. */

analyse([bye]).
analyse(Sentence) :-
  backwards_parse_tree([s], Sentence, 30, Extra, [Tree]),
  maybe_write(Extra),
  meaning(Tree, Meaning, X),
  process_meaning(Meaning, X), !.
analyse(Sentence) :-
  write('cannot parse sentence'), nl.

/* maybe_write(+Input)

  maybe_write writes any extra words of input. */
maybe_write([]).
maybe_write(Extra) :-
  write(Extra),
  write(' has been ignored'), nl.

/* process_meaning(+Meaning, +Pattern variable))
  process_meaning takes a meaning structure containing patterns
  and a pattern variable and deals with it. */

process_meaning([], _) :-
  write('that does not make sense'), nl.
process_meaning(where(Patterns), X) :-
  bagof(X, Patterns, Objects), !,
  where_is(Objects).
process_meaning(what(Patterns), X) :-
  bagof(X, Patterns, Objects), !,
  what_is_on(Objects).
process_meaning(_, _) :-
  write('no block matches that description'), nl.

/* where_is(+Object)
  where_is takes an object and answers the where question. */

where_is([Object]) :-
  fact(Object, ison, Site), !,
  write('on top of '),
  write(Site), nl.
where_is([Object]) :-
  write(Object),
  write(' is not on top of anything'), nl.
where_is([_ | _]) :-
  write('more than one block matches that description'), nl.

/* what_is_on(+Object)
  what_is_on takes an object and answers the what is on question. */

what_is_on([Object]) :-
  (fact(Cover, ison, Object) ; Cover = nothing),
  write(Cover),
  write(' is on top of '),
  write(Object), nl.
what_is_on([_ | _]) :-
  write('more than one block matches that description'), nl.

/* ------------------ PROGRAMS FROM CHAPTER 9 ------------------------- */

/* rule(+Rule)
  rule([<Successor>, <Certainty>, <Predecessor(s)>]) */

rule([[season, winter], 1, [month, december]]).
rule([[season, winter], 1, [month, january]]).
rule([[season, winter], 0.9, [month, february]]).
rule([[season, spring], 0.7, [month, march]]).
rule([[season, spring], 0.9, [month, april]]).
rule([[season, spring], 0.6, [month, may]]).
rule([[season, summer], 0.8, [month, june]]).
rule([[season, summer], 1, [month, july]]).
rule([[season, summer], 1, [month, august]]).
rule([[season, autumn], 0.8, [month, september]]).
rule([[season, autumn], 0.7, [month, october]]).
rule([[season, autumn], 0.6, [month, november]]).
rule([[pressure, high], 0.6,
      [weather_yesterday, good], [stability_of_the_weather, stable]]).
rule([[pressure, high], 0.9, [clouds, high]]).
rule([[pressure, high], 0.9, [clouds, none]]).
rule([[temp, cold], 0.9, [season, winter], [pressure, high]]).
rule([[temp, cold], 0.6, [season, summer], [pressure, low]]).
rule([[wind, none], 0.3, [pressure, high]]).
rule([[wind, east], 0.3, [pressure, high]]).
rule([[wind, west], 0.6, [pressure, low]]).
rule([[temp, warm], 0.8, [wind, south]]).
rule([[temp, cold], 0.9,
      [wind, east], [clouds, none], [season, winter]]).
rule([[temp, warm], 0.9,
      [wind, none], [pressure, high], [season, summer]]).
rule([[rain, yes], 0.4, [whereabouts, west]]).
rule([[temp, cold], 0.4, [whereabouts, north]]).
rule([[rain, no], 0.7, [whereabouts, east]]).
rule([[rain, yes], 0.3, [season, spring], [clouds, low]]).
rule([[rain, yes], 0.3, [season, spring], [clouds, high]]).
rule([[temp, warm], 0.7, [season, summer]]).
rule([[rain, yes], 0.2, [season, summer], [temp, warm]]).
rule([[rain, yes], 0.6, [pressure, low]]).
rule([[rain, yes], 0.6, [wind, west]]).
rule([[rain, yes], 0.8, [clouds, low]]).
rule([[temp, cold], 0.8, [season, autumn], [clouds, none]]).
rule([[temp, cold], 0.7, [season, winter]]).

/* backwards_search_tree(+Goals, -Trees).
  backwards_search_tree takes a list of goals and constructs a list of
  search trees. Where no rule can be found the user is asked about the goal.
  The first solution found for each goal is returned. */

backwards_search_tree([], []).
backwards_search_tree([Goal | Goals], [[Goal | Tree] | Trees]) :-
   rule([Goal, Certainty | Subgoals]),
   backwards_search_tree(Subgoals, Tree),
   backwards_search_tree(Goals, Trees).
backwards_search_tree([Goal | Goals],
                           [[Goal, 'USER_RESPONSE'] | Trees]) :-
   yesno(Goal, [yes]),
   backwards_search_tree(Goals, Trees).

/* yesno(+Goal, ?Answer)
  yesno prints a question constructed from the Goal and returns the user's
  answer or matches it against the desired answer. */

:- library(readline).

yesno([Property, Value], Answer) :-
   write('is '),
   write(Value),
   write(' the value of '),
   write(Property), nl,
   readline(Answer).

/* backwards_search_value(+Goals, -Certainty).
  backwards_search_value takes a list of goals and returns the certainty
  of them all being true based on taking the minimum of the certainties
  of a set of goals as the certainty of the set. */

backwards_search_value([], 1).
backwards_search_value([Goal | Goals], Certainty) :-
   rule([Goal, C | Subgoals]),
   backwards_search_value(Subgoals, C1),
   backwards_search_value(Goals, C2),
   C_here is C * C1,
   min(C_here, C2, Certainty).
backwards_search_value([Goal | Goals], C2) :-
   yesno(Goal, [yes]),
   backwards_search_value(Goals, C2).

/* min(+X, +Y, -Z).
  min returns in Z the minimum of X and Y */

min(X, Y, X) :-
   X =< Y, !.
min(X, Y, Y).

/* backwards_search_values(+Goals, -Certainty).
  backwards_search_values takes a list of goals and computes the overall
  certainty that the goals are all true via all possible paths.  paths which
  fail reduce the overall certainty. */

backwards_search_values([], 1).
backwards_search_values([Goal | Goals], Certainty) :-
   bagof([C | Subgoals], rule([Goal, C | Subgoals]), List),
   backwards_search_or(List, C1),
   backwards_search_values(Goals, C2),
   min(C1, C2, Certainty).
backwards_search_values([Goal | Goals], Certainty) :-
   yesno(Goal, Answer),
   augment(Goal, Answer, C1),
   backwards_search_values(Goals, C2),
   min(C1, C2, Certainty).

/* backwards_search_or(+Bag_of_subgoals, -Certainty)
  backwards_search_or takes a bag of alternative subgoals each associated
  with a certainty and computes the combined certainty of the set. */

backwards_search_or([], 0).
backwards_search_or([[C | Subgoals] | Others], Certainty) :-
   backwards_search_values(Subgoals, C1),
   backwards_search_or(Others, C2),
   C_here is C * C1,
   combine(C_here, C2, Certainty).

/* combine(+C1, +C2, -Certainty)
  combine computes certainty from C1 and C2 as for an OR node. */

combine(C1, C2, Certainty) :-
   C1 >= 0, C2 >= 0, !,
   Certainty is C1 + C2 - (C1 * C2).
combine(C1, C2, Certainty) :-
   C1 < 0, C2 < 0, !,
   Certainty is C1 + C2 + (C1 * C2).
combine(C1, C2, 0) :-
   abs(C1, C11),  abs(C2, C22),
   min(C11, C22, 1), !.
combine(C1, C2, Certainty) :-
   abs(C1, C11),  abs(C2, C22),
   min(C11, C22, C3),
   Certainty is (C1 + C2)/(1 - C3).

/* augment(+Goal, +Answer, -Value)
  augment returns the numerical value of answer and also adds the goal
  with its numerical value to the database.  The new database entries
  are similar in form to existing rules, except that they have no
  subgoals. */

augment(Goal, [yes], 1) :-
   asserta(rule([Goal, 1])).
augment(Goal, [no], -1) :-
   asserta(rule([Goal, -1])).

/* ------------------ PROGRAMS FROM CHAPTER 10 ------------------------- */

/* isa(?Colour, ?Shape) */

isa(colour, uniform).
isa(colour, striped).
isa(uniform, primary).
isa(uniform, pastel).
isa(primary, red).
isa(primary, blue).
isa(primary, yellow).
isa(pastel, pink).
isa(pastel, green).
isa(pastel, grey).
isa(shape, block).
isa(shape, sphere).
isa(block, brick).
isa(block, wedge).
isa(brick, cube).
isa(brick, cuboid).

/* generalise(+Description, +Positive example, -New higher description)
  generalise succeeds if the higher description covers both the
  original description and the positive example. */

generalise(Description, Pos_example, Higher_description) :-
   covers(Higher_description, Description),
   covers(Higher_description, Pos_example).

/* specialise(+Description, +Negative example, -New lower description)
  specialise succeeds if the lower description is covered by the
  original description but excludes the negative example. */

specialise(Description, Neg_example, Lower_description) :-
   covers(Description, Lower_description),
   not(covers(Lower_description, Neg_example)).

/* covers(?Description1, ?Description2)
  covers succeeds if Description1 covers Description2. */

covers([Colour_high, Shape_high], [Colour_low, Shape_low]) :-
   ancestor(Colour_high, Colour_low),
   ancestor(Shape_high, Shape_low).

/* ancestor(?Ancestor, ?Child)
  ancestor succeeds if Ancestor is above Child in the isa hierarchy. */

ancestor(Ancestor, Ancestor).
ancestor(Ancestor, Child) :-
   nonvar(Child), !,
   isa(Intermediate, Child),        /* SEARCH UP THE HIERARCHY */
   ancestor(Ancestor, Intermediate).
ancestor(Ancestor, Child) :-
   nonvar(Ancestor),
   isa(Ancestor, Intermediate),     /* SEARCH DOWN THE HIERARCHY */
   ancestor(Intermediate, Child).

/* tip(?Word)
  tip succeeds if Word is at the tip of the isa hierarchy. */

tip(X) :- isa(_, X), not(isa(X, _)).

/* dealwith(+Value, +Description, +General, +Special)
  dealwith takes a description plus its value plus the current most
  general and most special lists and processes them. */

dealwith(neg, Description, General, Special) :-
  specialise(General, Description, NewGeneral),
  above(NewGeneral, Special),
  learn1(NewGeneral, Special).
dealwith(pos, Description, General, []) :-
  learn1(General, Description).
dealwith(pos, Description, General, Special) :-
  generalise(Special, Description, NewSpecial),
  above(General, NewSpecial),
  learn1(General, NewSpecial).
dealwith(_, Description, General, Special) :-
  write(Description),
  write(' is inconsistent and ignored.'), nl,
  learn1(General, Special).

/* learn1(+General, +Special)
  learn1 takes the most general and most specific descriptions so
  far and exits if they are the same, otherwise it recursively gets
  a new example for the next cycle. */

learn1(C, C) :-
   write('The concept is '),
   write(C), nl.
learn1(General, Special) :-
   write('Most general concept is '),
   write(General), nl,
   write('Most special concept is '),
   write(Special), nl, nl,
   getexample(Value, Description),
   dealwith(Value, Description, General, Special).

/* learn drives the learning program. */

learn :- learn1([colour, shape], []).

/* above(+Description1, +Description2)
  above succeeds if Description1 covers Description2 as well as if
  Description2 is the empty list. */

above(_, []).
above(High, Low) :-
   covers(High, Low).

/* getexample(-Value, -Description)
  getexample gets a Description and a Value from the user. */

getexample(Value, Description) :-
  repeat,                           /* TO ALLOW FOR INPUT ERRORS */
  askfor(Value, Description).

/* askfor(-Value, -Description)
  askfor gets a Description and a Value from the user. */

askfor(Value, [Colour, Shape]) :-
  write('Type in a primitive description e.g. red cube'),
  readline([Colour, Shape]),
  tip(Colour),
  tip(Shape),
  yesno(Value).

/* yesno(-Value)
  yesno provides the Value. */

:- library(readline).

yesno(pos) :-
  write('Is it positive? yes./no. '),
  readline([yes]), !.
yesno(neg).

/*  --- Revision History ---------------------------------------------------
 */
