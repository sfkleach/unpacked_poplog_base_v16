/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:			contrib/x/prolog/xpw/lib/xresources.pl
 > Purpose:			Provide the functions of XpwPixmap.p for Prolog
 > Author:			Andreas Schoter, August 1990 (see revisions)
 > Documentation:	REF * xresources PLOGHELP * xprolog
 > Related Files:	LIB * XpwBasics
*/

:- module xresources.

:- prolog_language(pop11).

;;; return to top level to declare globals
section;
global vars plxt_resource_name plxt_add_resources;
endsection;

lvars plxt_resource_names = newassoc(nil);

;;; add a list of new associations to the Prolog resource list
define plxt_add_resources(list);
	lvars list;
	lvars item1 item2 count;
	destlist(list) -> count;
	until count == 0 do
		-> item1;
		-> item2;
		item1 -> plxt_resource_names(item2);
		count fi_- 2 -> count;
	enduntil;
enddefine;

;;; get an X name string corresponding to a Prolog atom
define plxt_resource_name(name); /* -> namestring */
	lvars name;
	lvars namestring;
	unless plxt_resource_names(name) ->> namestring then
		mishap(name,1,'Unrecognised Resource Name');
	else
		namestring;
	endunless;
enddefine;

;;; add all stringdef resource names
plxt_add_resources(
		[	accelerators		'accelerators\^@'
			allow_horiz			'allowHoriz\^@'
			allow_vert			'allowVert\^@'
			ancestor_sensitive	'ancestorSensitive\^@'
			background			'background\^@'
			background_pixmap	'backgroundPixmap\^@'
			bitmap				'bitmap\^@'
			border_color		'borderColor\^@'
			border				'borderColor\^@'
			border_pixmap		'borderPixmap\^@'
			border_width		'borderWidth\^@'
			colormap			'colormap\^@'
			depth				'depth\^@'
			destroy_callback	'destroyCallback\^@'
			edit_type			'editType\^@'
			file				'file\^@'
			font				'font\^@'
			force_bars			'forceBars\^@'
			foreground			'foreground\^@'
			function			'function\^@'
			height				'height\^@'
			highlight			'highlight\^@'
			h_space				'hSpace\^@'
			index				'index\^@'
			inner_height		'innerHeight\^@'
			inner_width			'innerWidth\^@'
			inner_window		'innerWindow\^@'
			insert_position		'insertPosition\^@'
			internal_height		'internalHeight\^@'
			internal_width		'internalWidth\^@'
			jump_proc			'jumpProc\^@'
			justify				'justify\^@'
			knob_height			'knobHeight\^@'
			knob_indent			'knobIndent\^@'
			knob_pixel			'knobPixel\^@'
			knob_width			'knobWidth\^@'
			label				'label\^@'
			length				'length\^@'
			lower_right			'lowerRight\^@'
			mapped_when_managed	'mappedWhenManaged\^@'
			menu_entry			'menuEntry\^@'
			name				'name\^@'
			notify				'notify\^@'
			orientation			'orientation\^@'
			parameter			'parameter\^@'
			pixmap				'pixmap\^@'
			popup_callback		'popupCallback\^@'
			popdown_callback	'popdownCallback\^@'
			resize				'resize\^@'
			reverse_video		'reverseVideo\^@'
			screen				'screen\^@'
			scroll_proc			'scrollProc\^@'
			scroll_d_cursor		'scrollDCursor\^@'
			scroll_h_cursor		'scrollHCursor\^@'
			scroll_l_cursor		'scrollLCursor\^@'
			scroll_r_cursor		'scrollRCursor\^@'
			scroll_u_cursor		'scrollUCursor\^@'
			scroll_v_cursor		'scrollVCursor\^@'
			selection			'selection\^@'
			selection_array		'selectionArray\^@'
			sensitive			'sensitive\^@'
			shown				'shown\^@'
			space				'space\^@'
			string				'string\^@'
			text_options		'textOptions\^@'
			text_sink			'textSink\^@'
			text_source			'textSource\^@'
			thickness			'thickness\^@'
			thumb				'thumb\^@'
			thumb_proc			'thumbProc\^@'
			top					'top\^@'
			translations		'translations\^@'
			update				'update\^@'
			use_bottom			'useBottom\^@'
			use_right			'useRight\^@'
			value				'value\^@'
			v_space				'vSpace\^@'
			width				'width\^@'
			window				'window\^@'
			x					'x\^@'
			y					'y\^@'
		]);

:- prolog_language(prolog).

:- endmodule xresources.

/* --- Revision History ---------------------------------------------------
--- Andreas Schoter, Jul 29 1991
		Changed resource names back to strings - most Xt functions check for
		the argument being a string (i.e. XtAddCallbacks)
--- Jonathan Meyer, Sep 19 1990
		Changed resource strings to words.
 */
