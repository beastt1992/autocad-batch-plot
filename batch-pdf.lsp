;;; BATCH-PDF with DCL Dialog
;;; Command: BPDF
;;; Compatible: AutoCAD 2014+
;;; v3.0 - DCL dialog for settings

(setq AC_0DEG 0)
(setq AC_FIT  0)

(defun BPDF-cfgpath ()
  (strcat (getenv "APPDATA") "\\bpdf_settings.cfg")
)

(defun BPDF-dclpath ()
  (strcat (getenv "APPDATA") "\\bpdf_dialog.dcl")
)

(defun BPDF-load-cfg ( / f line kv cfg)
  (setq cfg (list
    (cons "blockname" "")
    (cons "prefix" "frame")
    (cons "outpath" (strcat (getenv "USERPROFILE") "\\Desktop"))
    (cons "styleNum" "1")
    (cons "paperNum" "1")
    (cons "scaleStr" "")
  ))
  (setq f (open (BPDF-cfgpath) "r"))
  (if f
    (progn
      (while (setq line (read-line f))
        (setq kv (vl-string-search "=" line))
        (if kv
          (setq cfg (subst
            (cons (substr line 1 kv) (substr line (+ kv 2)))
            (assoc (substr line 1 kv) cfg)
            cfg
          ))
        )
      )
      (close f)
    )
  )
  cfg
)

(defun BPDF-save-cfg (blockname prefix outpath styleNum paperNum scaleStr / f)
  (setq f (open (BPDF-cfgpath) "w"))
  (if f
    (progn
      (write-line (strcat "blockname=" blockname) f)
      (write-line (strcat "prefix=" prefix) f)
      (write-line (strcat "outpath=" outpath) f)
      (write-line (strcat "styleNum=" (itoa styleNum)) f)
      (write-line (strcat "paperNum=" (itoa paperNum)) f)
      (write-line (strcat "scaleStr=" scaleStr) f)
      (close f)
    )
  )
)

;;; Write DCL file
(defun BPDF-write-dcl ( / f)
  (setq f (open (BPDF-dclpath) "w"))
  (write-line "bpdf_dialog : dialog {" f)
  (write-line "  label = \"BPDF  -  Batch PDF Export\";" f)
  (write-line "  : column {" f)
  (write-line "    : text { label = \"  BPDF  Batch PDF Export  v3.0\"; alignment = centered; }" f)
  (write-line "    spacer_1;" f)
  (write-line "    : row {" f)
  (write-line "      : edit_box { label = \"Block Name :\"; key = \"blockname\"; edit_width = 22; }" f)
  (write-line "      : button { label = \"  Pick  \"; key = \"click_block\"; width = 10; }" f)
  (write-line "    }" f)
  (write-line "    : edit_box { label = \"PDF Prefix  :\"; key = \"prefix\"; edit_width = 22; }" f)
  (write-line "    : edit_box { label = \"Output Folder:\"; key = \"outpath\"; edit_width = 35; }" f)
  (write-line "    spacer_1;" f)
  (write-line "    : row {" f)
  (write-line "      : list_box { label = \"Plot Style:\"; key = \"style\"; height = 6; width = 32; }" f)
  (write-line "      : list_box { label = \"Paper Size:\"; key = \"paper\"; height = 6; width = 32; }" f)
  (write-line "    }" f)
  (write-line "    spacer_1;" f)
  (write-line "    : row {" f)
  (write-line "      : edit_box { label = \"Scale (100=1:100, 0=Fit):\"; key = \"scale\"; edit_width = 10; }" f)
  (write-line "    }" f)
  (write-line "    spacer_1;" f)
  (write-line "    : boxed_row {" f)
  (write-line "      label = \"Plot Mode\";" f)
  (write-line "      : radio_button { label = \"All frames with this name\"; key = \"mode_all\"; }" f)
  (write-line "      : radio_button { label = \"Single frame only\"; key = \"mode_one\"; }" f)
  (write-line "    }" f)
  (write-line "    spacer_1;" f)
  (write-line "    ok_cancel;" f)
  (write-line "  }" f)
  (write-line "}" f)
  (close f)
)

