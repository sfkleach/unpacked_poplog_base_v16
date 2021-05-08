/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwmradioitem.p
 > Purpose:     "Radio-button" style items for PWM gfx windows
 > Author:      Ben Rubinstein, Mar 16 1987 (see revisions)
 > Documentation:   HELP *PWMITEMS
 > Related Files:   LIB * PWMTOGGLEITEM *PWMCYCLEITEM
 */

uses conspwmitem;
uses pwmitemhandler;
uses pwmgfxrasterop;
uses pwm_gfxtext;
uses pwm_gfxwipearea;

section $-library => pwmradioitem;
section $-library$-pwmlib => pwmradioitem;

define lconstant catchradio(ev, x, w, bo, curval, item);
    lvars ev x y w curval item values val;
    dlocal pwmgfxsurface, pwmgfxrasterop;
    if ev.isvector and subscrv(1, ev) == "press" then
        subscrv(4, ev) -> ev;
        for val in item.pi_value do
            if ev fi_> fast_back(val) then
                val -> ev;
                quitloop;
            endif;
        endfor;
        if ev.isinteger then return else ev.fast_front endif;
    elseif ev.isvector then         ;;; release - do nothing
        return
    elseif ev then                  ;;; please return current  value
        return(curval.cont);
    endif -> ev;    ;;; else  get new value off stack
    if ev = curval.cont then return endif;

    for val in item.pi_value do
        if val.fast_front = ev then false -> val; quitloop; endif;
    endfor;
    if val then mishap(ev, 1, 'attempt to assign bad value to radio item') endif;

    item.pi_window -> pwmgfxsurface;
    for val in item.pi_value do
        if val.fast_front = curval.cont then
            PWM_CLR -> pwmgfxrasterop;
            pwm_gfxwipearea(x, val.fast_back+bo, w, w);
        elseif val.fast_front = ev then
            PWM_SET -> pwmgfxrasterop;
            pwm_gfxwipearea(x, val.fast_back+bo, w, w);
        endif;
    endfor;
    (item.pi_proc)(ev ->> curval.cont);
enddefine;

lconstant fancy_button = newpwmrasterarray([1 16 1 16],1,
    consstring( 16:0,16:000,16:00,16:00,16:3F,16:FC,16:40,16:06,
                16:40,16:0A,16:4F,16:F6,16:48,16:1A,16:48,16:16,
                16:48,16:1A,16:48,16:16,16:48,16:1A,16:48,16:16,
                16:4F,16:FA,16:55,16:56,16:2A,16:AA,16:3F,16:FC,
              32));

define global pwmradioitem(window, x, y, initval, values, label, proc) -> item;
    lvars window x y label initval values proc item fancy=false;
    lvars fw fh fb h aw ah l bw bl vp va bt box;
    lvars bo = 2;
    dlocal pwmgfxrasterop,
            pwmgfxsurface,
            pwmalwaysflush = false,
            pwmgfxfont = pwmstdfont;
    dlocal pwmgfxpaintnum = 255;           ;;;maps forground colour

    ;;; take a value, and adjust tally of max length of printable versions
    define lconstant valmaxlen(o);
        lvars o;
        if o.islist or o.isvector then o(1) -> o endif;
        max(aw, datalength(o >< '')) -> aw;
    enddefine;

    if proc.isboolean then
        proc -> fancy;
        label -> proc;
        values -> label;
        initval -> values;
        y -> initval;
        x -> y;
        window -> x;
         -> window;
    endif;
    window -> pwmgfxsurface;

    pwmstdfont.pwm_fontwidth -> fw;
    pwmstdfont.pwm_fontheight -> fh;
    pwmstdfont.pwm_fontbaseline -> fb;

    if fancy then
        10 -> bw;
        4 -> bo;
        max(fh,bw+6) -> h;
    else
        fh -> h;
        fh - 4 -> bw;
    endif;

    applist(0 -> aw, values, valmaxlen);
    (aw * fw) + bw + (bo * 2) -> aw;
    values.length * h + 4 -> ah;
    if label then
        max(aw, label.datalength * fw) -> aw;
        ah + 3 + fh -> ah;
    endif;
    x + 2 + aw - bo - bw -> bl;
    {% x, y, x + aw + 4, y + ah %} -> box;
    ;;; make an item, although we can't fill in all the slots yet, so that
    ;;; we can check the space is available.
    conspwmitem(label, window, false,
                [press release], 1, box, false, proc) -> item;

    ;;; turn proc into catcher
    catchradio(% bl + 2, bw - 4, bo+2, consref(initval), item %) -> proc;
    ;;; and smash catcher into item
    proc -> item.pi_catch;
    ;;; assign catcher before we draw it, to make sure it doesn't overlap
    proc -> pwmitemhandler(window, [press release], 1, box);

    empty_box(x, y, aw + 4, ah);
    y + 2 -> y;
    if label then
        PWM_SET -> pwmgfxrasterop;
        pwm_gfxtext(x + 2, y + fb, label);
        y + fh + 3 -> y;
    endif;
    [] -> item.pi_value;
    for va in values do
        if va.islist then va.hd, va.tl.hd -> va else va endif -> vp;
        PWM_SET -> pwmgfxrasterop;
        pwm_gfxtext(x + 2, y +fb, vp);
        if fancy then
            PWM_SRC -> pwmgfxrasterop;
            pwm_gfxdumpraster(bl-3,y+bo-4,fancy_button);
        else
            empty_box(bl, y + bo, bw, bw);
        endif;
        if va = initval then
            PWM_SET -> pwmgfxrasterop;
            pwm_gfxwipearea(bl + 2, y + bo + 2, bw - 4, bw - 4);
        endif;
        conspair(va, y) :: item.pi_value -> item.pi_value;
        y + h -> y;
    endfor;
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Mar 25 1987 - added window to item record
*/
