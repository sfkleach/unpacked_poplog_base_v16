/* --- Copyright Chris Thornton and Benedict du Boulay 1992.  All rights reserved. ---------
 > File:           progall.p
 > Purpose:        POP-11 code from book - below
 > Author:         Chris Thornton & Benedict du Boulay
 > Documentation:  AI Through Search, Oxford: Intellect, 1992.
 > Related Files:  progall.pl
 > Version: 1.0
 */

/* ------------------ PROGRAMS FROM CHAPTER 2 ------------------------- */

  vars brighton is_goal successors simple_search_tree;

  [[seven_dials preston_circus]
   [seven_dials station]
   [seven_dials west_pier]
   [preston_circus seven_dials]
   [preston_circus the_level]
   [preston_circus the_parallels]
   [the_level preston_circus]
   [the_level the_parallels]
   [the_level old_steine]
   [old_steine the_level]
   [old_steine the_parallels]
   [old_steine palace_pier]
   [palace_pier old_steine]
   [palace_pier west_pier]
   [palace_pier clocktower]
   [west_pier palace_pier]
   [west_pier clocktower]
   [west_pier seven_dials]
   [station seven_dials]
   [station clocktower]
   [the_parallels preston_circus]
   [the_parallels the_level]
   [the_parallels old_steine]
   [the_parallels clocktower]
   [clocktower station]
   [clocktower the_parallels]
   [clocktower palace_pier]
   [clocktower west_pier]] -> brighton;

   vars toytown;

   [[A B][A C][C F][B E][B D] [D X][E X][X Z][Z Y]] -> toytown;

/* successors1 takes a location and returns a list
   of the places directly linked to it. */

define successors1(location) -> result;
   vars successor;
   [^( foreach [^location ?successor] do successor endforeach)]
   -> result
enddefine;

/* search takes the current location and the goal location and returns
   true if a path can be found to link them and false otherwise. */

define search(current_location, goal) -> boolean;
   vars successor;
   if is_goal(current_location, goal) then
      true -> boolean
   else
      for successor in successors(current_location) do
         if search(successor, goal) then
            true -> boolean; return
         endif
      endfor;
      false -> boolean
   endif;
enddefine;

define is_goal(location, goal) -> boolean;
   location matches goal -> boolean
enddefine;

/* search_path takes a path so far and a goal and returns a solution
   path that links them or false if no path can be found. */

define search_path(path_so_far, goal) -> solution_path;
   vars current_location, successor;
   last(path_so_far) -> current_location;
   if is_goal(current_location, goal) then
      path_so_far -> solution_path
   else
      for successor in successors(current_location) do
         unless member(successor, path_so_far) then
            search_path([^^path_so_far ^successor], goal)
            -> solution_path;
            if islist(solution_path) then return endif
         endunless
      endfor;
      false -> solution_path;
   endif;
enddefine;

vars toytown;

[[A B][A C][C F][B E][B D] [D X][E X][X Z][Z Y]] -> toytown;

/* search tree takes a path so far and a goal and returns the
   corresponding search tree. */

define search_tree(path_so_far, goal) -> tree;
   vars successor, subtree, current_location;
   last(path_so_far) -> current_location;
   [^current_location] -> tree;
   unless is_goal(current_location, goal) then
      for successor in successors(current_location) do
          unless member(successor, path_so_far)
          then search_tree([^^path_so_far ^successor], goal)
               -> subtree;
               [^^tree ^subtree] -> tree
          endunless
      endfor
   endunless
enddefine;

/* search_tree_no_dups takes a location and a goal and returns
   the corresponding search tree without duplicates. */

define search_tree_no_dups(current_location, goal) -> tree;
   vars visited;
   [] -> visited;
   simple_search_tree(current_location, goal) -> tree
enddefine;

define simple_search_tree(current_location, goal) -> tree;
   vars successor, subtree;
   [^current_location ^^visited] -> visited;   /* SIDE EFFECT */
   [^current_location] -> tree;
   unless is_goal(current_location, goal) then
      for successor in successors(current_location) do
          unless member(successor, visited) then
             simple_search_tree(successor, goal) -> subtree;
             [^^tree ^subtree] -> tree
          endunless
      endfor
   endunless
enddefine;


/* ------------------ PROGRAMS FROM CHAPTER 3 ------------------------- */

/* successors2 takes a state and returns a list of successor states. */

define successors2(state) -> result;
   vars X Y;
   state --> [?X ?Y];
   [[^X 0] [0 ^Y]] -> result;
enddefine;

/* successors3 takes a state and returns a list of successor states. */

define successors3(state) -> result;
   vars X Y result;
   state --> [?X ?Y];
   [^(
      /* FILL X COMPLETELY FROM Y WITH SOME LEFT OVER */
         if Y /= 0 and X /= 4 and X+Y > 4 then [4 ^(X+Y-4)] endif;
      /* EMPTY Y COMPLETELY INTO X */
         if Y /= 0 and X /= 4 and X+Y =< 4 then [^(X+Y) 0] endif;
      /* FILL Y COMPLETELY FROM X WITH SOME LEFT OVER */
         if Y /= 3 and X /= 0 and X+Y > 3 then [^(X+Y-3) 3] endif;
      /* EMPTY X COMPLETELY INTO Y */
         if Y /= 3 and X /= 0 and X+Y =< 3 then [0 ^(X+Y)] endif;
      /* EMPTY OUT X */
         if X /= 0 then [0 ^Y] endif;
      /* EMPTY OUT Y */
         if Y /= 0 then [^X 0] endif;
      /* FILL X UP FROM THE TAP */
         if X /= 4 then [4 ^Y] endif;
      /* FILL Y UP FROM THE TAP */
         if Y /= 3 then [^X 3] endif;
      )] -> result;
enddefine;

/* limited_search_tree takes a path so far, a goal and a depth and returns
   the corresponding search tree within given depth limit. */

define limited_search_tree(path_so_far, goal, depth) -> tree;
   vars successor, subtree, current_location;
   last(path_so_far) -> current_location;
   [^current_location] -> tree;
   unless is_goal(current_location, goal) or depth =< 0 then
      for successor in successors(current_location) do
          unless member(successor, path_so_far)
          then limited_search_tree([^^path_so_far ^successor], goal,
                                                depth-1) -> subtree;
               [^^tree ^subtree] -> tree
          endunless
      endfor
   endunless
enddefine;

vars chatty extend_agenda;

/* agenda_search takes an initial state, a goal, a word denoting a
   search method and a depth limit. It returns a path from the initial
   state to the goal using the specified search method.  If no path can
   be found it returns false. */

define agenda_search(initial_state, goal, search_type, depth) -> path;
   vars agenda paths visited;
   [ [^initial_state] ] -> agenda;
   [] -> visited;
   until agenda = [] do
      agenda --> [?path ??paths];
      if chatty then pr(length(agenda)); sp(1); pr(rev(path)); nl(1)
      endif;
      if is_goal(hd(path), goal)
      then rev(path) -> path; return
      elseif length(path) > depth then paths -> agenda
      else [^path ^^visited] -> visited;
           extend_agenda(paths, path, search_type) -> agenda;
      endif;
   enduntil;
   false -> path;
enddefine;

/* new_paths takes a path and uses the successor function to return a
   list of all extended paths which exclude duplicated nodes. */

define new_paths(path) -> extended_paths;
    vars state;
    [^( for state in successors(hd(path)) do
            unless member(state, path)
            then [^state ^^path]
            endunless
        endfor
      )] -> extended_paths
enddefine;

/* extend_agenda1 takes an agenda of paths, a path and a search method
   and returns a new agenda that incorporates the new extended paths. */

define extend_agenda1(agenda, path, search_type) -> new_agenda;
    vars extended_paths;
    new_paths(path) -> extended_paths;
    if search_type = "breadth"
    then [^^agenda ^^extended_paths] -> new_agenda
    elseif search_type = "depth"
    then [^^extended_paths ^^agenda] -> new_agenda
    endif
enddefine;

/* iterative deepening takes an initial state, a goal and a maximum depth
   and repeatedly calls agenda_search in depth-first mode with an ever
   increasing depth bound. It returns the solution path or false. */

define iterative_deepening_search(initial_state, goal, maxdepth) -> path;
    vars depth;
    for depth from 1 to maxdepth do
        agenda_search(initial_state, goal, "depth", depth) -> path;
        if path then return endif;
    endfor
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 4 ------------------------- */

