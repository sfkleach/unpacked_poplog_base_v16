/* --- Copyright University of Sussex 1989.  All rights reserved. ---------
 * File:    C.sun/pwm/pwgraster.c
 * Purpose: saving loading dumping reading and copying rasters
 * Author:  Ben Rubinstein (+ bitconversion by Aled Morris), Jan  8 1987 (see revisions)
 * $Header: /tmp_mnt/poplog/pop/pwm/RCS/pwgraster.c,v 1.5 89/10/19 19:29:51 pop Exp $
 */

#include "pwdec.h"
#include "pwrepseq.h"
#include <errno.h>
#include <sgtty.h>
#include <sys/ioctl.h>

#define RDUMPALRM 20000 /* how long to set timer for to stop us locking up */
#define MAXALARMS 3     /* how many times to left the timer go off before we
                        * give up */

static int errno;

struct timeval dump_timeout = {10, 10};

struct pixrect *pr_load();

colormap_t comap_t = {RMT_EQUAL_RGB, 0, (unsigned char *)NULL};
extern int gfx_mapsizes[];


/*****
 * bit masks for retrieving low-order bits from input stream,
 * this array is indexed by the number of significant bits, and
 * it gives the bitmask (ie all ones) to use
 *****/
int signib_masks[9] = { 0, 1, 3, 0, 15, 0, 0, 0, 255 };

/* -- checking the width of the communication channel--------------- */

static int com_width;

get_comms_width()
{
    unsigned int i, j;

    i = ((unsigned char)(com_charargs[0]) ^ (unsigned char)(com_charargs[1]))
            & 255;

    for (j = 0; ((i & 1 == 1) && (j < 9)) ; j++)
    {
        i = i >> 1;
    }

    sprintf(report_buffer, REPcomswidth, j);
    send_report_to_poplog(strlen(report_buffer));
#ifdef DeBug
    printf("GCW: com width appears to be %d (%d, %d)\n",
                        j, com_charargs[0], com_charargs[1]);
#endif
}

set_comms_width()
{
    com_width = com_numargs[0];
#ifdef DeBug
    printf("SCW: setting com width to %d\n", com_width);
#endif
}

/*--- dumping, reading and copying rasters --------------------------- */

