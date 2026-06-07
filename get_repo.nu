#!/usr/bin/env nu

def main [url: string] {
    let STRIPPED = ($url | str replace -r '\.git$' '')
    let CODE_DIR = ($STRIPPED | path basename)
    let CODE_USER = ($STRIPPED | path dirname | path basename)
    let PATH_OUT =  [$env.HOME 'GITHUB' $CODE_USER $CODE_DIR] | path join
    try {
        git clone $url $PATH_OUT
    } catch {
        cd $PATH_OUT
        echo 'pulling'
        git pull
    }
}