/* up takes a state and returns the state corresponding to moving a
   tile up or false if it cannot be moved. */

define up(node) -> new;
   vars a b c d x;
   if node matches [??a hole ?b ?c ?x ??d]
   then [^^a ^x ^b ^c hole ^^d] -> new
   else false -> new;
   endif;
enddefine;

/* down takes a state and returns the state corresponding to moving a
   tile down or false if it cannot be moved. */

define down(node) -> new;
   vars a b c d x;
   if node matches [??a ?x ?b ?c hole ??d]
   then [^^a hole ^b ^c ^x ^^d] -> new
   else false -> new
   endif;
enddefine;

/* exchange takes a state and returns a new state with the rows and
   columns exchanged. */

define exchange(node) -> new_node;
   vars a b c d e f g h i;
   node --> [?a ?b ?c ?d ?e ?f ?g ?h ?i];
   [^a ^d ^g ^b ^e ^h ^c ^f ^i] -> new_node
enddefine;

/* successors4 takes a state and returns a list of the successor states. */

define successors4(node) -> result;
   vars move turned;
   [^(
      down(node) -> move; if move then move endif;
      up(node) -> move; if move then move endif;
      exchange(node) -> turned;
      down(turned) -> move; if move then exchange(move) endif;
      up(turned) -> move; if move then exchange(move) endif;
     )] -> result
enddefine;

/* columndist takes tile value and a position and computes how many
   columns away it is from its home column. */

define columndist(tile,pos) -> dist;
   abs(((tile - 1) mod 3) - ((pos - 1) mod 3)) -> dist
enddefine;

/* rowdist takes tile value and a position and computes how many rows
   away it is from its home row. */

define rowdist(tile,pos) -> dist;
   abs(((tile - 1) div 3) - ((pos - 1) div 3)) -> dist
enddefine;

/* distance_to_goal takes a state and computes the minimum number of
   moves to get all the tiles in their goal positions. */

/* NOTE: there is another function with the same name in CHAPTER 5 */

define distance_to_goal(node) -> num;
    vars tile;
    0 -> num;
    for pos from 1 to 9 do
        node(pos) -> tile;
        unless tile = "hole"
        then num + columndist(tile,pos) + rowdist(tile,pos) -> num;
        endunless;
    endfor;
enddefine;

/* closeness_to_goal takes a state and computes numerically how close
   it is to the goal state, with 100 the arbitrary maximum possible value. */

define closeness_to_goal(node) -> value;
   100 - distance_to_goal(node) -> value
enddefine;

/* closer_to_goal takes two states and returns true if the first is
   nearer to the goal than the second. */

define closer_to_goal(node1, node2) -> boolean;
   closeness_to_goal(node1) > closeness_to_goal(node2) -> boolean
enddefine;

/* heuristic_search uses the recursion stack to give backtracking hill
   climbing search. It takes a path so far and a goal and returns a
   solution path. */

define heuristic_search(path_so_far, goal) -> path;
   vars current_node, path, successor;
   hd(path_so_far) -> current_node;
   if is_goal(current_node, goal) then
      rev(path_so_far) -> path
   else
      for successor in syssort(successors(current_node),
                                                 closer_to_goal) do
         unless member(successor, path_so_far) or
                closer_to_goal(current_node, successor)
         then heuristic_search([^successor ^^path_so_far], goal)
              -> path;
              if islist(path) then return endif
         endunless
      endfor;
      false -> path;
   endif;
enddefine;

/* better_path_h takes two paths and returns true if the final state of
   the first path is closer to or as close to the goal than the final state
   of the second path. */

define better_path_h(path1, path2);
   closeness_to_goal(hd(path1)) >= closeness_to_goal(hd(path2))
enddefine;

/* extend_agenda2 takes an agenda of paths, a path and a search method
   and returns a new agenda that incorporates the new extended paths. */

define extend_agenda2(agenda, path, search_type) -> new_agenda;
    vars extended_paths;
    new_paths(path) -> extended_paths;
    if search_type = "breadth"
    then [^^agenda ^^extended_paths] -> new_agenda
    elseif search_type = "depth"
    then [^^extended_paths ^^agenda] -> new_agenda
    elseif search_type = "hill_climbing"
    then syssort(extended_paths, better_path_h) -> extended_paths;
         if extended_paths = [] or
            better_path_h(path, hd(extended_paths))
         then [] -> new_agenda
         else [^(hd(extended_paths))] -> new_agenda
         endif
    elseif search_type = "best_first"
    then syssort([^^agenda ^^extended_paths], better_path_h)
         -> new_agenda
    endif
enddefine;

/* beam_search takes an initial state, a goal, a maximum depth and a
   beam-width and returns a solution path or false.  With chatty on
   it displays its agenda (not the current path) at each outer cycle. */

define beam_search(initial, goal, depth, beam_width) -> path;
    vars agenda layer state new_paths i;
    [ [^initial] ] -> agenda;
    until agenda = [] do
        if chatty then agenda ==> endif;
        agenda -> layer;
        [] -> agenda;
        until layer = [] do
            layer --> [?path ??layer];
            if is_goal(hd(path), goal) then rev(path) -> path; return
            elseif length(path) > depth then false -> path; return
            else
                extend_agenda(agenda, path, "best_first") -> agenda;
            endif;
        enduntil;
        if length(agenda) > beam_width
        then [^( for i from 1 to beam_width do agenda(i) endfor )]
             -> agenda
        endif;
    enduntil;
    false -> path;
enddefine;

/* better_path_g_h takes two paths and returns true if the first is estimated
   to cost less than the second if each were extended to reach the goal. */

define better_path_g_h(path1, path2) -> boolean;
   (length(path1) - 1 + distance_to_goal(hd(path1))) =<
   (length(path2) - 1 + distance_to_goal(hd(path2))) -> boolean
enddefine;

vars prune path_member;

/* This is extend agenda as before, but able to deal with A* search. */

define extend_agenda3(agenda, path, search_type) -> new_agenda;
    vars extended_paths;
    new_paths(path) -> extended_paths;
    if search_type = "breadth"
    then [^^agenda ^^extended_paths] -> new_agenda
    elseif search_type = "depth"
    then [^^extended_paths ^^agenda] -> new_agenda
    elseif search_type = "hill_climbing"
    then syssort(extended_paths, better_path_h) -> extended_paths;
         if extended_paths = [] or
            better_path_h(path, hd(extended_paths))
         then [] -> new_agenda
         else [^(hd(extended_paths))] -> new_agenda
         endif
    elseif search_type = "best_first"
    then syssort([^^agenda ^^extended_paths], better_path_h)
         -> new_agenda
    elseif search_type = "a_star"
    then prune(extended_paths) -> extended_paths;  /* side-effects! */
         syssort([^^agenda ^^extended_paths], better_path_g_h)
         -> new_agenda
    endif
enddefine;

/* prune takes a list of extended paths and checks each one to see
   whether it has been encountered before.  prune has _s_i_d_e-_e_f_f_e_c_t_s
   on the variables agenda in extend-agenda3 and visited in agenda_search. */

define prune(extended_paths) -> pruned_paths;
    vars new_path expanded_path unexpanded_path;
    [] -> pruned_paths;
    for new_path in extended_paths do
        path_member(new_path, visited) -> expanded_path;
        path_member(new_path, agenda) -> unexpanded_path;
        if not(expanded_path) and not(unexpanded_path)
        then [^^pruned_paths ^new_path] -> pruned_paths;
        elseif expanded_path and
               better_path_g_h(new_path, expanded_path)
        then delete(expanded_path, visited) -> visited;  /* ! */
             [^^pruned_paths ^new_path] -> pruned_paths;
        elseif unexpanded_path and
               better_path_g_h(new_path, unexpanded_path)
        then delete(unexpanded_path, agenda) -> agenda;  /* ! */
             [^^pruned_paths ^new_path] -> pruned_paths;
        endif
    endfor
enddefine;

/* path_member takes a path and a list of paths.  It returns in
   existing_path the first path it finds that has the same final
   node value as the given path.  If no such path can be found it
   returns false. */

define path_member(path, path_list) -> existing_path;
    for existing_path in path_list do
        if hd(path) matches hd(existing_path)
        then return
        endif
    endfor;
    false -> existing_path
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 5 ------------------------- */

