use crate::lua_module::*;
use mlua::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct Test {
    a: u32,
}
impl LuaUserData for Test {}

AddMethods!(xdgkit::desktop_entry::DesktopEntry,methods=>{

});

fn load_desktop_entries(pathes: Vec<String>) -> Vec<(String, xdgkit::desktop_entry::DesktopEntry)> {
    let mut r = Vec::new();
    for path in pathes.iter() {
        if let Ok(items) = std::fs::read_dir(path).map_err(|e| {
            eprintln!("Failed to read path :{} {:?}", path, e);
        }) {
            for entry in items {
                if let Ok(entry) = entry {
                    if entry
                        .file_type()
                        .map(|t| t.is_file() || t.is_symlink())
                        .unwrap_or(false)
                        && entry.file_name().to_string_lossy().ends_with(".desktop")
                    {
                        let filename = entry.file_name();
                        r.push((
                            filename.to_string_lossy().to_string(),
                            xdgkit::desktop_entry::DesktopEntry::new(String::from(
                                entry.path().to_string_lossy(),
                            )),
                        ));
                    }
                }
            }
        }
    }
    r
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "load_desktop_entries",
        lua.create_function(|lua, pathes: Vec<String>| {
            let entries = load_desktop_entries(pathes)
                .iter()
                .map(|(filename, entry)| {
                    let value = lua
                        .to_value(&serde_json::json!({
                            "filename":filename,
                            "name": entry.name.as_ref().unwrap_or(&String::new()),
                            "generic_name":entry.generic_name.as_ref().unwrap_or(&String::new()),
                            "icon_name":entry.icon.as_ref().unwrap_or(&String::new()),
                            "keywords":entry.keywords.as_ref().unwrap_or(&Vec::new())
                        }))
                        .unwrap();
                    value
                })
                .collect::<Vec<_>>();
            Ok(entries)
        })?,
    )?;
    exports.set(
        "find_icon",
        lua.create_function(|lua, name: String| {
            Ok(freedesktop_icons::lookup(name.as_str())
                .with_size(36)
                .find()
                .map(|path| path.to_string_lossy().to_string())
                .unwrap_or(String::new()))
        })?,
    )?;
    Ok(exports)
}
