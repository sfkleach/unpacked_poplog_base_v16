$! Create CLISP +CLX saved image
$
$ clisp \%nort \%noinit

(setq *making-saved-image* t)

(require :contrib)
(time (require :clx))
(use-package :xlib)

(if (savelisp "poplocalbin:clx.psv" :init t :lock t)
    (progn
        (write-line "CLX for X11R5")
        (setlisp)))

$
$ purge poplocalbin:clx.psv
