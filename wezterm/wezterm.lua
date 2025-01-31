-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.default_prog = { '/usr/local/bin/fish', '-l' }

-- and finally, return the configuration to wezterm
return config
