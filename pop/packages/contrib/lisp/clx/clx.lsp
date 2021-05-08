;;; Top-level load file for CLX (Common Lisp X windows interface)
;;; Note: CLX is Copyright (C) 1987 Texas Instruments Incorporated.
;;; John Williams, Feb 3 1995

(in-package "COMMON-LISP")

(setq pop11:popmemlim 1500000)

(setq pop11:pop_record_writeable t)

(pop11)
  section $-lisp;
  if pop_internal_version < 145101 then
      ;;; bug in fast_prolog_arg inside lblock
      false -> f_inline(symbol_function(@SVREF))
  endif;
  endsection;
  lisp
(in-package "COMMON-LISP")

(load "$popcontrib/lisp/clx/src/socket.p")

(load "$popcontrib/lisp/clx/src/buffer_io.p")

(load "$popcontrib/lisp/clx/src/provide.l")
