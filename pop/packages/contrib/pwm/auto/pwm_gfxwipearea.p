/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwm_gfxwipearea.p
 > Purpose:     Apply a raster-op over a rectangular area
 > Author:      Ben Rubinstein, Dec  2 1986
 > Documentation:   HELP *PWMGRAPHICS
 */

section $-library => pwm_gfxwipearea;
section $-library$-pwmlib => pwm_gfxwipearea;

uses pwmsequences;

define global pwm_gfxwipearea(h);
    lvars x y w h;
    if h then
        if h.isstring then
            -> y; -> x;
            checkinteger(x, 0, false);
            checkinteger(y, 0, false);
            length(h)*pwm_fontwidth(pwmgfxfont) -> w;
            pwm_fontheight(pwmgfxfont) -> h;
            y - pwm_fontbaseline(pwmgfxfont) -> y;
        else
            -> w -> y -> x;
            checkinteger(x, 0, false);
            checkinteger(y, 0, false);
            checkinteger(w, 0, false);
            checkinteger(h, 0, false);
        endif;
    else
        0 ->> h ->> w ->> y -> x;
    endif;
    pwmsendmessage(h, w, y, x, Pwms_gfxwipearea, pwmflushmessage);
enddefine;

endsection;
endsection;
