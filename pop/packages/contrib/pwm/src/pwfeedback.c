/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwfeedback.c
 * Purpose:		routines for the various forms of mouse tracking feedback
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwfeedback.c,v 1.2 89/08/23 16:41:34 pop Exp $
 */

#include "pwdec.h"

static struct pixrect *rubber_image, *rubber_saved;
static struct xypos rubber_imageloc;
static int (* rubber_redraw)();

#define TRKrubberline 1
#define TRKcrosshairs 2
#define TRKrubberbox  3

#define TRKbouncybox  4
#define TRKbouncyras  5

#define TRKtextselect 6

/*
|	rubber_moving	=	the current position of the moving point
|	rubber_fixed	=	the fixed point OR width of bouncy box/raster
|	rubber_imageloc =	top-left corner of where bouncy raster came from
|						(after setup: if non-neg, then we need to put it back)
|	rubber_image	=	the image we're bouncing
|	rubber_saved	=	if bouncing in SRC mode, portion of the window which
|						is currently obscured is saved here
|
|	num[0]	=	newx
|	num[1]	=	newy
|	num[2]	=	fixed.x		(image.width)
|	num[3]	=	fixed.y		(image.height)
|	num[4]	=	limit.x
|	num[5]	=	limit.y
|	num[6]	=	limit.width
|	num[7]	=	limit.height
|	num[8]	=	image.origin.x	(may be num[4] if no limit box)
|	num[9]	= 	image.origin.y	(may be num[5] if no limit box)
|
*/

/* -- utilities----------------------------------------------------- */

invert_box_frame(x1, y1, x2, y2)
int x1, y1, x2, y2;
{
	pw_vector(wt_pixwinp[current_in], x1, y1, x2, y1, PIX_NOT(PIX_DST), 0);
	pw_vector(wt_pixwinp[current_in], x2, y1, x2, y2, PIX_NOT(PIX_DST), 0);
	pw_vector(wt_pixwinp[current_in], x2, y2, x1, y2, PIX_NOT(PIX_DST), 0);
	pw_vector(wt_pixwinp[current_in], x1, y2, x1, y1, PIX_NOT(PIX_DST), 0);
}

invert_box_body(x1, y1, x2, y2)
int x1, y1, x2, y2;
{
	if ((x1 != x2) && (y1 != y2))
		pw_writebackground(wt_pixwinp[current_in],
								min(x1, x2), min(y1, y2),
								abs(x1 - x2), abs(y1 - y2),
								PIX_NOT(PIX_DST));
}

/* -- RUBber REDraw functions--------------------------------------- */

rubred_crosshairs(newx, newy)
int newx, newy;
{
	int i, xmargin, ymargin;

	if (ci_mmaction & TRK_modeflag)
	{
		xmargin = rubber_limit.xy1.x;
		ymargin = rubber_limit.xy1.y;
	}
	else
		xmargin = ymargin = 0;

	for (i = 0; i < 2; i++)		/* do it twice!!! */
	{
		if (rubber_moving.x != -1)
		{
			pw_vector(wt_pixwinp[current_in],
						xmargin,		rubber_moving.y,
						rubber_fixed.x,	rubber_moving.y,
						PIX_NOT(PIX_DST), 0);
			pw_vector(wt_pixwinp[current_in],
						rubber_moving.x, 	ymargin,
						rubber_moving.x,	rubber_fixed.y,
						PIX_NOT(PIX_DST), 0);
		}
    	rubber_moving.x = newx;
		rubber_moving.y = newy;
	}
}

rubred_sketchline(newx, newy)
int newx, newy;
{
	int i;

	if ((rubber_moving.x != -1) && (newx != -1))
		pw_vector(wt_pixwinp[current_in],
					rubber_moving.x, rubber_moving.y,
					newx, newy, graphic_op, graphic_value);

   	rubber_moving.x = newx;
	rubber_moving.y = newy;
}

