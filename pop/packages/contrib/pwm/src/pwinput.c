/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:        C.sun/pwm/pwinput.c
 * Purpose:     handle input from client and user
 * Author:      Ben Rubinstein, Jan  8 1987 (see revisions)
 * $Header: /tmp_mnt/poplog/pop/pwm/RCS/pwinput.c,v 1.4 90/06/07 17:59:41 pop Exp $
 */

/*
|       Handle all input.
|   Interesting kinds to distinguish are: input on outer ("tool") window;
|   input from the client process; input on the base window; and input
|   on other windows.
*/

#include "pwdec.h"
#include <sys/ioctl.h>
#include <errno.h>
extern int errno;

#include <suntool/menu.h>
struct menuitem toolmenuitem[]={
   {MENU_IMAGESTRING,"Open",(caddr_t)3},
   {MENU_IMAGESTRING,"Move",(caddr_t)5},
   {MENU_IMAGESTRING,"Resize",(caddr_t)6},
   {MENU_IMAGESTRING,"Front",(caddr_t)7},
   {MENU_IMAGESTRING,"Back",(caddr_t)8},
   {MENU_IMAGESTRING,"Redisplay",(caddr_t)1},
   {MENU_IMAGESTRING,"Quit",(caddr_t)2}
   };
struct menu toolmenu = {MENU_IMAGESTRING,"Frame",
   sizeof(toolmenuitem)/sizeof(toolmenuitem[0]),
   toolmenuitem,
   NULL,
   0};

/* these are for the tool selected proc to play with */
int  fake_obits, fake_ebits;
struct timeval fake_te={0,0}, *fake_tep = &fake_te;

/*--------------------------------------------------------------------
*   there was input on one of the tool windows.  Check which one, and
*   call handle_toolwin_input to deal with it.
*/
user_toolwin_input()
{
    int index, fd;

    for (index = WT_FIRSTWIN; index <= WT_LASTWIN; index++)
        if  (wt_active[index] >= WT_ACTIVE)
        {   /* live window, check if it had input */
            fd = wt_wimask[index];
            if (FD_ISSET(fd,&fdset))
            {
                if ((index == 0) && (selectstart.x != -1)) end_selection();
                handle_toolwin_input(index);
            }
        }
    /* end of for loop */
}

user_subwin_input()
{
    register int index;
    register short code;
    int fd;

    for (index = WT_FIRSTWIN; index <= WT_LASTWIN; index++)
        if  (wt_active[index] >= WT_ACTIVE)
        {   /* live window, check if it had input */
            fd = wt_swimask[index];
            if (FD_ISSET(fd,&fdset))
            {
                (void)input_readevent(wt_swfd[index], &inevent);
                code = inevent.ie_code;

                if ((selectstart.x != -1) && (index == 0)
                        && (code != LOC_MOVEWHILEBUTDOWN)
                        && ((code < MS_LEFT) || (code > MS_RIGHT)))
                    end_selection();

                if (code == LOC_WINENTER)
                {
                    selectedwin = index;
                    mark_tool_border(index, code);
                }
                else if (code == LOC_WINEXIT)
                {
                    selectedwin = WT_NOWIN;
                    mark_tool_border(index, code);

                    if (ci_mousedown != 0)
                    {
                        if ((ci_mmaction & TRK_actionmask) != 0)
                            rubber_finish();
                        report_mouse_exit(ci_mousedown);
                        ci_mmaction = ci_mousedown = 0;
                    }
                }
                else if (one_input == 1)
                {
                    one_input = 0;

                    if  ((code >= ASCII_FIRST) && (code <= ASCII_LAST))
                        report_ascii_event('A', code);
                    else if (index == 0) one_input = 1;
                    else
                        switch  (code)
                        {
                            case MS_LEFT:
                                report_ascii_event('B', 33);
                                ci_mousedown = 0;
                                break;
                            case MS_MIDDLE:
                                report_ascii_event('B', 34);
                                ci_mousedown = 0;
                                break;
                            case MS_RIGHT:
                                report_ascii_event('B', 35);
                                ci_mousedown = 0;
                                break;
                            default: /* (probably mouse motion) */
                                one_input = 1;
                                break;
                        }
                }
                else if ((code >= ASCII_FIRST) && (code <= ASCII_LAST))
                {
                    if ((index == 0) && base_cooked)
                        bwin_ascii_input(code);
                    else
                        handle_swin_input(index);
                }
                else
                {
                    if ((index == 0) && (!poplog_listening || base_cooked))
                        handle_bwin_input(index);   /* do selection */
                    else
                        handle_swin_input(index);
                }
            }
        }
    /* end of for loop */
}

