/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:           C.sun/pwm/pwdec.h
 * Purpose:        Global declarations for Sun PWM
 * Author:         Ben Rubinstein, Jan  8 1987 (see revisions)
 * $Header: /popv13.5/pop/pwm/RCS/pwdec.h,v 1.4 89/08/23 17:57:32 pop Exp $
 */

#include <stdio.h>
#include <strings.h>

#include <suntool/tool_hs.h>

#include <ctype.h>

/* --- constants -------------------------------------------------------- */

#define FALSE 0
#ifndef TRUE    /* it appears one of the sun header files defines it */
#define TRUE 1
#endif

#define VW_BELL_TIME 70000
#define VW_MAXITEMS 20      /* max number of items in a menu */

#define PW_MAXFONTS 8       /* maximum number of fonts that can be loaded */

#define STDIN_FD  0
#define STDOUT_FD 1
#define STDERR_FD 2

#define MRK_LINEMODE    0
#define MRK_FULLMODE    1

#define TRK_trackflag   64
#define TRK_modeflag    32  /*  (TRK_trackflag / 2) */
#define TRK_actionmask  31  /*  (TRK_modeflag - 1)  */

#define NXTWINDOW_ID    90
#define TXTWINDOW_ID    91
#define GFXWINDOW_ID    92

/* set in pwmain.c */
extern int SCREENWIDTH, SCREENHEIGHT, SCREENDEPTH;

#define WINSTARTX       2
#define WINSTARTY       80
#define ICONLASTX       (SCREENWIDTH - 64)
#define ICONLASTY       (SCREENHEIGHT - 64)

#define PWMABORT1   4       /* ctrl-D */
#define PWMABORT2   17      /* ctrl-Q */

#define COMBUFSIZE  512     /*  size of buffer for input from poplog    */
#define OUTBUFSIZE  128     /*  size of buffer for output to poplog     */
#define REPBUFSIZE  256     /*  size of buffer for making reports in    */
#define BWLBUFSIZE  256     /*  size of buffer for input in base window */
#define ARGSTRSIZE  512     /*  size of buffer string arg in a command  */
#define COMNUMNARGS 50      /*  maximum # of numeric args in a command  */
#define COMCHARNARGS 3      /*  maximum # of character args in a command  */

/* temp for debuggging */
#define VW_INITWIDTH    80
#define VW_INITHEIGHT   24

#define VW_ESCAPE       27

#define PWM_STATUS_FAILED   -1
#define PWM_STATUS_OK       0

#define WT_NOWIN    -1
#define WT_FIRSTWIN 0       /* smallest legal index into tables */
#define WT_LASTWIN  31      /* largest legal index into tables */

#define FT_FIRSTFRAME   32      /* smallest legal id */
#define FT_LASTFRAME    64      /* largest legal id, + 1*/


#define WT_UNUSED   0   /*  possible values in "wt_active" table */
#define WT_BOOKED   1   /*                                            */
#define WT_FRAMEW   2   /*      Frame "window" (rect only)            */
#define WT_TEXTW    3   /*      Base or user text window              */
#define WT_VEDWIN   4   /*      Ved window                            */
#define WT_GRAPHW   5   /*      Graphics window                       */

#define WT_ACTIVE   WT_TEXTW    /*  if >= this, then real window....        */

/* possible values in "wt_iconic" table */
#define WT_ICONIC   TOOL_ICONIC
#define WT_OPENED   0

/* --- structure definitions -------------------------------------------- */

struct xypos {      /* used for cursor & graphics positions */
    int x;
    int y;
};

struct xypair {
    struct xypos xy1;
    struct xypos xy2;
};

struct seq_rec {
    char seq[2];
    int (*proc)();
    char cnargs;
    char nnargs;
};

struct proc_rec {       /* stupid C doesn't allow array of functions, */
    int (*proc)();      /* so use an array of these instead           */
};

struct screen_record {
    int rows, cols;
    char **text;
};


/* --- miscellaneous declarations --------------------------------------- */

