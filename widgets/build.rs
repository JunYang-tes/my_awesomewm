use std::{env, path::{PathBuf, Path}};
use std::fs;

fn main() {
    let mut path = get_output_path();
    path.push("libwidgets.so");
    let mut target = PathBuf::from(
        env::var("CARGO_MANIFEST_DIR").unwrap()
    );
    target.push("../lua/widgets.so");
    println!("cp {} to {}",path.to_string_lossy(),target.to_string_lossy());
    let r = fs::copy(path,target);
    println!("{:?}",r);
}
fn get_output_path() -> PathBuf {
    //<root or manifest path>/target/<profile>/
    let manifest_dir_string = env::var("CARGO_MANIFEST_DIR").unwrap();
    let build_type = env::var("PROFILE").unwrap();
    let path = Path::new(&manifest_dir_string).join("target").join(build_type);
    return PathBuf::from(path);
}

