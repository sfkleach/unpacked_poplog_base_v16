/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:			$usepop/master/C.sun/pwm/pwv200.c
 * Purpose:			v200 terminal control commands
 * Author:			Ben Rubinstein, Feb 20 1987
 * Related Files:	PWTTY.C
 * $Header: /popv13.5/pop/pwm/RCS/pwv200.c,v 1.1 89/08/23 13:21:20 pop Exp $
 */

#include "pwdec.h"

/*--------------------------------------------------------------------
*	send same id as v200
*/
send_terminal_id()
{
	send_to_poplog(27);
	send_to_poplog('/');
	send_to_poplog('K');
}

/*--------------------------------------------------------------------
*	cursor up: no scroll, no going beyond margins
*/
cursor_up()
{
	if	(co_curposc->y != 0)
	{
		Remove_cursor;	/* unpaint the cursor */
		co_curposp->y = txtcoord_pix_y(--co_curposc->y);
		Paint_cursor;	/* paint the cursor in new position */
	}
}

/*--------------------------------------------------------------------
*	cursor down: no scroll, no going beyond margins
*/
cursor_down()
{
	if	(co_curposc->y < co_heightc)
	{
		Remove_cursor;	/* unpaint the cursor */
		co_curposp->y = txtcoord_pix_y(++co_curposc->y);
		Paint_cursor;	/* paint the cursor in new position */
	}
}

/*--------------------------------------------------------------------
*	cursor left: no scroll, no going beyond margins
*/
cursor_left()
{
	if	(co_curposc->x != 0)
	{
		Remove_cursor;	/* unpaint the cursor */
		co_curposp->x = txtcoord_pix_x(--co_curposc->x);
		Paint_cursor;	/* paint the cursor in new position */
	}
}

/*--------------------------------------------------------------------
*	cursor right: no scroll, no going beyond margins
*/
cursor_right()
{
	if	(co_curposc->x < co_widthc)
	{
		Remove_cursor;	/* unpaint the cursor */
		co_curposp->x = txtcoord_pix_x(++co_curposc->x);
		Paint_cursor;	/* paint the cursor in new position */
	}
}

/*--------------------------------------------------------------------
*	this is v200 "esc-L": scroll the line which cursor is now on, and all
*		lines below it, down one; blank out this line, and leave the cursor
* 		at the start of it.
*/
insert_line()
{
	register int i;
	int ystart;
	char *line, *lastline;

	Remove_cursor;					/* unpaint the cursor */

	/* do it in the character map */
	lastline = co_text[co_heightc - 1];	/* we don't want the data in't, just the space */

	for (i = co_heightc - 1; i > co_curposc->y; i--)
		co_text[i] = co_text[i-1];

	co_text[i] = lastline;								/* just the space... */

	for (i = 0; i < co_widthc; ) lastline[i++] = ' ';	/* and blank it */

	co_curposp->x = co_curposc->x = 0;				/* move the cursor */

	/* do on screen */
	ystart = font_home_y + co_curposp->y;

	/* scroll down... */
	pw_copy(co_pixwinp, 0, ystart + fontadv_y, co_widthp, co_heightp, PIX_SRC,
					co_pixwinp, 0, ystart);

	/* ... blank the cursor line */
	pw_writebackground(co_pixwinp, 0, ystart, co_widthp, fontadv_y, PIX_CLR);

	/* ... and repaint cursor */
	Paint_cursor;
}


/*--------------------------------------------------------------------
*	this is v200 "esc-M": delete the line that the cursor is now on,
*		and scroll all the lines below it up one; blank out the bottom line,
*		and leave the cursor at the left margin.
*/
delete_line()
{
	register int i;
	int ystart;
	char *lastline;

	/* do it in the character map */
	lastline = co_text[co_curposc->y];	/* not for the data, just the space */

	for (i = co_curposc->y; i < co_heightc - 1; i++)
		co_text[i] = co_text[i+1];

	co_text[i] = lastline;								/* just the space... */

	for (i = 0; i < co_widthc; ) lastline[i++] = ' ';	/* and blank it */

	/* move the cursor... */
	co_curposp->x = co_curposc->x = 0;

	/* do on screen */
	ystart = fontadv_y * co_curposc->y;

	/* scroll up ... */
	pw_copy(co_pixwinp, 0, ystart, co_widthp, co_heightp, PIX_SRC,
					co_pixwinp, 0, ystart + fontadv_y);

	/* ... blank the bottom line */
	pw_writebackground(co_pixwinp, 0, co_botlinetop,
									co_widthp, co_botlineheight, PIX_CLR);

	/* ... and repaint cursor */
	Paint_cursor;
}



/*--------------------------------------------------------------------
*	this is v200 "esc-t": clear the whole of the line on which the cursor
* 						is currently, cursor to start of line
*/
clear_line()
{
	int ci;

	/* clear the line on screen*/
	pw_writebackground(co_pixwinp,
							0,	/* x coord of top-left */
							co_curposp->y + font_home_y,
								/* y-coord of top left: funny, because
									characters need position specified
									in terms of their baseline, so curposc
									is valued accordingly */
							co_rect.r_width,
							fontadv_y,
							PIX_CLR);

	/* and clear the line in memory */
	for	(ci = 0; ci < co_widthc; ci++)
		co_text[co_curposc->y][ci] = ' ';

	/* adjust cursor position */
	co_curposc->x = 0;
	co_curposp->x = txtcoord_pix_x(co_curposc->x);

	/* repaint the cursor */
	Paint_cursor;
}