char **bw_text;         /* copies of the info in the screen record for the */
int bw_widthc;          /* base window, made more accesible for use by the */
            /* selection mechanism.                            */

int PWMPID; /* process id of pwm used for unique cms name */
struct pixfont *norm_font;
int fontadv_x, fontadv_y, font_home_y;

struct icon popicon, vedicon, gfxicon, txticon;

struct tool     *toolp;
struct toolsw   *tool_swp;
struct pixwin   *subwin_pwp;

struct timeval polling_timeout; /* a timeval of 0, which makes SELECT poll*/

struct itimerval itval1, itval2;    /* used for setting the itimer */

struct inputevent inevent;  /* used for all input events */

struct xypos rubber_offset;
struct xypos rubber_fixed;
struct xypos rubber_width;
struct xypos rubber_moving;
struct xypair rubber_limit;

char buf[256], conch;       /* general use - e.g. mishap */

char report_buffer[REPBUFSIZE]; /* for making up strings to send to poplog */

int rootfd;                     /* badly got */
int client_ifd, client_ofd;    /* our lines to client process (eg poplog) */
int client_pid;                 /* PID of client process */

char bw_linebuf[BWLBUFSIZE];    /* for collecting input in base window */
int bw_linelen;                 /* next position in bw_linebuf */

char **toolargs;                /* user's command line arguments */
struct xypos winstartpos;       /* top left of first/next window */
struct xypos iconstartpos;      /* top left of first/next icon */
struct xypos icondirection;     /* which way to arrange icons from
                    the initial position */

struct xypos nxtwin_winpos;     /* preset for position of next window   */
struct xypos nxtwin_iconpos;    /* preset for position of next icon     */
char nxtwin_iconic;             /* preset for next window open/closed   */

struct xypos selectstart,       /* position on screen of start and end  */
        selectend;          /* of selected text. start is -1 if not */
                /* in process of selecting */

char current_in,                 /* indices to the windows from which last */
    current_out,                /* input came, to which output should     */
    current_graf;               /* go until further notice, and to which  */
                /* graphics should be done on             */

char selectedwin;       /* the window we reckon the mouse may be in */

int graphic_op,                 /*  operator and value to use in    */
    graphic_value;              /*      graphics operations         */

fd_set fdset;   /* set of file descriptor used by BDS4.3 style select */

/* chars for pty signals */
char pty_intrc, pty_quitc, pty_startc, pty_stopc, pty_eofc;

/* this is the input mask for all subwindows (probably) */
struct inputmask sw_in_mask;

#ifdef PWMVer2
char output_buffer[OUTBUFSIZE]; /* after reporting a new input source,  */
#endif
int output_buflen;              /* we buffer output until a handshake   */
                /* is recieved                          */

/* table of Sun raster-ops from PWM standard ones */
static char ropconvert[16] =
    { 0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30 };

/* used by the various routines which deal with colourmaps */
static unsigned char big_red[256], big_green[256], big_blue[256];



/* --- variables for current output, current graphics windows ----------- */

int co_toolfd;          /* file descriptor of current tool (outer) window */
struct tool *co_toolp;  /* pointer to the tool struct of ditto */

char **co_text;         /* array of strings for current window */

struct pixwin *co_pixwinp;  /* pointer to pixwin for current output window */
struct pixwin *cg_pixwinp;  /* pointer to pixwin for current graphix window */
struct pixrect *cg_pixrectp;    /* pointer to pixrect for c.g.w, if
                    frame window */

struct rect co_rect;        /* rect for current output window */

int co_widthc;            /* width of current output window, in chars */
int co_heightc;           /* height of current output window, in chars */
struct xypos *co_curposc; /* cursor pos'n for c.o. window, in chars */

int co_widthp;            /* width of current output window, in pixels */
int co_heightp;           /* height of current output window, in pixels */
struct xypos *co_curposp; /* cursor pos'n for c.o. window, in pixels */

int co_botlinetop;      /* the y-coord of the top pixel in the bottom line
             *  of text in the current output window (pixels);
             */

int co_botlineheight;   /*  pixels from co_botlinetop to bottom of window */

