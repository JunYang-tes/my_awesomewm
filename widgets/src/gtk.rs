#[allow(unused)]
use crate::gtk_enums::*;
use crate::lua_module::*;
use gtk::{prelude::*, Button, Entry, Window};
use mlua::prelude::*;

use std::ops::{Deref};

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
struct LuaWrapper<T>(T);
impl<T> Deref for LuaWrapper<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
macro_rules! AddMethods {
    ($type:ty, $methods:ident => $block:block) => {
        impl LuaUserData for LuaWrapper<$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
        impl LuaUserData for LuaWrapper<&$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
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
     $item:ident => $exp:block) => {
        MatchLuaUserData!($data,
                          // &$item.0
                          $item => {
                              let $item = &$item.0;
                              $exp;
                          },
                          LuaWrapper<gtk::CheckButton>,
                          LuaWrapper<gtk::Grid>,
                          LuaWrapper<gtk::Box>,
                          LuaWrapper<gtk::ListBox>,
                          LuaWrapper<gtk::ListBoxRow>,
                          LuaWrapper<gtk::Label>,
                          LuaWrapper<gtk::Entry>,
                          LuaWrapper<gtk::Button>,);
        MatchLuaUserData!($data,
                          // $item.0
                          $item => {
                              let $item = $item.0;
                              $exp;
                          },
                          LuaWrapper<&gtk::CheckButton>,
                          LuaWrapper<&gtk::Grid>,
                          LuaWrapper<&gtk::Box>,
                          LuaWrapper<&gtk::ListBox>,
                          LuaWrapper<&gtk::ListBoxRow>,
                          LuaWrapper<&gtk::Label>,
                          LuaWrapper<&gtk::Entry>,
                          LuaWrapper<&gtk::Button>,
                          );

    }
}
macro_rules! GtkOrientableExt {
    ($method:ident) => {
        Getter!($method, orientation i => orientation::to_num(i));
        Setter!($method, set_orientation i32: i => orientation::from_num(i));
    }
}
macro_rules! GtkContainer {
    ($methods:ident) => {
        ParamlessCall!($methods, show_all);
        $methods.add_method_mut("add", |_, container, child: LuaValue| {
            match child {
                LuaValue::UserData(data) => {
                    MatchWidget!(data,item=>{
                        container.add(item);
                        return Ok(())
                    });
                }
                _ => {}
            }
            Ok(())
        });
    };
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
macro_rules! GtkConnect {
    ($methods:ident,$widget:ty,$($name:ident, ($gtk_args:ident,$lua_f:ident) => $block:block,)*)=>{
        $($methods.add_method_mut(stringify!($name),|_,widget,f:LuaValue|{
            match f {
                LuaValue::Function(f) => {
                    let $lua_f = unsafe { std::mem::transmute::<_, mlua::Function<'static>>(f) };
                    widget.$name(move |$gtk_args| {
                        $block;
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

AddMethods!(Window,methods => {
    ParamlessCall!(methods,present,maximize,close);
    GtkContainer!(methods);
});
AddMethods!(gtk::Button,methods =>{
    GtkWidgetExt!(methods);
    Setter!(methods, set_label String: s => s.as_str());
    GtkConnect!(methods,gtk::Button,connect_clicked,(w,f) => {
        let b = LuaWrapper(w);
        f.call::<LuaWrapper<&gtk::Button>,()>(unsafe {
            std::mem::transmute(b)
        })
        .unwrap();

    },);
});
AddMethods!(gtk::Label,methods =>{
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
});
AddMethods!(gtk::Entry,methods =>{
    GtkWidgetExt!(methods);
    Getter!(methods, text str => String::from(str));
    Setter!(methods,set_text String: str=> str.as_str());
});

AddMethods!(gtk::Box,methods=>{
    GtkWidgetExt!(methods);
    GtkContainer!(methods);
    GtkOrientableExt!(methods);
    methods.add_method_mut(
        "pack_start",
        |_, b, (child, expand, fill, padding): (LuaValue, bool, bool, u32)| {
            match child {
                LuaValue::UserData(data) => {
                    MatchWidget!(data,
                    child => {
                        b.pack_start(child,expand,fill,padding);
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
                        b.pack_end(child,expand,fill,padding);
                    });
                }
                _ => {}
            }
            Ok(())
        },
    );
});
AddMethods!(gtk::ListBox,methods=>{
    GtkWidgetExt!(methods);
    GtkContainer!(methods);
});
AddMethods!(gtk::ListBoxRow,methods=>{
    GtkWidgetExt!(methods);
    GtkContainer!(methods);
});
AddMethods!(gtk::Grid,methods=>{
    GtkWidgetExt!(methods);
    GtkContainer!(methods);
    methods.add_method_mut(
        "attach",
        |_, b, (w, left, top, width, height): (LuaValue, i32, i32, i32, i32)| {
            match w {
                LuaValue::UserData(data) => {
                    MatchWidget!(data, item=> {
                        b.attach(item,left,top,width,height);
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
                            b.attach_next_to(item,Some(item2),position_type::from_num(side),width,height);

                        });
                    });
                }
                _ => panic!("Expect widget"),
            }
            Ok(())
        },
    );
});
AddMethods!(gtk::FlowBox,methods=>{
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
                     MatchWidget!(data, item=> {b.insert(item,i)});
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

});
AddMethods!(gtk::CheckButton,methods=>{
  GtkWidgetExt!(methods);
});
AddMethods!(gtk::Stack, methods=>{
  GtkWidgetExt!(methods);
  GtkContainer!(methods);
  methods.add_method_mut(
      "add_titled",
      |_, stack, (child, name, title): (LuaValue, String, String)| {
          match child {
              LuaValue::UserData(data) => {
                  MatchWidget!(data,item => {
                      stack.add_titled(item,name.as_str(),title.as_str());
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
                      stack.add_named(item,name.as_str());
                  });
              }
              _ => panic!("Expect widget"),
          }
          Ok(())
      },
  );
});
AddMethods!(gtk::StackSwitcher,methods=>{

        GtkWidgetExt!(methods);
        methods.add_method_mut("set_stack", |_, switcher, stack: LuaValue| {
            match stack {
                LuaValue::UserData(data) => {
                    let stack = data.borrow::<LuaWrapper<gtk::Stack>>().unwrap();
                    switcher.set_stack(Some(&stack.0));
                }
                _ => panic!("Expect widget"),
            }
            Ok(())
        });
});


pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        App::new(),
        "win",
        LuaWrapper(Window::new(gtk::WindowType::Toplevel)),
        "button",
        LuaWrapper(Button::new()),
        "text_box",
        LuaWrapper(Entry::new()),
        "box",
        LuaWrapper(gtk::Box::new(gtk::Orientation::Horizontal, 0)),
        "label",
        LuaWrapper(gtk::Label::new(None)),
        "list_box",
        LuaWrapper(gtk::ListBox::new()),
        "list_box_row",
        LuaWrapper(gtk::ListBoxRow::new()),
        "flow_box",
        LuaWrapper(gtk::FlowBox::new()),
        "grid",
        LuaWrapper(gtk::Grid::new()),
        "check_button",
        LuaWrapper(gtk::CheckButton::new()),
        "stack",
        LuaWrapper(gtk::Stack::new()),
        "stack_switcher",
        LuaWrapper(gtk::StackSwitcher::new()),
    )
}
