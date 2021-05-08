;;; Load CLX (Common Lisp X windows interface)
;;; Note: CLX is Copyright (C) 1987 Texas Instruments Incorporated.
;;; John Williams, Nov 19 1990 updated feb 3 1995

(let ((*constant-functions* nil))		; T causes bugs in R5 CLX
	(load "$popcontrib/lisp/clx/clx.lsp"))

(pushnew
	'("$popcontrib/lisp/clx/teach/"
	 #.(pop11:consword "teach")
	 #.(pop11:consword "lisp_compile"))
	pop11:lispteachlist
	:test #'equal)
