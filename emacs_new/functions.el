(defun myfun/copy-org-src-block ()
  (interactive)
  (org-edit-src-code)
  (kill-ring-save  (point-min) (point-max))
  (org-edit-src-abort))

(defun myfun/save_and_format_py ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "ruff format -" (current-buffer) t "*ruff error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))


(defun myfun/switch_window ()
  (interactive)
  (other-window)
  )

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

(defhydra
  hydra-counsel (:color blue)
  "zoom"
  ("s" swiper "swiper")
  ("f" counsel-fzf "counsel-fzf")
  ("b" counsel-switch-buffer "counsel-switch-buffer")
  ("r" counsel-rg "counsel-rg"))

(defhydra
  hydra-window (:color red)
  "zoom"
  ("-" evil-window-split "evil-split-buffer")
  ("f" toggle-frame-fullscreen "toggle-frame-fullscreen")
  ("t" tear-off-window "tear-off-window")
  ("d" kill-buffer-and-window "kill-buffer-and-window")
  ("w" other-window "other-window"))