/* distance_to_goal takes a node and computes how far it is from
   either the goal of having 2 or 3 sticks to deal with. */

/* NOTE: there is another function with the same name in CHAPTER 4 */

define distance_to_goal(node) -> distance;
   vars sticks;
   node --> [?sticks];
   if sticks = 2 or sticks = 3 then 0 -> distance /* PROGRAM WINS */
   elseif sticks = 1 then 9 -> distance          /* PROGRAM LOSES */
   else (sticks - 2) -> distance
   endif
enddefine;

/* static_value computes the heuristic worth of a node, scoring
   9 for the best and 0 for the worst, i.e. from MAX's viewpoint. */

define static_value(node) -> proximity;
   (9 - distance_to_goal(node)) -> proximity;
enddefine;

/* successors5 takes a node in nim and produces a list of successor nodes. */

define successors5(node) -> children;
   vars sticks;
   node --> [?sticks];
   if sticks = 1 then [] -> children
   elseif sticks = 2 then [[1]] -> children
   else [[^(sticks - 2)] [^(sticks - 1)]] -> children
   endif
enddefine;

/* MAXs_go returns true if depth is an even number. */

define MAXs_go(depth) -> boolean;
   (depth rem 2) = 0 -> boolean
enddefine;

/* minimax_search takes a node, a depth in the game tree and a
  lookahead value and returns its value.  If it is MAXs_go, the best
  successor node is the one with the highest value, otherwise it's
  the one with the lowest value. */

define minimax_search(node, depth, lookahead) -> value;
   vars successor next_value;
   if depth >= lookahead
   then static_value(node) -> value;
   else if MAXs_go(depth)
       then -1000 -> value
       else 1000 -> value
       endif;
       for successor in successors(node) do
           minimax_search(successor, depth + 1, lookahead)
               -> next_value;
           if MAXs_go(depth)
           then max(next_value, value) -> value
           else min(next_value, value) -> value
           endif
       endfor
   endif
enddefine;

/* minimax_search_tree takes a node, a depth value and a lookahead
  and returns the tree searched using minimaxing.  Leaf nodes
  in the tree contain the number of sticks together with a static
  value.  Other nodes contain the number of sticks together with
  the dynamic value. */

define minimax_search_tree(node, depth, lookahead) -> tree;
   vars successor value next_value subtree;
   if depth >= lookahead
   then [[^^node ^(static_value(node))]] -> tree
   else if MAXs_go(depth)
       then -1000 -> value
       else 1000 -> value
       endif;
       [] -> tree;
       for successor in successors(node) do
           minimax_search_tree(successor, depth + 1, lookahead)
               -> subtree;
           subtree(1)(2) -> next_value;
           if MAXs_go(depth)
           then max(next_value, value) -> value
           else min(next_value, value) -> value
           endif;
           [^^tree ^subtree] -> tree;
       endfor;
       [[^^node ^value] ^^tree] -> tree
   endif
enddefine;

/* alphabeta_search augments minimax_search by including lower
  and upper bounds as arguments.  The tree is pruned whenever
  the lower bound is equal or greater to the upper bound. It
  returns the value of the node it is given. */

define alphabeta_search(node, depth, lookahead, lower, upper)
                                                          -> value;
   vars successor;
   if depth >= lookahead
   then static_value(node) -> value;
   else if MAXs_go(depth)
       then lower -> value
       else upper -> value
       endif;
       for successor in successors(node) do
           alphabeta_search(successor, depth + 1, lookahead, lower,
               upper) -> value;
           if MAXs_go(depth)
           then max(value, lower) -> lower;
               lower -> value;
           else min(value, upper) -> upper;
               upper -> value;
           endif;
           if lower >= upper
           then if chatty then [pruning] ==> endif;
               quitloop
           endif
       endfor;
   endif
enddefine;

/* alphabeta_search_tree takes a node, a depth and a lookahead value
  and returns the search tree with subtrees pruned from it. */

define alphabeta_search_tree(node, depth, lookahead, lower, upper)
                                                           -> tree;
   vars successor value subtree;
   if depth >= lookahead
   then [[^^node ^(static_value(node))]] -> tree
   else if MAXs_go(depth)
       then lower -> value
       else upper -> value
       endif;
       [] -> tree;
       for successor in successors(node) do
           alphabeta_search_tree(successor, depth + 1, lookahead,
               lower, upper) -> subtree;
           subtree(1)(2) -> value;
           if MAXs_go(depth)
           then max(value, lower) -> lower;
               lower -> value;
           else min(value, upper) -> upper;
               upper -> value;
           endif;
           [^^tree ^subtree] -> tree;
           if lower >= upper
           then if chatty then [pruning] ==> endif;
               quitloop
           endif;
       endfor;
       [[^^node ^value] ^^tree] -> tree
   endif
enddefine;

/* nim returns either [you win] or [I win] or a close variant */

define nim -> result;
   vars node value successor best_move best_value;
   [nim program] ==>
   [how many sticks do I get?] ==>
   readline() -> node;
   if node = [] or not(isinteger(hd(node))) or hd(node) < 2
   then [illegal start, I win] -> result; return
   endif;
   repeat
       -2000 -> best_value;
       for successor in successors(node) do
           alphabeta_search(successor, 1, 4, -1000, 1000) -> value;
           if value > best_value
           then value -> best_value;
               successor -> best_move
           endif;
       endfor;
       [the number of sticks left after my move is ^(best_move(1))]
           ==>
       [please type in the number of sticks left after your move]
           ==>
       readline() -> node;
       if node = [1] then [you win] -> result; return endif;
       if node = [0] then [I win] -> result; return endif;
       unless member(node, successors(best_move))
       then [illegal move, I win] -> result; return
       endunless
   endrepeat;
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 6 ------------------------- */

vars rulebase remove_dups;

/* hanoi takes a description of a Tower of Hanoi state
  and returns the final description. */

define hanoi(goal) -> result;
  vars disc bottom_disc A B C A_name tower;
  if goal matches [[?disc ?A_name] ?B ?C]
  then [move ^disc from ^A_name to ^C] ==>
       [[^A_name] ^B [^disc ^^C]] -> result
  else goal --> [[??tower ?bottom_disc ?A_name] ?B ?C];
       hanoi([[^^tower ^A_name] ^C ^B]) --> [?A ?C ?B];
       hanoi([[^bottom_disc ^A_name] ^B ^C]) --> [?A ?B ?C];
       hanoi([^B ^A ^C]) --> [?B ?A ?C];
       [^A ^B ^C] -> result;
  endif
enddefine;

/* backwards_search1 takes a list of goals as input and returns true
  if they can all be solved, and false otherwise. */

define backwards_search1(goals) -> boolean;
  vars goal subgoals other_goals;
  if goals = [] then true -> boolean
  else goals --> [?goal ??other_goals];
       foreach [^goal ??subgoals] in rulebase do
            backwards_search1(subgoals) -> boolean;
            if boolean
            then backwards_search1(other_goals) -> boolean;
                 if boolean then return endif
            endif
       endforeach;
       false -> boolean;
  endif;
enddefine;

vars rulebase1 rulebase2 rulebase3 rulebase4 rulebase5;

  [/* FACTS */
   [[have paper]]
   [[have cash]]
   [[in house]]
   [[have phone]]
   /* RULES */
   [[have book][have cash][in store]]
   [[have book][have creditcard][have phone]]
   [[have book][have paper][have pen][have time]]
   [[have creditcard][have bankaccount]]
  ] -> rulebase1;

  [/* FACTS */
   [[have paper]]
   [[have cash]]
   [[in house]]
   [[have phone]]
   [[have creditcard]] /* NEW FACT ADDED */
   /* RULES */
   [[have book][have cash][in store]]
   [[have book][have creditcard][have phone]]
   [[have book][have paper][have pen][have time]]
   [[have creditcard][have bankaccount]]
  ] -> rulebase2;

  [/* FACTS */
   [[weak battery]]
   [[damp weather]]
   [[old car]]
   /* RULES */
   [[low current][damp weather][weak battery]]
   [[old starter][old car]]
   [[car wont start][low current][old starter]]
   [[write off][car wont start][not AA member]]
   [[not AA member][irresponsible]]
  ] -> rulebase3;

   [ /* FACTS */
     [[rich]]
     [[good job]]
     /* RULES */
     [[happy][rich][successful][loved]]
     [[successful][respected][rich]]
     [[loved][desirable]]
     [[desirable][successful][happy]]
     [[respected][good job]]
   ] -> rulebase4;

   [[[irresponsible]]
    [[weak battery]]
    [[damp weather]]
    [[old car]]
    [[low current] [damp weather] [weak battery]]
    [[low current] [headlights on] [cold weather]]
    [[old starter] [old car]]
    [[car wont start] [low current] [old starter]]
    [[write off] [car wont start] [not AA member]]
    [[not AA member] [irresponsible]]
   ] -> rulebase5;

