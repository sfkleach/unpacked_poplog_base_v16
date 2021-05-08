/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwmenus.c
 * Purpose:		routines for making and invoking menus and prompt boxes
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwmenus.c,v 1.1 89/08/23 13:20:48 pop Exp $
 */

#include "pwdec.h"
#include <suntool/menu.h>

#define MENUDELIM1  9	/* ordinary delimiter */
#define MENUDELIM2	8	/* separator - no effect on suns */

#define MOPT_NORM	14	/* normal - full intensity, selectable */
#define MOPT_ADVS	1	/* advisory - half intensity, non-selectable */

struct timeval fake_tv = {0, 0};

static mitem_size = sizeof(struct menuitem);

struct menuitem bwin_menu_item[1], user_menu_items[VW_MAXITEMS];

struct menu		user_menu, basewin_menu;
struct menu *menu_pointer;
struct prompt	user_prompt;

/*--------------------------------------------------------------------
*	make a naf menu, with no items and a silly title; and set up the
*	invariant parts of the prompt structure.
*/
menu_setup()
{
    user_menu.m_imagetype = MENU_IMAGESTRING,
	user_menu.m_imagedata = "NoMenu";
    user_menu.m_itemcount = 0;
    user_menu.m_items = user_menu_items;
    user_menu.m_next = (struct menu *) NULL;
    user_menu.m_data = NULL;

    basewin_menu.m_imagetype = MENU_IMAGESTRING,
	basewin_menu.m_imagedata = "PWMtool";
    basewin_menu.m_itemcount = 1;
    basewin_menu.m_items = bwin_menu_item;
    basewin_menu.m_next = (struct menu *) NULL;
    basewin_menu.m_data = NULL;

	bwin_menu_item[0].mi_imagetype = MENU_IMAGESTRING;
	bwin_menu_item[0].mi_imagedata = "Stuff";
	bwin_menu_item[0].mi_data = (caddr_t)'S';

	user_prompt.prt_rect.r_height = PROMPT_FLEXIBLE;
	user_prompt.prt_font = norm_font;
}

define_menu()
{
	int menunumber, j, item;
	char *strings;

	user_menu.m_imagedata =
				(caddr_t)(strings = (char *)malloc(com_stringlen));

	item = 0;

	for (j = 0; j < com_stringlen; )
	{
		if (((*strings++ = com_stringarg[j]) == MENUDELIM1)
			|| (com_stringarg[j] == MENUDELIM2))
		{
			*(strings - 1) = 0;	/* terminate previous item */

			if	(item < VW_MAXITEMS)	/* assign this item */
			{
				user_menu_items[item].mi_imagetype = MENU_IMAGESTRING;
				user_menu_items[item].mi_imagedata = (caddr_t)strings;
				user_menu_items[item].mi_data = (caddr_t)++item;
			}

			if (com_stringarg[++j] < ' ')	/* control: skip it */
			{
				j++;
			}
		}
		else
			j++;
    }

	user_menu.m_itemcount = item - 1;

	return(0);		/* !!! kludge !!! */
}

/*--------------------------------------------------------------------
*	invoke the current user menu in the current input window, at the
*	position of the mouse at the last input event (which will usually be
*	be the input event which caused poplog to decide that the menu should
*	be invoked)
*		if wfd == -1 then
*			com_charargs[0] :	window for position or WT_NOWIN
*			com_numargs[0]	:	x-position relative to window
*			com_numargs[1]	:	y-position relative to window
*
*/
display_any_menu(menu_pointer, wfd)
struct menu *menu_pointer;
int wfd;
{
	struct menuitem *mi;
	register int mid, win;

	if (wfd == -1)
	{
		if ((win = com_charargs[0] - 32) != WT_NOWIN)
			win = check_window_id(0);

		if (win != WT_NOWIN)
		{
			wfd = wt_swfd[win];
			inevent.ie_locx = com_numargs[0];
			inevent.ie_locy = com_numargs[1];
		}
		else if (current_in == WT_NOWIN)
			wfd = rootfd;
		else
			wfd = wt_swfd[current_in];
	}

	if ((inevent.ie_code < BUT_FIRST) || (inevent.ie_code > BUT_LAST))
		inevent.ie_code = MS_RIGHT;

	inevent.ie_flags = 0;
	inevent.ie_time = fake_tv;

	mi = menu_display(&menu_pointer, &inevent, wfd);

	ci_mousedown = 0;

	if	(mi == (struct menuitem *) NULL)
		return(0);
	else
		return((int)mi->mi_data);
}


