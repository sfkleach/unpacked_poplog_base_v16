/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:        $usepop/master/C.all/lib/pwm/pwm_displaymenu.p
 > Purpose:     Display a menu on screen and get the user's choice
 > Author:      Ben Rubinstein, Dec  2 1986
 > Documentation:   HELP *PWMMENUS
 > Related Files:   LIB *PWM_DEFINEMENU
 */

section $-library => pwm_displayprompt;
section $-library$-pwmlib => pwm_displayprompt;

uses pwmsequences;

;;; pwm_displayprompt(<string>)

uses format_print;
define pad_string(message) -> message -> width;
lvars i j l message directive width = 0;

    1 -> i;
    [%
        while(locchar(`\n`, i, message) ->> j) do
            j - i -> l;
            substring(i,l,message);
            if l>width then l -> width; endif;
            j+1 -> i;
        endwhile;
        length(message)->j;
        if i <= j then
            substring(i,j-i+1,message);
        endif;
    %]  -> message;

    '~'><width><'A ' -> directive;
    [%
        for l in message do
            format_string(directive,[^l]);
        endfor;
    %] -> message;

    width + 1 -> width;
    width*length(message) -> l;
    consstring(applist(message,explode),l) -> message;

enddefine;

define global pwm_displayprompt(text);
    lvars width,text,c1,c2,opt;
    unless text.isstring then
        mishap('String required',[^text]);
    endunless;
    pad_string(text) -> text -> width;
    getpwmreport(text,width,Pwms_displayprompt,Pwms_repprompt) -> opt;
    if opt == 2 then
        -> c2; -> c1;
        consstring(c1+` `,c2+` `,2);
    else
        mishap('Invalid result from prompt',[^opt]);
    endif;
enddefine;

endsection;
endsection;
