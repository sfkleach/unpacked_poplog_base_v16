/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:    $usepop/master/C.all/lib/pwm/pwm_menucall.p
 > Purpose: display a menu and call a procedure depending on result
 > Author:  Ben Rubinstein, Dec 10 1986 (see revisions)
 > Documentation:   HELP *PWMMENUS
 > Related Files:   LIB *PWM_DISPLAYMENU
 */

section $-library => pwm_menucall;
section $-library$-pwmlib => pwm_menucall;

define global pwm_menucall(proclist, defproc);
    lvars proclist defproc len sub mresult proc;                
    if proclist.islist then
        proclist.length, subscrl
    elseif proclist.isvector then
        proclist.datalength, subscrv
    else
        mishap(proclist, 1, 'LIST OR VECTOR (of procedures) NEEDED')
    endif -> sub -> len;
    pwm_displaymenu() -> mresult;
    if mresult and mresult > 0 then
        if mresult > len then
            mishap(mresult, proclist, 2, 'no procedure for menu option')
        elseif defproc then
            chain(mresult, sub(mresult, proclist))
        else
            sub(mresult, proclist) -> proc;
            if proc.isprocedure then
                apply(proc);
            else
                apply(valof(proc));
            endif;
            mresult;
        endif
    elseif defproc then
        apply(mresult, defproc)
    else
        mresult
    endif
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- John Williams, Jun  5 1987 - made 'pwm_menucall' global
--- Anthony Worrall, Feb 7 1989 - allowed words in proclist
 */
