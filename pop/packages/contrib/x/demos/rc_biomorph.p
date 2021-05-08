;;; $popcontrib/x/demos/rc_biomorph.p
;;; rc_biomorph.p

;;; Mandelbrot biomorph program by J.Sloman and A.Sloman Sept 1989


/*
;;; Compile file then try
bio(creal, cimaginary, power);
bio(0.5s0, 0.0s0, 3);	;;; very nice
bio(0.5s0, 1.0s0, 5);
bio(-0.5s0, -1.0s0, 5);
bio(-0.5s0, -1.0s0, 2);
bio(-0.8s0, -1.0s0, 2);
;;; To make it faster use a smaller window
e.g. rc_new_window(350,350,600,200,true);
*/




uses rc_graphic;


define lconstant procedure drawpoint(/*x,y*/);
	;;; Takes two numbers. Faster than rc_drawpoint
	lvars x, y;
	rc_transxyout() -> y -> x;
	;;; XpwDrawPoint will do the rounding
	XpwDrawPoint(rc_window,x,y);
enddefine;

define lconstant procedure raisetopower(zr,zi,n);
	lvars newzr,newzi,tempzr,zi,zr,n;
	;;; raise Zr+Zi to power n
	zr -> newzr;
	zi -> newzi;
	fast_repeat n  times
		newzr -> tempzr;
		(newzr*zr)-(newzi*zi) -> newzr;
		(newzi*zr)+(tempzr*zi) -> newzi;
	endrepeat;
	newzr,newzi
enddefine;


define bio(creal, cimaginary, power);
	lvars , zr, zi, power, creal, cimaginary, increment, x,y,
		;
	rc_start();
	rc_window_xsize >> 1 -> rc_xorigin;
	rc_window_ysize >> 1 -> rc_yorigin;
	round(rc_window_xsize/4.0) -> rc_xscale;
	-round(rc_window_ysize/4.0) -> rc_yscale;
	rc_jumpto(0,0);
	;;; mainly between about 2 and -2 on X and Y
	;;; X=real part of complex number
	;;; Y=imaginary part
	;;; Also C, complex numbers
	;;; Power for them to be raised to e.g. 3
	;;; Example values creal=.5 and cimaginary=0
	1.0/rc_xscale -> increment;
	power - 1 -> power; ;;; instead of doing it each time
	for x from -2 by increment to 2 do
		for y from -2 by increment to 2 do
			x -> zr; y -> zi;
			fast_repeat 10 times
				;;;(x+:yi)^power + creal -> (x+:yi)
				raisetopower(zr, zi, power)
					+ cimaginary -> zi; + creal -> zr;

			if(zr > 10.0s0) then goto POINT1
			elseif(zr < -10.0s0) then goto POINT1
			elseif(zi >  10.0s0) then goto POINT1
			elseif(zi < -10.0s0) then goto POINT1
			elseif((zr * zr + zi * zi) > 100.0s0)
			then nextloop(2)
			endif
			endrepeat;

POINT1:
			if abs(zr) < 10.0s0 then goto POINT
			elseif abs(zi) < 10.0s0 then goto POINT
			else nextloop
			endif;
/*
			if zr > 10.0s0 then goto POINT
			elseif zr < -10.0s0 then goto POINT
			elseif zi > 10.0s0 then goto POINT
			elseif zi < -10.0s0 then goto POINT
			else nextloop
			endif;
*/
			POINT:
				drawpoint(x,y);
		endfor
	endfor
enddefine;