/*--------------------------------------------------------------------
*   read a raster description from poplog, returning a pointer to a
*   pixrect filled with the data, or a pointer to NULL if something
*   went wrong.  It is assumed that parts of the standard arg tables
*   have meanings as follows:
*       charargs[0] = bits per byte
*                       (number of bits in each byte sent which have
*                       signifigance: it is assumed that these are the lower
*                       order bits in each byte)
*       charargs[1] = bits per pixel
*                       (how many of the signifigant bits sent
*                       are consumed by each pixel)
*        numargs[0] = width (in pixels)
*        numargs[1] = height (in pixels)
*        numargs[2] = bytes per row (actual bytes sent for each row)
*
* (23/4/87) There are actually three "depth" (i.e. bits/pixel) values to
* be played around with:
*   the data sent down from the line gives some data per pixel (depth_i)
*   the output pixrect must have a certain depth, 1 or 8 (depth_r)
*   the colour-map may have a size in the range 1,2,4 or 8 (mapsize)
*
* So, the image data sent must be adjusted for the map size, by zero padding
* on left or by shifting right; then it must expanded if necessary to suit
* the depth of the output pixrect (always expanded, because if depth_r is
* 1 then mapsize will be 1: mapsize is always <=  depth_r.
*
*   If the data sent is packed into eight-bit, we can read a row directly into
*       a buffer pixrect's data area, and either rop it to the output pixrect;
*       or use sun's pixel-get routines to extract each pixel, for shifting,
*       and then use sun's pixel-put routines to pack the pixel into the output
*       pixrect (clipping)
*
*   If the data sent is packed, but into nibbles, we can read a row into our own
*       buffer, and then repack it into bytes into a buffer pixrect's data
*       area, and either rop it to the output pixrect; or use sun's pixel-get
*       routines to extract each pixel, for shifting, and then use sun's
*       pixel-put routines to pack the pixel into the output pixrect (clipping)
*
*   Otherwise, we require that the data is sent as one pixel in each byte (in the
*       low end) and then we read a row into our own buffer, extract each pixel
*       (no problem, 'cos it's just a byte) shift as necessary and then use
*       sun's pixel-put routines to pack the pixel into the output pixrect
*       (clipping as it does so).
*/
struct pixrect *
grph_readraster(depth_r, mapsize)
int depth_r;            /* depth of required output pixrect */
int mapsize;            /* depth of a pixel                 */
{
    int row, width, height,
        bits_pb,        /* bits per byte    */
        depth_i,        /* depth of image   */
        bytes_pr,       /* bytes being sent per row     */
        bytes_tr,       /* bytes to read from clientfd  */
        combytes;       /* bytes already in com_buffer  */

    char
        *databuffer,    /* buffer to read data into - may = rowbuffer   */
        *dbufadd,       /* used as a pointer into buffer                */
        *rowbuffer,     /* pointer to data in buffer pr                 */
        signibmask,     /* mask to get SIGNIfigant Bits out of a byte   */
        shiftcnt,       /* how many times to shift pixels               */
        onepixpb_no8,   /* true if one pixel per byte, not full 8-bit   */
        usedatabuf;     /* if we need to read data into a buffer of our own */

    struct pixrect *result_pr, *rowbuffer_pr;

    bytes_pr    = com_numargs[0];
    width       = com_numargs[1];
    height      = com_numargs[2];
    depth_i     = com_charargs[0] - 32;
    bits_pb     = com_charargs[1] - 32;

    onepixpb_no8 = (((bits_pb != 8) && (bits_pb == depth_i)) ? TRUE : FALSE);
    usedatabuf = ((bits_pb == 8) ? FALSE : TRUE);

    if ((!onepixpb_no8) && (bits_pb != 8) && (bits_pb != 4))
    {   /* unless one pixel per byte, must be in byte or nibble *
        *  mode, because we can't handle any other combination  */
#ifdef DeBug
    printf("bpb=%d, dpthI=%d, dpthr=%d.  Stop\n", bits_pb, depth_i, depth_r);
#endif
        misprint(bits_pb,
                "PWM: ignoring raster dump with strange (%d) bits per byte\n");
        goto rrfail1;
    }

    signibmask = signib_masks[bits_pb];
    shiftcnt = ((mapsize < depth_i) ? (depth_i - mapsize) : 0);

#ifdef DeBug
    printf("GRR: %dx%d, bytes/row=%d, bits/byte=%d\n\
\tDpthI=%d, DpthR=%d, MapS=%d, shift=%d, 1ppb=%d, udbuf=%d\n",
                width, height, bytes_pr, bits_pb, depth_i,
                depth_r, mapsize, shiftcnt, onepixpb_no8, usedatabuf);
#endif

    /* make a pixrect for the output raster */
    if ((result_pr = mem_create(width, height, depth_r))
                    == (struct pixrect *)NULL)
    {
        misprint(-1, "PWM: cannot create result pixrect for raster-dump");
        goto rrfail1;
    }

    if (!onepixpb_no8)
    {   /* make a pixrect for one row of the input raster */
        if ((rowbuffer_pr = mem_create(width, 1, depth_i))
                                        == (struct pixrect *)NULL)
        {
            misprint(-1, "PWM: cannot create buffer pixrect for raster-dump");
            onepixpb_no8 = TRUE;    /* so we don't try to destroy rowbuffer_pr */
            usedatabuf = FALSE;     /* so we don't try to free databuffer */
            goto rrfail2;
        }

        rowbuffer = (char *)
                    ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image;
#ifdef DeBug
    printf("GRR: rowbuffer_pr made: $%x ($%x), %dx%dx%d\n",
                        rowbuffer_pr, rowbuffer,
                        rowbuffer_pr->pr_width, rowbuffer_pr->pr_height,
                        rowbuffer_pr->pr_depth);
#endif
    }

/*  if ((bits_pb !=  8) || (depth_r < depth_i))*/
    if (usedatabuf)
    {   /* make a buffer that can hold one row's-worth of raw data from POPLOG */
        if ((databuffer = (char *)malloc(bytes_pr)) == (char *)NULL)
        {
            misprint(bytes_pr, "PWM: cannot allocate databuffer %d for raster-dump");
            usedatabuf = FALSE;     /* so we don't try and free databuffer */
            goto rrfail2;
        }
    }
    else
    {   /* use the row pixrect's memory directly */
         databuffer = (char *)
                    (((struct mpr_data *)rowbuffer_pr->pr_data)->md_image);
    }

#ifdef DeBug
    printf("GRR: rowbuffer=$%x, databuffer=$%x\n", rowbuffer, databuffer);
#endif

    if ((combytes = com_buflen - com_bufnext) < 0) combytes = 0;

    /* now, here we go: for each row... */
    for (row = 0; row < height; row++)
    {
        register int i;

        /* ... set bytes-to-read to bytes-per-row ... */
        bytes_tr = bytes_pr;

        if (combytes != 0)
        {   /* at least some of the data for this line has already been
            *   read off the device and into com_buffer: so copy it out
            *   and adjust variables.
            */
            bytes_tr = bytes_tr - (i = min(bytes_pr, combytes));
            for (; i >= 0; i--) databuffer[i] = com_buffer[com_bufnext++];

            if ((combytes = com_buflen - com_bufnext) < 0) combytes = 0;
        }

        dbufadd = (char *) databuffer + bytes_pr - bytes_tr;

        /* it may be zero if we got enough out of com_buffer above */
        while (bytes_tr != 0)
        {
            register int tries = 0;
            int tablesize;

            FD_ZERO(&fdset);
            FD_SET(client_ifd,&fdset);

            tablesize = getdtablesize();

            while ((i = select(tablesize, &fdset, 0, 0, &dump_timeout)) < 1)
            {
                if  (errno == EINTR)
                {
#ifdef DeBug
printf("GRR: select INTR (%d:%d) on row %d. Stop.\n", i, errno, row);
#endif
                    ioctl(client_ifd, TIOCFLUSH, (struct sgttyb *)NULL);
                    goto rrfail2;
                }
                else if (++tries > 2)
                {
#ifdef DeBug
printf("GRR: select failed (%d:%d) %d times on row %d. Stop.\n", i, errno, tries, row);
#endif
                    ioctl(client_ifd, TIOCFLUSH, (struct sgttyb *)NULL);
                    goto rrfail2;
                }
                else
                {
#ifdef DeBug
printf("GRR: select failed (%d:%d,i=%d) %d times on row %d.\n",
                                i, errno, client_ifd, tries, row);
#endif
                    FD_ZERO(&fdset);
                    FD_SET(client_ifd,&fdset);
                }
            }
            i = read(client_ifd, dbufadd, bytes_tr);
            bytes_tr = bytes_tr - i;
            dbufadd = dbufadd + i;
/*
#ifdef DeBug
    if (bytes_tr != 0)
        printf("going again in row %d: %d / %d\n", row, bytes_tr, bytes_pr);
    else if (shift_escape)
        printf("read row %d ok\n", row);
#endif
*/
        }

#ifdef DeBug
    if (row == 50)
        printf("-- %d, %d, %d\n", databuffer[23], databuffer[24], databuffer[25]);
#endif

        /* now transfer this row of data into the "result_pr", converting   *
        *   if necessary for different depths and for less than 8-bit data  */
        if (onepixpb_no8)
        {   /* exactly one pixel in each byte, at the low end of it */

            if (shiftcnt == 0) /* sent pixels same size or less than req. */
            {
                for (i = 0; i < bytes_pr; i++)
                    pr_put(result_pr, i, row, ((databuffer[i]) & signibmask));
            }
            else
            {
                for (i = 0; i < bytes_pr; i++)
                    pr_put(result_pr, i, row,
                        (((databuffer[i]) & signibmask) >>  shiftcnt));
            }
        }
        else
        {
            if (bits_pb == 4)
            {   /* nibble mode - whack it into byte mode, in the buffer_pr */
                register int j;

                for (i = j = 0; i < (bytes_pr - 1); j++)
                {
                    rowbuffer[j] = ((databuffer[i] & 15)
                                    | ((databuffer[i + 1] << 4) & 240));
                    i += 2;
                }
            }

            if ((depth_i == depth_r) && (depth_i == mapsize))
            {   /* no conversion necessary - just copy it in */
                pr_rop(result_pr, 0, row, width, 1, PIX_SRC,
                            rowbuffer_pr, 0, 0);
            }
            else if (shiftcnt == 0) /* bits in sent pixels <= req. */
            {
                for (i = 0; i < width; i++)
                    pr_put(result_pr, i, row, pr_get(rowbuffer_pr, i, 0));
            }
            else /* bits in sent pixels > req. depth: shift down */
            {
                for (i = 0; i < width; i++)
                    pr_put(result_pr, i, row,
                            ((pr_get(rowbuffer_pr, i, 0)) >> shiftcnt));
#ifdef DeBug
    if (row == 50)
    {
        int j;

        if (depth_i == 4) j = 2; else j = 1;

        printf("++ %d, %d, %d\n",
                pr_get(rowbuffer_pr, 23 * j, 0),
                pr_get(rowbuffer_pr, 24 * j, 0),
                pr_get(rowbuffer_pr, 25 * j, 0));
        printf("^^ %d, %d, %d\n",
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[23],
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[24],
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[25]);

    pr_put(rowbuffer_pr, 23 * j, 0, 1);
    pr_put(rowbuffer_pr, 24 * j, 0, 0);
    pr_put(rowbuffer_pr, 25 * j, 0, 1);
        printf("++ %d, %d, %d\n",
                pr_get(rowbuffer_pr, 23 * j, 0),
                pr_get(rowbuffer_pr, 24 * j, 0),
                pr_get(rowbuffer_pr, 25 * j, 0));
        printf("^^ %d, %d, %d\n",
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[23],
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[24],
                ((char *)
            ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image)[25]);
    }
#endif
            }
        }
    }

    goto rrexit;    /* clean up temporary buffers, return result pr */

rrfail2:
    pr_destroy(result_pr);
rrfail1:
    result_pr = (struct pixrect *)NULL;
rrexit:
    if (usedatabuf) free(databuffer);

    if (!onepixpb_no8) pr_destroy(rowbuffer_pr);

    return(result_pr);
}

