/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:    $usepop/master/C.all/lib/pwm/sunrasterfile.p
 > Purpose: read and write pwmrasterarrays as files in Sun standard format
 > Author:  Ben Rubinstein, Sep 21 1986 (see revisions)
 > Documentation:   HELP * PWMRASTERS
 > Related Files:   LIB * PWMRASTERS
 */

;;; NOTE: only handles type RT_STANDARD & colour map type RMT_EQUAL_RGB

uses newpwmrasterarray;

section $-library => sunrasterfile sunrasfile_colourmap sunrasheader;
section $-library$-pwmlib => sunrasterfile sunrasfile_colourmap sunrasheader;

global vars sunrasfile_colourmap = false;
lvars file;

/* defined by Sun */
constant rt_magic = 16:59A66A95,
         rt_standard = 1,
         rmt_none = 0,
         rmt_equal_rgb = 1;

define writeint(int, dev);
    lconstant string = consstring(0, 0, 0, 0, 4);
    lvars int dev;
    int && 255 -> subscrs(4, string);
    (int >> 8)  && 255 -> subscrs(3, string);
    (int >> 16) && 255 -> subscrs(2, string);
    (int >> 24) && 255 -> subscrs(1, string);
    syswrite(dev, string, 4);
enddefine;

define readint(dev) -> int;
    lconstant string = consstring(0, 0, 0, 0, 4);
    unless (sysread(dev, string, 4) ->> int) == 4 do
        mishap(int, dev, 2, 'unexpected lack of data in header')
    endunless;
    (subscrs(1, string) << 24)
        || (subscrs(2, string) << 16)
        || (subscrs(3, string) << 8)
        || subscrs(4, string) -> int
enddefine;

define lconstant misread(bytes);
    unless sysread(bytes) == bytes do
        mishap(file, bytes, 2, 'insufficient data in rasterfile');
    endunless;
enddefine;

define read_rasterheader(dev) -> width -> height -> depth -> len
                              -> cm_type -> cm_len -> colour_map;
    lconstant eb_buf = inits(1);
    lvars dev temp width height depth len cm_type cm_len colour_map=false;
    lvars col,entry,cmlen;
    unless (readint(dev) ->> temp) = rt_magic do
        mishap(file, temp, 2, 'not a rasterfile - bad magic number');
    endunless;
    readint(dev) -> width;
    readint(dev) -> height;
    readint(dev) -> depth;
    readint(dev) -> len;
    unless (readint(dev) ->> temp) = rt_standard do
        mishap(file, temp, 2, 'rasterfile of type RT_STANDARD required');
    endunless;
    if (readint(dev) ->> cm_type) == rmt_none then
        false -> cm_type;
    elseunless cm_type == rmt_equal_rgb do
        mishap(file, cm_type, 2, 'rasterfile must have RMT_EQUAL_RGB type colour map');
    endif;
    unless (readint(dev) ->> temp) = 0 or cm_type do
        mishap(file, temp, 2, 'rasterfile must have zero length colour map');
    elseif cm_type and ((temp // 3) -> cm_len) /== 0 do
        mishap(file, temp, 2, 'rasterfile colour map length must be multiple of 3');
    endunless;
    ;;; move to before image ADW 23/10/87
    ;;;; now read colourmap info, if any
    if cm_type then
        cm_len - 1 -> cmlen;
        newarray([0 ^cm_len],
            procedure(x);
                lvars x;
                initv(3);
            endprocedure) -> colour_map;
        for col from 1 to 3 do
            for entry from 0 to cmlen do
                misread(dev, eb_buf, 1);
                fast_subscrs(1, eb_buf) -> colour_map(entry)(col);
            endfor;
        endfor;
    endif;
enddefine;

define global sunrasheader(file);
lvars dev file;

    unless (sysopen(file, 0, false) ->> dev) do
        mishap(file, 1, 'file not found')
    endunless;

    read_rasterheader(dev);
    sysclose(dev);

enddefine;

define global sunrasterfile(file) -> rasarr;
    lvars bytes_p_row extrabyte avec_index rasarr pixels_p_byte;
    lvars dev len pic width height depth cm_len cm_type temp;
    lconstant eb_buf = inits(1);

    unless (sysopen(file, 0, false) ->> dev) do
        mishap(file, 1, 'file not found')
    endunless;

    read_rasterheader(dev) -> width -> height -> depth -> len
                           -> cm_type -> cm_len -> sunrasfile_colourmap;

    newpwmrasterarray([1 ^width 1 ^height], depth) -> rasarr;
;;; note local version of newpwmrasterarray padds to 16 bit boundary

    if ((width * depth) // 8 -> bytes_p_row) > 0 then
        bytes_p_row + 1 -> bytes_p_row;
    endif;

;;;    if erase(bytes_p_row // 2) == 0 then false else eb_buf endif -> extrabyte;

    1 -> avec_index;

    repeat height times
        misread(dev, avec_index, rasarr.arrayvector, bytes_p_row);
        avec_index + bytes_p_row -> avec_index;
;;;        if extrabyte then
;;;            misread(dev, extrabyte, 1);
;;;        endif;
    endrepeat;

    sysclose(dev);
enddefine;

define updaterof global sunrasterfile(rasarr, file);
    lvars rasarr avec dev width height depth a_index arr_bpr fil_bpr;
    lvars x1 x2 y1 y2;
    lconstant nullfield = consstring(0, 0, 0, 0, 4);

    ;;; this also checks properly formatted (byte-aligned) etc
    rasarr.pr_depth -> depth;

    rasarr.boundslist.destlist ->; -> y2 -> y1 -> x2 -> x1;
    x2 - x1 + 1 -> width;
    y2 - y1 + 1 -> height;

    rasarr.arrayvector -> avec;

    ;;; arr_bpr is bytes per row in the array vector,
    ;;; fil_bpr is bytes per row to be written to the file
    ;;;if ((width * depth) // 8 -> arr_bpr) > 0 then arr_bpr + 1 -> arr_bpr endif;
    (depth*length(avec)) div (8*height) -> arr_bpr;
    if erase(arr_bpr // 2) > 0 then arr_bpr + 1 else arr_bpr endif -> fil_bpr;

    syscreate(file, 1, false) -> dev;

    writeint(rt_magic, dev);                ;;; magic number
    writeint(width, dev);                   ;;; width in pixels
    writeint(height, dev);                  ;;; height in pixels
    writeint(depth, dev);                   ;;; depth in bits/pixel
    writeint(fil_bpr * height, dev);        ;;; bytes of data
    writeint(rt_standard, dev);             ;;; raster file type
    syswrite(dev, nullfield, 4);            ;;; maptype
    syswrite(dev, nullfield, 4);            ;;; maplength

    1 -> a_index;
    repeat height times
        syswrite(dev, a_index, avec, arr_bpr);
        unless arr_bpr == fil_bpr do
            syswrite(dev, nullfield, 1);    ;;; pad rows to 16 bit multiples
        endunless;
        a_index + arr_bpr -> a_index;
    endrepeat;

    sysclose(dev);
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Apr  5 1987 - changed section, made to use -pr_depth-
--- Ben Rubinstein, Mar 26 1987 - fixed silly vars problem in updater
--- Ben Rubinstein, Mar 17 1987 - made to read colour map data
--- Ben Rubinstein, Mar  5 1987 - altered for use with -newpwmrasterarray-
--- Anthony Worrall, Feb 3 1989 - changed calculation of bytes per row in array
                                  as pwmraster are padded cf sun.
*/
