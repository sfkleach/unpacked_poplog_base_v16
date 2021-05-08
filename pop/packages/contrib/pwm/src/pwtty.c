/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:			$usepop/master/C.sun/pwm/pwtty.c
 * Purpose:			basic terminal emulator functions for Sun PWM
 * Author:			Ben Rubinstein, Jan  8 1987
 * Related Files:	PWV200.C
 * $Header: /popv13.5/pop/pwm/RCS/pwtty.c,v 1.2 89/08/23 17:50:09 pop Exp $
 */

#include "pwdec.h"


/*--------------------------------------------------------------------
*   unpaint the cursor at the current position in current output window,
*	 repaint at the given coordinates (coords in characters, top-left of
*    window is 0, 0).	CAN ONLY BE GIVEN SENSIBLE COORDINATES.
*/
jump_cursor(x, y)
int x, y;
{
	/* rubout old cursor */
	pw_char(co_pixwinp, co_curposp->x, co_curposp->y, PIX_SRC,
                norm_font, (co_text[co_curposc->y][co_curposc->x])&0x7f);

	/* set new cursor-coords */
	co_curposp->x = txtcoord_pix_x(co_curposc->x = x);
	co_curposp->y = txtcoord_pix_y(co_curposc->y = y);

	/* display new cursor */
	Paint_cursor;
}


/*--------------------------------------------------------------------
*	ordinary printable characters - replace mode
*/
co_replace_char(code)
int code;
{
	int i;
#ifdef DeBug
	if (co_ceolneeded != 0) printf("||| crc: ceol flag still on\n");
#endif

	/* write the char in memory */
	co_text[co_curposc->y][co_curposc->x] = code;

	/* print the char on screen, over cursor etc */
	pw_char(co_pixwinp, co_curposp->x, co_curposp->y,
								PIX_SRC, norm_font, code&0x7f);

	/* adjust the cursor position */
	if	(co_curposc->x != co_widthc - 1)
		co_curposp->x = txtcoord_pix_x(co_curposc->x = co_curposc->x + 1);
	else
		if (co_winiswrap == TRUE) co_cursor_nextpos();

	/* repaint the cursor at new position */
	Paint_cursor;
}

/*--------------------------------------------------------------------
*	will only get printable chars - nl is flag: if non-zero, do a newline
*	after printing text.
*	first is index to first character, last is index to last character.
*	if the flag "co_ceolneeded" is true (1) then a "clear end of line" was
*	requested immediately before this text was sent, and was not done - so
*	we must take care of it here.
*/
co_buffer_replace(first, last, nl)
int first, last;
char nl;
{
	int x, xlim;
	char c, *l;

	x = co_curposc->x;
	xlim = co_widthc - 1;
	l = co_text[co_curposc->y];

	if	(x == xlim)	/* at right margin - overlay char, don't move cursor, */
	{				/*	and no need to do the clear end of line stuff     */
		l[x] = (c = (com_buffer[last] | term_grafmode));

		pw_char(co_pixwinp, co_curposp->x, co_curposp->y,
								PIX_SRC, norm_font, c&0x7f);
	}
	else
	{
		register int i;

		/* write the chars in memory */
	 	for (i = first; ((i < last) && (x < xlim)) ;)
			l[x++] = com_buffer[i++] | term_grafmode;

		l[x] = com_buffer[last] | term_grafmode;

		if ((x != xlim) && (co_ceolneeded == 1))
		{
			for (i = x; i < xlim; l[++i] = ' ');
		}

		/* print the text on screen, over cursor etc */
		pw_text(co_pixwinp, co_curposp->x, co_curposp->y, PIX_SRC,
						norm_font, l + co_curposc->x);

		/* adjust the cursor position */
		if (nl == 0)	/* else done below */
		{
			if	(x == xlim)
				co_curposp->x = txtcoord_pix_x(co_curposc->x = x);
			else
				co_curposp->x = txtcoord_pix_x(co_curposc->x = x + 1);
		}
	}

	if (nl != 0) 	/* newline: set the new cursor position */
	{
		int y;

		co_curposp->x = co_curposc->x = 0;

		if	(co_heightc <= (y = co_curposc->y + 1))
			co_scroll_up();
		else
			co_curposp->y = txtcoord_pix_y(co_curposc->y = y);
	}

	/* repaint the cursor at new position */
	Paint_cursor;

	/* ensure this flag has been turned off again */
	co_ceolneeded = 0;
}

