/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwmexecitem.p
 > Purpose:     A button which calls a procedure, inverted the while
 > Author:      Ben Rubinstein, Mar 24 1987 (see revisions)
 > Documentation: HELP * PWMITEMS
 > Related Files: LIB PWMITEMHANDLER, PWMTOGGLEITEM, PWMCYCLEITEM, etc
 */

uses conspwmitem;
uses pwmitemhandler;
uses pwmgfxrasterop;
uses pwm_gfxtext;
uses pwm_gfxwipearea;

section $-library => pwmexecitem pwmexecmenuitem pwmexec_chaining_proc;
section $-library$-pwmlib => pwmexecitem pwmexecmenuitem pwmexec_chaining_proc;

define lconstant toggle_execitem(x,y,w,h,item);
    dlocal pwmgfxsurface pwmgfxrasterop;
    unless islivepwmitem(item) then return endunless;
    PWM_NOTDST -> pwmgfxrasterop;           ;;; set r-op again in case proc changed it
    item.pi_window -> pwmgfxsurface;        ;;; select window again ditto
    pwm_gfxwipearea(x, y, w, h);            ;;; un-invert the button
    not(item.pi_value) -> item.pi_value;    ;;; unset flag to say we're finished
enddefine;

;;; this is the procedure (a closure of) which catches the event
;;;
define lconstant catchexec(ev, x, y, w, h, item);
    lvars ev item x y w;
    dlocal interrupt;
    if ev == true then      ;;; please return value
        return(item.pi_value)
    elseunless ev then      ;;; assignment - pull value off stack
        -> ev;
    elseif ev.isvector and subscrv(1, ev) == "press" then
        true -> ev;
    else
        return;             ;;; presumably a 'release' event
    endif;
    if item.pi_value        ;;; we're in the middle of doing things
    or not(ev) then         ;;; assigned false
        return
    endif;

    toggle_execitem(x,y,w,h,item);      ;;;invert item

    ;;; concat toggle_exec in front of interrupt in case a maishap or
    ;;; occurs durring the user procedure.
    toggle_execitem(%x,y,w,h,item%) <> interrupt -> interrupt;
    apply(item.pi_proc);                ;;; call the user procedure
    toggle_execitem(x,y,w,h,item);      ;;;uninvert item

enddefine;

;;; procedure to execute a procedure that does not return immediately (ie ved)
;;; from a pwmexecitem.
;;;This procedure toggles the exec item before calling the procedure and
;;; the again when the procedure exits. This means the item is NOT inverted
;;; during the procedure call.

define pwmexec_chaining_proc(x,y,w,h,item,proc);
    toggle_execitem(x,y,w,h,item);      ;;;uninvert item
    ;;; concat toggle_exec in front of interrupt in case a maishap or
    ;;; occurs durring the user procedure. Note ved resets interrupt
    toggle_execitem(%x,y,w,h,item%) <> interrupt -> interrupt;
    apply(proc);
    toggle_execitem(x,y,w,h,item);      ;;;invert item
enddefine;

define fancy_box(x,y,w,h);
lvars x,y,w,h;
    PWM_CLR -> pwmgfxrasterop;
    pwm_gfxwipearea(x, y, w, h);
    h fi_- 1 -> h; w fi_-1 -> w;
    PWM_SET -> pwmgfxrasterop;
    pwm_gfxdrawline(x fi_+ 3,           y,
                    x fi_+ w fi_- 3,    y,
                    x fi_+ w,           y fi_+ 3,
                    x fi_+ w,           y fi_+ h fi_- 3,
                    x fi_+ w fi_- 3,    y fi_+ h,
                    x fi_+ 3,           y fi_+ h,
                    x,                  y fi_+ h fi_- 3,
                    x,                  y fi_+ 3,
                    x fi_+ 3,           y,
                    9);
enddefine;

