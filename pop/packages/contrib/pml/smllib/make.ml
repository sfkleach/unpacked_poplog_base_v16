(* --- Copyright University of Sussex 1992. All rights reserved. ----------
 * File:            contrib/pml/smllib/make.ml
 * Purpose:         Make a saved image of the Edinburgh Standard ML Library
 * Author:          Robert John Duncan, Oct 29 1990 (see revisions)
 *)


(*
	To make a saved image in POPLOCALBIN containing the complete
	Edinburgh Standard ML Library, run the command

		pml %nort -noinit -nostdin -load <this-file>

	To run the image, do

		pml +smllib

 *)

val _ = (
		StdIO.output(StdIO.std_out, "Making SML library image ... ");
		StdIO.flush_out StdIO.std_out
	);

load load

val _ =
	if PML.System.make {
			image="$poplocalbin/smllib.psv",
			lock=true,
			share=true,
			banner=false,
			init=false
		}
	then
		PML.System.restart()
	else
		(StdIO.output(StdIO.std_out, "done\n");
		 PML.System.exit());

(* --- Revision History ---------------------------------------------------
--- Robert John Duncan, May 14 1992
		Added %nort to the recommended build command.
--- Robert John Duncan, Jun 14 1991
		Changed for Revision 1.16. Renamed "smllib".
--- Robert John Duncan, Apr 25 1991
		Revised for new version of the library
 *)
