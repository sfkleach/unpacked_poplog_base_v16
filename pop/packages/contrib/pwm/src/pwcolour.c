/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 * File:        $usepop/master/C.sun/pwm/pwcolour.c
 * Purpose:     additional graphics routines for manipulating colour maps
 * Author:		Ben Rubinstein, Feb 20 1987
 * $Header: /tmp_mnt/poplog/pop/pwm/RCS/pwcolour.c,v 1.4 89/10/19 19:30:29 pop Exp $
 */

#include "pwdec.h"
#include "pwrepseq.h"

#ifndef CMS_NAMESIZE	/* Sun leave this out of the header on mono suns! */
#define CMS_NAMESIZE 20
#endif


/*--------------------------------------------------------------------
*	the entry for some map number indicates the number of users for that
*	map; if it is negative that number can be re-used; if it is 0 then
*	a map has been created with that number, but is not currently assigned
*	to any window
*/
int gfx_mapusers[WT_LASTWIN + 1];

/*gfx_mapsizes is in pwdec.h so it can be used by write-raster-file routine*/

/*--------------------------------------------------------------------
*  a colour-map segment, while alive, has its size stored here.
*/
int gfx_mapsizes[WT_LASTWIN + 1];

/*--------------------------------------------------------------------
*	names for map segments
*/
char *gfx_mapnames[WT_LASTWIN + 1];

/*--------------------------------------------------------------------
*	if a map has been created and assigned to some window, and is not
*	currently assigned to any window but has not been killed, its contents
*	(i.e. the details of each entry) are stored here in case the map gets
*	assigned to another window.
*	They are stored as consecutive strings, in the order rgb.  e.g. a map
*	with four entries would have a string of the form  "RRRRGGGGBBBB".
*/
unsigned char *gfx_mapentries[WT_LASTWIN + 1];

/*-------------------------------------------------------------------
* initialise gfxmapsizes and gfx_mapusers
*/

setup_colour_tables()
{
int i;
	for(i=WT_FIRSTWIN;i<WT_LASTWIN;i++){
		gfx_mapusers[i] = -1;
		gfx_mapsizes[i] = 0;
	}
}
/*--------------------------------------------------------------------
*	Make a new colour-map segment.  This mainly involves reserving places in
*	tables, etc.
*/
grph_newcms()
{
    int index;
	char *name;

	/* find a spare number for the newmap */
	for (index = 0; gfx_mapusers[index] != -1; index++) {};

	name = (char *) calloc(CMS_NAMESIZE, sizeof(char));
	sprintf(name, "pwmgfxwinmap%dx%d", PWMPID, index);

	gfx_mapnames[index] = name;
	gfx_mapsizes[index] = com_numargs[0];
	gfx_mapusers[index] = 0;
	gfx_mapentries[index] = NULL;

	/* and report that it has been made */
	sprintf(report_buffer, REPstatus, index + 32);
	send_report_to_poplog(6);
}

/*--------------------------------------------------------------------
*	free up memory, and free entries in tables.  (We have to check whether
*	there is a saved copy of the map, just for the case where a map is made
*	and killed without ever being used - all other cases there definitely will
*	be.)
*/
grph_killcms()
{
	register int cmsid;

	if (((cmsid = com_charargs[0] - 32) < 0) || (cmsid >= WT_LASTWIN))
		misprint(cmsid, "PWM: can't kill map-segment %d, no such segment\n");
	else if (gfx_mapusers[cmsid] > 0)
		misprint(cmsid, "PWM: won't kill map-segment %d, still in use\n");
	else
	{
		gfx_mapsizes[cmsid] = 0;
		gfx_mapusers[cmsid] = -1;
		free(gfx_mapnames[cmsid]);

		if (gfx_mapentries[cmsid] != (unsigned char *)NULL)
			free(gfx_mapentries[cmsid]);
	}
}

/*--------------------------------------------------------------------
*	not availiable directly to the user: this may be called by
*	really_kill__window or grph_setcw_cms (below) to save the details of
*	any window's current map
*/
grph_unsetmap(window)
int window;
{
/*	unsigned char red[256], green[256], blue[256];*/
	int size, i, off2, index;
	unsigned char *savestring;


	/* first find out what map is being used now */
	index = wt_colmap[window];

	if (index >= 0)
	{
		gfx_mapusers[index] = gfx_mapusers[index] - 1;

		if (gfx_mapusers[index] == 0)	/* then we need to save the entries */
		{
			size = gfx_mapsizes[index];
			off2 = size * 2;
			pw_getcolormap(wt_pixwinp[window], 0, size,
											big_red, big_green, big_blue);

			savestring = (unsigned char *) calloc(size * 3, sizeof(char));

			for (i = 0; i < size; i++)
			{
				savestring[i] = big_red[i];
				savestring[i + size] = big_green[i];
				savestring[i + off2] = big_blue[i];
			}
			gfx_mapentries[index] = savestring;
		}
	}
}