/*--------------------------------------------------------------------
*	ordinary printable characters - insert mode
*/
co_insert_char(code)
int code;
{
	int i;
	char *line;

#ifdef DeBug
	if (co_ceolneeded != 0) printf("||| cic: ceol flag still on\n");
#endif

	line = co_text[co_curposc->y];

	/* write the char in memory, pushing tail to right */
	for (i = co_widthc - 1; i > co_curposc->x; i--)
		line[i] = line[i - 1];

	line[co_curposc->x] = code;

	/* refresh tail of line */
	pw_text(co_pixwinp, co_curposp->x, co_curposp->y,
								PIX_SRC, norm_font, line + co_curposc->x);

	/* adjust the cursor position */
	if	(co_curposc->x != co_widthc - 1)
		co_curposp->x = txtcoord_pix_x(++co_curposc->x);

	/* repaint the cursor at new position */
	Paint_cursor;
}

/*--------------------------------------------------------------------
*	actually ved never seems to stay in insert mode for more than one
*	character, except in tabs.
*	first is index to first character, last is index to last character.
*/
co_buffer_insert(first, last, nl)
int first, last;
char nl;
{
	register int i;
	int l, y;
	register char *line;

#ifdef DeBug
	if (co_ceolneeded != 0) printf("||| cbi: ceol flag still on\n");
#endif

	line = co_text[co_curposc->y];
	l = last - first + 1; /* length of new string */

	/* push chars to right in memory */
	for (i = co_widthc - 1; i > co_curposc->x; i--)
		line[i] = line[i - l];

	/* put in new chars */
	for (i = 0; i < l; i++)
		line[i + co_curposc->x] = com_buffer[first + i] | term_grafmode;

	pw_lock(co_pixwinp, &co_rect);

	/* refresh tail of line */
	pw_text(co_pixwinp, co_curposp->x, co_curposp->y,
								PIX_SRC, norm_font, line + co_curposc->x);

	/* adjust the cursor position */
	if (nl == 0)
	{
		if	(co_curposc->x != co_widthc - 1)
			co_curposp->x = txtcoord_pix_x(co_curposc->x = co_curposc->x + l);
	}
	else			/* newline */
	{
		co_curposp->x = co_curposc->x = 0;

		if	(co_heightc <= (y = co_curposc->y + 1))
			co_scroll_up();
		else
			co_curposp->y = txtcoord_pix_y(co_curposc->y = y);
	}

	/* repaint the cursor at new position */
	Paint_cursor;

	pw_unlock(co_pixwinp);
}

/*--------------------------------------------------------------------
*	this is v200 esc-O: delete character under the cursor, pull characters
*	to the right left one position; do not move cursor.
*		!!! this would be worth optimising: (veddeletewordleft etc): but
*	hard, because it's a two character sequence.	!!!
*/
delete_character(code)
int code;
{
	int i;
	char *line;

	line = co_text[co_curposc->y];

	/* delete the char in memory, pulling tail to left */
	for (i = co_curposc->x; i < co_widthc - 1; i++)
		line[i] = line[i + 1];
	line[i] = ' ';

	/* refresh tail of line */
	pw_text(co_pixwinp, co_curposp->x, co_curposp->y,
								PIX_SRC, norm_font, line + co_curposc->x);

	/* repaint the cursor */
	Paint_cursor;
}


co_carriage_return()
{
	Remove_cursor;	/* remove the cursor from the last position */

	/* set the new cursor position */
	co_curposp->x = co_curposc->x = 0;

	Paint_cursor;	/* repaint the cursor at the new position */
}

co_tab()
{
	Remove_cursor;	/* remove the cursor from the last position */

	/* set the new cursor position */
	co_cursor_nextpos();
	while	((co_curposc->x) % 8 != 0)
		co_cursor_nextpos();

	Paint_cursor;	/* repaint the cursor at the new position */
}

co_line_feed()
{
	Remove_cursor;	/* remove the cursor from the last position */

	/* set the new cursor position */
	if	(co_curposc->y + 1 >= co_heightc)
		co_scroll_up();
	else
	{
		co_curposc->y++;
		co_curposp->y = txtcoord_pix_y(co_curposc->y);
	}


	Paint_cursor; 	/* repaint the cursor at the new position */
}


/*--------------------------------------------------------------------
* 	this is what we do for 127 <DEL>: delete the character to the left of
*		of the cursor, move the cursor one position to the left.
*		do not move if already at left margin.
*/
co_delete()
{
	if	(co_curposc->x != 0)
	{
		Remove_cursor;

		co_curposp->x = txtcoord_pix_x(--co_curposc->x);

		/* clear the char in memory */
		co_text[co_curposc->y][co_curposc->x] = ' ';

		/* paint the cursor over it on screen */
		Paint_cursor;
	}
}