/*--------------------------------------------------------------------
*   Read a raster from the line, dump it to the screen.
*
*/
grph_rasterdump()
{
    int top, left, width, height, dpth_r, msiz;
    struct pixrect *temp_pr;

    width   = com_numargs[1];
    height  = com_numargs[2];
    left    = com_numargs[3];
    top     = com_numargs[4];

    dpth_r = cg_pixrectp->pr_depth;

#ifdef DeBug
    printf("GRD: dpth_r=%d\n", dpth_r);
#endif

/* IR 23/2/89: SFR 4185 - replaced the following with msiz = dpth_r
 *
 *  if ((cg_winisframe) || (dpth_r == 1))
 *      msiz = dpth_r;
 *  else
 *  {
 *      int i;
 *
 *      i = gfx_mapsizes[(wt_colmap[current_graf])];
 *
 *      for (msiz = 1; i >> msiz != 1 ; msiz++) {};
 *  }
 */

    msiz = dpth_r;


#ifdef DeBug
    printf("GRD: msiz=%d\n", msiz);
#endif

/* 
    if ((temp_pr = grph_readraster(dpth_r, msiz)) != (struct pixrect *)NULL)
    readraster only works for one bit anyway
*/
    if ((temp_pr = grph_readraster(1, 1)) != (struct pixrect *)NULL)
    {
        if (cg_winisframe)
            pr_rop(cg_pixrectp, left, top, width, height,
                                        graphic_op, temp_pr, 0, 0);
        else
            pw_rop(cg_pixwinp, left, top, width, height,
                                        graphic_op, temp_pr, 0, 0);

        pr_destroy(temp_pr);
    }
#ifdef DeBug
    else
        printf("GDR: read raster returned failure\n");
#endif
}