/* --- input from poplog ------------------------------------------------- */

poplog_input()
{

    if ((current_out == 0) && (selectstart.x != -1)) end_selection();

    com_buflen = read(client_ifd, &(com_buffer[0]), COMBUFSIZE);
                                        /* com_buflen is one more than the  *
                                        *   highest meaningful index into   *
                                        *   the input buffer.               */

    com_bufnext = 0;
    cursornotneeded = 1;
    while (com_bufnext < com_buflen)
    {
        if (in_escape == 1)
        {
            while ((in_escape == 1) && (com_bufnext < com_buflen))
                parse_escape_sequence(com_buffer[com_bufnext++]);
        }
        else if (com_buffer[com_bufnext] == VW_ESCAPE)
        {
            com_seq_len = 0;
            in_escape = 1;
            com_seq_add = com_bufnext;
            com_bufnext++;
        }
        else
        {
            if (com_buffer[com_bufnext] == 127)
            {
                co_window_output(com_buffer[com_bufnext++]);
            }
            else if (com_buffer[com_bufnext] > 31)
            {
                register int lc;
                int i, ll;
                char nl;

                lc = com_bufnext;

                while ((lc < com_buflen) && (com_buffer[lc] > 31)) lc++;

                if (lc < com_buflen)
                {
                    if (co_winiscooked && (com_buffer[lc] == 10))
                        nl = 1;
                    else if ((com_buffer[lc] == 13)
                                && (com_buffer[lc + 1] == 10))
                        nl = 2;
                    else nl = 0;
                }
                else
                {
                    nl = 0;
                }

                if (co_winiswrap == FALSE)
                {
                    co_bufferpr(com_bufnext, --lc, nl);
                }
                else        /* wants breaking at right margin */
                {
                    ll = co_widthc - co_curposc->x - 1; /* line left */

                    if (ll < (lc - com_bufnext))  /* extra chars */
                    {
                        co_bufferpr(com_bufnext, com_bufnext + ll, 1);
                        co_bufferpr(com_bufnext + ll + 1, --lc, nl);
                    }
                    else
                    {
                        co_bufferpr(com_bufnext, --lc, nl);
                    }
                }

                com_bufnext = lc + 1 + nl;
            }
            else
            {
                co_window_output(com_buffer[com_bufnext++]);
            }

        }
    }
    cursornotneeded = 0;
    Paint_cursor;
}

/* --- input on tool window ---------------------------------------------- */

