/* --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:            $popcontrib/x/demos/rc_chaos.p
 > Purpose:         Demonstration of chaotic behaviour of non-linear function
 > Author:          Aaron Sloman, May 18 1990
 > Documentation:	See below
 > Related Files:	LIB * RC_GRAPHIC LIB * RC_DRAWGRAPH
 */


;;; An interactive program for experimenting with attractors, etc
;;; Aaron Sloman - School of Cognitive and Computing Sciences
;;; Susssex University
;;; See test cases in comment at end. Search for "TEST"

;;; Load the file then run chaosinteract();

;;; ----------------------------------------------------------------

uses rc_graphic.p
uses rc_drawgraph

;;; Some file-local lexicals, used by procedure morechaos to continue
;;; running "chaos". This is a bodge. Should have used a lexical
;;; closure, or the process mechanism!

lvars last_incr, last_fun, last_startx, last_num;

global vars procedure morechaos;	;;; defined below


define chaos(incr, procedure fun, startx, num);
	;;; incr and fun as above plus a start value for x:  startx
	;;; and a number of iterations to do: num
	;;; Repeatedly apply the procedure fun, using its last output
	;;; as new input, and draw the behaviour on the screen.

	lvars startx, procedure fun, num, miny, maxy;

	;;; save values for morechaos, defined below. last_startx set at end.
	incr -> last_incr;
	fun -> last_fun,
	num -> last_num;

	unless iscaller(morechaos) then
		;;; Do this only when first called, using runchaos
		;;; set origin and scale
		rc_window_ysize -> rc_yorigin;
		0 -> rc_xorigin;
		rc_window_xsize -> rc_xscale;
		-rc_window_ysize -> rc_yscale;

		;;; draw a graph of the procedure fun
		rc_drawgraph(0,1,0,1,incr,incr,incr,incr,incr,fun)
			-> miny -> maxy;

		if maxy > 1 then
			;;; went too high
			'Redrawing with different scale' =>
			rc_window_ysize/(maxy + 0.1) -> rc_yscale;
			rc_drawgraph(0,1,0,1,incr,incr,incr,incr,incr,fun);
		endif;
		;;; draw the line y = x
		rc_drawline(0,0,1,1);
	endunless;

	;;; draw n lines showing xi = fun(xi-1)
	rc_jumpto(startx,0);
	fast_repeat num times
		;;; draw vertical line to next position on the graph for fun
		rc_drawto(rc_xposition,fun(rc_xposition));
		;;; draw horizontal line to the line y = x
		rc_drawto(rc_yposition,rc_yposition);
		if rc_xposition < 0 then
			'GONE NEGATIVE' =>
			rc_xposition =>
			return
		endif;
	endrepeat;
	rc_xposition -> last_startx;
enddefine;

define morechaos();
	;;; Continue running chaos from where it last left off
	chaos(last_incr,last_fun,last_startx,last_num);
enddefine;


define runchaos(fun,n);
	;;; Run the chaos procedure (with fun as argument fun) n times
	;;; with different starting points
	lvars x, procedure fun, n, char;
	rc_window_xsize -> rc_xscale;
	rc_window_ysize -> rc_yscale;
	rc_window_ysize -> rc_yorigin;
	rc_clear_window();
	rc_jumpto(0,0);square(1);
	for x from 0 by 0.05 to 1 do
		chaos(0.05,fun,x,n);
		rc_print_at(0.1,0.9,'PRESS KEY TO CONTINUE');
		repeat
			'press a key' =>
			rawcharin() -> char;
			if char = `\r` then
				rc_clear_window();
				rc_jumpto(0,0);square(1);
				quitloop()
			elseif char = `r` then rc_clear_window();
			elseif char == `q` then quitloop(2)
			elseif isnumbercode(char) then
				;;; do it again, but more times (n * char)
				char - `0` -> char;
				repeat char times morechaos() endrepeat;
			else quitloop()
			endif
		endrepeat
	endfor;
	rc_print_at(0.1,0.9,'========THAT\'S ALL==========');
enddefine;


define testproc(x, r);
	;;; a test procedure - for drawing a parabola
	;;; y = r*x*(1 - x)
	lvars x,r;
	r*x*(1 - x)
enddefine;

define testproc2(x, r);
	;;; sin function, mapping interval [0-1] to [0-180]
	;;; y = r * sin(x*180)
	lvars x, r;
	dlocal popradians = false;	;;; x is in degrees

	r*sin(x*180.0)
enddefine;


