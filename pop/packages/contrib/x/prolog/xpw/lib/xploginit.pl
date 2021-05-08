/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			/csuna/pop/master/contrib/x/prolog/xpw/lib/xploginit.pl
 > Purpose:			Initialise the Prolog XWindows interface
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	PLOGHELP * xprolog
 > Related Files:
*/

:- prolog_language(pop11).

500000 -> popmemlim;

'LOADING POP LIBRARIES' =>
'loading popxlib' =>
uses popxlib;
'loading xt_widgetinfo' =>
uses xt_widgetinfo.p;
'loading xpt_typecheck' =>
uses xpt_typecheck.p;
'loading XptNewWindow' =>
uses XptNewWindow.p;
'loading XptValue' =>
uses fast_XptValue.p;

:- prolog_language(prolog).

:- nl,write('** LOADING PROLOG BASIC LIBRARIES'),nl.
:- write('** loading xwidgets'),nl.
:- library(xwidgets).
:- write('** loading xresources'),nl.
:- library(xresources).
:- write('** loading xt_value'),nl.
:- library(xt_value).
:- write('** loading xcallbacks'),nl.
:- library(xcallbacks).

:- nl,write('** LOADING PROLOG GRAPHICS LIBRARIES'),nl.
:- write('** loading XpwGraphic'),nl.
:- library('XpwGraphic.pl').
:- write('** loading XpwCore'),nl.
:- library('XpwCore.pl').
:- write('** loading XpwPixmap'),nl.
:- library('XpwPixmap.pl').
:- write('** loading XpwMouse'),nl.
:- library('XpwMouse.pl').

:- nl,write('** XPROLOG INITIALIZE DONE'),nl.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jun 10 1991 Updated to use LIB * XptNewWindow
 */