/*--------------------------------------------------------------------
*   handle user input on a tool window: basically we do the same things as
*   the standard sun rooutine would, except that for quit we just send a
*   message to poplog, and for refresh we do a full refresh from the
*   character map instead of doing a sigwinch.  If the window is a text
*   window, we round size changes down to just fit the number of characters
*   that can fit, and at least one character.
*/
handle_toolwin_input(win_num)
int win_num;
{
    struct tool *toolp;
    char toolfd, iconic;
    struct menu * mytoolmenu = &toolmenu;

    toolp = wt_toolwp[win_num];
    toolfd = toolp->tl_windowfd;
    iconic = toolp->tl_flags & TOOL_ICONIC;

    if  (input_readevent(toolfd, &inevent) == -1)
        mishap(errno, "PWM: input readevent returned error %d\n");

    if ((inevent.ie_code == 17) && (pwmabortrequest == 1))
        poplog_proc_died = 1;
    else if ((inevent.ie_code == 4) && (pwmabortrequest == 0))
        pwmabortrequest = 1;
    else
        switch (inevent.ie_code)
        {
        case MS_LEFT:
            wmgr_open(toolfd, rootfd);
            if (iconic == WT_ICONIC)
                report_window_opened(win_num, WT_OPENED);
            break;
        case MS_MIDDLE:
            wmgr_changerect(toolfd, toolfd, &inevent, 1, 1);
            break;
        case MS_RIGHT:
            if ((inevent.ie_flags && IE_NEGEVENT) == 0) /* button down */
            {
                struct menuitem *mi;

                if (iconic == WT_ICONIC) {
                  toolmenuitem[0].mi_imagedata = "Open";
                  toolmenuitem[0].mi_data = (caddr_t)3;
                } else {
                  toolmenuitem[0].mi_imagedata = "Close";
                  toolmenuitem[0].mi_data = (caddr_t)4;
                }
  
                mi = menu_display(&mytoolmenu, &inevent, toolfd);

                if (mi != (struct menuitem *) NULL)
                    switch (mi->mi_data)
                    {
                    case 1:     /* Redisplay */
                        if ((wt_active[win_num] < WT_GRAPHW)
                                && (iconic != WT_ICONIC))
                            refresh_txtwin(wt_pixwinp[win_num],
                                            &wt_swrect[win_num],
                                            wt_scrndata[win_num],
                                            &wt_curposp[win_num]);
                        else
                            wmgr_refreshwindow(toolfd, rootfd);
                        break;
                    case 2:     /* Quit */
                        report_quit_request(win_num);
                        break;
                    case 3:     /* Open */
                        wmgr_open(toolfd, rootfd);
                        report_window_opened(win_num, WT_OPENED);
                        break;
                    case 4:     /* Close */
                        wmgr_close(toolfd, rootfd);
                        report_window_opened(win_num, WT_ICONIC);
                        break;
                    case 5:     /* Move */
                        wmgr_move(toolfd, rootfd);
                        break;
                    case 6:     /* Stretch */
                        if (iconic != WT_ICONIC)
                            safe_wmgr_stretch(win_num, toolfd, toolp);
                        break;
                    case 7:     /* Expose */
                        wmgr_top(toolfd, rootfd);
                        break;
                    case 8:     /* Hide */
                        wmgr_bottom(toolfd, rootfd);
                        break;
                    default:
#ifdef DeBug
                        misprint((mi->mi_data),
                            "PWM: strange menu result %d: is this a sun3???\n");
#endif
                        break;
                    }
            }
            break;
        }
    /* endif */
}

/*--------------------------------------------------------------------
*   see comment on above procedure
*/
safe_wmgr_stretch(win_num, toolfd, toolp)
int win_num, toolfd;
struct tool *toolp;
{
    struct rect newrect;
    struct toolsw *toolswp;
    int width, height;

    wmgr_stretch(toolfd);
}

/* --- input on 'base' sub-window ---------------------------------------- */

static short oldselectcode;

handle_bwin_input(win_num)
int win_num;
{
    short code;

    code = inevent.ie_code;

    if (inevent.ie_flags != 1)
    {
        if (code == MS_LEFT)
        {
            oldselectcode = code;
            start_selection();
        }
        else if (code == MS_MIDDLE)
        {
            oldselectcode = code;
            continue_selection();
        }
        else if (code == LOC_MOVEWHILEBUTDOWN)
        {
            if (oldselectcode == MS_LEFT) start_selection();
            else if (oldselectcode == MS_MIDDLE) continue_selection();
            else oldselectcode = 0;
        }
        else
        {
            oldselectcode = 0;
            if (code == MS_RIGHT)
                if (display_basewin_menu() != 0)
                {
                    if (selectstart.x != -1)  end_selection();
                    stuff_selection();
                }
        }
    }
    else
        oldselectcode = 0;
}