rubred_rubberline(newx, newy)
int newx, newy;
{
	register int i;

	for (i = 2; i != 0; i--)	/*	do it twice (!) */
	{
		if (rubber_moving.x != -1)
			pw_vector(wt_pixwinp[current_in],
						rubber_fixed.x, rubber_fixed.y,
						rubber_moving.x, rubber_moving.y, PIX_NOT(PIX_DST), 0);

	   	rubber_moving.x = newx;
		rubber_moving.y = newy;
	}
}

rubred_rubberbox(newx, newy)
int newx, newy;
{
	int i;

    if (ci_mmaction & TRK_modeflag)
	{
		if ((newx == -1)
			|| (rubber_moving.x == -1)
			|| (IsPositive(rubber_moving.x - rubber_fixed.x)
								!= IsPositive(newx - rubber_fixed.x))
			|| (IsPositive(rubber_moving.y - rubber_fixed.y)
								!= IsPositive(newy - rubber_fixed.y))
			)
		{
			for (i = 0; i < 2; i++)
			{
				if (rubber_moving.x != -1)
					invert_box_body(rubber_moving.x, rubber_moving.y,
									rubber_fixed.x, rubber_fixed.y);

		    	rubber_moving.x = newx; rubber_moving.y = newy;
			}
		}
		else 	/*optimise...*/
		{
			if (IsPositive(newx - rubber_moving.x) == IsPositive(newy - rubber_moving.y))
			{
				invert_box_body(newx, rubber_fixed.y,
							rubber_moving.x, rubber_moving.y);
				invert_box_body(rubber_fixed.x, newy,
							newx, rubber_moving.y);
			}
			else
			{
				invert_box_body(rubber_moving.x, rubber_fixed.y,
							newx, newy);
				invert_box_body(rubber_fixed.x, rubber_moving.y,
							rubber_moving.x, newy);
			}

	    	rubber_moving.x = newx; rubber_moving.y = newy;
		}
	}
	else
	{
		for (i = 0; i < 2; i++)
		{
			if (rubber_moving.x != -1)
				invert_box_frame(rubber_fixed.x, rubber_fixed.y,
							   		rubber_moving.x, rubber_moving.y);

	    	rubber_moving.x = newx; rubber_moving.y = newy;
		}
	}
}

rubred_bouncybox(newx, newy)
int newx, newy;
{
	int i;

    if (ci_mmaction & TRK_modeflag)
	{
		int diffx;

		diffx = newx - rubber_moving.x;

		if ( (newx == -1)
			|| (rubber_moving.x == -1)
			|| (abs(diffx) >= rubber_fixed.x)
			|| (abs(newy - rubber_moving.y) >= rubber_fixed.y))
		{
			for (i = 0; i < 2; i++)
			{
				if (rubber_moving.x != -1)
					pw_writebackground(wt_pixwinp[current_in],
										rubber_moving.x, rubber_moving.y,
										rubber_fixed.x, rubber_fixed.y,
										PIX_NOT(PIX_DST));

		    	rubber_moving.x = newx;
				rubber_moving.y = newy;
			}
		}
		else	/* optimise */
		{
			if (newx < rubber_moving.x)
			{
				pw_writebackground(wt_pixwinp[current_in],
					newx, newy,
					abs(diffx), rubber_fixed.y,
					PIX_NOT(PIX_DST));

				pw_writebackground(wt_pixwinp[current_in],
					newx + rubber_fixed.x, rubber_moving.y,
					abs(diffx), rubber_fixed.y,
					PIX_NOT(PIX_DST));
			}
			else if (newx > rubber_moving.x)
			{
				pw_writebackground(wt_pixwinp[current_in],
					rubber_moving.x, rubber_moving.y,
					diffx, rubber_fixed.y,
					PIX_NOT(PIX_DST));

				pw_writebackground(wt_pixwinp[current_in],
					rubber_moving.x + rubber_fixed.x, newy,
					diffx, rubber_fixed.y,
					PIX_NOT(PIX_DST));
			}

			if (newy != rubber_moving.y)
			{
				pw_writebackground(wt_pixwinp[current_in],
					max(rubber_moving.x, newx),
					min(rubber_moving.y, newy),
					rubber_fixed.x - abs(diffx),
					abs(newy - rubber_moving.y),
					PIX_NOT(PIX_DST));

				pw_writebackground(wt_pixwinp[current_in],
					max(rubber_moving.x, newx),
					rubber_fixed.y + min(rubber_moving.y, newy),
					rubber_fixed.x - abs(diffx),
					abs(newy - rubber_moving.y),
					PIX_NOT(PIX_DST));
			}
	    	rubber_moving.x = newx;
			rubber_moving.y = newy;
		}
	}
	else
	{
		for (i = 0; i < 2; i++)
		{
			if (rubber_moving.x != -1)
				invert_box_frame(rubber_moving.x, rubber_moving.y,
									rubber_moving.x + rubber_fixed.x,
									rubber_moving.y + rubber_fixed.y);

	    	rubber_moving.x = newx;
			rubber_moving.y = newy;
		}
	}

}