define chaosinteract();
	;;; Run the chaos procedure interactively using testproc
	;;; as defined above
	lvars x_value = 0.5, r_value = 2.5, n=1, char, answer, incr = 0.05;
	vars x;
	rc_window_xsize -> rc_xscale;
	rc_window_ysize -> rc_yscale;
	rc_window_ysize -> rc_yorigin;
	rc_start();
	repeat
		getline('Clear_screen? y/n') -> answer;
		if answer = [y] then
			rc_clear_window()
		endif;
		repeat
			'Current R is ' >< r_value =>
			getline('Value for R? (type number, or "inc number" or RETURN to use old value)') -> answer;
			if answer == [] then
			elseif isnumber(front(answer)) then front(answer) -> r_value
			elseif answer matches [inc ?x:isnumber] then
				r_value + x -> r_value
			else
				'Inappropriate value for R: ' >< front(answer) =>
				nextloop();
			endif;
			quitloop();
		endrepeat;
		repeat
			'Current X seed is ' >< x_value =>
			getline('Value for X? (type number >= 0 <= 1, or RETURN to use old value)') -> answer;
			if answer == [] then
			elseif isnumber(front(answer))
			and (front(answer) -> x; x >= 0) and x <= 1 then
				front(answer) -> x_value
			elseif answer matches [inc ?x:isnumber] then
				x_value + x -> x_value
			else
				'Inappropriate value for X: ' >< front(answer) =>
				nextloop();
			endif;
			quitloop()
		endrepeat;

		repeat
			'Current number of cycles is: ' >< n =>
			getline('How many? (type number or RETURN to use old value)') -> answer;
			if answer == [] then
			elseif isinteger(front(answer)) then
				front(answer) -> n
			else
				'Inappropriate value for X: ' >< front(answer) =>
				nextloop();
			endif;
			quitloop()
		endrepeat;

		printf(n, x_value, r_value, '\n** Starting: R = %p, X = %p, to be done %p times\n');
		chaos(incr, testproc(%r_value%), x_value, n);
		repeat
			'Press RETURN to continue, q to quit,  r to re-start, c to clear window' =>
			'Press a number to continue that number more cycles' =>
			readline() -> answer;
			if answer == [] then
				morechaos(); nextloop();
			else front(answer) -> answer
			endif;
			if answer = "r" then quitloop()
			elseif answer = "c" then
				rc_clear_window();
				rc_drawgraph(0,1,0,1,incr,incr,incr,incr,incr,testproc(%r_value%));
				;;; draw the line y = x
				rc_drawline(0,0,1,1);
			elseif answer == "q" then quitloop(2)
			elseif isinteger(answer) then
				;;; do it again, but more times (n * answer)
				repeat answer times morechaos() endrepeat;
			else quitloop()
			endif
		endrepeat
	endrepeat;
	'========THAT\'S ALL==========' =>
enddefine;

