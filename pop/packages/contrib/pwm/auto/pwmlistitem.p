/* --- Copyright University of Reading 1988.  All rights reserved. ---------
 > File:        pwmlistitem.p
 > Purpose:     a PWM item with a list of values
 > Author:      Anthony Worrall, Nov 14 1988 (see revisions)
 > Documentation:   HELP PWMITEMS
 > Related Files:   LIB *PWMCYCLEITEM  LIB * PWMSLIDERITEM

         CONTENTS - (Use <ENTER> gd to access required procedure)

 define lconstant display_slider(window,x,y,rows,offset,nvals);
 define lconstant displaylist(window,x,y,width,rows,values,offset,nvals);
 define lconstant valprintable(o,vl);
 define lconstant catchlist(ev, window, x, y, width, rows, item);
 define global pwmlist_delete(item,val);
 define global pwmlist_append(item,val);
 define global pwmlist_contents(item);
 define updaterof global pwmlist_contents(new_values, item);
 define global pwmlistitem(window, x, y, values, label, cols, rows,proc) -> item;

 */
uses pwmitemhandler;
uses conspwmitem;
uses pwmgfxrasterop;

section $-library => pwmlistitem pwmlist_delete pwmlist_append pwmlist_contents;
section $-library$-pwmlib => pwmlistitem pwmlist_delete pwmlist_append pwmlist_contents;

lvars TRACKING=false, oldmousexit=erase, oldmove = erase;

define lconstant display_slider(window,x,y,rows,offset,nvals);

    lvars window x y values s bs bo nvals rows fh fw offset;
    dlocal pwmgfxsurface = window,
         pwmgfxfont = pwmstdfont,
         pwmgfxrasterop = PWM_NOTDST;

    pwmgfxfont.pwm_fontheight -> fh;
    pwmgfxfont.pwm_fontwidth -> fw;
    ( rows - 2 ) * fh -> s;
    if nvals = 0 then s else min(s,max(1,round(s*rows/nvals))) endif; -> bs;
    if nvals = rows
    then 0
    else min(max(round((s-bs)*offset/(nvals - rows)),0),s-bs)
    endif -> bo;

    pwm_gfxwipearea(x-2*fw,y+fh+bo,2*fw-3,bs);
enddefine;

define lconstant displaylist(window,x,y,width,rows,values,offset,nvals);
    lvars window x y values index i r nvals width rows fh fb offset;
    dlocal pwmgfxsurface = window,
         pwmgfxfont = pwmstdfont,
         pwmgfxrasterop = PWM_CLR;

    pwmgfxfont.pwm_fontheight -> fh;
    pwmgfxfont.pwm_fontbaseline -> fb;

    ;;;clear area;
    pwm_gfxwipearea(x,y,width,fh*rows);
    PWM_SET -> pwmgfxrasterop;

    values(nvals) -> index;

    min(rows,nvals)-1 -> r;
    for i from 0 to r do
        pwm_gfxtext(x, y + fb + i*fh, fast_back(values(i + offset)));
    endfor;

    if index >= offset and index < offset+rows then
        PWM_NOTDST -> pwmgfxrasterop;
        pwm_gfxwipearea(x,y+(index-offset)*fh,width,fh);
    endif;

enddefine;

;;; take a value, and return pair of (value, printable version): printable
;;; version padded with spaces to VL characters
define lconstant valprintable(o,vl);
    lvars o po vl l;
    if o.islist or o.isvector then
        o(1) -> po; o(2) -> o;
    else o -> po;
    endif;
    po >< '' -> po;                 ;;;convert po into printable form
    length(po) -> l;
    if l > vl then
        substring(1,vl,po><'');   ;;;clip string only needed for pwmcycle_append
    else
        po;
        repeat (vl - l) times ><' ' endrepeat   ;;;padding
    endif -> po;
    conspair(o, po);
enddefine;

