/*  --- Copyright University of Sussex 1989. All rights reserved. ----------
 *  File:           $poplocal/local/lib/semnet.p
 *  Purpose:        Semantic network package for teaching
 *  Author:         Mike Sharples, Aug 30 1985 (see revisions)
 *  Documentation:  HELP * SEMNET
 *  Related Files:
 */

vars PARTLINK ISLINK CONNECTLINK VISITED sadd salladd sremove sflush;

;;; assumes "isa" for property inheritance and "ispart" for transitive
;;; relation and "connects" for commutative/transitive relation.

"ispart"->PARTLINK;
"isa"->ISLINK;
"connects"->CONNECTLINK;

add->sadd;
alladd->salladd;
remove->sremove;
flush->sflush;

;;; SPRESENT


;;; like present except it uses sysmatch rather than matches (ie it records
;;; variable bindings

define procedure syspresent(XX);
    lvars DB;
    database -> DB;
    until DB==nil do
        if sysmatch(XX,fast_front(DB)) then
            fast_front(DB) -> it;
            return(true);
        endif;
        fast_back(DB) -> DB
    enduntil;
    return(false);
enddefine;

define procedure sysinfer (A,REST)->RESPONSE;
    vars CC DB SS;
    unless syspresent(A<>REST)->>RESPONSE then
                                ;;; syspresent adds ? vars to popmatchvars
        database->DB;
        until DB==nil do
           if sysmatch([^^A ^ISLINK ??CC],fast_front(DB)) then
              back(popmatchvars)->popmatchvars; ;;;remove CC from popmatchvars
              quitif(sysinfer(CC,REST) ->>RESPONSE);
           endif;
           fast_back(DB)->DB;
        enduntil;
        nil->popmatchvars; ;;; clear in case ? var for A can be reinstantiated
    endunless;
enddefine;


define procedure systransitive (A,REST)->RESPONSE;
    vars CC DB ;
    unless (syspresent(A<>REST) and
               front(back(it))==PARTLINK)->>RESPONSE then
                                ;;; syspresent adds ?vars to popmatchvars
        database->DB;
        until DB==nil do
           if sysmatch([^^A ^PARTLINK ??CC],fast_front(DB)) then
              back(popmatchvars)->popmatchvars; ;;;remove CC from popmatchvars
              quitif(systransitive(CC,REST) ->>RESPONSE);
           endif;
           fast_back(DB)->DB;
        enduntil;
    endunless;
enddefine;

;;; splits a list into first element (including qvar) and rest

define procedure syssplit(PL)->A->REST;
   destpair(PL)->REST->A;
   if A=="?" then
     conspair("?",conspair(destpair(REST)->REST,[]))->A
   else
     A::nil->A
   endif;
enddefine;

;;; finds if A CONNECTs C

define procedure sysconnect (A,B,C)->RESPONSE;
    vars CC DB ITEM;
    fast_front(A)::VISITED->VISITED;
    unless ((syspresent(A<>B<>C) or (syspresent(C<>B<>A))) and
               front(back(it))==CONNECTLINK)->>RESPONSE then
                                ;;; syspresent adds ?vars to popmatchvars
        database->DB;
        until DB==nil do
           destpair(DB)->DB->ITEM;
           if (sysmatch([^^A ^CONNECTLINK ??CC],ITEM)
               or sysmatch([??CC ^CONNECTLINK ^^A],ITEM)) and
             ( back(popmatchvars)->popmatchvars; ;;;remove CC from popmatchvars
       not(member(fast_front(CC),VISITED))  ) then
              quitif(sysconnect(CC,B,C) ->>RESPONSE);
           endif;
        enduntil;
    endunless;
enddefine;




define procedure sysspresent(PATTERN)->RESPONSE;
  vars A,B,C,REST,VISITED;
   syssplit(PATTERN)->A->REST;
   syssplit(REST)->B->C;
   nil->VISITED;
   if (sysinfer(A,REST) or systransitive(A,REST)
       or sysconnect(A,B,C))->>RESPONSE then
 ;;; deals with inferred patterns. Ones whose first element is = or a
 ;;; ? variable eg [?x likes food] just use the 'it' assigned by
 ;;; sysmatches.
       unless A = [=] then
          instance(A)<>fast_back(it)->it;
       endunless;
    endif;
enddefine;


;;; equivalent to present, except that it inherits attributes from
;;; "isa" links and also uses "ispart" transitively

define procedure spresent (PATTERN) -> RESPONSE;
    vars popmatchvars;
    if ispair(PATTERN) then
        []->popmatchvars;
        sysspresent(PATTERN)->RESPONSE
    else
        mishap('LIST NEEDED FOR "SPRESENT"',[^PATTERN]);
    endif;
enddefine;



;;; SLOOKUP

define procedure slookup(PATTERN);
    unless spresent(PATTERN) then
        mishap(PATTERN,1,'SLOOKUP FAILURE')
    endunless
enddefine;




;;; SFOREACH

vars procedure sysstryeach;

define procedure stryeach(SFOREACH_PLIST,database);
   nil->popmatchvars;
   nil->VISITED;
  sysstryeach(SFOREACH_PLIST);
  ksuspend(false,1);
enddefine;

;;; looks for isa or ispart descendents, eg if the item is [person likes food]
;;; and A is ?x then tries to find [?x isa person] and, if found, makes 'it'
;;; [^x likes food]


vars systopmatch sys_get_descendents;

define sysstryeach(PL);
  vars VISITED SS DB ITEM A B C REST REVERSED;
  popmatchvars->SS;
  database->DB;
  syssplit(PL)->A->REST;
  syssplit(REST)->B->C;

;;; if the pattern is of the form [<node> connects ?var] then forward
;;; chaining is more efficient, but sysstryeach does backward chaining,
;;; so simply reverse the pattern to [?var connects <node>] and do
;;; backwards chaining (remembering to reverse 'it').
  if (length(A)=1 and B=[%CONNECTLINK%])->>REVERSED then
     A,C -> A -> C;
  endif;
  for ITEM in DB do
     if [%CONNECTLINK%] matches B
       and fast_front(fast_back(ITEM))==CONNECTLINK then ;;;try reversed "connects" match
         systopmatch(rev(ITEM));
         SS->popmatchvars;
     endif;
     systopmatch(ITEM);
     SS->popmatchvars;
  endfor;
enddefine;


define systopmatch(ITEM);
  vars SAVEVARS SAVEVISITED ITC ITB ITA REVERSED;
       explode(ITEM)->ITC->ITB->ITA;
       VISITED->SAVEVISITED;
       if sysmatch(B<>C,fast_back(ITEM)) then
          popmatchvars->SAVEVARS;
          if sysmatch(A,[%ITA%])
           and not(member(ITA,VISITED))  then  ;;;pattern may be of the form
             if REVERSED then                  ;;; [?x <link> ?x] in which
                rev(ITEM)->it;                 ;;; case no match, but possible
             else                              ;;; descendents
                ITEM->it;
             endif;
             suspend(true,1);
          endif;
          ITA::(ITC::VISITED)->VISITED;
          SAVEVARS->popmatchvars;
          if ITB==PARTLINK then
             sys_get_descendents(ITA,PARTLINK)
          elseif ITB==CONNECTLINK then
             sys_get_descendents(ITA,CONNECTLINK)
          else
             sys_get_descendents(ITA,ISLINK)
          endif;
          SAVEVISITED->VISITED;
        endif;
enddefine;

define sys_get_descendents(AA,BB);
  vars  NEWITEM NEWREST NEWA NEWB NEWC DB SAVEVARS;
  database->DB;
  for NEWITEM in DB do
   if BB==CONNECTLINK and fast_front(NEWITEM)=AA then
       rev(NEWITEM)->NEWITEM;
    endif;
    explode(NEWITEM)->NEWC->NEWB->NEWA;
    if  NEWC=AA and NEWB==BB and not(member(NEWA,VISITED)) then
        popmatchvars->SAVEVARS;
        NEWA::VISITED->VISITED;
;;;popmatchvars set in sysstryeach. Only return true is first query var
;;; (which may have been instantiated) matches first element of item.
        if sysmatch(A,[%NEWA%]) then
           if REVERSED then
               [^ITC ^ITB ^NEWA]->it
           else
               [^NEWA ^ITB ^ITC]->it;
           endif;
           suspend(true,1);
        endif;
        SAVEVARS->popmatchvars;
       sys_get_descendents(NEWA,BB);
     endif;
  endfor;
enddefine;

define procedure startstryeach(SFOREACH_PL,database);
  vars popmatchvars;
  consproc(SFOREACH_PL,database,2,stryeach);
enddefine;


vars syntax endsforeach;


define syntax sforeach;
    vars Var Lab Endlab _x;
    sysnvariable() -> Var;
    sysnlabel() -> Lab;  sysloop(Lab);
    sysnlabel() -> Endlab;   sysloopend(Endlab);
    sysVARS(Var,0);
    systxcomp([do then in]) -> _x;
    if _x == "in" then
        erase(systxcomp([do then]));
    else
        sysPUSH("database");
    endif;
    sysCALL("startstryeach");
    sysPOP(Var);
    sysLABEL(Lab);
    sysPUSHQ(0);
    sysPUSH(Var);
    sysCALL("runproc");
    sysIFNOT(Endlab);
    erase(systxsqcomp([endsforeach close]));
    sysGOTO(Lab);
    sysLABEL(Endlab);
enddefine;



;;; like stryeach, but does not reset popmatchvars

define procedure sstryeach(PLIST,database);
  nil->VISITED;
  sysstryeach(PLIST);
  ksuspend(false,1);
enddefine;



;;;  SALLPRESENT takes a whole list of patterns and tries to find
;;;  way of binding variables so that all items are present in the
;;;  DATABASE


vars procedure syssallpresent;

define sallpresent(XS);
  vars popmatchvars;
  nil->popmatchvars;
    syssallpresent(XS)->them;
enddefine;

;;;  SYSSALLPRESENT does all the work. It finds a match for the
;;;  first element of the list and then calls itself recursively to
;;;  find a match for the reminder.

define procedure syssallpresent(PL);
    vars V PATTERN, IT, SS, THEM, RESULT;
    popmatchvars->SS;
    if PL == [] then  ;;;no more patterns to match
       return(true,[]);
    else
       destpair(PL)->PL->PATTERN;
       consproc(PATTERN,database,2,sstryeach)->V;
       while runproc(0,V) do
          it->IT;
          if (syssallpresent(PL)->THEM->>RESULT) then
             IT::THEM->THEM;
             return(RESULT,THEM);
          endif;
          SS->popmatchvars;
       endwhile;
       return(false,[]);
    endif;
enddefine;


;;;  STRYALL takes a whole list of patterns and a database and tries to find
;;;  way of binding variables so that all items are present in the
;;;  DATABASE after finding one, it suspents the current process, which
;;;  can be resumed later.


vars procedure sysstryall ;


define procedure stryall(PLIST,database);
  vars popmatchvars;
  nil->popmatchvars;
    sysstryall(PLIST);
    ksuspend(false,1)
enddefine;





;;;  SYSTRYALL does all the work. It finds a match for the
;;;  first element of the list and then calls itself recursively to
;;;  find a match for the remainder. The use of POPMATCHVARS is
;;;  important; When match encounters a variable (indicated by the
;;;  prefix "?" or "??") it either users the existing value (if the
;;;  variable is a member of POPMATCHVARS) or finds a value. If the
;;;  match found for the first item is no good, then MATCHVARS must
;;;  be reset to allow a second match for the first item.
;;;  If the recursion ever terminates with PL empty, then a complete match
;;;  has been found. An instance of the list of patterns is built and assigned
;;;  to THEM, and the current process is suspended. If it is RUNPROC again, it
;;;  goes back up the recursive stack and tries again.

define procedure sysstryall(PL);
    vars V, X, SS;
    if PL == [] then
        instance(PL) -> them;    ;;;PL is the complete pattern
        suspend(true,1)
    else
        dest(PL) -> PL -> X;
        consproc(X,database,2,sstryeach)->V;          ;;; like foreach, but
        while runproc(0,V) do sysstryall(PL); endwhile;  ;;; doesnt reset
    endif;                                               ;;; popmatchvars
enddefine;


;;; STARTTRYALL creates a process, with a pattern list, a database and TRYALL
;;; as the procedure

define procedure startstryall(PL,database);
    consproc(PL,database,2,stryall)
enddefine;

;;;     SFOREVERY [........] DO <actions> ENDSFOREVERY
;;; becomes, roughly:
;;;
;;;     VARS %V;
;;;     STARTSTRYALL([.........]) -> %V;
;;;     WHILE RUNPROC(0,V) DO <actions> ENDSFOREVERY
;;;
vars syntax endsforevery;


define syntax sforevery;
    vars ENDLAB LAB VAR _x;
    sysnlabel() -> LAB; sysloop(LAB);
    sysnlabel() -> ENDLAB; sysloopend(ENDLAB);
    sysnvariable() -> VAR;
    sysVARS(VAR,0);
    systxcomp([do then in]) -> _x;
    if _x == "in" then
        erase(systxcomp([do then]))
    else
        sysPUSH("database")
    endif;
    sysCALL("startstryall");
    sysPOP(VAR);
    sysLABEL(LAB);
    sysPUSHQ(0);
    sysPUSH(VAR);
    sysCALL("runproc");
    sysIFNOT(ENDLAB);
    erase(systxsqcomp([endsforevery close]));
    sysGOTO(LAB);
    sysLABEL(ENDLAB)
enddefine;



;;; SWHICH

define procedure swhich (Vars, Pattern) -> List;
    vars Vars A B First  Rest Others;
    if ispair(Vars) or isword(Vars) then
        if ispair(Pattern) then
                [%sforevery Pattern do
                    if isword(Vars) then valof(Vars)
                    else maplist(Vars,valof)
                    endif
                endsforevery%] -> List;
        else mishap('LIST NEEDED FOR "SWHICH "', [^Pattern])
        endif;
    else
        mishap('WORD OR LIST NEEDED FOR "SWHICH "', [^Vars] )
    endif;
enddefine;


global vars semnet = true;     ;;; for -uses-


/*  --- Revision History ---------------------------------------------------
--- Aaron Sloman, 8 Jan 2020, fixed error reported by Hakan Kjellerstrand
 <         instance(PLIST) -> them;    ;;;PLIST is the complete pattern
 ---
 >         instance(PL) -> them;    ;;;PL is the complete pattern

--- John Williams, Mar 31 1989 Creates variable "semnet" (for -uses-)
--- Mike Sharples, Sep 27 1985 CONNECTS commutative link added
--- Mike Sharples, Sep  2 1985 Corrected bug in sysinfer and systransitive
                               so as to search up more than one isa chain.
 */
