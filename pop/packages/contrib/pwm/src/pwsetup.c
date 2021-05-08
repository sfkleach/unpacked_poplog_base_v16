/* --- Copyright University of Sussex 1989.  All rights reserved. ---------
 * File:        C.sun/pwm/pwsetup.c
 * Purpose:     setup for the PWM, making windows, cursor manipulation
 * Author:      Ben Rubinstein, Feb 20 1987 (see revisions)
 * $Header: /tmp_mnt/poplog/pop/pwm/RCS/pwsetup.c,v 1.4 89/10/19 19:28:03 pop Exp $
 */

#include "pwdec.h"
#include <sgtty.h>
#include <sys/ioctl.h>
#include "pwimages.h"

/*--- procedures used at startup time ----------------------------------- */

/*--------------------------------------------------------------------
*   miscellaneous setting up stuff
*/
misc_setup()
{
    popicon.ic_textrect.r_top = popicon.ic_height - fontadv_y;
    popicon.ic_textrect.r_height = fontadv_y;

    vedicon.ic_textrect.r_top = vedicon.ic_height - fontadv_y;
    vedicon.ic_textrect.r_height = fontadv_y;

    txticon.ic_textrect.r_top = txticon.ic_height - fontadv_y;
    txticon.ic_textrect.r_height = fontadv_y;

    gfxicon.ic_textrect.r_top = gfxicon.ic_height - fontadv_y;
    gfxicon.ic_textrect.r_height = fontadv_y;

    win_cursors[0] = &txtcursor1;
    win_cursors[1] = &txtcursor2;
    win_cursors[2] = &gfxcursor;

    graphic_op = PIX_SRC;
    graphic_value = 1;

    cg_winisframe = ci_mousedown = co_ceolneeded = co_winiscooked = FALSE;
    term_grafmode = term_insrtmode = FALSE;

    co_charpr = co_replace_char;
    co_bufferpr = co_buffer_replace;

    polling_timeout.tv_sec = polling_timeout.tv_usec = 0;

    /* both will be redefined to firstwin in main */
    current_graf = current_in = WT_NOWIN;

    poplog_connected = poplog_listening = base_cooked = ved_cooked = FALSE;

    pwmabortrequest = 0;

    selectstart.x = selectstart.y = -1;

    nxtwin_winpos.x = nxtwin_iconpos.x = -1;
    nxtwin_iconic = 0;

    PWMPID = getpid();
}


/*--------------------------------------------------------------------
*   initalise "sw_in_mask", which will be used for all the subwindows.
*       only called once (by main), and could be inline, but modularity...
*/
make_input_mask()
{
    input_imnull(&sw_in_mask);                      /* zero all bits */
    sw_in_mask.im_flags |= IM_ASCII | IM_NEGEVENT;  /* allow ascii */
    win_setinputcodebit(&sw_in_mask, MS_LEFT);      /* allow mouse buttons */
    win_setinputcodebit(&sw_in_mask, MS_MIDDLE);
    win_setinputcodebit(&sw_in_mask, MS_RIGHT);
    win_setinputcodebit(&sw_in_mask, LOC_MOVEWHILEBUTDOWN);
    win_setinputcodebit(&sw_in_mask, LOC_WINENTER);
    win_setinputcodebit(&sw_in_mask, LOC_WINEXIT);
}

/*--------------------------------------------------------------------
* clear the table, to say that there are no windows around.
*       only called once (in main), and could be in-line:
*       but we are modular little people...
*/
wipe_ids_array()
{
    int i;

    for (i = WT_FIRSTWIN; i <= WT_LASTWIN; i++)
        wt_active[i] = WT_UNUSED;
}


/*--------------------------------------------------------------------
*   this is almost certainly redundant, since we keep the device in half
*   cooked or raw mode in poplog: but might possibly be useful if we're
*   running a shell in the base window.
*/
frig_pty_chars()
{
    struct tchars sc;
    struct ltchars lc;

    ioctl(client_ofd, TIOCGETC, &sc);
    pty_intrc = sc.t_intrc;
    pty_quitc = sc.t_quitc;
    pty_startc = sc.t_startc;
    pty_stopc = sc.t_stopc;
    pty_eofc = sc.t_eofc;
    sc.t_brkc = 255;    /* -disabled */
    ioctl(client_ofd, TIOCSETC, &sc);

    ioctl(client_ofd, TIOCGLTC, &sc);
    lc.t_suspc = 28;    /* ^\ */
    lc.t_dsuspc = 25;   /* ^Y */
    lc.t_rprntc = 18;   /* ^R */
    lc.t_flushc = 15;   /* ^O */
    lc.t_werasc = 23;   /* ^W */
    lc.t_lnextc = 255;  /* -disabled */
    ioctl(client_ofd, TIOCSLTC, &sc);
}

