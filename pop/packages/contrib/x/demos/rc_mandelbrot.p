;;; $popcontrib/x/demos/rc_mandelbrot.p

;;; Jonathan Sloman and Aaron Sloman 19th May 1990

;;; Program to draw Mandelbrot pictures in black and white.
;;; Try modifying it do do it in colour?


/*
;;; Compile the file then try the following
rc_new_window(700,700,250,20,true);
mandel(10, 20);	;;; small one
mandel(10, 100); 	;;; bigger, and slower
mandel(10, 700);
*/


uses rc_graphic.p

define mandel(acc,size);
	;;; Draw a black and white mandelbrot picture

    lvars real, imag, temp, acc, size, x,y,n;
    unless isinteger(acc) then
        mishap(acc,1,'ACC should be an integer')
    endunless;
    unless isinteger(size) then
        mishap(acc,1,'ACC should be an integer')
    endunless;

    rc_start();

    round(size/3) -> size;

    round(2.25*size)+10 -> rc_xorigin;
    round(1.5*size)+10 -> rc_yorigin;

    size  -> rc_xscale;
    size  -> rc_yscale;

    for x from -2.25 by (1.0/size) to 1.0 do
        for y from -1.5 by (1.0/size) to 1.5 do

            x -> real;
            y -> imag;
            0 -> n;

            repeat
                real -> temp;
                real*real-imag*imag + x -> real;
                2*temp*imag + y -> imag;
                n fi_+ 1 -> n;
            quitif( n fi_> acc);
            quitif( (real * real + imag * imag) > 4);
            endrepeat;

            if n fi_> acc then
                rc_drawpoint(x,y);
            elseif ((n mod 2) == 0) and (round(x * size) mod 2 == 0)
            and (round(y * size) mod 2 == 0) then
                rc_drawpoint(x,y);
            endif;

        endfor;
    endfor;
enddefine;
