use fltk::{
    app::{self, wait_for},
    prelude::*,
};

use mlua::prelude::*;
use std::{
    any::Any,
    ops::{Deref, DerefMut},
};
trait FltkWrapper<T: WidgetExt> {
    fn get(&self) -> &T;
}

macro_rules! FltkWrapper {
    ($name:ident, $t:ty) => {
        #[derive(Debug)]
        struct $name($t);
        impl Deref for $name {
            type Target = $t;
            fn deref(&self) -> &Self::Target {
                &self.0
            }
        }
        impl DerefMut for $name {
            fn deref_mut(&mut self) -> &mut Self::Target {
                &mut self.0
            }
        }
    };
}
macro_rules! MakeFltkWidgetWrapper {
    ($name:ident,$t:ty) => {
        FltkWrapper!($name, $t);
        impl $name {
            fn default() -> $name {
                $name(<$t>::default())
            }
        }
        impl FltkWrapper<$t> for $name {
            fn get(&self) -> &$t {
                &self.0
            }
        }
    };
}
FltkWrapper!(App, fltk::app::App);
FltkWrapper!(Win, fltk::window::Window);

impl LuaUserData for App {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("run", |_, app, ()| {
            app.run().unwrap();
            Ok(())
        });
        methods.add_method("wait", |_, app, ()| wait_for(0.001).or(Ok(false)))
    }
}
macro_rules! ParamlessCall {
    ($methods:ident,$($name:ident),*) => {
        $($methods.add_method_mut(stringify!($name), |_, self_, ()| {
            self_.$name();
            Ok(())
        });)*
    };
}
impl LuaUserData for Win {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        ParamlessCall!(methods, show, begin, end);
        methods.add_method_mut("add", |_, win, child: usize| {
            let b = unsafe {
                fltk::widget::Widget::from_widget_ptr(child as *mut fltk_sys::widget::Fl_Widget)
            };
            win.add(&b);
            Ok(())
        });
    }
}
MakeFltkWidgetWrapper!(Button, fltk::button::Button);
impl LuaUserData for Button {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("set_label", |_, btn, l: LuaString| {
            btn.set_label(l.to_str().unwrap());
            Ok(())
        });
        methods.add_method("addr", |_, btn, ()| Ok(btn.as_widget_ptr() as usize))
    }
}
MakeFltkWidgetWrapper!(Frame, fltk::frame::Frame);
impl LuaUserData for Frame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("set_label", |_, btn, l: LuaString| {
            btn.set_label(l.to_str().unwrap());
            Ok(())
        });
        methods.add_method("addr", |_, btn, ()| Ok(btn.as_widget_ptr() as usize))
    }
}

MakeFltkWidgetWrapper!(Flex, fltk::group::Flex);
impl LuaUserData for Flex {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        ParamlessCall!(methods, show, end);
        methods.add_method_mut("set_label", |_, btn, l: LuaString| {
            btn.set_label(l.to_str().unwrap());
            Ok(())
        });
        methods.add_method("addr", |_, btn, ()| Ok(btn.as_widget_ptr() as usize));
        methods.add_method_mut("add", |_, win, child: usize| {
            let b = unsafe {
                fltk::widget::Widget::from_widget_ptr(child as *mut fltk_sys::widget::Fl_Widget)
            };
            win.add(&b);
            Ok(())
        });
    }
}
macro_rules! exports {
    ($lua:ident,$($name:literal,$value:expr),*,) => {
        {
            let exports = $lua.create_table()?;
            $(exports.set($name,$lua.create_function(|_,()|Ok($value))?)?;)*
            Ok(exports)
        }
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        App(fltk::app::App::default()),
        "win",
        Win(fltk::window::Window::default().with_size(400, 400)),
        "button",
        Button::default(),
        "frame",
        Frame::default(),
        "flex",
        Flex::default(),
    )
    // let exports = lua.create_table()?;
    // exports.set(
    //     "app",
    //     lua.create_function(|_, ()| Ok(App(fltk::app::App::default())))?,
    // )?;
    // exports.set(
    //     "win",
    //     lua.create_function(|_, ()| Ok(Win(fltk::window::Window::default().with_size(400, 300))))?,
    // )?;
    // exports.set(
    //     "button",
    //     lua.create_function(|_, ()| {
    //         Ok(Button(fltk::button::Button::default().with_size(100, 100)))
    //     })?,
    // )?;
    // exports.set(
    //     "frame",
    //     lua.create_function(|_, ()| Ok(Frame(fltk::frame::Frame::default().with_size(100, 100))))?,
    // )?;
    // exports.set(
    //     "flex",
    //     lua.create_function(|_, ()| Ok(Flex(fltk::group::Flex::default().with_size(100, 200))))?,
    // )?;
    //
    // Ok(exports)
}
