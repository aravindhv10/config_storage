-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.default_prog = { '/usr/local/bin/fish', '-l' }
config.use_fancy_tab_bar = false

config.keys = {
  {
    key = '/',
    mods = 'CTRL|ALT',
    action = wezterm.action.ShowLauncher ,
  },
}

 
config.launch_menu = {
  {
    label = 'fish',
    args = { '/usr/local/bin/fish', '-l' },
  },

  {
    label = 'Bash',
    args = { '/bin/bash', '-l' },
  },

  {
    label = 'tmux',
    args = { '/usr/local/bin/tmux_auto.sh' },
  },

  {
    label = 'top',
    args = { '/usr/local/bin/btm', '-b', '--process_command' },
  },

  {
    label = 'alsamixer',
    args = { 'alsamixer' },
  },
}

return config
