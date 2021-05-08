(* --- Copyright University of Sussex 1991. All rights reserved. ----------
 * File:            contrib/pml/smllib/load.ml
 * Purpose:         Load the Edinburgh Standard ML Library
 * Author:          Robert John Duncan, Oct 29 1990 (see revisions)
 *)

(*
 *	Library revision number (from CHANGES log)
 *)

val version = "Edinburgh Standard ML Library (Revision 1.17)";

(*
 *	Allow an extra 400k words for compiling everything
 *)

val memlim = (
		PML.System.Memory.gc();
		PML.Int.max
			(PML.System.Memory.usage+400000)
			(!PML.System.Memory.hilim)
	);

(*
 *	Guard closure_rules against the change made in "poplog.load"
 *)

val _ = PML.System.Compile.localise PML.System.Compile.closure_rules;

(*
 *	Load Poplog specific file
 *)

val _ = PML.System.Compile.use "library/poplog/poplog.load";

(*
 *	Reset Memory.hilim to something reasonable
 *)

val _ = PML.System.Memory.hilim := memlim;

(*
 *	Now load the library
 *)

val _ = PML.System.Compile.use "library/poplog/build_all.sml";

(*
 *	Update the version message
 *)

val _ =
	if not(PML.List.member version (!PML.System.version)) then
		PML.System.version := !PML.System.version @ [version]
	else
		();

(*
 *	Allow at least 100k working memory
 *)

val _ =
	PML.System.Memory.hilim := (
		PML.System.Memory.gc();
		PML.Int.max
			(PML.System.Memory.usage+100000)
			(!PML.System.Memory.hilim)
	);


(* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Jul 25 1991
		Revision 1.17: minor patches
--- Robert John Duncan, Jun 14 1991
		Changed for Revision 1.16. Renamed "smllib".
--- Robert John Duncan, Apr 25 1991
		Revised for new version of the library
 *)
