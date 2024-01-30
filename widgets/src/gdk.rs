use crate::lua_module::*;
use mlua::prelude::*;
AddMethods!(gtk::gdk::Screen,methods=>{});

pub fn gdk(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "screen",
        LuaWrapper(gtk::gdk::Screen::default().unwrap()),
    )
}
