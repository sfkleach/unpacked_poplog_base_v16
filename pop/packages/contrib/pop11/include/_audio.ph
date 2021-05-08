/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File: $UIDE/dvp/uide2/evaluate/include/_audio.ph
 > Purpose:         Include file for /dev/audio device - taken from sun file
 > Author:          Andy Holyer, Oct 23 1992
 > Documentation:
 > Related Files:
 */

/*
 * These are the ioctl calls for generic audio devices, including
 * the SPARCstation 1 audio device.
 *
 * You are encouraged to design your code in a modular fashion so that
 * future changes to the interface can be incorporated with little trouble.
 */

#_IF DEF  _sun_audioio_ph
    ;;; Avoid reloading
    [ %consword('#_ENDIF')% ] -> proglist;
#_ENDIF

/*
 * This structure contains state information for play or record streams.
 */
i_typespec audio_prinfo {
    /*
     * The following values describe the audio data encoding.
     * They are read-only for SPARCstation audio, but may be
     * dynamically configurable for other audio devices.
     */
    audio_prinfo_sample_rate :uint,     /* sample frames per second */
    audio_prinfo_channels    :uint,     /* number of interleaved channels */
    audio_prinfo_precision   :uint,     /* bits per sample */
    audio_prinfo_encoding    :uint,     /* data encoding method */

    /* The following values control audio device configuration */
    audio_prinfo_gain        :uint,     /* gain level: 0 - 255 */
    audio_prinfo_port        :uint,     /* selected I/O port (see below) */
    audio_prinfo__xxx        :uint[4],  /* Reserved for future use */

    /* The following values describe driver state */
    audio_prinfo_samples     :uint,     /* number of samples converted */
    audio_prinfo_eof         :uint,     /* number of EOF records (play only) */
    audio_prinfo_pause       :byte,     /* TRUE to pause, FALSE to resume */
    audio_prinfo_error       :byte,     /* TRUE if overflow/underflow */
    audio_prinfo_waiting     :byte,     /* TRUE if a process wants access */
    audio_prinfo__ccc        :byte[3],  /* Reserved for future use */

    /* The following values are read-only state flags */
    audio_prinfo_open        :byte,     /* TRUE if access requested at open */
    audio_prinfo_active      :byte      /* TRUE if HW I/O active */
};

/*
 * This structure describes the current state of the audio device.
 */
i_typespec audio_info {
    audio_info_play            :audio_prinfo,      /* output status information */
    audio_info_record          :audio_prinfo,      /* input status information */
    audio_info_monitor_gain    :uint,              /* input to output mix: 0 - 255 */
    audio_info__yyy            :uint[4]            /* Reserved for future use */
};

shadowclass audio_prinfo_ptr [refresh] :audio_prinfo;
shadowclass audio_info_ptr [refresh] :audio_info;


/* Audio encoding types */
INCLUDE_constant macro (

    AUDIO_ENCODING_ULAW =   (1), /* u-law encoding */
    AUDIO_ENCODING_ALAW =   (2), /* A-law encoding (not supported yet) */

/* These ranges apply to record, play, and monitor gain values */
    AUDIO_MIN_GAIN      =   (0),     /* minimum gain value */
    AUDIO_MAX_GAIN      =   (255),       /* maximum gain value */

/* Define some possible 'port' values */
    AUDIO_PORT_A        =   (1),     /* define generic port names */
    AUDIO_PORT_B        =   (2),
    AUDIO_PORT_C        =   (3),
    AUDIO_PORT_D        =   (4),

/* Define some convenient names for SPARCstation audio ports */
    AUDIO_SPEAKER       =   AUDIO_PORT_A,    /* output to built-in speaker */
    AUDIO_HEADPHONE     =   AUDIO_PORT_B,    /* output to headphone jack */
    AUDIO_MICROPHONE    =   AUDIO_PORT_A,    /* input from microphone */


/*
 * Ioctl calls for the audio device.
 */

/*
 * AUDIO_GETINFO retrieves the current state of the audio device.
 *
 * AUDIO_SETINFO copies all fields of the audio_info structure whose values
 * are not set to the initialized value (-1) to the device state.  It performs
 * an implicit AUDIO_GETINFO to return the new state of the device.  Note that
 * the record.samples and play.samples fields are set to the last value before
 * the AUDIO_SETINFO took effect.  This allows an application to reset the
 * counters while atomically retrieving the last value.
 *
 * AUDIO_DRAIN suspends the calling process until the write buffers are empty.
 */
    AUDIO_GETINFO   =   _IOR(`A`, 1, :audio_info),
    AUDIO_SETINFO   =   _IOWR(`A`, 2, :audio_info),
    AUDIO_DRAIN     =   _IO(`A`, 3),


/*
 * READSTART tells the device driver to start reading sound.  This is
 * useful for starting recordings when you don't want to call read()
 * until later.  STOP stops all i/o and clears the buffers, while
 * PAUSE stops i/o without clearing the buffers.  RESUME resumes i/o
 * after a PAUSE.  These ioctl's don't transfer any data.
 */
    AUDIOREADSTART  =   _IO(1, 3),
    AUDIOSTOP       =   _IO(1, 4),
    AUDIOPAUSE      =   _IO(1, 5),
    AUDIORESUME     =   _IO(1, 6),

/*
 * READQ is the number of bytes that have been read but not passed to
 * the application.  WRITEQ is the number of bytes passed into
 * the driver but not written to the device.  QSIZE is the number of bytes
 * in the queue.
 */
    AUDIOREADQ      =   _IOR(1, 7, :int),
    AUDIOWRITEQ     =   _IOR(1, 8, :int),
    AUDIOGETQSIZE   =   _IOR(1, 9, :int),
    AUDIOSETQSIZE   =   _IOW(1, 10, :int),

);

INCLUDE_constant _sun_audioio_ph = true;

/* --- Revision History ---------------------------------------------------
 * $Id: _audio.ph,v 1.2 1992/11/24 14:41:33 andyh Exp $
 *
 * $Log: _audio.ph,v $
 * Revision 1.2  1992/11/24  14:41:33  andyh
 * fixed spurious debugging message.
 *
 * Revision 1.1  1992/11/24  14:04:06  andyh
 * Initial revision
 *
 */
