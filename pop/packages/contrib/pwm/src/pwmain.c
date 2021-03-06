/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:           C.sun/pwm/pwmain.c
 * Purpose:        startup for sun pwm
 * Author:         Ben Rubinstein, Feb 20 1987 (see revisions)
 * $Header: /popv13.5/pop/pwm/RCS/pwmain.c,v 1.3 89/08/23 17:30:35 pop Exp $
 */

#include <pixrect/pixrect_hs.h>

/*
|       The starting point for the PWM: basically does setup and signal
|   catching - the real work is done in vedwin_select.
*/
#include "pwdec.h"
#include "pwid.h"

#ifdef DeBug
#include "pwcom.c"
#endif

extern int errno;
extern int setup_colour_tables();
int SCREENWIDTH, SCREENHEIGHT, SCREENDEPTH;

int sigchild_handler();
int sigwinch_handler();
int sigterm_catcher();
int fatalsig_catcher();

main(argc, argv)
    int argc;
    char *argv[];
{
    int i, l;
    struct toolio tio1;
    char *parent;
    Pixrect *screen, *pr_open();

    client_pid = poplog_proc_died = 0;  /* client pid must be zeroed before *
                                        * any possible call of mishap       */
    if (parent = (char *)getenv("WINDOW_PARENT")) {
        rootfd = open(parent, 0);
        if ((screen = pr_open("/dev/fb")) == NULL)
            mishap(errno, "PWM: Error (#%d) opening /dev/fb\n");
        SCREENWIDTH = screen->pr_size.x;
        SCREENHEIGHT = screen->pr_size.y;
        SCREENDEPTH = screen->pr_depth;
        (void) pr_close(screen);
    } else
        mishap(-1, "PWM: Can't translate WINDOW_PARENT\nNot running Suntools?\n");

    argc = parse_command_line(argc, argv);      /* parse command line args */

    setup_fonts();
    misc_setup();
    menu_setup();
    setup_colour_tables();
    wipe_ids_array();       /* confirm that there are no windows up yet */
    make_input_mask();      /* initalise "sw_in_mask" for all subwins */
    signal(SIGWINCH, sigwinch_handler);     /* trap window change signal */

    strncpy(buf, Version_str, (l = Version_len));
    for (i = 0; i < argc; i++)
    {
        buf[l++] = ' ';
        strcpy(buf + l, argv[i]);
        l = l + strlen(argv[i]);
    }
    buf[l] = 0;

    if ((i = new_vanilla_window(buf, "", VW_INITHEIGHT, VW_INITWIDTH,
                                &popicon, 0 - fontadv_y)) == 0)
            new_txt_window(i, VW_INITHEIGHT, VW_INITWIDTH);
    else
        mishap(-1, "PWM: Couldn't make base window\nNot running Suntools?\n");

    select_graphic_window(0);
    select_output_window(0);
    jump_cursor(0, co_heightc - 1); /* bottom of the screen */

    client_pid = fork_poplog(argv);
    frig_pty_chars();

    signal(SIGCHLD, sigchild_handler);
    signal(SIGTERM, sigterm_catcher);

    signal(SIGBUS, fatalsig_catcher);
    signal(SIGHUP, fatalsig_catcher);
    signal(SIGSEGV, fatalsig_catcher);
    signal(SIGSYS, fatalsig_catcher);
    signal(SIGSTOP, fatalsig_catcher);
    signal(SIGILL, fatalsig_catcher);
    signal(SIGQUIT, fatalsig_catcher);
    signal(SIGINT, fatalsig_catcher);

#ifdef DeBug
    printf("--- pid of poplog process is %d\n", client_pid);
#endif

    current_in = WT_FIRSTWIN;
    vedwin_select();            /* main loop to read input */

#ifdef DeBug
    printf("--- closing clientfd\n");
#endif
    kill(client_pid, SIGKILL);  /* just to be sure about it */
    close(client_ifd);
    if (client_ifd != client_ofd) close(client_ofd);
}

/*--------------------------------------------------------------------
* note window size change and damage repair signal
*       the signal is sent to the process, whenever any of it's
*       windows need repairing.  Currently this invokes
*       repainting on all windows: it would probably be faster
*       if it took the time to try and find out which ones
*       need it.
*/
sigwinch_handler()
{
    sigwinch_pending = 1;
}

sigchild_handler()
{
    poplog_proc_died = 1;

#ifdef DeBug
    printf("\n  *** signal from child ***\n");
#endif
}

sigterm_catcher()
{
#ifdef DeBug
    printf("TERM'ed (%d)!\n", poplog_proc_died);
#endif
    if (poplog_proc_died == 0)
    {
        kill(client_pid, SIGTERM);  /* pass it on */
        poplog_proc_died = 1;       /* to make sure we die */

/* it might take a long time to die: any other signal should finish us off */
        signal(SIGHUP,  sigterm_catcher);
        signal(SIGINT,  sigterm_catcher);
        signal(SIGQUIT, sigterm_catcher);
        signal(SIGILL,  sigterm_catcher);
        signal(SIGTRAP, sigterm_catcher);
        signal(SIGIOT,  sigterm_catcher);
        signal(SIGEMT,  sigterm_catcher);
        signal(SIGFPE,  sigterm_catcher);
        signal(SIGBUS,  sigterm_catcher);
        signal(SIGSEGV, sigterm_catcher);
        signal(SIGSYS,  sigterm_catcher);
        signal(SIGPIPE, sigterm_catcher);
        signal(SIGALRM, sigterm_catcher);
        signal(SIGTERM, sigterm_catcher);
        signal(SIGURG,  sigterm_catcher);
        signal(SIGSTOP, sigterm_catcher);
        signal(SIGTSTP, sigterm_catcher);
        signal(SIGCONT, sigterm_catcher);
        signal(SIGCHLD, sigterm_catcher);
        signal(SIGTTIN, sigterm_catcher);
        signal(SIGTTOU, sigterm_catcher);
        signal(SIGIO,   sigterm_catcher);
        signal(SIGXCPU, sigterm_catcher);
        signal(SIGXFSZ, sigterm_catcher);
        signal(SIGVTALRM ,  sigterm_catcher);
/*  signal(SIGPROF, sigterm_catcher);*/
        signal(SIGWINCH ,   sigterm_catcher);
    }
    else    /* second request, kill - hard - ourself and the client */
    {
        kill(client_pid, SIGKILL);
        kill(getpid(), SIGKILL);
    }
}

fatalsig_catcher(signal)
int signal;
{
#ifdef DeBug
    printf("Fatal signal %d\n", signal);
#endif
    kill(client_pid, SIGKILL);   /* commit infanticide */
    if (poplog_proc_died == 0)
    {
        poplog_proc_died = 1;       /* to make sure we die */
    }
    else    /* second request, suicide now */
    {
        kill(getpid(), SIGKILL);
    }
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    23:  main(argc, argv)
::    99:  sigchild_handler()
::   116:  sigwinch_handler()
::   121:  sigterm_catcher()
::   130:  fatalsig_catcher(signal)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Aled Morris, Nov 10 1987
    added code in main() for determining screen dimensions (i.e. added
    ioctl(FBIOGTYPE).
 $Log:	pwmain.c,v $
 * Revision 1.3  89/08/23  17:30:35  pop
 * Screen dimensions obtained by doing pr_open on /dev/fb, 
 * See Pixrect ref man page 23, Rev A 9 May 1988.
 * put frig_ptty_char back in
 * 
 * Revision 1.2  89/08/23  15:30:16  pop
 * modified select for BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:20:42  pop
 * Initial revision
 * 
 */
