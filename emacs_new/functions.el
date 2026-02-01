(defun myfun/copy-org-src-block ()
  (interactive)
  (org-edit-src-code)
  (kill-ring-save  (point-min) (point-max))
  (org-edit-src-abort))

(defhydra
  hydra-org (:color blue)
  "org"
  (";" org-toggle-comment "comment" :color red)
  ("e" org-edit-src-code "edit")
  ("t" org-babel-tangle "tangle")
  ("x" org-babel-execute-src-block "exec")
  ("a" org-edit-src-abort "abort")
  ("c" myfun/copy-org-src-block "copy")
  ("<escape>" nil "cancel" :color blue))
