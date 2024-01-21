//mod gtk;
mod fltk;
mod widgets;
mod win;
mod lua_module;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("win", win::exports(lua)?)?;
    exports.set("fltk", fltk::exports(lua)?)?;
    // exports.set("gtk", gtk::exports(lua)?)?;
    exports.set("widgets", widgets::exports(lua)?)?;
    Ok(exports)
}
