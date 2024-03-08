use crate::lua_module::*;
use mlua::prelude::*;

AddMethods!(gtk4::gdk::Texture,methods=>{});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "texture_from_file",
        lua.create_function(|_, file: String| {
            Ok(LuaWrapper(
                gtk4::gdk::Texture::from_filename(&std::path::Path::new(file.as_str())).unwrap(),
            ))
        })?,
    )?;
    Ok(exports)
}
