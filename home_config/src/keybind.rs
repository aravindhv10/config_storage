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
        "M_C_A" => ,
        _ => {
            println!("Unknown command: {}. Defaulting to help.", binary_name);
            show_help();
        }
    }
}
