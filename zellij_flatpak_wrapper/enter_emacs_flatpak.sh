#!/bin/sh
exec flatpak run '--talk-name=org.freedesktop.Flatpak' "--command=${HOME}/bin/zellij.sh" 'org.gnu.emacs'
