(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(modus-vivendi)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Noto Sans Mono" :foundry "GOOG" :slant normal :weight bold :height 180 :width normal)))))

(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;;When installing a package used in the init file itself,
;;e.g. a package which adds a use-package key word,
;;use the :wait recipe keyword to block until that package is installed/configured.
;;For example:
;;(use-package general :ensure (:wait t) :demand t)

(whitespace-mode 1)

(electric-pair-mode 1)

(global-display-line-numbers-mode 1)

; (setq modus-themes-org-blocks 'gray-background)
(setq modus-themes-org-blocks 'tinted-background)
(load-theme 'modus-vivendi)

(setq-default indent-tabs-mode nil)

(server-start)

(setq eshell-prefer-lisp-functions 1)

(use-package beacon
  :ensure t
  :demand t
  :config
  (global-hl-line-mode 1)
  (global-tab-line-mode 1)
  :init
  (beacon-mode 1)
  )

(use-package org :ensure t :demand t :init
  (setq org-confirm-babel-evaluate nil)
  (org-babel-do-load-languages
   'org-babel-load-languages '(
                               (emacs-lisp . t)
                               (python . t)
                               (R . t)
                               (eshell . t)
                               (awk . t)
                               (sql . t)
                               (shell . t)
                               (sqlite . t)
                               )))

(use-package flycheck
  :ensure t
  :demand t
  :init
  (global-flycheck-mode 1)
  )

(use-package consult-ag
  :ensure t
  :demand t
  :config
  :init
  )

(use-package ag
  :ensure t
  :demand t
  :config
  (setq ag-context-lines 4)
  (setq ag-highlight-search 4)
  (global-set-key (kbd "C-c g") 'ag)
  :init
  )

(use-package treemacs
  :ensure t
  :demand t
  :config
  :init
  )

(use-package projectile
  :ensure t
  :demand t
  :config
  ;; Recommended keymap prefix on macOS
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  ;; Recommended keymap prefix on Windows/Linux
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  :init
  (projectile-mode +1)
  )

(use-package undo-tree
  :ensure t
  :demand t
  :init
  (global-undo-tree-mode))

(use-package rainbow-mode
  :ensure t
  :demand t
  :init
  (add-hook 'prog-mode-hook 'rainbow-mode)
  (add-hook 'text-mode-hook 'rainbow-mode)
  (add-hook 'dired-mode-hook 'rainbow-mode)
  (add-hook 'conf-mode-hook 'rainbow-mode)
  )

(use-package rainbow-delimiters
  :ensure t
  :demand t
  :init
  (add-hook 'conf-mode-hook 'rainbow-delimiters-mode)
  (add-hook 'dired-mode-hook 'rainbow-delimiters-mode)
  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
  (add-hook 'text-mode-hook 'rainbow-delimiters-mode))

(use-package rainbow-identifiers
  :ensure t
  :demand t
  :init
  (add-hook 'conf-mode-hook 'rainbow-identifiers-mode)
  (add-hook 'dired-mode-hook 'rainbow-identifiers-mode)
  (add-hook 'prog-mode-hook 'rainbow-identifiers-mode)
  (add-hook 'text-mode-hook 'rainbow-identifiers-mode))

;; Use Dabbrev with Corfu!
(use-package dabbrev
  ;; Swap M-/ and C-M-/
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  ;; Since 29.1, use `dabbrev-ignored-buffer-regexps' on older.
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))

(use-package helpful :ensure t :demand t :init)

;; Enable vertico
(use-package vertico
  :ensure t
  :demand t
  :custom
  (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 10) ;; Show more candidates
  (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

(use-package consult :ensure t :demand t :init)

(use-package marginalia :ensure t :demand t :init (marginalia-mode))

(use-package orderless
  :ensure t
  :demand t
  :config
  ;; (defun flex-if-twiddle (pattern _index _total)
  ;;   (when (string-suffix-p "~" pattern)
  ;;     `(orderless-flex . ,(substring pattern 0 -1))))

  ;; (defun first-initialism (pattern index _total)
  ;;   (if (= index 0) 'orderless-initialism))

  ;; (defun not-if-bang (pattern _index _total)
  ;;   (cond
  ;;    ((equal "!" pattern)
  ;;     #'ignore)
  ;;    ((string-prefix-p "!" pattern)
  ;;     `(orderless-not . ,(substring pattern 1)))))

  ;; (setq orderless-matching-styles '(orderless-regexp)
  ;; 	orderless-style-dispatchers '(first-initialism
  ;;                                     flex-if-twiddle
  ;;                                     not-if-bang))
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))))
  ;; (completion-category-overrides '((file (styles basic partial-completion))))
  )

;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package evil
  :ensure t
  :demand t
  :config
  (evil-set-undo-system 'undo-tree)
  :init (evil-mode 1))

;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package which-key
  :ensure t
  :demand t
  :config
  (setq which-key-idle-delay 0.01)
  :init (which-key-mode 1)
  )

(use-package yasnippet-snippets :ensure t :demand t)
(use-package yasnippet :ensure t :demand t :init (yas-global-mode 1))

(use-package hydra
  :ensure t
  :demand t
  :init

  (defhydra hydra-all (:color blue)
    "all"
    ("s" hydra-consult/body     "consult")
    ("w" hydra-window/body     "window")
    ("o" hydra-org/body        "org")
    ("m" hydra-myfunc/body     "myfunc")
    ("h" hydra-completion/body "company")
    ("c" hydra-counsel/body    "counsel")
    ("p" hydra-projectile/body "projectile")
    ("e" eshell                "eshell")
    ("f" find-file-at-point    "file")
    ("u" undo-tree-visualize   "undo")
    ("t" treemacs              "treemacs")
    ("l" lsp                   "lsp")
    ("x" counsel-M-x           "M-x")
    ("<escape>" nil "cancel" :color blue)
    ("q" nil                   "cancel")
    )

  (defhydra hydra-consult (:color blue)
    "consult"
    ("s" consult-line "search buffer")
    ("a" consult-line-multi "search all buffers")
    ("q" hydra-all/body "all" :color blue)
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
    ("b" consult-buffer "switch_buffer" :color blue)
    ("k" kill-buffer "kill_buffer" :color blue)
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-org (:color blue)
    "org"
    (";"        org-toggle-comment          "comment" :color red)
    ("e"        org-edit-src-code           "edit")
    ("t"        org-babel-tangle            "tangle")
    ("x"        org-babel-execute-src-block "exec")
    ("a"        org-edit-src-abort          "abort")
    ("c"        myfun/copy-org-src-block    "copy")
    ("l"        hydra-org-cycle/body        "cycle")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))
  
  (defhydra hydra-org-cycle (:color red)
    "org-cycle"
    ("a"        org-cycle         "all")
    ("c"        org-cycle-content "content")
    ("g"        org-cycle-global  "global")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))



  (defhydra hydra-menu (:color red)
    "menu"
    ("z" text-scale-increase     "in")
    ("x" text-scale-decrease     "out")
    ("f" toggle-frame-fullscreen "fullscreen")
    ("y" myfun/menu_y            "enable")
    ("n" myfun/menu_n            "disable")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-format (:color blue)
    "format"
    ("e" myfun/save_and_expand       "expand")
    ("c" myfun/save_and_format_c     "c")
    ("p" myfun/save_and_format_py    "py")
    ("o" myfun/save_and_format_org   "org")
    ("l" myfun/save_and_format_latex "latex")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-myfunc (:color blue)
    "myfunc"
    ("m" hydra-menu/body   "menu")
    ("f" hydra-format/body "format")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))


  (defhydra hydra-completion (:color blue)
    "completion"
    ("d" company-dabbrev  "dabbrev")
    ("c" company-complete "complete")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-counsel-file (:color blue)
    "counsel-file"
    ("f" counsel-find-file "find")
    ("z" counsel-fzf       "fzf")
    ("g" find-grep-dired   "grep")
    ("d" counsel-dired     "dired")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-counsel (:color blue)
    "counsel"
    ("a" counsel-ag              "ag")
    ("c" counsel-company         "company")
    ("d" counsel-dired           "dired")
    ("k" counsel-flycheck        "flycheck")
    ("b" consult-buffer "buffer")
    ("f" hydra-counsel-file/body "file")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  (defhydra hydra-projectile (:color blue)
    "projectile"
    ("e" projectile-run-eshell "eshell")
    ("a" projectile-ag         "ag")
    ("d" projectile-dired      "dired")
    ("r" projectile-find-dir   "dir")
    ("f" projectile-find-file  "file")
    ("q" hydra-all/body "all" :color blue)
    ("<escape>" nil "cancel" :color blue))

  )

(use-package key-chord
  :ensure t
  :demand t
  :init
  (key-chord-mode)
  (key-chord-define-global "1q" 'hydra-all/body)
  (key-chord-define-global "2q" 'hydra-all/body)

  (key-chord-define-global "2w" 'myfun/other_window_and_menu)
  (key-chord-define-global "3w" 'myfun/other_window_and_menu)

  (key-chord-define-global "e3" 'consult-buffer)
  (key-chord-define-global "e4" 'consult-buffer)

  (key-chord-define-global "5t" 'hydra-format/body)
  (key-chord-define-global "6t" 'hydra-format/body)

  (key-chord-define-global "7y" 'hydra-window/body)
  (key-chord-define-global "6y" 'hydra-window/body)

  (key-chord-define-global "8u" 'undo-tree-visualize)
  (key-chord-define-global "7u" 'undo-tree-visualize)

  (key-chord-define-global "i9" 'hydra-counsel-file/body)
  (key-chord-define-global "i8" 'hydra-counsel-file/body)

  (key-chord-define-global "o9" 'hydra-org/body)
  (key-chord-define-global "o0" 'hydra-org/body)

  (key-chord-define-global "p=" 'hydra-projectile/body)
  (key-chord-define-global "p-" 'hydra-projectile/body)
  (key-chord-define-global "p0" 'hydra-projectile/body)
  (key-chord-define-global "p9" 'hydra-projectile/body)

  (key-chord-define-global "()" 'myfun/bb1)
  (key-chord-define-global "[]" 'myfun/bb2)
  (key-chord-define-global "<>" 'myfun/bb3)
  (key-chord-define-global "{}" 'myfun/bb4)

  (key-chord-define-global "(*" "()\C-b")
  (key-chord-define-global "p[" "[]\C-b")
  (key-chord-define-global "M<" "<>\C-b")
  (key-chord-define-global "P{" "{}\C-b")

  (key-chord-define-global ";." "->")

  (key-chord-define-global "o="  'evil-window-split)
  (key-chord-define-global "p="  'evil-window-split)
  (key-chord-define-global "[="  'evil-window-split)
  (key-chord-define-global "]="  'evil-window-split)
  (key-chord-define-global "\\=" 'evil-window-split)

  (key-chord-define-global "\\'" 'evil-window-vsplit)
  (key-chord-define-global "\\;" 'evil-window-vsplit)
  (key-chord-define-global "\\l" 'evil-window-vsplit)
  (key-chord-define-global "\\]" 'evil-window-vsplit)
  (key-chord-define-global "\\[" 'evil-window-vsplit))

(use-package markdown-mode
  :ensure t
  :demand t
  :config
  :init
  )

(use-package company
  :ensure t
  :demand t
  :config
  (setq company-minimum-prefix-length 0)
  (setq company-idle-delay 0)
  (add-hook 'prog-mode-hook 'company-mode)
  (add-hook 'text-mode-hook 'company-mode)
  ;; (add-hook 'eshell-mode-hook 'company-mode)
  ;; :init
  ;; (global-company-mode)
  )

(elpaca corfu)

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-separator ?\s)          ;; Orderless field separator
  (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  (corfu-preview-current nil)    ;; Disable current candidate preview
  (corfu-preselect 'prompt)      ;; Preselect the prompt
  (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  (corfu-scroll-margin 5)        ;; Use scroll margin

  ;; Enable Corfu only for certain modes. See also `global-corfu-modes'.
  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
  ;; be used globally (M-/).  See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  :init
  ;; (global-corfu-mode)
  )

(use-package cape
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press C-c p ? to for help.
  :bind
  ("C-c p" . cape-prefix-map) ;; Alternative keys: M-p, M-+, ...
  ;; Alternatively bind Cape commands individually.
  ;; :bind (("C-c p d" . cape-dabbrev)
  ;;        ("C-c p h" . cape-history)
  ;;        ("C-c p f" . cape-file)
  ;;        ...)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

;; Configure Tempel
(use-package tempel
  ;; Require trigger prefix before template name when completing.
  ;; :custom
  ;; (tempel-trigger-prefix "<")

  :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
         ("M-*" . tempel-insert))

  :init

  ;; Setup completion at point
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))

  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf)

  ;; Optionally make the Tempel templates available to Abbrev,
  ;; either locally or globally. `expand-abbrev' is bound to C-x '.
  ;; (add-hook 'prog-mode-hook #'tempel-abbrev-mode)
  ;; (global-tempel-abbrev-mode)
  )

;; Optional: Add tempel-collection.
;; The package is young and doesn't have comprehensive coverage.
(use-package tempel-collection
  :ensure t
  :demand t
  )

;; use-package with Elpaca:
(use-package dashboard
  :ensure t
  :config
  (add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
  (add-hook 'elpaca-after-init-hook #'dashboard-initialize)
  (dashboard-setup-startup-hook))

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

(defun myfun/save_and_format_py ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "yapf3" (current-buffer) t "*yapf3 error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/save_and_format_org ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (org-indent-region (point-min) (point-max))
  (shell-command-on-region (point-min) (point-max) "expand" (current-buffer) t "*format org error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/save_and_expand ()
  (interactive)
  (setq mytmpline (line-number-at-pos))
  (shell-command-on-region (point-min) (point-max) "expand" (current-buffer) t "*expand error*" t)
  (basic-save-buffer)
  (goto-line mytmpline))

(defun myfun/abort ()
  (interactive)
  (keyboard-escape-quit)
  (company-abort)
  (company-search-abort))

(defun myfun/menu_n ()
  (interactive)
  (menu-bar-mode 0)
  (tool-bar-mode 0))

(defun myfun/menu_y ()
  (interactive)
  (menu-bar-mode 1)
  (tool-bar-mode 1))

(defun myfun/copy-org-src-block ()
  (interactive)
  (org-edit-src-code)
  (kill-ring-save  (point-min) (point-max))
  (org-edit-src-abort))

(defun myfun/bb1 ()
  (interactive)
  (insert "()"))

(defun myfun/bb2 ()
  (interactive)
  (insert "[]"))

(defun myfun/bb3 ()
  (interactive)
  (insert "<>"))

(defun myfun/bb4 ()
  (interactive)
  (insert "{}"))

(defun myfun/other_window_and_menu ()
    (interactive)
    (other-window 1)
    (hydra-window/body))


(defun myfun/tear_and_full_screen ()
    (interactive)
    (tear-off-window)
    (toggle-frame-fullscreen))

(use-package emacs
  :custom

  ;; TAB cycle if there are only few candidates
  (completion-cycle-threshold 1)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function. As an alternative,
  ;; try `cape-dict'.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

(myfun/menu_n)
(toggle-frame-fullscreen)
