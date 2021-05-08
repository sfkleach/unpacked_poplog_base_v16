/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 *  File:           $usepop/pop/local/lib/newprodsys.p
 *  Purpose:        Production system interpreter
 *  Author:         Mike Sharples, Aug 29 1985 (see revisions)
 *  Machines:       cvaxa unx1 vax2 cgeca
 *  Documentation:  HELP * PRODSYS
 *  Related Files:  TEACH * PSYS2
 */

/*
THIS IS A PURELY LOCAL VERSION OF LIB PRODSYS
*/

/*  PRODUCTION SYSTEM INTERPRETER       Allan Ramsay, 29 November 1983
 *                          Modified by Mike Sharples, 24th April 1985
 *                          Modified by Tom Khabaza, 3rd Sept 1985
 *
 *  Intended to replace LIB PSYS - uses standard matcher to check triggers,
 *  all productions are turned into compiled procedures, and can have
 *  code for their bodies. Productions are defined via a more convenient
 *  syntax. Options are provided for preventing a given production from firing
 *  more than once for a given database item, and for backtracking after
 *  productions which call the procedure "fail", though these options are NOT
 *  compatible.
 */

vars _state_stack backtracking walk repeating chatty matched rulebase ;

if isundef(walk) then false -> walk endif;
if isundef(chatty) then true -> chatty endif;
if isundef(repeating) then true -> repeating endif;
if isundef(rulebase) then nil -> rulebase endif;
if isundef(backtracking) then false -> backtracking endif;

define constant p_name (_prod); subscrv(1,_prod) enddefine;
define constant p_pattern (_prod) ; subscrv(2,_prod) enddefine;
define constant p_body (_prod) ; subscrv(3,_prod) enddefine;
define constant p_func (_prod) ; subscrv(4,_prod) enddefine;

constant already_used ; /* Table containing items that have been matched
                         * against specific patterns - only used if repeating
                         * is false */
newproperty(nil,100,nil,false) -> already_used;



define global constant procedure exprread() ;
    vars svproglist pop_syntax_only ;
    true -> pop_syntax_only;
    proglist -> svproglist;
    sysxcomp();
    if null(proglist)
      then svproglist
    else
       [%
            until   svproglist == proglist
            do   if     not(null(svproglist)) and
                             (back(svproglist) == back(proglist))
                   then    fast_front(svproglist) -> fast_front(proglist); quitloop;
                   endif;
                fast_destpair(svproglist) -> svproglist;
            enduntil%];
    endif;
enddefine;

/* Procedure to do delayed evaluation of lists containing ^ or ^^ */
define deref (proglist);
    vars h;
    if      atom(proglist)
    then    proglist
    else    dest(proglist) -> proglist -> h;
            if      h == "^"
            then  popval(exprread()) :: deref(proglist);
            elseif  h == "^^"
            then    popval(exprread()) <> deref(proglist)
            else    h :: deref(proglist)
            endif;
    endif;
enddefine;

/* Tom Khabaza, 21 Nov. 1984: QUERY modification
    In order to make all_match handle multiple patterns with the SAME
    query variable in them, as with allpresent, we have to:
        Localise popmatchvars.
        Not use database procedures - this is because they use matches
        which itself localises popmatchvars.  We want to keep the value
        of popmatchvars going throughout the invokation of a rule;
        but if we backtrack within the invokation, we want to return
        to the previous value (hence savematchvars).
        We use a loop through the database, using sysmatch on each item
        to achieve this effect.
*/

define constant all_match (_triggers) -> _res;
    vars it _seen _pattern trigger popmatchvars f savematchvars;
    if      _triggers == nil
    then    nil -> _res
    else    deref(hd(_triggers)) -> trigger;
            if isprocedure(trigger) then
                ;;; modification WHERE
                ;;; a procedure in the list of triggers is a where clause
                ;;; it should return a boolean
                if trigger() and (all_match(tl(_triggers)) ->> _res) then
                    true :: _res -> _res;
                else
                    false -> _res;
                endif;
            elseif  trigger matches [not ? _pattern]
            then
                for f in database do    ;;; modification QUERY
                    if  sysmatch(_pattern, f) then
                        false -> _res; return;
                    endif;
                endfor;
                if (all_match(tl(_triggers)) ->> _res) then
                   trigger:: _res-> _res;
                endif;
            elseif  repeating
            then
                ;;; modification QUERY
                popmatchvars -> savematchvars;
                for f in database then
                    if (sysmatch(trigger, f) ->> _res)
                    and (all_match(tl(_triggers)) ->> _res)
                    then
                        f :: _res -> _res;
                        quitloop;
                    endif;
                    savematchvars -> popmatchvars;
                endfor;
            else    false -> _res;
                    already_used(_triggers) -> _seen;
                    ;;; modification QUERY
                    popmatchvars -> savematchvars;
                    for f in database do
                        if sysmatch(trigger, f)
                        and not(member(f, _seen))
                        and (all_match(tl(_triggers)) ->> _res)
                        then
                            f :: _res -> _res;
                            quitloop; /* Found one !!! */
                        endif;
                        savematchvars -> popmatchvars;
                    endfor;
            endif;
    endif;
enddefine;

define constant set_nil (_triggers);
vars _x ;
for _x on _triggers do nil -> already_used(_x) endfor;
enddefine;

