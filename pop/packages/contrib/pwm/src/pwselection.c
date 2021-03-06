/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwselection.c
 * Purpose:		text selection mechanism
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwselection.c,v 1.1 89/08/23 13:21:11 pop Exp $
 */

#include "pwdec.h"
#include <suntool/selection.h>


static char **sel_textmap, sel_window;
int sel_widthc;


/* sel_write, sel_read, and sel_clear are required by the suntools software
*	to exist.  The precise functionality of sel_clear seems to be unclear at
*	time of writing (with version 2.0 software and documentation).
*/


sel_write(sel, file)
struct selection *sel;
FILE *file;
{
	int x, y, xlim;

	if (((x = selectstart.x) != -1)		/* else no selection */
		&& (sel->sel_type == SELTYPE_CHAR))	/* else not our type */
	{
		for (y = selectstart.y; y < selectend.y; y++)
		{
			xlim = findendofline(sel_textmap[y], sel_widthc, MRK_LINEMODE);
			for (; x < xlim ; x++) putc(sel_textmap[y][x], file);

			if (sel_textmap[y][xlim] > 32) putc(sel_textmap[y][xlim], file);
			putc(10, file);

			x = 0;
		}

		xlim = min(selectend.x,
					findendofline(sel_textmap[y], sel_widthc, MRK_LINEMODE));

		for (; x < xlim ; x++) putc(sel_textmap[y][x], file);

		if (xlim == findendofline(sel_textmap[y], sel_widthc, MRK_LINEMODE))
			putc(10, file);
		else
			putc(sel_textmap[y][xlim], file);

		selectstart.x = selectstart.y = -1;
	}
}

sel_clear(sel, winfd)
struct selection *sel;
int winfd;
{
	if (selectstart.x != -1)
	{
		struct xypos temp;

		temp.x = temp.y = -1;
		adjust_text_highlight(sel_window, &selectstart,
									&temp, &selectend, MRK_LINEMODE);            
	}

	selectstart.x = selectstart.y = -1;
}

sel_read(sel, file)
struct selection *sel;
FILE *file;
{
	char c;

	if (sel->sel_type == SELTYPE_CHAR) /* else not our type */
	{
		while ((c = getc(file)) != EOF)
			if (base_cooked) bwin_ascii_input(c); else send_to_poplog(c);
	}
}

sel_report(sel, file)
struct selection *sel;
FILE *file;
{
	char c;

	if (sel->sel_type == SELTYPE_CHAR) /* else not our type */
		while ((c = getc(file)) != EOF) send_to_poplog(c);
}

/*--------------------------------------------------------------------
*	return the number of characters that would be written in the current
*	selection
*/
sel_length()
{
int x, y, xlim, length;

	length = 1;
	x = selectstart.x;

	for (y = selectstart.y; y < selectend.y; y++)
	{
		length = length - x + findendofline(sel_textmap[y],
												sel_widthc, MRK_LINEMODE);
		x = 0;
	}

	return(length - x + min(selectend.x,
							findendofline(sel_textmap[y],
											sel_widthc, MRK_LINEMODE)));
}

/*--------------------------------------------------------------------
*	this is called when "stuff" selected on base window menu.
*	pretend selection typed into base window.
*/
stuff_selection()
{
	selection_get(sel_read, wt_swfd[0]);
}

/*--------------------------------------------------------------------
*	this is called in response to an escape sequence from poplog: whack
*	out the current selection (thus allowing it to be read from a remote
*	machine).
*/
advise_text_selection()
{
	selection_get(sel_report, wt_swfd[0]);
}

start_selection()
{
	int x, y;

	struct xypos temp;

	sel_textmap = bw_text;
	sel_widthc = bw_widthc;
	sel_window = 0;

	if (selectstart.x != -1)
	{
		temp.x = temp.y = -1;
		adjust_text_highlight(sel_window, &selectstart, &temp, &selectend, MRK_LINEMODE);
	}

	selectstart.x = temp.x = inevent.ie_locx / fontadv_x;;
	selectstart.y = temp.y = inevent.ie_locy / fontadv_y;
	selectend.x = selectend.y = -1;

	adjust_text_highlight(sel_window, &selectstart, &selectend, &temp, MRK_LINEMODE);

	selectstart.x = selectend.x = temp.x;
	selectstart.y = selectend.y = temp.y;
}

continue_selection()
{
	int newx, newy, ydiff;
	struct xypos temp;

	if (selectstart.x != -1)
	{
		temp.x = inevent.ie_locx / fontadv_x;
		temp.y = inevent.ie_locy / fontadv_y;

		adjust_text_highlight(sel_window, &selectstart,
										&selectend, &temp, MRK_LINEMODE);

		selectend.x = temp.x;
		selectend.y = temp.y;
	}
}

/*--------------------------------------------------------------------
*	should only be called if there is a selection
*/
end_selection()
{
	struct selection sel;

	struct xypos temp;

	temp.x = temp.y = -1;
	adjust_text_highlight(sel_window, &selectstart,
										&temp, &selectend, MRK_LINEMODE);

	sel.sel_type = SELTYPE_CHAR;
	sel.sel_items = sel_length();
	sel.sel_itembytes = 1;
	sel.sel_pubflags = 1;		/* asshole sun don't explain this, but this *
								 *	 is the value shelltool gives it.		*/
	sel.sel_privdata = (caddr_t)0;

	selection_set(&sel, sel_write, sel_clear, wt_swfd[0]);

	selectstart.x = selectstart.y = -1;
}


/*--------------------------------------------------------------------
*	this is very similar to the above; it responds to a command from poplog.
*	note that cancels any selection that was in the process of being made.
*/
set_text_selection()
{
	struct selection sel;
	struct xypos temp;


	if (selectstart.x != -1) end_selection();

	selectstart.y = com_numargs[0];
	selectstart.x = com_numargs[1];
	selectend.y = com_numargs[2];
	selectend.x = com_numargs[3];

	if (((sel_window = check_window_id(0)) != WT_NOWIN)
	&& (wt_active[sel_window] < WT_GRAPHW)
	&& (((selectstart.y < selectend.y) ||
		((selectstart.y == selectend.y) && (selectstart.x <= selectend.x)))))
	{
#ifdef DeBug
	printf("sts: win#%d, (%d, %d) - (%d, %d)\n", sel_window,
					selectstart.y, selectstart.x,
					selectend.y, selectend.x);
#endif
		sel_textmap = (wt_scrndata[sel_window])->text;
		sel_widthc = (wt_scrndata[sel_window])->cols;

		sel.sel_type = SELTYPE_CHAR;
		sel.sel_items = sel_length();
		sel.sel_itembytes = 1;
		sel.sel_pubflags = 1;	/* asshole sun don't explain this, but this *
								 *	 is the value shelltool gives it.		*/
		sel.sel_privdata = (caddr_t)0;

		selection_set(&sel, sel_write, sel_clear, wt_swfd[0]);
	}
	else
		misprint(-1, "PWM: bad args for setting text selection\n");

	selectstart.x = selectstart.y = -1;
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    16:  sel_write(sel, file)
::    47:  sel_clear(sel, winfd)
::    62:  sel_read(sel, file)
::    75:  sel_report(sel, file)
::    89:  sel_length()
::   110:  stuff_selection()
::   120:  advise_text_selection()
::   125:  start_selection()
::   147:  continue_selection()
::   167:  end_selection()
::   193:  set_text_selection()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwselection.c,v $
 * Revision 1.1  89/08/23  13:21:11  pop
 * Initial revision
 * 
*/
