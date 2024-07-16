mod fltk;
mod cairo;
mod cairo_utils;
mod lua_module;
mod fs;
mod xdgkit;
mod launch;
mod fuzzy;
mod web_socket;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("fltk", fltk::exports(lua)?)?;
    exports.set("cairo",cairo::exports(lua)?)?;
    exports.set("fs",fs::exports(lua)?)?;
    exports.set("xdgkit",xdgkit::exports(lua)?)?;
    exports.set("launcher",launch::exports(lua)?)?;
    exports.set("matcher",fuzzy::exports(lua)?)?;
    exports.set("web_socket",web_socket::exports(lua)?)?;
    Ok(exports)
}
