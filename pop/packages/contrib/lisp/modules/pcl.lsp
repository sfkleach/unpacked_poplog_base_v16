;;; (Dummy) PCL module (for upward compatibilty only)
;;; Installed by John Williams, May 12 1995

(cl:provide :pcl)

(cl:progn
    (cl:write-line
        ";;; Note: PCL module no longer available (because CLOS is built-in)."
        cl:*debug-io*)
     (cl:values))       
