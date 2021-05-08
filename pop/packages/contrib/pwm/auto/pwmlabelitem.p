/* --- Copyright University of Reading 1987.  All rights reserved. ---------
 > File:        $usepop/lib/pwm/pwmlabelitem.p
 > Purpose:     A Label string that takes input from the keyboard
 > Author:      Anthony Worrall, Nov 4 1987
 > Documentation: HELP * PWMITEMS
 > Related Files: LIB PWMITEMHANDLER, PWMTOGGLEITEM, PWMCYCLEITEM, etc
 */
uses poppwmlib
uses conspwmitem;
uses pwmitemhandler;
uses pwmgfxrasterop;
uses pwm_gfxtext;
uses pwm_gfxwipearea;

define global constant pwmlabelcompile(item);
    compile(stringin(pwmitem_valof(item)));
enddefine;

section $-library =>
        pwmlabelitem pwmselectlabelitem pwmdeselectlabelitem
        pwmselectnextlabelitem;
section $-library$-pwmlib =>
        pwmlabelitem pwmselectlabelitem pwmdeselectlabelitem
        pwmselectnextlabelitem;

/*
Catch characters from keyboard and up date label
allowed values for input are
    true    select update label and select
    false   deselect label
    vector  { "character", c }.
If the character c is a newline or return then the procedure proc is called
if it is not false with argument item.
*/

define catchcharlabel(input,window,item,lstart_x,lstart_y,llen,user_proc);
dlocal pwmgfxsurface = window, pwmgfxfont = pwmstdfont, pwmgfxrasterop = PWM_CLR;
lvars label,c = inits(1),fw,fh,fb,overflow;
    item.pi_value -> label;
    pwm_fontwidth(pwmgfxfont) -> fw;
    pwm_fontheight(pwmgfxfont) -> fh;
    pwm_fontbaseline(pwmgfxfont) -> fb;
    if input then   ;;;selecting or selected for input;
        if input.isvector and input(1) = "character" then
            input(2) -> c(1);   ;;;force character
            switchon c(1)
            case = `\b orcase = `\^? then
                unless datalength(label) = 0 then
                    allbutlast(1,label) ->> label -> item.pi_value;
                endunless;
            case = `\r orcase = `\n then
                if user_proc then
                    if user_proc.isprocedure then
                        user_proc(item);
                    else
                        valof(user_proc)(item);
                    endif;
                    return();
                endif;
            case > 31 andcase < 127 then
                label >< c ->> label -> item.pi_value;
            endswitchon;
        endif;
        ;;;clear label area
        PWM_CLR -> pwmgfxrasterop;
        pwm_gfxwipearea(lstart_x,lstart_y,fw*llen,fh);
        ;;;get only the bit of the label to be displayed
        if (datalength(label)-llen ->> overflow) >= 0 then
            allbutfirst(overflow+1,label);
        else
            label;
        endif -> label;
        ;;;display the visible part of the label
        PWM_SET -> pwmgfxrasterop;
        pwm_gfxtext(lstart_x,lstart_y+fb,label);
        ;;; set the cursor
        pwm_gfxwipearea(lstart_x+fw*(llen+min(-1,overflow)),lstart_y,fw,fh-2);
    else    ;;; deselect;
        ;;;check if the item still exists;
        if item.pi_window then
          PWM_CLR -> pwmgfxrasterop;
          datalength(label)-llen -> overflow;
          pwm_gfxwipearea(lstart_x+fw*(llen+min(-1,overflow)),lstart_y,fw,fh-2);
        endif;
    endif;
enddefine;

/*
Procedure to allow an item to be deselected without selecting another one.
*/
define global pwmdeselectlabelitem(item);
lvars window charcatcher item;
    item.pi_window -> window;
    pwmeventhandler(window,"character") -> charcatcher;
    if charcatcher.isclosure and charcatcher.pdpart == catchcharlabel then
        ;;;deselect old labelitem
        charcatcher(false);
    endif;
    ;;;assign newcharcatcher to pwmeventhandler
    pwminputcatcher -> pwmeventhandler(window,"character");
enddefine;


