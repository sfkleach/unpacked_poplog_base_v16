/* --- Copyright University of Sussex 1987.  All rights reserved. ---------
 > File:		$usepop/master/C.all/lib/pwm/conspwmitem.p
 > Purpose:		Stuff needed for PWM items
 > Author:		Ben Rubinstein, Mar 15 1987 (see revisions)
 > Documentation:  HELP PWMITEMS
 */

uses pwmitemhandler;
uses pwmgfxrasterop;

section $-library => conspwmitem remove_pwmitem ispwmitem
                             islivepwmitem pwmitem_valof pwmitem_area;
section $-library$-pwmlib => conspwmitem remove_pwmitem ispwmitem
                             islivepwmitem pwmitem_valof pwmitem_area;


;;; format of items to be used with this library:
recordclass pwmitem
		pi_name		;;; presumably a string: free format
		pi_window 	;;; a PWM window ID, as submitted to -pwmitemhandler-
		pi_value	;;; free format
		pi_event	;;;	\
		pi_button	;;;  }- as submitted to -pwmitemhandler-
		pi_area		;;; /
		pi_catch	;;;	procedure submitted to -pwmitemhandler- (SEE BELOW)
		pi_proc		;;; free format: presumbly the user proc. to be called
		;			;;;    when value is changed.


;;; NOTE format of catcher procedure: takes one formal argument (presumably
;;; any other args necessry have been frozen in): generally this will be the
;;; mouse event vector supplied by -pwmitemhandler-.  It may also be called
;;; by -pwmitem_valof-, however, and in this case the argument will be:
;;;
;;;		true: 	please return current value of item on stack
;;; 	false:	take a new value for the item  off the stack, and do
;;; 				whatever's necessary.



;;; make the constructor procedure available
global vars conspwmitem;

;;; and export a non-updating version of the area accessor
define global pwmitem_area(item);
	item.pi_area;
enddefine;

procedure(i);
	lvars i;
	sys_syspr('<pwmitem ');
	if i.pi_name then
		sys_syspr(i.pi_name);
	elseif i.pi_proc then
		sys_syspr(i.pi_proc);
	endif;
	cucharout(`>`);
endprocedure -> class_print(pwmitem_key);

;;; utility used by several items: draw a box, clearing any garbage under it
;;; (note that this doesn't dlocal ras-op)
define empty_box(x, y, w, h);
	PWM_SET -> pwmgfxrasterop;
	pwm_gfxwipearea(x, y, w, h);
	PWM_CLR -> pwmgfxrasterop;
	pwm_gfxwipearea(x fi_+ 1, y fi_+ 1, w fi_- 2, h fi_- 2);
enddefine;

define global remove_pwmitem(item);
	lvars item box;
	dlocal pwmgfxsurface, pwmgfxrasterop;

	unless item.pi_window then
		mishap(item, 1, 'ITEM HAS ALREADY BEEN REMOVED');
	endunless;

	;;; remove event trap
	false -> pwmitemhandler(item.pi_window, item.pi_event,
							item.pi_button, (item.pi_area ->> box));
	;;; clear that area of the window
	item.pi_window -> pwmgfxsurface;
	PWM_CLR -> pwmgfxrasterop;
	pwm_gfxwipearea(subscrv(1, box), subscrv(2, box),
						subscrv(3, box) - subscrv(1, box) + 1,
						subscrv(4, box) - subscrv(2, box) + 1);

	;;; now mark it as cancelled.
	false ->> item.pi_window ->> item.pi_value ->> item.pi_event
		->> item.pi_button ->> item.pi_area ->> item.pi_proc -> item.pi_catch;
enddefine;

define global pwmitem_valof(item);
	lvars item;
	if item.pi_window then
		(item.pi_catch)(true);
	else
		mishap(item, 1, 'ITEM HAS BEEN REMOVED');
	endif;
enddefine;

define updaterof global pwmitem_valof(v, item);
	lvars v item;
	if item.pi_window then
		(item.pi_catch)(v, false);
	else
		mishap(item, 1, 'ITEM HAS BEEN REMOVED');
	endif;
enddefine;

define islivepwmitem(item);
	ispwmitem(item)
	and
	ispwm_id(item.pi_window)
	and
	islivepwm_id(item.pi_window);
enddefine;

endsection;
endsection;

/* --- Revision History ---------------------------------------------------
--- Ben Rubinstein, Mar 25 1987 - added window to item record
*/
