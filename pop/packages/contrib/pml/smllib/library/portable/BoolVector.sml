(*$BoolVector : Bool MonoVector *)

structure BoolVector = MonoVector (
  structure Element = Bool
);

(* BOOLEAN VECTORS

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           22 Sep 1989

Maintenance:    Author

RCS LOG

$Log:	BoolVector.sml,v $
Revision 1.2  91/02/11  19:56:07  19:56:07  db (Dave Berry)
Renamed Object to Element, since it isn't an OBJECT anymore.  This forms
part of the major reorganisation of the library.

Revision 1.1  90/12/20  14:50:20  14:50:20  db (Dave Berry)
Initial revision


*)

