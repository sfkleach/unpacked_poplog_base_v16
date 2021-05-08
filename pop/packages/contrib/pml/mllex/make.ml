(* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:			contrib/pml/mllex/make.ml
 * Purpose:			Make the ML-Lex saved image
 * Author:			Robert John Duncan, Nov 23 1994
 * Documentation:	HELP * MLLEX
 *)

(*	
 *	To make the saved image, do:
 *		pml %nort <this-file>
 *)

output(std_out, "Making ML-Lex saved image ...\n");
Memory.hilim := Int.max (!Memory.hilim) 600000;
open NJCompat;
Compile.warnings := false;
load lexgen/lexgen.sml
external val clearenv : unit -> unit = $-ml$-clear_global_env;
if (clearenv();
	System.make {
        image="$poplocalbin/mllex.psv",
        lock=true,
        share=true,
        banner=false,
        init=false
    })
then
(	output(std_out, "ML-Lex\n");
	app (fn(file)=>
		(	output(std_out, file);
			output(std_out, ":\n");
			LexGen.lexGen(file)
		    handle
				Io(msg) =>
					output(std_out, "\n! "^msg^"\n")
			|	exn =>
                	output(std_out, "\n! Exception ("^makestring(exn)^")\n");
			output(std_out, "\n")
		))
		(OS.arglist());
	System.exit()
)
else
(	output(std_out, "Done\n");
	System.exit()
)