/* --- flags ------------------------------------------------------------ */

char cg_winisframe;     /* true iff current graphics window is in   *
             * memory only (== "frame-store")           */

char ci_mousedown;      /* mouse is down in current input window        *
             * - not strictly flag, may be 0 or # of button */

char ci_mmaction;       /* report/track mouse movements */

char co_ceolneeded;     /* iff 1, then buffer replace should (simulate) *
             *  clearing to end of line first               */

char co_winiswrap;     /* 1 iff current output window wants long lines  *
            * to wrap at right margin (0 else) (this is     *
            * true of base window and user text windows)    *
            * this flag also controls whether a linefeed is *
            * interpreted as a cr-lf or just lf             */

char grafalarmflag;     /* set true by signal catcher for virtual alarm: *
             *  designed to stop grafraster locking up when  *
             *  it can't read enough bytes.                  */

char term_grafmode;     /* 0/128, added to chars before printing */

char term_insrtmode;    /* 0/non-zero = static/insert */

char one_input;         /*  if true, then send next input on any window      *
             *  as single 'special input event', without         *
             *  altering 'current_in' value or sending a message *
             *  about current in.                                */

char
    poplog_connected,   /* there is a poplog alive somewhere at the *
             * client end of the line                   */
    poplog_listening,   /* the poplog process is the one in force   */
    base_cooked,        /* pretend to be cooked tty in base window  */
    ved_cooked,         /* pretend to be cooked tty in ved windows  */
    co_winiscooked;     /* pretend to be cooked tty in current text window */

char poplog_proc_died;   /* set by catcher of SIGCHLD */

char pwmabortrequest;    /* normally zero, 1 if ^D last input on base tool  *
              * window: if 1 when ^Q input on b.t.w.,  exit     */

char shift_escape;       /* if true, then send 29 instead of 27 when ctrl & *
              *  shift are down                                 */

char sigwinch_pending;   /* set true to by SIGWINCH catcher */


/* --- stuff for parsing input from poplog process ---------------------- */

char com_buffer[COMBUFSIZE]; /* string in which input from poplog   */
                 /* is buffered                         */

char com_char;      /* result of polling, possibly set elsewhere also */

char com_header,     /* the first, second and third chars after the */
     com_code1,     /*      escape in an escape sequence          */
     com_code2;

/*unsigned*/
    int
    com_buflen,    /* number of characters currently in buffer*/

    com_bufnext,   /* next unused character in buffer*/

    com_seq_len,   /* number of characters examined so far in command sequence */
    com_seq_add,   /* 'address' in buffer of escape that started command sequence */

    com_bufind,    /* index for buffer - used in reading numbers */

    com_lastn, com_firstn;  /* numeric args from command sequence */

char in_escape;      /* 1 if in middle of escape sequence, 0 otherwise*/
char stringcom;      /* 1 iff current sequence ends with string term */

char com_stringarg[ARGSTRSIZE];    /* string part of an escape sequence */
int com_stringlen;          /* length of escape sequence string */

char com_ecargs;              /* number of char. args expected in command */
char com_charargs[COMCHARNARGS];

char com_enargs;              /* number of numeric args expected in command */
char com_nargs;               /* number of numeric args found in command */
int com_numargs[COMNUMNARGS]; /* the numeric args found in command: up to 50
                just because 'graf_polyline' may need that
                many */

char com_termin;         /* type of terminator: one of :             */
#define VW_NOTERM       0   /* we haven't worked it out yet         */

#define NUMS    1   /* get a number, then 't': call it with the number */
#define WMGR    3   /* sequence is 4 characters long, call the func (now) with co fd, rootfd */
#define DOIT    4   /* the sequence is 4 characters long: do it now */
#define CHR5    5   /* sequence is 5 characters long - next character is 't' */
#define ESCB    6   /* sequence ends with escape, backslash */
#define ESCC    7   /* sequence ends with escape, backslash: com_code2 is part of string  */

/* --- procedures ------------------------------------------------------- */


struct pixrect *get_gfx_surface_pr();
    /* takes a window or page index and returns pointer to pixrect */

