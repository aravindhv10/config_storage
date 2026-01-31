use std::str::FromStr;

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

fn get_env() -> std::collections::HashMap<std::ffi::OsString, std::ffi::OsString> {
    let mut current_env =
        std::collections::HashMap::<std::ffi::OsString, std::ffi::OsString>::new();

    for (key, value) in std::env::vars_os() {
        current_env.insert(key, value);
    }

    current_env
}

// Get path for home dir

async fn get_path_home(
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

async fn get_path_github(HOME: std::string::String) -> anyhow::Result<std::string::String> {
    let GITHUB = std::string::String::from(HOME) + "/GITHUB";
    let path = std::path::Path::new(GITHUB.as_str());
    tokio::fs::create_dir_all(path).await?;
    Ok(GITHUB)
}

////////////////////////////////////////////////////////////////
// general shrc begin //////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_shrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.shrc"
}

async fn get_content_shrc() -> std::string::String {
    std::string::String::from(include_str!("shrc"))
}

////////////////////////////////////////////////////////////////
// general shrc end ////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_bashrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.bashrc"
}

async fn get_content_bashrc() -> std::string::String {
    std::string::String::from(include_str!("bashrc"))
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_zshrc(HOME: std::string::String) -> std::string::String {
    HOME + "/.zshrc"
}

async fn get_content_zshrc() -> std::string::String {
    let mut contents_zshrc = std::string::String::from(include_str!("zshrc"));

    match tokio::process::Command::new("atuin")
        .args(["init", "zsh"])
        .output()
        .await
    {
        Ok(o) => {
            match std::str::from_utf8(&o.stdout) {
                Ok(atuin_init) => {
                    contents_zshrc = contents_zshrc + atuin_init;
                    println!("Done initializing atuin");
                }
                Err(e) => {
                    println!("Failed initializing atuin for zsh due to {}", e);
                }
            };
        }
        Err(e) => {
            println!("atuin not found, not initizliaing it for zsh");
        }
    }

    contents_zshrc
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_helix_config(HOME: std::string::String) -> anyhow::Result<std::string::String> {
    let path_str = HOME + "/.config/helix";
    let path = std::path::Path::new(path_str.as_str());
    tokio::fs::create_dir_all(path).await?;
    Ok(path_str + "/config.toml")
}

async fn get_content_helix_config() -> std::string::String {
    std::string::String::from(include_str!("helix_config.toml"))
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_fish_config(HOME: std::string::String) -> anyhow::Result<std::string::String> {
    let path_str = HOME + "/.config/fish";
    let path = std::path::Path::new(path_str.as_str());
    tokio::fs::create_dir_all(path).await?;
    Ok(path_str + "/config.fish")
}

async fn get_content_fish_config() -> std::string::String {
    let mut content_fish: std::string::String =
        std::string::String::from(include_str!("fish_config.fish"));

    match tokio::process::Command::new("atuin")
        .args(["init", "fish"])
        .output()
        .await
    {
        Ok(o) => {
            match std::str::from_utf8(&o.stdout) {
                Ok(o) => {
                    content_fish = content_fish + o;
                }
                Err(e) => {
                    println!("Unable to configure atuin for fish due to {}", e);
                }
            };
        }
        Err(e) => {
            println!("atuin not found")
        }
    }

    match tokio::process::Command::new("starship")
        .args(["init", "fish", "--print-full-init"])
        .output()
        .await
    {
        Ok(o) => {
            match std::str::from_utf8(&o.stdout) {
                Ok(o) => {
                    content_fish = content_fish + o;
                }
                Err(e) => {
                    println!("Unable to configure starship for fish due to {}", e);
                }
            };
        }
        Err(e) => {
            println!("starship not found")
        }
    }

    match tokio::process::Command::new("which")
        .arg("bat")
        .status()
        .await
    {
        Ok(o) => {
            match o.code() {
                Some(c) => {
                    if (c == 0) {
                        content_fish = content_fish
                            + r#"
function cat
    bat $argv
end
"#;
                        println!("Found bat, adding alias to cat for fish");
                    }
                }
                None => {}
            };
        }
        Err(e) => {}
    };

    match tokio::process::Command::new("which")
        .arg("eza")
        .status()
        .await
    {
        Ok(o) => {
            match o.code() {
                Some(c) => {
                    if (c == 0) {
                        content_fish = content_fish
                            + r#"
function ls
    eza -g $argv
end
"#;
                        println!("Found eza, adding alias to ls for fish");
                    }
                }
                None => {}
            };
        }
        Err(e) => {}
    };

    match tokio::process::Command::new("sk")
        .args(["--shell", "fish"])
        .output()
        .await
    {
        Ok(o) => {
            match std::str::from_utf8(&o.stdout) {
                Ok(o) => {
                    content_fish = content_fish + o;
                }
                Err(e) => {
                    println!("Unable to configure atuin for fish due to {}", e);
                }
            };
        }
        Err(e) => {
            println!("atuin not found")
        }
    }

    content_fish
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_alacritty_config(
    HOME: std::string::String,
) -> anyhow::Result<std::string::String> {
    let path_str = HOME + "/.config/alacritty";
    let path = std::path::Path::new(path_str.as_str());
    tokio::fs::create_dir_all(path).await?;
    Ok(path_str + "/alacritty.toml")
}

async fn get_content_alacritty_config() -> std::string::String {
    std::string::String::from(include_str!("alacritty.toml"))
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_foot_config(HOME: std::string::String) -> anyhow::Result<std::string::String> {
    let path_str = HOME + "/.config/foot";
    let path = std::path::Path::new(path_str.as_str());
    tokio::fs::create_dir_all(path).await?;
    Ok(path_str + "//foot.ini")
}

async fn get_content_foot_config() -> std::string::String {
    std::string::String::from(include_str!("foot.ini"))
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

async fn get_path_wezterm_config(HOME: std::string::String) -> std::string::String {
    HOME + "/.wezterm.lua"
}

async fn get_content_wezterm_config() -> std::string::String {
    std::string::String::from(include_str!("wezterm.lua"))
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

struct configurator {
    current_env: std::collections::HashMap<std::ffi::OsString, std::ffi::OsString>,
    path_home: std::string::String,
    path_shrc: std::string::String,
    path_zshrc: std::string::String,
    path_github: std::string::String,
    path_bashrc: std::string::String,
    path_helix_config: std::string::String,
    path_fish_config: std::string::String,
    path_alacritty_config: std::string::String,
    path_foot_config: std::string::String,
    path_wezterm_config: std::string::String,
}

impl configurator {
    async fn new() -> anyhow::Result<Self> {
        let current_env = get_env();
        let path_home = get_path_home(&current_env).await;

        let (
            path_shrc,
            path_zshrc,
            path_github,
            path_bashrc,
            path_helix_config,
            path_fish_config,
            path_alacritty_config,
            path_foot_config,
            path_wezterm_config,
        ) = tokio::join!(
            get_path_shrc(path_home.clone()),
            get_path_zshrc(path_home.clone()),
            get_path_github(path_home.clone()),
            get_path_bashrc(path_home.clone()),
            get_path_helix_config(path_home.clone()),
            get_path_fish_config(path_home.clone()),
            get_path_alacritty_config(path_home.clone()),
            get_path_foot_config(path_home.clone()),
            get_path_wezterm_config(path_home.clone()),
        );

        Ok(configurator {
            current_env: current_env,
            path_home: path_home,
            path_shrc: path_shrc,
            path_zshrc: path_zshrc,
            path_github: path_github?,
            path_bashrc: path_bashrc,
            path_helix_config: path_helix_config?,
            path_fish_config: path_fish_config?,
            path_alacritty_config: path_alacritty_config?,
            path_foot_config: path_foot_config?,
            path_wezterm_config: path_wezterm_config,
        })
    }

    async fn get_github_repo(
        self: &Self,
        github_url: std::string::String,
    ) -> anyhow::Result<std::string::String> {
        let starting_point = "https://github.com".len();
        let ending_point = github_url.len() - ".git".len();
        let new_url = self.path_github.clone() + &github_url.clone()[starting_point..ending_point];
        let path = std::path::Path::new(new_url.as_str());
        tokio::fs::create_dir_all(path).await?;

        match tokio::process::Command::new("git")
            .current_dir(path)
            .arg("clone")
            .arg(github_url)
            .arg(".")
            .output()
            .await
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

        match tokio::process::Command::new("git")
            .current_dir(path)
            .arg("pull")
            .arg("--ff-only")
            .output()
            .await
        {
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

        match tokio::process::Command::new("git")
            .current_dir(path)
            .arg("submodule")
            .arg("update")
            .arg("--recursive")
            .arg("--init")
            .output()
            .await
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

        Ok(new_url)
    }

    async fn update_config_store(self: &Self) -> anyhow::Result<()> {
        self.get_github_repo("https://github.com/aravindhv10/config_storage.git".to_string())
            .await?;

        Ok(())
    }

    async fn get_oh_my_zsh(self: &Self) -> anyhow::Result<()> {
        self.get_github_repo("https://github.com/ohmyzsh/ohmyzsh.git".to_string())
            .await?;

        match tokio::fs::symlink(
            "./GITHUB/ohmyzsh/ohmyzsh",
            self.path_home.clone() + "/.oh-my-zsh",
        )
        .await
        {
            Ok(_) => {
                println!("Created oh-my-zsh symlink");
            }
            Err(e) => {
                println!("failed to create symlink {}", e);
            }
        }

        Ok(())
    }

    async fn setup_all_config(self: &Self) -> anyhow::Result<()> {
        let status = tokio::join!(
            tokio::fs::write(&self.path_shrc, get_content_shrc().await),
            tokio::fs::write(&self.path_zshrc, get_content_zshrc().await),
            tokio::fs::write(&self.path_bashrc, get_content_bashrc().await),
            tokio::fs::write(&self.path_helix_config, get_content_helix_config().await),
            tokio::fs::write(&self.path_fish_config, get_content_fish_config().await),
            tokio::fs::write(
                &self.path_alacritty_config,
                get_content_alacritty_config().await
            ),
            tokio::fs::write(&self.path_foot_config, get_content_foot_config().await),
            tokio::fs::write(
                &self.path_wezterm_config,
                get_content_wezterm_config().await
            ),
            self.get_oh_my_zsh(),
            self.update_config_store()
        );
        status.0?;
        status.1?;
        status.2?;
        status.3?;
        status.4?;
        status.5?;
        status.6?;
        status.7?;
        Ok(())
    }
}

async fn do_all_config() -> anyhow::Result<()> {
    let slave = configurator::new().await?;
    slave.setup_all_config().await
}

fn do_all_config_wrapper() {
    let runtime = tokio::runtime::Builder::new_multi_thread()
        .thread_stack_size(1 << 23)
        .enable_all()
        .build()
        .expect("Unable to construct the tokio runtime");

    runtime.block_on(async { do_all_config().await });
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

fn main() {
    do_all_config_wrapper();
}
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
