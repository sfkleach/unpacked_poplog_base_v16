(* BUILD FILE - CORE VERSION

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           4 Feb 1989

Maintenance:    Author


DESCRIPTION

   This file builds the core of the library.  Users are responsible
   for loading other entries in the correct order.


NOTES

   Any system specific load file should be loaded before using this
   file to build the library itself.  System specific files define
   loadEntry, loadSig, etc., and resolve any name clashes with existing
   structures.


SEE ALSO

   build_make.skel, build_all.sml.


RCS LOG

$Log:	build_core.skel,v $
Revision 1.2  91/02/11  21:01:41  21:01:41  db (Dave Berry)
Added calls to load the generic signatures.

Revision 1.1  91/02/05  11:44:53  11:44:53  db (Dave Berry)
Initial revision


*)

local
  fun subst _ _ [] = []
  |   subst p a (h::t) =
    if p h then a :: subst p a t
    else h :: subst p a t

  val loadPrefix = ref "";
  val loadSigPrefix = ref "../signatures/";
in
  fun loadEntry s =
    let val l = subst (fn x => x = "'") "_" (explode s)
    in NonStandard.use (!loadPrefix ^ implode l ^ ".sml")
    end

  fun loadSig s =
    let val l = subst (fn x => x = "'") "_" (explode s)
    in NonStandard.use (!loadSigPrefix ^ implode l ^ ".sml")
    end

  fun loadLocalSig s =
    let val l = subst (fn x => x = "'") "_" (explode s)
    in NonStandard.use (!loadPrefix ^ implode l ^ ".sml")
    end

  fun setLoadPrefix s = (loadPrefix := s)

  fun setLoadSigPrefix s = (loadSigPrefix := s)
end;

(* If OutstreamType is loaded before Make then it should also be loaded
   before the Core files.  This is because Make uses NonStandard.flush_out,
   which must be defined on the outstream type in scope in the body of Make. *)

loadEntry "GeneralTypes";
loadEntry "InstreamType";
loadEntry "OutstreamType";

setLoadPrefix "Core/";
loadEntry "Vector";
loadEntry "Array";
loadEntry "Utils";
setLoadPrefix "";

setLoadSigPrefix "$popcontrib/pml/smllib/library/signatures/";

loadSig "EQUALITY";
loadSig "ORDERING";
loadSig "EQ_ORD";
loadSig "PRINT";
loadSig "OBJECT";
loadSig "PARSE";
loadSig "SEQ_PARSE";
loadSig "EQ_PRINT";
loadSig "SEQUENCE";
loadSig "SEQ_ORD";
loadSig "MONO_SEQ_PARSE";
loadSig "ORD_PRINT";
loadSig "EQTYPE_ORD";
loadSig "EQTYPE_PRINT";

val loadLibrary = loadEntry;
