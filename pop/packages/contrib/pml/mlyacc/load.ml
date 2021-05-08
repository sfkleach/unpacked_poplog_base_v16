(* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:			contrib/pml/mlyacc/load.ml
 * Purpose:			Load ML-Yacc into an interactive system
 * Author:			Robert John Duncan, Nov 23 1994
 * Documentation:	HELP * MLYACC
 *)

Memory.hilim := Int.max (!Memory.hilim) 800000;
open NJCompat;
open Array; (* order is crucial here, because of overloading of length *)
open List;
fun print(s) = output(std_out,s);
Compile.localise Compile.warnings := false;
load mlyacc/smlyacc.sml
