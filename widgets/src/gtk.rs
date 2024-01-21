use std::sync::Arc;

use gtk::{prelude::ApplicationExtManual, Application, ApplicationWindow};
use gtk::{prelude::*, Button};
use mlua::prelude::*;

lua_module::LuaUserDataWrapper!(Win, ApplicationWindow);

struct App {
    ctx: gtk::glib::MainContext,
}
impl App {
    fn init() {
        let c = gtk::glib::MainContext::default();
        c.iteration(false)
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("app", lua.create_function(app)?)?;
    Ok(exports)
}