/*--------------------------------------------------------------------
*	adjust cursor position records for the next availiable position,
*	scrolling if necessary.
*/
co_cursor_nextpos()
{
	co_curposc->x++;

	if	(co_curposc->x >= co_widthc)
	{
		co_curposc->x = 0;

		if	(co_curposc->y + 1 >= co_heightc)
		{
			co_scroll_up();
		}
		else
		{
			co_curposc->y++;
			co_curposp->y = txtcoord_pix_y(co_curposc->y);
		}
	}

	co_curposp->x = txtcoord_pix_x(co_curposc->x);
}

/*--------------------------------------------------------------------
*		scroll the whole of the current window up one line
*/
co_scroll_up()
{
	register int i;
	char *topline;

	/* scroll the character map */
	topline = co_text[0];	/* we don't want the data in't, just the space */

	for (i = 0; i < co_heightc - 1; i++)
		co_text[i] = co_text[i + 1];

	co_text[i] = topline;	/* use top line string for bottom line */

	/* clear bottom line of character map */
	for (i = 0; i < co_widthc; i++) topline[i] = ' ';

	/* scroll on screen */
	pw_rop(co_pixwinp, 0, 0, co_widthp, co_heightp,
					PIX_SRC, co_pixwinp->pw_prretained, 0, fontadv_y);

	pw_writebackground(co_pixwinp, 0, co_botlinetop,
						co_widthp, co_botlineheight, PIX_CLR);
}


/*--------------------------------------------------------------------
*	invert the top line of the window (usually the status line)
*	for a short time.   An audible bell would be useful (eg for current
*	input window).  The top line of the window is sensible for ved, but a
*	bit silly for the 'base window' - it should do something else.
*/
visible_bell()
{
	pw_writebackground(co_pixwinp, 0, 0,		/* coords of top-left */
							(wt_swrect[current_out]).r_width,
							fontadv_y,
							PIX_NOT(PIX_DST));

	signal(SIGALRM, identfn);
	itval1.it_value.tv_sec  = itval1.it_interval.tv_sec = 0;
	itval1.it_value.tv_usec = itval1.it_interval.tv_usec = VW_BELL_TIME;
	setitimer(ITIMER_REAL, &itval1, &itval2);

	pause();

	pw_writebackground(co_pixwinp, 0, 0,		/* y coord of top-left */
							(wt_swrect[current_out]).r_width,
							fontadv_y,
							PIX_NOT(PIX_DST));

	itval1.it_value.tv_sec  = itval1.it_interval.tv_sec = 0;
	itval1.it_value.tv_usec = itval1.it_interval.tv_usec = 0;
	setitimer(ITIMER_REAL, &itval1, &itval2);
}

co_control_you()
{
	co_insert_char('^');
	co_insert_char('U');
}

/*--------------------------------------------------------------------
*	handle all codes < 128 (which should never appear in any case)
*/
co_window_output(code)
char code;
{
	if	(code == 127)
		co_delete();
	else if (code >= ' ')
		co_charpr(code | term_grafmode);
	else
		switch (code)
		{
		case 0: 	/* ved uses this as a flush - just ignore it */
			break;
		case 1:		/* don't print: vedwiggle sends this to cause a delay! */
			break;
		case 7:
			visible_bell();
    		break;
		case 8:
			cursor_left();
    		break;
		case 9:
			co_tab();
    		break;
		case 10:
			co_line_feed();
			if (co_winiswrap) co_carriage_return();
    		break;
		case 12:
			clear_page();
    		break;
		case 13:
			co_carriage_return();
    		break;
		case 21:
			co_control_you();
    		break;
		default:
			co_insert_char('^');
			co_insert_char(code + 64);
		}
	/* end of if */
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    16:  jump_cursor(x, y)
::    35:  co_replace_char(code)
::    68:  co_buffer_replace(first, last, nl)
::   137:  co_insert_char(code)
::   172:  co_buffer_insert(first, last, nl)
::   229:  delete_character(code)
::   251:  co_carriage_return()
::   261:  co_tab()
::   273:  co_line_feed()
::   296:  co_delete()
::   316:  co_cursor_nextpos()
::   341:  co_scroll_up()
::   372:  visible_bell()
::   396:  co_control_you()
::   405:  co_window_output(code)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwtty.c,v $
 * Revision 1.2  89/08/23  17:50:09  pop
 * added mask with 0x7f for use with gp1 buffer
 * 
 * Revision 1.1  89/08/23  13:21:17  pop
 * Initial revision
 * 
*/
