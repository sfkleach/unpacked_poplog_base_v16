/* --- Copyright University of Sussex 1989.  All rights reserved. ---------
 * File:        C.sun/pwm/pwmisc.c
 * Purpose:     miscellaneous routines for Sun PWM
 * Author:      Ben Rubinstein, Jan  8 1987 (see revisions)
 * $Header: /popv13.5/pop/pwm/RCS/pwmisc.c,v 1.2 89/08/23 15:27:59 pop Exp $
 */

/*
|       The main program loop (vedwin_select) is in here, and the routines
|   for selecting, killing, and refreshing (..._sigwinch) windows.
*/

#include "pwdec.h"
#include "pwrepseq.h"

#include <errno.h>
extern int errno;
int recursing_sigwinch;

/*--------------------------------------------------------------------
*/
vedwin_select()
{
    int i, nfds, tablesize, fd;
    char code;

    /* do a refresh on all, to ensure they are visible */
    do_sigwinches();

    tablesize = getdtablesize();

    while (poplog_proc_died == 0)
    {

        /* check for sigwinches on all windows */
        if (sigwinch_pending == 1) do_sigwinches();

        /* get the current input mask */
        redo_window_masks();

        nfds = select(tablesize, &fdset, 0, 0, 0);

        if  (nfds < 0)
        {
            if (errno == EBADF)
                mishap(-1, "||| select: EBADF (bad fd)\n");
        /*
            else if (errno == EINTR)
                go round again so the signal can be caught */
        }
        else
        {
#ifdef DeBug
            if (FD_ISSET(STDIN_FD,&fdset)) {
                handle_control_input();
                FD_CLR(STDIN_FD,&fdset);
            }
#endif

            /* outer window */
            for (i = WT_FIRSTWIN; i <= WT_LASTWIN; i++) {
                if  (wt_active[i] >= WT_ACTIVE) {
                    fd = wt_wimask[i];
                    if (FD_ISSET(fd,&fdset)){
                        user_toolwin_input();
                        goto next_while;
                    }
                }
            }
            /* inner window */
            for (i = WT_FIRSTWIN; i <= WT_LASTWIN; i++) {
                if  (wt_active[i] >= WT_ACTIVE) {
                    fd = wt_swimask[i];
                    if (FD_ISSET(fd,&fdset)){
                        user_subwin_input();
                        goto next_while;
                    }
                }
            }
            if (FD_ISSET(client_ifd,&fdset)){
                poplog_input();
                FD_CLR(client_ifd,&fdset);
                goto next_while;
            }
            mishap(-1,"||| utterly naff fdset\n");
            /* end of if statement */
        }
next_while: ;
    }

    in_escape = com_buflen = com_seq_len = com_termin == 0;

#ifdef DeBug
    printf("*** signal from child: getting last thoughts ***\n");
#endif

    while (poll_poplog_process() == 1)
    {
        poplog_input();
    }

#ifdef DeBug
    printf("*** signal from child: got last thoughts ***\n");
#endif
    kill_all_windows();
}


poll_poplog_process()
{
    int tablesize;

    FD_ZERO(&fdset);
    FD_SET(client_ifd,&fdset);

    tablesize = getdtablesize();
    return(select(tablesize, &fdset, 0, 0, &polling_timeout));
}

do_sigwinches()
{
    int index;
    struct tool *toolptr;

    for (index = WT_FIRSTWIN; index <= WT_LASTWIN; index++)
        if  ((wt_active[index]) >= WT_ACTIVE)
        {
            toolptr = wt_toolwp[index];
            ((toolptr->tl_io).tio_handlesigwinch)(toolptr);
        }
    /* close for loop */
    sigwinch_pending = 0;
}


/*--------------------------------------------------------------------
*/
refresh_txtwin(pixwinp, rect, screen, curpos)
struct pixwin *pixwinp;
struct xypos  *curpos;
struct screen_record *screen;
struct rect *rect;
{
    int ri, ci;
    int rows, cols;
    char **text, *p;

    rows = screen->rows;
    cols = screen->cols;
    text = screen->text;

    pw_lock(pixwinp, rect);

    /* clear the pixwin */
    pw_writebackground(pixwinp, 0, 0, rect->r_width, rect->r_height, PIX_CLR);

