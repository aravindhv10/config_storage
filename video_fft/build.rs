fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo:rustc-link-arg=-lmytorch");
    Ok(())
}
