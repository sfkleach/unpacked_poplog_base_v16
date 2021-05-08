/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $UIDE/dvp/uide2/evaluate/include/audio.ph
 > Purpose:         Master include file for audio driver
 > Author:          Andy Holyer, Oct 23 1992
 > Documentation:
 > Related Files:   _audio.ph,
 */

#_IF DEF  _AUDIO_PH
    ;;; Avoid reloading
    [ %consword('#_ENDIF')% ] -> proglist;
#_ENDIF

include _streamio.ph;  ;;; Streams ioctl's

include _audio.ph;     ;;; Private Sun device equates

;;; This is a hack to allow the sysopen() call to be just right.....

INCLUDE_constant O_NDELAY = 4;

;;; And another one for the fnctl call....

INCLUDE_constant    F_SETFL =   4;

INCLUDE_constant _AUDIO_PH = true;


/* --- Revision History ---------------------------------------------------
 * $Id: audio.ph,v 1.1 1992/11/24 14:04:06 andyh Exp $
 *
 * $Log: audio.ph,v $
 * Revision 1.1  1992/11/24  14:04:06  andyh
 * Initial revision
 *
 */
