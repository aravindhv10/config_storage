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

fn get_path_zshrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.zshrc"
}

fn get_path_shrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.shrc"
}

fn get_path_github(HOME: std::string::String) -> std::string::String {
    HOME + "/GITHUB"
}

fn get_content_shrc() -> std::string::String {
    r#"
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
"#
    .to_string()
}

fn get_content_zshrc() -> std::string::String {
    r#"
. "${HOME}/.shrc"
export SHELL=zsh
export ZSH="$HOME/.oh-my-zsh"
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
plugins=(eza fzf git starship vi-mode zoxide zsh-interactive-cd)
source "${ZSH}/oh-my-zsh.sh"
eval "$(atuin init zsh)"
"#
    .to_string()
}

struct configurator {
    current_env: std::collections::HashMap<std::ffi::OsString, std::ffi::OsString>,
    path_home: std::string::String,
    path_shrc: std::string::String,
    path_zshrc: std::string::String,
    path_github: std::string::String,
}

impl configurator {
    fn new() -> Self {
        let current_env = get_env();
        let path_home = get_path_home(&current_env);
        let path_shrc = get_path_shrc(path_home.clone());
        let path_zshrc = get_path_zshrc(path_home.clone());
        let path_github = get_path_github(path_home.clone());
        configurator {
            current_env: current_env,
            path_home: path_home,
            path_shrc: path_shrc,
            path_zshrc: path_zshrc,
            path_github: path_github,
        }
    }

    fn get_github_repo(self: &Self, github_url: std::string::String) -> std::string::String {
        // https://github.com/ohmyzsh/ohmyzsh.git

        let starting_point = "https://github.com".len();
        let ending_point = github_url.len() - ".git".len();
        let new_url = self.path_github.clone() + &github_url.clone()[starting_point..ending_point];
        let path = std::path::Path::new(new_url.as_str());

        match std::fs::create_dir_all(path) {
            Ok(_) => println!("Directories created successfully or already existed."),
            Err(e) => eprintln!("Error creating directories: {}", e),
        }

        let command = std::process::Command::new("git")
            .arg("clone")
            .arg(github_url)
            .arg(&new_url)
            .output();

        match command {
            Ok(output) => {
                // Check if the command executed successfully.
                if output.status.success() {
                    // Convert the stdout bytes to a UTF-8 string and print it.
                    println!(
                        "Command output: {}",
                        String::from_utf8_lossy(&output.stdout)
                    );
                } else {
                    // Print an error message if the command failed.
                    eprintln!("Command failed with exit code: {}", output.status);
                    eprintln!("Stderr: {}", String::from_utf8_lossy(&output.stderr));
                }
            }
            Err(e) => {
                // Handle any errors that occurred during command execution.
                eprintln!("Failed to execute command: {}", e);
            }
        }

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
        self.get_oh_my_zsh();
    }
}

fn main() {
    let slave = configurator::new();
    slave.setup_shell();
}
