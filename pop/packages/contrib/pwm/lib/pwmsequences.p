/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:           $usepop/master/C.all/lib/pwm/pwmsequences.p
 > Purpose:        Define escape sequences for communicating with PWM
 > Author:         Ben Rubinstein, Dec  2 1986 (see revisions)
 */

section $-library;
section $-library$-pwmlib;

constant
    Pwms_idresult       =   '\^[^ZI%it',
    Pwms_numresult      =   '\^[^ZD%dt',

    Pwms_getcomswidth   =   '\^[{Zw\(170)\(85)t',
    Pwms_repcomswidth   =   '\^[^Zw%c%c%dt',
    Pwms_setcomswidth   =   '\^[{ZW%dt',

    Pwmsexposewindow    =   '\^[{WE%it',
    Pwmshidewindow      =   '\^[{WH%it',
    Pwmsmovewindow      =   '\^[{WM%it',
    Pwmsresizewindow    =   '\^[{WS%it',
    Pwmsrefreshwindow   =   '\^[{WR%it',

    Pwms_getwinlocat    =   '\^[{AL%it',
    Pwms_setwinlocat    =   '\^[{FL%i%d;%dt',
    Pwms_repwinlocat    =   '\^[^FL%i%d;%dt',

    Pwms_geticonlocat   =   '\^[{Al%it',
    Pwms_seticonlocat   =   '\^[{Fl%i%d;%dt',
    Pwms_repiconlocat   =   '\^[^Fl%i%d;%dt',

    Pwms_getexternsize  =   '\^[{AS%it',
    Pwms_setexternsize  =   '\^[{FS%i%d;%dt',
    Pwms_repexternsize  =   '\^[^UR%i%d;%dt',

    Pwms_getselection   =   '\^[{Aht',
    Pwms_setselection   =   '\^[{TS%i%d;%d;%d;%dt',

    Pwms_setwincursor   =   '\^[{Fc%i%it',
    Pwms_killcursor     =   '\^[{Kc%it',

    Pwms_definemenu     =   '\^[}Nm%s\^[\\',
    Pwms_displaymenu    =   '\^[{Um%i%i%d;%dt',
    Pwms_dispnewmenu    =   '\^[}Um%i%d;%d;%s\^[\\',
    Pwms_menuresult     =   '\^[^iM%it',

    Pwms_displayprompt  =   '\^[}Up%d;%s\^[\\',
    Pwms_repprompt      =   '\^[^i%i%it',

    Pwms_killmenu       =   '\^[{Km%it',

    Pwms_marktext       =   '\^[{TH%c%i%d;%d;%d;%dt',

    Pwms_gfxsetcgpaint  =   '\^[{SP%dt',
    Pwms_gfxsetcgrop    =   '\^[{SR%it',

    Pwms_gfxnewpage     =   '\^[{Ns%d;%dt',

    Pwms_gfxwritetext   =   '\^[}GT%d;%d;%s\^[\\',
    Pwms_gfxloadfont    =   '\^[}Nf%s\^[\\',
    Pwms_gfxsetcgfont   =   '\^[{SF%it',
    Pwms_gfxkillfont    =   '\^[{Kf%it',
    Pwms_newfontres     =   '\^[^GF%c%d;%d;%dt',

    Pwms_gfxsetpixel    =   '\^[{GP%d;%d;%dt',
    Pwms_gfxtestpixel   =   '\^[{Gp%d;%dt',

    Pwms_gfxlinestart   =   '\^[{GL',
    Pwms_gfxlinepoint   =   '%d;%d;',
    Pwms_gfxlineend     =   '%d;%dt',

    Pwms_gfxpolystart   =   '\^[{GF',
    Pwms_gfxpolypoint   =   '%d;%d;',
    Pwms_gfxpolyend     =   '%d;%dt',

    Pwms_gfxwipearea    =   '\^[{GW%d;%d;%d;%dt',

    Pwms_gfxcopyraster  =   '\^[{GC%i%i%i%d;%d;%d;%d;%d;%dt',
    Pwms_gfxdumpraster  =   '\^[{GD%i%i%d;%d;%d;%d;%dt',
    Pwms_gfxloadraster  =   '\^[{GR%d;%d;%d;%dt',
    Pwms_gfxrastercome  =   '\^[^Gr%i%i%d;%d;%dt',

    Pwms_gfxreadrasfile =   '\^[}Gr%d;%d;%d;%d;%d;%d;%s\^[\\',
    Pwms_gfxwriterasfil =   '\^[}Gw%d;%d;%d;%d;%s\^[\\',

    Pwms_gfxgetmapentry =   '\^[{Gm%dt',
    Pwms_gfxsetmapentry =   '\^[{GM%d;%d;%d;%dt',
    Pwms_gfxrepmapentry =   '\^[^GM%d;%d;%dt',

    Pwms_gfxusecms      =   '\^[{SC%it',
    Pwms_gfxkillcms     =   '\^[{KC%it',
    Pwms_gfxnewcms      =   '\^[{NC%dt',

    Pwms_trackmnolim    =   '\^[{TA%i%d;%d;%d;%dt',
    Pwms_trackrnolim    =   '\^[{TB%i%i%d;%d;%d;%d;%d;%dt',
    Pwms_trackmlimbox   =   '\^[{TA%i%d;%d;%d;%d;%d;%d;%d;%dt',
    Pwms_trackrlimbox   =   '\^[{TB%i%i%d;%d;%d;%d;%d;%d;%d;%d;%d;%dt',

    PwmnxtwinID         =   90,

    pwmsequences = true;    ;;; for loading with "uses"
;
endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Apr  5 1987 - added sequences for comwidth functions
--- Ben Rubinstein, Mar 27 1987 - added sequences for loadraster/rastercome
*/
