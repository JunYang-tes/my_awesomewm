mod win;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("win", win::exports(lua)?)?;
    Ok(exports)
}

