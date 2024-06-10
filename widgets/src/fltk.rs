use crate::lua_module::*;
use fltk::{app::wait_for, prelude::*};

use mlua::prelude::*;
use std::ops::{Deref, DerefMut};
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

macro_rules! AddMethods {
    ($type:ty, $methods:ident => $block:block) => {
        impl LuaUserData for LuaWrapper<$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
    };
}

impl LuaUserData for App {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("run", |_, app, ()| {
            app.run().unwrap();
            Ok(())
        });
        methods.add_method("wait", |_, _app, ()| wait_for(0.001).or(Ok(false)))
    }
}
macro_rules! WidgetBaseMethods {
    ($methods:ident) => {
        $methods.add_method("widget", |_, w, ()| Ok(w.as_widget_ptr() as usize));
        $methods.add_meta_method("__call", |_, s, ()| Ok(s.as_widget_ptr() as usize));
    };
}
macro_rules! WidgetExtMethods {
    ($methods:ident) => {
        ParamlessCall!($methods, show, hide, activate, deactivate);
        Getter!($methods, x, y, width, height, label, measure_label);

        // $methods.add_method_mut("set_size", |_, w, (width, height): (i32, i32)| {
        //     Ok(())
        // });
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
        //WidgetGroupMehods!(methods);
    }
}
// MakeFltkWidgetWrapper!(Button, fltk::button::Button);
// impl LuaUserData for Button {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         WidgetBaseMethods!(methods);
//         WidgetExtMethods!(methods);
//     }
// }
// MakeFltkWidgetWrapper!(Frame, fltk::frame::Frame);
// impl LuaUserData for Frame {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         WidgetBaseMethods!(methods);
//         WidgetExtMethods!(methods);
//     }
// }
AddMutMethods!(fltk::frame::Frame,methods=>{
     WidgetBaseMethods!(methods);
     WidgetExtMethods!(methods);
});

// impl LuaWrapper<fltk::group::Flex> {
//     fn size(&mut self, x: i32, y: i32) {
//         WidgetExt::set_size(&mut self.0, x, y);
//     }
// }
// impl LuaWrapper<&mut fltk::group::Flex> {
//     fn size(&mut self, x: i32, y: i32) {
//         WidgetExt::set_size(self.0, x, y);
//     }
// }

trait SetSize {
    fn size(&mut self, x: i32, y: i32);
}
impl<T: WidgetExt> SetSize for LuaWrapper<T> {
    fn size(&mut self, x: i32, y: i32) {
        WidgetExt::set_size(&mut self.0, x, y)
    }
}

AddMethods!(fltk::group::Flex,methods=>{
    WidgetBaseMethods!(methods);
    WidgetExtMethods!(methods);
    WidgetGroupMehods!(methods);
    methods.add_method_mut("set_size",|_,w,(x,y):(i32,i32)|{
        w.size(x,y);
        Ok(())
    });
});

AddMethods!(fltk::group::Pack,methods=>{
    WidgetBaseMethods!(methods);
    WidgetExtMethods!(methods);
    WidgetGroupMehods!(methods);
    methods.add_method_mut("set_width",|_,w,x:i32|{
        w.size(x,w.height());
        Ok(())
    });
    methods.add_method_mut("set_size",|_,w,(x,y):(i32,i32)|{
        w.size(x,y);
        Ok(())
    });
});
AddMethods!(fltk::group::Scroll,methods=>{
    WidgetBaseMethods!(methods);
    WidgetExtMethods!(methods);
    WidgetGroupMehods!(methods);
    methods.add_method_mut("set_width",|_,w,x:i32|{
        w.size(x,w.height());
        Ok(())
    });
    methods.add_method_mut("set_size",|_,w,(x,y):(i32,i32)|{
        w.size(x,y);
        Ok(())
    });
});

