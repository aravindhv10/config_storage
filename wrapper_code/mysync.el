(save-buffer)
(org-babel-tangle)
(async-shell-command "./mysync.sh" "log" "error")