/* Select a label item for input */
define global pwmselectlabelitem(item);
lvars proc window charcatcher item i;
    item.pi_proc -> proc;
    item.pi_window -> window;
    pwmeventhandler(window,"character") -> charcatcher;
    if charcatcher.isclosure and charcatcher.pdpart == catchcharlabel then
        ;;;deselect old labelitem
        charcatcher(false);
    endif;
    ;;;select new labelitem
    proc(true);
    ;;;assign newcharcatcher to pwmeventhandler
    proc -> pwmeventhandler(window,"character");
enddefine;

;;; a closure of this can be used as the procedure of a labeitem. When return
;;; is pressed then the label item next will be selected or the label item that
;;; is the value of next if next is a word.
define global pwmselectnextlabelitem(current,next);
lvars next,current;
    if next.ispwmitem then
        pwmselectlabelitem(next);
    else
        pwmselectlabelitem(valof(next));
    endif;
enddefine;

/*
The closure on this catcher not only has to catch the event but is also called
by pwmitem_valof with argument true to get the value and arguments v and false
to update the value of the item.
*/
define catchselectlabel(ev,item,user_proc);
    lvars ev,item,window,charcatcher user_proc i;
    if ev == true then          ;;; value requested
        return(item.pi_value);
    elseif ev == false then     ;;; updating value
            -> ev;
        if ev == true then      ;;;if update value is true execute proc
            if (user_proc) then
                if user_proc.isprocedure then
                    user_proc(item);
                else
                    valof(user_proc)(item);
                endif;
            endif;
        else                     ;;;update value is string
            ev><'' -> item.pi_value;
        endif;
    elseif ev.isvector and subscrv(1,ev) = "press" then
        pwmeventhandler(item.pi_window,"character") -> charcatcher;
        if charcatcher == item.pi_proc then
            pwm_displaymenu(item.pi_value><'\tClear\tStuff\t') -> i;
            switchon i =
            case 1 then
                '' -> item.pi_value;
            case 2 then
                pwm_getselection();
            endswitchon;
        endif;
    else
        return;         ;;;presumably a release
    endif;

    pwmselectlabelitem(item);
enddefine;


define global pwmlabelitem(window,x,y,nchar,prompt,label,user_proc) -> item;
lvars fh fw fb lstart llen box proc catcher user_proc;
dlocal pwmgfxrasterop pwmgfxfont = pwmstdfont, pwmgfxsurface = window;

    pwmstdfont.pwm_fontheight -> fh;
    pwmstdfont.pwm_fontwidth  -> fw;
    pwmstdfont.pwm_fontbaseline -> fb;
    ;;; position of start of label
    x+2+fw*(datalength(prompt)+1) -> lstart;
    ;;; position of end of label
    nchar*fw -> llen;

    ;;; the full area covered by the item
    {% x, y, llen+lstart+2, y+fh+2 %} -> box;


    conspwmitem(prompt, window, label><'',
                [press release], 1, box, false, false) -> item;

    ;;;character handler for this label
     catchcharlabel(%window,item,lstart,y+2,nchar,user_proc%) -> proc;
    ;;; and smash catcher into item
    proc -> item.pi_proc;

    ;;; turn proc into catcher, with item as frozen value
    catchselectlabel(%item,user_proc%) -> catcher;

    ;;; and smash catcher into item
    catcher -> item.pi_catch;

    ;;;; assign catcher before we draw it, to make sure it doesn't overlap
    catcher -> pwmitemhandler(window, [press release], 1, box);

    empty_box(x, y, lstart-x+llen + 2, fh + 3);  ;;; draw the box (defined in LIB CONSPWMITEM)
    PWM_SET -> pwmgfxrasterop;      ;;; and draw the label inside it
    pwm_gfxtext(x + 2, y + fb + 2, prompt);
    ;;; update label
    pwmselectlabelitem(item);
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
Added pwmlabelcompile                                           ADW
Added selectlabelitem and deselectlabelitem                     ADW 12/8/88
Added check that item still exists when trying to deselect it.  ADW 26/10/88
Added menu for selected label item.             ADW 30/3/89
Moved the wipe area used to clear label down one pixel.         ADW 17/8/89
*/