//
// MakeFltkWidgetWrapper!(Flex, fltk::group::Flex);
// impl LuaUserData for Flex {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         WidgetBaseMethods!(methods);
//         WidgetExtMethods!(methods);
//         WidgetGroupMehods!(methods);
//         ParamlessCall!(methods, row, recalc, layout, column);
//         Setter!(
//             methods,
//             fixed (usize, i32),
//             set_margin i32,
//             set_pad i32,
//             set_spacing i32,
//             set_margins (i32,i32,i32,i32)
//         );
//     }
// }
// impl Flex {
//     fn fixed(&mut self, args: (usize, i32)) -> () {
//         self.0.fixed(&get_widget_from_ptr(args.0), args.1)
//     }
//     fn set_margins(&mut self, args: (i32, i32, i32, i32)) -> () {
//         self.0.set_margins(args.0, args.1, args.2, args.3)
//     }
//     fn row(&mut self) -> () {
//         self.set_type(fltk::group::FlexType::Row)
//     }
//     fn column(&mut self) -> () {
//         self.set_type(fltk::group::FlexType::Column)
//     }
// }
// macro_rules! exports {
//     ($lua:ident,$($name:literal,$value:expr),*,) => {
//         {
//             let exports = $lua.create_table()?;
//             $(exports.set($name,$lua.create_function(|_,()|Ok($value))?)?;)*
//             Ok(exports)
//         }
//     }
// }
// MakeFltkWidgetWrapper!(Pack, fltk::group::Pack);
// impl LuaUserData for Pack {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         WidgetBaseMethods!(methods);
//         WidgetExtMethods!(methods);
//         WidgetGroupMehods!(methods);
//         Getter!(methods, spacing);
//         Setter!(methods, set_spacing, i32);
//         Setter!(methods, set_type,i32,i => match i {
//             0 => fltk::group::PackType::Vertical,
//             _ => fltk::group::PackType::Horizontal
//         });
//         ParamlessCall!(methods, auto_layout);
//     }
// }
//
// impl DerefMut for LuaWrapper<fltk::window::Window> {
//     fn deref_mut(&mut self) -> &mut Self::Target {
//         &mut self.0
//     }
// }
// impl DerefMut for LuaWrapper<&mut fltk::window::Window> {
//     fn deref_mut(&mut self) -> &mut Self::Target {
//         &mut self.0
//     }
// }
AddMutMethods!(fltk::window::Window,methods=>{
    WidgetBaseMethods!(methods);
    WidgetExtMethods!(methods);
    WidgetGroupMehods!(methods);
});
AddMethods!(fltk::button::Button,methods=>{
    WidgetBaseMethods!(methods);
    WidgetExtMethods!(methods);
    methods.add_method_mut("set_size",|_,w,(x,y):(i32,i32)|{
        w.size(x,y);
        Ok(())
    });
});

// impl LuaUserData for LuaWrapper<fltk::window::Window> {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         {
//             methods.add_method_mut("show", |lua, win, ()| {
//                 win.show();
//                 return Ok(());
//             });
//             WidgetBaseMethods!(methods);
//             WidgetExtMethods!(methods);
//         };
//     }
// }
// impl LuaUserData for LuaWrapper<&fltk::window::Window> {
//     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
//         {
//             methods.add_method_mut("show", |lua, win, ()| {
//                 win.show();
//                 return Ok(());
//             });
//             WidgetBaseMethods!(methods);
//             WidgetExtMethods!(methods);
//         };
//     }
// }

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        App(fltk::app::App::default()),
        "win",
        {
            let mut win = fltk::window::Window::default().with_size(400, 400);
            win.end();
            win.show();
            LuaWrapper(win)
        },
        "button",
        LuaWrapper(fltk::button::Button::default()),
        "flex",
        {
            let mut flex = fltk::group::Flex::default().size_of_parent();
            flex.set_type(fltk::group::FlexType::Row);
            flex.end();
            flex.show();
            LuaWrapper(flex)
        },
        "pack",
        {
            let pack = fltk::group::Pack::default();
            pack.end();
            LuaWrapper(pack)
        },
        "scroll",
        {
            let scroll = fltk::group::Scroll::default();
            scroll.end();
            LuaWrapper(scroll)
        },
        // Button::default(),
        // "frame",
        // Frame::default(),
        // "flex",
        // Flex::default(),
        // "pack",
        // Pack::default(),
    )
}
