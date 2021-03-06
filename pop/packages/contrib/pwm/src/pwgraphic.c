/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwgraphic.c
 * Purpose:		routines for the "simple" graphics commands
 * Author:		Ben Rubinstein, Feb 20 1987
 * Related Files: other graphics code in PWCOLOUR.C PWGRASTER.C PWGFXTEXT.C
 * $Header: /popv13.5/pop/pwm/RCS/pwgraphic.c,v 1.2 89/08/23 16:56:46 pop Exp $
 */

#include "pwdec.h"
#include "pwrepseq.h"

/*--------------------------------------------------------------------
*	this is keyed to the command from poplog, but just checks the args:
*	the real work is done by select_graphic_window, below
*/
grph_setcg_surface()
{
	int n;

	if ((n = check_surface_id(0)) != WT_NOWIN)
			if	(n != current_graf) select_graphic_window(n);
}

/*--------------------------------------------------------------------
*	set the Raster-Op for following graphics commands: just use the
*	argument to index into an array of values.
*/
grph_setcg_rop()
{
	graphic_op = ropconvert[(com_charargs[0] & 15)];
}

/*--------------------------------------------------------------------
*	set the paint number for following graphics commands
*/
grph_setcg_paint()
{
	graphic_value = com_numargs[0];
#ifdef DeBug
	printf("gsp: graphic value now %d\n", graphic_value);
#endif
}

/*--------------------------------------------------------------------
*	Draw one or more lines.  If there are less than four args then it does
*	nothing; else the first two are coords of start of the first line, and
*	each subsequent are the coords of the end of one line and the start of
*	the next (if any).  If there are an odd number of args (but more than 4)
*	then the y coord of the last line's endpoint cannot be guaranteed: it is
*	possible (? - maybe) that it could even crash.  Tough shit.
*/
grph_polyline()
{
	int n, x1, y1, x2, y2;

	n = 0;
	x1 = com_numargs[n++];
	y1 = com_numargs[n++];

    if(cg_winisframe){
        while (n < com_nargs)
        {
            x2 = com_numargs[n++];
            y2 = com_numargs[n++];
            pr_vector(cg_pixrectp, x1, y1, x2, y2, graphic_op, graphic_value);
            x1 = x2;
            y1 = y2;
        }
    } else {
        while (n < com_nargs)
        {
            x2 = com_numargs[n++];
            y2 = com_numargs[n++];
            pw_vector(cg_pixwinp, x1, y1, x2, y2, graphic_op, graphic_value);
            x1 = x2;
            y1 = y2;
        }
    }
}

/*--------------------------------------------------------------------
*   Draw a filled polygon.
*   Just fills a boundry defined in com_numargs
*   This may need to be done by drawing the outlin and the flooding on
*   machine that do not support arbitrary fill operations.
*   See comments on number of arguments to grph_polyline above.
*/
int npts[1];
#define NUM_POINTS COMNUMNARGS/2

struct pr_pos vlist[NUM_POINTS];

grph_polyfill()
{
    struct pr_pos   *v, *vend;
    int             *p, *pend;

    /* if (check_real_window() != 0) return(0); */

    v = vlist;
    vend = vlist + NUM_POINTS;
    p = com_numargs;
    pend = p + com_nargs;
    while( (p<pend) && (v<vend) ){
            v->x = *p++;
            v->y = *p++;
            v++;
    }
    npts[0] = com_nargs/2;
    if (cg_winisframe){
        pr_polygon_2(cg_pixrectp, 0, 0, 1, npts, vlist,
            graphic_op | PIX_COLOR(graphic_value), NULL, 0, 0);
    } else {
    pw_polygon_2(cg_pixwinp, 0, 0, 1, npts, vlist,
            graphic_op | PIX_COLOR(graphic_value), NULL, 0, 0);
    }
}