(defun c:BPDF ( / blockname outpath ss i ent obj sel entdata plotMode
                  minpoint maxpoint pt1 pt2
                  counter fname adoc alayout aplot
                  scaleStr scaleVal useFit styleSheet
                  prefix frameList frame fx fy fx2 fy2 rowHeight
                  plotterName styleList styleNum
                  allMedia mediaShort mediaIdx m j item
                  paperNum paperSize cfg lastVal inp confirm
                  AC_WINDOW err dcl_id singleEnt)
  (vl-load-com)
  (setq cfg (BPDF-load-cfg))

  ;; Setup VLA first to get style/paper lists
  (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
  (setq alayout (vla-get-activelayout adoc))
  (setq aplot (vla-get-plot adoc))
  (setq plotterName "DWG To PDF.pc3")
  (vla-RefreshPlotDeviceInfo alayout)
  (vla-put-configname alayout plotterName)
  (vla-RefreshPlotDeviceInfo alayout)

  (setq AC_WINDOW 4)
  (setq err (vl-catch-all-apply
    (function (lambda () (vla-put-plottype alayout 4)))
  ))
  (if (vl-catch-all-error-p err)
    (progn (vla-put-plottype alayout 3) (setq AC_WINDOW 3))
  )

  ;; Get style list
  (setq styleList
    (vlax-safearray->list
      (vlax-variant-value (vla-GetPlotStyleTableNames alayout))
    )
  )
  (setq styleList (append (list "None (Color)") styleList))

  ;; Get paper list
  (setq allMedia
    (vlax-safearray->list
      (vlax-variant-value (vla-GetCanonicalMediaNames alayout))
    )
  )
  (setq mediaShort nil mediaIdx 0)
  (foreach m allMedia
    (if (or (vl-string-search "A0" m) (vl-string-search "A1" m)
            (vl-string-search "A2" m) (vl-string-search "A3" m)
            (vl-string-search "A4" m))
      (setq mediaShort (append mediaShort (list (list mediaIdx m))))
    )
    (setq mediaIdx (1+ mediaIdx))
  )

  ;; Write DCL file
  (BPDF-write-dcl)

  ;; Initialize from config
  (setq blockname (cdr (assoc "blockname" cfg)))
  (setq prefix    (cdr (assoc "prefix"    cfg)))
  (setq outpath   (cdr (assoc "outpath"   cfg)))
  (setq scaleStr  (cdr (assoc "scaleStr"  cfg)))
  (setq styleNum  (atoi (cdr (assoc "styleNum" cfg))))
  (setq paperNum  (atoi (cdr (assoc "paperNum" cfg))))
  (setq plotMode  "A")
  (setq singleEnt nil)

  ;; While loop allows Pick to be used multiple times
  (setq dResult 2)
  (while (>= dResult 2)

    ;; If Pick was pressed, select a block first
    (if (= dResult 2)
      (progn
        (princ "\nClick on a title block frame (or press Enter to skip): ")
        (setq sel (entsel ""))
        (if sel
          (progn
            (setq ent (car sel))
            (setq entdata (entget ent))
            (if (= (cdr (assoc 0 entdata)) "INSERT")
              (progn
                (setq blockname (cdr (assoc 2 entdata)))
                (setq singleEnt ent)
                (princ (strcat "\nBlock detected: " blockname "\n"))
              )
              (alert "Please click on a Block (INSERT) entity.")
            )
          )
        )
      )
    )

    ;; Load and show dialog
    (setq dcl_id (load_dialog (BPDF-dclpath)))
    (if (not (new_dialog "bpdf_dialog" dcl_id))
      (progn (alert "Cannot load dialog.") (exit))
    )

    ;; Set field values
    (set_tile "blockname" (if blockname blockname ""))
    (set_tile "prefix"    (if (and prefix (/= prefix "")) prefix "frame"))
    (set_tile "outpath"   (if (and outpath (/= outpath "")) outpath (strcat (getenv "USERPROFILE") "\\Desktop")))
    (set_tile "scale"     (if scaleStr scaleStr ""))
    (set_tile "mode_all"  "1")

    ;; Populate style list
    (start_list "style")
    (foreach s styleList (add_list s))
    (end_list)
    (set_tile "style" (itoa (if (> styleNum 0) (1- styleNum) 0)))

    ;; Populate paper list
    (start_list "paper")
    (foreach item mediaShort (add_list (cadr item)))
    (end_list)
    (set_tile "paper" (itoa (if (> paperNum 0) (1- paperNum) 0)))

    ;; Button actions
    (action_tile "click_block" "(done_dialog 2)")
    (action_tile "accept"
      (strcat
        "(setq blockname (get_tile \"blockname\"))"
        "(setq prefix (get_tile \"prefix\"))"
        "(setq outpath (get_tile \"outpath\"))"
        "(setq scaleStr (get_tile \"scale\"))"
        "(setq styleNum (1+ (atoi (get_tile \"style\"))))"
        "(setq paperNum (1+ (atoi (get_tile \"paper\"))))"
        "(setq plotMode (if (= (get_tile \"mode_all\") \"1\") \"A\" \"1\"))"
        "(done_dialog 1)"
      )
    )

    (setq dResult (start_dialog))
    (unload_dialog dcl_id)
  )

  ;; Cancelled
  (if (= dResult 0)
    (progn (princ "\nCancelled.") (exit))
  )
  ;; Process scale
  (if (or (= scaleStr "")
          (= scaleStr "0")
          (= (strcase scaleStr) "F")
          (= (strcase scaleStr) "FIT"))
    (progn (setq useFit T scaleVal 0) (setq scaleStr ""))
    (setq useFit nil scaleVal (atof scaleStr))
  )

  (setq styleSheet (if (= styleNum 1) "" (nth (1- styleNum) styleList)))
  (setq paperSize (cadr (nth (1- paperNum) mediaShort)))

  ;; Validate
  (if (= blockname "") (progn (alert "Block name is required.") (exit)))

  ;; Output folder
  (if (/= (substr outpath (strlen outpath)) "\\")
    (setq outpath (strcat outpath "\\"))
  )
  (vl-mkdir outpath)

  (BPDF-save-cfg blockname prefix outpath styleNum paperNum scaleStr)

  ;; Find frames
  (if (= plotMode "1")
    (progn
      (if singleEnt
        (progn
          (setq obj (vlax-ename->vla-object singleEnt))
          (vla-getboundingbox obj 'minpoint 'maxpoint)
          (setq frameList (list (list
            (vlax-safearray-get-element minpoint 0)
            (vlax-safearray-get-element minpoint 1)
            (vlax-safearray-get-element maxpoint 0)
            (vlax-safearray-get-element maxpoint 1)
          )))
          (setq counter 1)
        )
        (progn
          (princ "\nClick on a title block frame: ")
          (setq sel (entsel ""))
          (if sel
            (progn
              (setq ent (car sel))
              (setq obj (vlax-ename->vla-object ent))
              (vla-getboundingbox obj 'minpoint 'maxpoint)
              (setq frameList (list (list
                (vlax-safearray-get-element minpoint 0)
                (vlax-safearray-get-element minpoint 1)
                (vlax-safearray-get-element maxpoint 0)
                (vlax-safearray-get-element maxpoint 1)
              )))
              (setq counter 1)
            )
            (progn (princ "\nCancelled.") (exit))
          )
        )
      )
    )
    (progn
      (setq ss (ssget "X"
        (list (cons 0 "INSERT") (cons 2 blockname) (cons 410 "Model"))
      ))
      (if (null ss) (progn (alert (strcat "Block not found: " blockname)) (exit)))
      (setq counter (sslength ss))
      (setq frameList nil i 0)
      (repeat counter
        (setq ent (ssname ss i))
        (setq obj (vlax-ename->vla-object ent))
        (vla-getboundingbox obj 'minpoint 'maxpoint)
        (setq fx (vlax-safearray-get-element minpoint 0))
        (setq fy (vlax-safearray-get-element minpoint 1))
        (setq fx2 (vlax-safearray-get-element maxpoint 0))
        (setq fy2 (vlax-safearray-get-element maxpoint 1))
        (setq frameList (append frameList (list (list fx fy fx2 fy2))))
        (setq i (1+ i))
      )
      (setq rowHeight (* (- (cadddr (car frameList)) (cadr (car frameList))) 0.5))
      (setq frameList
        (vl-sort frameList
          (function (lambda (a b)
            (if (> (abs (- (cadr a) (cadr b))) rowHeight)
              (> (cadr a) (cadr b))
              (< (car a) (car b))
            )
          ))
        )
      )
    )
  )

  (princ (strcat "\nFound " (itoa counter) " frame(s). Plotting...\n"))
  (setvar "CMDECHO" 0)

  ;; Apply settings
  (setvar "BACKGROUNDPLOT" 0)
  (vla-put-canonicalmedianame alayout paperSize)
  (vla-put-plotrotation alayout AC_0DEG)
  (vla-put-centerplot alayout :vlax-true)
  (vla-put-plotwithlineweights alayout :vlax-true)
  (if (/= styleSheet "")
    (progn
      (vla-put-plotwithplotstyles alayout :vlax-true)
      (vla-put-stylesheet alayout styleSheet)
    )
    (vla-put-plotwithplotstyles alayout :vlax-false)
  )
  (if useFit
    (progn
      (vla-put-useStandardScale alayout :vlax-true)
      (vla-put-standardscale alayout AC_FIT)
    )
    (progn
      (vla-put-useStandardScale alayout :vlax-false)
      (vla-SetCustomScale alayout 1.0 scaleVal)
    )
  )

  ;; Plot loop
  (setq i 0)
  (foreach frame frameList
    (setq pt1 (vlax-make-safearray vlax-vbdouble '(0 . 1)))
    (vlax-safearray-put-element pt1 0 (car frame))
    (vlax-safearray-put-element pt1 1 (cadr frame))
    (setq pt2 (vlax-make-safearray vlax-vbdouble '(0 . 1)))
    (vlax-safearray-put-element pt2 0 (caddr frame))
    (vlax-safearray-put-element pt2 1 (cadddr frame))
    (vla-SetWindowToPlot alayout pt1 pt2)
    (vla-put-plottype alayout AC_WINDOW)
    (setq fname (strcat outpath prefix "_" (itoa (1+ i)) ".pdf"))
    (vla-PlotToFile aplot fname)
    (setvar "MODEMACRO" (strcat "BPDF: [" (itoa (1+ i)) "/" (itoa counter) "] Plotting..."))
    (setq i (1+ i))
  )

  (setvar "BACKGROUNDPLOT" 2)
  (setvar "MODEMACRO" "")
  (setvar "CMDECHO" 1)
  (alert (strcat "Done! " (itoa counter) " PDFs exported\nLocation: " outpath))
  (princ)
)
