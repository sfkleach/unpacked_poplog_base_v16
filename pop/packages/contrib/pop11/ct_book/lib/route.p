/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:           $usepop/pop/local/lib/route.p
 > Purpose:        Demonstration of search using London Underground routes
 > Author:         David Young, Nov 20 1986
 > Machines:       unx1 vax2
 > Documentation:  TEACH * ROUTE
 > Related Files:  LIB * ROUTETREE
 */

/*
Branch and Bound search program for finding underground routes,
assuming 2 mins between stations and 3 mins to change.

Written in TPOP except for the use of the matcher arrow, and comment
delimiters like the ones round this comment.

*/

/* If CHATTY is set TRUE then the program will print out the arrivals at
each station. If VERYCHATTY is set TRUE then the program will print out
the pending arrivals thus created as well. */

vars chatty verychatty;
true -> chatty;
false -> verychatty;

/* First the basic assumptions. */

vars travtime changetime;
2 -> travtime;
3 -> changetime;

/*
Now set up a map of the underground.

The format is a set of triples with CONNECTS as the only relation.
Each item related is a line-station combination: the first word of the
list is a line name and the rest of the list is a station name.
The line name need not really appear twice in each relation but it is
convenient if it does so.

This is only 24 connections. The full map has several hundred, but this
will suffice for demonstration.

The line names are in capitals for printing out purposes only.

Note that after ROUTE has been called, the database will contain not only
the map but also a representation of the whole search tree for that route.
*/


add( [[JUBILEE charing cross] connects [JUBILEE green park]] );
add( [[JUBILEE green park] connects [JUBILEE bond street]] );
add( [[JUBILEE bond street] connects [JUBILEE baker street]] );
add( [[BAKERLOO embankment] connects [BAKERLOO charing cross]] );
add( [[BAKERLOO charing cross] connects [BAKERLOO piccadilly circus]] );
add( [[BAKERLOO piccadilly circus] connects [BAKERLOO oxford circus]] );
add( [[CIRCLE embankment] connects [CIRCLE westminster]] );
add( [[CIRCLE westminster] connects [CIRCLE st jamess park]] );
add( [[CIRCLE st jamess park] connects [CIRCLE victoria]] );
add( [[CIRCLE victoria] connects [CIRCLE sloane square]] );
add( [[CIRCLE sloane square] connects [CIRCLE south kensington]] );
add( [[PICCADILLY south kensington] connects [PICCADILLY knightsbridge]] );
add( [[PICCADILLY knightsbridge] connects [PICCADILLY hyde park corner]] );
add( [[PICCADILLY hyde park corner] connects [PICCADILLY green park]] );
add( [[PICCADILLY green park] connects [PICCADILLY piccadilly circus]] );
add( [[CENTRAL lancaster gate] connects [CENTRAL marble arch]] );
add( [[CENTRAL marble arch] connects [CENTRAL bond street]] );
add( [[CENTRAL bond street] connects [CENTRAL oxford circus]] );
add( [[CENTRAL oxford circus] connects [CENTRAL tottenham court road]] );
add( [[VICTORIA warren street] connects [VICTORIA oxford circus]] );
add( [[VICTORIA oxford circus] connects [VICTORIA green park]] );
add( [[VICTORIA green park] connects [VICTORIA victoria]] );
add( [[VICTORIA victoria] connects [VICTORIA pimlico]] );
add( [[VICTORIA pimlico] connects [VICTORIA vauxhall]] );



define addonefuture(newplace,newtime,comefrom);
    ;;; This records in the database a single pending arrival at a place
    ;;; (where place means a line-station combination as in the database),
    ;;; unless there has already been an arrival at that place.
    ;;; Also protects against inserting the same future event twice, as
    ;;; could happen when looking at line changes due to the fact that the
    ;;; information that a station is on a given line can appear twice in
    ;;; the database.
    ;;; Can also say what it's doing.
    vars futureevent;

    [will arrive ^newplace at ^newtime mins from ^comefrom] -> futureevent;

    if not(present([arrived ^newplace at = mins from =]))
    and not(present(futureevent))
    then
        add(futureevent);
        if verychatty then
            [ . . will arrive ^newplace at ^newtime mins] =>
        endif;
    endif;

enddefine;



