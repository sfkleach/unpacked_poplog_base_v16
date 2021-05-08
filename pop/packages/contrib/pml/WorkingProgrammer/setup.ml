(* --- Copyright University of Sussex 1991. All rights reserved. ----------
 * File:            contrib/pml/WorkingProgrammer/setup.ml
 * Purpose:         Setup Poplog ML to compile examples from
 *                  "ML for the Working Programmer"
 * Author:          Robert John Duncan, Jan 14 1991 (see revisions)
 * Documentation:   HELP * WORKING_PROGRAMMER
 * Related Files:   contrib/pml/WorkingProgrammer/src/*.ML
 *)


(* Export the -use- function *)
val use = Compile.use;

(* Add the source directory to the compiler's searchpath *)
val _ =
	let	val srcdir = "$popcontrib/pml/WorkingProgrammer/src/"
	in	if List.member srcdir (!Compile.searchpath) then
			()
		else
			Compile.searchpath := srcdir :: !Compile.searchpath
	end;

(* Make ".ML" the file type, to enable SHOWLIB, LMR etc. *)
val _ = Compile.filetype := ".ML";

(* Turn off closure rules *)
val _ = Compile.closure_rules := false;

(* Ensure at least 350000 words free to compile everything *)
val _ =
	Memory.hilim := (
		Memory.gc();
		Int.max (!Memory.hilim) (Memory.usage+350000)
	);


(* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Jun 14 1991
		Tidied up.
--- Robert John Duncan, Apr 25 1991
		Deleted exceptions hack: no longer necessary.
 *)
