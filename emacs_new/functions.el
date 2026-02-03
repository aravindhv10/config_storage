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
  (other-window 1)
  (hydra-window/body))

(defhydra
  hydra-org (:color blue)
  "org"
  (";" org-toggle-comment "comment" :color red)
  ("e" org-edit-src-code "edit" :color blue)
  ("t" org-babel-tangle "tangle" :color red)
  ("x" org-babel-execute-src-block "exec" :color red)
  ("a" org-edit-src-abort "abort" :color blue)
  ("c" myfun/copy-org-src-block "copy" :color red)
  ("k" org-babel-previous-src-block "org-babel-previous-src-block" :color red)
  ("j" org-babel-next-src-block "next src block"  :color red)
  ("<escape>" nil "cancel" :color blue))

(defhydra
  hydra-counsel (:color blue)
  "zoom"
  ("s" swiper "swiper")
  ("f" counsel-fzf "counsel-fzf")
  ("b" counsel-switch-buffer "counsel-switch-buffer")
  ("r" counsel-rg "counsel-rg")
  ("d" counsel-dired "counsel-dired")
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
  ("<escape>" nil "cancel" :color blue))

(defhydra hydra-projectile (:color blue)
  "window"
  ("f" projectile-find-file "projectile-find-file" :color blue)
  ("d" projectile-dired "projectile-dired" :color blue)
  ("g" projectile-find-dir "projectile-find-dir" :color blue)
  ("r" projectile-ripgrep "projectile-ripgrep" :color blue)
  ("m" magit "magit" :color blue)
  ("<escape>" nil "cancel" :color blue))
