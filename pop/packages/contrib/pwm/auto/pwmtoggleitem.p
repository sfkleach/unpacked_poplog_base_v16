/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwmtoggleitem.p
 > Purpose:     a PWM input item which can be toggled on and off
 > Author:      Ben Rubinstein, Mar 15 1987 (see revisions)
 > Documentation:   HELP *PWMITEMS
 > Related Files:   LIB *PWMCYCLEITEM
 */

uses conspwmitem;
uses pwmitemhandler;
uses pwmgfxrasterop;
uses pwm_gfxtext;
uses pwm_gfxwipearea;

section $-library => pwmtoggleitem;
section $-library$-pwmlib => pwmtoggleitem;

;;; this is the procedure (a closure of) which catches the event
;;;
define lconstant catchtoggle(ev, display_toggle_proc, item);
    lvars ev item;
    dlocal pwmgfxsurface;
    if ev.isvector and subscrv(1, ev) == "press" then
        not(item.pi_value)
    elseif ev.isvector then         ;;; release - do nothing
        return
    elseif ev then                  ;;; please return current  value
        return(item.pi_value);
    endif -> ev;        ;;; else  get new value off stack

    unless ev.not == item.pi_value.not then
        item.pi_window -> pwmgfxsurface;
        ev -> item.pi_value;
        display_toggle_proc(ev);
        (item.pi_proc)(ev);
    endunless;
enddefine;

define constant default_display_toggle(flag,x,y,w,h);
lvars flag x y w h;
dlocal pwmgfxrasterop;
        if flag then PWM_SET else PWM_CLR endif -> pwmgfxrasterop;
        pwm_gfxwipearea(x, y, w, h);
enddefine;

define constant raster_display_toggle(flag,x,y,true_ras,false_ras);
lvars flag x y w h;
dlocal pwmgfxrasterop=PWM_SRC;
dlocal pwmgfxpaintnum = 255;           ;;;maps forground colour
        pwm_gfxdumpraster(x,y,if flag then true_ras else false_ras endif);
enddefine;

lconstant fancy_button = newpwmrasterarray([1 16 1 16],1,
    consstring( 16:0,16:000,16:00,16:00,16:3F,16:FC,16:40,16:06,
                16:40,16:0A,16:4F,16:F6,16:48,16:1A,16:48,16:16,
                16:48,16:1A,16:48,16:16,16:48,16:1A,16:48,16:16,
                16:4F,16:FA,16:55,16:56,16:2A,16:AA,16:3F,16:FC,
              32));

;;; pwmtoggleitem(<window-id>, <integer:X>, <integer:Y>,
;;;                 <boolean>, <string>, <procedure>) -> <vector:Item>
;;;
;;; window, x, and y define where item goes (x and y are top left corner)
;;; boolean is the initial value
;;; string is the label
;;; procedure is called whenever value changed
;;;
define global pwmtoggleitem(window, x, y, initval, label, proc) -> item;
    lvars window x y w h b l bh bw bo bl bt initval label proc item box;
    lvars fancy=false, true_ras=false, false_ras=false, toggle_proc;
    dlocal pwmgfxrasterop, pwmgfxsurface pwmgfxfont = pwmstdfont;
    dlocal pwmgfxpaintnum = 255;           ;;;maps forground colour

    pwmstdfont.pwm_fontwidth -> w;
    pwmstdfont.pwm_fontheight -> h;
    pwmstdfont.pwm_fontbaseline -> b;

    if proc.isarray then
        proc -> false_ras;
        label -> true_ras;
        initval -> proc;
        y -> label;
        x -> initval;
        window -> y;
        -> x;
        -> window;
    elseunless proc.isprocedure then
        proc -> fancy;
        label -> proc;
        initval -> label;
        y -> initval;
        x -> y;
        window -> x;
        -> window;
    endif;

    window -> pwmgfxsurface;

    ;;; box size is BW, offset round box BO, top left of box is BL, BT
    if fancy then
        max(h,16) -> h;
        10 -> bw;
        4 -> bo;
    elseif true_ras then
        boundslist(true_ras).explode -> bh ->; -> bw ->;
        boundslist(false_ras).explode -> bl ->; -> bt ->;
        max(bh,bl) -> bh;
        max(bt,bw) -> bw;
        max(h,bh+2) -> h;
        2 -> bo;
    else
        h - 4 -> bw;
        2 -> bo;
    endif;

    w * label.datalength -> l;
    x + l + 3 + bo -> bl;
    y + 1 + bo -> bt;

    ;;; the full area covered by the item
    {% x, y, bl+bw+bo, y+h+2 %} -> box;

    conspwmitem(label, window, initval,
                [press release], 1, box, false, proc) -> item;

    if true_ras then
        raster_display_toggle(%bl,bt,true_ras,false_ras%)
    else
        default_display_toggle(%bl+2, bt+2, bw-4,bw-4%)
    endif -> toggle_proc;

    ;;; turn proc into catcher
    catchtoggle(% toggle_proc, item %) -> proc;

    ;;; and smash catcher into item (!)
    proc -> item.pi_catch;

    ;;;; assign catcher before we draw it, to make sure it doesn't overlap
    proc -> pwmitemhandler(window, [press release], 1, box);

    empty_box(x, y, l + 4 + bo * 2 + bw, h + 3);

    PWM_SET -> pwmgfxrasterop;
    pwm_gfxtext(x + 2, y + (b + h) div 2, label);

    if fancy then
        PWM_SRC -> pwmgfxrasterop;
        pwm_gfxdumpraster(bl-3,bt-4,fancy_button);
    elseunless true_ras then
        empty_box(bl, bt, bw, bw);
    endif;

    toggle_proc(initval);

enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Mar 25 1987 - added window to item record
--- Ben Rubinstein, Mar 23 1987 - made to ignore equivalent new values
*/