/* backwards_search takes a list of goals as input and returns
  true if they can all be solved, and otherwise returns false. It
  checks for loops by ensuring that the search remains within a
  depth limit. */

define backwards_search(goals, depth) -> boolean;
  vars goal goal_list subgoals other_goals;
  if goals = [] then true -> boolean
  elseif depth <= 0 then  false -> boolean
  else goals --> [?goal ??other_goals];
       foreach [^goal ??subgoals] do
           backwards_search(subgoals, depth-1) -> boolean;
           if boolean
           then unless present([^goal]) then add([^goal]) endunless;
                backwards_search(other_goals, depth) -> boolean;
                if boolean then return endif
           endif
       endforeach;
       false -> boolean
  endif
enddefine;

/* prove takes a list of goals and rulebase and returns true if
  all the goals can be solved, and false otherwise.  It passes on
  a depth limit to backwards_search to avoid loops. */

define prove(goals, rulebase, depth) -> boolean;
  vars database;
  rulebase -> database;
  backwards_search(goals,depth) -> boolean
enddefine;

/* backwards_search_tree takes a list of goals as input and returns
  the solution AND tree for them if it exists, and otherwise returns
  false. */

define backwards_search_tree(goals, depth) -> tree;
   vars goal first_tree other_trees goal subgoals other_goals;
   if goals = [] then [] -> tree
   elseif depth <= 0 then false -> tree
   else goals --> [?goal ??other_goals];
       foreach [^goal ??subgoals] do
           backwards_search_tree(subgoals, depth-1) -> first_tree;
           if islist(first_tree)
           then unless present([^goal]) then add([^goal]) endunless;
               backwards_search_tree(other_goals, depth)
                   -> other_trees;
               if islist(other_trees)
               then [[^goal ^^first_tree] ^^other_trees] -> tree;
                   return
               endif
           endif
       endforeach;
       false -> tree;
   endif
enddefine;

/* proof_tree takes a single goal as input and returns its proof tree
  or false if there is none. */

define proof_tree(goal, rulebase, depth) -> tree;
  vars database;
  rulebase -> database;
  backwards_search_tree([^goal], depth) -> tree;
  if islist(tree) then hd(tree) -> tree endif
enddefine;

/* AO_search_tree takes a list of goals as input and returns
  the search AND/OR tree as output. */

define AO_search_tree(goals, depth) -> and_tree;
   vars goal sub_tree  subgoals and_tree or_tree item;
   if goals = [] then [[KNOWN]] -> and_tree
   elseif depth <= 0 then [[DEPTH LIMITED]] -> and_tree
   else [[AND]] -> and_tree;
       for goal in goals do
           if present([^goal ==])
           then [[OR]] -> or_tree;
               foreach [^goal ??subgoals] do
                   AO_search_tree(subgoals, depth-1) -> sub_tree;
                   [^^or_tree ^sub_tree] -> or_tree
               endforeach;
               if or_tree matches [[OR] ?item]
               then item -> or_tree
               endif;
           else [[UNKNOWN]] -> or_tree
           endif;
           [^^and_tree [^goal ^or_tree]] -> and_tree
       endfor;
       if and_tree matches [[AND] ?item] then item -> and_tree endif
   endif
enddefine;

/* successors6 takes a state consisting of a list of goals as input and
  returns a list of new states consisting of lists of subgoals
  derivable from the original goals with any duplications removed. */

define successors6(state) -> states;
   vars goal subgoals remainder;
   [] -> states;
   for goal in state do
       delete(goal, state) -> remainder;
       foreach [^goal ??subgoals] in rulebase do
           [^^states ^(remove_dups([^^subgoals ^^remainder]))]
               -> states
       endforeach
   endfor
enddefine;

/* remove_dups takes a list as input and returns a list with any
  duplicated elements removed. */

define remove_dups(list) -> newlist;
   if list = [] then [] -> newlist
   elseif member(hd(list), tl(list)) then remove_dups(tl(list))
           -> newlist
   else hd(list) :: remove_dups(tl(list)) -> newlist
   endif
enddefine;

/* forwards_search takes a list of facts as input and returns a
  list of all the facts that can be derived, including the originals. */

define forwards_search(facts) -> result;
  vars conclusion, conclusions;
  [] -> conclusions;
  foreach [?conclusion ^^facts] do
       [^^conclusions ^conclusion] -> conclusions
  endforeach;
  if conclusions = [] then
     facts -> result
  else
     forwards_search(conclusions) -> result
  endif
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 7 ------------------------- */

vars operators1 chatty_print operators achieve operators2;

[[  [operator stand_back]
    [preconditions [near box]]
    [additions [safe]]
    [deletions [near box]]]
[   [operator go_forward]
    [preconditions [safe]]
    [additions [near box]]
    [deletions [safe]]]
[   [operator light_firework_safely]
    [preconditions [near box][box open][have fire][firework out]]
    [additions [firework alight]]
    [deletions [firework out]]]
[   [operator open_box]
    [preconditions [near box][box closed]]
    [additions [box open]]
    [deletions [box closed]]]
[   [operator close_box]
    [preconditions [near box][box open]]
    [additions [box closed]]
    [deletions [box open]]]
[   [operator use_lighter]
    [preconditions [have lighter]]
    [additions [have fire]]
    [deletions]]
[   [operator strike_match]
    [preconditions [have matches]]
    [additions [have fire]]
    [deletions]]
[   [operator enjoy_firework]
    [preconditions [firework alight][box closed][safe]]
    [additions [happy]]
    [deletions ]] ] -> operators1;

define title(operator) -> header;
   operator --> [[operator ??header] = = =]
enddefine;

define preconditions(operator) -> preconds;
   operator --> [= [preconditions ??preconds] = =]
enddefine;

define additions(operator) -> adds;
   operator --> [= = [additions ??adds] =]
enddefine;

define deletions(operator) -> dels;
   operator --> [= = = [deletions ??dels]]
enddefine;

/* achieve1 takes a list of goals, a database and a depth limit and returns
  a plan consisting of a list of operator titles and the resultant database. */

define achieve1(goals, initial_state, depth) -> plan -> database;
   vars goal operator other_goals sub_plan rest_plan;
   initial_state -> database;
   if goals = [] then [] -> plan;
   elseif depth <= 0 then false -> plan;
   else chatty_print([attempting ^goals]);
       goals --> [?goal ??other_goals];
       if present(goal)
       then chatty_print([^goal is already true]);
           achieve1(other_goals, initial_state, depth)
               -> plan -> database;
       else
           for operator in operators do
               if member(goal, additions(operator))
               then chatty_print([trying ^(title(operator))]);
                   achieve1(preconditions(operator), initial_state,
                       depth-1) -> sub_plan -> database;
                   if islist(sub_plan)
                   then allremove(deletions(operator));
                       alladd(additions(operator));
                       chatty_print([state now is ^^database]);
                       achieve1(other_goals, database, depth)
                           -> rest_plan -> database;
                       if islist(rest_plan)
                       then
                         [^^sub_plan ^(title(operator)) ^^rest_plan]
                               -> plan; quitloop
                       else chatty_print([backtracking]);
                       endif
                   else chatty_print([backtracking]);
                   endif;
               endif
           endfor
       endif;
       unless allpresent(goals) then
           false -> plan; initial_state -> database
       endunless
   endif
enddefine;

/* find_plan takes an initial state and a list of goals and returns a plan
  or false.  It sets an arbitrary depth limit of 10 on achieve1. */

define find_plan(initial_state, goals) -> plan;
   vars final_state;
   achieve(goals, initial_state, 10) -> plan -> final_state;
enddefine;

/* chatty_print prints its argument if chatty is true */

define chatty_print(comment);
   if chatty then comment ==> endif
enddefine;

