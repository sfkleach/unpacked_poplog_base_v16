/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:           $usepop/master/C.sun/pwm/pwreport.c
 * Purpose:        sending reports to client
 * Author:         Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwreport.c,v 1.2 89/08/23 17:39:21 pop Exp $
 */

#include "pwdec.h"
#include "pwrepseq.h"
#include "pwid.h"


send_to_poplog(code)
char code;
{
		write(client_ofd, &code, 1);
}

send_report_to_poplog(noofchars)
int noofchars;
{
#ifdef DeBug
	if (shift_escape)
	{
		int i;

		printf("VVV sending report %d long:\n", noofchars);
		for (i = 0; i < noofchars; i++)
			printf(":::  %c (%d)\n", report_buffer[i], report_buffer[i]);
	}
#endif
	write(client_ofd, report_buffer, noofchars);
}

send_this_report_to_poplog(report, noofchars)
char *report;
int noofchars;
{
#ifdef DeBug
	if (shift_escape)
	{
		int i;

		printf("VVV sending report %d long:\n", noofchars);
		for (i = 0; i < noofchars; i++)
			printf(":::  %c (%d)\n", report[i], report[i]);
	}
#endif
	write(client_ofd, report, noofchars);
}

report_status(s)
int s;
{
	sprintf(report_buffer, REPstatus, s + 32);
	send_report_to_poplog(6);
}

report_integer(i)
int i;
{
	sprintf(report_buffer, REPinteger, i);
	send_report_to_poplog(strlen(report_buffer));
}

advise_open_or_closed()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		if	(wmgr_iswindowopen(wt_toolwp[win]->tl_windowfd))
			sprintf(report_buffer, REPwinopened, com_charargs[0]);
		else
			sprintf(report_buffer, REPwinclosed, com_charargs[0]);

		send_report_to_poplog(RLENwinreport);
	}
	else Report_null;		/* to kick off the listener at the other end */
}

report_win_resized(win, w, h)
register int win, w, h;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPwinresized, win + 32, w, h);
		send_report_to_poplog(strlen(report_buffer));
	}
}

advise_external_size()
{
	register int win, w, h;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		w = (int)(tool_get_attribute(wt_toolwp[win], WIN_WIDTH));
		h = (int)(tool_get_attribute(wt_toolwp[win], WIN_HEIGHT));
#ifdef DeBug
	printf("reporting external size: w = %d, h = %d\n", w, h);
#endif

		sprintf(report_buffer, REPexternsize, win + ' ', w, h);
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;		/* to kick off the listener at the other end */
}

advise_internal_size()
{
	register int win, w, h;

			/* whereas the values returned for COLUMNS/LINES are the internal
			*	size, those for WIDTH/HEIGHT are external - so we have to
			*	frig for 5-pixel borders on three sides, and 2 + fontheight
			*	on top
			*/
	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		w = (int)(tool_get_attribute(wt_toolwp[win], WIN_WIDTH)) - 10;
		h = (int)(tool_get_attribute(wt_toolwp[win], WIN_HEIGHT)) - fontadv_y - 7;

#ifdef DeBug
	printf("reporting internal size: w = %d, h = %d\n", w, h);
#endif
		if (wt_active[win] != WT_GRAPHW)
		{
			w = w / fontadv_x;
			h = h / fontadv_y;
#ifdef DeBug
	printf("reporting txt internal size: w = %d, h = %d\n", w, h);
#endif
		}

		sprintf(report_buffer, REPinternsize, win + ' ', w, h);
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;		/* to kick off the listener at the other end */
}

advise_win_location()
{
	int top, left;
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		top = (int)(tool_get_attribute(wt_toolwp[win], WIN_TOP));
		left = (int)(tool_get_attribute(wt_toolwp[win], WIN_LEFT));

		sprintf(report_buffer, REPwinlocat, com_charargs[0], left, top);
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;
}

advise_icon_location()
{
	int top, left;
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		top = (int)(tool_get_attribute(wt_toolwp[win], WIN_ICON_TOP));
		left = (int)(tool_get_attribute(wt_toolwp[win], WIN_ICON_LEFT));

		sprintf(report_buffer, REPiconlocat, com_charargs[0], left, top);
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;
}

advise_win_title()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		sprintf(report_buffer, REPwintitle,
				(char *)(tool_get_attribute(wt_toolwp[win], WIN_LABEL)));
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;
}

advise_icon_title()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		sprintf(report_buffer, REPicontitle,
				(char *)(tool_get_attribute(wt_toolwp[win], WIN_ICON_LABEL)));
		send_report_to_poplog(strlen(report_buffer));
	}
	else Report_null;
}


