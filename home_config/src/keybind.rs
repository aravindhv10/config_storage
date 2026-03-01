use std::os::unix::process::CommandExt;
use std::process::Command;

fn main() {
    // Get the first argument, which is the path used to invoke the binary
    let path = std::env::args().next().expect("No executable path found");

    // Extract the filename (basename) from the path
    let binary_name = std::path::Path::new(&path)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("");

    // Dispatch based on the name
    match binary_name {
        "M_C_Q" => {
            let err = Command::new("wezterm").exec();
        }
        "M_C_W" => {}
        "M_C_E" => {}
        "M_C_R" => {}
        "M_C_T" => {}
        "M_C_A" => {
            let err = Command::new("firefox").exec();
        }
        "M_C_S" => {
            let err = Command::new("thorium")
                .arg("--enable-features=UseOzonePlatform")
                .arg("--ozone-platform=wayland")
                .exec();
        }
        "M_C_D" => {
            let err = Command::new("dolphin").exec();
        }
        "M_C_F" => {
            let err = Command::new("pavucontrol").exec();
        }
        "M_C_G" => {
            let err = Command::new("footclient").arg("nmtui").exec();
        }
        _ => {
            println!("Unknown command: {}. Defaulting to help.", binary_name);
        }
    }
}
