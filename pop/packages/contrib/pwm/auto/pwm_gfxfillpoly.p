/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwm_gfxfillpoly.p
 > Purpose:     Fill a closed polygon (Based on pwm_gfxdrawline)
 > Author:      Anthony Worrall Sept 12 1988
 > Documentation:   HELP *PWMGRAPHICS
 */

section $-library => pwm_gfxfillpoly;
section $-library$-pwmlib  => pwm_gfxfillpoly;

uses pwmsequences;

define global pwm_gfxfillpoly(coords);
    lvars coords tcoords, x = false, y = false;
    if coords.islist then
        (coords.length) -> tcoords;
        if coords.hd.isinteger then
            tcoords / 2 -> tcoords;
        endif;
        unless tcoords.isinteger do
            mishap(coords, 1, 'odd number of coordinates');
        endunless;
        dl(coords);
    else
        coords -> tcoords;
    endif;
    until tcoords == 0 do
        tcoords - (min(tcoords, 20) ->> coords) -> tcoords;
            pwmsendmessage(Pwms_gfxpolystart, false);
            if x and y then pwmsendmessage(y, x, Pwms_gfxpolypoint, false) endif;
            repeat coords - 1 times
                -> y;
                unless y.isinteger do y(1), y(2) -> y; endunless -> x;
                pwmsendmessage(y, x, Pwms_gfxpolypoint, false);
            endrepeat;
            -> y;
            unless y.isinteger do y(1), y(2) -> y; endunless -> x;
            pwmsendmessage(y, x, Pwms_gfxpolyend, pwmflushmessage);
    enduntil
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
*/
