;;; (Dummy) MIT-LOOP module (for upward compatibilty only)
;;; Installed by John Williams, May 12 1995

(cl:provide :mit-loop)

(cl:progn
    (cl:write-line
        ";;; Note: MIT-LOOP module no longer available (because LOOP built-in)."
        cl:*debug-io*)
     (cl:values))       
