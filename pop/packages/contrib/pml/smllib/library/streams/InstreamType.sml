(*$InstreamType : INSTREAM_TYPE Instream *)

loadEntry "Instream";
loadSig "INSTREAM_TYPE";
structure Types: INSTREAM_TYPE = Instream;
open Types;
structure Types = struct end;

(* INSTREAM TYPE

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           22 Sep 1989

Maintenance:    Author

RCS LOG

$Log:	InstreamType.sml,v $
Revision 1.4  91/02/04  16:56:05  16:56:05  db (Dave Berry)
This signature now defines all the pervasives on instreams.  So an
implementation of this signature can replace the pervasives if necessary.

Revision 1.3  91/01/30  19:01:20  19:01:20  db (Dave Berry)
Renamed loadFun and loadStr to loadEntry.

Revision 1.2  91/01/25  20:17:18  20:17:18  db (Dave Berry)
Changed signature names to all upper case.
Amended tag declarations to match above change.

Revision 1.1  90/12/20  14:53:46  14:53:46  db (Dave Berry)
Initial revision


*)