bwin_ascii_input(code)
char code;
{
    oldselectcode = 0;

    if ( code == pty_intrc ){         /* ^C: send an interrupt */
        echo_code(code);
        bw_linelen = 0;
        send_to_poplog(code);
        kill(client_pid, SIGINT);
        }
    else if ( code == 8 )
        delete_bw_input_char();
    else if ( code == 127 )
        delete_bw_input_char();
    else if ( code == 10 )         /* LF send the line */
        dispatch_input_line(0);
    else if ( code == 13 ) {        /* CR send the line */
        if (shift_escape)
            if (inevent.ie_shiftmask == 20)
            {
                send_to_poplog (13);
            }
        dispatch_input_line(0);
        }
    else if ( code == pty_startc )         /* ^Q restart output */
        ioctl(client_ofd, TIOCSTART);
    else if ( code == 18 )                /* ^R reprint input line */
        reprint_bw_input_line();
    else if ( code == pty_stopc )         /* ^S stop output */
        ioctl(client_ofd, TIOCSTOP);
    else if ( code == 21 )              /* ^U cancel line */
        cancel_bw_input_line();
    else if ( code == pty_quitc ) {        /* ^Y */
        echo_code(code);
        kill(client_pid, SIGQUIT);
        }
    else if ( code == pty_eofc ) {        /* ^Z send it now */
        if (bw_linelen == 0)        /* termin */
        {
            int real_co;

            if ((real_co = current_out) != 0) select_output_window(0);
            switch_current_in(0);

        /* The old quit code: IR
        *
        *   co_insert_char('^');
        *   co_insert_char(code + 64);
        *   co_carriage_return();
        *   send_to_poplog(26);
        */

            echo_code_and_save('b');
            echo_code_and_save('y');
            echo_code_and_save('e');
            dispatch_input_line(0);

            if (real_co != 0) select_output_window(real_co);
        }
        else
            qdispatch_input_line(0);
    }
    else
        echo_code_and_save(code);
}

qdispatch_input_line(win_num)
int win_num;
{
    switch_current_in(win_num);

    write(client_ofd, bw_linebuf, bw_linelen - 1);

    bw_linelen = 0;
}

dispatch_input_line(win_num)
int win_num;
{
    echo_code_and_save(10);
    echo_code_and_save(13);

    switch_current_in(win_num);

    write(client_ofd, bw_linebuf, bw_linelen - 1);

    bw_linelen = 0;
}

reprint_bw_input_line()
{
    int i, real_co;

    if  ((real_co = current_out) != 0) select_output_window(0);

    co_window_output(18);
    co_window_output(13);
    co_window_output(10);
    for (i = 0; i < bw_linelen; i++) co_window_output(bw_linebuf[i]);

    if  (real_co != 0) select_output_window(real_co);
}

delete_bw_input_char()
{
    char lastcode;
    int real_co, xpos;

    if  (bw_linelen != 0)
    {
        if  ((real_co = current_out) != 0) select_output_window(0);

        lastcode = bw_linebuf[--bw_linelen];
        co_delete();

        if  (lastcode == 9) /* tab */
        {
            xpos = (co_curposc->x - (co_curposc->x / 4) - 1);
            while (xpos-- > 0)
                co_delete();
        }
        else if (lastcode < 32)
            co_delete();

        if  (real_co != 0) select_output_window(real_co);
    }
}

cancel_bw_input_line()
{
    char lastcode;
    int real_co;

    if  ((real_co = current_out) != 0) select_output_window(0);

    while (bw_linelen != 0)
    {
        co_window_output(127);
        lastcode = bw_linebuf[--bw_linelen];
        if  (lastcode < 32)
            co_window_output(127);
    }

    if  (real_co != 0) select_output_window(real_co);
}

echo_code_and_save(code)
char code;
{
    int real_co;

    if  ((real_co = current_out) != 0) select_output_window(0);

    co_window_output(code);

    bw_linebuf[bw_linelen++] = code;
    if(bw_linelen > BWLBUFSIZE) qdispatch_input_line(0);

    if  (real_co != 0) select_output_window(real_co);
}

echo_code(code)
char code;
{
    int real_co;

    if  ((real_co = current_out) != 0)
    {
        select_output_window(0);
        co_window_output(code);
        select_output_window(real_co);
    }
    else
        co_window_output(code);
}


/* --- input on 'ved' sub-window ----------------------------------------- */


handle_swin_input(win_num)
int win_num;
{
    short code;

    code = inevent.ie_code;

    if   ((code >= ASCII_FIRST) && (code <= ASCII_LAST))
    {
        switch_current_in(win_num);

        if  (code < 32)
        {
            switch (code)
            {
            case 3:         /* ^C */
                send_to_poplog(code);
                kill(client_pid, SIGINT);
                break;
            case 17:        /* ^Q */
                ioctl(client_ofd, TIOCSTART);
                break;
            case 19:        /* ^S */
                ioctl(client_ofd, TIOCSTOP);
                break;
            case 25:        /* ^Y */
                kill(client_pid, SIGQUIT);
                break;
            case 27:
                if  ((shift_escape) && (inevent.ie_shiftmask == 20))
                    send_to_poplog(29);
                else
                    send_to_poplog(code);
                break;
            default:
                send_to_poplog(code);
                break;
            }
        }
        else
            send_to_poplog(code);

        if (co_winiscooked && (current_out == current_in))
            co_window_output(code);

    }
    else
        handle_nonascii_input(win_num);
}

