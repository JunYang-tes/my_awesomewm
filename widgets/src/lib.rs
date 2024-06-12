mod gtk4;
mod gdk4;
mod gtk4_enums;
mod fltk;
mod cairo;
mod cairo_utils;
mod lua_module;
mod fs;
mod gtk4_css;
mod xdgkit;
mod launch;
mod fuzzy;
mod web_socket;
pub mod qt;

use mlua::prelude::*;

#[mlua::lua_module]
fn widgets(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("fltk", fltk::exports(lua)?)?;
    exports.set("gtk4",gtk4::exports(lua)?)?;
    exports.set("gdk4",gdk4::exports(lua)?)?;
    exports.set("gtk4_css",gtk4_css::exports(lua)?)?;
    exports.set("cairo",cairo::exports(lua)?)?;
    exports.set("fs",fs::exports(lua)?)?;
    exports.set("xdgkit",xdgkit::exports(lua)?)?;
    exports.set("launcher",launch::exports(lua)?)?;
    exports.set("matcher",fuzzy::exports(lua)?)?;
    exports.set("web_socket",web_socket::exports(lua)?)?;
    exports.set("qt",qt::exports(lua)?)?;
    Ok(exports)
}
