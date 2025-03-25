-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.default_prog = { 'fish', '-l' }
config.use_fancy_tab_bar = false

config.color_scheme = 'Modus-Vivendi'

config.keys = {
  {
    key = '/',
    mods = 'CTRL|ALT',
    action = wezterm.action.ShowLauncher,
  },
  {
    key = 'LeftArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.SplitPane {
      direction = 'Left',
      command = { args = { 'fish' } },
      size = { Percent = 50 },
    },
  },
  {
    key = 'RightArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.SplitPane {
      direction = 'Right',
      command = { args = { 'fish' } },
      size = { Percent = 50 },
    },
  },
  {
    key = 'DownArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.SplitPane {
      direction = 'Down',
      command = { args = { 'fish' } },
      size = { Percent = 50 },
    },
  },
  {
    key = 'UpArrow',
    mods = 'CTRL|ALT',
    action = wezterm.action.SplitPane {
      direction = 'Up',
      command = { args = { 'fish' } },
      size = { Percent = 50 },
    },
  },
}

config.launch_menu = {
  {
    label = 'fish',
    args = { 'fish', '-l' },
  },
  {
    label = 'Bash',
    args = { 'bash', '-l' },
  },
  {
    label = 'tmux',
    args = { 'byobu-tmux' },
  },
  {
    label = 'top',
    args = { 'btm', '-b', '--process_command' },
  },
  {
    label = 'alsamixer',
    args = { 'alsamixer' },
  },
}

return config
