(load-file (expand-file-name "~/GITHUB/aravindhv10/config_storage/emacs_new/paths.el"))

;; Evil and evil collections
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(setq modus-themes-org-blocks 'tinted-background)
(setq-default indent-tabs-mode nil)

(load-file (expand-file-name "~/GITHUB/aravindhv10/config_storage/emacs_new/requires.el"))
(load-file (expand-file-name "~/GITHUB/aravindhv10/config_storage/emacs_new/hooks.el"))

(evil-mode 1)
(which-key-mode 1)
(global-company-mode 1)
(evil-collection-init)
(ivy-mode 1)
(global-display-line-numbers-mode 1)
(global-diff-hl-mode)

;; Note that the built-in `describe-function' includes both functions
;; and macros. `helpful-function' is functions only, so we provide
;; `helpful-callable' as a drop-in replacement.

(load-file (expand-file-name "~/GITHUB/aravindhv10/config_storage/emacs_new/bindings.el"))

(load-theme 'modus-vivendi)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-use-system-font t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "PfEd" :slant normal :weight bold :height 158 :width normal)))))
