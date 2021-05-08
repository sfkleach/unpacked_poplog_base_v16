/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            $UIDE/dvp/uide2/evaluate/include/_streamio.ph
 * Purpose:         Sreams ioctl definitions
 * Author:          Andy Holyer, Oct 23 1992
 * Documentation:
 * Related Files:
 */

#_IF DEF _sys_stropts_ph
    ;;; Avoid reloading
    [ %consword('#_ENDIF')% ] -> proglist;
#_ENDIF

/*
 * Read options
 */
INCLUDE_constant macro (
    RNORM       =   0,          /* read msg norm */
    RMSGD       =   1,          /* read msg discard */
    RMSGN       =   2,          /* read msg no discard */

/*
 * Flush options
 */

    FLUSHR      =   1,          /* flush read queue */
    FLUSHW      =   2,          /* flush write queue */
    FLUSHRW     =   3,          /* flush both queues */

/*
 * Events for which to be sent SIGPOLL signal
 */
    S_INPUT     =   8:001,        /* regular priority msg on read Q */
    S_HIPRI     =   8:002,        /* high priority msg on read Q */
    S_OUTPUT    =   8:004,        /* write Q no longer full */
    S_MSG       =   8:010,        /* signal msg at front of read Q */

/*
 * Flags for recv() and send() syscall arguments
 */
    RS_HIPRI    =   1,      /* send/recv high priority message */

/*
 * Flags returned as value of recv() syscall
 */
    MORECTL     =   1,      /* more ctl info is left in message */
    MOREDATA    =   2,      /* more data is left in message */
);

INCLUDE_constant    FMNAMESZ =  8;

include 'sys/ioccom.ph';

/*
 * User level ioctl format for ioctl that go downstream I_STR
 */
i_typespec strioctl {
    strioctl_ic_cmd     :int,       /* command */
    strioctl_ic_timout  :int,       /* timeout value */
    strioctl_ic_len     :int,       /* length of data */
    strioctl_ic_dp      :exptr      /* pointer to data */
};


/*
 * Value for timeouts (ioctl, select) that denotes infinity
 */
INCLUDE_constant INFTIM =   -1;


/*
 * Stream buffer structure for send and recv system calls
 */
i_typespec strbuf {
    strbuf_maxlen  :int,           /* no. of bytes in buffer */
    strbuf_len     :int,           /* no. of bytes returned */
    strbuf_buf     :exptr         /* pointer to data */
};


/*
 * stream I_PEEK ioctl format
 */

i_typespec  strpeek {
    strpeek_ctlbuf  :strbuf,
    strpeek_databuf :strbuf,
    strpeek_flags :long
};

/*
 * stream I_FDINSERT ioctl format
 */
i_typespec strfdinsert {
    strfdinsert_ctlbuf  :strbuf,
    strfdinsert_databuf :strbuf,
    strfdinsert_flags   :long,
    strfdinsert_fildes  :int,
    strfdinsert_offset  :int
};


/*
 * receive file descriptor structure
 */
i_typespec strrecvfd {
    strrecvfd_fd    :int,
    strrecvfd_uid   :ushort,
    strrecvfd_gid   :ushort,
    strrecvfd_fill  :byte[8]
};

/*
 *  Stream Ioctl defines
 */
INCLUDE_constant macro (
   I_NREAD      =   _IOR(`S`,8:01,:int),
   I_PUSH       =   _IOWN(`S`,8:02,FMNAMESZ+1),
   I_POP        =   _IO(`S`,8:03),
   I_LOOK       =   _IORN(`S`,8:04,FMNAMESZ+1),
   I_FLUSH      =   _IO(`S`,8:05),
   I_SRDOPT     =   _IO(`S`,8:06),
   I_GRDOPT     =   _IOR(`S`,8:07,:int),
   I_STR        =   _IOWR(`S`,8:010, :strioctl),
   I_SETSIG     =   _IO(`S`,8:011),
   I_GETSIG     =   _IOR(`S`,8:012,:int),
   I_FIND       =   _IOWN(`S`,8:013,FMNAMESZ+1),
   I_LINK       =   _IO(`S`,8:014),
   I_UNLINK     =   _IO(`S`,8:015),
   I_PEEK       =   _IOWR(`S`,8:017, :strpeek),
   I_FDINSERT   =   _IOW(`S`,8:020, :strfdinsert),
   I_SENDFD     =   _IO(`S`,8:021),
   I_RECVFD     =   _IOR(`S`,8:022, :strrecvfd),
   I_PLINK      =   _IO(`S`,8:023),
   I_PUNLINK    =   _IO(`S`,8:024)
);


INCLUDE_constant _sys_stropts_ph = true ;


/* --- Revision History ---------------------------------------------------
 * $Id: _streamio.ph,v 1.1 1992/11/24 14:04:06 andyh Exp $
 *
 * $Log: _streamio.ph,v $
 * Revision 1.1  1992/11/24  14:04:06  andyh
 * Initial revision
 *
 */