int (* co_charpr)();     /* function which takes a printable character and
                outputs it on the current window. */

int co_insert_char(),           /* may be assigned to "co_charpr" */
    co_replace_char();

int (* co_bufferpr)();     /* function which takes several printable chars
                and outputs them on the current window. */

int co_buffer_insert(),           /* may be assigned to "co_bufferpr" */
    co_buffer_replace();

int (*com_read_proc)();     /* function which reads a code in the command
                sequence */

int (*com_doit_proc)();     /* function to call when command sequence
                has been read in */

int com_num_read(),         /* may be assigned to "com_read_proc" */
    com_char_read(),
    com_numterm_read(),
    com_string_read();

int /* may be assigned to "com_doit_proc" */

    cursor_up(),                      /* v200 commands */
    cursor_down(),
    cursor_right(),
    cursor_left(),
    set_graphic_mode(),
    reset_graphic_mode(),
    home_cursor(),
    insert_line(),
    delete_line(),
    delete_character(),
    send_terminal_id(),
    set_insert_mode(),
    reset_insert_mode(),
    clear_line(),
    clear_page(),
    clear_endof_line(),
    clear_endof_page(),

    ansi_cursor_address(),

    get_comms_width(),
    set_comms_width(),


    ved_number_command(),    /* ved specials - not implemented yet */
    ved_scroll_left(),
    ved_scroll_right(),

    grph_copyraster(),           /* graphics commands */
    grph_getmapentry(),
    grph_killcms(),
    grph_killfont(),
    grph_kill_page(),
    grph_loadfont(),
    grph_newcms(),
    grph_new_page(),
    grph_pixel_set(),
    grph_pixel_test(),
    grph_polyline(),
    grph_polyfill(),
    grph_rasterread(),
    grph_rasterdump(),
    grph_readrasfile(),
    grph_setcg_font(),
    grph_setcg_paint(),
    grph_setcg_rop(),
    grph_setcg_surface(),
    grph_setcw_cms(),
    grph_setmapentry(),
    grph_text(),
    grph_wipearea(),
    grph_writerasfile(),

    highlight_text(),
    kill_cursor(),
    kill_menu(),
    kill_window(),
    make_new_window(),
    define_new_menu(),
    display_new_menu(),
    display_def_menu(),
    new_cursor_file(),
    new_cursor_image(),
    display_prompt(),
    advise_elevator_pos(),
    advise_win_location(),
    advise_icon_location(),
    advise_win_title(),
    advise_icon_title(),
    advise_internal_size(),
    advise_external_size(),
    advise_open_or_closed(),
    advise_pwm_details(),
    rubber_setup(),
    set_text_selection(),
    advise_text_selection(),
    set_text_window(),
    set_external_size(),
    set_icon_file(),
    set_icon_image(),
    set_icon_location(),
    set_icon_title(),
    set_input_source(),
    set_internal_size(),
    set_elevator_pos(),
    set_elevator_size(),
    set_win_cursor(),
    set_win_location(),
    set_win_title(),
    tidy_windows(),
    various_command(),

    winmgr_commands()
;


int print_input_event(),            /* handle input on subwindow        */
    wipe_ids_array(),               /* reset tables etc                 */
    txtwin_sigwinch(),              /* handle sigwinch on txt subwindows */
    gfxwin_sigwinch(),              /* handle sigwinch on gfx subwindows */
    make_new_pop_win(),             /* make new window, and install it  */
    handle_control_input(),         /* deal with commands */
    txtcoord_pix_x(),
    txtcoord_pix_y(),
    pixcoord_txt_x(),
    pixcoord_txt_y(),
    identfn(),
    write_line();

char *getenv();

struct screen_record *make_screen_record();
struct screen_record *resize_screen_rec();

/* --- macros ----------------------------------------------------------- */

char cursoronscreen, cursornotneeded;

/*
*   send to poplog to indicate an error state, if we know it's listening for
*   a formatted report
*/
#define Report_null send_to_poplog(0)