/* achieve2 takes a list of goals as input and returns a plan consisting of
  a list of operator titles.  If the initial plan does not achieve all the
  goals, because of an interaction, a repair is added onto the end of the plan. */

define achieve2(goals, initial_state, depth) -> plan -> database;
   vars goal operator other_goals sub_plan rest_plan repair;
   initial_state -> database;
   if goals = [] then [] -> plan;
   elseif depth <= 0 then false -> plan;
   else chatty_print([attempting ^goals]);
       goals --> [?goal ??other_goals];
       if present(goal)
       then chatty_print([^goal is already true]);
           achieve2(other_goals, initial_state, depth)
               -> plan -> database;
       else
           for operator in operators do
               if member(goal, additions(operator))
               then chatty_print([trying ^(title(operator))]);
                   achieve2(preconditions(operator), initial_state,
                       depth-1) -> sub_plan -> database;
                   if islist(sub_plan)
                   then allremove(deletions(operator));
                       alladd(additions(operator));
                       chatty_print([state now is ^^database]);
                       achieve2(other_goals, database, depth)
                           -> rest_plan -> database;
                       if islist(rest_plan)
                       then
                         [^^sub_plan ^(title(operator)) ^^rest_plan]
                               -> plan;
                           quitloop
                       else chatty_print([backtracking]);
                       endif
                   else chatty_print([backtracking]);
                   endif;
               endif
           endfor
       endif;
       unless allpresent(goals) then
           chatty_print([repair plan ^plan for goals ^goals]);
           achieve2(goals, database, depth-1) -> repair -> database;
           if allpresent(goals)
           then plan <> repair -> plan
           else false -> plan;
               initial_state -> database;
           endif
       endunless
   endif
enddefine;

[
[   [operator pick up ?x]
    [preconditions [on_table ?x][clear ?x][empty hand]]
    [additions [holding ?x]]
    [deletions [on_table ?x][clear ?x][empty hand]]]
 [   [operator put down ?x]
    [preconditions [holding ?x]]
    [additions [on_table ?x][clear ?x][empty hand]]
    [deletions [holding ?x]]]
 [   [operator stack ?x on ?y]
    [preconditions [holding ?x][clear ?y]]
    [additions [on ?x ?y][clear ?x][empty hand]]
    [deletions [holding ?x][clear ?y]]]
 [   [operator unstack ?x from ?y]
    [preconditions [on ?x ?y][clear ?x][empty hand]]
    [additions [holding ?x][clear ?y]]
    [deletions [on ?x ?y][clear ?x][empty hand]]]
] -> operators2;

/* instantiate takes a list of operators and a list of block names
  and returns a complete list of specific operators.  It assumes that
  the variables used in the operators are x and y. */

define instantiate(operators, blocks) -> new_operators;
   vars x y;
   [^( for operator in operators do
           for x in blocks do
              for y in blocks do
                  unless x = y then instance(operator) endunless
              endfor
           endfor
       endfor)] -> new_operators;
   remove_dups(new_operators) -> new_operators;
enddefine;

/* remove_dups takes a list and returns a copy of the list omitting
  duplications. */

define remove_dups(inlist) -> outlist;
   if inlist = [] then [] -> outlist
   elseif member(hd(inlist), tl(inlist))
   then remove_dups(tl(inlist)) -> outlist
   else hd(inlist) :: remove_dups(tl(inlist)) -> outlist
   endif
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 8 ------------------------- */

vars rulebase6 facts6 grammar1 grammar2 topcats process_where_question
     process_what_question;

 [ [[university] [university admin] [university buildings]]
   [[school] [school admin] [school buildings]]
   [[school buildings] [classrooms] [offices]]
   [[university buildings] [labs] [offices] [library]]
   [[school admin] [headmaster] [bursar]]
   [[university admin] [VC] [senate]]
 ] -> rulebase6;

 [ [[labs]]
   [[offices]]
   [[library]]
   [[VC]]
   [[senate]]
 ] -> facts6;

 [ [s np vp]
   [np snp] [np snp pp]
   [snp det noun]
   [pp prep snp]
   [vp verb np]
   [noun man] [noun flies] [noun girl] [noun plane] [noun computer]
   [verb hated] [verb kissed] [verb flies]
   [det the] [det a]
 ] -> grammar1;

  [ [snp det ap noun]
    [ap ap adj] [ap adj]
    [adj big] [adj red] [adj hot]
  ] -> grammar2;

/* backwards_parse_tree takes a list of goals, e.g. categories and a
  list containing a sequence of words and a depth limit. It returns a list
  containing the parse tree and a list of any unused words.  If the parse
  fails it returns false plus the original list of words. */

define backwards_parse_tree(goals, sequence, depth)
                                             -> trees -> remainder;
   vars goal rest subgoals other_goals first_tree other_trees;
   if goals = []
   then [] -> trees; sequence -> remainder
   elseif depth <= 0 then false -> trees; sequence -> remainder
   else goals --> [?goal ??other_goals];
       if sequence matches [^goal ??rest]
       then backwards_parse_tree(other_goals, rest, depth-1)
               -> other_trees -> remainder;
           [^goal ^^other_trees] -> trees;
           return
       else foreach [^goal ??subgoals] do
               backwards_parse_tree(subgoals, sequence, depth-1)
                   -> first_tree -> rest;
               if islist(first_tree)
               then backwards_parse_tree(other_goals, rest, depth)
                       -> other_trees -> remainder;
                   if islist(other_trees)
                   then
                    [[^goal ^^first_tree] ^^other_trees] -> trees;
                       return
                   endif
               endif
           endforeach
       endif;
       false -> trees; sequence -> remainder;
   endif;
enddefine;

/* forwards_parse_goals takes a list of goals and of words and returns the
  list of goals if the sequence conforms to them, or false. */

define forwards_parse_goals(goals, sequence, depth) -> outgoals;
   vars goal subgoals before after;
   if sequence matches goals then goals -> outgoals
   elseif depth <= 0 then false -> outgoals
   else foreach [?goal ??subgoals] do
           if sequence matches [??before ^^subgoals ??after] then
               forwards_parse_goals(goals, [^^before ^goal ^^after],
                   depth-1) -> outgoals;
               if islist(outgoals) then return endif
           endif
       endforeach;
       false -> outgoals
   endif
enddefine;

/* forwards_parse_trees takes a list of goals and a sequence of words
  and returns a list containing the parse-trees, or false if no parse
  trees can be built */

define forwards_parse_trees(goals, sequence, depth) -> trees;
   vars goal subgoals before after tree;
   if topcats(sequence, goals) then sequence -> trees
   elseif depth <= 0 then false -> trees
   else
       foreach [?goal ??subgoals] do
           if sequence matches
               [??before ??tree: ^(topcats(%subgoals%)) ??after]
           then
               forwards_parse_trees(goals,
                   [^^before [^goal ^^tree] ^^after], depth-1)
                   -> trees;
               if islist(trees) then return endif
           endif
       endforeach;
       false -> trees
   endif
enddefine;

/* topcats takes a tree (or a list of words) and a list categories
  (or a list of words) as input, and returns true if the major
  categories in the tree match the list of categories.  If
  both inputs are lists of words, it returns true if they match. */

define topcats(tree, cats) -> boolean;
   if tree = [] and cats = [] then true -> boolean
   elseif tree = [] or cats = [] then false -> boolean
   elseif atom(hd(tree))
   then hd(tree) = hd(cats) and topcats(tl(tree), tl(cats))
           -> boolean
   else hd(hd(tree)) = hd(cats) and topcats(tl(tree), tl(cats))
           -> boolean
   endif
enddefine;

 [ [isa block objR] [colour red objR]   [size large objR]
   [isa block objr] [colour red objr]   [size small objr]
   [isa block objG] [colour green objG] [size large objG]
   [isa block objg] [colour green objg] [size small objg]
   [isa block objB] [colour blue objB]  [size large objB]
   [isa block objb] [colour blue objb]  [size small objb]
   [objb ison objG]
   [objG ison objR]
   [objR ison table]
   [objg ison table]
   [objr ison objB]
   [objB ison table] ] -> database;

/* meaning takes a parse-tree and returns the meaning built out of match
  patterns.  If the meaning cannot be found it returns [] */