grph_setcw_cms()
{
/*	unsigned char red[256], green[256], blue[256];*/
    int size, index, i, other_win;
    struct rect swrect;

	/* make sure this is a plausible cms id */
	index = com_charargs[0] - 32;
	if ((index < 0) || (index >= WT_LASTWIN))
	{
		misprint(index, "PWM: bad cms id %d, can't set it.\n");
		return(0);
	}

    if (cg_winisframe) return;

	/* first check off the map being used now */
	grph_unsetmap(current_graf);

	/* now get the size of the new map */
	size = gfx_mapsizes[index];

	/* find another window using this map */
	for (other_win = WT_FIRSTWIN; other_win <= WT_LASTWIN; other_win++)
		if (wt_active[other_win] >= WT_ACTIVE)
			if (wt_colmap[other_win] == index) break;

	if (other_win <= WT_LASTWIN)
	{
#ifdef DeBug
	printf("gsmD: map #%d also used by window #%d\n", index, other_win);
#endif
		pw_getcolormap(wt_pixwinp[other_win], 0, size,
											big_red, big_green, big_blue);
		pw_setcmsname(cg_pixwinp, gfx_mapnames[index]);
		pw_putcolormap(cg_pixwinp, 0, size, big_red, big_green, big_blue);
	}
	else if (gfx_mapentries[index] != (unsigned char *)NULL)
	{
#ifdef DeBug
	printf("gsmD: map #%d has saved values ($%x)\n", index, gfx_mapentries[index]);
#endif
		pw_setcmsname(cg_pixwinp, gfx_mapnames[index]);
		pw_putcolormap(cg_pixwinp, 0, size,
								gfx_mapentries[index],
								gfx_mapentries[index] + (size),
								gfx_mapentries[index] + (size * 2));

		free(gfx_mapentries[index]);
	}
	else
	{
#ifdef DeBug
	printf("gsmD: map #%d is brand new ($%x)\n", index, gfx_mapentries[index]);
#endif
		big_red[0] = big_green[0] = big_blue[0] = 255;
		big_red[size - 1] = big_green[size - 1] = big_blue[size - 1] = 0;

		pw_setcmsname(cg_pixwinp, gfx_mapnames[index]);
		pw_putcolormap(cg_pixwinp, 0, size, big_red, big_green, big_blue);
	}

	/* note that this has one more user */
	gfx_mapusers[index] = gfx_mapusers[index] + 1;
	wt_colmap[current_graf] = index;

    /* refresh the window */
	if ((wt_active[current_graf] < WT_GRAPHW)
	&& ((toolp->tl_flags & TOOL_ICONIC) != WT_ICONIC))
		refresh_txtwin(wt_pixwinp[current_graf], &wt_swrect[current_graf],
			wt_scrndata[current_graf], &wt_curposp[current_graf]);
	else
		wmgr_refreshwindow(wt_toolwp[current_graf]->tl_windowfd, rootfd);
}

grph_setmapentry()
{
	unsigned char red[1], green[1], blue[1];

	if (check_real_window() != 0) return(0);

	red[0] = com_numargs[1];
	green[0] = com_numargs[2];
	blue[0] = com_numargs[3];

	if (wt_colmap[current_graf] == -1)
		misprint(current_graf, "can't set entry in map for %d, not PWM map\n");
	else if (gfx_mapsizes[(wt_colmap[current_graf])] <= com_numargs[0])
		misprint(gfx_mapsizes[(wt_colmap[current_graf])],
						"can't set entry in map, outside range (%d)\n");
	else
		pw_putcolormap(cg_pixwinp, com_numargs[0], 1, red, green, blue);
}

grph_getmapentry()
{
	register int index, size;
	unsigned char red[1], green[1], blue[1];

	if (check_real_window() != 0) return(0);

	index = com_numargs[0];

	if (wt_colmap[current_graf] == -1)
		size = 2;
	else
		size = gfx_mapsizes[(wt_colmap[current_graf])];

	if (size <= com_numargs[0])
	{
		misprint(size, "PWM: can't get map entry, outside range (%d)\n");
		sprintf(report_buffer, REPmapentry, -1, -1, -1);
	}
	else
	{
		pw_getcolormap(cg_pixwinp, com_numargs[0], 1, red, green, blue);
		sprintf(report_buffer, REPmapentry, red[0], green[0], blue[0]);
	}

	send_report_to_poplog(strlen(report_buffer));
}

#ifdef DeBug
describe_colourmap()
{
/*	unsigned char red[256], green[256], blue[256];*/
	int index, size, i;
	char name[CMS_NAMESIZE];

	index = wt_colmap[current_graf];

	pw_getcmsname(cg_pixwinp, name);
	printf("map name is: '%s'\n", name);

	if (index < 0)
	{
		printf("--- default\n");
	}
	else
	{
		printf("--- ours, #%d, size=%d, users=%d\n",
				index, gfx_mapsizes[index], gfx_mapusers[index]);

		pw_getcolormap(cg_pixwinp, 0, gfx_mapsizes[index],
									big_red, big_green, big_blue);

		for (i = 0; i < gfx_mapsizes[index]; i++)
			printf("%d:\t%d\t%d\t%d\n", i,
						big_red[i], big_green[i], big_blue[i]);
	}
}
#endif


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    49:  grph_newcms()
::    76:  grph_killcms()
::   100:  grph_unsetmap(window)
::   135:  grph_setcw_cms()
::   201:  grph_setmapentry()
::   220:  grph_getmapentry()
::   249:  describe_colourmap()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */
/*
$Log:	pwcolour.c,v $
 * Revision 1.4  89/10/19  19:30:29  pop
 * removed changes in depth and fixed window refreshing 
 * 
 * Revision 1.3  89/08/23  16:13:04  pop
 * modified map name to use pid to make name unique
 * added set frame depth so that depth of frames controled by cms (sic)
 * modified grph_setcw_cms so that it changes the depth of the backing
 * pixrect and calls set_frame_depth if window is a frame
 * 
 * Revision 1.2  89/08/23  15:29:00  pop
 * modified select to use BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:19:31  pop
 * Initial revision
 * 
*/
