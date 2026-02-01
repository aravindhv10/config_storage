(global-set-key (kbd "C-;") 'avy-goto-line)
(global-set-key (kbd "C-M-/") #'dabbrev-expand)
(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h x") #'helpful-command)
(global-set-key (kbd "M-/") #'company-dabbrev)

(key-chord-define-global "6u" 'vundo)
(key-chord-define-global "7u" 'vundo)
(key-chord-define-global "8u" 'vundo)

(key-chord-define-global "o8" 'hydra-org/body)
(key-chord-define-global "o9" 'hydra-org/body)
(key-chord-define-global "o0" 'hydra-org/body)

(key-chord-define-global "s1" 'swiper)
(key-chord-define-global "s2" 'swiper)
(key-chord-define-global "s3" 'swiper)
