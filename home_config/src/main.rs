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
    current_env: &std::collections::HashMap<std::ffi::OsString, std::ffi::OsString>,
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

fn get_path_shrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.shrc"
}

fn get_path_bashrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.bashrc"
}

fn get_path_zshrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.zshrc"
}

fn get_path_github(HOME: std::string::String) -> std::string::String {
    HOME + "/GITHUB"
}

fn get_path_helix_config(HOME: std::string::String) -> std::string::String {
    let path_str = HOME + "/.config/helix/";
    let path = std::path::Path::new(path_str.as_str());

    match std::fs::create_dir_all(path) {
        Ok(o) => println!("Created directory {}.", path_str.as_str()),
        Err(e) => eprintln!(
            "Error creating directories {} due to {}",
            path_str.as_str(),
            e
        ),
    }

    path_str + "/config.toml"
}

fn get_path_fish_config(HOME: std::string::String) -> std::string::String {
    let path_str = HOME + "/.config/fish/";
    let path = std::path::Path::new(path_str.as_str());

    match std::fs::create_dir_all(path) {
        Ok(o) => println!("Created directory {}.", path_str.as_str()),
        Err(e) => eprintln!(
            "Error creating directories {} due to {}",
            path_str.as_str(),
            e
        ),
    }

    path_str + "/config.fish"
}

fn get_content_shrc() -> std::string::String {
    r#"
export SUDO_ASKPASS="$HOME/SUDO_ASKPASS"
"#
    .to_string()
}

fn get_content_bashrc() -> std::string::String {
    r#"
. "${HOME}/.shrc"
export SHELL=bash
eval -- "$(starship init bash --print-full-init)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
"#
    .to_string()
}

fn get_content_zshrc() -> std::string::String {
    r#"
. "${HOME}/.shrc"
export SHELL=zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(eza fzf git starship vi-mode zoxide zsh-interactive-cd)
source "${ZSH}/oh-my-zsh.sh"
eval "$(atuin init zsh)"
"#
    .to_string()
}

fn get_content_helix_config() -> std::string::String {
    r#"
theme = "modus_vivendi"

[editor]
    true-color = true

[editor.lsp]
    display-inlay-hints = true
"#
    .to_string()
}

fn get_content_fish_config() -> std::string::String {
    r#"
. "$HOME/.shrc"
atuin init fish | source
source (starship init fish --print-full-init | psub)

fish_vi_key_bindings

function ls
    eza -g $argv
end

function cat
    bat $argv
end



"#
    .to_string()
}

struct configurator {
    current_env: std::collections::HashMap<std::ffi::OsString, std::ffi::OsString>,
    path_home: std::string::String,
    path_shrc: std::string::String,
    path_zshrc: std::string::String,
    path_github: std::string::String,
    path_bashrc: std::string::String,
    path_helix_config: std::string::String,
    path_fish_config: std::string::String,
}

impl configurator {
    fn new() -> Self {
        let current_env = get_env();
        let path_home = get_path_home(&current_env);
        let path_shrc = get_path_shrc(path_home.clone());
        let path_zshrc = get_path_zshrc(path_home.clone());
        let path_github = get_path_github(path_home.clone());
        let path_bashrc = get_path_bashrc(path_home.clone());
        let path_helix_config = get_path_helix_config(path_home.clone());
        let path_fish_config = get_path_fish_config(path_home.clone());
        configurator {
            current_env: current_env,
            path_home: path_home,
            path_shrc: path_shrc,
            path_zshrc: path_zshrc,
            path_github: path_github,
            path_bashrc: path_bashrc,
            path_helix_config: path_helix_config,
            path_fish_config: path_fish_config,
        }
    }

    fn get_github_repo(self: &Self, github_url: std::string::String) -> std::string::String {
        let starting_point = "https://github.com".len();
        let ending_point = github_url.len() - ".git".len();
        let new_url = self.path_github.clone() + &github_url.clone()[starting_point..ending_point];
        let path = std::path::Path::new(new_url.as_str());

        match std::fs::create_dir_all(path) {
            Ok(o) => println!("Created directory {}.", new_url.as_str()),
            Err(e) => eprintln!("Error creating directories: {}", e),
        }

        match std::env::set_current_dir(path) {
            Ok(_) => {
                println!("Currently in dir {}", new_url.as_str());
            }
            Err(e) => {
                println!("Failed to change to dir {} due to {}", new_url.as_str(), e);
            }
        }

        match std::process::Command::new("git")
            .arg("clone")
            .arg(github_url)
            .arg(".")
            .output()
        {
            Ok(output) => {
                if output.status.success() {
                    println!(
                        "Command output: {}",
                        String::from_utf8_lossy(&output.stdout)
                    );
                } else {
                    eprintln!("Command failed with exit code: {}", output.status);
                    eprintln!("Stderr: {}", String::from_utf8_lossy(&output.stderr));
                }
            }
            Err(e) => {
                eprintln!("Failed to execute command: {}", e);
            }
        }

        match std::process::Command::new("git").arg("pull").output() {
            Ok(o) => {
                println!(
                    "git pull executed successfully,\n{:?}\n{:?}",
                    std::string::String::from_utf8_lossy(&o.stdout),
                    std::string::String::from_utf8_lossy(&o.stderr),
                )
            }
            Err(e) => {
                println!("git pulled failed due to {}", e);
            }
        }

        match std::process::Command::new("git")
            .arg("submodule")
            .arg("update")
            .arg("--recursive")
            .arg("--init")
            .output()
        {
            Ok(o) => {
                println!(
                    "git submodule update,\n{:?}\n{:?}",
                    std::string::String::from_utf8_lossy(&o.stdout),
                    std::string::String::from_utf8_lossy(&o.stderr),
                );
            }
            Err(e) => {
                println!("Failed git submodule update failed due to: {}", e);
            }
        };

        new_url
    }

    fn get_oh_my_zsh(self: &Self) {
        let _ = self.get_github_repo("https://github.com/ohmyzsh/ohmyzsh.git".to_string());
        match std::os::unix::fs::symlink(
            "./GITHUB/ohmyzsh/ohmyzsh",
            self.path_home.clone() + "/.oh-my-zsh",
        ) {
            Ok(_) => {
                println!("Created oh-my-zsh symlink")
            }
            Err(e) => {
                println!("failed to create symlink {}", e);
            }
        }
    }

    fn setup_shell(self: &Self) {
        std::fs::write(&self.path_shrc, get_content_shrc()).expect("Unable to write shrc");
        std::fs::write(&self.path_zshrc, get_content_zshrc()).expect("Unable to write zshrc");
        std::fs::write(&self.path_bashrc, get_content_bashrc()).expect("Unable to write bashrc");
        std::fs::write(&self.path_helix_config, get_content_helix_config())
            .expect("Unable to write helix config");
        std::fs::write(&self.path_fish_config, get_content_fish_config())
            .expect("Unable to write bashrc");
        self.get_oh_my_zsh();
    }
}

fn main() {
    let slave = configurator::new();
    slave.setup_shell();
}
