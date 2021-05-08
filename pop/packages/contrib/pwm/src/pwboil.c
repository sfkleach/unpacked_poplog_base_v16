/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		C.sun/pwm/pwboil.c
 * Purpose:		various pwm utilities
 * Author:		Ben Rubinstein, Feb 20 1987 (see revisions)
 * $Header: /popv13.5/pop/pwm/RCS/pwboil.c,v 1.2 89/08/23 16:04:31 pop Exp $
 */

/*
|	"boilerplate" code.  basically just stuff that's more boring than
|	what's elsewhere.
*/
#include "pwdec.h"

/*--------------------------------------------------------------------
* takes a number and a message: prints the message on stderr and quits.
* 		unless the number is -1, there should be a '%..d' bit in the
*		message, and this will be replaced with the number when the
*		message is printed out.
*/
mishap(i, mess)
int i;
char *mess;
{
	if	(i == -1)
		fputs(mess, stderr);
	else
	{
		sprintf(buf, mess, i);
		fputs(buf, stderr);
	}
	if (client_pid != 0) kill(client_pid, SIGKILL);
	exit(1);
}

/*--------------------------------------------------------------------
* takes a number and a message: prints the message on stderr.
* 		unless the number is -1, there should be a '%..d' bit in the
*		message, and this will be replaced with the number when the
*		message is printed out.
*	Unlike "mishap", above, this does not exit.
*/
misprint(i, mess)
int i;
char *mess;
{
	if	(i == -1)
		fputs(mess, stderr);
	else
		fprintf(stderr, mess, i);
}

/*--------------------------------------------------------------------
*  return index to the next free position in window table, or WT_NOWIN:
*		"engages" the returned position, with 2; when a window has
*		actually been installed here this will go to 1.
*/
next_index()
{
	int i;

	for	(i = WT_FIRSTWIN; i <= WT_LASTWIN; i++)
		if (wt_active[i] == WT_UNUSED)
		{
			wt_active[i] = WT_BOOKED;
			return(i);
		}
	return(WT_NOWIN);
}

/*--------------------------------------------------------------------
*	under release 3, the selected tool is marked with a black border.
*	Unfortunately one can't simply use a write background, else would
*	paint over name stripe and outer border - even if one did a w.b.
*	on the inner rectangle, would screw the inner border when CLR'ing.
*	this func is used by the input handler when it gets a WINENTER or
*	WINEXIT code, and by the refresh routines if they have a record of
*	this window being selected.
*/
mark_tool_border(index, code)
register char index;
register short code;
{
	toolp = wt_toolwp[index];
	if (wmgr_iswindowopen(toolp->tl_windowfd))
	{
		register int blop, xlim, ylim;

		blop = ((code == LOC_WINEXIT) ? PIX_CLR : PIX_SET);


		ylim = toolp->tl_rectcache.r_height - 3;
		xlim = toolp->tl_rectcache.r_width - 3;

		pw_vector(toolp->tl_pixwin, 2, fontadv_y + 2, 2, ylim, blop, 1);
		pw_vector(toolp->tl_pixwin, 2, ylim, xlim, ylim, blop, 1);
		pw_vector(toolp->tl_pixwin, xlim, ylim, xlim, fontadv_y + 2, blop, 1);
	}
}

