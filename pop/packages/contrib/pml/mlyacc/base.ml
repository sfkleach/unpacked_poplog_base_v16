(* --- Copyright University of Sussex 1994. All rights reserved. ----------
 * File:			contrib/pml/mlyacc/base.ml
 * Purpose:			Loads the ML-Yacc parser
 * Author:			Robert John Duncan, Nov 23 1994
 * Documentation:	HELP * MLYACC
 *)

(* The parser needs SML/NJ compatibility *)
open NJCompat Array List;
fun print(s) = output(std_out,s);

load mlyacc/base.sml
