use crate::lua_module::*;
use gtk::{prelude::*, Button, Entry,Window};
use mlua::prelude::*;
use mlua::prelude::*;
use std::ops::{Deref, DerefMut};

struct App {
    ctx: gtk::glib::MainContext,
}
impl App {
    fn new() -> App {
        gtk::init().unwrap();
        App {
            ctx: gtk::glib::MainContext::default(),
        }
    }
    fn iteration(&self, block: bool) -> bool {
        self.ctx.iteration(block)
    }
}
impl LuaUserData for App {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        Setter!(methods, iteration, bool);
    }
}

macro_rules! Basic {
    ($methods:ident) => {};
}
macro_rules! GtkWidgetExt {
    ($method:ident) => {
        ParamlessCall!($method, show);
        Getter!($method, width_request, height_request,margin);
        Setter!($method, set_expand bool,
                set_has_default bool,
                set_has_focus bool,
                set_height_request i32,
                set_width_request i32,
                set_is_focus bool,
                set_margin i32);
    };
}
macro_rules! MatchLuaUserData {
    ($data:ident,
     $item: ident => $exp : block,
     $($type:ty,)*) => {
        $(
        if $data.is::<$type>() {
            let $item = $data.borrow::<$type>().unwrap();
            $exp;
        }
         )*
    };
}
macro_rules! MatchWidget {
    ($data:ident,
     $item: ident => $exp :block) => {MatchLuaUserData!($data, $item => $exp, Btn,Textbox,Box,);}
}
macro_rules! GtkContainer {
    ($methods:ident) => {
        $methods.add_method_mut("add", |_, container, child: LuaValue| {
            match child {
                LuaValue::UserData(data) => {
                    MatchWidget!(data, item => {
                        container.add(&item.0);
                        return Ok(())
                    });
                }
                _ => {}
            }
            Ok(())
        })
    };
}

LuaUserDataWrapper!(Win, Window);
impl LuaUserData for Win {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkContainer!(methods);
        Getter!(methods,);
        ParamlessCall!(methods, present, maximize, close);
    }
}

LuaUserDataWrapper!(Btn, Button);
impl LuaUserData for Btn {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        Basic!(methods);
        GtkWidgetExt!(methods);
        Setter!(methods, set_label String: s => s.as_str());
    }
}
LuaUserDataWrapper!(Textbox, Entry);
impl LuaUserData for Textbox {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        Getter!(methods, text str => String::from(str));
        Setter!(methods,set_text String: str=> str.as_str());
        Basic!(methods);
    }
}
LuaUserDataWrapper!(Box, gtk::Box);
impl LuaUserData for Box {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        methods.add_method_mut(
            "pack_start",
            |_, b, (child, expand, fill, padding): (LuaValue, bool, bool, u32)| {
                match child {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data,
                        child => {
                            b.pack_start(&child.0,expand,fill,padding);
                        });
                    }
                    _ => {}
                }
                Ok(())
            },
        );
        methods.add_method_mut(
            "pack_end",
            |_, b, (child, expand, fill, padding): (LuaValue, bool, bool, u32)| {
                match child {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data,
                        child => {
                            b.pack_end(&child.0,expand,fill,padding);
                        });
                    }
                    _ => {}
                }
                Ok(())
            },
        );
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        App::new(),
        "win",
        Win(Window::new(gtk::WindowType::Toplevel)),
        "button",
        Btn(Button::new()),
        "textbox",
        Textbox(Entry::new()),
        "box",
        Box(gtk::Box::new(gtk::Orientation::Horizontal, 0)),
    )
}
