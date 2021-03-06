/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:		$usepop/master/C.sun/pwm/pwpty.c
 * Purpose:     open a pty for communication between the PWM and its client
 * Author:		Ben Rubinstein, Jan  8 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwpty.c,v 1.1 89/08/23 13:20:59 pop Exp $
 */

/*
|  Code to open a pseudo-tty and fork a process running the argument
|   command at the slave end of it.
*/

#include "pwdec.h"

#include <sgtty.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <strings.h>

extern char **environ;  /* for set_term_name, below */

char *master = "/dev/ptypX",
    *slave = "/dev/ttypX";


fork_poplog(argv)
char **argv;
{
    int yopipe, forked_pid, slave_fdi, slave_fdo, pipefd[2];
    struct sgttyb termparams;

    if  ((slave_fdi = open_pty()) != -1)
    {
        if (strcmp(argv[0], "PIPE") == 0)
        {
            yopipe = 1;
            argv[0] = "pop11";
        }
        else
        {
            yopipe = 0;
        }

#ifdef DeBug
        printf(">>> pipe status: %d\n", yopipe);
#endif

        if ((yopipe == 1) && (pipe(pipefd) == 0))
        {
            client_ifd = pipefd[0];
            client_ifd = client_ofd;
            slave_fdo = pipefd[1];
#ifdef DeBug
            printf("=== pipe call succeeded\n");
#endif
        }
        else
        {
            client_ifd = client_ofd;
            slave_fdo = slave_fdi;
#ifdef DeBug
            if (yopipe == 1) printf("=== pipe call failed\n");
#endif
        }

        set_term_name();        /* setenv TERM "pwmsun" */


        forked_pid = fork();

        if  (forked_pid == 0)
        {           /* this is the forked process */

            signal(SIGHUP, SIG_DFL);
            signal(SIGINT, SIG_DFL);
            signal(SIGQUIT, SIG_DFL);
            signal(SIGTERM, SIG_DFL);
            signal(SIGTSTP, SIG_IGN);
            signal(SIGCHLD, SIG_DFL);

            dup2(slave_fdi, 0);     /* switching to the pseudo tty */
            dup2(slave_fdo, 1);
            dup2(slave_fdo, 2);

            execvp(argv[0], argv); /* go for it */

			/* this should never get executed but does for certain
			*	kinds of child failure
			*/
            perror(argv[0]);
            mishap(-1, "PWM: child failed, see above\n");
        }
        else if (forked_pid < 0)
		{
            mishap(-1, "PWM: unable to fork child\n");
        }
		else
        {           /* this is the PWM process */
#ifdef DeBug
            printf("--- pty open, with fds: MI-%d, MO-%d (%s), S-%d\n",
                                client_ifd, client_ofd, master, slave_fdi);
#else
/*          close(slave_fdi);*/ /* can't do this, else don't get any last
                                * thoughts when child dies - and furthermore,
                                * we hang while we're waiting for them.
                                */
            close(0);
            close(1);
#endif
            return(forked_pid);
        }
    }
    else
        mishap(-1, "PWM: unable to open a pty\n");
}

/*--------------------------------------------------------------------
*   nasty hack to set the environment variable "TERM" to "pwmsun".
*       only called once (above), and could be inline, but modularity...
*/
set_term_name()
{
    int i;
    char *s, *t;

    t = getenv("TERM");                 /* get arg part of string */
    s = (char *)(t - 5);                /* get address of start of string */
    for(i = 0; s != environ[i]; i++) {};    /* find it in the array */
    environ[i] = "TERM=pwm";                /* replace it in the array */
}


open_pty()
{
    int lastchar, slavefd;

    for (lastchar = '0'; lastchar <= 'f'; lastchar++)
    {
        if (lastchar == '9' + 1) lastchar = 'a';    /* jump for hex digits */

        master[9] = lastchar;
        slave[9] = lastchar;

        if ((client_ofd = test_accessible(master)) >= 0)
        {
            if  ((slavefd = test_accessible(slave)) >= 0)
                return(slavefd);
            else
                close(client_ofd);
        }
    }
    return(-1);
}

test_accessible(path)
char *path;
{
    int fd;
    if  (access(path, 6) == 0)
    {
        fd = open(path, O_RDWR);
        return(fd);
    }
    else
        return(-1);
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    25:  fork_poplog(argv)
::   112:  set_term_name()
::   124:  open_pty()
::   146:  test_accessible(path)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwpty.c,v $
 * Revision 1.1  89/08/23  13:20:59  pop
 * Initial revision
 * 
*/
