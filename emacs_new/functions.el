;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | ################################################################################################################################ |
;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | Begin functions to format and save code                                                                                          |
;; |----------------------------------------------------------------------------------------------------------------------------------|

(defun myfun/save_and_format_py ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "ruff format -" (current-buffer) t "*ruff error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/save_and_format_c ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "clang-format" (current-buffer) t "*fcc error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/save_and_format_latex ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "latexindent" (current-buffer) t "*latexindent error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/save_and_expand ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "expand" (current-buffer) t "*expand error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/copy-org-src-block ()
  (interactive)
  (org-edit-src-code)
  (kill-ring-save  (point-min) (point-max))
  (org-edit-src-abort))

(defun myfun/switch_window ()
  (interactive)
  (other-window 1)
  (hydra-window/body))

;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | End functions to format and save code                                                                                            |
;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | ################################################################################################################################ |
;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | Begin hydra definitions                                                                                                          |
;; |----------------------------------------------------------------------------------------------------------------------------------|

(defhydra
  hydra-format-and-save (:color blue)
  "format-and-save"
  ("p" myfun/save_and_format_py "save and format python" :color blue)
  ("l" myfun/save_and_format_latex "save and format latex" :color blue)
  ("q" hydra-all/body "hydra-all" :color blue)
  ("<escape>" nil "cancel" :color blue))

(defhydra
  hydra-org (:color blue)
  "org"
  ("b" org-table-align "org-table-align" :color red)
  ("c" myfun/copy-org-src-block "copy" :color red)
  ("e" org-edit-src-code "edit" :color blue)
  ("j" org-babel-next-src-block "next src block"  :color red)
  ("k" org-babel-previous-src-block "org-babel-previous-src-block" :color red)
  (";" org-toggle-comment "comment" :color red)
  ("t" org-babel-tangle "tangle" :color red)
  ("x" org-babel-execute-src-block "exec" :color red)
  ("q" hydra-all/body "hydra-all" :color blue)
  ("<escape>" nil "cancel" :color blue))

(defhydra
  hydra-counsel (:color blue)
  "counsel"
  ("s" swiper "swiper")
  ("f" counsel-fzf "counsel-fzf")
  ("b" counsel-switch-buffer "counsel-switch-buffer")
  ("r" counsel-rg "counsel-rg")
  ("d" counsel-dired "counsel-dired")
  ("q" hydra-all/body "hydra-all" :color blue)
  ("<escape>" nil "cancel" :color blue))

(defhydra hydra-window (:color red)
  "window"
  ("w" other-window "other" :color red)
  ("s" save-buffer "save" :color red)
  ("t" tear-off-window "tear" :color red)
  ("r" toggle-frame-fullscreen "fullscreen" :color red)
  ("d" delete-window "delete_window" :color red)
  ("f" delete-frame "delete_frame" :color red)
  ("v" evil-window-vsplit "vertical split" :color red)
  ("h" evil-window-split "horizontal split" :color red)
  ("b" counsel-switch-buffer "switch_buffer" :color blue)
  ("k" kill-buffer "kill_buffer" :color blue)
  ("q" hydra-all/body "hydra-all" :color blue)
  ("<escape>" nil "cancel" :color blue))

(defhydra hydra-projectile (:color blue)
  "window"
  ("d" projectile-dired "projectile-dired" :color blue)
  ("e" projectile-run-eshell "eshell" :color blue)
  ("f" projectile-find-file "projectile-find-file" :color blue)
  ("g" projectile-find-dir "projectile-find-dir" :color blue)
  ("m" magit "magit" :color blue)
  ("r" projectile-ripgrep "projectile-ripgrep" :color blue)
  ("q" hydra-all/body "hydra-all" :color blue)
  ("<escape>" nil "cancel" :color blue))

(defhydra hydra-all (:color blue)
  "global hydra menu"

  ("z" vundo "undo-tree" :color blue)
  ("x" counsel-dired "counsel-dired" :color blue)
  ("c" counsel-company "counsel-company" :color blue)
  ("v" counsel-find-file "counsel-find-file" :color blue)
  ("b" counsel-rg "counsel-rg" :color blue)

  ("n" counsel-rg "counsel-rg" :color blue)
  ("m" magit "magit" :color blue)
  ("/" counsel-switch-buffer "counsel-switch-buffer" :color blue)

  ("a" swiper "swiper" :color blue)
  ("s" swiper "swiper" :color blue)
  ("d" counsel-dired "counsel-dired" :color blue)
  ("f" counsel-find-file "counsel-find-file" :color blue)
  ("g" counsel-rg "counsel-rg" :color blue)

  ("h" counsel-rg "counsel-rg" :color blue)
  ("j" counsel-rg "counsel-rg" :color blue)
  ("k" counsel-rg "counsel-rg" :color blue)
  ("l" counsel-rg "counsel-rg" :color blue)

  ("q" hydra-all/body "hydra-counsel" :color blue)
  ("w" myfun/switch_window "hydra-window" :color blue)
  ("e" hydra-counsel/body "hydra-counsel" :color blue)
  ("r" hydra-counsel/body "hydra-counsel" :color blue)
  ("t" hydra-format-and-save/body "hydra-format-and-save" :color blue)

  ("y" hydra-org/body "hydra-org" :color blue)
  ("u" hydra-org/body "hydra-org" :color blue)
  ("i" hydra-org/body "hydra-org" :color blue)
  ("o" hydra-org/body "hydra-org" :color blue)
  ("p" hydra-projectile/body "hydra-projectile" :color blue)


  ("<escape>" nil "cancel" :color blue))

;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | End hydra definitions                                                                                                            |
;; |----------------------------------------------------------------------------------------------------------------------------------|
;; | ################################################################################################################################ |
;; |----------------------------------------------------------------------------------------------------------------------------------|