rubred_bouncyras(newx, newy)
int newx, newy;
{
	int i;
#ifdef DeBug
	printf("RBR, mode%d: width(%d,%d); moving(%d,%d); newpos(%d,%d)\n",
			((ci_mmaction & TRK_modeflag) == 0),
			rubber_width.x, rubber_width.y,
			rubber_moving.x, rubber_moving.y,
			newx, newy);
#endif

	if ((ci_mmaction & TRK_modeflag) == 0)
	{	/* XOR mode */
		for (i = 2; i != 0; i--)
		{
			if (rubber_moving.x != -1)
			   	pw_rop(wt_pixwinp[current_in],
					rubber_moving.x, rubber_moving.y,
					rubber_width.x, rubber_width.y,
					PIX_SRC ^  PIX_DST,
					rubber_image, 0, 0);

	    	rubber_moving.x = newx;
			rubber_moving.y = newy;
		}
	}
	else
	{	/* SRC mode  */
		if (rubber_moving.x != -1)
		{	/* restore saved copy of old pos */
		   	pw_rop(wt_pixwinp[current_in],
					rubber_moving.x, rubber_moving.y,
					rubber_width.x, rubber_width.y,
					PIX_SRC, rubber_saved, 0, 0);
		}

		if (newx != -1)
		{	/* save what's under new pos */
			pr_rop(rubber_saved, 0, 0, rubber_width.x, rubber_width.y,
						PIX_SRC, wt_pixwinp[current_in]->pw_prretained,
	 					newx, newy);

			/* blat moving image on top */
		   	pw_rop(wt_pixwinp[current_in],
					newx, newy, rubber_width.x, rubber_width.y,
					PIX_SRC, rubber_image, 0, 0);
		}

    	rubber_moving.x = newx; rubber_moving.y = newy;
	}
}

rubred_textselect(newx, newy)
int newx, newy;
{
	struct xypos temp;

   	temp.x = newx;
	temp.y = newy;

	adjust_text_highlight(current_in,
							&rubber_fixed, &rubber_moving, &temp,
							ci_mmaction & TRK_modeflag);

   	rubber_moving.x = newx;
	rubber_moving.y = newy;
}

/* -- setup, closedown, and inbetween------------------------------- */

