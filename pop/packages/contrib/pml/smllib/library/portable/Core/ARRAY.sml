signature CORE_ARRAY =

(* CORE ARRAY FUNCTIONS

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           24 Jan 1991

Maintenance:    Author


DESCRIPTION

   This is the implementation of arrays agreed between the implementors
   of SML/NJ, Poly/ML and Poplog ML in Autumn 1990.  The main library
   adds more functionality.


RCS LOG

$Log$

*)

sig

  eqtype 'a array

  exception Size

  exception Subscript

  val array: int * '_a -> '_a array

  val arrayoflist: '_a list -> '_a array

  val tabulate: int * (int -> '_a) -> '_a array

  val sub: 'a array * int -> 'a

  val update: 'a array * int * 'a -> unit

  val length: 'a array -> int
end
