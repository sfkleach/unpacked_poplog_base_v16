/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwscrn.c
 * Purpose:		making and remaking character maps for text windows
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwscrn.c,v 1.1 89/08/23 13:21:09 pop Exp $
 */

#include "pwdec.h"

/* -------------------------------------------------------------
*	we need to allocate space for <rows> arrays of characters,
*		each <columns> + 1 long;
*		and one array of <rows> pointers to char arrays.
*/
struct screen_record *make_screen_record(rows, columns)
int rows, columns;
{
	int i;
	char *p;
	char **screen_text;
	struct screen_record *scr_rec;

	/* make the array for all the lines */
	screen_text = (char **) calloc(rows, sizeof(char *));

	/* then make an array for each line, and save the screen */
	for (i = 0; i < rows; i++)
	{
		p = (char *) calloc((columns + 1), sizeof(char));	/* "+ 1" for the terminating zero */
		screen_text[i] = p;
	}

	scr_rec = (struct screen_record *) malloc(sizeof(struct screen_record));

	scr_rec->rows = rows;
	scr_rec->cols = columns;
	scr_rec->text = screen_text;

	return(scr_rec);
}


/* -------------------------------------------------------------
*		take a screen record and a pwixwin "rect", which contains
*	size information: make a new screen record of the new size specified
*	by the "rect", with as much of the data from the old rect as can be
*	fitted in, and any other space filled with spaces.
*/
struct screen_record *resize_screen_rec(old_scrnrec, rect, win)
struct screen_record *old_scrnrec;
struct rect rect;
int win;
{
	int ri, ci, roff;
	int or, oc, nr, nc;			/* old/new rows/columns */
	char *old_line, *new_line;
	char **old_text, **new_text;
	struct screen_record *new_scrnrec;

	or = old_scrnrec->rows;
	oc = old_scrnrec->cols;
	old_text = old_scrnrec->text;

	nr = (rect.r_height) / fontadv_y;
	nc = (rect.r_width) / fontadv_x;

	/* base window copies from the bottom, others from top */
	if ((win == 0)  && (or > nr))
	{
		roff = or - nr;
printf("resize: or=%d, nr=%d, roff=%d\n", or, nr, roff);
	}
	else
		roff = 0;

	new_scrnrec = make_screen_record(nr, nc);
	new_text = new_scrnrec->text;

	for (ri = 0; ri < nr ; ri++)
	{
		new_line = new_text[ri];
		if	(ri < or)
		{
			old_line = old_text[ri + roff];
			for (ci = 0; ci < nc; ci++)
				if	(ci < oc)
					new_line[ci] = old_line[ci];
				else
					new_line[ci] = ' ';
		}
		else
			for (ci = 0; ci < nc; ci++)
				new_line[ci]= ' ';
	}

	for (ri = 0; ri < nr ; ri++)	/* 	add terminating 0 at	*/
		new_text[ri][nc] = 0;		/*		end of each line	*/

	return(new_scrnrec);
}

clear_screen_record(screen)
struct screen_record *screen;
{
	int rows, cols, ri, ci;
	char **text, *p;

	rows = screen->rows;
	cols = screen->cols;
	text = screen->text;

	for (ri = 0; ri < rows; ri++)
	{
		p = text[ri];
		for (ci = 0; ci < cols; ci++)
		{
            *(p + ci) = ' ';
		}
		*(p + cols) = 0;
	}
}


free_screen_record(screen)
struct screen_record *screen;
{
	int rows;
	char **text;

	int i;
	char *p;

	rows = screen->rows;
	text = screen->text;

	for (i = 0; i < rows; i++)
	{
		p = text[i];
		free(p);
	}
	free(text);
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    14:  struct screen_record *make_screen_record(rows, columns)
::    48:  struct screen_record *resize_screen_rec(old_scrnrec, rect, win)
::   101:  clear_screen_record(screen)
::   123:  free_screen_record(screen)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwscrn.c,v $
 * Revision 1.1  89/08/23  13:21:09  pop
 * Initial revision
 * 
*/
