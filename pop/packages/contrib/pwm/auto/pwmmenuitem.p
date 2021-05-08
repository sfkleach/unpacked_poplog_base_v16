/* --- Copyright University of Reading 1987.  All rights reserved. ---------
 > File:        $usepop/lib/pwm/pwmlabelitem.p
 > Purpose:     Define a box in which a menu other tahn the default is used
 > Author:      Anthony Worrall, Dec 20 1987
 > Documentation: HELP * PWMITEMS
 > Related Files: LIB PWMITEMHANDLER, PWMTOGGLEITEM, PWMCYCLEITEM, etc
 */
uses poppwmlib
uses conspwmitem;
uses pwmitemhandler;

section $-library => pwmmenuitem;
section $-library$-pwmlib => pwmmenuitem;

/*
The closure on this catcher not only has to catch the event but is also called
by pwmitem_valof with argument true to get the value and arguments v and false
to update the value of the item.
*/
define catchmenu(ev,item);
    lvars ev,item,window,charcatcher proc;
    if ev == true then          ;;; value requested
        return(item.pi_value);
    elseif ev == false then     ;;; updating value
            -> ev;
        unless ev.isstring do
            mishap('String Needed',[^ev]);
        endunless;
        ev -> item.pi_value;
        return;
    elseunless ev.isvector and subscrv(1,ev) = "press" do
        return;         ;;;presumably a release
    endif;
    pwm_menucall(item.pi_value,item.pi_proc,false)->;
enddefine;


define global pwmmenuitem(window,box,menu,procs) -> item;
lvars box procs catcher itemmenu=false;
dlocal pwmgfxsurface;


    ;;; the full area covered by the item
    if box.ispwmitem then
        box.pi_area -> box;
        true -> itemmenu;
    else
         box -> h;
         window -> w;
         -> y;
         -> x;
         -> window;
        {% x, y, x+w, y+h%} -> box;
    endif;

    window -> pwmgfxsurface;

    conspwmitem("menu", window, menu,
                [press release], 3, box, false, procs) -> item;

    ;;; turn proc into catcher, with item as frozen value
    catchmenu(%item%) -> catcher;

    ;;; and smash catcher into item
    catcher -> item.pi_catch;

    ;;;; assign catcher before we draw it, to make sure it doesn't overlap
    catcher -> pwmitemhandler(window, [press release], 3, box);

    unless itemmenu then
        empty_box(x, y, w, h);  ;;; draw the box (defined in LIB CONSPWMITEM)
    endunless
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
*/