/*--- procedures for making new windows --------------------------------- */


/*--------------------------------------------------------------------
*   extra_y is to make the backup pixrect slightly bigger, so that if we try
*   and scroll up with a batch raster-op from the backup pixrect, we won't
*   get a flash of garbage at the bottom of the screen.  If the window is
*   going to be a text window, this arg will be the height of the font: for
*   a graphics window it will be zero.  For the base window we have to use
*   the command line args, so this is indicated by a negative value for the
*   extra-y argument.  The reason for clumping all these together in this
*   long and awkward procedure is to allow crashing out at any stage of the
*   process to happen cleanly.
*/
new_vanilla_window(header, label, height, width, icon, extra_y)
int height, width, extra_y;
char *header, *label;
struct icon *icon;
{
    int index, weirdfd;

    if  ((index = next_index()) == WT_NOWIN)
    {
        misprint(-1, "PWM: can't make window - no room at table\n");
        goto badexit1;
    }

    if ((weirdfd = check_free_fds()) == -1)
    {
        misprint(-1, "PWM: can't make window - too many PWM windows\n");
        goto badexit1;
    }

    /* sort out position */
    if (nxtwin_winpos.x == -1)
    {
        nxtwin_winpos.x = WINSTARTX + (22 * index);
        nxtwin_winpos.y = WINSTARTY + (36 * index);
    }

    if (nxtwin_iconpos.x == -1)
    {
        nxtwin_iconpos.x =
            icon_x_position(iconstartpos.x + index * icondirection.x);
        nxtwin_iconpos.y =
            icon_y_position(iconstartpos.y + index * icondirection.y);
    }

    if (extra_y < 0)    /* base window: dims in chars, use toolargs */
    {
        if  ((toolp = tool_make(WIN_LABEL, header, WIN_ICON, icon,
                WIN_ICON_LABEL, label,
                WIN_COLUMNS, width, WIN_LINES, height,
                WIN_ATTR_LIST,  toolargs,
                WIN_ICON_TOP, iconstartpos.y, WIN_ICON_LEFT, iconstartpos.x,
                WIN_TOP, winstartpos.y, WIN_LEFT, winstartpos.x,
                0)) == NULL)
        {
            misprint(index, "PWM: can't make tool %d\n");
            goto badexit2;
        }
        /* free storage allocated to tool_args */
        tool_free_attribute_list(toolargs);

        /* take abs value of extra-y */
        extra_y = 0 - extra_y;
    }
    else if (extra_y == 0)  /* then gfx: dimensions in pixels */
    {
        if  ((toolp = tool_make(WIN_LABEL, header, WIN_ICON_LABEL, label,
                WIN_WIDTH, width, WIN_HEIGHT, height,
                WIN_TOP,    nxtwin_winpos.y,
                WIN_LEFT,   nxtwin_winpos.x,
                WIN_ICON, icon,
                WIN_ICON_TOP, nxtwin_iconpos.y,
                WIN_ICON_LEFT, nxtwin_iconpos.x,
                WIN_ICONIC, nxtwin_iconic,
                0)) == NULL)
        {
            misprint(index, "PWM: Can't make tool %d\n");
            goto badexit2;
        }
    }
/*  else if (com_charargs[1] == 'v')    ;;; ved window: dimensions in characters
    {
        if  ((toolp = tool_make(WIN_LABEL, header, WIN_ICON_LABEL, label,
                WIN_COLUMNS, width, WIN_LINES, height,
                WIN_TOP,    nxtwin_winpos.y,
                WIN_LEFT,   nxtwin_winpos.x,
                WIN_ICON, icon,
                WIN_ICON_TOP, nxtwin_iconpos.y,
                WIN_ICON_LEFT, nxtwin_iconpos.x,
                WIN_ICONIC, nxtwin_iconic,
                0)) == NULL)
        {
            misprint(index, "PWM: can't make tool %d\n");
            goto badexit2;
        }
    }
*/ 
    else    /* text window: dimensions in characters, "TXT" icon */
    {
        if  ((toolp = tool_make(WIN_LABEL, header, WIN_ICON_LABEL, label,
                WIN_COLUMNS, width, WIN_LINES, height,
                WIN_TOP,    nxtwin_winpos.y,
                WIN_LEFT,   nxtwin_winpos.x,
                WIN_ICON, icon,
                WIN_ICON_TOP, nxtwin_iconpos.y,
                WIN_ICON_LEFT, nxtwin_iconpos.x,
                WIN_ICONIC, nxtwin_iconic,
                0)) == NULL)
        {
            misprint(index, "PWM: can't make tool %d\n");
            goto badexit2;
        }
    }