/*--------------------------------------------------------------------
*	responds to command from poplog; sets flag so that subsequent
*	mouse movements will be reported, and sets up various values
*/
rubber_setup()
{
	register int i;
	register char surf;
	int newx, newy;

	rubber_moving.x = rubber_moving.y = -1;

	if (ci_mousedown == 0) return(ci_mmaction = 0);	/* and return */

	if (((ci_mmaction = com_charargs[0] - 32) & TRK_actionmask) == 0)
		return(0);	/* we're just reporting, not doing any feedback */

	if ((ci_mmaction & TRK_actionmask) == TRKbouncyras)
	{	/* last two numeric args are x and y of source image, second pair are
		 * width and height of source image: get them all here to avoid
		 * scaling from character coords; decrement nargs past the extra two
		 * args so we don't screw up over limit-box args
		*/
		rubber_imageloc.y = com_numargs[--com_nargs];
        rubber_imageloc.x = com_numargs[--com_nargs];

        rubber_width.x = com_numargs[2];
		rubber_width.y = com_numargs[3];
#ifdef DeBug
	printf("RBS: b.r. from (%d,%d) width=%d, height=%d\n",
            		rubber_imageloc.x, rubber_imageloc.y,
                    rubber_width.x, rubber_width.y);
#endif
#ifdef DeBug
	printf("RBS: image from (%d,%d), size %dx%d\n", rubber_imageloc.x,
			        rubber_imageloc.y, rubber_width.x, rubber_width.y);
#endif
	}

	if ((wt_active[current_in] != WT_GRAPHW)
		&& ((ci_mmaction & TRK_actionmask) != TRKtextselect))
	{	/* scale args to pixel values */
		for (i = 0; i < com_nargs; i++)
		{
			com_numargs[i] = com_numargs[i] * fontadv_x;
			i++;
			com_numargs[i] = com_numargs[i] * fontadv_y;
		}
	}

	newx = com_numargs[0];
	newy = com_numargs[1];
	rubber_fixed.x = com_numargs[2];	/* defaults -                  */
	rubber_fixed.y = com_numargs[3];    /*  - may be over-ridden below */

	/* set up limit box defaults: top, left, bottom, right of window */
	rubber_limit.xy1.x = rubber_limit.xy1.y = 0;
	rubber_limit.xy2.x = wt_swrect[current_in].r_width;
	rubber_limit.xy2.y = wt_swrect[current_in].r_height;

	/* then over-ride limit-box values if command specified them */
	if (com_nargs == 8)
	{
		rubber_limit.xy1.x = com_numargs[4];
		rubber_limit.xy1.y = com_numargs[5];
		if ((i = com_numargs[6]) != 0)
		{
			i = rubber_limit.xy1.x + i;
			if (i < rubber_limit.xy2.x) rubber_limit.xy2.x = i;
		}

		if ((i = com_numargs[7]) != 0)
		{
			i = rubber_limit.xy1.y + i;
			if (i < rubber_limit.xy2.y) rubber_limit.xy2.y = i;
		}
	}
	else if (com_nargs != 4)
	{
		ci_mmaction = 0;
#ifdef DeBug
		printf("RBS: naff number (%d) of args for tracking\n", com_nargs);
#endif
	}
#ifdef DeBug
	printf("RBS: limit box (%d,%d) to (%d,%d)\n",
				rubber_limit.xy1.x, rubber_limit.xy1.y,
				rubber_limit.xy2.x, rubber_limit.xy2.y);
#endif

	if (((ci_mmaction & TRK_actionmask) == TRKbouncybox)
		|| ((ci_mmaction & TRK_actionmask) == TRKbouncyras))
	{	/* then "snap" box to mouse */
		int extn, extq, delta;

		extq = (extn = rubber_fixed.x) >> 2;		/* div by 4 */

		delta = inevent.ie_locx - newx;
		if (delta < extq)
			rubber_offset.x = 0;		/* first quarter or less */
		else if (delta < (extn - extq))
			rubber_offset.x = delta;	/* middle half		*/
		else rubber_offset.x = extn;	/* last quarter or more */

		extq = (extn = rubber_fixed.y) >> 2;		/* div by 4 */
		delta = inevent.ie_locy - newy;
		if (delta < extq)
			rubber_offset.y = 0;		/* first quarter or less */
		else if (delta < (extn - extq))
			rubber_offset.y = delta;	/* middle half		*/
		else rubber_offset.y = extn;	/* last quarter or more */
	}
	else
	{
		rubber_offset.x = rubber_offset.y = 0;
	}

	/* assign a procedure to do the display work */
	switch (ci_mmaction & TRK_actionmask)
	{
	case TRKcrosshairs:
		rubber_redraw = rubred_crosshairs;
		hide_mouse_cursor(current_in);
		if (ci_mmaction & TRK_modeflag)
		{
			rubber_fixed.x = rubber_limit.xy2.x;
			rubber_fixed.y = rubber_limit.xy2.y;
		}
		else
		{
			rubber_fixed.x = wt_swrect[current_in].r_width;
			rubber_fixed.y = wt_swrect[current_in].r_height;
		}
		break;
	case TRKrubberline:
	    if (ci_mmaction & TRK_modeflag)		/* actually sketch line */
			rubber_redraw = rubred_sketchline;
		else
			rubber_redraw = rubred_rubberline;
		break;
	case TRKrubberbox:
		rubber_redraw = rubred_rubberbox;
		break;
	case TRKbouncybox:
		rubber_redraw = rubred_bouncybox;
		break;
	case TRKbouncyras:
		rubber_redraw = rubred_bouncyras;
		break;
	case TRKtextselect:
		if (wt_active[current_in] < WT_GRAPHW)
			rubber_redraw = rubred_textselect;
		else
		{
			ci_mmaction = 0;
			misprint(current_in,
			"PWM: ignoring request for text feedback on non-text window #%d\n");
		}
		break;
	default:
		break;
	}

#ifdef DeBug
	printf("Rub#%d: fixed=(%d,%d); new=(%d,%d); off=(%d,%d)\n",
			ci_mmaction, rubber_fixed.x, rubber_fixed.y,
			newx, newy, rubber_offset.x, rubber_offset.y);
#endif

	if ((ci_mmaction & TRK_actionmask) == TRKbouncyras)
	{   /* special set-up required */
		surf = com_charargs[1] - 32;

#ifdef DeBug
	printf("RBS: b.r. from surf %d (ci=%d): (%d,%d) size=%dx%d\n",
					surf, current_in,
            		rubber_imageloc.x, rubber_imageloc.y,
                    rubber_width.x, rubber_width.y);
#endif
		if (surf == current_in)
		{
			/* create a little pixrect to keep the image in */
			rubber_image = mem_create(rubber_width.x, rubber_width.y,
						wt_pixwinp[current_in]->pw_prretained->pr_depth);

			/* and copy the image in */
			pr_rop(rubber_image, 0, 0, rubber_width.x, rubber_width.y,
						PIX_SRC,
						wt_pixwinp[current_in]->pw_prretained,
                        rubber_imageloc.x, rubber_imageloc.y);
		}
		else
		{ 	/* use a "region pixrect" from the source */
			rubber_image = pr_region(get_gfx_surface_pr(surf),
										rubber_imageloc.x, rubber_imageloc.y,
										rubber_width.x, rubber_width.y);
			/* and note that we don't have to put it back */
			rubber_imageloc.x = rubber_imageloc.y = -1;
		}

		if ((ci_mmaction & TRK_modeflag) != 0)	/* SRC mode */
		{	/* create pixrect to save what's under bouncing image */
			rubber_saved = mem_create(rubber_fixed.x, rubber_fixed.y,
					wt_pixwinp[current_in]->pw_prretained->pr_depth);
#ifdef DeBug
	printf("RBS: created rubber_saved, $%x\n", rubber_saved);
#endif
		}
	}

	if (ci_mmaction) 	/* may have been zeroed if silly request */
	{
		/* clip newx and newy to fit in limit box */
		if (rubber_limit.xy2.x != 0)
			if (newx < rubber_limit.xy1.x) newx = rubber_limit.xy1.x;
			else if (newx > rubber_limit.xy2.x) newx = rubber_limit.xy2.x;
		if (rubber_limit.xy2.y != 0)
			if (newy < rubber_limit.xy1.y) newy = rubber_limit.xy1.y;
			else if (newy > rubber_limit.xy2.y) newy = rubber_limit.xy2.y;

		/* special case: if bouncing raster in SRC mode, and the initial
	     * position of bouncy raster is where it came from, clear it before
		 * doing first redraw so that when it's moved away it'll leave a hole
		 * behind.
		 */
        if ((ci_mmaction == (TRKbouncyras | TRK_modeflag))
		&& (surf == current_in)
		&& (newx == rubber_imageloc.x) && (newy == rubber_imageloc.y))
		{
#ifdef DeBug
	printf("RBS: doing special src/ras CLR op\n");
#endif
			pw_writebackground(wt_pixwinp[current_in], newx, newy,
								rubber_width.x, rubber_width.y, PIX_CLR);
		}
		else
		{	/* note we don't have to put it back */
			rubber_imageloc.x = rubber_imageloc.y = -1;
#ifdef DeBug
	printf("RBS: not doing src/ras CLR op: iloc=(%d, %d)\n",
							rubber_imageloc.x, rubber_imageloc.y);
#endif
		}

		/* do the first action */
		rubber_redraw(newx, newy);
	}
}

