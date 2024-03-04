use std::ops::Deref;

use crate::gtk4_enums::*;
use crate::lua_module::*;
use gtk4::prelude::*;
use mlua::prelude::*;

struct App {
    ctx: gtk4::glib::MainContext,
}
impl App {
    fn new() -> App {
        gtk4::init().unwrap();
        App {
            ctx: gtk4::glib::MainContext::default(),
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

macro_rules! GtkOrientableExt {
    ($method:ident) => {
        Getter!($method, orientation i => orientation::to_num(i));
        Setter!($method, set_orientation i:i32 => orientation::from_num(i));
    }
}
macro_rules! GtkWidgetExt {
    ($widget:ty,$methods:ident) => {
        ParamlessCall!($methods,grab_focus);
        Setter!($methods,
                set_visible bool,
                set_hexpand bool,
                set_vexpand bool,
                set_can_focus bool,
                set_can_target bool
                );
        Getter!($methods,
                css_classes classes=>classes
                                         .iter()
                                         .map(|s|String::from(s.as_str()))
                                         .collect::<Vec<_>>());
        MethodWidthLuaCallbackTransmuteStatic!(
            $methods,
            connect_map (lua,w,f)=>{
                let widget = w.downgrade();
                w.connect_map(move |_|{
                    if let Some(w) = widget.upgrade() {
                        if let Err(err) = f.call::<_,()>(LuaWrapper(w)) {
                            eprintln!("Lua callback error: {:?}",err);
                        }
                    }
                });
                Ok(())
            }
            connect_clicked (lua,w,f)=>{
                let controller = gtk4::GestureClick::new();
                let widget = w.downgrade();
                controller.connect_released(move |_controler,press_count,x,y|{
                    if let Some(w) = widget.upgrade() {
                        f.call::<_,()>((LuaWrapper(w),press_count,x,y)).unwrap();
                    }
                });
                let weak_controller = controller.downgrade();
                let widget = w.downgrade();
                w.add_controller(controller);
                Ok(lua.create_function(move |_,()|{
                    if let (Some(controller),Some(widget)) = (weak_controller.upgrade(),widget.upgrade()) {
                        widget.remove_controller(&controller);
                    }
                    Ok(())
                }).unwrap())
            }
            );
        $methods.add_method("connect_key_press_event",|lua,w,f:LuaValue|{
            match f {
                LuaValue::Function(f)=>{
                    println!("connect_key_press_event");
                    let g = unsafe {std::mem::transmute::<_,mlua::Function<'static>>(f)};
                    let lua = unsafe {std::mem::transmute::<_,&'static Lua>(lua)};
                    let key_event = gtk4::EventControllerKey::new();
                    let widget = w.downgrade();
                    key_event.connect_im_update(|w|{
                        println!("im update {:?}",w);
                    });
                    key_event.connect_key_pressed(move |_key_event,key,code,modifier|{
                        println!("pressed");
                        if let Some(w) = widget.upgrade() {
                            let mask_bits = modifier.bits();
                            let modifier = Table!(lua,
                                                  alt=>mask_bits & 8 == 8,
                                                  meta=> mask_bits &268435456 == 268435456,
                                                  hyper => mask_bits & 134217728 == 134217728,
                                                  ctrl=>mask_bits & 4 == 4,);
                            let stop_propagation = g.call::<(_,u32,_),bool>((LuaWrapper(w),code,modifier)).unwrap_or(false);
                            if stop_propagation {
                                gtk4::glib::Propagation::Stop
                            } else {
                                gtk4::glib::Propagation::Proceed
                            }
                        } else {
                            gtk4::glib::Propagation::Proceed
                        }
                    });
                    w.add_controller(key_event);
                },
                _ => {
                    panic!("Expect callback function")
                }
            }
            Ok(())
        });
        ReturnlessCall!($methods,
                        add_css_class cls:String=>cls.as_str(),
                        remove_css_class cls:String=>cls.as_str()
                        );
    }
}
macro_rules! MatchWidget {
    ($data:ident,
     $item:ident => $exp:block) => {
        MatchLuaUserData!($data,$item => {let $item = &$item.0;$exp},
                          LuaWrapper<gtk4::Button>,
                          LuaWrapper<gtk4::Label>,
                          LuaWrapper<gtk4::Entry>,
                          LuaWrapper<gtk4::ListBox>,
                          LuaWrapper<gtk4::ListBoxRow>,
                          LuaWrapper<gtk4::ScrolledWindow>,
                          LuaWrapper<gtk4::Picture>,
                          LuaWrapper<gtk4::Box>
                          );
        MatchLuaUserData!($data,$item => {let $item = $item.0;$exp},
                          LuaWrapper<&gtk4::Button>,
                          LuaWrapper<&gtk4::Label>,
                          LuaWrapper<&gtk4::Entry>,
                          LuaWrapper<&gtk4::ListBox>,
                          LuaWrapper<&gtk4::ListBoxRow>,
                          LuaWrapper<&gtk4::ScrolledWindow>,
                          LuaWrapper<&gtk4::Picture>,
                          LuaWrapper<&gtk4::Box>
                          );
    }
}
macro_rules! MethodWidthLuaUserData {
    ($methods:ident,$($name:ident $item:ident,$user_data:ident=>$block:block)*)=>{
        $($methods.add_method(stringify!($name),|_lua,$item,val:LuaValue|{
            match val {
                LuaValue::UserData($user_data)=>{
                    $block
                },
                _ => {
                    panic!("Expect LuaValue::UserData")
                }
            }
        });)*
    }
}
macro_rules! MethodWidthLuaCallback {
    ($methods:ident,$($name:ident ($lua:ident,$item:ident,$user_data:ident)=>$block:block)*)=>{
        $($methods.add_method(stringify!($name),|$lua,$item,val:LuaValue|{
            match val {
                LuaValue::Function($user_data)=>{
                    $block
                },
                _ => {
                    panic!("Expect LuaValue::Function")
                }
            }
        });)*
    }
}
macro_rules! MethodWidthLuaCallbackTransmuteStatic {
    ($methods:ident,$($name:ident ($lua:ident,$item:ident,$lua_fn:ident)=>$block:block)*)=>{
        MethodWidthLuaCallback!($methods, $($name (lua,item,lua_fn)=>{
            let $lua_fn = unsafe {std::mem::transmute::<_,mlua::Function<'static>>(lua_fn)};
            let $lua = unsafe {std::mem::transmute::<_,&'static Lua>(lua)};
            let $item = item;
            $block
        })*);
    }
}
AddMethods!(gtk4::glib::signal::SignalHandlerId,methods=>{});
AddMethods!(gtk4::Window,methods => {
    ParamlessCall!(methods,present,close);
    GtkWidgetExt!(gtk::Window,methods);
    Setter!(methods, set_hide_on_close bool);
    MethodWidthLuaCallbackTransmuteStatic!(
        methods,
        connect_close_request (lua,win,f)=>{
            let win_ref = win.downgrade();
            win.connect_close_request(move |_| {
                if let Some(win) = win_ref.upgrade() {
                    let stop_propagation = f.call::<_,bool>(LuaWrapper(win));
                    if let Ok(stop_propagation) = stop_propagation {
                        if stop_propagation {
                            gtk4::glib::Propagation::Stop
                        } else {
                            gtk4::glib::Propagation::Proceed
                        }
                    } else {
                        eprintln!("Lua callback error: {:?}",stop_propagation);
                        gtk4::glib::Propagation::Proceed
                    }
                } else {
                    gtk4::glib::Propagation::Proceed
                }
            });
            Ok(())
        }
        );
    methods.add_method("set_skip_taskbar_hint",|_,w,b:bool|{
        if let Some(surface)=w.surface() {
            let display = surface.display();
            let backend = display.backend();
            if backend.is_x11() {
                let x11_surface = unsafe {
                    surface.unsafe_cast::<gdk4_x11::X11Surface>()
                };
                x11_surface.set_skip_taskbar_hint(b);
            }
        }
        Ok(())
    });
    methods.add_method("set_role",|_,w,role:String|{
        if let Some(surface)=w.surface() {
            let display = surface.display();
            let backend = display.backend();
            if backend.is_x11() {
                let x11_surface = unsafe {
                    surface.unsafe_cast::<gdk4_x11::X11Surface>()
                };
                x11_surface.set_utf8_property("WM_WINDOW_ROLE",Some(role.as_str()));
            }
        }
        Ok(())
    });
    methods.add_method("set_child",|_,w,child:LuaValue|{
        match child {
            LuaValue::UserData(d)=>{
                MatchWidget!(d,item=>{
                    w.set_child(Some(item));
                });
            },
            _ => {}
        }
        Ok(())
    });
});
AddMethods!(gtk4::ScrolledWindow,methods=>{
    GtkWidgetExt!(gtk::Window,methods);
    methods.add_method("set_child",|_,w,child:LuaValue|{
        match child {
            LuaValue::UserData(d)=>{
                MatchWidget!(d,item=>{
                    w.set_child(Some(item));
                });
            },
            _ => {}
        }
        Ok(())
    });
});
AddMethods!(gtk4::Box,methods => {
    GtkWidgetExt!(gtk4::Box,methods);
    Setter!(methods, set_spacing i32,
                     set_homogeneous bool);
    GtkOrientableExt!(methods);
    methods.add_method_mut("remove_all_children",|_,b,()|{
        while let Some(child) = b.first_child() {
            b.remove(&child);
        }
        Ok(())
    });
    MethodWidthLuaUserData!(methods,
        append box_,child=>{
            MatchWidget!(child,child=>{
                box_.append(child);
            });
            Ok(())}
        prepend box_,child => {
            MatchWidget!(child,child=>{
                box_.prepend(child);
            });
            Ok(())
        }
        remove box_,child => {
            MatchWidget!(child,child=>{
                box_.remove(child);
            });
            Ok(())
        }
    );
});
AddMethods!(gtk4::Button,methods => {
    use gtk4::prelude::ButtonExt;
    GtkWidgetExt!(gtk4::Box,methods);
    Setter!(methods,
            set_can_shrink bool);
    Setter!(methods,set_label i:String => i.as_str());
    MethodWidthLuaCallbackTransmuteStatic!(
        methods,
        connect_clicked (lua,btn,f)=>{
            let mut signal =Some( btn.connect_clicked(move |_|{
                f.call::<(),()>(()).unwrap();
            }));
            let b =btn.downgrade();
            Ok(lua.create_function_mut(move |_,()|{
                let btn = b.upgrade();
                if let Some(signal) = signal.take() {
                    if let Some(btn) = btn {
                        btn.disconnect(signal)
                    }
                }
                Ok(())
            }).unwrap())
        }
    );
});
AddMethods!(gtk4::Entry,methods => {
    GtkWidgetExt!(gtk4::Entry,methods);
    Getter!(methods, text str => String::from(str));
    Setter!(methods,set_text str:String=> str.as_str());
    MethodWidthLuaCallbackTransmuteStatic!(
        methods,
        connect_activate (lua,entry,f) => {
            let entry_ref = entry.downgrade();
            entry.connect_activate(move |_|{
                if let Some(entry) = entry_ref.upgrade() {
                    if let Err(err) = f.call::<_,()>(LuaWrapper(entry)) {
                        eprintln!("Lua callback error: {:?}",err);
                    }
                }
            });
            Ok(())
        }
        connect_text_notify (lua,entry,f)=>{
            entry.connect_text_notify(move |entry|{
                f.call::<_,()>(String::from(entry.text().as_str())).unwrap();
            });
            Ok(())
        });
});
AddMethods!(gtk4::Label,methods=>{
    GtkWidgetExt!(gtk4::Label,methods);
    Setter!(methods,
            set_xalign f32,
            set_wrap bool);
    Setter!(methods,
            set_label i:String => i.as_str(),
            set_text i:String => i.as_str(),
            set_markup i:String => i.as_str()
            );
});
AddMethods!(gtk4::ListBoxRow,methods=>{
    GtkWidgetExt!(gtk4::ListBox,methods);
    methods.add_method("set_child",|_,w,child:LuaValue|{
        match child {
            LuaValue::UserData(d)=>{
                MatchWidget!(d,item=>{
                    w.set_child(Some(item));
                });
            },
            _ => {}
        }
        Ok(())
    });
});
AddMethods!(gtk4::ListBox,methods=>{
    GtkWidgetExt!(gtk4::ListBox,methods);
    methods.add_method("remove_all_children",|_,list,()|{
        list.remove_all();
        Ok(())
    });
    Call!(methods,
          row_at_index,
          idx:i32 => idx,
          row => Ok(LuaWrapper(row.unwrap()))
          );
    methods.add_method("select_row",|_,list,row:LuaValue|{
        match row {
            LuaValue::UserData(d)=>{
                if d.is::<LuaWrapper<gtk4::ListBoxRow>>() {
                    let row = d.borrow::<LuaWrapper<gtk4::ListBoxRow>>().unwrap();
                    list.select_row(Some(&row.0));
                } else if d.is::<LuaWrapper<&gtk4::ListBoxRow>>() {
                    let row = d.borrow::<LuaWrapper<&gtk4::ListBoxRow>>().unwrap();
                    list.select_row(Some(row.0));
                }
            },
            _ => {
                panic!("Expect list row");
            }
        }
        Ok(())
    });
    // Call!(methods,
    //       select_row,
    //       input:LuaValue => match input {
    //           LuaValue::UserData(d)=>{
    //               let r = d.borrow::<LuaWrapper<gtk4::ListBoxRow>>().unwrap();
    //               Some(&r.0)
    //           },
    //           _ => {
    //               panic!("Expect list row")
    //           }
    //       },
    //       ret=>Ok(())
    //       );
    MethodWidthLuaUserData!(methods,
        append box_,child=>{
            MatchWidget!(child,child=>{
                box_.append(child);
            });
            Ok(())});
});
AddMethods!(gtk4::Picture,methods => {
    GtkWidgetExt!(gtk4::Picture,methods);
    Setter!(methods,
            set_can_shrink bool
            );
    Setter!(methods,
            set_content_fit i:u32 => fit::from_num(i),
            set_filename str:String=>Some(str));
    methods.add_method("set_cairo_img_surface",|_,pic,img:LuaValue|{
        match img {
            LuaValue::UserData(data)=>{
                if data.is::<LuaWrapper<cairo::ImageSurface>>() {
                    let mut surface = data.take::<LuaWrapper<cairo::ImageSurface>>().unwrap();
                    let fmt = match surface.format() {
                        cairo::Format::ARgb32 => gtk4::gdk::MemoryFormat::A8r8g8b8,
                        cairo::Format::Rgb24 => gtk4::gdk::MemoryFormat::R8g8b8,
                        cairo::Format::A8 => gtk4::gdk::MemoryFormat::A8,
                        _ => {
                            panic!("Unsupported")
                        }
                    };
                    let width = surface.width();
                    let height = surface.height();
                    let stride = surface.stride() as usize;
                    let data = surface.0.data().unwrap();
                    let data:&[u8] = data.as_ref();
                    let data  = gtk4::glib::Bytes::from(data);
                    let texture = gtk4::gdk::MemoryTexture::new(
                        width,
                        height,
                        fmt,
                        &data,
                        stride as usize
                    );
                    pic.set_paintable(Some(&texture));
                }

            },
            _ =>{}
        }
        Ok(())
    })
});


pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        App::new(),
        "win",
        LuaWrapper(gtk4::Window::new()),
        "scrolled_win",
        LuaWrapper(gtk4::ScrolledWindow::new()),
        "button",
        LuaWrapper(gtk4::Button::new()),
        "text_box",
        LuaWrapper(gtk4::Entry::new()),
        "label",
        LuaWrapper(gtk4::Label::new(None)),
        "list_box",
        LuaWrapper(gtk4::ListBox::new()),
        "list_box_row",
        LuaWrapper(gtk4::ListBoxRow::new()),
        "box",
        LuaWrapper(gtk4::Box::new(gtk4::Orientation::Horizontal, 0)),
        "picture",
        LuaWrapper(gtk4::Picture::new()),
    )
}