    if  ((tool_swp = tool_createsubwindow(toolp, "",
                    TOOL_SWEXTENDTOEDGE, TOOL_SWEXTENDTOEDGE,
                    NULL)) == NULL)
    {
        misprint(-1, "PWM: can't make window: not enough window devices\n");
        goto badexit3;
    }

    if  ((subwin_pwp = pw_open(tool_swp->ts_windowfd)) == NULL)
    {
        misprint(index, "PWM: can't create pixwin %d\n");
        goto badexit3;
    }

    win_getsize(tool_swp->ts_windowfd, &(wt_swrect[index]));

    /* make it retained */
    if  ((subwin_pwp->pw_prretained =
                mem_create(wt_swrect[index].r_width,
                            wt_swrect[index].r_height + extra_y,
                            SCREENDEPTH)) == NULL)
    {
        misprint(index, "PWM: can't create retained rec for win %d\n");
        goto badexit3;
    }

    /* set subwindow "private data" so sigwinch handler can identify it */
    tool_swp->ts_data = (caddr_t)index;

    win_setinputmask(tool_swp->ts_windowfd,
                        &sw_in_mask,
                        (struct inputmask *)NULL,
                        WIN_NULLLINK);

    /* other installation common to all window types */
    wt_toolwp[index] = toolp;
    wt_wimask[index] = toolp->tl_windowfd;

    wt_swfd[index] = tool_swp->ts_windowfd;
    wt_toolswp[index] = tool_swp;
    wt_swimask[index] = tool_swp->ts_windowfd;

    wt_pixwinp[index] = subwin_pwp;
    wt_iconic[index] = WT_OPENED;
    wt_colmap[index] = -1;
    wt_curposp[index].y = txtcoord_pix_y(0);
    wt_curposp[index].x =
    wt_curposc[index].x = wt_curposc[index].y = 0;
    wt_flags[index] = 0;

    close(weirdfd);
    goto newvanexit;

badexit3:
    tool_destroy(toolp);
badexit2:
    wt_active[index] = WT_UNUSED;
    close(weirdfd);
badexit1:
    index = WT_NOWIN;
newvanexit:
    nxtwin_winpos.x = nxtwin_iconpos.x = -1;
    nxtwin_iconic = 0;
    return(index);
}


/*--------------------------------------------------------------------
*   make new text tool and sub window, and put it in tables.
*   assumes that tool has been made as "toolp", with subwindow
*
*/
new_txt_window(index, rows, columns)
int index, rows, columns;
{
    win_setcursor(tool_swp->ts_windowfd, win_cursors[0]);
    win_setcursor(tool_swp->ts_windowfd, win_cursors[(wt_cursor[index] = 0)]);

    /* install sigwinch handler for this sub_window */
    tool_swp->ts_io.tio_handlesigwinch = txtwin_sigwinch;

    tool_install(toolp);                    /* install tool in window tree */

    /* make a data structure to hold the screen data, and clear it */
    wt_scrndata[index] = make_screen_record(rows, columns);
    clear_screen_record(wt_scrndata[index]);
#ifdef DeBug
    printf("--- New screen rec: $%x\n", wt_scrndata[index]);
#endif

    /* clear the pixwin */
    pw_writebackground(subwin_pwp, 0, 0,
                            wt_swrect[index].r_width,
                            wt_swrect[index].r_height,
                            PIX_CLR);

    if (com_charargs[1] == 'v')         /* ved window */
        wt_active[index] = WT_VEDWIN;
    else                            /* base or user text window */
        wt_active[index] = WT_TEXTW;

    redo_window_masks();

    tool_sigwinch(toolp);                   /* ensure it'll be refreshed */

#ifdef DeBug
    printf("--- New txt win: %d. pixrects: $%x, $%x\n", index,
                            subwin_pwp->pw_pixrect, subwin_pwp->pw_prretained);
#endif
}

