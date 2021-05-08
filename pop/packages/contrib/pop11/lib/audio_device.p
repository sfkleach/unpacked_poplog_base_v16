/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:			$popcontrib/pop11/lib/audio_device.p
 > Purpose:			Audio pseudo-device - for general-purpose use
 > Author:			Andy Holyer, Nov 17 1992
 > Documentation:   $popcontrib/pop11/ref/audio_device
 > Related Files:   $popcontrib/pop11/include/audio.ph
 */

section $-audio => audio;

extend_searchlist('$popcontrib/pop11/include/', popincludelist)
	-> popincludelist;

include audio.ph;

defclass audio_device_info
	{
		physical_audio_read_device,
		physical_audio_write_device,
		audio_ctrl_channel,
		audio_device_status
	};

uses sigdefs;

vars op_buffer,
	  pop_using_audio_write_device = false,
	  pop_audio_write_queue = [],
;

exload 'audio_device'
	write(3) :int,
	fcntl(3) :int,
	ioctl(3),
	_pop_sigaction(2),
	_pop_usersig_handler,
	_pop_sigmask(1)	:uint,
endexload;

lvars macro (
	audio_device = '/dev/audio',
	audio_control = '/dev/audioctl',
);

vars samples_read = 0,
	  procedure audio_write,
	  procedure audio_status,
	;

define audio_write_demon(device);
	lvars device;
	lvars i,
	  	buflen = length(op_buffer),
		;
	/* So output something !! */
	exacc	write(
		device_os_channel(
			device_user_data(device).physical_audio_write_device
		),
		op_buffer,
		buflen
	) -> i;


	unless i = -1 then
		if buflen = i then
			'' -> op_buffer;
			true -> sys_signal_handler(SIG_IO);
			false -> pop_using_audio_write_device;
			if pop_audio_write_queue = [] then
				
				/* Check if anyone else wants to use this device ... */
				
				if  audio_status(device)
						.audio_info_play.audio_prinfo_waiting /= 0 then
					sysclose(
						device_user_data(device).physical_audio_read_device
					);
					false -> device_user_data(device)
					.physical_audio_read_device;
				endif;
			else
				audio_write(
					device,
					dest(pop_audio_write_queue) -> pop_audio_write_queue
				);
			endif;
			return;
		else
			substring(i+1, buflen - i, op_buffer) -> op_buffer;
		endif;
	endunless;

enddefine;

define audio_w_open() -> device;
lvars device;
	/* (Attempt to) open the audio device */
	unless
		sysopen(
			audio_device,
			1 || O_NDELAY /* Read Only, Block Mode */,
			true /* Block Mode */,
			`A` /* Never mishap on failure to open device */
		) ->> device
	then
		mishap('Unable to open audio device',[]);
	endunless;


	/* Set up the device to be non-blocking on write */
	if
		exacc fcntl(device_os_channel(device), F_SETFL, O_NDELAY)
			= -1
	then
		mishap('Unable to set device non-blocking', []);
	endif;

	/* Set up a SIG_IO on an empty buffer */
	unless
		sys_io_control(
			device,
			I_SETSIG,
			S_OUTPUT
		)
	then
		mishap('Device will not respond to ioctl',[]);
		return(false);
	endunless;


	/* ... And turn off Poplog's trap for SIG_IO */

	exacc _pop_sigaction(SIG_IO, _pop_usersig_handler);

enddefine;

define audio_write(device, buf);
	lvars device, buf;
	lvars 	i = 0,
		;
	if pop_using_audio_write_device then
		rev(
			buf ::
				rev(pop_audio_write_queue)
		) -> pop_audio_write_queue;
	else
		true -> pop_using_audio_write_device;
		buf -> op_buffer;

		/* Let the demon see the rabbit */

		audio_write_demon(% device %) -> sys_signal_handler(SIG_IO);

		/* And just to pump-prime... */

		audio_write_demon(device);
	endif
enddefine;


define audio_w_close(device);
lvars device;
	/* Close the audio device to allow other processes access */
	sysclose(device);
enddefine;

define audio_write_nicely(buffer);
lvars buffer;
lvars device;
	audio_w_open() -> device;
	audio_write(device, buffer);
	sys_io_control(
		device,
		AUDIO_DRAIN,
		false
	) ->;
	audio_w_close(device);
enddefine;


define audio_status(udev) -> status;
lvars udev, status = udev.device_user_data.audio_device_status;

	unless udev.device_user_data.audio_ctrl_channel then
		sysopen(audio_control, 0, true).device_os_channel
			-> udev.device_user_data.audio_ctrl_channel;
	endunless;

	exacc ioctl(
		udev.device_user_data.audio_ctrl_channel,
		AUDIO_GETINFO,
		device_user_data(udev).audio_device_status
	);

enddefine;


