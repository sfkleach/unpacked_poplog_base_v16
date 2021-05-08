/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:        $usepop/master/C.sun/pwm/pwid.h
 * Purpose:     defines parts of PWM identity message
 * Author:      Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwid.h,v 1.2 89/08/23 17:13:53 pop Exp $
 */


/*
|   This file defines parts of the "PWM long identity" message, which
|   may differ according to machine and PWM version.
|
|   Those which are commented out must be supplied elsewhere in the
|   linking process.  Note that screen width/height are already declared in
|   PWDEC.H
|
*/

#define PWMID_version       "1.78"
#define Version_str         "Sussex POPLOG Window Manager, version 1.78:RU3"
#define Version_len         46          /* length of string above */

/* #define PWMID_date          "2/10/86" */     /* supplied by makefile */
/* #define PWMID_machine       "sun3" */        /* supplied by makefile */

#ifdef DeBug
#define PWMID_misc           "debug"
#else
#define PWMID_misc           "-"
#endif
/*
$Log:	pwid.h,v $
 * Revision 1.2  89/08/23  17:13:53  pop
 * made version string end 1.78:RU3
 * 
 * Revision 1.1  89/08/23  13:20:33  pop
 * Initial revision
 * 
*/