report_mbutton_pressed(b, x, y)
int x, y;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPmousepress, b + 32, x, y);
		send_report_to_poplog(strlen(report_buffer));
	}
}

report_mbutton_released(b, x, y)
int x, y;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPmouserlse, b + 32, x, y);
		send_report_to_poplog(strlen(report_buffer));
	}
}

report_mbutton_moved(b, x, y)
int x, y;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPmousemove, b + 32, x, y);
		send_report_to_poplog(strlen(report_buffer));
	}
}

report_mouse_exit(b)
register int b;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPmouseexit, b + 32);
		send_report_to_poplog(6);
	}
}

report_input_window(w)
int w;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPinputsrc, w + 32);
		send_report_to_poplog(6);
	}
}

report_input_event(type, code)
char type, code;
{
	sprintf(report_buffer, REPinpevent, type, code);
	send_report_to_poplog(6);
}

/*	this is needed for get-one-input and prompt-user, because otherwise
*	the ascii character `t` could be confused with the terminator.
*	This is a fix: "input_event" should use this, but it would require too
*	many changes.  Should be sorted out for version 13.		bhr 23/7/86.
*/
report_ascii_event(type, code)
char type, code;
{
	sprintf(report_buffer, REPinpevent, type, code);
	send_report_to_poplog(7);
}

report_quit_request(w)
int w;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPwinquitreq, w + 32);
		send_report_to_poplog(6);
	}
}

/*--------------------------------------------------------------------
*	no point building this into the image until we have scroll bars
*/
/*
report_elevator_pos(win)
register int win;
{
	if (poplog_listening)
	{
		sprintf(report_buffer, REPelevatorpos, win, -1, -1);
		send_report_to_poplog(strlen(report_buffer));
	}
}
*/

/*--------------------------------------------------------------------
*	command from poplog
*/
advise_elevator_pos()
{
/*
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
		report_elevator_pos(win);
	else
	{
		misprint(com_charargs[0], "PWM: can't report elevators for %d, no such window\n");
		Report_null;
	}
*/
}

report_window_opened(w, opened)
int w, opened;
{
	if (poplog_listening)
	{
		if (opened == WT_ICONIC)
			sprintf(report_buffer, REPwinclosed, w + 32);
		else
			sprintf(report_buffer, REPwinopened, w + 32);

		send_report_to_poplog(6);
	}
}

advise_pwm_details()
{
#ifdef DeBug
	printf("--- reporting details: %c\n", com_charargs[0]);
#endif
	switch (com_charargs[0])
	{
	case 'i':
		if (poplog_connected == FALSE)	/* don't get involved with two at once */
		{
			sprintf(report_buffer, REPpwmident,
						PWMID_machine,
						PWMID_version,
						SCREENWIDTH, SCREENHEIGHT,	/* defined in pwdec.h */
						SCREENDEPTH,
						PWMID_date,
						PWMID_misc,
						wt_scrndata[0]->cols, wt_scrndata[0]->rows,
						fontadv_x, fontadv_y, -font_home_y
						);
			send_report_to_poplog(strlen(report_buffer));
		}
		break;
    case '1':
		one_input = 1;			/* set one-input mode */
		break;
	case 'w':
		/* live windows !!! */
		break;
	default:
		misprint(com_charargs[0], "PWM: bad 'details' type for report\n");
		break;
	}
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ----1---Copyright University of Sussex 1987.  All rights reserved. ------
::    12:  send_to_poplog(code)
::    18:  send_report_to_poplog(noofchars)
::    34:  send_this_report_to_poplog(report, noofchars)
::    51:  report_status(s)
::    58:  report_integer(i)
::    65:  advise_open_or_closed()
::    81:  report_win_resized(win, w, h)
::    91:  advise_external_size()
::   109:  advise_internal_size()
::   141:  advise_win_location()
::   157:  advise_icon_location()
::   173:  advise_win_title()
::   186:  advise_icon_title()
::   200:  report_mbutton_pressed(b, x, y)
::   210:  report_mbutton_released(b, x, y)
::   220:  report_mbutton_moved(b, x, y)
::   230:  report_mouse_exit(b)
::   240:  report_input_window(w)
::   250:  report_input_event(type, code)
::   262:  report_ascii_event(type, code)
::   269:  report_quit_request(w)
::   297:  advise_elevator_pos()
::   312:  report_window_opened(w, opened)
::   326:  advise_pwm_details()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwreport.c,v $
 * Revision 1.2  89/08/23  17:39:21  pop
 * modified advise_pwm_details to use SCREENDEPTH
 * 
 * Revision 1.1  89/08/23  13:21:02  pop
 * Initial revision
 * 
*/