define addfuture(event);
    ;;; Given an event, adds the pending events that follow it into the database
    vars place newplace time station line newln;

    ;;; Get breakdown of event
    ;;; Note that the matcher arrow --> could be replaced by MATCHES
    ;;; except that it does not return a TRUE/FALSE value. We know that
    ;;; the event passed to ADDFUTURE will have the right format.
    event --> [arrived ?place at ?time mins from =];
    place --> [?line ??station];

    ;;; First get all the connections on the same line
    foreach [^place connects ?newplace] do
        addonefuture(newplace,time+travtime,place);
    endforeach;

    ;;; This just repeats the last bit for patterns the other way round
    foreach [?newplace connects ^place] do
        addonefuture(newplace,time+travtime,place);
    endforeach;

    ;;; Then all the changes to other lines
    foreach [[?newln ^^station] connects =] do
        addonefuture([^newln ^^station],time+changetime,place);
    endforeach;

    ;;; And again for patterns the other way round
    foreach [= connects [?newln ^^station]] do
        addonefuture([^newln ^^station],time+changetime,place);
    endforeach;

enddefine;



define next()->event;
    ;;; This looks at all the future events in the database and finds
    ;;; the one that will happen next - that is, the one with the
    ;;; smallest value of time, and returns a list giving the
    ;;; corresponding actual event.
    vars leasttime place time lastplace;
    ;;; leasstime has to start off bigger than any likely time
    100000 -> leasttime;

    foreach [will arrive ?place at ?time mins from ?lastplace] do
        if time < leasttime then
            [arrived ^place at ^time mins from ^lastplace] -> event;
            time -> leasttime;
        endif;
    endforeach;

enddefine;



define insertnext(event);
    ;;; Takes an event returned by NEXT and inserts it into the database, then
    ;;; removes all pending events which would cause later arrivals at the same
    ;;; station.
    ;;; Can also print out the event.
    vars place;

    ;;; addition
    add(event);

    ;;; removal
    event --> [arrived ?place at = mins from =];
    foreach ([will arrive ^place at = mins from =]) do
        remove(it);
    endforeach;

    if chatty or verychatty then
        event =>
    endif;

enddefine;



define start(station);
    ;;; This sets up the database ready to start by inserting pending
    ;;; arrivals at the starting station
    vars line;

    foreach [[?line ^^station] connects =] do
            addonefuture([^line ^^station],0,[start]);
    endforeach;

    ;;; This is the same as the first half but for the other sort of patterns
    foreach [= connects [?line ^^station]] do
            addonefuture([^line ^^station],0,[start]);
    endforeach;
enddefine;



define growtree(startstat,deststat);
    ;;; Inserts information into the database till the "tree" as far as
    ;;; the destination station has grown
    vars nextevent destline;
    start(startstat);

    repeat
        next() -> nextevent;
        insertnext(nextevent);
    quitif (nextevent matches [arrived [?destline ^^deststat] at = mins from =]);
        addfuture(nextevent);
    endrepeat;

    add([finished at [^destline ^^deststat]]);
enddefine;



define traceroute()->routelist;
    ;;; assuming the tree has been grown in the database, and event is the
    ;;; arrival at the destination station, return a list of the stations
    ;;; through which the quickest route passes
    vars place lastplace time ok;

    ;;; ok will always be true
    present([finished at ?place]) -> ok;

    present([arrived ^place at ?time mins from ?lastplace]) -> ok;
    [[^place at ^time mins]] -> routelist;

    until lastplace = [start] do
        lastplace -> place;
        ;;; the next line is there for its side effects. ok will always be true
        present([arrived ^place at ?time mins from ?lastplace]) -> ok;
        [[^place at ^time mins] ^^routelist] -> routelist;
    enduntil;

enddefine;



define checkstat(station);
    ;;; simply checks that a station is present in the database
    present([[= ^^station] connects =])
        or present([= connects [= ^^station]]);
enddefine;



define tidyup();
    ;;; this removes any previous route-finding information from the
    ;;; database, in order to clear the way for a new route
    foreach [will arrive = at = mins from =] do
        remove(it);
    endforeach;
    foreach [arrived = at = mins from =] do
        remove(it);
    endforeach;
enddefine;



define route(startstat,deststat)->the_route;
    ;;; this is the overall calling program
    ;;; this sets up the database for the other routines.

    ;;; checking
    if not(checkstat(startstat)) then
        [start station ^^startstat not found] =>
        false->the_route
    endif;
    if not(checkstat(deststat)) then
        [destination station ^^deststat not found] =>
        false->the_route
    endif;

    ;;; tidy the database in preparation
    tidyup();

    ;;; do the search
    growtree(startstat,deststat);

    ;;; return the result
    ;;; Note that the database is left with all the search stuff still in it
    traceroute()->the_route

enddefine;