rubber_action()
{
	int newx, newy;

	/* add the offsets from the mouse */
	newx = inevent.ie_locx - rubber_offset.x;
	newy = inevent.ie_locy - rubber_offset.y;

	if ((ci_mmaction & TRK_actionmask) == TRKtextselect)
	{
		newx = pixcoord_txt_x(newx);
		newy = pixcoord_txt_y(newy) - 1;
	}

	/* clip it */
	if (rubber_limit.xy2.x != 0)
		if (newx < rubber_limit.xy1.x) newx = rubber_limit.xy1.x;
		else if (newx > rubber_limit.xy2.x) newx = rubber_limit.xy2.x;
	if (rubber_limit.xy2.y != 0)
		if (newy < rubber_limit.xy1.y) newy = rubber_limit.xy1.y;
		else if (newy > rubber_limit.xy2.y) newy = rubber_limit.xy2.y;

	/* don't piss around */
	if (rubber_moving.x == newx && rubber_moving.y == newy) return(0);

	rubber_redraw(newx, newy);
}

rubber_finish()
{
#ifdef DeBug
	printf("RBF, cleaning up...\n");
#endif
	rubber_redraw(-1, -1);

	if ((ci_mmaction & TRK_actionmask) == TRKbouncyras)
	{
		if ((ci_mmaction & TRK_modeflag) != 0)	/* SRC mode */
		{
#ifdef DeBug
	printf("RBF, destroying rubber-saved ($%x)\n", rubber_saved);
#endif
			pr_destroy(rubber_saved);
			if (rubber_imageloc.x > -1)		/* put the image back now */
				pw_rop(wt_pixwinp[current_in],
						rubber_imageloc.x, rubber_imageloc.y,
						rubber_width.x, rubber_width.y,
						PIX_SRC, rubber_image, 0, 0);
		}

#ifdef DeBug
	printf("RBF, destroying rubber-image...\n");
#endif
		pr_destroy(rubber_image);
	}
	else if ((ci_mmaction & TRK_actionmask) == TRKcrosshairs)
		win_setcursor(wt_swfd[current_in],
						win_cursors[(wt_cursor[current_in])]);

	rubber_offset.x = rubber_offset.y = 0;
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ---44---utilities------
::    46:  invert_box_frame(x1, y1, x2, y2)
::    55:  invert_box_body(x1, y1, x2, y2)
:: ---65---RUBber REDraw functions------
::    67:  rubred_crosshairs(newx, newy)
::    98:  rubred_sketchline(newx, newy)
::   112:  rubred_rubberline(newx, newy)
::   129:  rubred_rubberbox(newx, newy)
::   186:  rubred_bouncybox(newx, newy)
::   277:  rubred_bouncyras(newx, newy)
::   330:  rubred_textselect(newx, newy)
:: --346---setup, closedown, and inbetween------
::   352:  rubber_setup()
::   582:  rubber_action()
::   610:  rubber_finish()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwfeedback.c,v $
 * Revision 1.2  89/08/23  16:41:34  pop
 * *** empty log message ***
 * 
 * Revision 1.1  89/08/23  13:20:14  pop
 * Initial revision
 * 
*/