define meaning(parse_tree) -> result;
  vars snp result adj pp ap np noun word aps;
  if parse_tree matches [noun ?word] then
     [[isa ^word ?x]] -> result
  elseif parse_tree matches [adj ?word] then
     [[= ^word ?x]] -> result
  elseif parse_tree matches [snp ?noun] then
     meaning(noun) -> result
  elseif parse_tree matches [ap ?adj] then
     meaning(adj) -> result
  elseif parse_tree matches [ap ?adj ?ap] then
     [^^(meaning(adj)) ^^(meaning(ap))] -> result;
  elseif parse_tree matches [snp ?ap ?noun] then
     [^^(meaning(ap)) ^^(meaning(noun))] -> result;
  elseif parse_tree matches [np [det =] ?snp] then
     meaning(snp) -> result
  elseif parse_tree matches [pp [prep =] ?np] then
     meaning(np) -> result
  elseif parse_tree matches [s [wh1 where][vbe is] ?np] then
     [where ^(meaning(np))] -> result
  elseif parse_tree matches [s [wh2 what][vbe is] ?pp] then
     [what ^(meaning(pp))] -> result
  else
     [] -> result
  endif;
enddefine;

 vars grammar3;
 [ [s v np pp]                             [adj white]
  [s wh1 vbe np]                          [adj red]
  [s wh2 vbe pp]                          [adj blue]
  [np pn]                                 [adj green]
  [np det snp]                            [adj big]
  [np det snp pp]                         [adj small]
  [snp noun]                              [adj large]
  [snp ap noun]                           [adj little]
  [ap adj]                                [prep on]
  [ap adj ap]                             [prep onto]
  [pp prep np]                            [prep to]
  [noun block]                            [prep over]
  [noun box]                              [prep in]
  [noun table]                            [prep at]
  [noun one]                              [prep under]
  [wh1 where]                             [prep above]
  [wh2 what]                              [prep by]
  [pn it]                                 [det each]
  [v put]                                 [det every]
  [v move]                                [det the]
  [v pickup]                              [det a]
  [v putdown]                             [det some]
  [vbe is]                               ] -> grammar3;

/* parse_with takes a list of words and a grammar and returns a parse-tree
  for a sentence. If the parse fails it returns false. If there are extra
  words on the end of the sentence it prints a message */

define parse_with(sentence, grammar) -> tree;
  vars database remainder;
  grammar -> database;
  backwards_parse_tree([s], sentence, 30) -> tree -> remainder;
  unless remainder = []
  then [^^remainder has been ignored] =>
  endunless;
  if islist(tree) then hd(tree) -> tree endif
enddefine;

/* analyse takes a sentence as input and passes it to subsidiary functions
  for parsing and response */

define analyse(sentence);
  vars trees tree match_patterns;
  if sentence = [bye] then return endif;
  parse_with(sentence, grammar3) -> tree;
  if tree = false then
     [cannot parse sentence] =>
  else
     meaning(tree) -> match_patterns;
     if match_patterns = [] then
        [that does not make sense] =>
     elseif hd(match_patterns) = "where" then
        process_where_question(match_patterns)
     elseif hd(match_patterns) = "what" then
        process_what_question(match_patterns)
     endif;
  endif;
enddefine;

/* process_where_question takes the meaning of a [where is the....] question
  and searches the database of block facts for an appropriate answer */

define process_where_question(question);
  vars patterns objects x y;
  question --> [where ?patterns];
  which("x",patterns) -> objects;
  if objects = [] then
     [no block matches that description] =>
  elseif objects matches [?x] then
     if [^x ison ?y] isin database
     then [on top of ^y] =>
     else [^x is not on top of anything] =>
     endif
  else
     [more than one block matches that description] =>
  endif;
enddefine;

/* process_what_question takes the meaning of a [what is on the....] question
  and searches the database of block facts for an appropriate answer */

define process_what_question(question);
  vars patterns objects x y;
  question --> [what ?patterns];
  which("x",patterns) -> objects;
  if objects = [] then
     [no block matches that description] =>
  elseif objects matches [?x] then
     if [?y ison ^x] isin database
     then [^y is on top of ^x] =>
     else [nothing is on top of ^x] =>
     endif
  else
     [more than one block matches that description] =>
  endif;
enddefine;

/* converse repeatedly takes input from the user and passes it to analyse
  for response, until the user types bye */

define converse;
  vars input;
  [hello] =>
  until input = [bye] do
     readline() -> input;
     analyse(input);
  enduntil;
  [bye] =>
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 9 ------------------------- */

vars rulebase7 combine;

 [ [[season winter] 1 [month december]]
   [[season winter] 1 [month january]]
   [[season winter] 0.9 [month february]]
   [[season spring] 0.7 [month march]]
   [[season spring] 0.9 [month april]]
   [[season spring] 0.6 [month may]]
   [[season summer] 0.8 [month june]]
   [[season summer] 1 [month july]]
   [[season summer] 1 [month august]]
   [[season autumn] 0.8 [month september]]
   [[season autumn] 0.7 [month october]]
   [[season autumn] 0.6 [month november]]
   [[pressure high] 0.6 [weather_yesterday good]
                        [stability_of_the_weather stable]]
   [[pressure high] 0.9 [clouds high]]
   [[pressure high] 0.9 [clouds none]]
   [[temp cold] 0.9 [season winter] [pressure high]]
   [[temp cold] 0.6 [season summer] [pressure low]]
   [[wind none] 0.3 [pressure high]]
   [[wind east] 0.3 [pressure high]]
   [[wind west] 0.6 [pressure low]]
   [[temp warm] 0.8 [wind south]]
   [[temp cold] 0.9 [wind east] [clouds none] [season winter]]
   [[temp warm] 0.9 [wind none] [pressure high]
                                [season summer]]
   [[rain yes] 0.4 [whereabouts west]]
   [[temp cold] 0.4 [whereabouts north]]
   [[rain no] 0.7 [whereabouts east]]
   [[rain yes] 0.3 [season spring] [clouds low]]
   [[rain yes] 0.3 [season spring] [clouds high]]
   [[temp warm] 0.7 [season summer]]
   [[rain yes] 0.2 [season summer] [temp warm]]
   [[rain yes] 0.6 [pressure low]]
   [[rain yes] 0.6 [wind west]]
   [[rain yes] 0.8 [clouds low]]
   [[temp cold] 0.8 [season autumn] [clouds none]]
   [[temp cold] 0.7 [season winter]]
 ] -> rulebase7;

/* backwards_search_tree1 takes a list of goals and produces a list of
  solution trees or false if no solution can be found */

define backwards_search_tree1(goals) -> tree;
  vars goal subgoals other_goals first_tree other_trees;
  if goals = [] then [] -> tree; return
  else goals --> [?goal ??other_goals];
       if present([^goal ==]) then
          foreach [^goal = ??subgoals] do
               backwards_search_tree1(subgoals) -> first_tree;
               if islist(first_tree)
               then backwards_search_tree1(other_goals)
                    -> other_trees;
                    if islist(other_trees)
                    then [[^goal ^^first_tree] ^^other_trees]
                         -> tree; return
                    endif
               endif
          endforeach;
       elseif yesno([is ^(goal(2)) the value of ^(goal(1))]) then
              backwards_search_tree1(other_goals) -> other_trees;
              if islist(other_trees)
              then [[^goal [[USER RESPONSE]]] ^^other_trees] -> tree;
                   return
              endif
       endif;
  endif;
  false -> tree
enddefine;

/* backward_search_value takes a list of goals and returns the certainty
  factor derived from the first successful solution which it finds for each
  goal */

define backwards_search_value(goals) -> certainty;
  vars goal subgoals other_goals c c1 c2;
  if goals = [] then 1 -> certainty; return
  else goals --> [?goal ??other_goals];
       if present([^goal ==]) then
          foreach [^goal ?c ??subgoals] do
               backwards_search_value(subgoals) -> c1;
               if isnumber(c1)
               then backwards_search_value(other_goals) -> c2;
                    if isnumber(c2)
                    then min(c * c1, c2) -> certainty;
                         return
                    endif
               endif
          endforeach;
       elseif yesno([is ^(goal(2)) the value of ^(goal(1))]) then
              backwards_search_value(other_goals) -> c2;
              if isnumber(c2)
              then c2 -> certainty;
                   return
              endif
       endif;
  endif;
  false -> certainty
enddefine;

/* backwards_search_values takes a list of goals and returns the overall
  certainty that they are all true by exploring the whole search space.
  Negative answers score -1. */