define_new_menu()
{
/*	report_status(define_menu());*/
	report_status(-1);			/* !!! kludge !!! */
}

/*--------------------------------------------------------------------
*	invoke the current user menu in the current input window, at the
*	position of the mouse at the last input event (which will usually be
*	be the input event which caused poplog to decide that the menu should
*	be invoked)
*/
display_def_menu()
{
	register int mid, res;

	if ((mid = com_charargs[1] - 32) != 0)	/* !!! kludge !!! */
		misprint(mid, "PWM: cannot put up menu %d: no such menu\n");
	else
		report_input_event('M', 32 + display_any_menu(&user_menu, -1));
}

display_new_menu()
{
	(void)define_menu();
	report_input_event('M', 32 + display_any_menu(&user_menu, -1));
}

display_basewin_menu()
{
	return(display_any_menu(&basewin_menu, wt_swfd[0]));
}


/*--------------------------------------------------------------------
*	put up the given text in a box roughly in the
*	middle of the screen, and wait for some input.   Send a status report
*	of 0 if the input was anything other than one of the mouse buttons, or
*	1, 2 or 3 according to the button that was pressed.
*/
display_prompt()
{
	int c;
	int top, left;

	if	(wmgr_iswindowopen(co_toolfd))
	{
		top = (int)(tool_get_attribute(co_toolp, WIN_TOP));
		left = (int)(tool_get_attribute(co_toolp, WIN_LEFT));
	}
	else
	{
		top = (int)(tool_get_attribute(co_toolp, WIN_ICON_TOP));
		left = (int)(tool_get_attribute(co_toolp, WIN_ICON_LEFT));
	}

	user_prompt.prt_rect.r_left = 330 - left;
	user_prompt.prt_rect.r_top = 330 - top;
	user_prompt.prt_rect.r_width = com_numargs[0] * fontadv_x;
	user_prompt.prt_text = com_stringarg;

	inevent.ie_time = fake_tv;

	menu_prompt(&user_prompt, &inevent, co_toolfd);

	if ((inevent.ie_code >= ASCII_FIRST) && (inevent.ie_code <= ASCII_LAST))
			report_ascii_event('A', inevent.ie_code);
	else
		switch	(inevent.ie_code)
		{
		case MS_LEFT:	report_ascii_event('B', 33); break;
		case MS_MIDDLE:	report_ascii_event('B', 34); break;
		case MS_RIGHT: 	report_ascii_event('B', 35); break;
		default: 		report_ascii_event('B', 32); break;
		}

	ci_mousedown = 0;	/* so poplog won't get following up-button event */
}

/*--------------------------------------------------------------------
*	!!! this hasn't yet been worked out
*/
kill_menu()
{
	register int mid;

	if ((mid = com_charargs[0] - 32) == 0)
		misprint(mid, "PWM: cannot kill menu %d: protected menu\n");
	else
		misprint(mid, "PWM: cannot kill menu %d: no such menu\n");
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    30:  menu_setup()
::    54:  define_menu()
::   103:  display_any_menu(menu_pointer, wfd)
::   144:  define_new_menu()
::   156:  display_def_menu()
::   166:  display_new_menu()
::   172:  display_basewin_menu()
::   184:  display_prompt()
::   226:  kill_menu()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/* 
$Log:	pwmenus.c,v $
 * Revision 1.1  89/08/23  13:20:48  pop
 * Initial revision
 * 
*/
