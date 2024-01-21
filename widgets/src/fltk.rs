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
macro_rules! Getter {
    ($methods:ident,$($name:ident),*) => {
        $($methods.add_method_mut(stringify!($name),|_,self_,()|{
            Ok(self_.$name())
        });)*
    }
}
macro_rules! Setter {
    ($methods:ident,$($name:ident,$type:ty),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,v:$type|{
            w.$name(v);
            Ok(())
        });)*
    };
    ($methods:ident,$($name:ident $type:ty),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,v:$type|{
            w.$name(v);
            Ok(())
        });)*
    };
    ($methods:ident,$($name:ident,$lua_type:ty,
                      $input:ident => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        }))*
    }
}
macro_rules! WidgetBaseMethods {
    ($methods:ident) => {
        $methods.add_method("widget", |_, w, ()| Ok(w.as_widget_ptr() as usize));
        $methods.add_meta_method("__call", |_, s, ()| Ok(s.as_widget_ptr() as usize));
        //ParamlessCall!($methods,delete)
    };
}
macro_rules! WidgetExtMethods {
    ($methods:ident) => {
        ParamlessCall!($methods, show, hide, activate, deactivate);
        Getter!($methods, x, y, width, height, label, measure_label);

        $methods.add_method_mut("set_size", |_, w, (width, height): (i32, i32)| {
            //WidgetExt::set_size(&mut w,width,height);
            WidgetExt::set_size(&mut w.0, width, height);
            Ok(())
        });
        $methods.add_method_mut("set_pos", |_, w, (x, y): (i32, i32)| {
            w.set_pos(x, y);
            Ok(())
        });
        $methods.add_method_mut("set_label", |_, w, l: LuaString| {
            w.set_label(l.to_str().unwrap());
            Ok(())
        });
        $methods.add_method_mut("set_frame", |_, w, v: i32| {
            w.set_frame(unsafe { fltk::enums::FrameType::from_i32(v) });
            Ok(())
        });
        $methods.add_method_mut("set_tooltip", |_, w, v: String| {
            w.set_tooltip(v.as_str());
            Ok(())
        })
    };
}
fn get_widget_from_ptr(ptr: usize) -> fltk::widget::Widget {
    unsafe { fltk::widget::Widget::from_widget_ptr(ptr as *mut fltk_sys::widget::Fl_Widget) }
}
macro_rules! WidgetGroupMehods {
    ($methods:ident) => {
        ParamlessCall!($methods, begin, end, clear);
        Getter!($methods, children);
        Setter!($methods, make_resizable, bool);
        $methods.add_method_mut("resizable", |_, g, child: usize| {
            let b = get_widget_from_ptr(child);
            g.resizable(&b);
            Ok(())
        });
        $methods.add_method_mut("add", |_, g, child: usize| {
            let b = get_widget_from_ptr(child);
            g.add(&b);
            Ok(())
        });
        $methods.add_method_mut("insert", |_, g, (child, idx): (usize, i32)| {
            let b = get_widget_from_ptr(child);
            g.insert(&b, idx);
            Ok(())
        });
        $methods.add_method_mut("remove", |_, g, child: usize| {
            let b = get_widget_from_ptr(child);
            g.remove(&b);
            Ok(())
        });
        $methods.add_method_mut("remove_by_index", |_, g, idx: i32| {
            g.remove_by_index(idx);
            Ok(())
        });
    };
}
impl LuaUserData for Win {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        WidgetBaseMethods!(methods);
        WidgetExtMethods!(methods);
        WidgetGroupMehods!(methods);
    }
}
MakeFltkWidgetWrapper!(Button, fltk::button::Button);
impl LuaUserData for Button {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        WidgetBaseMethods!(methods);
        WidgetExtMethods!(methods);
    }
}
MakeFltkWidgetWrapper!(Frame, fltk::frame::Frame);
impl LuaUserData for Frame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        WidgetBaseMethods!(methods);
        WidgetExtMethods!(methods);
    }
}

MakeFltkWidgetWrapper!(Flex, fltk::group::Flex);
impl LuaUserData for Flex {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        WidgetBaseMethods!(methods);
        WidgetExtMethods!(methods);
        WidgetGroupMehods!(methods);
        ParamlessCall!(methods, row, recalc, layout, column);
        Setter!(
            methods,
            fixed (usize, i32),
            set_margin i32,
            set_pad i32,
            set_spacing i32,
            set_margins (i32,i32,i32,i32)
        );
    }
}
impl Flex {
    fn fixed(&mut self, args: (usize, i32)) -> () {
        self.0.fixed(&get_widget_from_ptr(args.0), args.1)
    }
    fn set_margins(&mut self, args: (i32, i32, i32, i32)) -> () {
        self.0.set_margins(args.0, args.1, args.2, args.3)
    }
    fn row(&mut self) -> () {
        self.set_type(fltk::group::FlexType::Row)
    }
    fn column(&mut self) -> () {
        self.set_type(fltk::group::FlexType::Column)
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
MakeFltkWidgetWrapper!(Pack, fltk::group::Pack);
impl LuaUserData for Pack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        WidgetBaseMethods!(methods);
        WidgetExtMethods!(methods);
        WidgetGroupMehods!(methods);
        Getter!(methods, spacing);
        Setter!(methods, set_spacing, i32);
        Setter!(methods, set_type,i32,i => match i {
            0 => fltk::group::PackType::Vertical,
            _ => fltk::group::PackType::Horizontal
        });
        ParamlessCall!(methods, auto_layout);
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
        "pack",
        Pack::default(),
    )
}
