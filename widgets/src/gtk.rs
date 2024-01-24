use crate::gtk_enums::*;
use crate::lua_module::*;
use gtk::{prelude::*, Button, Entry, Window};
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
     $item: ident => $exp :block) => {MatchLuaUserData!($data, $item => $exp,
                                                        Btn,Textbox,Box,Label,ListBox,);}
}
macro_rules! GtkContainer {
    ($methods:ident) => {
        ParamlessCall!($methods,show_all);
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
LuaUserDataWrapper!(Label, gtk::Label);
impl LuaUserData for Label {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        use pango::EllipsizeMode;
        Getter!(methods, angle, cursor_position, selection_bound, wraps);
        Getter!(methods,
        wrap_mode i => wrap_mode::to_num(i),
        line_wrap_mode i => wrap_mode::to_num(i),
        ellipsize i=> match i {
            EllipsizeMode::None => 0,
            EllipsizeMode::Start => 1,
            EllipsizeMode::Middle => 2,
            EllipsizeMode::End => 3,
            EllipsizeMode::__Unknown(i)=>i,
            _ => -1
        },
        justify i => justification::to_num(i)
        );
        Setter!(methods,
                set_use_markup bool,
                set_use_underline bool,
                set_width_chars i32,
                set_max_width_chars i32,
                set_xalign f32,
                set_selectable bool,
                set_single_line_mode bool,
                set_line_wrap bool,
                set_yalign f32,
                set_lines i32,
                set_wrap bool);
        Setter!(methods,
                set_label String: i=>i.as_str(),
                set_text String: i=>i.as_str(),
                set_text_with_mnemonic String: i=>i.as_str(),
                set_markup String: i=>i.as_str(),
                set_pattern String: i=>i.as_str(),
                set_markup_with_mnemonic String: i=>i.as_str(),
                set_wrap_mode i32: i => wrap_mode::from_num(i),
                set_line_wrap_mode i32: i => wrap_mode::from_num(i),
                set_ellipsize i32: i=> match i {
                    0 => EllipsizeMode::None,
                    1 => EllipsizeMode::Start,
                    2 => EllipsizeMode::Middle,
                    3 => EllipsizeMode::End,
                    i => EllipsizeMode::__Unknown(i)
                },
                set_justify i32: i => justification::from_num(i)
        );
    }
}

LuaUserDataWrapper!(ListBox, gtk::ListBox);
impl LuaUserData for ListBox {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        GtkContainer!(methods);
    }
}
LuaUserDataWrapper!(ListBoxRow, gtk::ListBoxRow);
impl LuaUserData for ListBoxRow {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        GtkContainer!(methods);
    }
}
LuaUserDataWrapper!(FlowBox, gtk::FlowBox);
impl LuaUserData for FlowBox {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        GtkContainer!(methods);
        ParamlessCall!(methods,
                       invalidate_filter,
                       unselect_all,
                       invalidate_sort,
                       select_all);
        Getter!(
            methods,
            activates_on_single_click,
            column_spacing,
            is_homogeneous,
            max_children_per_line,
            min_children_per_line,
            row_spacing
        );
        Getter!(methods,
                selection_mode i => selection_mode::to_num(i));
        methods.add_method_mut("insert", |_, b, (w, i): (LuaValue, i32)| {
            match w {
                LuaValue::UserData(data) => {
                    MatchWidget!(data, item=> {b.insert(&item.0,i)});
                }
                _ => panic!("Expect widget"),
            }
            Ok(())
        });
        Setter!(methods,
                set_column_spacing u32,
                set_homogeneous bool,
                set_max_children_per_line u32,
                set_min_children_per_line u32,
                set_row_spacing u32,
                set_activate_on_single_click bool);
        Setter!(methods,
                set_selection_mode i32: i => selection_mode::from_num(i));
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
        "text_box",
        Textbox(Entry::new()),
        "box",
        Box(gtk::Box::new(gtk::Orientation::Horizontal, 0)),
        "label",
        Label(gtk::Label::new(None)),
        "list_box",
        ListBox(gtk::ListBox::new()),
        "list_box_row",
        ListBoxRow(gtk::ListBoxRow::new()),
        "flow_box",
        FlowBox(gtk::FlowBox::new()),
    )
}