/*
;;; TEST commands - mark and load in the editor

;;;This lets you experiment with different values of R, different starting
;;;values for x and different numbers of cycles.

chaosinteract();

;;; There follow lots of examples with comments
;;; I don't know to what extent the behaviour depends on the fact
;;; that I tested these with popdprecision set to false, i.e. using
;;; only single precision decimal arithmetic.

;;; Each group of examples uses the same function and the same r, with a
;;; different starting point for x and possibly different numbers of
;;; repetitions.

rc_clear_window();
;;; converges to 0.6
chaos(0.05,testproc(%2.5%),0.5,11);
chaos(0.05,testproc(%2.5%),0.8,61); rc_xposition
chaos(0.05,testproc(%2.5%),0.1,61); rc_xposition
chaos(0.05,testproc(%2.5%),0.01,61); rc_xposition
morechaos(); rc_xposition

rc_clear_window();
;;; tiny attractor approached VERY slowly
;;; 0.669612 0.663695
chaos(0.05,testproc(%3.0%),0.5,561); rc_xposition
chaos(0.05,testproc(%3.0%),0.8,561); rc_xposition
chaos(0.05,testproc(%3.0%),0.21,561); rc_xposition
morechaos(); rc_xposition


rc_clear_window();
;;; work out to attractor 0.558014 0.764566
chaos(0.05,testproc(%3.1%),0.6666,61); rc_xposition
;;; work in to attractor
chaos(0.05,testproc(%3.1%),0.5,61); rc_xposition
morechaos(); rc_xposition

rc_clear_window();
;;;  0.833417
chaos(0.05,testproc(%3.35%),0.3,61);  rc_xposition
chaos(0.05,testproc(%3.35%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.35%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.35%),0.9,61); rc_xposition
morechaos(); rc_xposition


rc_clear_window();
;;;; converges slowly
;;; 0.847412 0.446103 0.852478 0.433869
chaos(0.05,testproc(%3.45%),0.3,61);  rc_xposition
chaos(0.05,testproc(%3.45%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.45%),0.702,261); rc_xposition
chaos(0.05,testproc(%3.45%),0.9,261); rc_xposition
morechaos(); spr(rc_xposition)



rc_clear_window();
;;; converges quickly
;;; 0.826941 0.500884 0.874997 0.382819
chaos(0.05,testproc(%3.50%),0.3,61);  rc_xposition
chaos(0.05,testproc(%3.50%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.50%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.50%),0.9,61); rc_xposition
morechaos(); spr(rc_xposition)


rc_clear_window();
;;; converges quickly to 8 positions
0.887371 0.370326 0.812656 0.506029 0.881684 0.3548 0.827806 0.540474 0.887371
chaos(0.05,testproc(%3.55%),0.3,5);  rc_xposition
chaos(0.05,testproc(%3.55%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.55%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.55%),0.9,61); rc_xposition
chaos(0.05,testproc(%3.55%),0.1,61); rc_xposition
repeat 50 times morechaos(); endrepeat;

rc_clear_window();
;;; converges quickly to stable orbit with 16 positions
chaos(0.05,testproc(%3.565%),0.3,61);  rc_xposition
chaos(0.05,testproc(%3.565%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.565%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.565%),0.9,61); rc_xposition
morechaos(); spr(rc_xposition)


rc_clear_window();
;;; converges quickly to stable orbit with 32 positions
0.841069  etc
chaos(0.05,testproc(%3.569%),0.3,61);  rc_xposition
chaos(0.05,testproc(%3.569%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.569%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.569%),0.9,61); rc_xposition
chaos(0.05,testproc(%3.569%),0.1,61); rc_xposition
morechaos(); spr(rc_xposition)

rc_clear_window();
;;; converges quickly to stable orbit with 64 positions
0.892216 etc
chaos(0.05,testproc(%3.5698%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.5698%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.5698%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.5698%),0.9,11); rc_xposition
chaos(0.05,testproc(%3.5698%),0.1,11); rc_xposition
repeat 64 times morechaos(); spr(rc_xposition) endrepeat


rc_clear_window();
;;; converges quickly to stable orbit with several hundred positions
chaos(0.05,testproc(%3.575%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.575%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.575%),0.702,61); rc_xposition
chaos(0.05,testproc(%3.575%),0.9,61); rc_xposition
repeat 64 times morechaos(); spr(rc_xposition) endrepeat

rc_clear_window();
;;; converges quickly to stable orbit with many hundreds of positions ?
chaos(0.05,testproc(%3.60%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.60%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.60%),0.702,261); rc_xposition
chaos(0.05,testproc(%3.60%),0.9,61); rc_xposition
morechaos(); spr(rc_xposition)
repeat 64 times morechaos(); spr(rc_xposition) endrepeat


rc_clear_window();
;;; converges quickly to stable orbit with many hundreds of positions ?
chaos(0.05,testproc(%3.62%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.62%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.62%),0.702,261); rc_xposition
chaos(0.05,testproc(%3.62%),0.9,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat


rc_clear_window();
;;; Lots of orbits, but no longer space filling? L-shaped box emerging
chaos(0.05,testproc(%3.810%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.810%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.810%),0.739,11); rc_xposition
chaos(0.05,testproc(%3.810%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat

rc_clear_window();
;;; Lots of orbits, but no longer space filling. L-shaped box
chaos(0.05,testproc(%3.825%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.825%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.825%),0.739,11); rc_xposition
chaos(0.05,testproc(%3.825%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat


rc_clear_window();
;;; Lots of orbits, but not space filling. L-shaped box clear
chaos(0.05,testproc(%3.827%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.827%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.827%),0.739,11); rc_xposition
chaos(0.05,testproc(%3.827%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat



rc_clear_window();
;;; L shaped block with perturbations
chaos(0.05,testproc(%3.8283%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.8283%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.8283%),0.82832,11); rc_xposition
chaos(0.05,testproc(%3.8283%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat

rc_clear_window();
;;; L shaped block with perturbations
chaos(0.05,testproc(%3.82837%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.82837%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.82837%),0.828372,11); rc_xposition
chaos(0.05,testproc(%3.82837%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat

rc_clear_window();
;;; NB looks stable, then eventually unfolds again
chaos(0.05,testproc(%3.828426%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.828426%),0.55,11); rc_xposition
chaos(0.05,testproc(%3.828426%),0.8284262,11); rc_xposition
chaos(0.05,testproc(%3.828426%),0.01,11); rc_xposition
morechaos(); rc_xposition
repeat 64 times morechaos(); endrepeat

rc_clear_window();
;;; eventually converges to L shaped 3 position orbit
chaos(0.05,testproc(%3.828427%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.828427%),0.55,11); rc_xposition
chaos(0.05,testproc(%3.828427%),0.828,11); rc_xposition
chaos(0.05,testproc(%3.828427%),0.01,11); rc_xposition
morechaos(); rc_xposition
repeat 64 times morechaos(); endrepeat



rc_clear_window();
;;; One orbit with three positions
chaos(0.05,testproc(%3.829%),0.3,11);  rc_xposition
chaos(0.05,testproc(%3.829%),0.5,61); rc_xposition
chaos(0.05,testproc(%3.829%),0.739,11); rc_xposition
chaos(0.05,testproc(%3.829%),0.1,61); rc_xposition
morechaos();
repeat 64 times morechaos(); endrepeat


rc_clear_window();
0.0 0.0 0.663478 0.954581 0.527415
chaos(0.05,testproc(%4.0%),0.3,61); rc_xposition   ;;;chaotic
;;; this seems to hit an attractor
chaos(0.05,testproc(%4.0%),0.5,61);
;;; this is very chaotic
chaos(0.05,testproc(%3.999999%),0.5,61);
;;; this goes negative and stops
chaos(0.05,testproc(%4.000001%),0.5,61);
;;; this eventually gets to 0,0
chaos(0.05,testproc(%4.000001%),0.6,61);
;;; so does this
chaos(0.05,testproc(%4.000001%),0.1,61);
repeat 64 times morechaos(); spr(rc_xposition); endrepeat;


rc_clear_window();
;;; this one sticks at 0.75, 0.75
chaos(0.05,testproc(%4.0%),0.75,61); rc_xposition
chaos(0.05,testproc(%4.0%),0.750001,61);
morechaos(); rc_xposition

;;; These go negative
chaos(0.05,testproc(%4.5%),0.9,61);
chaos(0.05,testproc(%4.5%),0.75,61);
chaos(0.05,testproc(%4.5%),0.77,61);
chaos(0.05,testproc(%4.5%),0.77556,61);
chaos(0.05,testproc(%4.5%),0.29999999,61);
chaos(0.05,testproc(%4.5%),0.0419999,61);


;;;NOW THE SIN FUNCTION testproc2
rc_clear_window();
morechaos();
;;; converges on the intersection
chaos(0.05,testproc2(%0.6%),0.5,61);
chaos(0.05,testproc2(%0.6%),0.01,61);
chaos(0.05,testproc2(%0.6%),0.99,61);

rc_clear_window();
morechaos();
;;; converges on the intersection
chaos(0.05,testproc2(%0.7%),0.5,61);
chaos(0.05,testproc2(%0.7%),0.01,61);
chaos(0.05,testproc2(%0.7%),0.99,61);


rc_clear_window();
morechaos();
;;; converges on an attractor - from inside or from outside only (?)
chaos(0.05,testproc2(%0.73%),0.5,61);
chaos(0.05,testproc2(%0.73%),0.01,61);
chaos(0.05,testproc2(%0.73%),0.68,61);

rc_clear_window();
morechaos(); rc_xposition
;;; attractor approached from both directions
chaos(0.05,testproc2(%0.8%),0.1,61);
chaos(0.05,testproc2(%0.8%),0.6,61);
chaos(0.05,testproc2(%0.8%),0.95,61);



rc_clear_window()
morechaos();
;;; converges on an attractor - from both directions
chaos(0.05,testproc2(%0.815%),0.49,61);
chaos(0.05,testproc2(%0.815%),0.01,61);
chaos(0.05,testproc2(%0.815%),0.68,61);


rc_clear_window()
morechaos();
;;; converges on an attractor - from both directions
chaos(0.05,testproc2(%0.83%),0.49,61);
chaos(0.05,testproc2(%0.83%),0.01,61);
chaos(0.05,testproc2(%0.83%),0.68,61);
chaos(0.05,testproc2(%0.83%),0.99,61);

rc_clear_window();
morechaos(); rc_xposition
;;; These ones SLOWLY approach two close attractors, from inside and outside
;;; 446681 446662 81936 819369
chaos(0.05,testproc2(%0.831%),0.1,61);
chaos(0.05,testproc2(%0.831%),0.6,61);
chaos(0.05,testproc2(%0.831%),0.95,61);
chaos(0.05,testproc2(%0.831%),0.446681,61);


rc_clear_window()
morechaos();rc_xposition
;;; converges VERY slowly on one position
;;; x = 0.445223 (and its image)
chaos(0.05,testproc2(%0.8328%),0.49,61);
chaos(0.05,testproc2(%0.8328%),0.01,61);
chaos(0.05,testproc2(%0.8328%),0.68,61);
chaos(0.05,testproc2(%0.8328%),0.445223,61);  rc_xposition


rc_clear_window()
morechaos(); rc_xposition
;;; converges SLOWLY on TWO attractors 0.444919 0.445107 0.82056 0.820644
chaos(0.05,testproc2(%0.833%),0.49,261);
chaos(0.05,testproc2(%0.833%),0.01,261);
chaos(0.05,testproc2(%0.833%),0.68,261);
chaos(0.05,testproc2(%0.833%),0.444919,261);  rc_xposition

rc_clear_window()
morechaos(); rc_xposition
;;; converges  on two attractors 0.407069 0.484182 0.804454 0.838963
;;; ??? or is it FOUR close together ???
chaos(0.05,testproc2(%0.84%),0.49,61); rc_xposition
chaos(0.05,testproc2(%0.84%),0.01,61); rc_xposition
chaos(0.05,testproc2(%0.84%),0.68,61);
chaos(0.05,testproc2(%0.84%),0.407069,61); rc_xposition


rc_clear_window()
morechaos(); rc_xposition =>
** 0.799863 ** 0.395491 ** 0.844962 ** 0.496972
;;; converges  on two attractors
chaos(0.05,testproc2(%0.845%),0.49,61); rc_xposition
chaos(0.05,testproc2(%0.845%),0.01,61); rc_xposition
chaos(0.05,testproc2(%0.845%),0.68,61); rc_xposition


rc_clear_window();
morechaos();  rc_xposition
;;; 8 positions. Converges quickly
repeat 64 times morechaos();  endrepeat;
chaos(0.05,testproc2(%0.86%),0.311,11);
chaos(0.05,testproc2(%0.86%),0.56,11);
chaos(0.05,testproc2(%0.86%),0.86,11);
chaos(0.05,testproc2(%0.86%),0.1,11);


rc_clear_window();
morechaos();  rc_xposition
;;; 16 positions ? converges quickly
repeat 64 times morechaos();  endrepeat;
chaos(0.05,testproc2(%0.865%),0.311,11);
chaos(0.05,testproc2(%0.865%),0.56,11);
chaos(0.05,testproc2(%0.865%),0.865,11);
chaos(0.05,testproc2(%0.865%),0.13,11);


rc_clear_window();
morechaos();  rc_xposition
;;; 8 positions
repeat 64 times morechaos();  endrepeat;
chaos(0.05,testproc2(%0.868%),0.311,11);
chaos(0.05,testproc2(%0.868%),0.56,11);
chaos(0.05,testproc2(%0.868%),0.868,11);
chaos(0.05,testproc2(%0.868%),0.013,11);


rc_clear_window();
morechaos();  rc_xposition
repeat 64 times morechaos();  endrepeat;
;;; L-shaped box. Large number of locations
chaos(0.05,testproc2(%0.95%),0.311,11);
chaos(0.05,testproc2(%0.95%),0.56,11);
chaos(0.05,testproc2(%0.95%),0.99,11);
chaos(0.05,testproc2(%0.95%),0.1,11);


rc_clear_window();
morechaos();  rc_xposition
repeat 64 times morechaos();  endrepeat;
;;;fills space. Looks totally chaotic
chaos(0.05,testproc2(%1.00%),0.311,11);
chaos(0.05,testproc2(%1.00%),0.56,11);
;;; Next one very close to intersection. stable
chaos(0.05,testproc2(%1.00%),0.7364844482415167,11);
;;; Next one just off intersection. Only diverges with popdprecision true
chaos(0.05,testproc2(%1.00%),0.7364844482415168,11);
chaos(0.05,testproc2(%1.00%),0.1,11);
;;; Next one takes a while to get anwhere (Depends on rounding errors)
chaos(0.05,testproc2(%1.00%),1.00,11);


*/
