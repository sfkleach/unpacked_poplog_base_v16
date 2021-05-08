/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwcommand.c
 * Purpose:		routines which execute miscellaneous commands from client
 * Author:		Ben Rubinstein, Jan  8 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwcommand.c,v 1.2 89/08/23 16:18:28 pop Exp $
 */

#include "pwdec.h"
/*	only need this for set_icon_image, and it doesn't work.
#include <suntool/icon_load.h>
*/

/*--------------------------------------------------------------------
*	this is called in response to the v200 command "<esc>Y<x><y>".  Because
*	ved scrolls by jumping to the top of the window (below the status line)
*	deleting a line, and then jumping back to the bottom of the window to
*	fill in the line, this routine checks for the sequence <cursor address>
*	<delete line (escape M)> <cursor address> and does the whole lot, if found,
*	in one go.  Note however that this is only done if the first cursor
*	coordinates are sensible.
*/
cursor_address()
{
	int x, y;

	if	(((y = com_code1 - 32) >= 0) && ((x = com_code2 - 32) >= 0)
			&& (x < co_widthc) && (y < co_heightc)
			&& (com_bufnext + 6 < com_buflen)	/* 6 more chars: esc,M,esc,Y,<x>,<y> */
			&& (com_buffer[com_bufnext] == VW_ESCAPE)
			&& (com_buffer[com_bufnext + 1] == 'M')
			&& (com_buffer[com_bufnext + 2] == VW_ESCAPE)
			&& (com_buffer[com_bufnext + 3] == 'Y'))
	{
		char *lastline;
		register int i;

		/* rubout old cursor */
		pw_char(co_pixwinp, co_curposp->x, co_curposp->y, PIX_SRC,
						norm_font, co_text[co_curposc->y][co_curposc->x]&0x7f);

		com_bufnext = com_bufnext + 4;

		/* swap lines in the character map, to re-use the space */
		lastline = co_text[y];
		for (i = y; i < co_heightc - 1; i++) co_text[i] = co_text[i+1];
		co_text[i] = lastline;

		/* and blank the (new) bottom line */
		for (i = 0; i < co_widthc; ) lastline[i++] = ' ';

		/* scroll up on screen... */
		y = fontadv_y * y;	/* pixel address of top of line */
		pw_copy(co_pixwinp, 0, y, co_widthp, co_heightp - fontadv_y,
							PIX_SRC, co_pixwinp, 0, y + fontadv_y);

		/* ... blank the bottom line */
		pw_writebackground(co_pixwinp, 0, co_botlinetop,
							co_widthp, co_botlineheight, PIX_CLR);

		/* set new cursor-coords */
		y = com_buffer[com_bufnext++] - 32;
		x = com_buffer[com_bufnext++] - 32;
	}

   	if	(x < 0) x = 0; else if (x >= co_widthc) x = co_widthc - 1;
   	if	(y < 0) y = 0; else if (y >= co_heightc) y = co_heightc - 1;

	jump_cursor(x, y);
}

ansi_cursor_address()
{
	jump_cursor(com_numargs[0], com_numargs[1]);
}

