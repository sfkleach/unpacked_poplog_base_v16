/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:           $usepop/master/C.sun/pwm/pwcomseq.h
 * Purpose:        tables for parsing command sequences
 * Author:         Ben Rubinstein, Feb 20 1987
 * $Header: /popv13.5/pop/pwm/RCS/pwcomseq.h,v 1.2 89/08/23 16:20:36 pop Exp $
 */

/*
*   this string is of the 2nd characters of the legit 2-char escape sequences
*   (all of which are v200): if you have escape, followed by one
*   of these chars, then you have reached the end of a v200 command sequence
*   and should do it.
*/
#define V2exechars "ABCDFGHLMOZijtvxy"
#define V2exelen 17

struct proc_rec v2exeprocs[V2exelen] =
{
    {   cursor_up           },  /* A */
    {   cursor_down         },  /* B */
    {   cursor_right        },  /* C */
    {   cursor_left         },  /* D */
    {   set_graphic_mode    },  /* F */
    {   reset_graphic_mode  },  /* G */
    {   home_cursor         },  /* H */
    {   insert_line         },  /* L */
    {   delete_line         },  /* M */
    {   delete_character    },  /* O */ /* !ST */
    {   send_terminal_id    },  /* Z */ /* !ST */
    {   set_insert_mode     },  /* i */ /* !ST */
    {   reset_insert_mode   },  /* j */ /* !ST */
    {   clear_line          },  /* t */ /* ST=l */
    {   clear_page          },  /* v */ /* ST=E */
    {   clear_endof_line    },  /* x */ /* ST=K */
    {   clear_endof_page    },  /* y */ /* ST=J */
};


/*
*   this string is of the 2nd characters of the 2-char v200 sequences which
*   are not supported: they will be ignored, but must be spotted, in case
*   any one tries to send them, so that they won't be printed out.
*/
#define V2ignore "-123456789;:=>IJKNSWX\\abcdefghklmnoqrsuwz"
#define V2ignlen 41

/*
*   this string is of the second character of escape sequences at least
*   four characters long.  If you have escape followed by one of these
*   chars, keep going at least until you have got two more.
*
*   except for "Y" (which is v200 cursor address) and "[" (which is ANSI
*   cursor address) the procedure associated with the sequence is in the
*   table below
*/
#define Fourc_second "}Y[{"
#define Fourc_seclen 4

#define COMnumdelim    ';'
#define COMpwmnumterm  't'
#define COMansixyterm  'H'
#define COMstrterm     '\\'


struct seq_rec com_table[] =
{
    {   "AE",       advise_elevator_pos,        1,  0},
    {   "AI",       advise_open_or_closed,      1,  0},
    {   "Al",       advise_icon_location,       1,  0},
    {   "AL",       advise_win_location,        1,  0},
    {   "AP",       advise_pwm_details,         1,  0},
    {   "As",       advise_internal_size,       1,  0},
    {   "AS",       advise_external_size,       1,  0},
    {   "Ah",       advise_text_selection,      0,  0},
    {   "AT",       advise_win_title,           1,  0},
    {   "At",       advise_icon_title,          1,  0},
    {   "Ci",       new_cursor_image,           3,  5},
    {   "Fc",       set_win_cursor,             2,  0},
    {   "FE",       set_elevator_pos,           1,  2},
    {   "Fe",       set_elevator_size,          1,  2},
    {   "FI",       set_icon_image,             3,  3},
    {   "Fl",       set_icon_location,          1,  2},
    {   "FL",       set_win_location,           1,  2},
    {   "Fs",       set_internal_size,          1,  2},
    {   "FS",       set_external_size,          1,  2},
    {   "GC",       grph_copyraster,            3,  6},
    {   "GD",       grph_rasterdump,            2,  5},
    {   "GL",       grph_polyline,              0,  COMNUMNARGS},
    {   "GF",       grph_polyfill,              0,  COMNUMNARGS},
    {   "Gm",       grph_getmapentry,           0,  1},
    {   "GM",       grph_setmapentry,           0,  4},
    {   "GP",       grph_pixel_set,             0,  3},
    {   "Gp",       grph_pixel_test,            0,  2},
    {   "GR",       grph_rasterread,            0,  4},
    {   "GW",       grph_wipearea,              0,  4},
    {   "KC",       grph_killcms,               1,  0},
    {   "Kc",       kill_cursor,                1,  0},
    {   "Kf",       grph_killfont,              1,  0},
    {   "Km",       kill_menu,                  1,  0},
    {   "Kw",       kill_window,                1,  0},
    {   "Ks",       grph_kill_page,             1,  0},
    {   "Ns",       grph_new_page,              0,  2},
    {   "NC",       grph_newcms,                0,  1},
    {   "SC",       grph_setcw_cms,             1,  0},
    {   "SF",       grph_setcg_font,            1,  0},
    {   "SG",       grph_setcg_surface,         1,  0},
    {   "SI",       set_input_source,           1,  0},
    {   "SP",       grph_setcg_paint,           0,  1},
    {   "SR",       grph_setcg_rop,             1,  0},
    {   "ST",       set_text_window,            1,  0},
    {   "TA",       rubber_setup,               1,  COMNUMNARGS},
    {   "TB",       rubber_setup,               2,  COMNUMNARGS},
    {   "TH",       highlight_text,             2,  4},
    {   "TS",       set_text_selection,         1,  4},
    {   "Um",       display_def_menu,           2,  2},
    {   "VC",       various_command,            1,  0},
    {   "Vn",       ved_number_command,         0,  1},
    {   "W",        winmgr_commands,            1,  0},
    {   "Zw",       get_comms_width,            2,  0},
    {   "ZW",       set_comms_width,            0,  1},
#define Cocb_len 54     /* ocb = Open Curly Bracket = '{' */
    {   "Cf",       new_cursor_file,            0,  0},
    {   "Fi",       set_icon_file,              1,  0},
    {   "Ft",       set_icon_title,             1,  0},
    {   "FT",       set_win_title,              1,  0},
    {   "Gr",       grph_readrasfile,           0,  6},
    {   "GT",       grph_text,                  0,  2},
    {   "Gw",       grph_writerasfile,          0,  4},
    {   "Nf",       grph_loadfont,              0,  0},
    {   "Nm",       define_new_menu,            0,  0},
    {   "Um",       display_new_menu,           1,  2},
    {   "Nw",       make_new_window,            2,  2},
    {   "Sw",       tidy_windows,               0,  0},
    {   "Up",       display_prompt,             0,  1},
    {   "Vl",       ved_scroll_left,            0,  2},
    {   "Vr",       ved_scroll_right,           0,  2},
#define Cccb_len 15      /* ccb = Close Curly Bracket = '}' */
};
/*
$Log:	pwcomseq.h,v $
 * Revision 1.2  89/08/23  16:20:36  pop
 * added sequence for grph_polyfill
 * 
 * Revision 1.1  89/08/23  13:20:05  pop
 * Initial revision
 * 
*/