/*--------------------------------------------------------------------
*   read a raster from the screen, send it up the line.
*/
grph_rasterread()
{
    int x, y, ylim, i, depth, width, height, bytes_pl;
    short *rowbuffer;
    struct pixrect *rowbuffer_pr;

    x = com_numargs[0];
    y = com_numargs[1];
    width = com_numargs[2];
    height = com_numargs[3];
    ylim = com_numargs[1] + height;

    depth = cg_pixrectp->pr_depth;

    if ((x + width) > cg_pixrectp->pr_width)
        width = cg_pixrectp->pr_width - x;
    if ((y + height) > cg_pixrectp->pr_height)
        height = cg_pixrectp->pr_height - y;

#ifdef DeBug
    printf("-- grb: (%d,%d) %dx%d (%dx%d), d=%d\n", x, y, width, height,
                    com_numargs[2], com_numargs[3], depth);
#endif

    rowbuffer_pr = mem_create(width, 1, depth);
    bytes_pl = ((struct mpr_data *)rowbuffer_pr->pr_data)->md_linebytes;
    rowbuffer = ((struct mpr_data *)rowbuffer_pr->pr_data)->md_image;

    sprintf(report_buffer, REPrastercome, 8 + 32, depth + 32,
                            width, height, bytes_pl);
    send_report_to_poplog(strlen(report_buffer));

    ioctl(client_ofd, TIOCFLUSH, (struct sgttyb *)NULL);
    set_rawmode();

    for (y = com_numargs[1]; y < ylim; y++)
    {
        pr_rop(rowbuffer_pr, 0, 0, width, 1, PIX_SRC, cg_pixrectp, x, y);
        write(client_ofd, rowbuffer, bytes_pl);
#ifdef DeBug
        printf("--- grb: sent another %d bytes\n", bytes_pl);
#endif
    }

    ioctl(client_ofd, TIOCFLUSH, (struct sgttyb *)NULL);
    pr_destroy(rowbuffer_pr);
    reset_rawmode();
}