/*--------------------------------------------------------------------
*	"wipe over" a rectangle on screen with the current graphics op.
*	the args are top, left, width, height to define the rectangle:
*	if width and height are both zero, it will extend from the <top>,
*	<left> given in the args to the bottom right of the window.
*/
grph_wipearea()
{
	register int w, h;

	if ((w = com_numargs[2]) == 0) w = cg_pixrectp->pr_width;
	if ((h = com_numargs[3]) == 0) h = cg_pixrectp->pr_height;


	if (cg_winisframe)
	{
		pr_rop(cg_pixrectp, com_numargs[0], com_numargs[1], w, h,
							graphic_op | PIX_COLOR(graphic_value),
							(struct pixrect *)NULL, 0, 0);
	}
	else if (graphic_op == PIX_SRC)
	{
		pw_rop(cg_pixwinp, com_numargs[0], com_numargs[1], w, h,
							graphic_op | PIX_COLOR(graphic_value),
							(struct pixrect *)NULL, 0, 0);
	}
	else
	{
		pw_writebackground(cg_pixwinp,
							com_numargs[0], com_numargs[1], w, h,
							graphic_op);
	}
}


/*--------------------------------------------------------------------
*	return the value of the pixel at given coordinates: reads it from
*	the backup pixrect instead of the main one, to avoid naff results on
*	obscured areas.
*/
grph_pixel_test()
{
#ifdef DeBug
	register int val;

	val = pr_get(cg_pixrectp, com_numargs[0], com_numargs[1]);
	printf("value at %d, %d is %d\n", com_numargs[0], com_numargs[1], val);
	report_integer(val);
#else
	report_integer(pr_get(cg_pixrectp, com_numargs[0], com_numargs[1]));
#endif
}

grph_pixel_set()
{
	if (cg_winisframe)
	{
#ifdef DeBug
	printf("Putting P pixel %d at (%d, %d)\n",
					com_numargs[2], com_numargs[0], com_numargs[1]);
#endif
		pr_put(cg_pixrectp, com_numargs[0], com_numargs[1], com_numargs[2]);
	}
	else
	{
#ifdef DeBug
	printf("Putting W pixel %d at (%d, %d)\n",
					com_numargs[2], com_numargs[0], com_numargs[1]);
#endif
		pw_put(cg_pixwinp, com_numargs[0], com_numargs[1], com_numargs[2]);
	}
}

/* -- utilities----------------------------------------------------- */

select_graphic_window(n)
int n;
{
	current_graf = n;

	if (wt_active[n] == WT_FRAMEW)
	{
		cg_winisframe = 1;
		cg_pixwinp = (struct pixwin *)NULL;
		cg_pixrectp = gfx_frames[current_graf - FT_FIRSTFRAME];
	}
	else
	{
		cg_winisframe = 0;
		cg_pixwinp = wt_pixwinp[current_graf];
		cg_pixrectp = cg_pixwinp->pw_prretained;
	}
}

check_real_window()
{
	if (cg_winisframe)
		misprint(current_graf, "PWM: can't do graphic operation on %d, it's a page\n");

	return(cg_winisframe);
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ----1---Copyright University of Sussex 1987.  All rights reserved. ------
::    17:  grph_setcg_surface()
::    29:  grph_setcg_rop()
::    37:  grph_setcg_paint()
::    53:  grph_polyline()
::    88:  grph_wipearea()
::   121:  grph_pixel_test()
::   134:  grph_pixel_set()
:: --154---utilities------
::   156:  select_graphic_window(n)
::   175:  check_real_window()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwgraphic.c,v $
 * Revision 1.2  89/08/23  16:56:46  pop
 * removed CSUN_VUP_BUG as this was fixed in SUNOS3.2
 * Allowed all operation to be performed on frames
 * add grph_fillpoly
 * added PIX_COLOR(graphic_value) top op used to wipe frame
 * 
 * Revision 1.1  89/08/23  13:20:23  pop
 * Initial revision
 * 
*/