define backwards_search_values(goals) -> certainty;
   vars goal subgoals other_goals boolean c c1 c2;
   if goals = [] then 1 -> certainty
   else goals --> [?goal ??other_goals];
       if present([^goal ==]) then
           0 -> certainty;
           foreach [^goal ?c ??subgoals] do
               backwards_search_values(subgoals) -> c1;
               backwards_search_values(other_goals) -> c2;
               combine(min(c * c1, c2),certainty) -> certainty;
           endforeach;
       else yesno([is ^(goal(2)) the value of ^(goal(1))])
               -> boolean;
           if boolean then 1 -> c1 else -1 -> c1 endif;
           add([^goal ^c1]);
           backwards_search_values(other_goals) -> c2;
           min(c1, c2) -> certainty;
       endif;
   endif;
enddefine;

/* combine takes two certainty values each of which refers to the same goal
  and computes their combined effect as per the rules given in the text. */

define combine(c1,c2) -> certainty;
  if c1 >= 0 and c2 >= 0
  then c1 + c2 - (c1 * c2) -> certainty
  elseif c1 < 0 and c2 < 0
  then c1 + c2 + (c1 * c2) -> certainty
  else (1 - min(abs(c1),abs(c2))) -> certainty;
       unless certainty = 0
       then (c1 + c2)/certainty -> certainty
       endunless
  endif
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 10 ------------------------- */

vars blocks grammar4 shorter negative_examples;

 [ [object colour shape]
   [colour striped]
   [colour uniform]
   [uniform primary]
   [uniform pastel]
   [primary red]
   [primary blue]
   [primary yellow]
   [pastel pink]
   [pastel green]
   [pastel grey]
   [shape block]
   [shape sphere]
   [block brick]
   [block wedge]
   [brick cube]
   [brick cuboid] ] -> blocks;

 [ [s np vp]
   [np snp]
   [snp det noun]
   [vp verb np]
   [noun girl]
   [noun man]
   [verb hated]
   [verb moved]
   [det the]
   [det a] ] -> grammar4;


/* backwards_search_trees takes a list of descriptions and returns the
  ISA trees below them. */

define backwards_search_trees(descriptions) -> tree;
  vars goal subgoals;
  [] -> tree;
  for goal in descriptions do
     if present([^goal ==]) then
        [^^tree [^goal
         ^(foreach [^goal ??subgoals] do
              explode(backwards_search_trees(subgoals))
           endforeach)]] -> tree;
     else
        [^^tree ^goal] -> tree;
     endif
  endfor;
enddefine;

/* backwards_search_objects takes a description and returns all the
  specific objects covered by that description. */

define backwards_search_objects(description) -> extension;
   vars before after subgoals goal;
   [] -> extension;
   if description matches
      [??before ?goal:is_abstract_feature ??after] then
      foreach [^goal ??subgoals] do
        [^^extension
         ^^(backwards_search_objects([^^before ^^subgoals ^^after]))
        ] -> extension;
      endforeach
   else  /* ALL PARTS OF THE DESCRIPTION ARE CONCRETE */
       [^description] -> extension
   endif;
enddefine;

/* is_abstract_feature returns true if its input is an abstract feature,
  and false otherwise. */

define is_abstract_feature(feature) -> boolean;
  present([^feature ==]) -> boolean
enddefine;

/* backwards_search_descriptions takes a list of descriptions and returns
  all the descriptions that they cover. */

define backwards_search_descriptions(goals) -> descriptions;
   vars before after subgoals goal;
   [] -> descriptions;
   if goals matches [== ?goal:is_abstract_feature ==]
   then for goal in goals do
           goals --> [??before ^goal ??after];
           foreach [^goal ??subgoals] do
               [^^descriptions
                   ^^(backwards_search_descriptions
                              ([^^before ^^subgoals ^^after])
                     )
               ] -> descriptions;
           endforeach;
       endfor;
       [^goals ^^descriptions] -> descriptions;
   endif;
enddefine;

/* make description table constructs a table made up of lists of
  descriptions each paired with the specific objects that they
  cover. The lists of paired descriptions and specific objects is
  sorted by length. */

define make_description_table() -> description_table;
   vars description;
   [^(for description in backwards_search_descriptions([object]) do
       [^description ^^(backwards_search_objects(description))]
      endfor)
   ] -> description_table;
   syssort(description_table, shorter) -> description_table;
enddefine;

/* shorter returns true if the first list is shorter than the second,
  and otherwise false. */

define shorter(list1, list2) -> boolean;
  length(list1) < length(list2) -> boolean
enddefine;

/* is_negative_example returns true if its input is a member
  of the non-local variable (negative_examples) and false otherwise. */

define is_negative_example(primitive_description) -> boolean;
  member(primitive_description, negative_examples) -> boolean
enddefine;

/* subset_of returns true if list1 is a subset of list2, and false
  otherwise. */

define subset_of(list1, list2) -> boolean;
  vars item;
  true -> boolean;
  for item in list1 do
     unless member(item, list2) then false -> boolean; return
     endunless
  endfor;
enddefine;

/* covers takes a description and a set of examples.  It scans
  the non-local variable, description_table, to find the description
  entry and returns true if the examples input turn out to be a subset
  of the extension of the given description in the table. */

define covers(description, examples) -> boolean;
  vars extension;
  if [^description ??extension] isin description_table
  then subset_of(examples, extension) -> boolean
  else false -> boolean
  endif;
enddefine;

/* best_description takes a list of negative examples and positive examples
  and via the description table returns that description which excludes all
  the negative examples and covers all the positive examples. */

define best_description(negative_examples, positive_examples) -> description;
   vars entry primitive_description;
   for entry in description_table do
       if not(entry matches [?description ==
                             ?primitive_description:is_negative_example ==])
       and covers(description, positive_examples) then return
       endif
   endfor;
   false -> description
enddefine;

/* process_example takes a primitive description and a boolean denoting whether
  the example is positive or not and returns a new description. */

define process_example(primitive_description, positive) -> description;
   if positive then
       [^primitive_description ^^positive_examples] -> positive_examples;
   else
       [^primitive_description ^^negative_examples] -> negative_examples;
   endif;
   best_description(negative_examples, positive_examples) -> description;
enddefine;

/* learn sets up the initial list of positive and negative examples together
  with the description table and then loops asking the user for a new example.
  The loop terminates when a positive example cannot be processed. */

define learn;
   vars input positive description_table positive_examples
       negative_examples;
   make_description_table() -> description_table;
   [] -> positive_examples; [] -> negative_examples;
   repeat forever
       [type in a primitive description] ==>
       readline() -> input; if input = [bye] then return endif;
       yesno([is it positive?]) -> positive;
       process_example(input, positive) -> description;
       if description then [concept definition is ^description] ==>
       else quitloop
       endif;
   endrepeat;
enddefine;

/* ------------------ PROGRAMS FROM CHAPTER 11 ------------------------- */

vars rulebase8 rulebase9 rulebase10 is_var contents set_vars1 set_local_vars
     makelist makelist1;

 [ [[friends X Y] [likes X Y] [likes Y X]]
   [[likes fred albert]]
   [[likes fred john]]
   [[likes albert fred]]
   [[likes john jane]] ] -> rulebase8;

 [ [[append [] X X]]
   [[append [. H T] L [. H X]][append T L X]]
   [[member X [. X Y]]]
   [[member X [. Z Y]][member X Y]] ] -> rulebase9;

   [[[rule [. have_smarties []]]]
    [[rule [. have_eggs []]]]
    [[rule [. have_flour []]]]
    [[rule [. have_money []]]]
    [[rule [. have_car []]]]
    [[rule [. in_kitchen []]]]

    [[rule [. decorate_cake [. have_cake [. have_icing []]]]]]
    [[rule [. decorate_cake [. have_cake [. have_smarties []]]]]]
    [[rule [. have_money [. in_bank []]]]]
    [[rule [. have_cake [. have_money [. in_store []]]]]]
    [[rule [. have_cake [. in_kitchen [. have_phone []]]]]]
    [[rule [. in_store [. have_car []]]]]
    [[rule [. in_bank [. have_car []]]]]

    [[backwards_search_tree [] []]]

    [[backwards_search_tree [. Goal Goals] [. [. Goal Tree ] Trees]]
       [rule [. Goal Subgoals]]
       [backwards_search_tree Subgoals Tree]
       [backwards_search_tree Goals Trees]]
   ] -> rulebase10;