grph_copyraster()
{
    int swin, sx, sy, width, height, op, val, dwin, dx, dy;
    register int xdiff, ydiff, depth;
    struct pixrect *spr, *dpr, *tmp_pr;

    swin = com_charargs[0] - 32;
    op = ropconvert[(com_charargs[1] & 15)];
    dwin = com_charargs[2] - 32;

    sx = com_numargs[0];    sy = com_numargs[1];
    width = com_numargs[2]; height = com_numargs[3];
    dx = com_numargs[4];    dy = com_numargs[5];

    if ((dpr = get_gfx_surface_pr(dwin)) == (struct pixrect *)NULL)
        return(0);

    if ((spr = get_gfx_surface_pr(swin)) == (struct pixrect *)NULL)
        return(0);

    if (dpr->pr_depth != spr->pr_depth)
    {
#ifdef DeBug
    printf("GCR: different depths: (%d=%d, %d=%d)\n",
                                swin, spr->pr_depth, dwin, dpr->pr_depth);
#endif
        misprint(-1, "PWM: can't copy raster: windows of different depth\n");
        return(0);
    }
#ifdef DeBug
    printf("GCR: d=%d,pr=$%x, s=%d,pr=$%x\n", dwin, dpr, swin, spr);
#endif

    if (width == 0) width = spr->pr_width;
    if (height == 0) height = spr->pr_height;

    if (wt_active[dwin] == WT_FRAMEW)
    {
#ifdef DeBug
    printf("GCR- type 1, %d is frame\n", dwin);
#endif
        pr_rop(dpr, dx, dy, width, height, graphic_op, spr, sx, sy);

        if ((op != PIX_DST) && (wt_active[swin] != WT_FRAMEW))
            pw_writebackground(wt_pixwinp[swin], sx, sy, width, height, op);
    }
    else if  ((dwin != swin) || (op == PIX_DST) ||
            (abs(sx - dx) >= width) || (abs(sy - dy) >= height))
    {   /* then we don't have to anything fancy about the clear up */
        pw_rop(wt_pixwinp[dwin], dx, dy, width, height, graphic_op, spr, sx, sy);

        if ((op != PIX_DST) && (wt_active[swin] != WT_FRAMEW))
            pw_writebackground(wt_pixwinp[swin], sx, sy, width, height, op);
    }
    else
    {
        tmp_pr = mem_create(width, height, spr->pr_depth);
        pr_rop(tmp_pr, 0, 0, width, height, graphic_op, spr, sx, sy);

        if (sx < dx)
            pw_writebackground(wt_pixwinp[swin], sx, sy,
                                    min(dx - sx, width), height, op);
        else if (sx > dx)
            pw_writebackground(wt_pixwinp[swin], dx + width, sy,
                                    sx - dx, height, op);

        if (sy < dy)
            pw_writebackground(wt_pixwinp[swin], max(sx, dx), sy,
                                    width - abs(sx - dx),
                                    min(dy - sy, height), op);
        else if ((sy > dy) && ((sy - dy) < height))
            pw_writebackground(wt_pixwinp[swin], max(sx, dx), dy + height,
                                    width - abs(sx - dx), sy - dy, op);

        pw_rop(wt_pixwinp[dwin], dx, dy, width, height, graphic_op, tmp_pr, 0, 0);
        pr_destroy(tmp_pr);
    }
}

