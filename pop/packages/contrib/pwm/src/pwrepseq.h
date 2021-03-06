/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:        $usepop/master/C.sun/pwm/pwrepseq.c
 * Purpose:     definitions of reports to client process
 * Author:      Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwrepseq.h,v 1.1 89/08/23 13:21:06 pop Exp $
 */

/*
| this file defines (as macros to be submitted to sprintf) the format
|    of escape sequences for messages to the client process
|
|   - all reports either start with "^" and end with "t"
|                     or start with "~" and end with "\033\\"
*/

#define REPwinclosed    "\033^IC%ct"
#define REPinputsrc     "\033^II%ct"
#define REPmouseexit    "\033^IM%ct"
#define REPwinopened    "\033^IO%ct"
#define REPwinquitreq   "\033^IQ%ct"
#define RLENwinreport   6

#define REPmousepress   "\033^MP%c%d;%dt"
#define REPmouserlse    "\033^MR%c%d;%dt"
#define REPmousemove    "\033^MM%c%d;%dt"
#define REPwinresized   "\033^Mr%c%d;%dt"
#define REPelevatorpos  "\033^Me%c%d;%dt"

#define REPmishap       "\033~Er%d;%d;%s\033\\"

/*
|   - the above reports can be issued by the pwm without poplog having
|   requested them: all such reports must be arraanged such that the pattern
|   can be determined from the two characters following the escape (hence
|   the odd-looking conflation of winresized with mouse buton events). The
|   reports below are not affected by any such constraints.
*/

#define REPstatus    "\033^ZI%ct"
#define REPinteger   "\033^ZD%dt"

#define REPinpevent  "\033^i%c%ct"

#define REPcomswidth "\033^Zw\252\125%dt"

#define REPinternsize   "\033^Ur%c%d;%dt"
#define REPexternsize   "\033^UR%c%d;%dt"

#define REPwintitle     "\033~FT%s\033\\"
#define REPicontitle    "\033~Ft%s\033\\"

#define REPmapentry  "\033^GM%d;%d;%dt"
#define REPiconlocat "\033^Fl%c%d;%dt"
#define REPwinlocat  "\033^FL%c%d;%dt"

#define REPnewfont "\033^GF%c%d;%d;%dt"

#define REPrastercome "\033^Gr%c%c%d;%d;%dt"

#define REPpwmident  "\033~RP%s\11%s\11%d;%d;%d\11%s\11%s\11%d;%d\11%d;%d;%d\033\\"
/*
$Log:	pwrepseq.h,v $
 * Revision 1.1  89/08/23  13:21:06  pop
 * Initial revision
 * 
*/
