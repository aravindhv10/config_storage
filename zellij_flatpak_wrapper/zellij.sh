#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
export SHELL='nu'
exec 'zellij' 'attach' '--create'
