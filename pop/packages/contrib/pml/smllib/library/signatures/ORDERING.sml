(*$ORDERING *)

signature ORDERING =
sig

(* A TYPE WITH AN ORDERING FUNCTION

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           5 Feb 1991

Maintenance:    Author


DESCRIPTION

   This signature defines a type T and an ordering function.


SEE ALSO

   EQUALITY, PRINT, EQ_ORD, EQTYPE_ORD, OBJECT.


RCS LOG

$Log:	ORDERING.sml,v $
Revision 1.1  91/02/11  18:54:54  18:54:54  db (Dave Berry)
Initial revision



*)


(* TYPES *)

  type T


(* OBSERVERS *)

  val lt: T -> T -> bool
   (* lt x y; returns true if x is less than y; returns false otherwise. *)

end;

