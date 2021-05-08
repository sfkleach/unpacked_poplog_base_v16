(* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:			contrib/pml/mllex/load.ml
 * Purpose:			Load ML-Lex into an interactive system
 * Author:			Robert John Duncan, Nov 23 1994
 * Documentation:	HELP * MLLEX
 *)

Memory.hilim := Int.max (!Memory.hilim) 600000;
open NJCompat;
Compile.localise Compile.warnings := false;
load lexgen/lexgen.sml