/*--- filing windows ------------------------------------------------------*/

/*--------------------------------------------------------------------
*   args are left, top, width, height, and filename
*/
grph_writerasfile()
{
    FILE *output_file;
    int res, w, h, x, y;
    colormap_t *cmap_tp;                /* pointer to a colourmap thing*/
    unsigned char *cmap_map[3];     /* array of pointers to colmap entries*/

    if ((output_file = fopen(com_stringarg, "w")) == (FILE *)NULL)
    {
        misprint(-1, "PWM: couldn't open file\n");
        report_status(2);
    }
    else
    {
        x = com_numargs[0];
        y = com_numargs[1];
        w = com_numargs[2];
        h = com_numargs[3];

/*      cmap_tp = (colormap_t *)NULL;*/
        if (cg_winisframe || (cg_pixrectp->pr_depth == 1))
        {
#ifdef DeBug
    printf("--- gwr: depth 1, using null cmap\n");
#endif
            cmap_tp = (colormap_t *)NULL;
        }
        else if (wt_colmap[current_graf] == -1)
        {
#ifdef DeBug
    printf("--- gwr: depth >1 but no cms, using null cmap\n");
#endif
            comap_t.type = RMT_NONE;
            comap_t.length = 0;
            comap_t.map[0] = (unsigned char *)NULL;
            comap_t.map[1] = (unsigned char *)NULL;
            comap_t.map[2] = (unsigned char *)NULL;
            cmap_tp = &comap_t;
        }
        else
        {
#ifdef DeBug
    printf("--- gwr: win %d, depth >1, using our cms %d\n",
                             current_graf, wt_colmap[current_graf]);
#endif
            comap_t.type = RMT_EQUAL_RGB;
            comap_t.length = gfx_mapsizes[wt_colmap[current_graf]];
#ifdef DeBug
    printf("--- gwr: depth >1, using our cms length %d\n", comap_t.length);
#endif
            pw_getcolormap(cg_pixwinp, 0, comap_t.length,
                                    big_red, big_green, big_blue);

#ifdef DeBug
    printf("--- gwr: read cms values\n");
#endif
/*
            cmap_map[0] = big_red;
            cmap_map[1] = big_blue;
            cmap_map[2] = big_green;
            comap_t.map[0] = cmap_map[0];
            comap_t.map[1] = cmap_map[1];
            comap_t.map[2] = cmap_map[2];
*/
            comap_t.map[0] = big_red;
            comap_t.map[1] = big_blue;
            comap_t.map[2] = big_green;
#ifdef DeBug
    printf("--- gwr: cms 0 = %d, %d, %d\n",
                comap_t.map[0][0],
                comap_t.map[1][0],
                comap_t.map[2][0]);
    printf("--- gwr: cms 1 = %d, %d, %d\n",
                comap_t.map[0][1],
                comap_t.map[1][1],
                comap_t.map[2][1]);
#endif
            cmap_tp = &comap_t;
        }

        if (x == 0 && y == 0 && w == 0 && h == 0)
        {   /* the whole window */
#ifdef DeBug
    printf("--- gwr: writing whole window (%dx%d)\n",
                    cg_pixrectp->pr_width, cg_pixrectp->pr_height);
#endif
            res = pr_dump(cg_pixrectp,
                            output_file,
/*                          (colormap_t *)NULL,*/
                            cmap_tp,
                            RT_STANDARD,
                            0);
        }
        else
        {
            struct pixrect *tmp_pr;

            if (w == 0) w = cg_pixrectp->pr_width - x;
            if (h == 0) h = cg_pixrectp->pr_height - y;
            tmp_pr = mem_create(w, h, cg_pixrectp->pr_depth);
            pr_rop(tmp_pr, 0, 0, w, h, PIX_SRC, cg_pixrectp, x, y);
/* pr_dump doesn't seem to be able to handle region pixrects */
/*          tmp_pr = pr_region(cg_pixrectp, x, y, w, h);*/
#ifdef DeBug
    printf("--- gwr: temp_pr made (%d, %d), depth=%d, $%x\n",
                            w, h, tmp_pr->pr_depth, tmp_pr);
#endif
            res = pr_dump(tmp_pr,
                            output_file,
/*                          (colormap_t *)NULL,*/
                            cmap_tp,
                            RT_STANDARD,
                            0);

            pr_destroy(tmp_pr);
        }
        fclose(output_file);
#ifdef DeBug
    printf("--- gwr: pr_dump returned %d\n", res);
#endif
        if (res > 1) res = 1;
        report_status(res);
    }
}