/*--------------------------------------------------------------------
*   make new tool with graphics sub window, and put it in tables.
*/
new_gfx_window(index, height, width)
int index, height, width;
{
    win_setcursor(tool_swp->ts_windowfd, win_cursors[(wt_cursor[index] = 2)]);

    /* install sigwinch handler for this sub_window */
    tool_swp->ts_io.tio_handlesigwinch = gfxwin_sigwinch;

    tool_install(toolp);                    /* install tool in window tree */

    wt_active[index] = WT_GRAPHW;

    redo_window_masks();

    tool_sigwinch(toolp);                   /* ensure it'll be refreshed */

#ifdef DeBug
    printf("--- New gfx win: %d. pixrects: $%x, $%x\n", index,
                            subwin_pwp->pw_pixrect, subwin_pwp->pw_prretained);
#endif
    return(index);
}

/*--------------------------------------------------------------------
*   ensure that there are enough spare fds to complete the window-making
*   process, instead of finding out when we're half-way through and
*   getting reams of rude error messages.  We return the first fd both
*   as a method of returning -1 if there are not enough spare fds, and
*   because if there are, due to a bug in tool_make, thhis fd will be
*   opened and not closed, so we have to close it ourselves.
*/
check_free_fds()
{
    int fd1, fd2, fd3, fd4;

    fd1 = open("/dev/win0", 0);
    fd2 = open("/dev/win0", 0);
    fd3 = open("/dev/win0", 0);
    fd4 = open("/dev/win0", 0);
    close(fd1); close(fd2); close(fd3); close(fd4);

    if ((fd2 == -1) || (fd3 == -1) || (fd4 == -1) ) fd1 = -1;
#ifdef DeBug
    printf("--- cff: %d,%d,%d,%d\n", fd1, fd2, fd3, fd4);
#endif

    return(fd1);
}

/* -- procedures dealing with cursor images------------------------- */

hide_mouse_cursor(win)
int win;
{
    win_setcursor(wt_swfd[win], &nullcursor);
}

/*--------------------------------------------------------------------
*   this is a frig: there should be a table of cursors, with the
*   procedures kill_cursor, new_cursor_file and new_cursor_image being used
*   to add and remove cursors in the table. but since the new_cursor_xxx
*   haven't yet been defined, this will serve for the nonce.
*/
set_win_cursor()
{
    register char win, cid;

    if ((win = check_window_id(1)) != WT_NOWIN)
    {
        if (((cid = com_charargs[0] - 32) < 3) && (cid >= 0))
        {
            win_setcursor(wt_swfd[win], win_cursors[cid]);
            wt_cursor[win] = cid;
        }
        else
            misprint(cid, "PWM: cannot set cursor %d, no such cursor\n");
    }
}

/*--------------------------------------------------------------------
*   see above notes on how come we can get away with this
*/
kill_cursor()
{
    register int cid;

    if (((cid = com_charargs[0] - 32) == 0) || (cid == 1))
        misprint(cid, "PWM: cannot kill cursor %d: protected cursor\n");
    else
        misprint(cid, "PWM: cannot kill cursor %d: no such cursor\n");
}

new_cursor_file()
{
    misprint(-1, "PWM: creating new cursor images not currently supported\n");
}

new_cursor_image()
{
    misprint(-1, "PWM: creating new cursor images not currently supported\n");
}

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Feb 23 1989
    Implemented changes for SFR 4185
$Log:	pwsetup.c,v $
 * Revision 1.4  89/10/19  19:28:03  pop
 * windows now default to SCREENDEPTH depth
 * 
 * Revision 1.3  89/08/23  17:47:14  pop
 * modified frig_pty_char to set pty_* variables
 * made default window depth 1 cf. sunview
 * 
 * Revision 1.2  89/08/23  15:35:13  pop
 * modifed to use BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:21:14  pop
 * Initial revision
 * 
 */