    /* draw text */
    for (ri = 0; ri < rows; ri++)
    {
        p = text[ri];
        pw_text(pixwinp, 0, txtcoord_pix_y(ri),
                            PIX_SRC ^ PIX_DST, norm_font, p);
    }

    /* draw the cursor */
    Paint_cursor;

    pw_unlock(pixwinp);
}

/*--------------------------------------------------------------------
*   this is a trap, so that we can spot size changes and round them
*   down to text sizes (and enusre that window can display at least one
*   character).  The real sigwinching is done in real_txtwin_sigwinch,
*   below.
*/
txtwin_sigwinch(sw_num)
int sw_num;
{
    int rows, cols;
    struct tool     *toolptr;
    struct toolsw   *toolswp;
    struct pixwin   *pixwinp;
    struct rect newrect, oldrect;

    toolswp = wt_toolswp[sw_num];
    oldrect = wt_swrect[sw_num];
    pixwinp = wt_pixwinp[sw_num];

    /* determine current size of subwindow */
    win_getsize(toolswp->ts_windowfd, &newrect);

    /* prepare pixwin for damage repair */
/*  pw_damaged(pixwinp);*/

    if (recursing_sigwinch == 0)
    {
        /* if the size has changed */
        if ((oldrect.r_width != newrect.r_width) ||
                                (oldrect.r_height != newrect.r_height))
        {
            if ((rows = newrect.r_height / fontadv_y) < 1) rows = 1;
            if ((cols = newrect.r_width / fontadv_x) < 1) cols = 1;
#ifdef DeBug
        printf("txsg1: size - h=%d, w=%d\n", rows, cols);
#endif
            tool_set_attributes(wt_toolwp[sw_num],
                            WIN_LINES, rows, WIN_COLUMNS, cols, 0);
#ifdef DeBug
        printf("txsg2: size - h=%d, w=%d\n", rows, cols);
#endif
            recursing_sigwinch = 1;
            toolptr = wt_toolwp[sw_num];
            ((toolptr->tl_io).tio_handlesigwinch)(toolptr);
            recursing_sigwinch = 0;
        }
        else
            real_txtwin_sigwinch(sw_num);
    }
    else
        real_txtwin_sigwinch(sw_num);
}


/*--------------------------------------------------------------------
*/
real_txtwin_sigwinch(sw_num)
int sw_num;
{
    int i, ri, ci, old_co;
    int rows, cols;
    char **text, *p;

    struct toolsw *toolswp;
    struct pixwin *pixwinp;
    struct xypos  *curpos;
    struct screen_record *screen;
    struct rect newrect, oldrect;

    int icflag;

    screen = wt_scrndata[sw_num];
    toolswp = wt_toolswp[sw_num];
    oldrect = wt_swrect[sw_num];
    pixwinp = wt_pixwinp[sw_num];

    /* determine current size of subwindow */
    win_getsize(toolswp->ts_windowfd, &newrect);

    /* prepare pixwin for damage repair */
    pw_damaged(pixwinp);

    /* if the size has changed */
    if (oldrect.r_width != newrect.r_width ||
                            oldrect.r_height != newrect.r_height)
    {
#ifdef DeBug
        printf("txsg3: size - h=%d, w=%d\n", newrect.r_height, newrect.r_width);
#endif

        /* make a new screen record */
        wt_scrndata[sw_num]
                        = resize_screen_rec(screen, newrect, sw_num);
        free_screen_record(screen);     /* free memory used by old one */
        screen = wt_scrndata[sw_num]; /* switch identifiers */

        /* remember new size */
        wt_swrect[sw_num] = newrect;

        old_co = current_out;
        select_output_window(sw_num);   /* reset size things */
        report_win_resized(sw_num, co_widthc, co_heightc);

        /* ensure cursor is on screen */
        if (co_curposc->x >= co_widthc)
        {
            co_curposc->x = co_widthc - 1;
            co_curposp->x = txtcoord_pix_x(co_curposc->x);
        }
        if (co_curposc->y >= co_heightc)
        {
            co_curposc->y = co_heightc - 1;
            co_curposp->y = txtcoord_pix_y(co_curposc->y);
        }

        if  (sw_num != old_co)
            select_output_window(old_co);   /* set it back */

        /* destroy the old backup pixrect */
        pr_destroy(pixwinp->pw_prretained);

        /* make a new backup pixrect */
        if  ((pixwinp->pw_prretained =
                    mem_create(newrect.r_width,
                                newrect.r_height + fontadv_y,
                               /* IR: SFR 4185 - replaced 1 with following */
                               pixwinp->pw_pixrect->pr_depth)
             ) == NULL)
            mishap(index, "||| Can't create retained rec for win %d\n");

#ifdef DeBug
    printf("--- refreshing txtwin %d\n", sw_num);
#endif
        refresh_txtwin(pixwinp, &newrect, screen, &wt_curposp[sw_num]);

        pw_donedamaged(pixwinp); /* clip on all visible areas */
    }
    else /* make sure call pw_donedamaged if haven't above */
    {
        pw_repairretained(pixwinp);
        pw_donedamaged(pixwinp);
    }
    if (selectedwin == sw_num) mark_tool_border(sw_num, LOC_WINENTER);
}


