(* BUILD FILE - MAKE VERSION

Created by:     Dave Berry, LFCS, University of Edinburgh
                db@lfcs.ed.ac.uk
Date:           18 Jan 1991

Maintenance:    Author

DESCRIPTION

   This file is a skeleton file.  The INSTALL script will use
   it to generate build_make.sml.  This involves replacing the
   string "$popcontrib/pml/smllib/library/signatures/" with the appropriate full path name.

   This file loads the make system and calls Make.loadFrom to
   consult the tag declarations in the other files of the library.
   If the resulting core image is saved, users then need only to
   call loadLibrary for the particular library entries they want.


NOTES

   Any system specific load file should be loading before using this
   file to build the library itself.  System specific files define
   loadStr, loadSig, etc., and resolve any name clashes with existing
   structures.


SEE ALSO

   build_all.sml, build_core.skel.


RCS LOG

$Log:	build_make.skel,v $
Revision 1.3  91/02/05  11:45:52  11:45:52  db (Dave Berry)
Added build_core.skel to SEE ALSO section.

Revision 1.2  91/01/30  19:07:59  19:07:59  db (Dave Berry)
Renamed loadFun and loadStr to loadEntry.

Revision 1.1  91/01/24  16:38:11  16:38:11  db (Dave Berry)
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

setLoadPrefix "Core/";
loadEntry "Vector";
loadEntry "Array";
loadEntry "Utils";

setLoadPrefix "";
loadEntry "MonoSet";

setLoadPrefix "Make/";
loadEntry "Make";


Make.loadFrom "ML_CONSULT";

fun loadEntry _ = ();
val loadLocalSig = loadEntry;
val loadSig = loadEntry;

setLoadSigPrefix "$popcontrib/pml/smllib/library/signatures/";

val loadLibrary = Make.make;