/*--------------------------------------------------------------------
* 	this is v200 "esc-v": wipe whole screen, cursor to home.
*/
clear_page()
{
	int ri, ci;
	char *line;

	/* clear the pixwin */
	pw_writebackground(co_pixwinp, 0, 0,
							co_rect.r_width,
							co_rect.r_height,
							PIX_CLR);

	/* clear the internal image */
	for (ri = 0; ri < co_heightc; ri++)
		for (ci = 0; ci < co_widthc; ci++)
			co_text[ri][ci] = ' ';

	/* adjust cursor position */
	co_curposc->x = 0;
	co_curposc->y = 0;
	co_curposp->x = txtcoord_pix_x(co_curposc->x);
	co_curposp->y = txtcoord_pix_y(co_curposc->y);

	/* repaint the cursor */
	Paint_cursor;

}

/*--------------------------------------------------------------------
*	this is v200 "esc-x": clear to end of line on which the cursor
* 						is currently, don't move cursor
*	ved refreshes by "text. nl. c-eol. text. nl. c-eol...".  newlines
*	following text are already optimised, so spotting that this is followed
*	by text, and then letting the buffered text replace routine take care of
*	clearing the line first makes for speed.
*/
clear_endof_line()
{
	register int ci;

	if ((com_bufnext < com_buflen) && (term_insrtmode == FALSE) &&
		((ci = com_buffer[com_bufnext]) > 31) && (ci < 127))
	{
		/* then the text output routine will be called next, so don't clear */
		co_ceolneeded = 1;
	}
	else
	{
		/* clear the line on screen*/
		pw_writebackground(co_pixwinp,
								co_curposp->x,		/* x coord of top-left */
								co_curposp->y + font_home_y,
									/* y-coord of top left: funny, because
										characters need position specified
										in terms of their baseline, so curposp
										is valued accordingly */
								co_rect.r_width - co_curposp->x,
								fontadv_y,
								PIX_CLR);

		/* and clear the line in memory */
		for	(ci = co_curposc->x; ci < co_widthc; ci++)
			co_text[co_curposc->y][ci] = ' ';

		/* repaint the cursor */
		Paint_cursor;				/* !!! should be redundisable */
	}
}

/*--------------------------------------------------------------------
*	this is v200 "esc-y": clear from cursor position to end of screen
* 					and don't move the cursor.
*/
clear_endof_page()
{
	int ci, ri, tly;

	/* clear the line on screen*/
	pw_writebackground(co_pixwinp,
							co_curposp->x,		/* x coord of top-left */
							co_curposp->y + font_home_y,
								/* y-coord of top left: funny, because
									characters need position specified
									in terms of their baseline, so curposc
									is valued accordingly */
							co_rect.r_width - co_curposp->x,
							fontadv_y,
							PIX_CLR);

	/* and clear the line in memory */
	for	(ci = co_curposc->x; ci < co_widthc; ci++)
		co_text[co_curposc->y][ci] = ' ';

	/* clear the lines below on screen*/
	tly = txtcoord_pix_y(co_curposc->y + 1) + font_home_y;
			/* y-coord of top left: funny, because characters need position
			*	specified in terms of their baseline, so curposc is valued
			*	accordingly
			*/

	pw_writebackground(co_pixwinp,
							0, tly, 		/* coords of top-left */
							co_rect.r_width,
							co_rect.r_height - tly,
							PIX_CLR);

	/* clear the lines below in memory */
	for	(ri = co_curposc->y + 1; ri < co_heightc; ri++)
		for	(ci = 0; ci < co_widthc; ci++)
			co_text[ri][ci] = ' ';

	/* repaint the cursor */
	Paint_cursor;				/* !!! should be redundisable */
}

set_graphic_mode()
{
	term_grafmode = TFLG_GRAFMODE;
#ifdef DeBug
	printf("--- sgm: grafmode now $%x\n", term_grafmode);
#endif
}

reset_graphic_mode()
{
	term_grafmode = FALSE;
#ifdef DeBug
	printf("--- rgm: grafmode now $%x\n", term_grafmode);
#endif
}

home_cursor()
{
	jump_cursor(0, 0);
}

set_insert_mode()
{
	co_charpr = co_insert_char;
	co_bufferpr = co_buffer_insert;
	term_insrtmode = TFLG_INSERTMODE;
}

reset_insert_mode()
{
	co_charpr = co_replace_char;
	co_bufferpr = co_buffer_replace;
	term_insrtmode = FALSE;
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    13:  send_terminal_id()
::    24:  cursor_up()
::    37:  cursor_down()
::    50:  cursor_left()
::    63:  cursor_right()
::    78:  insert_line()
::   118:  delete_line()
::   158:  clear_line()
::   189:  clear_page()
::   224:  clear_endof_line()
::   261:  clear_endof_page()
::   303:  set_graphic_mode()
::   311:  reset_graphic_mode()
::   319:  home_cursor()
::   324:  set_insert_mode()
::   331:  reset_insert_mode()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwv200.c,v $
 * Revision 1.1  89/08/23  13:21:20  pop
 * Initial revision
 * 
*/
