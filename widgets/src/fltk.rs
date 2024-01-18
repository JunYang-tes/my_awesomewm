use fltk::{app, button::Button, frame::Frame, prelude::*, window::Window};

extern crate fltk as fltk_;
use fltk_::{prelude::WidgetExt, app::wait_for};
use mlua::prelude::*;
use std::ops::{Deref, DerefMut};

struct App(fltk::app::App);
impl Deref for App {
    type Target = fltk::app::App;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for App {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl LuaUserData for App {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("run", |_, app, ()| {
            app.run().unwrap();
            Ok(())
        });
        methods.add_method("wait", |_, app, ()|wait_for(0.001).or(Ok(false)))
    }
}

struct Win(fltk::window::Window);
impl Deref for Win {
    type Target = fltk::window::Window;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for Win {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
impl LuaUserData for Win {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("show", |_, win, ()| {
            win.show();
            Ok(())
        })
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "app",
        lua.create_function(|_, ()| Ok(App(fltk::app::App::default())))?,
    )?;
    exports.set(
        "win",
        lua.create_function(|_, ()| Ok(Win(fltk::window::Window::default().with_size(400, 300))))?,
    )?;
    Ok(exports)
}