/* value_of takes a term and returns its value.  If the term is
  a "Prolog" variable, value_of calls itself recursively on its
  contents, otherwise it returns the term itself. */

define value_of(term) -> value;
  if is_var(term)
  then value_of(contents(term)) -> value
  else term -> value
  endif
enddefine;

/* the updater of value_of, assigns value to term.  If term
  contains a "Prolog" variable, the updater calls itself recursively
  on the contents, otherwise it assigns the value to the
  directly contents of the variable. */

define updaterof value_of(value, term);
  if is_var(contents(term))
  then value -> value_of(contents(term))
  else value -> contents(term)
  endif
enddefine;

/* is_uninstantiated_var takes a term and returns true if it is a "Prolog"
  variable and its value is a word starting with the underscore character. */

define is_uninstantiated_var(term) -> boolean;
  vars w;
  value_of(term) -> w;
  is_var(term) and isword(w) and w(1) = `_` -> boolean;
enddefine;

/* is_var returns true if its argument is a "Prolog" variable. */

define is_var(term) -> boolean;
  term matches [$ = $] -> boolean
enddefine;

/* cons_var takes a value and constructs a new "Prolog" variable. */

define cons_var(value) -> new_variable;
   [$ ^value $] -> new_variable
enddefine;

/* contents takes a "Prolog" variable and returns its immediate value. */

define contents(variable) -> value;
   variable --> [$ ?value $]
enddefine;

/* the updater of contents */

define updaterof contents(value, term);
   value -> hd(tl(term))
enddefine;

/* prterm prints a term without the extra $'s and [] around "Prolog" variables. */

define prterm(term);
   vars x;
   if is_var(term) then prterm(value_of(term))
   elseif islist(term)
   then pr("["); for x in term do prterm(x); sp(1) endfor; pr("]")
   else pr(term)
   endif
enddefine;

/* unify takes two terms and returns true if they unify, and otherwise
  false.  It may have the side effect of making variables share, whether
  the unification is successful or not. */

define unify(term1, term2) -> boolean;
   vars i;
   true -> boolean;
   if is_uninstantiated_var(term1)
   then term2 -> value_of(term1)            /* SIDE-EFFECT */
   elseif is_uninstantiated_var(term2)
   then term1 -> value_of(term2)
   else value_of(term1) -> term1;
       value_of(term2) -> term2;            /* SIDE-EFFECT */
       if islist(term1) and islist(term2)
          and length(term1) = length(term2)
       then for i from 1 to length(term1) do
               unless unify(term1(i), term2(i))
               then false -> boolean; return
               endunless
           endfor
       else term1 = term2 -> boolean
       endif
   endif
enddefine;

/* top_level_instantiations_ok prints out the top level instantiations,
  if any, and reads whether the user types ";" in response.  If so,
  false is returned so that the search continues, otherwise true is
  returned. */

define top_level_instantiations_ok(insts) -> boolean;
  vars input pop_readline_prompt inst;
  '? ' -> pop_readline_prompt;
  if insts = []           /* THERE WERE NO TOP-LEVEL VARIABLES */
  then pr('yes'); nl(2);  /* INDICATE THAT THE SEARCH SUCCEEDED */
       true -> boolean    /* AND RETURN <TRUE> */
  else for inst in insts do      /* PRINT INSTANTIATIONS */
           pr(inst(1)); pr(' = ');
           prterm(inst(2)); nl(1)
       endfor;
       readline() -> input;
       if input = [;]
       then false -> boolean    /* CAUSE SEARCH TO CONTINUE */
       else pr('yes'); nl(2);   /* THE USER TYPED <RETURN> */
            true -> boolean
       endif
  endif
enddefine;

/* treat_as_var takes a term and checks whether it is a word that
  starts with an uppercase letter, e.g. X, Y or Foo. */

define treat_as_var(term) -> boolean;
   isword(term) and isuppercode(term(1)) -> boolean
enddefine;

/* set_vars takes a structure and returns a new structure where
  every word starting with an uppercase letter is replaced by
  a "Prolog" variable.  It also returns a list of pairs which
  map the original variable names with the "Prolog" variables. */

define set_vars(structure) -> new_structure -> insts;
   vars database;
   [] -> database;
   set_vars1(structure) -> new_structure;
   database -> insts
enddefine;

/* set_vars1 works its way through a structure and replaces
  all the variables, defined via treat_as_var, by REF objects.  It uses
  the database to keep track of which variables have been so replaced. */

define set_vars1(structure) -> new_structure;
  vars component new_variable;
  [^(for component in structure do
         if treat_as_var(component)
         then
            if present([^component ?variable])
            then variable
            else cons_var(gensym("_")) -> new_variable;
                 add([^component ^new_variable]); /* ADD TO INSTS */
                 new_variable
            endif;
         elseif islist(component) then
            set_vars1(component)
         else
            component
         endif;
     endfor)] -> new_structure;
enddefine;

/* make_restorative_pairs takes a structure and returns a list of pairs of its
 uninstantiated variables and their contents. */

define make_restorative_pairs(structure) -> pairs;
  vars component;
  [^(for component in structure do
         if is_uninstantiated_var(component)
         then [^(contents(component)) ^component]
         elseif islist(component)
         then explode(make_restorative_pairs(component))
         endif
      endfor)] -> pairs;
enddefine;

define satisfy_extralogical_goal(goals);
  vars structure clause variables goal other_goals;
  if not(goals matches [?goal ??other_goals]) then
     return(goals)
  elseif goal matches [write ?structure] then
     structure ==>
  elseif goal matches [popval ?structure]
     then popval(structure);
  elseif goal matches [assert ?structure] then
     add(structure);
  elseif goal matches [retract ?structure] then
     for clause in database do
        if unify(structure, set_local_vars(clause, newassoc([]))) then
           remove(clause);
           return(other_goals)
        endif;
     endfor;
     return(false);
  else
     return(goals)
  endif;
  return(other_goals);
enddefine;

/* backwards_search_prolog takes a list of goals and set of instantiations
  and returns true if the goals can be satisfied and false otherwise. */

define backwards_search_prolog(goals, insts) -> boolean;
   vars var_map clause clause_goal renamed_clause subgoals
        search_goal other_goals pair pairs;
   if goals = []
   then top_level_instantiations_ok(insts) -> boolean;
   else goals --> [?search_goal ??other_goals];
       make_restorative_pairs(search_goal) -> pairs;
       for clause in database do
           set_vars(clause) -> renamed_clause -> var_map;
           renamed_clause --> [?clause_goal ??subgoals];
           if unify(search_goal, clause_goal) and
              backwards_search_prolog([^^subgoals ^^other_goals],
                                      insts)
           then true -> boolean; return
           else       /* RESTORE OLD VALUES FOR SEARCH_GOAL VARS */
               for pair in pairs do
                   pair(1) -> contents(pair(2))
               endfor
           endif
       endfor;
       false -> boolean
   endif;
enddefine;

/* satisfy_top_level_goals takes a list of goals and tries to satisfy them. */

define satisfy_top_level_goals(goals);
  vars top_level_insts;
  1 -> gensym("_");
  set_vars(goals) -> goals -> top_level_insts;
  if not(backwards_search_prolog(goals, rev(top_level_insts)))
  then pr('no'); nl(2)
  endif;
enddefine;

/* toyplog takes a rulebase and conducts a Prolog like interaction */

define toyplog(rulebase);
  vars goals pop_readline_prompt database;
  '?- ' -> pop_readline_prompt;
  pr('Toyplog version 1'); nl(1);
  rulebase -> database;
  until goals = [bye] do
     makelist(readline()) -> goals;
     unless goals = [bye] or goals = [] then
        satisfy_top_level_goals(goals);
     endunless;
  enduntil;
enddefine;

/* makelist takes a flat list possibly containing "[" and "]" and
  returns a correspondingly nested list. */

define makelist(flatlist) -> structure;
  makelist1() -> structure
enddefine;

define makelist1() -> structure;
  [^( until flatlist = [] or hd(flatlist) = "]" do
         if hd(flatlist) = "["
         then tl(flatlist) -> flatlist;
              makelist1()
         else hd(flatlist);
         endif;
         tl(flatlist) -> flatlist
      enduntil) ] -> structure
enddefine;

/*  --- Revision History ---------------------------------------------------
 */
