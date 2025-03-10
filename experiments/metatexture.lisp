(in-package :experiments)

;;; Colour Pass

(defclass mt-colour-pass (pass) ())

(defun make-mt-colour-pass ()
  (make-instance
   'mt-colour-pass
   :shaders (list (make-instance 'cel-shader))
   :description
   (make-framebuffer-description
    (list (gficl:make-attachment-description :type :texture)
	  (gficl:make-attachment-description :position :depth-attachment))
    :samples 16)))

;;; Metatexture Pass

(defclass metatexture-shader (normals-shader) ())

(defmethod reload ((s metatexture-shader))
  (shader-reload-files (s (#p"metatexture.vs" #p"metatexture.fs")
			  :folder (shader-subfolder #p"metatexture/"))
		       shader
    (gl:uniformi (gficl:shader-loc shader "tex") 0)
    (gficl:bind-vec shader "tex_dim"
		    (list (getf (cdr (get-asset 'metatexture-noise)) :width)
			  (getf (cdr (get-asset 'metatexture-noise)) :height)))))

(defmethod draw ((obj metatexture-shader) scene)
  (gl:enable :depth-test :cull-face)
  (gl:active-texture :texture0)
  (gficl:bind-gl (car (get-asset 'metatexture-noise)))
  (call-next-method))

(defclass metatexture-pass (pass)
  ((clear-colour :initform '(0.5 0.5 0.5 0.0))))

(defun make-metatexture-pass ()
  (make-instance
   'metatexture-pass
   :shaders (list (make-instance 'metatexture-shader))
   :description
   (make-framebuffer-description
    (list (gficl:make-attachment-description :type :texture)
	  (gficl:make-attachment-description :position :depth-attachment))
    :samples 16)))

;;; Post Processing Pass

(defclass mt-post-shader (post-shader) ())

(defmethod reload ((s mt-post-shader))
  (shader-reload-files (s (#p"post.vs" #p"metatexture/metatex-post.fs")) shader
    (gl:uniformf (gficl:shader-loc shader "offset_intensity") 0.02)
    (gl:uniformi (gficl:shader-loc shader "mt") 0)
    (gl:uniformi (gficl:shader-loc shader "col") 1)))

(defmethod shader-scene-props ((s mt-post-shader) (scene post-scene))
  (with-slots (transform) scene
    (gficl:bind-gl (slot-value s 'shader))
    (gficl:bind-matrix (slot-value s 'shader) "transform" transform)
    (gl:active-texture :texture0)    
    (gl:bind-texture :texture-2d (get-post-tex scene :mt :color-attachment0))
    (gl:active-texture :texture1)
    (gl:bind-texture :texture-2d (get-post-tex scene :col :color-attachment0))))

(defclass mt-post-pass (post-pass) ())

(defun make-mt-post-pass ()
  (make-instance
   'mt-post-pass
   :shaders (list (make-instance 'mt-post-shader))
   :description
   (make-framebuffer-description (list (gficl:make-attachment-description)))))

;;; Post Scene

(defclass mt-post-scene (post-scene) ())

;;; Pipeline

(defclass aos-pipeline (pipeline)
  ((post-scene :initarg :post-scene :type mt-post-scene)))

(defun make-aos-pipeline ()  
  (make-instance
   'aos-pipeline
   :post-scene (make-instance 'mt-post-scene)
   :passes (list (cons :col (make-mt-colour-pass))
		 (cons :mt (make-metatexture-pass))		 
		 (cons :post (make-mt-post-pass)))))

(defmethod resize ((pl aos-pipeline) w h)
  (call-next-method)
  (with-slots ((scene post-scene)) pl
    (resize scene w h)
    (set-post-texs scene (alist-fb-textures pl '(:mt :col)))))

(defmethod draw ((pl aos-pipeline) scenes)
  (draw (get-pass pl :mt) scenes)
  (draw (get-pass pl :col) scenes)
  (draw (get-pass pl :post) (slot-value pl 'post-scene))
  (gficl:blit-framebuffers
   (get-final-framebuffer (get-pass pl :post))
   nil (gficl:window-width) (gficl:window-height)))
