/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwmcycleitem.p
 > Purpose:     a PWM item with a list of values it cycles through
 > Author:      Ben Rubinstein, Mar 15 1987 (see revisions)
 > Documentation:   HELP PWMITEMS
 > Related Files:   LIB *PWMTOGGLEITEM
 */
uses pwmitemhandler;
uses conspwmitem;
uses pwmgfxrasterop;

section $-library => pwmcycleitem pwmcycle_delete pwmcycle_append;
section $-library$-pwmlib => pwmcycleitem pwmcycle_delete pwmcycle_append;

;;; (a closure of) this procedure actually catches the event
;;;
define lconstant catchcycle(ev, window, x, y, item,wipe);
    lvars ev window x y l newval values index i;
    dlocal pwmgfxsurface = window,
            pwmgfxfont = pwmstdfont,
            pwmgfxrasterop = PWM_SET;
    item.pi_value -> values;
    datalength(values)-1 -> l;
    values(l) -> index;
    if ev.isvector and subscrv(1, ev) == "release" then
        return
    elseif ev.isvector then ;;; actual press
        switchon subscrv(2,ev) =
        case 1 then
            (index + 1) mod l  -> index;
        case 2 then
            (index - 1) mod l -> index;
        else  ;;;menu call
            item.pi_name><'\t';
            fast_for i from 0 to l fi_- 1  do
                values(i) -> ev;
                ><(ev.fast_back)><'\t';
            endfor;
            .pwm_displaymenu -> newval;
            if   newval
            and  newval > 0
            then newval-1 -> index;
            endif;
        endswitchon;
        index -> values(l);
        values(index) -> ev;
    elseif ev then                  ;;; please return current  value
        return(values(index).fast_front);
    else
        -> newval;          ;;; new value
        fast_for index from 0 to l fi_- 1 do
            values(index) -> ev;
            quitif(ev.fast_front = newval);
        endfor;
        if index = l do
            mishap(newval, 1, 'attempt to assign bad value');
        endif;
        index -> values(l);
    endif;
    PWM_CLR -> pwmgfxrasterop;
    wipe();
    PWM_SET -> pwmgfxrasterop;
    pwm_gfxtext(x, y, ev.fast_back);
    if item.pi_proc then (item.pi_proc)(ev.fast_front) endif;
enddefine;

define pwmcycle_delete(item,val);
    lvars item val values index i l ev deleted = false,update = false;
    dlocal pwmgfxsurface = item.pi_window,
            pwmgfxfont = pwmstdfont,
            pwmgfxrasterop = PWM_SET;
    item.pi_value -> values;
    datalength(values)-1 -> l;
    values(l) -> index;
    l - 1 -> l;
    newanyarray([0 ^l],{%
        fast_for i from 0 to l do
            values(i) -> ev;
            if ev.fast_front = val then
                true -> deleted;
                if index = i then
                    true -> update;
                endif
            else
                ev;
            endif
        endfor;
        index mod l ->> index;
    %});
    if deleted then -> item.pi_value; else erase(); endif;
    if update then
        fast_front((item.pi_value)(index)) -> pwmitem_valof(item);
    endif;
enddefine;

;;; take a value, and return pair of (value, printable version): printable
;;; version padded with spaces to VL characters
define lconstant valprintable(o,vl);
    lvars o po l vl padding;
    if o.islist or o.isvector then
        o(1) -> po; o(2) -> o;
    else o -> po;
    endif;
    po >< '' -> po;                 ;;;convert po into prontable form
    length(po) -> l;
    if l > vl then
        substring(1,vl,po><'');   ;;;clip string only needed for pwmcycle_append
    else
        po;
        repeat (vl - l) times ><' ' endrepeat   ;;;padding
    endif -> po;
    conspair(o, po);
enddefine;

define pwmcycle_append(item,val);
    lvars item val values index i l ev update = false;
    dlocal pwmgfxsurface = item.pi_window,
            pwmgfxfont = pwmstdfont,
            pwmgfxrasterop = PWM_SET;
    item.pi_value -> values;
    datalength(values)-1 -> l;
    values(l) -> index;
    {%
        fast_for i from 0 to l fi_- 1 do
            values(i);
        endfor;
        valprintable(val,datalength(fast_back(values(0))));
        index;
    %} -> values;
    newanyarray([0 %length(values)-1%],values) -> item.pi_value;