/*--------------------------------------------------------------------
*/
gfxwin_sigwinch(sw_num)
int sw_num;
{
    int icflag;
    struct toolsw *toolswp;
    struct pixwin *pixwinp;
    struct rect newrect, oldrect;

    toolswp = wt_toolswp[sw_num];
    oldrect = wt_swrect[sw_num];
    pixwinp = wt_pixwinp[sw_num];

    /* determine current size of subwindow */
    win_getsize(toolswp->ts_windowfd, &newrect);

    /* prepare pixwin for damage repair */
    pw_damaged(pixwinp);

    /* if the size has changed */
    if  ((oldrect.r_width != newrect.r_width)
        || (oldrect.r_height != newrect.r_height))
    {

        wt_swrect[sw_num] = newrect; /* remember new size */

        /* destroy the old backup pixrect */
        pr_destroy(pixwinp->pw_prretained);

        /* make a new backup pixrect */
        if  ((pixwinp->pw_prretained =
                    mem_create(newrect.r_width, newrect.r_height,
                               /* IR, SFR 4185 - replaced 1 with following */
                               pixwinp->pw_pixrect->pr_depth)
             ) == NULL)
            mishap(index, "||| Can't create retained rec for win %d\n");

        /* clear the pixwin */
        pw_writebackground(pixwinp, 0, 0,
                                newrect.r_width,
                                newrect.r_height,
                                PIX_CLR);

        pw_donedamaged(pixwinp); /* clip on all visible areas */

        report_win_resized(sw_num, newrect.r_width, newrect.r_height);  /* tell poplog */
    }
    else
    {
        pw_repairretained(pixwinp);
        pw_donedamaged(pixwinp);
    }
    if (selectedwin == sw_num) mark_tool_border(sw_num, LOC_WINENTER);
}


/*--------------------------------------------------------------------
*  return the number of windows which are active
*/
count_live_windows()
{
    int i, liveones;
    struct tool *toolp;

    liveones = 0;
    for (i = WT_FIRSTWIN; i <= WT_LASTWIN; i++)
    {
        if  ((wt_active[i]) != WT_UNUSED)
            liveones = liveones + 1;
    }
    return(liveones);
}

/*--------------------------------------------------------------------
* kills all the windows listed as active. Basically
* used when the poplog process dies, to clean up nicely.
*/
kill_all_windows()
{
    int i;

    for (i = WT_LASTWIN; i >= WT_FIRSTWIN; i--)
        if  ((wt_active[i]) >= WT_ACTIVE)
        really_kill_window(i);
}

/*--------------------------------------------------------------------
*   actually do the killing of a window.
*/
really_kill_window(n)
int n;
{
    grph_unsetmap(n);   /* necessary in case it has a cms */

    tool_done(wt_toolwp[n]);    /* this is almost certainly redundant */

    tool_destroy(wt_toolwp[n]);

    close(wt_swfd[n]);
    close(wt_toolwp[n]->tl_windowfd);

    wt_active[n] = WT_UNUSED;
    redo_window_masks();

    if (n != 0)
    {
        if (current_out == n) select_output_window(0);
        if (current_graf == n) select_graphic_window(0);
    }
}

