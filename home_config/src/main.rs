use std::str::FromStr;

fn get_env() -> std::collections::HashMap<std::ffi::OsString, std::ffi::OsString> {
    let mut current_env =
        std::collections::HashMap::<std::ffi::OsString, std::ffi::OsString>::new();

    for (key, value) in std::env::vars_os() {
        current_env.insert(key, value);
    }

    current_env
}

fn get_path_home(
    current_env: std::collections::HashMap<std::ffi::OsString, std::ffi::OsString>,
) -> std::string::String {
    let HOME = std::ffi::OsString::from_str("HOME").unwrap();
    let HOME: std::ffi::OsString = match current_env.get(&HOME) {
        Some(val) => val.clone(),
        None => std::ffi::OsString::from("/root"),
    };
    let HOME = HOME
        .into_string()
        .expect("unable to convert HOME from osstring to string");
    HOME
}

fn get_path_zshrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.zshrc"
}

fn get_content_zshrc() -> std::string::String {
    r#"
export SHELL=zsh
export ZSH="$HOME/.oh-my-zsh"
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
plugins=(eza fzf git starship vi-mode zoxide zsh-interactive-cd)
source "${ZSH}/oh-my-zsh.sh"
eval "$(atuin init zsh)"
"#
    .to_string()
}

fn main() {
    let current_env = get_env();
    let path_home = get_path_home(current_env);
    let path_zshrc = get_path_zshrc(path_home);
    println!("{path_zshrc:?}");

    let mut zshrc: std::string::String = r#"
export SHELL=zsh
export ZSH="$HOME/.oh-my-zsh"
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
plugins=(eza fzf git starship vi-mode zoxide zsh-interactive-cd)
source "${ZSH}/oh-my-zsh.sh"
eval "$(atuin init zsh)"
"#
    .to_string();
}