enddefine;

lconstant cycle_ras = newpwmrasterarray([1 16 1 16],1,
        consstring(
            16:07, 16:C0, 16:0F, 16:E0, 16:18, 16:34, 16:30, 16:1C,
            16:60, 16:1C, 16:20, 16:3C, 16:00, 16:00, 16:00, 16:00,
            16:78, 16:08, 16:70, 16:0C, 16:70, 16:18, 16:58, 16:30,
            16:0F, 16:E0, 16:07, 16:C0, 16:00, 16:00, 16:00, 16:00,
            32)
        );

;;; pwmcycleitem(<window-id>, <integer:X>, <integer:Y>,
;;;                 <vector>, <string>, <procedure>) -> <vector:Item>
;;;
;;; window, x, and y define where item goes (x and y are top left corner)
;;; vector is list of values, first one the initial value
;;;         if any value in vector is a list, it is taken as [label value]
;;; string is the label
;;; procedure is called whenever value changed
;;;
define global pwmcycleitem(window, x, y, values, label, proc) -> item;
    lvars window x y w h b l c cx cy m values label cproc item box;
    lvars fancy = false;
    vars vl;
    dlocal pwmgfxrasterop, pwmgfxsurface, pwmgfxfont = pwmstdfont;
    dlocal pwmgfxpaintnum = 255;           ;;;maps forground colour

    ;;; take a value, and adjust tally of max length of printable versions
    define lconstant valmaxlen(o);
        lvars o;
        if o.islist or o.isvector then o(1) -> o endif;
        max(vl, datalength(o >< '')) -> vl;
    enddefine;

    unless label.isstring then
        proc -> fancy;
        label -> proc;
        values -> label;
        y -> values;
        x -> y;
        window -> x;
         -> window;
    endunless;
    window -> pwmgfxsurface;

    pwmstdfont.pwm_fontwidth -> w;
    pwmstdfont.pwm_fontheight -> h;
    pwmstdfont.pwm_fontbaseline -> b;

    0 -> vl; applist(values, valmaxlen);        ;;; get VL, max length of value
    {% applist(values, valprintable(%vl%)),0 %} -> values;
    newanyarray([0 %length(values)-1%],values) -> values;
    vl * w -> vl;
    w * label.datalength -> l;

    if fancy then
        l + 16 -> l;
    endif;

    x + l + vl + w + 4 -> cx;
    y + 2 + h -> cy;

    {% x, y, cx, cy %} -> box;

    ;;; make up an "item" record
    conspwmitem(label, window, values, [press release], [1 2 3], box, false, proc)
                -> item;

    ;;; turn proc into catcher
    catchcycle(% window, x + 2 + l + w, y + b + 2, item,
        pwm_gfxwipearea(%x+l+w+2,y+2,vl,h%)%) -> proc;

    ;;; and smash catcher into item (!)
    proc -> item.pi_catch;

    ;;; assign it before drawing anything in case it's illegal
    proc -> pwmitemhandler(window, [press release], [1 2 3], box);

    empty_box(x,y, cx-x, cy-y + 1);
    PWM_SET -> pwmgfxrasterop;
    pwm_gfxtext(x + 2, y + b + 2, label);
    pwm_gfxtext(x + 2 + l + w, y + b + 2, fast_back(values(0)));
    if fancy then
        PWM_SRC -> pwmgfxrasterop;
        pwm_gfxdumpraster(x+l-10,y+2,cycle_ras);
    endif;
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Mar 27 1987 - fixed buggy text drawing
--- Anthony Worrall Dec 18 1987 - added menu selection
--- Anthony Worrall Dec 31 1987 - Changed values so as stored in an array
                                - with the last value as an index.
--- Anthony Worrall Oct 24 1988 - Added fancy option
--- Anthony Worrall Nov 14 1988 - Added pwmcycle_delete and pwmcycle_append
                                - valprintable modified.
*/
