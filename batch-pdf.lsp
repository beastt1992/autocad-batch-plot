;;; BATCH-PDF
;;; Function: Batch export all title block frames to PDF
;;; Command: BPDF
;;; Compatible: AutoCAD 2014+

(setq AC_WINDOW 3)
(setq AC_0DEG 0)
(setq AC_FIT 0)

(defun BPDF-cfgpath ()
  (strcat (getenv "APPDATA") "\\bpdf_settings.cfg")
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

(defun c:BPDF ( / blockname outpath ss i ent obj
                  minpoint maxpoint pt1 pt2
                  counter fname adoc alayout aplot
                  scaleStr scaleVal useFit styleSheet
                  prefix frameList frame fx fy fx2 fy2 rowHeight
                  plotterName styleList styleNum
                  allMedia mediaShort mediaIdx m j item
                  paperNum paperSize cfg lastVal inp confirm)
  (vl-load-com)

  (setq cfg (BPDF-load-cfg))

  (setq lastVal (cdr (assoc "blockname" cfg)))
  (if (/= lastVal "")
    (setq inp (getstring (strcat "\nBlock Name <" lastVal ">: ")))
    (setq inp (getstring "\nBlock Name: "))
  )
  (setq blockname (if (= inp "") lastVal inp))
  (if (= blockname "") (progn (princ "\nCancelled.") (exit)))

  (setq lastVal (cdr (assoc "prefix" cfg)))
  (setq inp (getstring (strcat "\nPDF Prefix <" lastVal ">: ")))
  (setq prefix (if (= inp "") lastVal inp))

  (setq lastVal (cdr (assoc "outpath" cfg)))
  (setq inp (getstring (strcat "\nOutput Folder <" lastVal ">: ")))
  (setq outpath (if (= inp "") lastVal inp))
  (if (/= (substr outpath (strlen outpath)) "\\")
    (setq outpath (strcat outpath "\\"))
  )
  (vl-mkdir outpath)
  (princ (strcat "Output: " outpath "\n"))

  (setq ss (ssget "X"
    (list (cons 0 "INSERT") (cons 2 blockname) (cons 410 "Model"))
  ))
  (if (null ss)
    (progn (alert (strcat "Block not found: " blockname)) (exit))
  )
  (setq counter (sslength ss))
  (princ (strcat "Found " (itoa counter) " frames\n"))

  (setq adoc (vla-get-activedocument (vlax-get-acad-object)))
  (setq alayout (vla-get-activelayout adoc))
  (setq aplot (vla-get-plot adoc))
  (setq plotterName "DWG To PDF.pc3")
  (vla-put-configname alayout plotterName)
  (vla-RefreshPlotDeviceInfo alayout)

  (setq styleList
    (vlax-safearray->list
      (vlax-variant-value (vla-GetPlotStyleTableNames alayout))
    )
  )
  (setq styleList (append (list "None (Color)") styleList))
  (setq lastVal (atoi (cdr (assoc "styleNum" cfg))))
  (if (or (< lastVal 1) (> lastVal (length styleList))) (setq lastVal 1))
  (princ "\nPlot Style:\n")
  (setq i 1)
  (foreach s styleList
    (princ (strcat "  " (itoa i) ". " s (if (= i lastVal) "  <- last" "") "\n"))
    (setq i (1+ i))
  )
  (setq inp (getint (strcat "Select <" (itoa lastVal) ">: ")))
  (setq styleNum (if (or (null inp) (< inp 1) (> inp (length styleList))) lastVal inp))
  (setq styleSheet (if (= styleNum 1) "" (nth (1- styleNum) styleList)))
  (princ (strcat "Style: " (if (= styleSheet "") "None" styleSheet) "\n"))

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
  (setq lastVal (atoi (cdr (assoc "paperNum" cfg))))
  (if (or (< lastVal 1) (> lastVal (length mediaShort))) (setq lastVal 1))
  (princ "\nPaper Size:\n")
  (setq j 1)
  (foreach item mediaShort
    (princ (strcat "  " (itoa j) ". " (cadr item) (if (= j lastVal) "  <- last" "") "\n"))
    (setq j (1+ j))
  )
  (setq inp (getint (strcat "Select <" (itoa lastVal) ">: ")))
  (setq paperNum (if (or (null inp) (< inp 1) (> inp (length mediaShort))) lastVal inp))
  (setq paperSize (cadr (nth (1- paperNum) mediaShort)))
  (princ (strcat "Paper: " paperSize "\n"))

  (setq lastVal (cdr (assoc "scaleStr" cfg)))
  (setq inp (getstring
    (strcat "\nScale denominator (100=1:100, Enter=Fit)"
      (if (/= lastVal "") (strcat " <" lastVal ">") " <Fit>") ": ")
  ))
  (setq scaleStr (if (= inp "") lastVal inp))
  (if (= scaleStr "")
    (setq useFit T scaleVal 0)
    (setq useFit nil scaleVal (atof scaleStr))
  )

  (BPDF-save-cfg blockname prefix outpath styleNum paperNum scaleStr)

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

  (alert (strcat
    "===== Confirm Plot =====\n\n"
    "Frames: " (itoa counter) "\n"
    "Prefix: " prefix "\n"
    "Output: " outpath "\n"
    "Paper:  " paperSize "\n"
    "Style:  " (if (= styleSheet "") "None" styleSheet) "\n"
    "Scale:  " (if useFit "Fit" (strcat "1:" (rtos scaleVal 2 0))) "\n\n"
    "Click OK to continue"
  ))
  (initget "Y N")
  (setq confirm (getkword "\nConfirm [Y=Yes / N=Cancel] <Y>: "))
  (if (= confirm "N")
    (progn (princ "\nCancelled.") (exit))
  )

  (princ "Plotting...\n")
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
    (princ (strcat "  [" (itoa (1+ i)) "/" (itoa counter) "] Done\n"))
    (setq i (1+ i))
  )

  (setvar "BACKGROUNDPLOT" 2)
  (alert (strcat "Done! " (itoa counter) " PDFs exported\nLocation: " outpath))
  (princ)
)
