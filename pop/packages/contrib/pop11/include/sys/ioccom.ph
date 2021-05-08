/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:           $UIDE/dvp/uide2/evaluate/include/sys/ioccom.ph
 > Purpose:
 > Author:          Andy Holyer, Oct 23 1992
 > Documentation:
 > Related Files:
 */

#_IF DEF __sys_ioccom_ph
    ;;; Avoid reloading
    [ %consword('#_ENDIF')% ] -> proglist;
#_ENDIF

/*
 * Ioctl's have the command encoded in the lower word,
 * and the size of any in or out parameters in the upper
 * word.  The high 2 bits of the upper word are used
 * to encode the in/out status of the parameter; for now
 * we restrict parameters to at most 255 bytes.
 */
INCLUDE_constant macro (
    _IOCPARM_MASK   =   16:FF,       /* parameters must be < 256 bytes */
    _IOC_VOID       =   16:20000000, /* no parameters */
    _IOC_OUT        =   16:40000000, /* copy out parameters */
    _IOC_IN         =   16:80000000, /* copy in parameters */
    _IOC_INOUT      =   (_IOC_IN || _IOC_OUT)
/* the 0x20000000 is so we can distinguish new ioctl's from old */
);
define :inline INCLUDE_constant _IO(x,y);
    (_IOC_VOID || ( x <<8) || y)
enddefine;

define :inline INCLUDE_constant _IOR(x,y,t=typespec);
    ( _IOC_OUT || ( ( SIZEOFTYPE(t) && _IOCPARM_MASK ) <<16 ) || (x << 8) || y)
enddefine;

define :inline INCLUDE_constant _IORN(x,y,t);
    (_IOC_OUT || (((t) && _IOCPARM_MASK) << 16) || (x << 8) || y)
enddefine;

define :inline INCLUDE_constant _IOW(x,y,t=typespec);
    ( _IOC_IN || ((SIZEOFTYPE(t) && _IOCPARM_MASK) << 16) || (x << 8) || y)
enddefine;

define :inline INCLUDE_constant _IOWN(x,y,t);
    (_IOC_IN || (((t) && _IOCPARM_MASK) << 16) ||(x << 8)|| y)
enddefine;


/* this should be _IORW, but stdio got there first */
define :inline INCLUDE_constant _IOWR(x,y,t=typespec);
    (_IOC_INOUT || ((SIZEOFTYPE(t) && _IOCPARM_MASK) << 16) || (x << 8) || y)
enddefine;

define :inline INCLUDE_constant _IOWRN(x,y,t);
    (_IOC_INOUT || (((t) && _IOCPARM_MASK) << 16) || (x << 8) || y)
enddefine;

/*
 * Registry of ioctl characters, culled from system sources
 *
 * char file where defined      notes
 * ---- ------------------      -----
 *   F  sun/fbio.h
 *   G  sun/gpio.h
 *   H  vaxif/if_hy.h
 *   M  sundev/mcpcmd.h         *overlap*
 *   M  sys/modem.h         *overlap*
 *   S  sys/stropts.h
 *   T  sys/termio.h            -no overlap-
 *   T  sys/termios.h           -no overlap-
 *   V  sundev/mdreg.h
 *   a  vaxuba/adreg.h
 *   d  sun/dkio.h          -no overlap with sys/des.h-
 *   d  sys/des.h           (possible overlap)
 *   d  vax/dkio.h          (possible overlap)
 *   d  vaxuba/rxreg.h          (possible overlap)
 *   f  sys/filio.h
 *   g  sunwindow/win_ioctl.h       -no overlap-
 *   g  sunwindowdev/winioctl.c     !no manifest constant! -no overlap-
 *   h  sundev/hrc_common.h
 *   i  sys/sockio.h            *overlap*
 *   i  vaxuba/ikreg.h          *overlap*
 *   k  sundev/kbio.h
 *   m  sundev/msio.h           (possible overlap)
 *   m  sundev/msreg.h          (possible overlap)
 *   m  sys/mtio.h          (possible overlap)
 *   n  sun/ndio.h
 *   p  net/nit_buf.h           (possible overlap)
 *   p  net/nit_if.h            (possible overlap)
 *   p  net/nit_pf.h            (possible overlap)
 *   p  sundev/fpareg.h         (possible overlap)
 *   p  sys/sockio.h            (possible overlap)
 *   p  vaxuba/psreg.h          (possible overlap)
 *   q  sun/sqz.h
 *   r  sys/sockio.h
 *   s  sys/sockio.h
 *   t  sys/ttold.h         (possible overlap)
 *   t  sys/ttycom.h            (possible overlap)
 *   v  sundev/vuid_event.h     *overlap*
 *   v  sys/vcmd.h          *overlap*
 *
 * End of Registry
 */

INCLUDE_constant __sys_ioccom_ph = true ;


/* --- Revision History ---------------------------------------------------
 * $Id: ioccom.ph,v 1.1 1992/11/24 14:02:42 andyh Exp $
 *
 * $Log: ioccom.ph,v $
 * Revision 1.1  1992/11/24  14:02:42  andyh
 * Initial revision
 *
 */
