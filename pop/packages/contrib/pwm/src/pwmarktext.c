/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwmarktext.c
 * Purpose:		highlighting ranges of text in a PWM window
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwmarktext.c,v 1.1 89/08/23 13:20:45 pop Exp $
 */

#include "pwdec.h"

/*--------------------------------------------------------------------
*	invert text in a window, from start position to end position.  If
*	the window is a ved window, leave the first column alone.  If mode
*	is zero, invert only to the first character  after the last non-
*	white-space char on the line - otherwise invert to the right edge
*	of the window
*/
invert_text_area(win, start, end, mode)
int win, mode;
struct xypos *start, *end;
{
	int widthc, x1, x2, lmarg;
    char **textmap;
	struct pixwin *pwp;

	/* indent left margin by 1 char if ved window */
/*	lmarg = ((wt_active[win] == WT_VEDWIN) ? 1 : 0);*/
	if (wt_active[win] == WT_VEDWIN)
		lmarg = 1;
	else
		lmarg = 0;
#ifdef DeBug
	printf("ITA: win=%d, act=%d, WTV=%d, lmarg=%d\n",
								win, wt_active[win], WT_VEDWIN, lmarg);
#endif

	if (start->x != -1)
	{
		widthc = (wt_scrndata[win])->cols;
		textmap = (wt_scrndata[win])->text;
		pwp = wt_pixwinp[win];

		if (start->y == end->y)	/* all on one line */
		{
			if (start->x > end->x)		/* swap them */
			{
				register struct xypos *temp;

				temp = start;
				start = end;
				end = temp;
			}

			x1 = max(lmarg, min(start->x,
							findendofline(textmap[start->y], widthc, mode)));
			x2 = max(lmarg, min(end->x,
							findendofline(textmap[start->y], widthc, mode)));

			pw_writebackground(pwp,
					txtcoord_pix_x(x1),
					start->y * fontadv_y,
					(x2 - x1 + 1) * fontadv_x,
					fontadv_y, PIX_NOT(PIX_DST));
		}
		else
		{
			int y;

			if (start->y > end->y)		/* swap them */
			{
				register struct xypos *temp;

				temp = start;
				start = end;
				end = temp;
			}

			x1 = max(lmarg, findendofline(textmap[start->y], widthc, mode));
			x2 = max(lmarg, min(x1, start->x));

			pw_writebackground(pwp,
					txtcoord_pix_x(x2), start->y * fontadv_y,
					(x1 + 1 - x2) * fontadv_x, fontadv_y,
					PIX_NOT(PIX_DST));

			x2 = max(lmarg, min(end->x,
						findendofline(textmap[end->y], widthc, mode)));

			pw_writebackground(pwp,
					lmarg * fontadv_x,
					end->y * fontadv_y,
					(x2 + 1 - lmarg) * fontadv_x,
					fontadv_y,
					PIX_NOT(PIX_DST));

			for (y = start->y + 1; y < end->y; y++)
			{
				x1 = max(lmarg, findendofline(textmap[y], widthc, mode));

				pw_writebackground(pwp,
					lmarg * fontadv_x,
					y * fontadv_y,
					(x1 + 1 - lmarg) * fontadv_x,
					fontadv_y,
					PIX_NOT(PIX_DST));
			}
		}
	}
}

/*--------------------------------------------------------------------
*	returns 1 if pos1 is before pos2, 0 else
*/
direction(pos1, pos2)
struct xypos *pos1, *pos2;
{
	if (pos1->y < pos2->y)	return(1);
	else if (pos1->y > pos2->y)	return(0);
	else if (pos1->x < pos2->x)	return(1);
	else return(0);
}

adjust_text_highlight(win, fixed, oldpos, newpos, mode)
int win, mode;
struct xypos *fixed, *oldpos, *newpos;
{
	if ((oldpos->x == -1) || (newpos->x == -1)
		|| (direction(fixed, newpos) != direction(fixed, oldpos)))
	{
		if (oldpos->x != -1)
			invert_text_area(win, fixed, oldpos, mode);
		if (newpos->x != -1)
			invert_text_area(win, fixed, newpos, mode);
	}
	else	/* optimise... */
	{
		if (direction(fixed, oldpos) == direction(oldpos, newpos))
			invert_text_area(win, oldpos, oldpos, mode);
		else
			invert_text_area(win, newpos, newpos, mode);

		invert_text_area(win, newpos, oldpos, mode);
	}
}

/*--------------------------------------------------------------------
*	take a line (a string) and return the index to the character after
*	the last non-space character, (or to the last character if not space),
*	having regard to the maximum sensible value for the index.  It also
*	takes a flag which, if true, causes it to simply return the maximum value
*	that was passed to it.  This is of course wildly inefficient but makes
*	various callers simpler.
*/
findendofline(line, maxi, mode)
char *line;
int maxi, mode;
{
	int end;

	if (mode == MRK_LINEMODE)
		if (line[--maxi] == 32)
			for (; (maxi != 0) && (line[maxi - 1] == 32); maxi--) {};

	return(maxi);
}

/*--------------------------------------------------------------------
*	this handles a command from poplog
*/
highlight_text()
{
	register int win;
	struct xypos start, end;

	if ((win = check_window_id(0)) != WT_NOWIN)
	{
		start.x = com_numargs[0];
		start.y = com_numargs[1];
		end.x = com_numargs[2];
		end.y = com_numargs[3];
		invert_text_area(win, &start, &end, com_charargs[1] - 32);
	}
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    16:  invert_text_area(win, start, end, mode)
::   112:  direction(pos1, pos2)
::   121:  adjust_text_highlight(win, fixed, oldpos, newpos, mode)
::   152:  findendofline(line, maxi, mode)
::   168:  highlight_text()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwmarktext.c,v $
 * Revision 1.1  89/08/23  13:20:45  pop
 * Initial revision
 * 
*/
