#[allow(unused)]
use crate::gtk_enums::*;
use crate::lua_module::*;
use gtk::{prelude::*, Button, Entry, Window};
use mlua::prelude::*;

use std::ops::Deref;

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
macro_rules! MatchLuaUserData {
    ($data:ident,
     $item: ident => $exp : block,
     $($type:ty),+ $(,)?) => {
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
                          LuaWrapper<gtk::MenuButton>,
                          LuaWrapper<gtk::Image>,
                          LuaWrapper<gtk::ScrolledWindow>,
                          LuaWrapper<gtk::EventBox>,
                          LuaWrapper<gtk::CheckButton>,
                          LuaWrapper<gtk::Grid>,
                          LuaWrapper<gtk::Box>,
                          LuaWrapper<gtk::ListBox>,
                          LuaWrapper<gtk::ListBoxRow>,
                          LuaWrapper<gtk::Label>,
                          LuaWrapper<gtk::Entry>,
                          LuaWrapper<gtk::Button>);
        MatchLuaUserData!($data,
                          // $item.0
                          $item => {
                              let $item = $item.0;
                              $exp;
                          },
                          LuaWrapper<&gtk::MenuButton>,
                          LuaWrapper<&gtk::Image>,
                          LuaWrapper<&gtk::ScrolledWindow>,
                          LuaWrapper<&gtk::EventBox>,
                          LuaWrapper<&gtk::CheckButton>,
                          LuaWrapper<&gtk::Grid>,
                          LuaWrapper<&gtk::Box>,
                          LuaWrapper<&gtk::ListBox>,
                          LuaWrapper<&gtk::ListBoxRow>,
                          LuaWrapper<&gtk::Label>,
                          LuaWrapper<&gtk::Entry>,
                          LuaWrapper<&gtk::Button>
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
        $methods.add_method_mut("remove_all_children",|_,container,()|{
            container.foreach(|w|{
                container.remove(w);
            });
            Ok(())
        });
    };
}
macro_rules! GtkCast {
    ($widget:ident,
      $sub:ident => $todo:block,
      $($widget_type:ty,)+ $(,)? ) => {
        $(if $widget.is::<$widget_type>(){
            let $sub:LuaWrapper<&'static $widget_type> = LuaWrapper(unsafe {
                std::mem::transmute($widget.downcast_ref::<$widget_type>().unwrap())
            });
            $todo
        })*

    }
}
macro_rules! GtkWidgetExt {
    ($method:ident) => {
        ParamlessCall!($method, show,grab_focus);
        Getter!($method, width_request, height_request,
                get_visible,
                margin);
        Getter!($method,
                halign i => align::to_num(i),
                valign i => align::to_num(i),
                style_context ctx=>LuaWrapper(ctx));
        Setter!($method,
                set_expand bool,
                set_hexpand bool,
                set_vexpand bool,
                set_visible bool,
                set_has_default bool,
                set_has_focus bool,
                set_height_request i32,
                set_width_request i32,
                set_is_focus bool,
                set_margin i32);
        Setter!($method,
                set_halign i32:i=>align::from_num(i),
                set_valign i32:i=>align::from_num(i)
                );

        $method.add_method("set_size_request",|_,w,i:(i32,i32)|{
            w.set_size_request(i.0,i.1);
            Ok(())
        });
        // Setter!($mathod,
        //     set_halign i32: i => align::from_num(i),
        //     set_valign i32: i => align::from_num(i),
        // );
    };
    ($widget:ty,$methods:ident) => {
        GtkWidgetExt!($methods);
        GtkConnect!($methods,$widget,
                    connect_map,
                    connect_unmap,
                    connect_show,
                    connect_app_paintable_notify,
                    connect_can_focus_notify,
                    connect_can_default_notify,
                    connect_composite_child_notify,
                    connect_events_notify,
                    connect_expand_notify,
                    connect_style_updated,
                    connect_focus_on_click_notify,
                    connect_halign_notify,
                    connect_valign_notify,
                    connect_has_default_notify,
                    connect_has_focus_notify,
                    connect_unrealize,
                    connect_realize,
                    connect_grab_focus,
                    connect_has_tooltip_notify,
                    connect_height_request_notify,
                    connect_hexpand_notify,
                    connect_hexpand_set_notify,
                    connect_is_focus_notify,
                    connect_margin_notify,
                    connect_margin_bottom_notify,
                    connect_margin_top_notify,
                    connect_margin_start_notify,
                    connect_margin_end_notify,
                    connect_name_notify,
                    connect_no_show_all_notify,
                    connect_opacity_notify,
                    connect_parent_notify,
                    connect_receives_default_notify,
                    connect_scale_factor_notify,
                    connect_sensitive_notify,
                    connect_tooltip_markup_notify,
                    connect_tooltip_text_notify,
                    connect_vexpand_notify,
                    connect_vexpand_set_notify,
                    connect_visible_notify,
                    connect_width_request_notify,
                    connect_window_notify,
                    connect_hide);
        GtkConnectPropgatableEvent!($methods,$widget,
                    connect_delete_event gtk::gdk::Event,
                    connect_focus_in_event gtk::gdk::EventFocus,
                    connect_focus_out_event gtk::gdk::EventFocus,
                    connect_key_press_event gtk::gdk::EventKey,
                    connect_key_release_event gtk::gdk::EventKey,
                    connect_button_release_event gtk::gdk::EventButton,
                    connect_button_press_event gtk::gdk::EventButton);
        GtkConnect!($methods,$widget,
                    connect_size_allocate &gtk::Rectangle);
        GtkConnect!($methods,$widget,
                    connect_parent_set:((w,p),f)=>{
                        if let Some(p) = p {
                            GtkCast!(p,
                                     p=>{
                                        let w = LuaWrapper(w);
                                        f.call::<(LuaWrapper<&'static $widget>,_),()>(unsafe {
                                            (std::mem::transmute(w),p)
                                        }).unwrap();
                                     },gtk::Box,gtk::FlowBox,gtk::Window,gtk::ListBox,gtk::ScrolledWindow,
                                     );
                        } else {
                                f.call::<LuaWrapper<&$widget>,()>(unsafe {
                                    std::mem::transmute(w)
                                }).unwrap();

                        }
                    });
    };
}
macro_rules! GtkConnect {
    ($methods:ident,$widget:ty,$($name:ident: (($($gtk_args:ident),+ $(,)?),$lua_f:ident) => $block:block),+ $(,)? )=>{
        $($methods.add_method_mut(stringify!($name),|_,widget,f:LuaValue|{
            match f {
                LuaValue::Function(f) => {
                    let $lua_f = unsafe { std::mem::transmute::<_, mlua::Function<'static>>(f) };
                    widget.$name(move |$($gtk_args,)*|  {
                        $block;
                    });
                },
                _ => {
                    panic!("Expect a function")
                }
            }
            Ok(())
        });)*
    };
    ($methods:ident,$widget:ty,$($name:ident),+ $(,)?)=>{
        $(GtkConnect!($methods,$widget,$name:((w),f)=>{
            let b = LuaWrapper(w);
            let r = f.call::<LuaWrapper<&$widget>,()>(unsafe {
                std::mem::transmute(b)
            });
            if r.is_err() {
                eprintln!("Event callback err: {:?}",r);
            }
        });)*
    };
    ($methods:ident,$widget:ty,$($name:ident $event:ty),+ $(,)?)=>{
        $(GtkConnect!($methods,$widget,$name:((w,e),f)=>{
            let b = LuaWrapper(w);
            let r = f.call::<(LuaWrapper<&$widget>,LuaWrapper<$event>),()>(unsafe {
                (std::mem::transmute(b),std::mem::transmute(e))
            });
            if r.is_err() {
                eprintln!("Event callback err: {:?}",r);
            }
        });)*
    };
}
macro_rules! GtkConnectPropgatableEvent {
    ($methods:ident,$widget:ty,$($name:ident $event:ty),+ $(,)?)=>{
        $(GtkConnect!($methods,$widget,$name:((w,e),f)=>{
            let w = LuaWrapper(w);
            let stop = f.call::<(LuaWrapper<&$widget>,LuaWrapper<&$event>),bool>(unsafe {
                (std::mem::transmute(w),std::mem::transmute(LuaWrapper(e)))
            });
            if stop.is_err() {
                eprintln!("Event callback err: {:?}",stop);
            }
            let stop = stop.unwrap_or(false);
            if stop {
                return glib::Propagation::Stop
            } else {
                return glib::Propagation::Proceed
            }
        });)*
    }
}
macro_rules! GtkButtonExt {
    ($widget:ty,$methods:ident)=>{
        Getter!($methods,clicked);
        Setter!($methods, set_label String: s => s.as_str());
        GtkConnect!($methods,$widget,connect_clicked);
    }
}
macro_rules! GtkToggleButtonExt {
    ($widget:ty,$methods:ident)=>{
        Getter!($methods,is_active);
        Setter!($methods, set_active bool);
        GtkConnect!($methods,$widget,connect_toggled);
    }
}

AddMethods!(Window,methods => {
    ParamlessCall!(methods,present,maximize,close);
    GtkWidgetExt!(Window,methods);
    GtkContainer!(methods);
    Setter!(methods,set_role String:i=>i.as_str());
    Setter!(methods,set_skip_taskbar_hint bool,
                    set_decorated bool,
                    set_skip_pager_hint bool);
    Setter!(methods,set_type_hint i32: i => window_type_hint::from_num(i));
    methods.add_method("set_pos",|_,w,i:(i32,i32)|{
        w.move_(i.0,i.1);
        Ok(())
    });
    methods.add_method("set_default_size",|_,w,i:(i32,i32)|{
        w.set_default_size(i.0,i.1);
        Ok(())
    });
});
AddMethods!(gtk::ScrolledWindow,methods => {
    GtkWidgetExt!(gtk::ScrolledWindow,methods);
    GtkContainer!(methods);
});
AddMethods!(gtk::Button,methods =>{
    GtkWidgetExt!(gtk::Button,methods);
    GtkConnect!(methods,gtk::Button,connect_clicked);
    GtkButtonExt!(gtk::Button,methods);
});
AddMethods!(gtk::Label,methods =>{
    GtkWidgetExt!(gtk::Label,methods);
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
            set_label Option<String>: i=> i.unwrap_or(String::from("")).as_str(),
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
    GtkWidgetExt!(gtk::Entry, methods);
    Getter!(methods, text str => String::from(str));
    Setter!(methods,set_text String: str=> str.as_str());
});

AddMethods!(gtk::Box,methods=>{
    GtkWidgetExt!(gtk::Box,methods);
    GtkContainer!(methods);
    GtkOrientableExt!(methods);
    Getter!(methods, is_homogeneous);
    Setter!(methods, set_homogeneous bool,
            set_spacing i32);

    methods.add_method("set_child_packing",|_,b,(child, expand, fill, padding,pack_type):
                       (LuaValue, bool, bool, u32,u32)|{
            match child {
                LuaValue::UserData(data) => {
                    MatchWidget!(data,
                    child => {
                        b.set_child_packing(child,expand,fill,padding,
                                            if pack_type == 0 { gtk::PackType::Start}
                                            else { gtk::PackType::End} );
                    });
                }
                _ => {}
            }
        Ok(())
    });
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
    GtkWidgetExt!(gtk::ListBox,methods);
    GtkContainer!(methods);
    Call!(methods,
          row_at_index,
          idx:i32 => idx,
          row => Ok(LuaWrapper(row.unwrap()))
          );
    methods.add_method("select_row",|_,list,row:LuaValue|{
          match row {
              LuaValue::UserData(data)=>{
                  if data.is::<LuaWrapper<gtk::ListBoxRow>>() {
                      let row = data.borrow::<LuaWrapper<gtk::ListBoxRow>>().unwrap();
                      list.select_row(Some(&row.0))
                  } else {
                      let row = data.borrow::<LuaWrapper<&gtk::ListBoxRow>>().unwrap();
                      list.select_row(Some(row.0))
                  }

              },
              _ => {panic!("expect list row")}

          }
        Ok(())
    })
});
AddMethods!(gtk::ListBoxRow,methods=>{
    GtkWidgetExt!(gtk::ListBoxRow,methods);
    GtkContainer!(methods);
});
AddMethods!(gtk::Grid,methods=>{
    GtkWidgetExt!(gtk::Grid,methods);
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
         GtkWidgetExt!(gtk::FlowBox,methods);
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
  GtkWidgetExt!(gtk::CheckButton,methods);
  GtkButtonExt!(gtk::CheckButton,methods);
  GtkToggleButtonExt!(gtk::CheckButton,methods);
});
AddMethods!(gtk::Stack, methods=>{
  GtkWidgetExt!(gtk::Stack,methods);
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
        GtkWidgetExt!(gtk::StackSwitcher,methods);
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
AddMethods!(gtk::EventBox,methods => {
    GtkWidgetExt!(gtk::EventBox,methods);
    GtkContainer!(methods);
});
AddMethods!(gtk::Image,methods => {
    GtkWidgetExt!(gtk::Image,methods);
    Getter!(methods, pixel_size);
    Setter!(methods, set_pixel_size i32);
    methods.add_method("set_from_file",|_,w,file:String|{
        w.0.set_from_file(Some(file));
        Ok(())
    });
    methods.add_method("set_icon_name",|_,w,name:String|{
        w.0.set_from_icon_name(Some(name.as_str()),gtk::IconSize::Button);
      Ok(())
    });
    methods.add_method("set_size",|_,img,(w,h):(i32,i32)|{
        if let Some(surface) = img.surface() {
            let (ow,oh) = crate::cairo_utils::get_surface_size(&surface);
            if let Some(pixbuf) = gtk::gdk::pixbuf_get_from_surface(&surface,0,0,ow,oh) {
                let pixbuf = pixbuf.scale_simple(w,h,gtk::gdk::gdk_pixbuf::InterpType::Nearest).unwrap_or(pixbuf);
                img.set_from_pixbuf(Some(&pixbuf));
            }
        }
        Ok(())
    });
    methods.add_method("set_image",|_,w,img:LuaValue| {
        match img {
            LuaValue::UserData(data)=>{
                if let Ok(surface) = data.borrow::<LuaWrapper<&cairo::ImageSurface>>() {
                    w.set_from_surface(Some(surface.0));
                } else if let Ok(surface) = data.borrow::<LuaWrapper<cairo::ImageSurface>>() {
                    w.set_from_surface(Some(&surface.0))
                } else {
                    panic!("Unsupported")
                }
                Ok(())
            },
            _ => {
                panic!("expect img")
            }
        }
    });
});
AddMethods!(gtk::MenuButton,methods => {
    GtkWidgetExt!(gtk::MenuButton,methods);
});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports: LuaResult<LuaTable> = exports!(
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
        "event_box",
        LuaWrapper(gtk::EventBox::new()),
        "css_provider",
        LuaWrapper(gtk::CssProvider::new()),
        "scrolled_win",
        LuaWrapper(gtk::ScrolledWindow::default()),
        "image",
        LuaWrapper(gtk::Image::default()),
        "menu_button",
        LuaWrapper(gtk::MenuButton::default()),
    );
    let exports = exports.unwrap();
    exports.set("STYLE_PROVIDER_PRIORITY_USER", 800)?;
    exports.set("StyleContext", crate::gtk_style::style_context(lua)?)?;

    Ok(exports)
}
