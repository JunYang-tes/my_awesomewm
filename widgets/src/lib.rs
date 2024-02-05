mod gtk;
mod gdk;
mod gtk_enums;
mod gtk_events;
mod gtk_style;
mod fltk;
mod lua_module;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("fltk", fltk::exports(lua)?)?;
    exports.set("gtk", gtk::exports(lua)?)?;
    exports.set("gdk",gdk::gdk(lua)?)?;
    Ok(exports)
}