winmgr_commands()
{
	register int win;

	if (com_charargs[0] == (NXTWINDOW_ID + 32))
	{
		switch(com_code2)
		{
		case 'C': nxtwin_iconic = 1; break;
		case 'O': nxtwin_iconic = 0; break;
		default:
			misprint(-1, "PWM: bad window id (can't preset function)\n");
			break;
		}
	}
	else if ((win = check_window_id(0)) != WT_NOWIN)
	{
		switch(com_code2)
		{
		case 'C':
			wmgr_close(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'E':
			wmgr_top(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'H':
			wmgr_bottom(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'M':
			wmgr_move(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'O':
			wmgr_open(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'R':
			if ((wt_active[win] < WT_GRAPHW)
			&& ((toolp->tl_flags & TOOL_ICONIC) != WT_ICONIC))
				refresh_txtwin(wt_pixwinp[win],
								&wt_swrect[win],
								wt_scrndata[win],
								&wt_curposp[win]);
			else
				wmgr_refreshwindow(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
		case 'S':
			wmgr_stretch(wt_toolwp[win]->tl_windowfd, rootfd);
			break;
#ifdef DeBug
		default:
			printf("||| bad window manager command %c (%d)\n", com_code2, com_code2);
			break;
#endif
		}
	}
}


/*--- two-number commands ------------------------------------------ */

set_icon_location()
{
	register int win, top, left;
	struct tool *toolp;

	if (com_charargs[0] == (NXTWINDOW_ID + 32))
	{
		nxtwin_iconpos.x = com_numargs[0];
		nxtwin_iconpos.y = com_numargs[1];
	}
	else if ((win = check_window_id(0)) != WT_NOWIN)
	{
		toolp = wt_toolwp[win];

		top = (int)(tool_get_attribute(toolp, WIN_TOP));
		left = (int)(tool_get_attribute(toolp, WIN_LEFT));

		tool_set_attributes(toolp,
				WIN_ICON_LEFT, com_numargs[0],
				WIN_ICON_TOP, com_numargs[1],
				WIN_TOP, top,
				WIN_LEFT, left,
				0);
	}
}

set_win_location()
{
	register int win;

	if (com_charargs[0] == (NXTWINDOW_ID + 32))
	{
		nxtwin_winpos.x = com_numargs[0];
		nxtwin_winpos.y = com_numargs[1];
	}
	else if ((win = check_window_id(0)) != WT_NOWIN)
	{
		tool_set_attributes(wt_toolwp[win],
			WIN_LEFT, com_numargs[0],
			WIN_TOP, com_numargs[1],
			0);
	}
}

set_internal_size()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		if (wt_active[win] == WT_GRAPHW)		/* size in pixels */
		{
/*
	horrible frigging here is because we want to set the dimensions of the
	subwindow, and Sun define these attributes as those of the outer window,
	whereas the line/column ones used below are understood to refer to the
	inner one.  the border on three sides is 5 pixels, hence add 10 to the
	width: on the top it is 2 pixels plus the height of the standard font.
*/
			tool_set_attributes(wt_toolwp[win],
								WIN_WIDTH, com_numargs[0] + 10,
								WIN_HEIGHT, com_numargs[1] + fontadv_y + 7,
								0);
		}
		else			/* size in characters */
		{
			tool_set_attributes(wt_toolwp[win],
				WIN_COLUMNS, com_numargs[0],
				WIN_LINES, com_numargs[1],
				0);
		}
	}
}


set_external_size()
{
	register int win, w, h;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		w = com_numargs[0];
		h = com_numargs[1];

#ifdef DeBug
	printf("setting external size1: w = %d, h = %d\n", w, h);
#endif
		if (wt_active[w] != WT_GRAPHW)
		{
			/* text window, and external size must be rounded down so
			*	that internal size exactly fits character grid.  See notes
			*	above for more details of nasty frigging
			*/
			if ((w = (w - 10) / fontadv_x) < 1) w = 1;
			w = w * fontadv_x + 10;
			if ((h = (h - 7) / fontadv_y) < 2) h = 2;
			h = h * fontadv_y + 7;
		}

#ifdef DeBug
	printf("setting external size2: w = %d, h = %d\n", w, h);
#endif
		tool_set_attributes(wt_toolwp[win],
								WIN_WIDTH, w, WIN_HEIGHT, h, 0);
	}
}

kill_window()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		if	(win == WT_FIRSTWIN)
			misprint(-1, "PWM: refusing to kill base window\n");
		else if ((wt_active[win] < WT_ACTIVE)
				 && (wt_active[win] != WT_FRAMEW))
    		misprint(win, "PWM: can't kill window %d, already dead\n");
		else
		{
#ifdef DeBug
			misprint(win, "--- accepting command to kill window %d\n");
#endif
			really_kill_window(win);
			if	(current_out == win) select_output_window(WT_FIRSTWIN);
		}

	}
	current_in = WT_NOWIN;	/* ensure poplog knows where input is coming
								*	from  - especially if the command failed
								*/
}

/*--- string-argument commands ------------------------------------- */

make_new_window()
{
	register int s2, i, c, r;
	char type, flags;

	c = com_numargs[0];
	r = com_numargs[1];
	type = com_charargs[1];
	flags = com_charargs[0] - 32;
#ifdef DeBug
	printf("--- mnw: making new window type=%c, flags=%d, %dx%d\n", type, flags, c, r);
#endif

	s2 = com_stringlen - 2;	/* last char in string */

	/* ved window: icon label copied after last /; others, split at tab */
	if (type == 'v') {
		while ((s2 > 0) && (com_stringarg[s2 - 1] != '/')) s2--;
	} else {
		while ((s2 > 0) && (com_stringarg[s2 - 1] != '\t')) s2--;
		if (s2 > 0) com_stringarg[s2 -1] = 0;
	}

	if (type == 't' || type == 'v')	/* window type: currently "t", "v" or "g" */
	{

		if (type == 't')
		{
			if ((i = new_vanilla_window(com_stringarg, com_stringarg + s2,
											r, c, &txticon,
											fontadv_y)) != WT_NOWIN)
			new_txt_window(i, r, c);
		}
		else
		{
			if ((i = new_vanilla_window(com_stringarg, com_stringarg + s2,
											r, c, &vedicon,
											fontadv_y)) != WT_NOWIN)
			new_txt_window(i, r, c);
		}

		current_in = WT_NOWIN;
		report_status(i);
	}
	else if (type == 'g')
	{
		if ((i = new_vanilla_window(com_stringarg, com_stringarg + s2,
									r + fontadv_y + 7, c + 10,
									&gfxicon, 0)) != WT_NOWIN)
			new_gfx_window(i, r, c);

		report_status(i);
	}
	else
	{
		misprint(type, "PWM: bad type for window: %d\n");
		report_status(WT_NOWIN);
	}
}


/*--------------------------------------------------------------------
*	kill all windows not mentioned in the command argument.
*	This is basically used when poplog tries to make a window and gets back
*	a garbled message - it may be that the PWM has made the window, but
*	(probably because of user type-ahead) poplog doesn't know the number,
*	and never will.  So it tells the PWM about all the windows it knows of,
*	and the PWm kills any other live ones.
*
*		a) It is not clear what should be done if it mentions a window
*			that the PWM doesn't know about
*
*		b) it might be better to simply have a command which says "what
*			was the number of that last window?"
*/
tidy_windows()
{
/*	register int i;*/
	int i;
	char nn, nc;

	com_stringlen--;
	for (nn = WT_FIRSTWIN + 1; nn <= WT_LASTWIN; nn++)
		if (wt_active[nn] >= WT_ACTIVE)
		{
			nc = nn + 32;

			for (i = 0; i < com_stringlen; i++)
				if (com_stringarg[i] == nc)
				{
#ifdef DeBug
					printf("tidy: not killing window %d\n", nn);
#endif
					break;
				}

			if (i >= com_stringlen)
			{
				really_kill_window(nn);
#ifdef DeBug
					printf("tidy: killing window %d\n", nn);
#endif
			}
		}
}

set_win_title()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		tool_set_attributes(wt_toolwp[win], WIN_LABEL, com_stringarg, 0);
	}
}

