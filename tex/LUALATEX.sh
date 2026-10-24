#!/bin/sh
cd "$('dirname' '--' "${0}")"
'lualatex' '-shell-escape' 'main_lualatex.tex'
#'gnuplot' './main_new-gnuplottex-fig1.gnuplot'
'biber' 'main_new'
'lualatex' '-shell-escape' 'main_lualatex.tex'
'lualatex' '-shell-escape' 'main_lualatex.tex'
exit '0'
