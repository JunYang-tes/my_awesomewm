mod gtk;
mod gtk_enums;
mod fltk;
mod lua_module;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("fltk", fltk::exports(lua)?)?;
    exports.set("gtk", gtk::exports(lua)?)?;
    Ok(exports)
}