/*--------------------------------------------------------------------
*	probably very inefficient, but it's only done
*	once and not worth the hassle
*/
parse_command_line(argc, argv)
int argc;
char *argv[];
{
	int i;
	char *icl, *ict;

	/* suntool standard ones */
	toolargs = NULL;
	tool_parse_all(&argc, argv, &toolargs, "pwmtool");

	/* check if position of first icon specified */
	if ((tool_find_attribute(toolargs, WIN_ICON_LEFT, &icl) == 1)
		&& (tool_find_attribute(toolargs, WIN_ICON_TOP, &ict) == 1))
	{
		iconstartpos.x = (int)icl;
		iconstartpos.y = (int)ict;
	}
	else
		iconstartpos.x = iconstartpos.y = 4;

	tool_free_attribute(WIN_ICON_LEFT, icl);
	tool_free_attribute(WIN_ICON_TOP, ict);

	/* check if position of first window specified */
	if ((tool_find_attribute(toolargs, WIN_LEFT, &icl) == 1)
		&& (tool_find_attribute(toolargs, WIN_TOP, &ict) == 1))
	{
		winstartpos.x = (int)icl;
		winstartpos.y = (int)ict;
	}
	else
	{
		winstartpos.x = WINSTARTX;
		winstartpos.y = WINSTARTY;
	}

	tool_free_attribute(WIN_LEFT, icl);
	tool_free_attribute(WIN_TOP, ict);

	/* our special one - direction to arrange icons */
	icondirection.x = icondirection.y = 0;
	for (i = 0; i < argc - 1; i++)
	{
		if (strncmp(argv[i], "-WD", 3) == 0)
		{
			switch (argv[i + 1][0])
			{
			case 'N':
			case 'n':
				icondirection.y = -68; break;
			case 'S':
			case 's':
				icondirection.y = 68;  break;
			case 'E':
			case 'e':
				icondirection.x = 68;  break;
			case 'W':
			case 'w':
				icondirection.x = -68; break;
			default:
				misprint(-1, "pwmtool: bad argument to -WD (NSEW)\n");
				break;
			}

			for (; i < argc - 2; i++) argv[i] = argv[i + 2];
			argc = argc - 2;
			break;
		}
	}

	/* default icon direction: east */
	if ((icondirection.x == 0) && (icondirection.y == 0))
		icondirection.x = 68;

	/* by default, run pop11 in base window */
	if	(argc < 2)
		argv[0] = "pop11";
	else
	{
		for (i = 0; i < argc; i++) argv[i] = argv[i + 1];
		argc--;
	}

	/* ensure that arg after last is null */
	argv[argc] = (char) NULL;

	/* return nargs, for use in title stripe */
	return(argc);
}

/*--------------------------------------------------------------------
*	check the suggested icon position, and wrap it round if necessary
*/
icon_x_position(x)
int x;
{
	while (x < 0) x = x + (SCREENWIDTH-68);
	while (x > ICONLASTX) x = x - (SCREENWIDTH-68);
	return(x);
}

/*--------------------------------------------------------------------
*	check the suggested icon position, and wrap it round if necessary
*/
icon_y_position(y)
int y;
{
	while (y < 0) y = y + (SCREENHEIGHT-68);
	while (y > ICONLASTY) y = y - (SCREENHEIGHT-68);
	return(y);
}

/*--------------------------------------------------------------------
* takes text coordinate x, returns pixel coordinate x.
*  text origin is 0, 0;
*/
txtcoord_pix_x(tx)
int tx;
{
	return(tx * fontadv_x);
}

/*--------------------------------------------------------------------
* takes text coordinate y, returns pixel coordinate y.
*  text origin is 0, 0;
*/
txtcoord_pix_y(ty)
int ty;
{
	return((ty * fontadv_y) - font_home_y);
}


/*--------------------------------------------------------------------
* takes pixel coordinate x, returns text coordinate x.
*  text origin is 0, 0;
*/
pixcoord_txt_x(px)
int px;
{
	return((px == 0) ? 0 : (px / fontadv_x));
}

/*--------------------------------------------------------------------
* takes pixel coordinate y, returns text coordinate y.
*  text origin is 0, 0;
*/
pixcoord_txt_y(py)
int py;
{
	return((py == 0) ? 0 : ((py + fontadv_y) / fontadv_y));
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    19:  mishap(i, mess)
::    41:  misprint(i, mess)
::    56:  next_index()
::    78:  mark_tool_border(index, code)
::   102:  parse_command_line(argc, argv)
::   196:  icon_x_position(x)
::   207:  icon_y_position(y)
::   219:  txtcoord_pix_x(tx)
::   229:  txtcoord_pix_y(ty)
::   240:  pixcoord_txt_x(px)
::   250:  pixcoord_txt_y(py)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Jan 17 1989
	--- placed a (char) cast in mark_tool_border to fix apparent change to
		compiler
$Log:	pwboil.c,v $
 * Revision 1.2  89/08/23  16:04:31  pop
 * changed code in mark_tool_border to be a short
 * modified icon_[xy]_position to take into account the size of the icon
 * 
 */