;;; (a closure of) this procedure actually catches the event
;;;
define lconstant catchlist(ev, window, x, y, width, rows, item);
    lvars ev window x y newval values index i nvals width rows fh fw fb offset;
    lvars s bs bo wipeproc update;
    dlocal pwmgfxsurface = window,
         pwmgfxfont = pwmstdfont,
         pwmgfxrasterop = PWM_SET;

    define pwmlist_mousexit(ev,window,wipeproc);
        dlocal pwmgfxsurface = window, pwmgfxrasterop = PWM_NOTDST;
        lvars wipeproc window ev;
        wipeproc();
        oldmousexit -> pwmeventhandler(window,"mousexit");
        if TRACKING = "SLIDER" then
            oldmove -> pwmeventhandler(window,"move");
        endif;
        false -> TRACKING;
    enddefine;

    define display_move(ev,window,x,y,width,rows,values,offset,nvals,s,bs);
        lvars ev,window,x,y,width,rows,values,offset,nvals,s,bs,bo;
        ev(4) - y - fh -> bo;
        round(bo * ( nvals - rows ) / ( s - bs )) -> offset;
        max(0,min(offset,max(nvals-rows,0))) -> offset;
        displaylist(window,x,y,width,rows,values,offset,nvals);
    enddefine;

    pwmgfxfont.pwm_fontwidth -> fw;
    pwmgfxfont.pwm_fontheight -> fh;
    pwmgfxfont.pwm_fontbaseline-> fb;

    item.pi_value -> values;
    datalength(values)-2 -> nvals;
    values(nvals) -> index;
    values(nvals+1) -> offset;

    switchon ev
    case .isvector then
        if fast_subscrv(1, ev) == "release" then    ;;;handle release event
            if TRACKING then
                ;;;restore old mose exit handler for both SELECTION and SLIDER
                oldmousexit -> pwmeventhandler(window,"mousexit");
                switchon TRACKING =
                case "SELECT" then                  ;;; handle selection
                    false -> TRACKING;   ;;;tracking finished
                    (ev(4) - y + fh - fb ) div fh -> i;  ;;;calculate nearest line
                    max(min(i,nvals-1),0)  -> i;
                    PWM_NOTDST -> pwmgfxrasterop;           ;;; mark line
                    pwm_gfxwipearea(x,y+i*fh,width,fh);
                    i + offset ->> index ->  values(nvals); ;;;store new index
                    if (item.pi_proc) then                  ;;;cal user proc
                        (item.pi_proc)(fast_front(values(index)));
                    endif;
                case "SLIDER" then                      ;;;handle slider
                    false -> TRACKING;   ;;;tracking finished
                    ev(4) - y - fh -> bo;               ;;;box offset
                    ( rows - 2 ) * fh -> s;             ;;;size of whole slider
                    ;;;size of box
                    min(s-1,max(1,round(s*rows/nvals))) -> bs;
                    ;;;calculate first visible value
                    round(bo * ( nvals - rows ) / ( s - bs )) -> offset;
                    ;;; clip between 0 and nvals
                    max(0,min(offset,max(nvals-rows,0))) -> offset;
                    offset -> values(nvals+1);                      ;;;store offset
                    display_slider(window,x,y,rows,offset,nvals);   ;;;update slider
                    ;;; update displayed text
                    displaylist(window,x,y,width,rows,values,offset,nvals);
                    oldmove -> pwmeventhandler(window,"move");  ;;;restore old move handler
                endswitchon;
            endif;
        else                                ;;;handle PRESS event
            if TRACKING then
                ;;;rapid clicking of mouse loses release events !!!!
                ;;;simulate a mouse exit to reset everything
                pwmeventhandler(window,"mousexit")(false);
                TRACKING =>
                return;
            endif;
            if ev(4) < y-2 then         ;;;on label display selcted value
                unless i >= offset and i < offset+rows then
                    ;;;make index the top line unless it is too near the end
                    display_slider(window,x,y,rows,offset,nvals);
                    min(index, max(nvals-rows,0))  ->> offset -> values(nvals+1);
                    displaylist(window,x,y,width,rows,values,offset,nvals);
                    display_slider(window,x,y,rows,offset,nvals);
                endunless;
                return
                ;;; SELECTION
            elseif ev(3) > x then           ;;;selection
                unless nvals = 0 then       ;;;if no values then nothing to select
                    PWM_NOTDST -> pwmgfxrasterop;
                    ;;; procedure to restore screen if the mouse exit with button down
                    if index >= offset and index < offset+rows then
                        pwm_gfxwipearea(%x,y+(index-offset)*fh,width,fh%);
                    else
                        identfn
                    endif -> wipeproc;
                    wipeproc();                 ;;;clear the selection
                    ;;;store mouse exit handler
                    pwmeventhandler(window,"mousexit") -> oldmousexit;
                    ;;; eventhandler can return false but will not except false
                    unless oldmousexit then erase -> oldmousexit; endunless;
                    ;;; store exit handler for SELECT
                    "SELECT"-> TRACKING;        ;;;note tracking a SELECTION
                    pwmlist_mousexit(%window,wipeproc%)
                        -> pwmeventhandler(window,"mousexit");
                    ;;; start tracking
                    pwm_trackmouse([%x,y,1,max((min(rows,nvals)-1)*fh,1)%],x,ev(4),width,fh,"bsheet",false);
                endunless;

                ;;;SCROLL TEXT DOWN BUTTON
            elseif ev(4) < y+fh then
                until (max((offset - 1) ,0) ->> i) = offset do
                    display_slider(window,x,y,rows,offset,nvals);
                    i -> offset;
                    PWM_SRC -> pwmgfxrasterop;
                    pwm_gfxcopyraster(window,x,y,width,(rows-1)*fh,PWM_CLR,
                        window,x,y+fh);
                    PWM_SET -> pwmgfxrasterop;
                    pwm_gfxtext(x,y+fb,(values(offset).fast_back));
                    if offset = index then
                        PWM_NOTDST -> pwmgfxrasterop;
                        pwm_gfxwipearea(x,y,width,fh);
                    endif;
                    display_slider(window,x,y,rows,offset,nvals);
                    quitif(sys_input_waiting(poprawdevin))
                enduntil;

                ;;;SCROLL TEXT DOWN BUTTON
            elseif ev(4) > y+(rows-1)*fh then            ;;;scroll text up

                until (min(offset+1,max(nvals-rows,0))->>i) = offset do
                    display_slider(window,x,y,rows,offset,nvals);
                    i -> offset;
                    PWM_SRC -> pwmgfxrasterop;
                    pwm_gfxcopyraster(window,x,y+fh,width,(rows-1)*fh,PWM_CLR,
                        window,x,y);
                    offset + rows - 1 -> i;
                    PWM_SET -> pwmgfxrasterop;
                    pwm_gfxtext(x,y+(rows-1)*fh+fb,(values(i).fast_back));
                    if i = index then
                        PWM_NOTDST -> pwmgfxrasterop;
                        pwm_gfxwipearea(x,y+(rows-1)*fh,width,fh);
                    endif;
                    display_slider(window,x,y,rows,offset,nvals);
                    quitif(sys_input_waiting(poprawdevin));
                enduntil;
            else                                ;;;slider
                if nvals > rows then
                    ( rows - 2 ) * fh -> s;
                    min(s-1,max(1,round(s*rows/nvals))) -> bs;
                    display_slider(window,x,y,rows,offset,nvals);
                    pwmeventhandler(window,"mousexit") -> oldmousexit;
                    unless oldmousexit then erase -> oldmousexit; endunless;
                    pwmeventhandler(window,"move") -> oldmove;
                    unless oldmove then erase -> oldmove; endunless;
                    "SLIDER" -> TRACKING;
                    pwmlist_mousexit(%window,
                         displaylist(%window,x,y,width,rows,values,offset,nvals%)
                         <>display_slider(%window,x,y,rows,offset,nvals%)
                         %) -> pwmeventhandler(window,"mousexit");
                    display_move(%window,x,y,width,rows,values,offset,nvals,s,bs%)
                        -> pwmeventhandler(window,"move");
                    pwm_trackmouse([%x-2*fw,y+fh,1,s-bs%],x-2*fw,ev(4),2*fw-3,bs,"bsheet",true);
                endif;
            endif;
            index -> values(nvals);
            offset -> values(nvals+1);
            ;;;END OF PRESS HANDLER
        endif;
    case = "DELETE" then
            -> newval;
        false -> update;
        display_slider(window,x,y,rows,offset,nvals);
        {%
             nvals - 1 -> nvals;
             fast_for i from 0 to nvals do
                 values(i) -> ev;
                 if ev.fast_front = newval then
                     if i >= offset and i < offset+rows then
                         true -> update;
                     endif;
                     if index > i then index - 1 -> index;
                     elseif index = i then -1 -> index
                     endif;
                 else
                     ev;
                 endif
             endfor;
             index;
             0,
             %} -> values;
        length(values) - 2 -> nvals;
        newanyarray([0 %nvals+1%],values) ->> values -> item.pi_value;
        min(offset, max(nvals-rows,0))  ->> offset -> values(nvals+1);
        if update then
            displaylist(window,x,y,width,rows,values,offset,nvals);
        endif;
        display_slider(window,x,y,rows,offset,nvals);

    case = "APPEND" then
            -> newval;
        display_slider(window,x,y,rows,offset,nvals);
        newanyarray([0 ^(nvals+2)], {%
                 fast_for i from 0 to nvals fi_-1 do
                     values(i);
                 endfor;
                 valprintable(newval,width div fw);
                 index;
                 offset,
                 %}) ->> values -> item.pi_value;
        if nvals < rows then
            displaylist(window,x,y,width,rows,values,0,nvals+1);
        endif;
        display_slider(window,x,y,rows,offset,nvals+1);

    case = "UPDATE_CONTENTS" then
            -> values;
        display_slider(window,x,y,rows,offset,nvals);
        {%  if values.islist
             then applist
             else appdata
             endif(values, valprintable(%width div fw%)),-1,0
        %} -> values;
        length(values) - 2 -> nvals;
        newanyarray([0 %nvals+1%],values) ->> values -> item.pi_value;
        0 -> offset;
        displaylist(window,x,y,width,rows,values,offset,nvals);
        display_slider(window,x,y,rows,offset,nvals);

    case = true then                  ;;; please return current  value
        if index = -1 then
            return(undef);
        else
            return(values(index).fast_front);
        endif;
    else
            -> newval;          ;;; new value
        if newval = undef then
            if index >= offset and index < offset+rows then
                PWM_NOTDST -> pwmgfxrasterop;
                pwm_gfxwipearea(x,y+(index-offset)*fh,width,fh);
            endif;
            -1 -> values(nvals);
        else
            fast_for i from 0 to nvals fi_- 1 do
                values(i) -> ev;
            quitif(ev.fast_front = newval);
            endfor;
            if i= nvals do
                mishap(newval, 1, 'attempt to assign bad value');
            endif;
            PWM_NOTDST -> pwmgfxrasterop;
            ;;; set new selection
            i -> values(nvals);
            if i >= offset and i < offset+rows then
                ;;;clear old selection;
                if index >= offset and index < offset+rows then
                    pwm_gfxwipearea(x,y+(index-offset)*fh,width,fh);
                endif;
                pwm_gfxwipearea(x,y+(i-offset)*fh,width,fh);
            else
                display_slider(window,x,y,rows,offset,nvals);
                ;;;make index the top line unless it is too near the end
                min(i, max(nvals-rows,0))  ->> offset -> values(nvals+1);
                displaylist(window,x,y,width,rows,values,offset,nvals);
                display_slider(window,x,y,rows,offset,nvals);
            endif;
            if (item.pi_proc) then
                (item.pi_proc)(newval);
            endif;
        endif;
    endswitchon;
