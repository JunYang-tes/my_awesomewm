mod gtk;
mod win;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("win", win::exports(lua)?)?;
    exports.set("gtk", gtk::exports(lua)?)?;
    Ok(exports)
}
