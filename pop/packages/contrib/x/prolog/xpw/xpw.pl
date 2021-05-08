/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $popcontrib/xpop/prolog/xpw/xpw.pl
 > Purpose:         Initialise search lists for Prolog Xpw interface
 > Author:          Robert John Duncan, Nov 14 1990
 */

pop11

uses popxlib

lconstant
	XPW_DIR = '$popcontrib/x/prolog/xpw/',
;

(XPW_DIR dir_>< 'help/')  :: prolog_helpdirs  -> prolog_helpdirs;
(XPW_DIR dir_>< 'teach/') :: prolog_teachdirs -> prolog_teachdirs;
(XPW_DIR dir_>< 'ref/')   :: prolog_refdirs   -> prolog_refdirs;
(XPW_DIR dir_>< 'lib/')   :: prolog_libdirs   -> prolog_libdirs;