define constant run();
vars _res _pattern matched _prod_list _prod _state_stack _sv_dbase;
if      backtracking and not(repeating)
then    mishap('Cannot do backtracking unless repeating is enabled')
endif;
nil -> _state_stack;
unless  repeating
then    for _prod in rulebase do set_nil(p_pattern(_prod)) endfor;
endunless;
true -> matched;
while   matched
do      false -> matched; rulebase -> _prod_list; database -> _sv_dbase;
        until   _prod_list == nil
        do      if      (p_func(dest(_prod_list) -> _prod_list)(), matched)
                then    if      backtracking
                        then    {% _prod_list, _sv_dbase %} :: _state_stack
                                                              -> _state_stack;
                        endif;
                        quitloop
                endif;
        enduntil;
endwhile;
enddefine;

define constant fail ;
                       /* Restore _prod_list (i.e. list of productions still
                        * to be checked) and database to state they were in
                        * when last production was selected. Pretend that you
                        * haven't actually done anything (by setting matched
                        * to false).
                        */
vars _x ;
unless  backtracking and _state_stack /== nil
then    mishap('Cannot backtrack - no states left or not in right mode',nil)
endunless;
dest(_state_stack) -> _state_stack -> _x;
subscrv(1,_x) -> _prod_list; subscrv(2,_x) -> database; false -> matched;
enddefine;

define constant end_sys () ;
exitfrom(database,run);
enddefine;

define constant pattern_vars (_pattern);
vars x ;
if      atom(_pattern)
then    nil
elseif  ((hd(_pattern)->>x) == "?" or x == "??" or x == "^" or x == "^^")
          and (hd(tl(_pattern)) /== "(")
then    tl(_pattern) -> _pattern;
        if null(_pattern) then mishap('Illformed pattern',nil) endif;
        hd(_pattern) :: pattern_vars(tl(_pattern))
else    pattern_vars(hd(_pattern)) <> pattern_vars(tl(_pattern))
endif;
enddefine;

define constant set_pattern (_name, _pattern,_res,_body);
vars request subl;
if      walk
then
        while (applist([About to try rule ^ _name],spr);
               readline()->>request)/=nil do
           if request = [why]
           then spr('Because');
                for subl on _res
                do   spr(hd(subl));
                     if     tl(subl)/=nil
                     then   pr('and');
                     endif;
                     pr(newline);
                endfor
           elseif   request= [show]
           then     applist([Rule ^ _name ^newline
                             'Conditions:' ^ _pattern ^newline
                             'Actions:' ^ _body ^newline],spr);
           endif;
        endwhile;
endif;
if      chatty
then    applist([^newline Using rule ^ _name with ^newline
                'Database:' ^database
                ^newline 'Conditions:' ^ _pattern 'matching ' ^ _res
                ^newline 'Actions:'  ^ _body  ^newline],spr);
endif;
true -> matched;
unless  repeating
then    for _x on _pattern
        do  (dest(_res) -> _res) :: already_used(_x) -> already_used(_x);
        endfor;
endunless;
enddefine;

vars syntax endrule ;

define syntax rule ;
vars _name _pattern _body _vlist _x _fn _savproglist _proc;
''><itemread()-> _name;
[%until (listread() ->> _x) == ";"
  do    if _x == "where" then   ;;; modification WHERE
            ;;; make the procedure to check the "where" condition
            ;;; where clauses must be at the end of the pattern,
            ;;; and must finish with a semi-colon.
            proglist -> _savproglist;
            sysPROCEDURE('where cluase',0);
            systxcomp(";") ->;
            sysENDPROCEDURE() ->> _proc;
            cons_with consstring
            {% until tl(_savproglist) == proglist do
                dest_characters(dest(_savproglist) -> _savproglist); `\s`;
            enduntil -> %} -> pdprops(_proc);
            quitloop;
        elseif atom(_x) then
            mishap('Trigger should be list or where clause', [% _x %]);
        else    _x;
        endif;
  enduntil %] -> _pattern;
pattern_vars(_pattern) -> _vlist;
unless _vlist == nil then popval([vars ^^ _vlist ;] ->> _vlist) endunless;
impseqread() -> _body;
unless  itemread() == "endrule"
then    mishap('Unexpected terminator - expecting ENDRULE', nil)
endunless;
/* Now make up and compile (NOT run) a procedure which tests whether the
 * pattern is matched, and, if it is, sets matched to true and runs the body
 */
popval([procedure (_pattern);
        ^^ _vlist;
        if      all_match(_pattern) ->> _res
        then    set_pattern(^ _name, _pattern, _res, ^ _body);
                ^^ _body;
        endif;
        endprocedure ]) -> _fn;
rulebase <> [% {% _name, _pattern, _body, _fn(% _pattern %) %} %]
    -> rulebase;
enddefine;


constant procedure notequalto;
   nonop /= -> notequalto;

constant procedure greaterthan;
   nonop > ->greaterthan;

constant procedure lessthan;
   nonop < -> lessthan;

/*  --- Revision History ---------------------------------------------------
--- Mike Sharples, Oct 23 1986 Removed bug (I hope) in part of all_match
         that matches [not ? _pattern]
--- Tom Khabaza, Nov. 21 1985 Modified handling of query variables in patterns
        to be consistent with allpresent etc.
        (see comments labelled with "QUERY").
        Also made local rather than public library
--- Tom Khabaza, Sep  3 1985 Modified to use where clauses
        (see comments labelled with "WHERE").
 */