;;; pwmexecitem(<window-id>, <integer:X>, <integer:Y>,
;;;                 <string>, <procedure>) -> <pwmitem>
;;;
;;; window, x, and y define where item goes (x and y are top left corner)
;;; string is the label
;;; procedure is called whenever thing is hit
;;;
;;; alternative form
;;; pwmexecitem(window,x,y,w,h,paintproc,proc) -> item;
define anyexecitem(window, x, y, label, proc,menu) -> item;
    lvars window x y h l label proc item box menu fancy = false;
    dlocal pwmgfxrasterop, pwmgfxsurface, pwmgfxfont = pwmstdfont;
    dlocal pwmgfxpaintnum = 255;           ;;;maps forground colour

    if proc.isboolean then
        proc -> fancy;
        label -> proc;
        y -> label;
        x -> y;
        window -> x;
        -> window;
    endif;

    unless proc.isprocedure then
        mishap(proc, 1, 'PROCEDURE NEEDED');
    endunless;

    if label.isprocedure and not(label.isarray) then
        y -> h;
        x -> l;
        checkinteger(h, 0, false);
        checkinteger(l, 0, false);
        window -> y;
            -> x;
            -> window;
    elseunless label.isstring or label.isarray do
        mishap(label, 1, 'STRING OR PWMRASTER NEEDED');
    endif;

    unless window.pwm_windowtype do
        mishap(window, 1, 'PWM WINDOW NEEDED');
    else
        checkinteger(x, 0, false);
        checkinteger(y, 0, false);
    endunless;

    window -> pwmgfxsurface;
    if label.isstring then
        pwmstdfont.pwm_fontheight + 2 -> h;
        ;;; l is length in pixels of the label
        pwmstdfont.pwm_fontwidth * label.datalength + 3 -> l;
    elseif label.isarray then
        false -> fancy;
        boundslist(label).explode  + 1 -> h ->; + 1 -> l ->;
    endif;

    if fancy then l + 2 -> l endif;
    ;;; the full area covered by the item
    if menu then
        {% x, y, x+l+2, y+h+2 %};
    else
        {% x, y, x+l, y+h %}
    endif -> box;

    conspwmitem(label, window, false,
                [press release], 1, box, false, proc) -> item;

    if proc.isclosure and proc.pdpart = pwmexec_chaining_proc then
        proc(% x + 1, y + 1, l - 1 , h - 1, item %) -> proc;
        proc -> item.pi_proc;
    endif;

    ;;; turn proc into catcher, with item as frozen value
    catchexec(% x + 1, y + 1, l - 1 , h - 1, item %) -> proc;

    ;;; and smash catcher into item
    proc -> item.pi_catch;

    ;;;; assign catcher before we draw it, to make sure it doesn't overlap
    proc -> pwmitemhandler(window, [press release], 1, box);

    if fancy then
        fancy_box(x,y,l+1,h+1);
    else
        empty_box(x, y, l + 1, h + 1);  ;;; draw the box (defined in LIB CONSPWMITEM)
    endif;

    PWM_SET -> pwmgfxrasterop;          ;;; and draw the label inside it
    if menu then
        if fancy then
            pwm_gfxdrawline(x fi_+ 4,           y fi_+ h fi_+ 2,
                            x fi_+ l fi_- 2,    y fi_+ h fi_+ 2,
                            x fi_+ l fi_+ 2,    y fi_+ h fi_- 2,
                            x fi_+ l fi_+ 2,    y fi_+ 4,
                    4);
        else
            pwm_gfxdrawline(x fi_+ 1,          y fi_+ h fi_+ 2,
                            x fi_+ l fi_+ 2,   y fi_+ h fi_+ 2,
                            x fi_+ l fi_+ 2,   y fi_+ 1,
                        3);
        endif;
    endif;
    if label.isstring then
        if fancy then
            pwm_gfxtext(x + 3, y + pwmstdfont.pwm_fontbaseline + 2, label);
        else
            pwm_gfxtext(x + 2, y + pwmstdfont.pwm_fontbaseline + 2, label);
        endif;
    elseif label.isarray then
        PWM_SRC -> pwmgfxrasterop;
        pwm_gfxdumpraster(x+1,y+1,label);
    else
        label(box);
    endif;

enddefine;

false -> pdprops(anyexecitem);
global vars pwmexecitem = anyexecitem(%false%);
"pwmexecitem" -> pdprops(anyexecitem);

define global pwmexecmenuitem(fancy) with_nargs 5;
    lvars fancy proc menu;
    if fancy.isboolean then
            -> proc;
    else
        fancy -> proc;
        false -> fancy;
    endif;
    if proc.isvector then
            -> menu;
        pwm_menucall(%menu,proc,false%)<>erase -> proc;
    endif;
    anyexecitem(proc,fancy,true);
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Mar 25 1987 - added window to item record
--- Anthony Worrall Nov.   1987 - catchexec modifed to allow for death of window.
--- Anthony Worrall Jan 27 1987 - allowed label to be paint proc.
--- Anthony Worrall Oct 31 1988 - added dlocal interrupt to allow for mishaps
                                  and interrupts.
--- Anthony Worrall Dec 15 1988 - Added fancy option
--- Anthony Worrall Jan 22 1989 - Allowed label to be a pwmraster
*/
