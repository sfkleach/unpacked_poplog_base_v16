(* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:			contrib/pml/mlyacc/make.ml
 * Purpose:			Make the ML-Yacc saved image
 * Author:			Robert John Duncan, Nov 23 1994
 * Documentation:	HELP * MLYACC
 *)

(*	
 *	To make the saved image, do:
 *		pml %nort <this-file>
 *)

output(std_out, "Making ML-Yacc saved image ...\n");
Memory.hilim := Int.max (!Memory.hilim) 800000;
open NJCompat;
open Array; (* order is crucial here, because of overloading of length *)
open List;
fun print(s) = output(std_out,s);
Compile.warnings := false;
load mlyacc/smlyacc.sml
external val clearenv : unit -> unit = $-ml$-clear_global_env;
if (clearenv();
	System.make {
        image="$poplocalbin/mlyacc.psv",
        lock=true,
        share=true,
        banner=false,
        init=false
    })
then
(	output(std_out, "ML-Yacc\n");
	app (fn(file)=>
		(	output(std_out, file);
			output(std_out, ":\n");
			ParseGen.parseGen(file)
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
