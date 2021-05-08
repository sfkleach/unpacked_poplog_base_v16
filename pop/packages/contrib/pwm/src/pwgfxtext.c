/* --- Copyright University of Sussex 1989.  All rights reserved. ---------
 * File:        C.sun/pwm/pwgfxtext.c
 * Purpose:     graphics text and fonts
 * Author:      Ben Rubinstein, Feb 20 1987 (see revisions)
 * $Header: /tmp_mnt/poplog/pop/pwm/RCS/pwgfxtext.c,v 1.3 90/06/07 17:55:25 pop Exp $
 */

#include "pwdec.h"
#include "pwrepseq.h"

/* To get th Sussex pwm behaviour with gfx text uncomment the line below */
/* #define SUSSEX_PWM */

/* IR 23/2/89: SFR 4185
 *
 *	* colour-sun bug: pw_text screws up on pixels of    *
 *	* depth>1; so use pw_ttext on gfx windows, and don't *
 *	** use >2 colours on txt windows.                    *
 * #define CSUN_TXT_BUG
 */

static struct pixfont *gfx_fonts[PW_MAXFONTS - 1];

char            cg_fontid;      /* id-number of current font, + 32 */
struct pixfont *cg_pixfontp;    /* pointer to current gfx font */

/*--------------------------------------------------------------------
*   called when pwm is starting up, to load default font,
*       initialise table and set up variables relating to font size
*/
setup_fonts()
{
	register int i;

	gfx_fonts[0] = cg_pixfontp = norm_font = pw_pfsysopen();
	cg_fontid = ' ';

	fontadv_x = norm_font->pf_defaultsize.x;
	fontadv_y = norm_font->pf_defaultsize.y;
	font_home_y = ((norm_font->pf_char)['A']).pc_home.y;

	for (i = 1; i < PW_MAXFONTS; i++) gfx_fonts[i] = (struct pixfont *)NULL;
}


grph_loadfont()
{
	register int i;
	struct pixfont *f;

	for (i = 1; i < PW_MAXFONTS; i++)
		if (gfx_fonts[i] == (struct pixfont *)NULL) break;

	if (i < PW_MAXFONTS)
	{
		if ((f = pf_open(com_stringarg)) == NULL)
		{
			fprintf(stderr, "PWM: couldn't load font %s\n", com_stringarg);
			Report_null;
		}
		else
		{
			gfx_fonts[i] = f;
			sprintf(report_buffer, REPnewfont, i,
						f->pf_defaultsize.x,
						f->pf_defaultsize.y,
						-(f->pf_char['A']).pc_home.y);
			send_report_to_poplog(strlen(report_buffer));
		}
	}
	else
	{
		fprintf(stderr,
			"PWM: can't load font %s, no room at table\n",
			com_stringarg);
		Report_null;
	}
}

grph_killfont()
{
	register int i;
	struct pixfont *f;

	if (((i = com_charargs[0] - 32) < 0) || (i >= PW_MAXFONTS))
		fprintf(stderr, "PWM: can't kill font %d, not valid id\n", i);
	else if (i == 0)
		fprintf(stderr, "PWM: won't kill font #0\n");
	else
		if ((f = gfx_fonts[i]) == (struct pixfont *)NULL)
			fprintf(stderr, "PWM: can't kill font %d, no such font\n", i);
		else
		{
			if (f == cg_pixfontp) {cg_pixfontp = norm_font; cg_fontid = ' ';}
			pf_close(f);
			gfx_fonts[i] = (struct pixfont *)NULL;
		}
}

grph_setcg_font()
{
	register int i;

	if (((i = com_charargs[0] - 32) < 0) || (i >= PW_MAXFONTS))
		fprintf(stderr, "PWM: can't set font %d, not valid id\n", i);
	else
	{
		if (gfx_fonts[i] == (struct pixfont *)NULL)
			fprintf(stderr, "PWM: can't set font %d, no such font\n", i);
		else
		{
			cg_pixfontp = gfx_fonts[i];
			cg_fontid = com_charargs[0];
		}
	}
}

/*--------------------------------------------------------------------
*   print the arg text in the current graphix window, at the arg
*   position (in pixels);  All characters are assumed to be printable,
*   and no interpretation of control chars etc is done.
*/
grph_text()
{
#ifdef SUSSEX_PWM
    if (cg_winisframe)
        if (cg_pixrectp->pr_depth != 1)   /* frig for sun's bug */
            pr_ttext(cg_pixrectp, com_numargs[0], com_numargs[1],
                     graphic_op | PIX_COLOR(graphic_value), cg_pixfontp,
                     com_stringarg);
         else
             pr_text(cg_pixrectp, com_numargs[0], com_numargs[1],
                     graphic_op | PIX_COLOR(graphic_value), cg_pixfontp,
                     com_stringarg);
     else
        if (cg_pixwinp->pw_prretained->pr_depth != 1)   /* frig for sun's bug */
            pw_ttext(cg_pixwinp, com_numargs[0], com_numargs[1],
                     graphic_op | PIX_COLOR(graphic_value), cg_pixfontp,
                     com_stringarg);
         else
             pw_text(cg_pixwinp, com_numargs[0], com_numargs[1],
                     graphic_op | PIX_COLOR(graphic_value), cg_pixfontp,
                     com_stringarg);
#else
    if (cg_winisframe)
        pr_ttext(cg_pixrectp, com_numargs[0], com_numargs[1],
                        graphic_op | PIX_COLOR(graphic_value),
                        cg_pixfontp, com_stringarg);
    else
        pw_ttext(cg_pixwinp, com_numargs[0], com_numargs[1],
                        graphic_op | PIX_COLOR(graphic_value),
                        cg_pixfontp, com_stringarg);
#endif
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    24:  setup_fonts()
::    39:  grph_loadfont()
::    73:  grph_killfont()
::    93:  grph_setcg_font()
::   116:  grph_text()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Feb 23 1989 - Installed fixes according to SFR 4185
--- John Williams, Aug 17 1988 - Changed PIX_COLOUR to PIX_COLOR
--- Ian Rogers, Jun  7 1988 - Installed fixes according to SFR 4214
$Log:	pwgfxtext.c,v $
 * Revision 1.3  90/06/07  17:55:25  pop
 * added compile time option to give Sussex pwm behaviour
 * 
 * Revision 1.2  89/08/23  16:45:03  pop
 * modified grph_text to write on frames as well as windows and allways
 * use transparent text (p[rw]_ttext).
 * 
 * Revision 1.1  89/08/23  13:20:19  pop
 * Initial revision
 * 
 */
