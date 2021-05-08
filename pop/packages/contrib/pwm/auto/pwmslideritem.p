/* --- Copyright University of Reading 1988.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwmslideritem.p
 > Purpose:     Horizontal or Vertical slider item
 > Author:      Anthony Worrall Feb 1988 (see revisions)
 > Documentation: HELP * PWMITEMS
 > Related Files: LIB PWMITEMHANDLER, PWMTOGGLEITEM, PWMCYCLEITEM, etc
 */

uses conspwmitem;
uses pwmitemhandler;
uses pwmgfxrasterop;
uses pwm_gfxwipearea;

section $-library => pwmslideritem;
section $-library$-pwmlib => pwmslideritem;

lvars TRACKING = false;
lvars oldmousexit = erase;
lvars oldmove = erase;

define slidermousexit(ev,item,wipeproc,x,y,bx,bw,h,interactive);
    lvars ev item wipeproc x y bx bw h interactive;
    dlocal pwmgfxsurface, pwmgfxrasterop;
    PWM_NOTDST -> pwmgfxrasterop;       ;;; inverting raster-op
    item.pi_window -> pwmgfxsurface;    ;;; select the window
    oldmousexit -> pwmeventhandler(pwmgfxsurface,"mousexit");
    false -> TRACKING;
    wipeproc(x,y,bx,bw,h);
    if interactive then
        oldmove -> pwmeventhandler(pwmgfxsurface,"move");
        PWM_SET -> pwmgfxrasterop;
        {%bx,bw%} -> item.pi_value;
        pi_proc(item)(bx,bw)
    endif;
enddefine;

define slidermove(ev,proc,x,y,w,bw,horiz);
    lvars ev proc w bx bw horiz;
    if horiz then
        min(ev(3)-x,w-bw+1)
    else
        min(ev(4)-y,w-bw+1)
    endif -> bx;
    proc(max(bx,1),bw);
enddefine;

;;; this is the procedure (a closure of) which catches the event
;;;
define lconstant catchslider(ev, x, y, w, h, item, wipeproc, mousetracker, horiz,interactive);
    dlocal pwmgfxsurface, pwmgfxrasterop;
    lvars bx bw ev x y w h item proc wipeproc mousetracker proc;
    if ev == true then      ;;; please return value
        return(item.pi_value)
    elseunless ev then      ;;; assignment - pull value off stack
        -> ev;
        ;;;do not update if TRACKING this item
        if ev.isvector and not(TRACKING = item) then
            checkinteger(ev(2),1,w);
            checkinteger(ev(1),1,w-ev(2)+1);
            PWM_NOTDST -> pwmgfxrasterop;       ;;; inverting raster-op
            item.pi_window -> pwmgfxsurface;    ;;; select the window
            item.pi_value.explode -> bw -> bx;
            wipeproc(x,y,bx,bw,h);
            ev(1) -> bx; ev(2) -> bw;
            ev -> item.pi_value;
            wipeproc(x,y,bx,bw,h);
            if (item.pi_proc ->> proc).isprocedure then
                proc(bx,bw);                ;;;call user procedure
            endif;
        endif;

    elseif ev.isvector and subscrv(1, ev) == "press" then
            if TRACKING then
                pwmeventhandler(item.pi_window,"mousexit") -> proc;
                if proc then proc(false) endif;
                false -> TRACKING;
                return;
            endif;
            PWM_NOTDST -> pwmgfxrasterop;       ;;; inverting raster-op
            item.pi_window -> pwmgfxsurface;    ;;; select the window
            item.pi_value.explode -> bw -> bx;
            wipeproc(x,y,bx,bw,h);
            item -> TRACKING;
            mousetracker(x,y,w,h,bw,ev,interactive);
            pwmeventhandler(pwmgfxsurface,"mousexit") -> oldmousexit;
            unless oldmousexit then erase -> oldmousexit; endunless;
            if interactive then
                pwmeventhandler(pwmgfxsurface,"move") -> oldmove;
                unless oldmove then erase -> oldmove; endunless;
                slidermove(%item.pi_proc,x,y,w,bw,horiz%)
                -> pwmeventhandler(pwmgfxsurface,"move");
            endif;
            slidermousexit(%item,wipeproc,x,y,bx,bw,h,interactive%)
                -> pwmeventhandler(pwmgfxsurface,"mousexit");
    elseif TRACKING then    ;;;a release while tracking
        false -> TRACKING;
        PWM_NOTDST -> pwmgfxrasterop;       ;;; inverting raster-op
        item.pi_window -> pwmgfxsurface;    ;;; select the window
        oldmousexit -> pwmeventhandler(pwmgfxsurface,"mousexit");
        if interactive then
            oldmove -> pwmeventhandler(pwmgfxsurface,"move");
        endif;
        item.pi_value.explode -> bw -> bx;
        if horiz then
            min(ev(3)-x,w-bw+1)
        else
            min(ev(4)-y,w-bw+1)
        endif -> bx;
        wipeproc(x,y,bx,bw,h);
        {%bx,bw%} -> item.pi_value;
        PWM_SET -> pwmgfxrasterop;
        if (item.pi_proc ->> proc).isprocedure then
            proc(bx,bw);
        endif;
    endif;
