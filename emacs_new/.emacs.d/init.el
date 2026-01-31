(add-to-list 'load-path (expand-file-name "~/GITHUB/abo-abo/swiper"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/emacs-evil/evil"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/emacs-evil/evil-collection"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/magnars/dash.el"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/magnars/s.el"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/noctuid/annalist.el"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/rejeep/f.el"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/Wilfred/elisp-refs"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/Wilfred/helpful"))
(add-to-list 'load-path (expand-file-name "~/GITHUB/company-mode/company-mode"))

;; Evil and evil collections
(setq evil-want-integration t)
(setq evil-want-keybinding nil)

(require 'annalist)
(require 'company)
(require 'dash)
(require 'elisp-refs)
(require 'evil)
(require 'evil-collection)
(require 'f)
(require 'helpful)
(require 's)
(require 'swiper)


(evil-mode 1)
(global-company-mode 1)
(evil-collection-init)
(ivy-mode)

;; Note that the built-in `describe-function' includes both functions
;; and macros. `helpful-function' is functions only, so we provide
;; `helpful-callable' as a drop-in replacement.
(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)

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