set_icon_title()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		tool_set_attributes(wt_toolwp[win], WIN_ICON_LABEL, com_stringarg, 0);
	}
}

set_icon_image()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		misprint(-1, "PWM: setting icon image from line not currently supported\n");
	}
}

/*--------------------------------------------------------------------
*	doesn't work, and no time to find out why
*/
set_icon_file()
{
/*	struct icon newicon;*/
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		misprint(-1, "PWM: setting icon image from file not currently supported\n");
	}
/*
	if (icon_load(&newicon, com_stringarg, buf) == 0)
		fprintf(stderr, "PWM: iconload failed: %s\n", buf);
	else
	{
		tool_set_attributes(wt_toolwp[win], WIN_ICON, &newicon, 0);
		tool_free_attribute(WIN_ICON, &newicon);
	}
*/
}

/*--- one-number commands ------------------------------------------ */

set_text_window()
{
	register int win;

	if ((win = check_window_id(0)) == WT_NOWIN)
		report_status(PWM_STATUS_FAILED);
	else
	{
		if	(win != current_out) select_output_window(win);
	}
}

/*--------------------------------------------------------------------
*	the function of this command is to arrange that unless the user does
*	something to avoid it, their next input will go to the argument window.
*	on the Sun, this is done by ensuring the window is fully visible, and
*	moving the mouse into it  (it would be neater to check, after opening
*	the window, whether the mouse is now within it, and if so avoid moving
*	it: but this is surprisingly laborious.  Perhaps in the next version?)
*/
set_input_source()
{
	register int win;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		wmgr_open(wt_toolwp[win]->tl_windowfd, rootfd);
		win_setmouseposition(wt_swfd[win], 4, 4);
    }
}