enddefine;

define global pwmlist_delete(item,val);
    lvars item val;
    (item.pi_catch)(val,"DELETE");
enddefine;

define global pwmlist_append(item,val);
    lvars item val;
    (item.pi_catch)(val,"APPEND");
enddefine;

;;; return contents list of item. A list of lists, where the head of
;;; the list is the displayed item and the tail is the value passed to
;;; the procedure.
define global pwmlist_contents(item);
  lvars i value_array item  contents_list nvals fr bk;
  item.pi_value -> value_array;
  datalength(value_array)-2 -> nvals;
  [% fast_for i from 0 to nvals fi_-1 do
       [^(fast_back(value_array(i))) ^(fast_front(value_array(i)))];
     endfor;
     %];
enddefine;

define updaterof global pwmlist_contents(new_values, item);
  lvars new_values, item;
    (item.pi_catch)(new_values,"UPDATE_CONTENTS");
enddefine;


;;; pwmlistitem(<window-id>, <integer:X>, <integer:Y>,
;;;                 <vector>, <string>, <procedure>) -> <vector:Item>
;;;
;;; window, x, and y define where item goes (x and y are top left corner)
;;; vector is list of values, first one the initial value
;;;         if any value in vector is a list, it is taken as [label value]
;;; string is the label
;;; procedure is called whenever value changed
;;;
define global pwmlistitem(window, x, y, values, label, cols, rows,proc) -> item;
    lvars window x y w h b cols rows cx cy i label values item box proc;
    dlocal pwmgfxrasterop, pwmgfxsurface, pwmgfxfont = pwmstdfont;

    window -> pwmgfxsurface;

    pwmstdfont.pwm_fontwidth -> w;
    pwmstdfont.pwm_fontheight -> h;
    pwmstdfont.pwm_fontbaseline -> b;

    {%  if values.islist
        then applist
        else appdata
        endif(values, valprintable(%cols%)),-1,0 %} -> values;
    newanyarray([0 %length(values)-1%],values) -> values;

    max(cols,length(label)-2) -> cols;
    cols * w -> cols;

    x + cols + 4 + 2*w -> cx;
    y + 4 + rows*h+h -> cy;

    {% x, y, cx, cy %} -> box;

    ;;; make up an "item" record
    conspwmitem(label, window, values, [press release], [1], box, false, proc)
                -> item;

    ;;; turn proc into catcher
    catchlist(% window, x +2*w+2, y + 3 + h, cols, rows, item %) -> proc;

    ;;; and smash catcher into item (!)
    proc -> item.pi_catch;

    ;;; assign it before drawing anything in case it's illegal
    proc -> pwmitemhandler(window, [press release], [1], box);

    empty_box(x,y, cx-x, cy-y + 1);
    PWM_SET -> pwmgfxrasterop;
    pwm_gfxtext(x+2,y+2+b,label);
    y + 1 + h -> y;
    pwm_gfxdrawline(x,y,cx-1,y,2);
    pwm_gfxdrawline(x+2*w,y,x+2*w,cy-1,2);

    pwm_gfxdrawline(x,y+h,x+2*w,y+h,2);
    pwm_gfxfillpoly(x+3,y+h-2,x+w+1,y+2,x+2*w-1,y+h-2,3);

    pwm_gfxdrawline(x,cy-h,x+2*w,cy-h,2);
    pwm_gfxfillpoly(x+3,cy-h+3,x+w+1,cy-2,x+2*w-1,cy-h+3,3);

    y + 2 -> y;
    x + 2 + 2*w -> x;
    display_slider(window,x,y,rows,0,length(values)-2);
    min(rows - 1,length(values)-3) -> rows;
    for i from 0 to rows do
        pwm_gfxtext(x, y + b + i*h, fast_back(values(i)));
    endfor;

enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
Made scroll buttons keep scrolling untill button released.       ADW 30/1/90
Added pwmlist_contents(item) and updaterof pwmlist_contents      RMB 21/12/88
Allowed values to be given in vector (or any subscriptable
data structure) as well as a list.                               ADW 17/1/89
*/