switch_current_in(new_in)
{
    if  (current_in != new_in)
    {
        report_input_window(new_in);
        current_in = new_in;

        ci_mousedown = 0;
    }
}

select_output_window(n)
register int n;
{
    /* save gfx and insert mode for old window */
    if  ((current_out >= WT_FIRSTWIN)
            && (current_out <= WT_LASTWIN)
            && (wt_active[current_out] >= WT_ACTIVE)
            && (wt_active[current_out] < WT_GRAPHW))
    {
        wt_flags[current_out] = term_grafmode | term_insrtmode;
    }

    if  ((n >= WT_FIRSTWIN)
            && (n <= WT_LASTWIN)
            && (wt_active[n] >= WT_ACTIVE)
            && (wt_active[current_out] < WT_GRAPHW))
    {
        current_out = n;

        co_toolp = wt_toolwp[n];
        co_toolfd = co_toolp->tl_windowfd;

        co_pixwinp = wt_pixwinp[n];
        co_rect = wt_swrect[n];

        co_widthp = co_rect.r_width;
        co_heightp = co_rect.r_height;

        /* whether to wrap long lines round */
        co_winiswrap = ((wt_active[n] == WT_TEXTW) ? TRUE : FALSE);

        co_curposp = &wt_curposp[n];
        co_curposc = &wt_curposc[n];

        co_text = (wt_scrndata[n])->text;
        co_widthc = (wt_scrndata[n])->cols;
        co_heightc = (wt_scrndata[n])->rows;

        if (n == 0)     /* base window */
        {
            bw_text = co_text;
            bw_widthc = co_widthc;
            co_winiswrap = ((!poplog_listening || base_cooked) ? TRUE : FALSE);
            co_winiscooked = base_cooked;
        }
        else if (wt_active[n] == WT_VEDWIN)
            co_winiscooked = ved_cooked;
        else
            co_winiscooked = FALSE;

        co_botlinetop = txtcoord_pix_y(co_heightc - 1) + font_home_y;
        co_botlineheight = co_widthp - co_botlinetop;

        term_grafmode = wt_flags[n] & TFLG_GRAFMODE;
        term_insrtmode  = wt_flags[n] & TFLG_INSERTMODE;

        if (term_insrtmode == FALSE)
        {
            co_charpr = co_replace_char;
            co_bufferpr = co_buffer_replace;
        }
        else
        {
            co_charpr = co_insert_char;
            co_bufferpr = co_buffer_insert;
        }
    }
    else
        mishap(n, "PWM: attempt to select invalid window for output: %d\n");
}

/*--------------------------------------------------------------------
*   set the global vars twin_ibits and swin_ibits to be input masks,
*   which can be handed to select, for all the current tool windows,
*   and all the current subwindows.
*/
redo_window_masks()
{
    int i;

    FD_ZERO(&fdset);
    FD_SET(client_ifd,&fdset);

#ifdef DeBug
    FD_SET(STDIN_FD,&fdset);
#endif

    for (i = WT_FIRSTWIN; i <= WT_LASTWIN; i++)
        if (wt_active[i] >= WT_ACTIVE)
        {
            FD_SET(wt_wimask[i],&fdset);
            FD_SET(wt_swimask[i],&fdset);
        }
}

/*--------------------------------------------------------------------
*   stupid function for catching alarm signals, etc
*/
identfn()
{
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    21:  vedwin_select()
::    86:  poll_poplog_process()
::    96:  do_sigwinches()
::   114:  refresh_txtwin(pixwinp, rect, screen, curpos)
::   153:  txtwin_sigwinch(sw_num)
::   203:  real_txtwin_sigwinch(sw_num)
::   293:  gfxwin_sigwinch(sw_num)
::   349:  count_live_windows()
::   367:  kill_all_windows()
::   379:  really_kill_window(n)
::   401:  switch_current_in(new_in)
::   412:  select_output_window(n)
::   482:  redo_window_masks()
::   505:  identfn()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Feb 23 1989
    Implemented changes described in SFR 4185
$Log:	pwmisc.c,v $
 * Revision 1.2  89/08/23  15:27:59  pop
 * modified select to use BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:20:51  pop
 * Initial revision
 * 
 */