various_command()
{
#ifdef DeBug
	printf("--- various command: %c (%d)\n", com_charargs[0], com_charargs[0]);
#endif
	switch (com_charargs[0])
	{
	case '0':		/* PWMCOM_EXTERN */
		poplog_connected = poplog_listening = FALSE;
		base_cooked = ved_cooked = co_winiscooked = FALSE;
		/* clearall */
		break;
	case '1':		/* PWMCOM_CONNECTED */
		poplog_connected = poplog_listening = TRUE;
		base_cooked = co_winiscooked = TRUE;
		break;
	case '2':		/* PWMCOM_SUSPENDED */
		poplog_listening = co_winiscooked = FALSE;
		break;
	case '3':		/* PWMCOM_RESTORED */
		poplog_listening = TRUE;
		if (current_out == 0)
			co_winiscooked = base_cooked;
		else if (wt_active[current_out] == WT_VEDWIN)
			co_winiscooked = ved_cooked;
		break;
	case '4':
		base_cooked = TRUE;
		if (current_out == 0) co_winiscooked = TRUE;
		break;
	case '5':
		base_cooked = FALSE;
		if (current_out == 0) co_winiscooked = FALSE;
		break;
	case '6':
		ved_cooked = TRUE;
		if (wt_active[current_out] == WT_VEDWIN) co_winiscooked = TRUE;
		break;
	case '7':
		ved_cooked = FALSE;
		if (wt_active[current_out] == WT_VEDWIN) co_winiscooked = FALSE;
		break;
    case '8':
		current_in = WT_NOWIN;	/* ensure source of next input reported */
		break;
	case '9': 		/* toggle shift_escape flag */
		shift_escape = (shift_escape ? FALSE : TRUE);
		break;
	default:
#ifdef DeBug
		printf("||| bad various command: %d\n", com_numargs[0]);
#endif
		break;
	}
}

/* -- currently unsupported functions------------------------------- */

ved_number_command()
{
#ifdef DeBug
	printf("=== set (ved) line number to %d\n", com_numargs[0]);
#endif
}

ved_scroll_left()
{
#ifdef DeBug
	printf("=== (ved) scroll left from %d by %d\n", com_numargs[0], com_numargs[1]);
#endif
}

ved_scroll_right()
{
#ifdef DeBug
	printf("=== (ved) scroll right from %d by %d\n", com_numargs[0], com_numargs[1]);
#endif
}

set_elevator_pos()
{
#ifdef DeBug
	misprint(com_numargs[0], "=== set scroller position to %d\n");
#endif
}

set_elevator_size()
{
#ifdef DeBug
	printf(com_numargs[0], "=== set scroller size to %d\n");
#endif
}


/*--- utilities used by command procedures ------------------------- */

/*--------------------------------------------------------------------
*	takes index to supposed window-id in array of character args, and
*	returns the win-id if there is one, WT_NOWIN else (and complains
*	in the else case)
*/
check_window_id(i)
register int i;
{
	i = com_charargs[i] - 32;

	if (i == WT_NOWIN)
		misprint(-1, "PWM: can't operate on window #-1: no such window\n");
	else if (i == NXTWINDOW_ID)
		misprint(-1, "PWM: can't preset for this attribute\n");
	else if (i == TXTWINDOW_ID)
		if ((i = current_out) == WT_NOWIN)
			misprint(-1, "PWM: can't use current text window: not set\n");
		else
			return(i);
	else if (i == GFXWINDOW_ID)
		if ((i = current_graf) == WT_NOWIN)
			misprint(-1, "PWM: can't use current gfx window: not set\n");
		else
			return(i);
	else if	((i < WT_FIRSTWIN) || (i > WT_LASTWIN))
		misprint(i, "PWM: can't operate on window #%d: not active\n");
	else if	(wt_active[i] >= WT_ACTIVE)
		return(i);
	else
		misprint(i, "PWM: can't operate on window #%d: not active\n");

	return(WT_NOWIN);
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ----1---Copyright University of Sussex 1987.  All rights reserved. ------
::    21:  cursor_address()
::    70:  ansi_cursor_address()
::    75:  winmgr_commands()
:: --132---two-number commands ------
::   134:  set_icon_location()
::   160:  set_win_location()
::   178:  set_internal_size()
::   209:  set_external_size()
::   241:  kill_window()
:: --267---string-argument commands ------
::   269:  make_new_window()
::   344:  tidy_windows()
::   375:  set_win_title()
::   385:  set_icon_title()
::   395:  set_icon_image()
::   408:  set_icon_file()
:: --428---one-number commands ------
::   430:  set_text_window()
::   450:  set_input_source()
::   461:  various_command()
:: --517---currently unsupported functions------
::   519:  ved_number_command()
::   526:  ved_scroll_left()
::   533:  ved_scroll_right()
::   540:  set_elevator_pos()
::   547:  set_elevator_size()
:: --555---utilities used by command procedures ------
::   562:  check_window_id(i)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwcommand.c,v $
 * Revision 1.2  89/08/23  16:18:28  pop
 * added mask in pw_char for use with gp1 buffer
 * 
 * Revision 1.1  89/08/23  13:19:52  pop
 * Initial revision
 * 
*/