/*--------------------------------------------------------------------
*   args are filename, x, y, w, h to define a rectangular portion of the
*   image to restore, and x,y of where in the window the top left corner
*   of restored image should go:
*
*               com_numargs[0] - dest.left
*               com_numargs[1] - dest.top
*               com_numargs[2] - source.left
*               com_numargs[3] - source.top
*               com_numargs[4] - width
*               com_numargs[5] - height
*               com_stringarg - filename
*/
grph_readrasfile()
{
    FILE *input_file;
    struct pixrect *input_pr;
    int width, height;

    if ((input_file = fopen(com_stringarg, "r")) == (FILE *)NULL)
        misprint(-1, "PWM: couldn't open rasterfile\n");
    else
    {
        input_pr = pr_load(input_file, (colormap_t *)NULL);
        fclose(input_file);

        if (input_pr == (struct pixrect *)NULL)
        {
            misprint(-1, "PWM: couldn't load rasterfile\n");
        }
        else
        {
            width = input_pr->pr_size.x;
            if (com_numargs[4] != 0 && com_numargs[4] < width)
                width = com_numargs[4];

            height = input_pr->pr_size.y;
            if (com_numargs[5] != 0 && com_numargs[5] < height)
                height = com_numargs[5];

            if (cg_winisframe)
                pr_rop(cg_pixrectp,
                        com_numargs[0],
                        com_numargs[1],
                        width, height,
                        graphic_op, input_pr, com_numargs[2], com_numargs[3]);
            else
                pw_rop(cg_pixwinp,
                        com_numargs[0],
                        com_numargs[1],
                        width, height,
                        graphic_op, input_pr, com_numargs[2], com_numargs[3]);

            pr_destroy(input_pr);
        }
        fclose(input_file);
    }
}


/* -- pages--------------------------------------------------------- */

grph_new_page()
{
    register int i;

    for (i = FT_FIRSTFRAME; i < FT_LASTFRAME ; i++)
        if (wt_active[i] == FALSE) break;

    if (i < FT_LASTFRAME)
    {
        if  ((gfx_frames[i - FT_FIRSTFRAME]
                = mem_create(com_numargs[0], com_numargs[1],SCREENDEPTH)) == NULL)
        {
            misprint(i, "PWM: can't create invisible win %d\n");
            wt_active[i] = FALSE;
        }
        else
        {
            wt_active[i] = WT_FRAMEW;
        }
    }
    else
    {
        misprint(-1, "PWM: can't make invisible window - no room at table\n");
    }
    report_status(i);
}

grph_kill_page()
{
    register int i;

    if (((i = com_charargs[0] - 32) < FT_FIRSTFRAME) || (i >= FT_LASTFRAME))
        misprint(i, "PWM: can't kill surface %d - no such surface\n");
    else if (wt_active[i] != WT_FRAMEW)
        misprint(i, "PWM: can't kill surface %d - not live surface\n");
    else
    {
        pr_destroy(gfx_frames[i - FT_FIRSTFRAME]);
        wt_active[i] = FALSE;
        if (current_graf == i) select_graphic_window(0);
    }
}