define audio_read_p( udev, bsub, bytestruct, nbytes) -> nread;
	lvars udev, bsub, bytestruct, nbytes, nread=0;
	lvars readthistime,
	      toread = nbytes,
		  marker = bsub,
	;

	unless device_user_data(udev).physical_audio_read_device then
		/* (Attempt to) open the audio device */
		unless
			sysopen(
				audio_device,
				0 || O_NDELAY  /* Read Only, Block Mode */,
				true /* Block Mode */,
				`A` /* Never mishap on failure to open device */
			) ->> device_user_data(udev).physical_audio_read_device
		then
			mishap('Unable to open audio device',[]);
			return(0);
		else
			0 -> samples_read;
		endunless;
    endunless;

	/* Read repeatedly until required amount of data has been read */
	while toread > 0 do

		/* Stop xved interrupting the read() call */

		exacc _pop_sigmask(1) ->;

		sysread(
			udev.device_user_data.physical_audio_read_device,
			marker,
        	bytestruct,
			toread
		) -> readthistime;

		/* "Do it up again, Wiggle" */

		exacc _pop_sigmask(0) ->;
		
		toread - readthistime -> toread;

		nread + readthistime -> nread;

		marker + readthistime -> marker;

		samples_read + readthistime -> samples_read;

	endwhile;

		sysclose(device_user_data(udev).physical_audio_read_device);
		false -> device_user_data(udev).physical_audio_read_device;

enddefine;


define audio_test_input_p(udev) -> n;
	lvars udev, n;
	if (audio_status(udev).audio_info_record.audio_prinfo_samples ->> n) = 0 then
		false -> n;
	endif;
enddefine;


define audio_clear_input_p(udev);
	lvars udev;
	if device_user_data(udev).physical_audio_read_device then
		sys_io_control(
			device_user_data(udev).physical_audio_read_device,
			I_FLUSH,
			FLUSHR
		) ->;
	endif;
enddefine;


define audio_write_p(udev, bsub, bytestruct, nbytes);
lvars udev, bsub, bytestruct, nbytes;
	unless device_user_data(udev).physical_audio_write_device then
		audio_w_open() -> device_user_data(udev).physical_audio_write_device;
	endunless;
	
	audio_write(udev, substring(bsub, nbytes, bytestruct));

enddefine;


define audio_flush_p(udev);
lvars udev;
	if device_user_data(udev).physical_audio_write_device then
		sys_io_control(
			device_user_data(udev).physical_audio_write_device,
			AUDIO_DRAIN
		) ->;
	endif;
enddefine;


define audio_close_p(udev);
lvars udev;

	if device_user_data(udev).physical_audio_read_device then
		sysclose(device_user_data(udev).physical_audio_read_device);
		false -> device_user_data(udev).physical_audio_read_device;
	endif;

	if device_user_data(udev).physical_audio_write_device then
		sysclose(device_user_data(udev).physical_audio_write_device);
		false -> device_user_data(udev).physical_audio_write_device;
	endif;

enddefine;


constant audio = consdevice(
	'audio',                	;;; device_open_name
	'SPARC audio port',			;;; device_full_name
	consaudio_device_info( 			;;; device_user_data
		false,			;;; physical_audio_read_device
		false,			;;; physical_audio_write_device
		false,			;;; audio_control_channel
		initaudio_info_ptr()	;;; pointer to audio device status pointer
	),
	0,							;;; flags - 0, hence not a terminal
	{%                       	;;; Methods Vector
		{%                  	;;; Read Vector
			audio_read_p,		;;; READ_P(UDEV, BSUB, BYTESTRUCT, NBYTES) -> NREAD
			audio_test_input_p,	;;; TEST_INPUT_P(UDEV) -> N_OR_FALSE
			audio_clear_input_p	;;; CLEAR_INPUT_P(UDEV)
			%},

        {%						;;; Write Vector
			audio_write_p,		;;; WRITE_P(UDEV, BSUB, BYTESTRUCT, NBYTES)
			audio_flush_p       ;;; FLUSH_P(UDEV)
			%},

		false,					;;; You can't seek in the audio device....

		audio_close_p			;;;  CLOSE_P(UDEV)
		%}
	);

endsection;

/* $Id: audio_device.p,v 1.7 1993/07/07 15:45:24 johnw Exp $
 *
 * $Log: audio_device.p,v $
 * Revision 1.7  1993/07/07  15:45:24  johnw
 * erases result of sys_io_control where appropriate
 *
 * Revision 1.6  1993/07/07  15:40:40  andyh
 * First version in contrib. Two competing processes no longer
 * hang when both try to open device.
 *
 * Revision 1.5  1993/04/15  10:34:52  andyh
 * Added vars declarations for forward references
 *
 * Revision 1.4  1993/04/06  14:44:09  andyh
 * Added check that $UIDE/dvp/uide2/include is in popincludelist
 *
 * Revision 1.3  1992/11/24  14:40:17  andyh
 * Fixed spurious "uses" call
 *
 * Revision 1.2  1992/11/24  14:01:14  ianr
 * added logging variables
 *
 */
