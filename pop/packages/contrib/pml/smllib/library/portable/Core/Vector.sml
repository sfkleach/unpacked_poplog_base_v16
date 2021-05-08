loadLocalSig "VECTOR";

structure CoreVector: CORE_VECTOR =

(* CORE ARRAY FUNCTIONS

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           24 Jan 1991

Maintenance:    Author


DESCRIPTION

   A vector is implemented portably in terms of a list.  Most compilers
   will provide more efficient implementations.


RCS LOG

$Log:	Vector.sml,v $
Revision 1.1  91/01/25  11:29:58  11:29:58  db (Dave Berry)
Initial revision


*)

struct

  infix sub

  datatype 'a vector = Vector of 'a list

  exception Size

  exception Subscript

  val vector = Vector

  fun tabulate (i, f) =
        let fun tab j = if j < i then f j :: tab (j+1) else nil
        in if i < 0 then raise Size else Vector (tab 0)
        end

  fun op sub (Vector nil, i) = raise Subscript
  |   op sub (Vector (a::r), i) =
        if i > 0 then op sub (Vector r, i-1)
        else if i < 0 then raise Subscript
        else a

  fun length (Vector nil) = 0
  |   length (Vector (a::r)) = 1 + length (Vector r)

end