/* macro to repaint the character under the cursor in current window, to remove cursor*/
#define Remove_cursor if (cursoronscreen) { pw_char(co_pixwinp, co_curposp->x, co_curposp->y, PIX_SRC, norm_font, (co_text[co_curposc->y][co_curposc->x])&0x7f); cursoronscreen = 0; }

/* macro to paint the cursor at the current cursor pos in current window */
#define Paint_cursor if (!cursornotneeded) { pw_char(co_pixwinp, co_curposp->x, co_curposp->y, PIX_NOT(PIX_SRC), norm_font, (co_text[co_curposc->y][co_curposc->x])&0x7f); cursoronscreen = 1; }

/* 1 unless arg is negative */
#define IsPositive(n) ((n < 0) ? 0 : 1)

/* --- tables ----------------------------------------------------------- */

/* these are the tables which vedwin_select uses */

struct screen_record
        *wt_scrndata[WT_LASTWIN + 1];       /* array of strings holding text on screen */
struct tool
        *wt_toolwp[WT_LASTWIN + 1];    /* pointers to the tool windows */
struct toolsw
        *wt_toolswp[WT_LASTWIN + 1];   /* pointers to the tool sub-windows */
struct pixwin
        *wt_pixwinp[WT_LASTWIN + 1];       /* pointers to pixwins for the tool sub-windows */
struct xypos wt_curposp[WT_LASTWIN + 1];   /* position of text cursor, in pixels */
struct xypos wt_curposc[WT_LASTWIN + 1];   /* position of text cursor, in chars */
struct rect wt_swrect[WT_LASTWIN + 1];     /* rectangles for the sub-windows */
int     wt_swfd[WT_LASTWIN + 1],       /* the subwindow file descriptors */
        wt_wimask[WT_LASTWIN + 1],     /* input mask for the tool windows */
        wt_swimask[WT_LASTWIN + 1];    /* input mask for the tool sub-windows */
char    wt_iconic[WT_LASTWIN + 1],     /* booleans for each window */
        wt_active[FT_LASTFRAME],       /* the id numbers */
        wt_colmap[WT_LASTWIN + 1],     /* index to colour map */
        wt_cursor[WT_LASTWIN + 1],     /* current cursor for win */
        wt_flags[WT_LASTWIN  + 1];     /*  128 - graphics mode for txt win *
                      *   64 - insert mode for ditto     *
                        */
#define TFLG_GRAFMODE   128     /* <- must be this: or'ed directly with chars */
#define TFLG_INSERTMODE  64

/* pointers to "frame store" pixrects */
struct pixrect *gfx_frames[FT_LASTFRAME - FT_FIRSTFRAME + 1];

/* pointers to cursor objects */
struct cursor *win_cursors[3];

/*int *gfx_mapsizes;*/


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ---14---constants ------
:: ---89---structure definitions ------
:: --118---miscellaneous declarations ------
:: --213---variables for current output, current graphics windows ------
:: --241---flags ------
:: --292---stuff for parsing input from poplog process ------
:: --341---procedures ------
:: --482---macros ------
:: --501---tables ------
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Aled Morris, Nov 10 1987
    made SCREENWIDTH and SCREENHEIGHT variables that are set in main(),
    as opposed to hard wiring the screen dimensions at compile time!
--- John Williams, Jun  5 1987 - replaced definitions of GFXWINDOWID and
                                    TXTWINDOWID that had been removed
--- John Williams, May 29 1987 - increased max number of items in a menu
$Log:	pwdec.h,v $
 * Revision 1.4  89/08/23  17:57:32  pop
 * added back sw_in_mask which was accidentally removed
 * 
 * Revision 1.3  89/08/23  16:29:04  pop
 * added SCREENDEPTH and PWMID
 * addef mask &-x7f to repaint and pain macros for use with gp1 buffer
 * 
 * Revision 1.2  89/08/23  15:34:17  pop
 * modifed to use BSD4.3 fd_set and increased size of window table
 * 
 * Revision 1.1  89/08/23  13:20:09  pop
 * Initial revision
 * 
*/
