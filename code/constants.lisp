(in-package :project)

(defconstant +asset-folder+ #p"assets/")
(defconstant +shader-folder+ #p"shaders/")

(alexandria:define-constant +world-up+ (gficl:make-vec'(0 1 0))
			    :test #'(lambda (x y) (gficl:=vec x y)))