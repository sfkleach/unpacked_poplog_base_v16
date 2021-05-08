/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/newpwmrasterarray.p
 > Purpose:     Create a new array suitable for use with PWM raster functions
 > Author:      Ben Rubinstein, Mar  5 1987 (see revisions)
 > Documentation:   HELP *PWMRASTERS
 > Related Files:   LIB *BITVECTORS
 */

uses bitvectors;

section $-library => newpwmrasterarray pr_depth;
section $-library$-pwmlib => newpwmrasterarray pr_depth;

lconstant pa_keys = {% bitvector_key, false, 0, false, 0, 0, 0, false %};
lconstant pa_nap  = {% false, false, 0, false, 0, 0, 0, false %};

define lconstant get_newarr_proc(depth) -> proc;
    lvars depth proc key keyid name subit swap_subit;
    lconstant notonavax = conspair(false, false);

    define lconstant swapped_sub_1(x, vec, proc);
        lvars x vec proc;
        x fi_- 1 -> x;
        proc((x fi_&&~~ 7) fi_+ 8 fi_- (x fi_&& 7), vec);
    enddefine;
    ;;;
    define lconstant uswapped_sub_1(v, x, vec, proc);
        lvars v x vec proc;
        x fi_- 1 -> x;
        proc(v, (x fi_&&~~ 7) fi_+ 8 fi_- (x fi_&& 7), vec);
    enddefine;

    define lconstant swapped_sub_2(x, vec, proc);
        lvars x vec proc;
        x fi_- 1 -> x;
        proc((x fi_&&~~ 3) fi_+ 4 fi_- (x fi_&& 3), vec);
    enddefine;
    ;;;
    define lconstant uswapped_sub_2(v, x, vec, proc);
        lvars v x vec proc;
        x fi_- 1 -> x;
        proc(v, (x fi_&&~~ 3) fi_+ 4 fi_- (x fi_&& 3), vec);
    enddefine;

    define lconstant swapped_sub_4(x, vec, proc);
        lvars x vec proc;
        proc((if x fi_&& 1 == 0 then x fi_- 1 else x fi_+ 1 endif), vec);
    enddefine;
    ;;;
    define lconstant uswapped_sub_4(v, x, vec, proc);
        lvars v x vec proc;
        proc(v, (if x fi_&& 1 == 0 then x fi_- 1 else x fi_+ 1 endif), vec);
    enddefine;

    if (subscrv(depth, pa_nap) ->> proc) == 0 then
        mishap(depth, 1, 'DEPTH MUST BE 1, 2, 4  or 8');
    elseunless proc do

        ;;; make the key
        unless (subscrv(depth, pa_keys) ->> key) do
            consword('pwmrasv' >< depth) -> name;
            name <> "_key" -> keyid;
            sysSYNTAX(keyid, 0, false);
            sysGLOBAL(keyid);
            if iskey(valof(keyid) ->> key) and class_spec(key) = depth then
                valof(keyid)
            else
                conskey(name, depth) ->> key_of_dataword(name)
            endif ->> valof(keyid) -> key;
            key -> subscrv(depth, pa_keys);
        endunless;

        ;;; check if the bits are reversed
        unless front(notonavax) do
            initbitvector(1) -> subit;
            1 -> subit(1);
            (fast_subscrs(1, subit) == 128) -> back(notonavax);
            true ->> subit -> front(notonavax);
        endunless;
        ;;; now make a newarray proc; with swapping subscriptor if required
        if depth == 8 or back(notonavax) then
            newanyarray(% key %)        ;;; bits are right way round
        else                            ;;; bits need to be swapped
            class_subscr(key) -> subit;
            if depth == 1 then
                swapped_sub_1(% subit %) -> swap_subit;
                uswapped_sub_1(% subit.updater %) -> swap_subit.updater;
            elseif depth == 2 then
                swapped_sub_2(% subit %) -> swap_subit;
                uswapped_sub_2(% subit.updater %) -> swap_subit.updater;
            elseif depth == 4 then
                swapped_sub_4(% subit %) -> swap_subit;
                uswapped_sub_4(% subit.updater %) -> swap_subit.updater;
            endif;
            newanyarray(% key, swap_subit %)
        endif ->> proc -> subscrv(depth, pa_nap);
    endif;
enddefine;

define global newpwmrasterarray(bounds, depth) -> array;
    lvars bounds depth string newaproc newbounds rx2;
    lvars x1 x2 y1 y2 bpr bbpr h si vi vec;

    if depth.isstring then
        bounds, depth -> string -> depth -> bounds;
    else
        false -> string;
    endif;

    checkinteger(depth, 1, 8);

    if bounds.destlist = 4 then
        -> y2 -> y1 -> x2 -> x1;
        unless x1.isinteger and x2.isinteger do
            mishap(x1, x2, 2, 'integer bounds needed')
        endunless;
    else
        mishap(bounds, 1, 'bit arrays must be two dimensional')
    endif;

    get_newarr_proc(depth) -> newaproc;
    x2 -> rx2;
    until erase((depth * (x2 fi_- x1 fi_+ 1)) fi_// 16) == 0 do
        x2 fi_+ 1 -> x2;
    enduntil;
    [% x1, x2, y1, y2 %] -> bounds;
    newaproc(bounds) -> array;
    rx2 -> subscrl(2, bounds);
    if string then
        depth * (x2 - x1 + 1) -> bpr;                       ;;; bits per row
        if (bpr // 8 -> bpr) > 0 then bpr + 1 -> bpr endif; ;;; bytes per row
        y2 - y1 + 1 -> h;
        bpr + erase(bpr // 2) -> bbpr;  ;;; bytes per row rounded to 16 bits
        unless string.datalength == bbpr * h do
            mishap(string.datalength, h, bpr, bbpr, 4, 'bad length for raster string');
        endunless;
        array.arrayvector -> vec;
        0 ->> si -> vi;
        repeat h times
            fast_for x1 from 1 to bpr do
                fast_subscrs(x1 fi_+ si, string)
                    -> fast_subscrs(x1 fi_+ vi, vec);
            endfor;
            vi fi_+ bpr -> vi;
            si fi_+ bbpr -> si;
        endrepeat;
    endif;
enddefine;

;;; return the depth of an array, checking that it conforms to all the
;;; requirements for use with PWM functions
;;;
define global pr_depth(array) -> depth;
    lvars array depth x1 x2 y1 y2;
    array.arrayvector.datakey.class_spec -> depth;
    unless lmember(depth, [1 2 4 8]) do
        mishap(array, depth, 2,
                'depth of arrays for use with PWM must be power of 2');
    elseunless array.boundslist.destlist == 4 do
        mishap(array, 1, 'only two dimensional arrays can be used with PWM');
    else
        -> y2 -> y1 -> x2 -> x1;
        y2 fi_- y1 fi_+ 1 -> y1;    ;;; height
        x2 fi_- x1 fi_+ 1 -> x1;    ;;; width
        if ((x1 fi_* depth) fi_// 16 -> x2) fi_> 0 then x2 + 1 -> x2 endif;
        ;;; x2 is bytes per line - now see how many entries that is
        (x2 * 16) / depth -> x2;
        unless array.arrayvector.datalength == (x2 fi_* y1) do
            mishap(array, 1, 'badly-formatted array for use with PWM');
        endunless;
    endunless;
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Apr 11 1987 - frigged for swapped bitfields on VAXen
--- Ben Rubinstein, Apr  5 1987 - added -pr_depth-
--- Ben Rubinstein, Mar 17 1987 - made to accept old-style string
--- Anthony Worrall Jan 22 1989 - changed padding to 16bit per line (cf sun)
*/
