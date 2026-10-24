#!/bin/sh
cd "$('dirname' '--' "${0}")"
'lualatex' '-shell-escape' 'main_new.tex'
#'gnuplot' './main_new-gnuplottex-fig1.gnuplot'
'biber' 'main_new'
'lualatex' '-shell-escape' 'main_new.tex'
'lualatex' '-shell-escape' 'main_new.tex'
exit '0'
