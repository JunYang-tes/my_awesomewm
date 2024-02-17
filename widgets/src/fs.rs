use mlua::prelude::*;

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "dir",
        lua.create_function(|_, path: String| {
            let items = std::fs::read_dir(path.as_str());
            if let Ok(items) = items {
                Ok(items
                    .map(|res| res.map(|e| e.path().to_str().map(|s| String::from(s))))
                    .filter(|i| i.is_ok())
                    .map(|i| i.unwrap())
                    .filter(|i| i.is_some())
                    .map(|i| i.unwrap())
                    .collect::<Vec<_>>())
            } else {
                eprintln!("Failed to read {},error is {:?}", path, items);
                Ok(Vec::<String>::new())
            }
        })?,
    )?;
    Ok(exports)
}