enddefine;

define horizontal_mousetracker(x,y,w,h,bw,ev,interactive);
    pwm_trackmouse([%x+1,y+1,max(w-bw,1),1%],ev(3),y,bw,h,"bsheet",interactive);
enddefine;

define vertical_mousetracker(x,y,w,h,bw,ev,interactive);
    pwm_trackmouse([%x+1,y+1,1,max(w-bw,1)%],x,ev(4),h,bw,"bsheet",interactive);
enddefine;

define horizontal_wipearea(x,y,bx,bw,h);
    pwm_gfxwipearea(x+bx,y+1,bw,h);
enddefine;

define vertical_wipearea(x,y,bx,bw,h);
    pwm_gfxwipearea(x+1,y+bx,h,bw);
enddefine;

;;; pwmexecitem(<window-id>, <integer:X>, <integer:Y>,
;;;                 <integer:W>,  <integer:H>,
;;;                 <integer:BX>, <integer:BW>, <procedure>) -> <pwmitem>
;;;
;;; window, x, and y define where item goes (x and y are top left corner)
define global pwmslideritem(window, x, y, w, h, mark_offset, mark_size, proc,interactive) -> item;
    lvars window x y w h mark_offset mark_size proc item box interactive;
    dlocal pwmgfxrasterop, pwmgfxsurface;

    unless window.pwm_windowtype do
        mishap(window, 1, 'PWM WINDOW NEEDED');
    else
        checkinteger(x, 0, false);
        checkinteger(y, 0, false);
        checkinteger(w, 0, false);
        checkinteger(h, 0, false);
        checkinteger(mark_offset, 0, false);
        checkinteger(mark_size, 0, false);
    endunless;

    window -> pwmgfxsurface;

    unless proc.isprocedure then
        false -> interactive;
    endunless;

    ;;; the full area covered by the item

    if w > h then
        w - 1 -> w;
    else
        h - 1 -> h;
    endif;

    {% x, y, x+w+3, y+h+3 %} -> box;
    conspwmitem('slider', window, {%mark_offset,mark_size%},
                [press release], 1, box, false, proc) -> item;

    ;;; turn proc into catcher, with item as frozen value
    if w > h then
        catchslider(% x + 1, y + 1, w, h, item,
            horizontal_wipearea,horizontal_mousetracker, true,interactive%);
    else
        catchslider(% x + 1, y + 1, h, w, item,
            vertical_wipearea, vertical_mousetracker, false,interactive%);
    endif -> proc;

    ;;; and smash catcher into item
    proc -> item.pi_catch;

    ;;;; assign catcher before we draw it, to make sure it doesn't overlap
    proc -> pwmitemhandler(window, [press release], 1, box);

    empty_box(x, y, w + 4, h + 4);  ;;; draw the box (defined in LIB CONSPWMITEM)

    PWM_NOTDST -> pwmgfxrasterop;
    if w > h then
        pwm_gfxwipearea(x+1+mark_offset,y+2,mark_size,h);
    else
        pwm_gfxwipearea(x+2,y+1+mark_offset,w,mark_size);
    endif;
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
-- user procedure called when value asigned to pwmitem_valof(slider)
                                                A.D.Worrall 20 Oct 1988
-- Added interactive mode.                      A.D.Worrall Nov 1988
-- Made catcher handle release and protected against fast clicks.
                                                A.D.Worrall 25 Nov 1988
*/