handle_nonascii_input(win_num)
int win_num;
{
    short code, flags;
    int  xpos, ypos;

    if (wt_active[win_num] == WT_GRAPHW)
    {
        xpos = inevent.ie_locx - rubber_offset.x;
        ypos = inevent.ie_locy - rubber_offset.y;
    }
    else
    {
        xpos = pixcoord_txt_x(inevent.ie_locx - rubber_offset.x);
        ypos = pixcoord_txt_y(inevent.ie_locy - rubber_offset.y) - 1;
    }

    code  = inevent.ie_code;
    flags = inevent.ie_flags;

    if  ((code >= BUT_FIRST) && (code <= BUT_LAST))
    {
        switch_current_in(win_num);

        if  (flags == 1)
        {
            if (ci_mousedown != 0)
            {
                if ((ci_mmaction & TRK_actionmask) != 0)
                {
                    rubber_finish();
                    /* clip it */
                    if (rubber_limit.xy2.x != 0)
                        if (xpos < rubber_limit.xy1.x)
                            xpos = rubber_limit.xy1.x;
                        else if (xpos > rubber_limit.xy2.x)
                            xpos = rubber_limit.xy2.x;

                    if (rubber_limit.xy2.y != 0)
                        if (ypos < rubber_limit.xy1.y)
                            ypos = rubber_limit.xy1.y;
                        else if (ypos > rubber_limit.xy2.y)
                            ypos = rubber_limit.xy2.y;
                }

                report_mbutton_released(code + 1 - BUT_FIRST, xpos, ypos);
            }

            ci_mmaction = ci_mousedown = 0;
        }
        else
        {
            ci_mousedown = code + 1 - BUT_FIRST;

            report_mbutton_pressed(ci_mousedown, xpos, ypos);
        }
    }
    else if (ci_mousedown != 0)
    {
        if (code == LOC_MOVEWHILEBUTDOWN)
        {
            if ((ci_mmaction & TRK_trackflag) != 0)
                report_mbutton_moved(ci_mousedown, xpos, ypos);

            if ((ci_mmaction & TRK_actionmask) != 0) rubber_action();
        }
    }
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    30:  user_toolwin_input(ibits)
::    47:  user_subwin_input(ibits)
:: --125---input from poplog ------
::   127:  poplog_input()
:: --215---input on tool window ------
::   225:  handle_toolwin_input(win_num)
::   314:  safe_wmgr_stretch(win_num, toolfd, toolp)
:: --325---input on 'base' sub-window ------
::   329:  handle_bwin_input(win_num)
::   374:  bwin_ascii_input(code)
::   443:  qdispatch_input_line(win_num)
::   453:  dispatch_input_line(win_num)
::   466:  reprint_bw_input_line()
::   480:  delete_bw_input_char()
::   505:  cancel_bw_input_line()
::   523:  echo_code_and_save(code)
::   537:  echo_code(code)
:: --553---input on 'ved' sub-window ------
::   556:  handle_swin_input(win_num)
::   606:  handle_nonascii_input(win_num)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Jan 17 1989                
--- changed behaviour of ctrl-Z in base window (this should quit pwmtool)
        such that it now sends the string 'bye' instead ascii 26
 $Log:	pwinput.c,v $
 * Revision 1.4  90/06/07  17:59:41  pop
 * added SUNOS 4.1 fix from David Tock (dit@uk.ac.aberdeen.kc)
 * 
 * Revision 1.3  89/08/23  17:24:32  pop
 * modifed bwin_ascii_input so that it used pty_* instead of hard coded 
 * control charactors
 * 
 * Revision 1.2  89/08/23  15:28:36  pop
 * modified select to use BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:20:39  pop
 * Initial revision
 * 
 */
