#[allow(unused)]
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
macro_rules! GtkOrientableExt {
    ($method:ident) => {
        Getter!($method, orientation i => orientation::to_num(i));
        Setter!($method, set_orientation i32: i => orientation::from_num(i));
    }
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
     $item: ident => $exp :block) => {
        MatchLuaUserData!($data,
                          $item => $exp,
                          Btn,Textbox,Box,Label,ListBox,ListBoxRow,
                          FlowBox,Grid,Stack,StackSwitcher,);}
}
macro_rules! GtkContainer {
    ($methods:ident) => {
        ParamlessCall!($methods,show_all);
        $methods.add_method_mut("add", |_, container, child: LuaValue| {
            match child {
                LuaValue::UserData(data) => {
                    MatchWidget!(data, item => {
                        container.add(item.to_ref());
                        return Ok(())
                    });
                }
                _ => {}
            }
            Ok(())
        })
    };
}
macro_rules! GtkConnect {
    ($methods:ident,$widget:ident,$($name:ident,)*)=>{
        $($methods.add_method_mut(stringify!($name),|_,widget,f:LuaValue|{
            match f {
                LuaValue::Function(f) => {
                    let f = unsafe { std::mem::transmute::<_, mlua::Function<'static>>(f) };
                    widget.connect_clicked(move |w| {
                        let b = $widget::new_with_ref(w);
                        f.call::<$widget, ()>(unsafe { std::mem::transmute::<_, $widget<'static>>(b) })
                             .unwrap();
                    });
                },
                _ => {
                    panic!("Expect a function")
                }
            }

            Ok(())
        }))*;
    }
}

LuaUserDataWrapper!(Win, Window);
impl LuaUserData for Win {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkContainer!(methods);
        Getter!(methods,);
        ParamlessCall!(methods, present, maximize, close);
    }
}

LuaUserDataWrapper!(Btn, BtnEnum, Button);
impl<'a> LuaUserData for Btn<'a> {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        Basic!(methods);
        GtkWidgetExt!(methods);
        Setter!(methods, set_label String: s => s.as_str());
        GtkConnect!(methods, Btn, connect_clicked,);
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
        GtkOrientableExt!(methods);
        methods.add_method_mut(
            "pack_start",
            |_, b, (child, expand, fill, padding): (LuaValue, bool, bool, u32)| {
                match child {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data,
                        child => {
                            b.pack_start(child.to_ref(),expand,fill,padding);
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
                            b.pack_end(child.to_ref(),expand,fill,padding);
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
        ParamlessCall!(
            methods,
            invalidate_filter,
            unselect_all,
            invalidate_sort,
            select_all
        );
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
                    MatchWidget!(data, item=> {b.insert(item.to_ref(),i)});
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
LuaUserDataWrapper!(Grid, gtk::Grid);
impl LuaUserData for Grid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        GtkContainer!(methods);
        methods.add_method_mut(
            "attach",
            |_, b, (w, left, top, width, height): (LuaValue, i32, i32, i32, i32)| {
                match w {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data, item=> {
                            b.attach(item.to_ref(),left,top,width,height);
                        });
                    }
                    _ => panic!("Expect widget"),
                }
                Ok(())
            },
        );
        methods.add_method_mut(
            "attach_next_to",
            |_, b, (w1, w2, side, width, height): (LuaValue, LuaValue, i32, i32, i32)| {
                match (w1, w2) {
                    (LuaValue::UserData(data), LuaValue::UserData(data2)) => {
                        MatchWidget!(data, item=> {
                            MatchWidget!(data2, item2 => {
                                b.attach_next_to(item.to_ref(),Some(item2.to_ref()),position_type::from_num(side),width,height);

                            });
                        });
                    }
                    _ => panic!("Expect widget"),
                }
                Ok(())
            },
        );
    }
}
LuaUserDataWrapper!(CheckButton, gtk::CheckButton);
impl LuaUserData for CheckButton {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
    }
}
LuaUserDataWrapper!(Stack, gtk::Stack);
impl LuaUserData for Stack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        GtkContainer!(methods);
        methods.add_method_mut(
            "add_titled",
            |_, stack, (child, name, title): (LuaValue, String, String)| {
                match child {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data,item => {
                            stack.add_titled(item.to_ref(),name.as_str(),title.as_str());
                        });
                    }
                    _ => panic!("Expect widget"),
                }
                Ok(())
            },
        );
        methods.add_method_mut(
            "add_named",
            |_, stack, (child, name): (LuaValue, String)| {
                match child {
                    LuaValue::UserData(data) => {
                        MatchWidget!(data,item => {
                            stack.add_named(item.to_ref(),name.as_str());
                        });
                    }
                    _ => panic!("Expect widget"),
                }
                Ok(())
            },
        );
    }
}
LuaUserDataWrapper!(StackSwitcher, gtk::StackSwitcher);
impl LuaUserData for StackSwitcher {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        GtkWidgetExt!(methods);
        methods.add_method_mut("set_stack", |_, switcher, stack: LuaValue| {
            match stack {
                LuaValue::UserData(data) => {
                    let stack = data.borrow::<Stack>().unwrap();
                    switcher.set_stack(Some(&stack.0));
                }
                _ => panic!("Expect widget"),
            }
            Ok(())
        });
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
        Btn::new(Button::new()),
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
        "grid",
        Grid(gtk::Grid::new()),
        "check_button",
        CheckButton(gtk::CheckButton::new()),
        "stack",
        Stack(gtk::Stack::new()),
        "stack_switcher",
        StackSwitcher(gtk::StackSwitcher::new()),
    )
}