/* -- utilities----------------------------------------------------- */

/*--------------------------------------------------------------------
* takes id num of supposed page or window, and checks that it is either
* a live page or a live window; complaining if not.  Returns a pointer
* to the pixrect for the page/backup pixrect for the window, NULL if there
* was an error.
*/
struct pixrect *
get_gfx_surface_pr(win)
int win;
{
    if ((win >= WT_FIRSTWIN)
        && (win <= WT_LASTWIN)
        && (wt_active[win] >= WT_ACTIVE))
    {
        return(wt_pixwinp[win]->pw_prretained);
    }
    else if ((win >= FT_FIRSTFRAME)
        && (win < FT_LASTFRAME)
        && (wt_active[win] != FALSE))
    {
        return(gfx_frames[win - FT_FIRSTFRAME]);
    }
    else
    {
        misprint(win, "PWM: can't do graphics on #%d, no such surface\n");
        return((struct pixrect *)NULL);
    }
}

/*--------------------------------------------------------------------
*   takes index to supposed surface-id in array of character args, and
*   returns the win-id if there is one, WT_NOWIN else (and complains
*   in the else case)
*/
check_surface_id(i)
register int i;
{
    i = com_charargs[i] - 32;

    if ((i < WT_FIRSTWIN) || (i >= FT_LASTFRAME))
    {
        misprint(i, "PWM: can't do graphics on %d, no such surface\n");
        return(WT_NOWIN);
    }
    else if (i < FT_FIRSTFRAME)
    {
        if (wt_active[i] < WT_ACTIVE)
        {
            misprint(i, "PWM: can't do graphics on %d, not live window\n");
            return(WT_NOWIN);
        }
        else
            return(i);
    }
    else
    {
        if (wt_active[i] == FALSE)
        {
            misprint(i, "PWM: can't do graphics on %d, not live surface\n");
            return(WT_NOWIN);
        }
        else
            return(i);
    }
}

set_rawmode()
{
    int wasraw;
    struct sgttyb sg;

    ioctl(client_ofd, TIOCGETP, &sg);

    wasraw = sg.sg_flags & ECHO;

    if (wasraw == 0)
    {
        sg.sg_flags = sg.sg_flags | RAW;
        ioctl(client_ofd, TIOCSETP, &sg);
    }

    return(wasraw);
}

reset_rawmode()
{
    struct sgttyb sg;

    ioctl(client_ofd, TIOCGETP, &sg);
    sg.sg_flags = sg.sg_flags ^ RAW;
    ioctl(client_ofd, TIOCSETP, &sg);
}


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
:: ----1---Copyright University of Sussex 1987.  All rights reserved. ------
:: ---34---checking the width of the communication channel------
::    38:  get_comms_width()
::    58:  set_comms_width()
:: ---66---dumping, reading and copying rasters ------
::   114:  grph_readraster(depth_r, mapsize)
::   392:  grph_rasterdump()
::   437:  grph_rasterread()
::   486:  grph_copyraster()
:: --565---filing windows ------
::   570:  grph_writerasfile()
::   708:  grph_readrasfile()
:: --755---pages------
::   757:  grph_new_page()
::   785:  grph_kill_page()
:: --801---utilities------
::   810:  get_gfx_surface_pr(win)
::   837:  check_surface_id(i)
::   869:  set_rawmode()
::   887:  reset_rawmode()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */

/* --- Revision History ---------------------------------------------------
--- Ian Rogers, Feb 23 1989
    Implemented changes according to SFR 4185
$Log:	pwgraster.c,v $
 * Revision 1.5  89/10/19  19:29:51  pop
 * pages  now default to SCREENDEPTH depth
 * 
 * Revision 1.4  89/08/23  17:53:51  pop
 * depth removed from new_page
 * 
 * Revision 1.3  89/08/23  17:07:30  pop
 * made depth of new page allways one, the depth can be controlled by
 * use of colourmaps (sic)
 * 
 * Revision 1.2  89/08/23  15:31:12  pop
 * modified select for BSD4.3 fd_set
 * 
 * Revision 1.1  89/08/23  13:20:27  pop
 * Initial revision
 * 
 */
