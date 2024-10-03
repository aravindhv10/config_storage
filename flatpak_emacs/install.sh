#!/bin/sh
flatpak search sdk > ./list.sdk.txt
flatpak search llvm >> ./list.llvm.txt 
flatpak search rust >> ./list.rust.txt
flatpak search org.gnu.emacs >> ./list.emacs.txt

flatpak install org.freedesktop.Sdk/x86_64/24.08
flatpak install org.freedesktop.Sdk.Extension.llvm18/x86_64/24.08
flatpak install org.freedesktop.Sdk.Extension.rust-stable/x86_64/24.08
flatpak install org.gnu.emacs
